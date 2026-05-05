# EcoSentinel 生態守護系統

> 鼠鼠去,生態回來。從毒到精準,走向生態平衡。
>
> 整合 One Health 與 IPM 框架的台北城市生態守護系統。

[![Deploy to Azure Static Web Apps](https://github.com/<YOUR_USERNAME>/<YOUR_REPO>/actions/workflows/azure-static-web-apps.yml/badge.svg)](https://github.com/<YOUR_USERNAME>/<YOUR_REPO>/actions)

---

## 架構概覽

```
┌──────────────────────────────────────────────────────────┐
│                    使用者瀏覽器                            │
│  ┌────────────────────────────────────────────────┐      │
│  │  index.html · Leaflet 地圖 · Chart.js 儀表       │      │
│  └────────────────────────────────────────────────┘      │
│                       │                                  │
│                       ▼ HTTPS                            │
└───────────────────────┼──────────────────────────────────┘
                        │
        ┌───────────────┴────────────────┐
        ▼                                ▼
  ┌──────────────┐               ┌────────────────┐
  │ Azure Static │               │   Supabase     │
  │  Web Apps    │               │  (PostgreSQL +  │
  │ (前端託管)    │               │   PostGIS +     │
  │              │               │   Realtime)     │
  └──────┬───────┘               └────────┬────────┘
         ▲                                 ▲
         │ push 自動部署                    │ Row Level Security
         │                                 │
  ┌──────┴───────┐                         │
  │   GitHub     │─────────────────────────┘
  │  (原始碼 +    │      Supabase JS SDK
  │ GitHub       │
  │  Actions)    │
  └──────────────┘
```

**為什麼選這套?**

| 元件 | 角色 | 為什麼 |
|------|------|--------|
| **Azure Static Web Apps** | 前端託管 + CI/CD | 免費方案足夠、自動 HTTPS、全球 CDN、PR 自動 preview |
| **Supabase** | DB + API + Realtime + Auth | PostGIS 對「廚餘節點 500m 內」這種空間查詢是天作之合。Realtime 訂閱讓地圖即時更新。前端可直接呼叫,不需要寫後端伺服器 |
| **GitHub Actions** | 自動部署 | push 到 main 即部署、PR 自動產生 preview URL |

---

## 專案結構

```
ecosentinel/
├── .github/
│   └── workflows/
│       └── azure-static-web-apps.yml    # CI/CD 工作流
├── public/                               # 部署到 Azure 的內容
│   ├── index.html                        # 主頁(整合所有 UI)
│   ├── staticwebapp.config.json          # Azure SWA 路由與 headers 設定
│   └── js/
│       ├── config.js                     # 設定檔(部署時被 Actions 改寫)
│       └── supabase-client.js            # Supabase API 封裝
├── supabase/
│   └── migrations/
│       └── 0001_initial_schema.sql       # 資料庫 schema(PostGIS + 種子資料)
├── docs/                                 # 進階文件
├── .gitignore
└── README.md
```

---

## 部署指南(完整流程)

整個流程約 30-40 分鐘。準備好以下帳號:

- [ ] GitHub 帳號
- [ ] [Supabase](https://supabase.com) 帳號(免費)
- [ ] [Azure](https://azure.microsoft.com/free) 帳號(免費,需信用卡驗證)

---

### 步驟 1 · 建立 Supabase 專案 (10 分鐘)

1. 登入 [supabase.com](https://supabase.com),點選 **New project**
2. 填入:
   - **Project name**: `ecosentinel`
   - **Database password**: 設定一個強密碼並**好好保存**
   - **Region**: 選擇 `Northeast Asia (Tokyo)` 或 `Southeast Asia (Singapore)`(亞洲使用者較快)
   - **Pricing plan**: Free
3. 等待約 2 分鐘專案建立完成

#### 1.1 執行資料庫 Schema

1. 進入 Supabase Dashboard → 左側選單 **SQL Editor**
2. 點選 **New query**
3. 把 [`supabase/migrations/0001_initial_schema.sql`](./supabase/migrations/0001_initial_schema.sql) 整份內容貼上
4. 點選右下角 **Run**(或按 `Cmd/Ctrl + Enter`)
5. 應該看到 `Success. No rows returned` — 完成 ✓

驗證:
- 左側選單 **Table Editor** → 應看到 `reports` 表
- 點進去應有 26 筆種子資料(8 廚餘 + 8 鼠患 + 5 街貓 + 3 投藥 + 2 中毒)

#### 1.2 取得連線資訊

1. 左側選單 **Project Settings**(齒輪圖示)→ **API**
2. 複製以下兩個值,稍後會用到:
   - **Project URL**: 形如 `https://xxxxxxxxxxx.supabase.co`
   - **Project API keys** → **anon / public**: 一長串 JWT 字串

> **這兩個值會出現在前端原始碼裡。是這樣設計的。**
> Supabase 的 anon key 是「公開金鑰」,前端可以看到不是漏洞。
> 真正的安全靠資料庫的 **Row Level Security**(我們在 schema 中已設定)。

---

### 步驟 2 · 推上 GitHub (5 分鐘)

```bash
# 在本機解壓專案後
cd ecosentinel

# 初始化 git
git init
git add .
git commit -m "Initial commit: EcoSentinel"

# 在 GitHub 網站建立新 repo(不要勾選 Initialize with README)
# 然後:
git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
git branch -M main
git push -u origin main
```

---

### 步驟 3 · 建立 Azure Static Web App (10 分鐘)

1. 登入 [Azure Portal](https://portal.azure.com)
2. 上方搜尋 `Static Web Apps` → 點選 **建立**(Create)
3. **Basics** 頁籤填入:
   - **Subscription**: 選擇你的訂閱
   - **Resource Group**: 點 **Create new**,命名為 `ecosentinel-rg`
   - **Name**: `ecosentinel`(這會是你網址前綴)
   - **Plan type**: **Free**
   - **Region for Azure Functions API**: 選擇 `East Asia` 或 `Southeast Asia`
   - **Source**: 選 **GitHub**
4. 點 **Sign in with GitHub**,授權 Azure 存取
5. 填入:
   - **Organization**: 你的 GitHub 帳號
   - **Repository**: 剛建立的 repo
   - **Branch**: `main`
6. **Build Details** 頁籤:
   - **Build Presets**: **Custom**
   - **App location**: `public`
   - **Api location**: 留空
   - **Output location**: 留空
7. 點 **Review + create** → **Create**

> Azure 會自動在你的 repo `.github/workflows/` 建立一個 workflow 檔案。
> **但我們已經有一個了**(`azure-static-web-apps.yml`),
> Azure 自動建立的會多餘。你可以選擇:
> - 把 Azure 自動建立的那個檔案(通常名字像 `azure-static-web-apps-<random>.yml`)刪除
> - 或保留它,我們的版本會自動覆蓋(因為功能相同)
>
> **建議:**保留我們的、刪除自動建立的那個,以免混淆。

#### 3.1 取得部署 Token

1. 在 Azure Portal,進入剛建立的 Static Web App
2. 上方點選 **Overview** → 右上角 **Manage deployment token**
3. 複製整串 token,稍後會用到

---

### 步驟 4 · 在 GitHub 設定 Secrets (5 分鐘)

進入你的 GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

依序新增三個 secrets:

| Secret 名稱 | 值 |
|------------|---|
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | 步驟 3.1 複製的 Azure deployment token |
| `SUPABASE_URL` | 步驟 1.2 的 Project URL |
| `SUPABASE_ANON_KEY` | 步驟 1.2 的 anon public key |

---

### 步驟 5 · 觸發部署 (5 分鐘)

```bash
# 隨便改一下,觸發 push
git commit --allow-empty -m "Trigger first deployment"
git push
```

或者直接在 GitHub repo → **Actions** 頁籤 → 選擇 workflow → **Run workflow**。

部署過程:
1. GitHub Actions 跑起來(約 2-3 分鐘)
2. 在 Actions 頁面可以看到綠色勾勾代表成功
3. 進 Azure Portal 的 Static Web App → **Overview** → 看到 **URL** 欄位的網址
4. 開啟那個網址,你的 EcoSentinel 就上線了 🎉

#### 驗證部署成功

打開網站後檢查:
- [ ] 頁面正常載入(不是空白)
- [ ] 右上角 navbar 應顯示綠色 `● 即時資料` 徽章(若顯示橘色 `◆ DEMO 模式`,表示 Supabase 連線失敗,檢查 secrets)
- [ ] 地圖上有約 26 個圖標(8 個菱形廚餘節點 + 其他圓形)
- [ ] 試送一筆測試通報 → 回 Supabase Dashboard → Table Editor → 應看到新資料

---

## 本機開發

### 純前端開發

```bash
cd public
# 用任何靜態 server 都可以,例如:
python3 -m http.server 8000
# 或
npx serve .
```

打開 `http://localhost:8000`。

預設是 **DEMO 模式**(用內建 mock 資料,不連 Supabase)。

### 連線到本地 Supabase

複製 `public/js/config.js` 為 `public/js/config.local.js`,填入你的 Supabase 設定:

```javascript
window.ECOSENTINEL_CONFIG = {
  SUPABASE_URL: 'https://xxxxxx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGc...',
  USE_MOCK_DATA: false,
};
```

然後在 `index.html` 中暫時把 `<script src="js/config.js">` 改成 `<script src="js/config.local.js">`。

> **記得**:`config.local.js` 已被加入 `.gitignore`,不會被推上 GitHub。

---

## 安全模型

### 為什麼 anon key 寫在前端是 OK 的?

Supabase 的安全模型不是「藏住 key」,而是「在資料庫層級設定誰可以做什麼」。

我們的 `0001_initial_schema.sql` 已經設定:

| 操作 | 匿名使用者(任何人) | 已登入使用者 |
|------|---------------------|------------------|
| 讀取(SELECT) | ✓ | ✓ |
| 新增(INSERT) | ✓ | ✓ |
| 修改(UPDATE) | ✗ | ✗(目前都不允許) |
| 刪除(DELETE) | ✗ | ✗(目前都不允許) |

「任何人都能新增」是公民科學專案的設計選擇 — 我們希望市民可以匿名通報,
不需要先註冊。**真正的防濫用機制**應該包含:

- [ ] 加入 reCAPTCHA 或 hCaptcha 擋機器人(待實作)
- [ ] Rate limit:同一 IP 短時間多次通報自動合併(`client_fingerprint` 欄位已預留)
- [ ] 社群審核:`verified` 欄位預設 false,需審核後才在地圖顯示

### 進階:加入管理員帳號

未來若要加入「管理員可審核/刪除」功能,在 Supabase Dashboard:

1. **Authentication** → **Providers** → 啟用 Email
2. 邀請管理員 Email 註冊
3. 修改 RLS policy:

```sql
-- 範例:讓管理員可以更新所有 reports
drop policy if exists "Only authenticated can update" on public.reports;
create policy "Admins can update"
  on public.reports for update
  to authenticated
  using (auth.jwt() ->> 'email' in ('admin@yourdomain.com'));
```

---

## 進階設定

### 自訂網域

1. Azure Portal → 你的 Static Web App → **Custom domains**
2. **Add** → 輸入你的網域(例如 `ecosentinel.taipei`)
3. 在你的網域 DNS 服務商加入 Azure 提供的 CNAME 記錄
4. Azure 會自動申請免費 SSL 憑證

### 監控與分析

- **Azure**: Static Web App → **Application Insights**(可加裝免費追蹤)
- **Supabase**: Dashboard → **Reports** 看 API 用量
- **GitHub**: Actions 頁面看每次部署紀錄

### 升級到付費方案的時機

| 場景 | 何時需要升級 |
|------|------------|
| Azure SWA Free → Standard | 月流量 > 100GB,或需 SLA 保證 |
| Supabase Free → Pro | DB > 500MB,或需要每日自動備份 |

---

## 故障排除

### 部署成功但網站顯示 DEMO 模式

→ GitHub secrets 沒設好。檢查:
- Repo → Settings → Secrets → 確認三個 secrets 都存在
- 重跑 Actions(可以 push 一個空 commit:`git commit --allow-empty -m "redeploy"`)

### Supabase 通報送出失敗

打開瀏覽器 DevTools → Console,常見錯誤:

| 錯誤訊息 | 原因 | 解法 |
|---------|------|------|
| `JWT expired` | anon key 失效 | Supabase 不會讓 anon key 過期,通常是貼成了 service key,重貼 anon |
| `new row violates row-level security policy` | RLS 沒設好 | 重跑 schema SQL |
| `relation "public.reports" does not exist` | schema 沒跑 | 跑步驟 1.1 |

### 地圖空白

- 檢查瀏覽器 Console 有沒有 JS 錯誤
- 通常是 `config.js` 路徑載入失敗,檢查 `public/staticwebapp.config.json`

---

## 後續路線圖

- [ ] 加入使用者帳號(Supabase Auth),通報者可追蹤自己提報的案件處理進度
- [ ] 整合 LINE Notify,讓里長/動保志工訂閱所在區的新通報
- [ ] PWA 化(Progressive Web App),手機可加到主畫面、離線可用
- [ ] 加入動保處/環保局的 API 整合(若公部門願意提供)
- [ ] 進階分析:用 PostgreSQL 的時序分析做「廚餘暫置 → 鼠患通報」相關係數即時計算

---

## 授權與貢獻

歡迎 Issue 與 PR。本專案以 MIT 授權釋出。

**主要參考資料**:
- [見鼠地圖 Rat Radar](https://ratdar.taipei/) — 公民科學鼠患地圖
- [台北市資料大平台](https://data.taipei/) — 政府開放資料
- [疾病管制署](https://www.cdc.gov.tw/) — 鼠媒傳染病監測

---

**鼠鼠去,生態回來。**
*From Poison to Precision · 用科學守護台北*
