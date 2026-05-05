-- ============================================================================
-- EcoSentinel · Supabase Database Schema
-- ============================================================================
-- 此 SQL 執行於 Supabase SQL Editor。Supabase 預設啟用 RLS (Row Level Security)，
-- 我們明確設定每張表的存取規則:
--   - 公開讀取(任何人都能看見地圖上的回報)
--   - 公開寫入(任何人都能匿名通報,符合公民科學精神)
--   - 但禁止修改/刪除他人記錄(防止資料污染)
-- ============================================================================

-- 啟用 PostGIS 與 pg_trgm(模糊搜尋) extension
create extension if not exists postgis;
create extension if not exists pg_trgm;

-- ============================================================================
-- ENUM 類型定義
-- ============================================================================
do $$ begin
  create type report_type as enum (
    'rat',       -- 鼠患
    'cat',       -- 街貓
    'poison',    -- 投藥點/毒餌
    'injured',   -- 中毒/受傷鳥獸
    'leftover'   -- 廚餘暫置點
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type severity_level as enum ('low', 'medium', 'high', 'critical');
exception when duplicate_object then null; end $$;

do $$ begin
  create type habitat_type as enum (
    'market',      -- 市場/餐飲
    'residential', -- 住宅巷弄
    'park',        -- 公園/綠地
    'sewer',       -- 下水道/排水
    'school',      -- 學校/公共設施
    'transit',     -- 運輸節點
    'other'
  );
exception when duplicate_object then null; end $$;

-- ============================================================================
-- 主回報資料表
-- ============================================================================
create table if not exists public.reports (
  id            uuid primary key default gen_random_uuid(),
  type          report_type not null,
  title         text not null,
  description   text,
  location_name text,
  -- 使用 PostGIS Point(經緯度),SRID 4326 = WGS84
  geom          geography(Point, 4326) not null,
  severity      severity_level not null default 'medium',
  habitat       habitat_type,
  -- 通報者匿名資料(選填)
  reporter_role text,
  contact_email text,
  -- 廚餘暫置點專用欄位
  daily_volume_tons numeric(10, 2),
  -- 中繼資料
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  -- 是否經過審核(預設 false,community moderation)
  verified      boolean not null default false,
  -- 防 spam:同一 IP 短時間多次通報會被合併
  client_fingerprint text
);

-- ============================================================================
-- 索引(查詢效能)
-- ============================================================================
-- 空間索引:讓「附近 N 公尺內」這類查詢飛快
create index if not exists reports_geom_idx on public.reports using gist (geom);
-- 類型篩選
create index if not exists reports_type_idx on public.reports (type);
-- 時間排序(feed 用)
create index if not exists reports_created_at_idx on public.reports (created_at desc);
-- 嚴重度篩選
create index if not exists reports_severity_idx on public.reports (severity);

-- ============================================================================
-- 自動更新 updated_at trigger
-- ============================================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end; $$ language plpgsql;

drop trigger if exists reports_updated_at on public.reports;
create trigger reports_updated_at
  before update on public.reports
  for each row execute function public.set_updated_at();

-- ============================================================================
-- View:給前端使用,把 PostGIS geom 拆成 lat/lng 給 Leaflet
-- ============================================================================
create or replace view public.reports_v as
select
  id,
  type,
  title,
  description,
  location_name,
  st_y(geom::geometry) as lat,
  st_x(geom::geometry) as lng,
  severity,
  habitat,
  reporter_role,
  daily_volume_tons,
  created_at,
  verified
from public.reports;

-- ============================================================================
-- RPC:取得「廚餘節點 X 公尺內的鼠患通報」
-- 這是政策關聯分析的核心查詢
-- ============================================================================
create or replace function public.rats_near_leftover(radius_meters int default 500)
returns table (
  rat_id uuid,
  rat_title text,
  rat_lat double precision,
  rat_lng double precision,
  rat_severity severity_level,
  nearest_leftover_id uuid,
  nearest_leftover_name text,
  distance_meters double precision
)
language sql stable as $$
  select
    r.id as rat_id,
    r.title as rat_title,
    st_y(r.geom::geometry) as rat_lat,
    st_x(r.geom::geometry) as rat_lng,
    r.severity as rat_severity,
    l.id as nearest_leftover_id,
    l.title as nearest_leftover_name,
    st_distance(r.geom, l.geom) as distance_meters
  from public.reports r
  cross join lateral (
    select id, title, geom
    from public.reports
    where type = 'leftover'
    order by geom <-> r.geom
    limit 1
  ) l
  where r.type = 'rat'
    and st_distance(r.geom, l.geom) <= radius_meters
  order by distance_meters asc;
$$;

-- ============================================================================
-- RPC:取得指定行政區內的回報統計
-- ============================================================================
create or replace function public.report_stats_by_type()
returns table (
  type report_type,
  count bigint,
  avg_severity numeric
)
language sql stable as $$
  select
    type,
    count(*)::bigint as count,
    round(avg(case severity
      when 'low' then 1
      when 'medium' then 2
      when 'high' then 3
      when 'critical' then 4
    end)::numeric, 2) as avg_severity
  from public.reports
  group by type
  order by count desc;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.reports enable row level security;

-- 任何人(包含未登入)都可讀取
drop policy if exists "Anyone can read reports" on public.reports;
create policy "Anyone can read reports"
  on public.reports for select
  to anon, authenticated
  using (true);

-- 任何人都可以新增通報(公民科學)
drop policy if exists "Anyone can insert reports" on public.reports;
create policy "Anyone can insert reports"
  on public.reports for insert
  to anon, authenticated
  with check (true);

-- 只有已登入使用者(未來:管理員)可以更新或刪除
-- 目前先禁止所有人改/刪,避免資料污染
drop policy if exists "Only authenticated can update" on public.reports;
create policy "Only authenticated can update"
  on public.reports for update
  to authenticated
  using (false);  -- 預設不允許,之後可加管理員角色

drop policy if exists "Only authenticated can delete" on public.reports;
create policy "Only authenticated can delete"
  on public.reports for delete
  to authenticated
  using (false);

-- ============================================================================
-- 種子資料 SEED · 將原本 hardcoded 的展示資料寫入資料庫
-- ============================================================================
-- 注意:重複執行此 SQL 不會重複插入(用 on conflict do nothing 保護)
-- 但因為 id 是 gen_random_uuid(),這裡用 location_name 做唯一性判斷
-- ============================================================================

-- 廚餘暫置點(8 個)
insert into public.reports (type, title, description, location_name, geom, severity, daily_volume_tons, verified)
values
  ('leftover', '北投焚化廠 · 洲美露天區', '緊鄰洲美運動公園,綠桶帆布覆蓋,日供應約百噸',
   '北投區洲美街 271 號',
   st_setsrid(st_makepoint(121.5050, 25.0917), 4326)::geography,
   'critical', 580, true),
  ('leftover', '木柵堆肥場', '台北市主要堆肥處理場,容量受限',
   '文山區木柵路五段',
   st_setsrid(st_makepoint(121.5685, 24.9892), 4326)::geography,
   'high', 25, true),
  ('leftover', '大同清潔隊轉運站', '日間暫置,鄰近市場',
   '大同區昌吉街',
   st_setsrid(st_makepoint(121.5240, 25.0490), 4326)::geography,
   'high', 12, true),
  ('leftover', '大安清潔隊轉運站', '日間暫置,鄰住宅區',
   '大安區辛亥路二段',
   st_setsrid(st_makepoint(121.5430, 25.0260), 4326)::geography,
   'high', 15, true),
  ('leftover', '萬華清潔隊轉運站', '日間暫置,鄰夜市商圈',
   '萬華區東園街',
   st_setsrid(st_makepoint(121.5070, 25.0395), 4326)::geography,
   'high', 14, true),
  ('leftover', '內湖清潔隊轉運站', '日間暫置,鄰科技園區',
   '內湖區行善路',
   st_setsrid(st_makepoint(121.5780, 25.0680), 4326)::geography,
   'high', 10, true),
  ('leftover', '松山清潔隊轉運站', '日間暫置,鄰交通樞紐',
   '松山區市民大道五段',
   st_setsrid(st_makepoint(121.5780, 25.0500), 4326)::geography,
   'high', 11, true),
  ('leftover', '信義清潔隊轉運站(已改善)', '改用密閉式設施,持續觀察',
   '信義區忠孝東路五段',
   st_setsrid(st_makepoint(121.5680, 25.0345), 4326)::geography,
   'medium', 6, true)
on conflict do nothing;

-- 鼠患通報(8 個)
insert into public.reports (type, title, description, location_name, geom, severity, habitat, verified)
values
  ('rat', '信義商圈鼠跡', '商圈後巷夜間活動頻繁', '信義區市府路',
   st_setsrid(st_makepoint(121.5654, 25.0330), 4326)::geography, 'high', 'market', true),
  ('rat', '中山市場周邊', '市場攤商通報多隻成鼠', '中山區雙城街',
   st_setsrid(st_makepoint(121.5430, 25.0418), 4326)::geography, 'critical', 'market', true),
  ('rat', '大同區巷弄', '巷弄垃圾堆置點', '大同區延平北路',
   st_setsrid(st_makepoint(121.5170, 25.0476), 4326)::geography, 'medium', 'residential', true),
  ('rat', '師大夜市後巷', '夜市收攤後鼠群活動', '大安區師大路',
   st_setsrid(st_makepoint(121.5440, 25.0275), 4326)::geography, 'high', 'market', true),
  ('rat', '士林市場', '市場中央通道', '士林區大東路',
   st_setsrid(st_makepoint(121.5440, 25.0586), 4326)::geography, 'critical', 'market', true),
  ('rat', '公館商圈下水道', '下水道孔附近活動', '中正區羅斯福路',
   st_setsrid(st_makepoint(121.5340, 25.0210), 4326)::geography, 'high', 'sewer', true),
  ('rat', '萬華區夜市', '華西街夜市周邊', '萬華區華西街',
   st_setsrid(st_makepoint(121.5180, 25.0390), 4326)::geography, 'critical', 'market', true),
  ('rat', '北投市場', '市場後門堆置區', '北投區光明路',
   st_setsrid(st_makepoint(121.5230, 25.0623), 4326)::geography, 'medium', 'market', true)
on conflict do nothing;

-- 街貓 TNR 巡守(5 個)
insert into public.reports (type, title, description, location_name, geom, severity, verified)
values
  ('cat', 'TNR 街貓「黑糖」', '已絕育,定點餵養', '大安區建國南路',
   st_setsrid(st_makepoint(121.5540, 25.0340), 4326)::geography, 'low', true),
  ('cat', 'TNR 街貓「白米」', '已絕育,健康狀況良好', '中山區民生東路',
   st_setsrid(st_makepoint(121.5580, 25.0440), 4326)::geography, 'low', true),
  ('cat', 'TNR 街貓「奶茶」', '已絕育,商圈巡守', '中山區赤峰街',
   st_setsrid(st_makepoint(121.5340, 25.0480), 4326)::geography, 'low', true),
  ('cat', 'TNR 街貓「布丁」', '已絕育,公園周邊', '中正區南海路',
   st_setsrid(st_makepoint(121.5380, 25.0260), 4326)::geography, 'low', true),
  ('cat', 'TNR 街貓「咖啡」', '已絕育,市場巡守', '大同區寧夏路',
   st_setsrid(st_makepoint(121.5180, 25.0560), 4326)::geography, 'low', true)
on conflict do nothing;

-- 投藥點(3 個)
insert into public.reports (type, title, description, location_name, geom, severity, verified)
values
  ('poison', '公園發現毒餌站', '公園角落發現密閉式毒餌站', '大安區仁愛公園',
   st_setsrid(st_makepoint(121.5470, 25.0380), 4326)::geography, 'high', true),
  ('poison', '巷弄毒藥牌', '私人投放,無標示', '中山區建國北路',
   st_setsrid(st_makepoint(121.5390, 25.0510), 4326)::geography, 'medium', true),
  ('poison', '路面散落毒餌', '藍色毒餌散落人行道', '信義區基隆路',
   st_setsrid(st_makepoint(121.5510, 25.0290), 4326)::geography, 'critical', true)
on conflict do nothing;

-- 中毒/受傷鳥獸(2 個)
insert into public.reports (type, title, description, location_name, geom, severity, verified)
values
  ('injured', '⚠ 疑似中毒夜鷺', '池畔發現倒地夜鷺,口吐白沫', '中山區新生公園',
   st_setsrid(st_makepoint(121.5390, 25.0410), 4326)::geography, 'critical', true),
  ('injured', '⚠ 街貓異常死亡', '街貓於餵養點附近死亡,疑似二級中毒', '信義區虎林街',
   st_setsrid(st_makepoint(121.5640, 25.0350), 4326)::geography, 'critical', true)
on conflict do nothing;

-- ============================================================================
-- 啟用 Realtime(讓地圖即時收到新通報)
-- ============================================================================
-- 在 Supabase 控制台 → Database → Replication 中,把 reports 表加入 publication
-- 或直接執行:
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'reports'
  ) then
    alter publication supabase_realtime add table public.reports;
  end if;
end $$;

-- ============================================================================
-- 完成提示
-- ============================================================================
-- 執行成功後,前往 Supabase Dashboard → Table Editor 應可看到 reports 表
-- 並有 26 筆種子資料(8 leftover + 8 rat + 5 cat + 3 poison + 2 injured)
-- ============================================================================
