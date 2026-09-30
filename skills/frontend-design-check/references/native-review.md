# App 視覺檢查約定

目標是 iOS / Android 原生 app（Swift、Kotlin、React Native、Expo、Flutter 等）時使用。流程和判定原則跟 [視覺檢查約定](visual-review.md) 一樣，只是把瀏覽器換成模擬器或實機、把 DOM 量測換成 element tree 量測。

## 對照基準：device + scale

App 沒有 URL 和 viewport，改用這組條件鎖定對照基準：

- **Device**：模擬器或實機型號、OS 版本。
- **邏輯尺寸**：iOS 用 pt、Android 用 dp，例如 iPhone 402×874 pt、Pixel 412×915 dp。
- **Scale**：iOS 的 `@2x` / `@3x`，Android 的 density（`adb shell wm density` 的值 ÷ 160）。這就是 web 的 DPR。

截圖像素尺寸 = 邏輯尺寸 × scale。例如 402×874 pt @3x 的截圖是 1206×2622 px。Figma frame 要選同一個邏輯尺寸，export 時用同一個 scale（`3x`），兩張圖像素尺寸才會一致。Figma frame 跟 device 尺寸不同時，先跟使用者確認用哪台 device 對照，不要自己縮放圖片硬湊。

記錄：Figma 檔案和 node ID、app 的 bundle ID / package name、畫面名稱或 deep link、device、OS 版本、邏輯尺寸、scale、截圖時間和排除的標註 layer。

## 截圖前固定環境

系統狀態會讓兩張圖多出跟產品無關的差異，截圖前先固定：

| 項目 | iOS 模擬器 | Android |
|---|---|---|
| Status bar | `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3` | `adb shell settings put global sysui_demo_allowed 1` 後，用 `adb shell am broadcast -a com.android.systemui.demo -e command enter`、`-e command clock -e hhmm 0941`、`-e command notifications -e visible false` |
| 字級 | `xcrun simctl ui booted content_size large`（系統預設） | `adb shell settings put system font_scale 1.0` |
| 深淺色 | `xcrun simctl ui booted appearance light`（或 `dark`，跟設計稿一致） | `adb shell cmd uimode night no`（或 `yes`） |
| 動畫 | 等畫面靜止後再截 | `adb shell settings put global window_animation_scale 0`，`transition_animation_scale`、`animator_duration_scale` 同樣設 0 |

設計稿的 status bar 如果是示意圖，或時間、電量不一樣，把 status bar 區塊列為排除的標註，不當差異處理。檢查完用 `xcrun simctl status_bar booted clear`、`-e command exit` 還原。

## 截圖

每次正式截圖前確認：

- 停在目標畫面，不是登入、錯誤、loading、權限詢問或非預期跳轉的畫面。
- 畫面上有穩定的標記（例如某個 `testID` / accessibility id 已出現），需要的 async 內容都載入完。
- 自訂 font 已載入（例如 Expo 的 `useFonts` 已 resolve、splash screen 已隱藏）。
- 鍵盤、toast、系統對話框都沒擋住畫面，捲動位置在設計稿對應的位置。

截圖不需要 Appium，用 Xcode / Android SDK 內建指令即可，像素尺寸都是實際解析度：

- iOS 模擬器：`xcrun simctl io booted screenshot --type=png <檔案>.png`
- Android：`adb exec-out screencap -p > <檔案>.png`
- 已接上 Appium MCP 時，也可用 `appium_screenshot`。

截完用 `sips -g pixelWidth -g pixelHeight <檔案>.png`（macOS）確認像素尺寸跟 Figma 參考圖一致。

## 數值比對（App 每次都做）

截圖用眼睛比，容易漏掉 1–4 pt 的間距差和相近的顏色差。App 驗證時，每次都要把 Figma 的數值跟**模擬器或實機上真實的 element tree** 逐項比對。不要把 RN 轉成 react-native-web 在瀏覽器裡量：瀏覽器和原生的排版引擎、font 都不同，量到的不是使用者看到的畫面。

### 1. 對應 anchor

挑出畫面上要比的元素（按鈕、卡片、標題、列表項目、主要容器），列成 `testID / accessibility id ↔ Figma node ID` 對照表。沒有 `testID` 的元素，用文字內容加上位置順序來對應；對不上就問使用者，不要猜。

### 2. 期望值：從 Figma 抽數字

用 Figma MCP（`get_design_context`、`get_metadata`），或有 `FIGMA_API_KEY` 時用 REST API `GET /v1/files/:fileKey/nodes?ids=:nodeId`，取出每個 anchor 的：

- 位置和尺寸：`absoluteBoundingBox` 減去所在 frame 的原點，換成相對畫面左上角的 `x`、`y`、`width`、`height`。
- 間距：`paddingLeft/Right/Top/Bottom`、`itemSpacing`（gap）。
- 顏色：`fills` / `strokes` 的 hex 和 opacity。
- 文字：`fontSize`、`lineHeightPx`、`fontWeight`、`fontFamily`、文字顏色。
- 圓角：`cornerRadius`。

COMPONENT_SET 要依畫面實際用到的 variant 抽，不要只抽第一個。

### 3. 實際值：從真實 element tree 量

