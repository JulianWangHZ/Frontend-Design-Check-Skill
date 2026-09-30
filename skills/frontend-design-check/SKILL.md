---
name: frontend-design-check
description: 把 Figma 設計稿做成 web 頁面或 iOS / Android app 畫面，或把既有畫面對齊設計稿，並在瀏覽器或模擬器實際跑起來截圖、跟 Figma 參考圖用同尺寸與 scale 逐項比對，確認有證據的差異才修。當使用者給 Figma 連結要求刻頁面、刻 app 畫面、對齊 UI、修視覺落差或做 design review 時使用；手上沒有 Figma 稿的前端工作不適用。
---

# Figma 頁面還原

用 repo 現有的前端技術棧實作設計稿，並檢查實際 render 出來的頁面。不能只看 source code 或別人給的頁面截圖就判斷效果。

先判斷目標平台：

- **Web**（含手機版網頁、Expo web）：照本文件的瀏覽器流程。
- **App**（iOS / Android 原生、React Native、Expo、Flutter）：流程相同，但截圖與量測改照 [App 視覺檢查約定](references/native-review.md)。下文的 viewport / DPR 對應 app 的 device 邏輯尺寸 / scale，URL / route 對應畫面名稱或 deep link，DOM 量測對應 element tree 量測。

## 確定對照目標

- 找到包含完整頁面的正確 Figma node。parent group 可能包含 nested frame export 時漏掉的可見 layer 或 overflow 內容。
- 在明確的 viewport 尺寸和 DPR（devicePixelRatio）下，截取實際跑起來的頁面。使用者給的截圖可當輔助證據；只有使用者明確指定時，才把它當作最終頁面的對照目標。
- 做一張跟頁面 viewport 像素尺寸完全一致的 Figma 參考圖。如果完整頁面橫跨 nested frame 或 sibling layer，要在 1:1 畫布上拼接或裁切，並在複核前確認需要的內容都有顯示。
- 在相同 viewport 和 DPR 下比較 Figma 參考圖與 local server 截圖。排除 review 標註、游標、畫布留白等非產品內容。
- 呼叫 Figma `get_design_context` 前，先載入可用的 Figma design-to-code Skill；呼叫 `use_figma` 前，先載入可用的 Figma-use Skill（Figma plugin 提供的 `figma:figma-use`）。

## 實作前先看專案

讀 repo 的指示文件（`CLAUDE.md`、`AGENTS.md` 等）、app shell、layout 樣式、現有 component、design token 和已安裝的 UI 套件。符合設計要求時，沿用專案現有的 component 與慣例。

使用者要求模組化交付時，把頁面切成職責獨立的區塊，並依 [模組說明約定](references/module-contract.md) 為每個區塊寫說明文件。使用 subagent 時，先定好模組約定和互不重疊的檔案歸屬，再指定一個 integrator 負責共用 layout 及整頁驗證。

## 實作 layout

先把頁面外層的幾何關係做好：viewport、fixed 與 flow 區塊、layout 約束、overflow 和 z-index 堆疊；然後才做內容、控制項、state 與互動。

特別檢查重複結構和 data-driven 區塊，包括表頭、列表項目、state、尺寸，以及 nested frame 之外仍應顯示的內容。若產品明確要求 responsive 或 fluid layout，就照該行為做，不能只固定在單張靜態 export 的尺寸上。

UI icon 用真正的 icon component 或素材。新增素材前先檢查已安裝的 icon 套件和專案現有的封裝；優先用專案的 icon 套件，其次用正確的設計素材，最後才用 local SVG 或 icon component。如果都沒有，記錄限制。不要用依賴 font 的文字符號假裝成 icon。

## 驗證實際頁面

跑專案相關的檢查和 production build。在瀏覽器開啟實際跑起來的 app 並設定目標 viewport。每次正式截圖前，確認最終 URL 和目標 route 正確；排除登入、錯誤、loading 和非預期 redirect 狀態；等待穩定的頁面標記、需要的 async 內容及 `document.fonts.ready`。這些都通過後才截圖。能拿到 DOM 資訊時，檢查關鍵 layout 區塊的 rect 座標和 computed style。

App 則是跑專案的檢查和 debug / release build，在模擬器或實機開到目標畫面。截圖前先固定 status bar、字級、深淺色和動畫，確認停在目標畫面、async 內容和自訂 font 都載入完，再截圖。每次都要把 Figma 數值跟模擬器上真實的 element tree 逐項比對，不能改用 react-native-web 在瀏覽器量測。細節見 [App 視覺檢查約定](references/native-review.md)。

直接用眼睛看圖片差異，不把 pixel diff 比例當結論。使用者要求獨立 review 時，讓 reviewer 分別檢查 layout、component 細節和內容完整性，只提供兩張正式對照截圖，並講清楚哪些標註要排除。

如果 reviewer 意見不一致，或回報可疑的重複偏移，不要馬上改頁面。用相同座標從兩張原圖裁切同一區塊，用原始解析度檢查，並量測 DOM 邊界。只有圖片或 layout 量測有證據的問題才進入修改。完整方法見 [視覺檢查約定](references/visual-review.md)。

## 交付內容

保留最終 Figma 參考圖、新截的頁面截圖、有標籤的並排對照圖、使用者要求的模組說明，以及簡短的檢查紀錄。在檔案旁記錄 Figma node、最終 URL、viewport、DPR 和截圖時間（app 改記 bundle ID / package name、畫面、device、OS 版本、邏輯尺寸和 scale）。並排展示前確認兩張截圖的像素尺寸相同。

說明 code 改動、URL 與 viewport（app 為 device 與 scale）、build 結果、已確認的剩餘限制（例如缺少需要的 font），並提供最終產出檔案的可點擊路徑。
