## 用途

skill 啟動後、進入步驟 1 之前的前置檢查邏輯。從本檔提取偵測規則與互動流程，在 skill 初始化時執行。

## 偵測範圍

1. **該 PRD 是否已有 sub-issue**
   - 查詢該 PRD issue 的 sub-issue 列表（透過 GitHub 原生 sub-issue 關係）
   - 只計入 open 狀態的 sub-issue（已 closed 的視為歷史，不阻擋重跑）

2. **偵測結果**
   - 結果為 0：無既有 sub-issue，直接進步驟 1
   - 結果 > 0：進入互動確認流程

## 互動確認流程

展示給使用者以下資訊（假設 PRD issue number 為 `36`）：

> 這個 PRD 已有 N 個 open 的 sub-issue：
> - #123 [PRD-36/1] 建立登入流程
> - #124 [PRD-36/2] 建立註冊流程
> - ...
>
> 依你之前的設計決策，若要修改 breakdown 需要全部關掉重建。要繼續嗎？
>
> - A）關閉舊 sub-issue（close reason: `not_planned` 並附註 `superseded by ito-issues re-run`）後重跑
> - B）取消本次執行

## 批次關閉規則

若使用者選 A：

1. 對每個既有 sub-issue 執行 close 操作
   - Close reason 使用 `not_planned`（GitHub 原生支援的 reason 之一）
   - Close comment 附註：`Superseded by ito-issues re-run on <日期>`
2. 若任何一個 close 失敗，停止整批操作，回報已關閉哪些、哪個失敗
3. 全部關閉成功後，進步驟 1 正常流程

## 不會做的事

- **不 delete issue**：只 close，保留軌跡供未來回溯
- **不 rollback**：若中途失敗，已 close 的不會重開
- **不自動處理已 closed 的 sub-issue**：已 closed 的視為歷史，重跑時只在新 sub-issue 的 body 中不引用它們即可

## 邊界情境

- **使用者重跑時 PRD title 改過了**：sub-issue title 前綴仍用 PRD issue number（例如 `PRD-36`），不隨 title 變動；新 sub-issue 的 index 從 1 重新連號
- **PRD 本身已 closed**：skill 應拒絕執行，提示使用者該 PRD 已關閉，重開或另建新 PRD 後再跑
