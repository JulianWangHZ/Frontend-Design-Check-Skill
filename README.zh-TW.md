# frontend-design-check

[English](README.md) | 繁體中文

**給 Claude 一個 Figma 連結，拿回一個跟設計稿逐像素對照過的頁面或 app 畫面。**

`frontend-design-check` 是一個 Claude Code Skill：在現有前端專案中還原 Figma 頁面，並用**實際跑起來的畫面**截圖檢查還原效果。適用於做新頁面、把既有頁面對齊設計稿，以及照需求把頁面拆成模組。

## 支援平台

| 平台 | 截圖 | 量測 |
|---|---|---|
| Web（React、Vue、Next.js…，含手機版網頁、Expo web） | 瀏覽器，指定 viewport + DPR | DOM：`getBoundingClientRect()`、computed style |
| iOS / Android app（Swift、Kotlin、React Native、Expo、Flutter） | 模擬器或實機，指定 device + scale | 真實 element tree：iOS `idb`、Android `uiautomator dump`、RN `measureInWindow` 或 Appium，每次跟 Figma 數值逐項比對 |

iOS 檢查需要 macOS（iOS 模擬器只能在 Mac 上跑）；Windows 和 Linux 可以檢查 web 和 Android。

兩種平台的判定原則一樣：同像素尺寸的兩張原圖，有證據的差異才修。

## Why

「照 Figma 刻」最常見的失敗不是刻不出來，而是**驗不準**：

- 只看 source code 或別人貼的截圖就說「一樣了」，實際跑起來位置、font、overflow 內容都不對。
- nested frame export 時漏掉 overflow 的 layer，參考圖本身就不完整。
- 拿相似度分數或 pixel diff 比例當結論，被 fallback font 和 anti-aliasing 誤導。
- 多個 reviewer 看同一張縮小的拼接圖得出同樣結論，就去改 code，結果改錯。

這個 Skill 把「對照」變成有證據的流程：同尺寸、同 viewport、同 DPR 的兩張原圖，有爭議的地方用相同座標裁切 + DOM 量測核實，確認後才改。

## 運作方式

1. **確定對照目標** — 找到包含完整頁面的 Figma node（含 overflow 的 sibling layer），產出跟頁面 viewport 像素尺寸完全一致的參考圖。
2. **實作前先看專案** — 讀 repo 指示文件、app shell、design token、現有 component 與 icon 套件，能沿用就沿用。設計稿畫到的照 Figma；沒畫的狀態與 token 照 codebase，兩邊都沒有就先問一次，不自行猜。
3. **實作 layout** — 先做外層幾何（viewport、fixed / flow 區塊、overflow、z-index），再做內容、控制項、state 與互動。
4. **驗證實際畫面** — Web：build、開瀏覽器、確認最終 URL 與 `document.fonts.ready` 後才截圖，有爭議就裁切原圖 + `getBoundingClientRect()` 核實。App：固定 status bar、字級、深淺色和動畫，在模擬器截圖，用 element tree 量測核實。
5. **交付** — Figma 參考圖、新截圖、並排對照圖、檢查紀錄（node、URL 或 device、viewport 或 scale、截圖時間）。

## 使用前準備

