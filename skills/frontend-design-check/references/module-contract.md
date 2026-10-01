# 模組說明約定

每個獨立實作的 UI 模組寫一份 Markdown 說明，檔名用設計中實際的區塊或 component 名稱。

每份說明包含：

```markdown
# ComponentName

## 職責
說明負責的可見區塊和行為。

## Figma 來源
- 檔案：設計檔名稱
- Node：正確的 node ID
- 參考尺寸：寬 × 高

## 專案依據
列出沿用的現有 component 與 design token（附檔案路徑），以及 Figma 沒畫的狀態各依據哪個檔；找不到依據的細節標「codebase 查無」。

## 公開介面
列出 props、emit 的 event、slots 和重要的預設值。

## State 與互動
列出 selected、展開、選單、彈窗、搜尋、排序、分頁、empty state 和 disabled state。

## 素材與 icon
列出設計專用素材和已安裝 UI 套件中的 icon。

## Layout 約束
記錄固定尺寸、flow 行為、錨定方式、欄位規則、overflow、z-index 和 responsive 行為。

## 驗證
記錄截圖裁切區塊和實際頁面的量測結果。
```

不要把 responsive 行為寫死成單張截圖上的量測值。Figma 尺寸只描述參考狀態；縮放、錨定、換行、裁切和 overflow 時的預期行為要另外說明。
