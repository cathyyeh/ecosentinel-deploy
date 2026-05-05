// ============================================================================
// EcoSentinel · Frontend Config
// ============================================================================
// 本機開發:複製此檔為 config.local.js 並填入你的 Supabase 設定。
// Azure 部署:GitHub Actions 會在 build 階段用 secrets 動態產生此檔(覆蓋這份範本)。
//
// 注意:這裡的 anon key 是「公開金鑰」(publishable key)
// 寫死在前端是 Supabase 預期的用法,真正的安全靠 Row Level Security(RLS)
// 而不是隱藏 key。詳見 README 的「安全模型」段落。
// ============================================================================

window.ECOSENTINEL_CONFIG = {
  // ------------------------------------------------------------------------
  // Supabase 連線設定
  // ------------------------------------------------------------------------
  // 部署時:由 GitHub Actions 從 secrets 注入(SUPABASE_URL / SUPABASE_ANON_KEY)
  // 本機:把下面兩個值改成你 Supabase 專案的對應值,或建立 config.local.js
  SUPABASE_URL: '__SUPABASE_URL__',
  SUPABASE_ANON_KEY: '__SUPABASE_ANON_KEY__',

  // ------------------------------------------------------------------------
  // 模式切換
  // ------------------------------------------------------------------------
  // 若上面兩個值是預設佔位符,自動切回 mock 模式(用內建假資料)
  // 這讓任何人 clone 這個 repo 都能直接打開 index.html 看到完整 demo
  USE_MOCK_DATA: true,
};

// 自動偵測:若 URL 已被替換為真實值,則關閉 mock 模式
if (window.ECOSENTINEL_CONFIG.SUPABASE_URL &&
    !window.ECOSENTINEL_CONFIG.SUPABASE_URL.startsWith('__')) {
  window.ECOSENTINEL_CONFIG.USE_MOCK_DATA = false;
}
