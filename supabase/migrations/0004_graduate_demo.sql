-- ============================================================================
-- EcoSentinel 0004 · 從示範模式畢業
--   移除示範鼠患/毒餌/中毒受傷資料 (共 13 筆)
--   保留:8 個廚餘節點 + 5 隻 TNR 街貓 = 13 筆基礎資料
--   理由:
--     1. 即時鼠患通報已導向見鼠地圖(夥伴)
--     2. 熱區因子分析用真實 510 筆資料,比示範強
--     3. 廚餘節點是 EcoSentinel 獨家貢獻,留著
--     4. 街貓是個人故事延伸 + 街貓研究區塊呼應
-- ============================================================================

-- 先看看要刪什麼
select
  type,
  count(*) as count_to_delete,
  array_agg(title order by title) as titles
from public.reports
where verified = true
  and type in ('rat', 'poison', 'injured')
group by type;

-- 執行刪除(留 leftover 與 cat)
delete from public.reports
where verified = true
  and type in ('rat', 'poison', 'injured');

-- 檢查剩下什麼
select
  type,
  count(*) as remaining
from public.reports
where verified = true
group by type
order by type;

-- 預期結果:
-- type      | remaining
-- ----------|----------
-- cat       | 5
-- leftover  | 8
