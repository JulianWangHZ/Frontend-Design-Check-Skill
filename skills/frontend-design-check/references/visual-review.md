# 視覺檢查約定

對照實際跑起來的頁面與 Figma，或處理互相矛盾的 review 意見時使用。

## 正式對照素材

記錄 Figma 檔案和 node ID、該 node 是頁面 frame 還是包含 overflow sibling layer 的 parent group，以及瀏覽器 URL、viewport、DPR、瀏覽器引擎、截圖時間和排除的標註 layer。

參考圖與頁面截圖必須是相同像素尺寸，並呈現相同的產品 viewport。截圖前確認最終 URL、穩定的頁面 selector、需要的 async 內容和 `document.fonts.ready`。如果任務要求驗證實際頁面，不能用貼上來的網頁截圖代替 local server 新截的圖。

## 檢查範圍

直接看原始尺寸的圖片。獨立檢查分別涵蓋：

1. Layout：固定區塊、座標、寬高、padding、overflow 與裁切。
2. 細節：icon、border、顏色、font-weight、line-height、選單、控制項和 state。
3. 完整性：漏掉的表格、欄、列、控制項、文案、彈窗和 overflow 內容。

請 reviewer 指出具體元素和看得到的邊界。不要把相似度分數或 pixel diff 比例當判定證據；瀏覽器 render、fallback font、標註和 anti-aliasing 都會影響這些數字。

## 核實有爭議的問題

reviewer 回報位置偏移時：

1. 用相同的 `x`、`y`、`width`、`height` 從兩張原圖裁切。
2. 用原始解析度看兩張裁切結果。
3. 先比較 component 邊框和穩定的參照物，再判斷文字字形。
4. 查詢實際頁面的 `getBoundingClientRect()` 和相關 computed style。
5. 只有裁切圖或 DOM 量測確認有問題後才改 code。

可依頁面中穩定的 selector 調整以下瀏覽器 code：

```js
const rect = (selector) => {
  const value = document.querySelector(selector).getBoundingClientRect()
  return { x: value.x, y: value.y, width: value.width, height: value.height, right: value.right }
}

return ['header', 'main', '[data-testid="primary-content"]']
  .filter((selector) => document.querySelector(selector))
  .map((selector) => ({ selector, ...rect(selector) }))
```

這段是 function body。用 Playwright MCP 的 `browser_evaluate` 時，包成 `() => { … }` 傳入；在其他只執行 script 的工具中，包成 `(() => { … })()`。

多個 reviewer 看同一張縮小過的拼接圖得出相同結論，仍不能證明偏移真的存在。改之前要用原始解析度的裁切圖或實際頁面的 layout 量測核實。

## Font 限制

檢查 computed font 及實際載入的 font 檔。即使 component 座標相同，平台的 fallback font 也可能改變字寬、視覺粗細和間距。除非需要的 font 在授權和技術上都能用，否則把這種差異記錄為 render 限制。