| 做法 | 平台 | 單位 | 備註 |
|---|---|---|---|
| `idb ui describe-all --udid <UDID>` | iOS 模擬器 | pt | 需要 `idb` + `idb_companion`；`AXUniqueId` 就是 `testID` |
| `adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml` | Android | px | SDK 內建；`resource-id` 就是 `testID` |
| `appium_get_page_source`，或 `appium_find_element` 後讀 `rect` / `bounds` | iOS / Android | iOS pt、Android px | 需要 Appium + Appium MCP |
| 暫時加 `ref.current?.measureInWindow((x, y, width, height) => console.log(…))` | React Native / Expo | pt / dp | 不用安裝；量完要移除 |
| Xcode Debug View Hierarchy、Flutter DevTools Widget Inspector | iOS 原生、Flutter | pt / 邏輯 pixel | 只能人工操作，agent 無法自動讀 |

iOS 模擬器要自動量測，至少需要 `idb`、Appium、RN `measureInWindow` 其中一種。Android 用內建的 `uiautomator dump` 就夠了。

量不到元素時，先排除這些原因：

- **React Native 的 view flattening**（iOS / Android 都會發生）：沒有 style 效果、只負責排版的 View 會在 native 端被合併掉，不會出現在 element tree。要量的容器加上 `testID`，或加 `collapsable={false}`。
- **Jetpack Compose**：`Modifier.testTag` 預設不會輸出成 `resource-id`。要在畫面 root 設 `Modifier.semantics { testTagsAsResourceId = true }`，`uiautomator dump` 才讀得到。
- **Android dump 失敗**：出現 `could not get idle state` 代表畫面還在動，先照「截圖前固定環境」關掉動畫再 dump。

為了量測暫時加的 `testID`、`collapsable`、`measureInWindow`，量完如果不屬於交付內容，就要移除。

element tree 只有 bounds 和文字，所以各屬性的量法不同：

| 屬性 | 怎麼量 | 信度 |
|---|---|---|
| 位置、寬高 | element tree bounds | 量測 |
| Padding、gap | 用父子、兄弟元素的 bounds 相減算出 | 量測（附算式） |
| 上下順序、所屬容器 | 比較 bounds 的 `y` 和包含關係 | 量測 |
| 文字內容 | element tree 的 label / text | 量測 |
| 行高 | 單行文字的 bounds 高度 | 量測 |
| 背景色、border 色 | 在截圖上，取元素內部避開文字和 icon 的點，座標 × scale 後讀像素色值 | 取樣（容許誤差） |
| 字級、字重、font family | 讀 code 的 style 推導，搭配裁切圖目視 | 靜態推導 |

換算規則：

1. Android 的 `bounds="[x1,y1][x2,y2]"` 是 px，要除以 scale 換成 dp：`width = (x2 - x1) / scale`。iOS 的值已經是 pt，直接比。
2. Safe area（瀏海、Dynamic Island、home indicator、Android 系統導覽列）會讓內容整體位移。先確認 Figma frame 有沒有包含 status bar 和 safe area，跟 device 一致後再判斷是不是偏移。
3. 取色前確認截圖的色彩空間：`sips -g profile <檔案>.png`。iOS 模擬器截圖是 sRGB，可以直接跟 Figma 的 sRGB 色值比。如果是 Display P3，要先轉換，或在紀錄中註明。
4. 顏色取樣會受 anti-aliasing、半透明疊色和陰影影響。每個色塊至少取 3 個點，每個 channel 差距在 ±3 以內算相符。半透明元素要比對疊色後的結果，不是直接比 fill 的值。

### 4. 判定：每個差異歸成 4 類

| 類別 | 判準 | 動作 |
|---|---|---|
| 真的有差 | 數值不同，也沒有正當理由 | 列為待修 |
| 看起來一樣 | 數值不同但畫面相同（例如 h48 的元素，radius 100 和 50 都是完整膠囊形） | 必須附上量測或算式，沒有依據就改列待裁定 |
| 全域 token 差 | code 用的是全 app 共用的 token（例如 body 字級 16，但 Figma 標 15） | 先問使用者，不能自己決定不修 |
| 平台限制 | 系統元件、系統 font、Android dp 換 px 的 ±1 rounding | 記錄原因，不修 |

幾何容許誤差：iOS ±0.5 pt，Android ±1 dp（來自 rounding）。超過的差異才進入判定。

### 5. 報告

量測值和靜態推導的信度不同，不能混在同一張表：

1. **量測表**：`anchor | 屬性 | Figma 期望值 | 實際值 | 判定`
2. **取色表**：`anchor | 取樣點 | Figma 色值 | 截圖色值 | 判定`
3. **靜態推導表**：表頭註明「讀 code 推導，非量測」
4. **待裁定清單**：原樣列出要問使用者的問題，不要代替使用者回答

使用者要求才改 code。這一步只負責找出差異和分類。

## 有爭議時的核實

檢查範圍和核實步驟跟 [視覺檢查約定](visual-review.md) 相同，第 4 步的 DOM 量測改用上面的 element tree 量測。

以上方法都拿不到可用的座標時（例如 Flutter 自繪 UI 沒有 semantics），只用相同座標的原圖裁切判斷，並在檢查紀錄寫明量測限制。

## App 特有的差異來源

- **系統 font**：iOS 的 SF Pro、Android 的 Roboto 跟 Figma 用的 font 不同時，字寬和行高會有差，照 [Font 限制](visual-review.md#font-限制) 記錄。
- **Pixel rounding**：Android 的 dp 換 px 會四捨五入，1 px 以內的差異先看是不是 rounding，不要急著改 code。
- **平台元件**：原生的 switch、date picker、navigation bar 由系統繪製，跟設計稿不同時記錄為平台限制，除非使用者要求改成自訂元件。
