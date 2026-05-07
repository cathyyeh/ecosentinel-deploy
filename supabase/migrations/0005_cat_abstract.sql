-- ============================================================================
-- EcoSentinel 0005 · 街貓資料抽象化 + TCCP 標記 (修正版)
--   1. reports 表加 tccp_completed 欄位 (布林值)
--   2. 更新 5 隻街貓的 title、description、location_name
--   3. 重建 reports_v view 含 tccp_completed (不含 photo_url)
--
-- ⚠ 修正:移除原 SQL 中誤加的 photo_url 欄位 (你的 reports 表沒有此欄位)
-- ============================================================================

-- ============================================================================
-- 1. 加 tccp_completed 欄位
-- ============================================================================
alter table public.reports
  add column if not exists tccp_completed boolean default false;

-- ============================================================================
-- 2. 重建 reports_v view (含 tccp_completed,不含 photo_url)
-- ============================================================================
drop view if exists public.reports_v;

create view public.reports_v as
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
  tccp_completed,
  created_at,
  verified
from public.reports
where verified = true;

grant select on public.reports_v to anon, authenticated;

-- ============================================================================
-- 3. 更新 5 隻街貓資料
-- ============================================================================

-- 黑糖
update public.reports
set
  title = '街貓「黑糖」',
  location_name = '大安區一帶',
  description = '橘色虎斑 · 左耳剪角 · 鄰居默契照顧',
  tccp_completed = true
where type = 'cat' and title like '%黑糖%';

-- 白米
update public.reports
set
  title = '街貓「白米」',
  location_name = '中山區一帶',
  description = '白底灰斑 · 左耳剪角 · 社區照護中',
  tccp_completed = true
where type = 'cat' and title like '%白米%';

-- 奶茶
update public.reports
set
  title = '街貓「奶茶」',
  location_name = '中山區一帶',
  description = '奶茶色虎斑 · 左耳剪角 · 老巷弄常駐',
  tccp_completed = true
where type = 'cat' and title like '%奶茶%';

-- 布丁
update public.reports
set
  title = '街貓「布丁」',
  location_name = '中正區一帶',
  description = '奶油色虎斑 · 左耳剪角 · 巷弄裡的長輩',
  tccp_completed = true
where type = 'cat' and title like '%布丁%';

-- 咖啡
update public.reports
set
  title = '街貓「咖啡」',
  location_name = '大同區一帶',
  description = '深棕長毛 · 左耳剪角 · 這條巷的長輩',
  tccp_completed = true
where type = 'cat' and title like '%咖啡%';

-- ============================================================================
-- 4. 驗證
-- ============================================================================
select
  title,
  location_name,
  description,
  tccp_completed
from public.reports
where type = 'cat' and verified = true
order by title;