- 一個能開的 Figma 設計連結，最好直接指到完整頁面的 node；設計需要權限時，確認 Claude Code 已接上 Figma MCP 並能讀取。
- 一個能跑起來的前端專案，以及要實作或檢查的頁面 route（app 為畫面名稱或 deep link）。
- Web：能操作瀏覽器的工具（例如 Playwright MCP 或 Claude in Chrome），用來開頁面並截圖。
- App：已開機的 iOS 模擬器（Xcode，僅限 macOS）或 Android 模擬器 / 實機（`adb`）。截圖用內建指令即可。數值量測：Android 用內建的 `uiautomator dump`；iOS 需要 [`idb`](https://fbidb.io)（`brew install facebook/fb/idb-companion` + `pip install fb-idb`）或 Appium 其中一種，React Native 專案也可以改用 `measureInWindow`，不另外安裝。
- 明確的目標 viewport 尺寸或 device 型號；有 responsive、互動或拆模組需求，也寫在任務裡。

## 安裝

擇一：

**Claude Code plugin**（推薦）

```text
/plugin marketplace add JulianWangHZ/Frontend-Design-Check-Skill
/plugin install frontend-design-check@frontend-design-check
```

**npx**：裝到任何會讀 `SKILL.md` 的 agent

```bash
npx -y skills add JulianWangHZ/Frontend-Design-Check-Skill --skill frontend-design-check -g
```

**手動複製**：個人全域或單一專案

macOS / Linux：

```bash
git clone https://github.com/JulianWangHZ/Frontend-Design-Check-Skill.git
# 全域（所有專案可用）
mkdir -p ~/.claude/skills
cp -R Frontend-Design-Check-Skill/skills/frontend-design-check ~/.claude/skills/
# 或只給某個專案用
mkdir -p <專案根目錄>/.claude/skills
cp -R Frontend-Design-Check-Skill/skills/frontend-design-check <專案根目錄>/.claude/skills/
```

Windows（PowerShell）：

```powershell
git clone https://github.com/JulianWangHZ/Frontend-Design-Check-Skill.git
# 全域（所有專案可用）
New-Item -ItemType Directory -Force "$HOME\.claude\skills" | Out-Null
Copy-Item -Recurse Frontend-Design-Check-Skill\skills\frontend-design-check "$HOME\.claude\skills\"
# 或只給某個專案用
New-Item -ItemType Directory -Force "<專案根目錄>\.claude\skills" | Out-Null
Copy-Item -Recurse Frontend-Design-Check-Skill\skills\frontend-design-check "<專案根目錄>\.claude\skills\"
```

保持 `SKILL.md` 與 `references/` 的相對位置。裝好後重開 Claude Code，在 `/` 選單中應該看得到 `frontend-design-check`。

## 快速開始

在**目標前端專案**中開 Claude Code，送出附 Figma 連結與驗收條件的任務。

還原新頁面：

```text
使用 /frontend-design-check，還原這個 Figma 頁面：<Figma 頁面連結或 node 連結>。
在目前前端專案中實作，目標 route 是 /dashboard，用 1440×900 viewport 檢查。
保留設計中的完整內容、控制項和 state，並提供實際頁面與設計稿的截圖對照。
```

修正既有頁面：

```text
使用 /frontend-design-check，對照 <Figma node 連結> 檢查目前專案的 /dashboard。
修正有證據支持的 layout 和細節差異，用 1440×900 viewport 驗證實際頁面。
```

還原 app 畫面：

```text
使用 /frontend-design-check，還原這個 Figma 畫面：<Figma node 連結>。
在目前的 React Native 專案實作 Settings 畫面，用 iPhone 17 Pro 模擬器（402×874 pt @3x）檢查。
提供模擬器截圖與設計稿的對照。
```

任務明確是 Figma 頁面還原或對齊時，Claude 也會依 Skill 描述自動選用；寫出 `/frontend-design-check` 可明確指定（用 plugin 安裝時為 `/frontend-design-check:frontend-design-check`）。

| 你想要… | 在任務裡加上 |
|---|---|
| 拆成多個模組分別實作 | 指出要拆的頁面區塊，會為每塊附上[模組說明](skills/frontend-design-check/references/module-contract.md) |
| 獨立 review | 要求「分別 review layout、細節、完整性」 |
| Responsive / fluid layout | 說明預期行為，不會只固定在單張 export 的尺寸 |
| 指定對照截圖 | 明確說用你給的截圖當最終對照目標 |

## 交付內容

- Code 改動與相關檢查、build 結果
- Figma 參考圖、新截的頁面截圖、有標籤的並排對照圖（兩張像素尺寸相同）
- 簡短的檢查紀錄：Figma node、最終 URL、viewport、DPR、截圖時間（app 為 bundle ID / package name、畫面、device、OS 版本、scale）
- 已確認的剩餘限制（例如缺少需要的 font）
- 要求拆模組時，附上各模組說明

## 注意事項

**Font 差異不一定是 bug。** 就算 component 座標完全一樣，平台的 fallback font 也會改變字寬、粗細和間距。需要的 font 在授權或技術上拿不到時，會記為 render 限制，而不是硬調間距去湊。

**不看相似度分數。** Pixel diff 比例會被瀏覽器 render、fallback font、標註和 anti-aliasing 影響，只當參考；判定一律靠原解析度的裁切圖或 DOM / element tree 量測。完整方法見[視覺檢查約定](skills/frontend-design-check/references/visual-review.md)。

**App 量的是真的 app。** 數值比對直接讀模擬器上的 element tree，不把 React Native 轉成 web 在瀏覽器量；瀏覽器的排版和 font 跟原生不同，量到的不是使用者看到的畫面。位置、尺寸、間距是量測值；背景色從截圖取樣；字級、字重讀 code 推導，報告會分開列出信度。

**App 的 status bar 不算差異。** 時間、電量、訊號跟設計稿不同是正常的。截圖前會先把 status bar 固定成 9:41、滿電；設計稿的 status bar 只是示意圖時，這塊直接排除不比。細節見 [App 視覺檢查約定](skills/frontend-design-check/references/native-review.md)。

## 檔案說明

```text
.claude-plugin/
  plugin.json                      Claude Code plugin 設定
  marketplace.json                 plugin marketplace 設定
skills/frontend-design-check/
  SKILL.md                         觸發條件、實作流程與交付要求
  references/module-contract.md    拆模組實作時用的說明範本
  references/visual-review.md      截圖複核與爭議問題的驗證方法
  references/native-review.md      App（iOS / Android）的截圖與量測方法
```

## 授權

MIT，詳見 [LICENSE](LICENSE)。
