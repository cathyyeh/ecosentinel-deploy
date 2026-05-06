// ============================================================================
// EcoSentinel · Supabase Client
// ============================================================================
// 此模組初始化 Supabase 連線,提供:
//   1. 從 Supabase 讀取所有通報(取代 hardcoded reports 陣列)
//   2. 寫入新通報
//   3. 訂閱 realtime 變更(新通報即時推送到地圖)
//   4. 空間查詢(廚餘節點 500m 內的鼠患)
//
// 環境變數注入:
//   build 時由 GitHub Actions 將 secrets 寫入 config.js
//   開發時可建立本機 config.local.js 覆蓋
// ============================================================================

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

// ============================================================================
// 讀取設定:由 config.js (GitHub Actions 在部署時生成) 注入
// ============================================================================
// window.ECOSENTINEL_CONFIG 由 /js/config.js 提供。
// 若沒有 config.js(例如本機直開 file://),退回 demo 模式
// ============================================================================
const config = window.ECOSENTINEL_CONFIG || {
  SUPABASE_URL: '',
  SUPABASE_ANON_KEY: '',
  USE_MOCK_DATA: true,  // 沒設定 Supabase 時,自動回退到模擬資料
};

export const USE_MOCK_DATA = config.USE_MOCK_DATA || !config.SUPABASE_URL;

// ============================================================================
// 建立 Supabase client(只在有設定時才建立)
// ============================================================================
export const supabase = USE_MOCK_DATA
  ? null
  : createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY, {
      auth: {
        // 這個專案目前不需要登入,關閉 auto refresh 節省連線
        autoRefreshToken: false,
        persistSession: false,
      },
      realtime: {
        params: { eventsPerSecond: 5 },
      },
    });

// ============================================================================
// API:取得所有通報
// ============================================================================
export async function fetchReports({ types = null, limit = 500 } = {}) {
  if (USE_MOCK_DATA) {
    return { data: getMockReports(), error: null, mock: true };
  }

  let query = supabase
    .from('reports_v')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);

  if (types && types.length > 0) {
    query = query.in('type', types);
  }

  const { data, error } = await query;
  if (error) {
    console.error('[Supabase] fetchReports failed:', error);
    return { data: getMockReports(), error, mock: true };
  }
  return { data, error: null, mock: false };
}

// ============================================================================
// API:新增通報
// ============================================================================
export async function insertReport(payload) {
  if (USE_MOCK_DATA) {
    console.warn('[Mock mode] insertReport simulated:', payload);
    return { data: { ...payload, id: 'mock-' + Date.now() }, error: null, mock: true };
  }

  // 把前端的 lat/lng 轉成 PostGIS 認得的 WKT(Well-Known Text)
  const { lat, lng, ...rest } = payload;
  const insertData = {
    ...rest,
    geom: `POINT(${lng} ${lat})`,
  };

  const { data, error } = await supabase
    .from('reports')
    .insert(insertData)
    .select()
    .single();

  if (error) {
    console.error('[Supabase] insertReport failed:', error);
    return { data: null, error, mock: false };
  }
  return { data, error: null, mock: false };
}

// ============================================================================
// API:上傳照片到 Supabase Storage
// 回傳 public URL,可寫入 reports.photo_url
// ============================================================================
export async function uploadPhoto(file, onProgress) {
  if (USE_MOCK_DATA) {
    console.warn('[Mock mode] uploadPhoto simulated');
    return { url: 'mock://photo/' + Date.now(), error: null, mock: true };
  }

  // 檔名:時間戳 + 隨機字串避免衝突
  const ext = file.type === 'image/png' ? 'png' :
              file.type === 'image/webp' ? 'webp' : 'jpg';
  const filename = `${Date.now()}-${Math.random().toString(36).slice(2, 10)}.${ext}`;

  if (typeof onProgress === 'function') onProgress(10);

  const { data, error } = await supabase.storage
    .from('report-photos')
    .upload(filename, file, {
      cacheControl: '3600',
      upsert: false,
      contentType: file.type,
    });

  if (error) {
    console.error('[Supabase Storage] upload failed:', error);
    return { url: null, error, mock: false };
  }

  if (typeof onProgress === 'function') onProgress(90);

  // 取得 public URL
  const { data: urlData } = supabase.storage
    .from('report-photos')
    .getPublicUrl(filename);

  if (typeof onProgress === 'function') onProgress(100);

  return { url: urlData.publicUrl, error: null, mock: false };
}

// ============================================================================
// API:訂閱 realtime 新通報(讓地圖即時更新)
// ============================================================================
export function subscribeToReports(onInsert) {
  if (USE_MOCK_DATA) {
    console.info('[Mock mode] realtime subscription disabled');
    return { unsubscribe: () => {} };
  }

  const channel = supabase
    .channel('reports-feed')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'reports' },
      (payload) => {
        // payload.new 是 reports 原始格式(geom 是 PostGIS hex)
        // 我們要轉成 lat/lng — 但 realtime 不會自動跑 view,
        // 所以這裡簡化:重新 fetch 一次最新一筆
        if (typeof onInsert === 'function') onInsert(payload.new);
      }
    )
    .subscribe();

  return {
    unsubscribe: () => supabase.removeChannel(channel),
  };
}

// ============================================================================
// API:空間查詢 — 廚餘節點 N 公尺內的鼠患通報
// ============================================================================
export async function fetchRatsNearLeftover(radiusMeters = 500) {
  if (USE_MOCK_DATA) {
    // 簡化版本:從 mock 資料計算
    const reports = getMockReports();
    const leftovers = reports.filter(r => r.type === 'leftover');
    const rats = reports.filter(r => r.type === 'rat');
    return {
      data: rats.map(rat => {
        let nearest = null;
        let minDist = Infinity;
        leftovers.forEach(l => {
          const d = haversineMeters(rat.lat, rat.lng, l.lat, l.lng);
          if (d < minDist) { minDist = d; nearest = l; }
        });
        return {
          rat_id: rat.id,
          rat_title: rat.title,
          rat_lat: rat.lat,
          rat_lng: rat.lng,
          rat_severity: rat.severity,
          nearest_leftover_id: nearest?.id,
          nearest_leftover_name: nearest?.title,
          distance_meters: Math.round(minDist),
        };
      }).filter(r => r.distance_meters <= radiusMeters),
      error: null,
      mock: true,
    };
  }

  const { data, error } = await supabase.rpc('rats_near_leftover', {
    radius_meters: radiusMeters,
  });
  return { data, error, mock: false };
}

// ============================================================================
// Helper: Haversine 球面距離(公尺)— 給 mock 模式用
// ============================================================================
function haversineMeters(lat1, lng1, lat2, lng2) {
  const R = 6371000;
  const toRad = (x) => (x * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 +
            Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
            Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ============================================================================
// Mock 資料 — 只有在沒設定 Supabase 時使用
// ============================================================================
function getMockReports() {
  return [
    // 廚餘暫置點(EcoSentinel 整理,部分查證中)
    { id: 'l1', type: 'leftover', lat: 25.0917, lng: 121.5050, title: '北投焚化廠 · 洲美露天區', location_name: '北投區洲美街 271 號', severity: 'critical', daily_volume_tons: 580, created_at: '2026-05-01T08:00:00Z' },
    { id: 'l2', type: 'leftover', lat: 24.9892, lng: 121.5685, title: '木柵堆肥場', location_name: '文山區木柵路五段', severity: 'high', daily_volume_tons: 25, created_at: '2026-05-01T08:00:00Z' },
    { id: 'l3', type: 'leftover', lat: 25.0490, lng: 121.5240, title: '大同清潔隊轉運站', location_name: '大同區昌吉街', severity: 'high', daily_volume_tons: 12, created_at: '2026-05-01T08:00:00Z' },
    { id: 'l4', type: 'leftover', lat: 25.0260, lng: 121.5430, title: '大安清潔隊轉運站', location_name: '大安區辛亥路二段', severity: 'high', daily_volume_tons: 15, created_at: '2026-05-01T08:00:00Z' },
    { id: 'l5', type: 'leftover', lat: 25.0395, lng: 121.5070, title: '萬華清潔隊轉運站', location_name: '萬華區東園街', severity: 'high', daily_volume_tons: 14, created_at: '2026-05-01T08:00:00Z' },
    { id: 'l6', type: 'leftover', lat: 25.0680, lng: 121.5780, title: '內湖清潔隊轉運站', location_name: '內湖區行善路', severity: 'high', daily_volume_tons: 10, created_at: '2026-05-01T08:00:00Z' },
    { id: 'l7', type: 'leftover', lat: 25.0500, lng: 121.5780, title: '松山清潔隊轉運站', location_name: '松山區市民大道五段', severity: 'high', daily_volume_tons: 11, created_at: '2026-05-01T08:00:00Z' },
    { id: 'l8', type: 'leftover', lat: 25.0345, lng: 121.5680, title: '信義清潔隊轉運站(已改善)', location_name: '信義區忠孝東路五段', severity: 'medium', daily_volume_tons: 6, created_at: '2026-05-01T08:00:00Z' },
    // 街貓(社區實際 TNR 個體)
    { id: 'c1', type: 'cat', lat: 25.0340, lng: 121.5540, title: 'TNR 街貓「黑糖」', location_name: '大安區建國南路', severity: 'low', created_at: '2026-05-04T12:00:00Z' },
    { id: 'c2', type: 'cat', lat: 25.0440, lng: 121.5580, title: 'TNR 街貓「白米」', location_name: '中山區民生東路', severity: 'low', created_at: '2026-05-03T12:00:00Z' },
    { id: 'c3', type: 'cat', lat: 25.0480, lng: 121.5340, title: 'TNR 街貓「奶茶」', location_name: '中山區赤峰街', severity: 'low', created_at: '2026-05-02T12:00:00Z' },
    { id: 'c4', type: 'cat', lat: 25.0260, lng: 121.5380, title: 'TNR 街貓「布丁」', location_name: '中正區南海路', severity: 'low', created_at: '2026-04-30T12:00:00Z' },
    { id: 'c5', type: 'cat', lat: 25.0560, lng: 121.5180, title: 'TNR 街貓「咖啡」', location_name: '大同區寧夏路', severity: 'low', created_at: '2026-04-28T12:00:00Z' },
    // 即時鼠患通報請至見鼠地圖 ratdar.taipei
    // 中毒/投藥事件:目前無資料(若你目擊請至見鼠地圖通報)
  ];
}

// ============================================================================
// Helper: 把 created_at ISO 字串轉成「N 分鐘前」中文格式
// ============================================================================
export function timeAgo(iso) {
  const d = new Date(iso);
  const now = Date.now();
  const diff = (now - d.getTime()) / 1000;
  if (diff < 60) return Math.floor(diff) + ' 秒前';
  if (diff < 3600) return Math.floor(diff / 60) + ' 分鐘前';
  if (diff < 86400) return Math.floor(diff / 3600) + ' 小時前';
  if (diff < 604800) return Math.floor(diff / 86400) + ' 天前';
  return d.toLocaleDateString('zh-TW');
}
