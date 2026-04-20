---
name: ito-issues
description: 讀取 GitHub PRD issue，拆分成可獨立 demo 的 vertical slice sub-issues。使用者說「把 PRD 拆成 task」、「建 sub-issue」、「開工作 issue」時使用。不適用於需要直接實作、純技術架構討論、或 PRD 尚未定案的情境。
---

# ito-issues

## 概覽

讀取 GitHub 上既有的 PRD issue，以 read-only 方式探索 codebase 後，將 PRD 拆成可獨立 demo 的 vertical slice sub-issues，並用 GitHub 原生 sub-issue / Blocked by 關係建立依賴。

## 使用時機

- 使用者說「把 PRD 拆成 task」、「建 sub-issue」、「開工作 issue」
- ito-prd 完成後使用者表示「接著拆 task」，主動接手
- 使用者給定 PRD issue 編號或 URL 要求拆分執行任務

**不應使用的情況：** 需要直接實作功能、純技術架構討論、PRD 尚未定案需要先跑 ito-prd、或 PRD 已在進行中不應重切。

## 核心流程

### 步驟 1：取得 PRD issue

依優先順序判斷 PRD 來源：

| 來源 | 判斷依據 |
|------|---------|
| slash command 參數 | prompt 帶 issue 編號或 URL（例如 `/ito-issues 42` 或 `/ito-issues https://github.com/org/repo/issues/42`） |
| 對話 context | 剛跑完 ito-prd 留下明確的 issue 編號 |
| 互動選擇 | 以上皆無時，列出當前 repo 所有帶 `PRD` label 的 open issue 讓使用者選一個 |

確認 PRD issue 後，讀取其完整 body 與 metadata（title、labels、既有的 sub-issues），並記下 PRD issue number 作為後續 sub-issue 編號前綴（例如 PRD issue `#36` → sub-issue 前綴 `PRD-36`）。

### 步驟 2：Re-run 前置檢查

讀取 `references/re-run-precheck.md` 以取得偵測規則與互動流程。

若該 PRD 已有 open 的 sub-issue，進入互動確認流程；使用者選擇關閉重建才繼續，選擇取消則 skill 結束。

若無既有 sub-issue，直接進步驟 3。

### 步驟 3：Read-only 探索

**不寫任何 code**，產出僅存在 agent 內部 context，不落檔。本步驟目標：

1. 讀 PRD issue body，識別 User Stories、驗收條件、Out of Scope、已知侷限
2. 探索同 repo 的相關 codebase：
   - 單一明確查詢 → 直接用 Grep / Glob
   - 範圍不確定或需多輪搜尋 → 呼叫 Explore sub-agent，避免污染主對話 context
3. 識別現有 pattern、convention、dependency、風險、未知點

**完整性檢查：**

- 若 PRD 缺驗收條件、缺 User Stories、或需求敘述過於發散，soft warn 使用者指出具體缺口，由使用者決定續跑或退回 `/ito-prd` 補齊
- 若 PRD 只涉及單一層（純 CSS、純 config、純文件），soft warn「看起來不需要 vertical slicing」，使用者可 override 照拆（拆成 commit-size task）

### 步驟 4：內部建構 dependency graph

agent 內部推理依賴關係（例如 DB schema → API models → API endpoints → frontend client → UI components；或 validation logic → API endpoints），實作順序依 dependency graph bottom-up。

此步驟的 dependency graph **不對外展示**，只作為步驟 5 slicing 的推理依據。

### 步驟 5：Vertical slicing

讀取 `references/vertical-slicing-examples.md` 以取得判斷基準與對照範例。

切分原則：

- 每個 slice 切穿所有整合層（schema + API + UI + tests），**不是**單層 horizontal
- 每個 slice 必須可獨立 demo / verify
- 偏好多個薄 slice 勝過少數厚 slice
- 不限定 slice 數量，純以「可獨立 demo」作為判斷

若 PRD 為單層型且使用者已 override，slice 以 commit-size task 為單位切分。

### 步驟 6：向使用者確認 breakdown

一次展示以下內容，完成唯一的對外 checkpoint（假設 PRD issue number 為 `36`）：

```
Breakdown 提案（PRD #36）

1. [PRD-36/1] <slice 1 純裸標題>
   - Blocked by: None
   - 涵蓋 User Stories：US-01, US-02

2. [PRD-36/2] <slice 2 純裸標題>
   - Blocked by: #<issue 1 建立後的實際編號>
   - 涵蓋 User Stories：US-03

3. [PRD-36/3] <slice 3 純裸標題>
   - Blocked by: #<issue 1>, #<issue 2>
   - 涵蓋 User Stories：US-04

依賴關係摘要：
- #1 為其他 slice 的基礎
- #2 依賴 #1 的 schema 與 auth
- #3 依賴 #1, #2 的完整流程
```

同時提問：

- 顆粒度合適嗎？（太粗 / 太細）
- 依賴關係對嗎？
- 有哪些要合併、拆分、移除、新增？

### 步驟 7：Iteration（自由文字 + diff 回放）

使用者用自由文字描述修改意圖（例如「把 2 和 3 合起來，5 拆成前後端兩塊，移除 7」）。

Agent 執行：

1. **Parse 意圖**成 diff list，格式如：
   ```
   - merge 2+3 → 新 slice: [PRD-36/_] ...
   - split 5 → 5a: [PRD-36/_] ..., 5b: [PRD-36/_] ...
   - remove 7
   - reorder: 新順序 1, 2, 4, 5a, 5b, 6
   ```
   註：diff list 中的索引使用 `_` 佔位，實際編號會在套用後依最終順序重新編號。
2. **回放 diff list** 給使用者確認：「我理解你的意思是以下 N 項修改，確認嗎？」
3. 使用者確認後才套用，**依最終順序從 1 重新連號**（例如原本的 5a 變成 `[PRD-36/4]`），套用後重展完整 breakdown 回到步驟 6

重複直到使用者明確 approve 整份 breakdown。

### 步驟 8：建立 sub-issues

Approval 後**不再 prompt**，直接依序建完：

1. 讀取 `references/issue-template.md` 以取得 body 模板結構
2. 確保 `Task` label 存在於 repo：不存在則先建立（顏色由 agent 選中性色）
3. 依 dependency 順序建 issue（blocker 先建，才能在後續 issue body 與 dependency 關係中引用真實 issue number）
4. 對每個 slice：
   - 建 issue，title 格式 `[PRD-<parent-number>/<final-index>] <純裸標題>`（例如 `[PRD-36/1] 建立廣告操作後台登入流程`）
   - Body 依 `references/issue-template.md` 填入父 Issue、功能範圍、驗收條件、Blocked by
   - Labels 只帶 `Task`
   - 以 GitHub 原生 sub-issue 功能關聯到 parent PRD issue
   - 以 GitHub 原生 issue dependencies 建立 Blocked by 關係
5. 全部建完後，回報每個新 sub-issue 的 URL 與編號

**工具選擇：** 本步驟的所有動作（建 issue、建 label、建立 sub-issue 關係、建立依賴）由 agent 自選適當工具完成（`gh` CLI、`gh api`、`gh api graphql`、REST API 皆可），skill 不綁定特定工具或參數格式。

## 常見合理化藉口

| 合理化藉口 | 實際情況 |
|---|---|
| 「直接拆不用讀 codebase」 | 跳過步驟 3 會錯過既有 pattern、convention，slice 切出來與 codebase 現況脫節 |
| 「dependency graph 內部想過就好，不用真的推」 | 略過步驟 4 會導致 slice 依賴順序錯、blocker 後於 blockee 被建立 |
| 「這個 slice 雖然是 horizontal，但工作量剛好」 | 工作量大小不是判準；horizontal slice 無法獨立 demo，後續整合風險會爆炸 |
| 「使用者大致同意了，不用展示 diff list」 | 自由文字意圖容易誤讀，跳過回放確認會讓修改錯位而使用者不察 |
| 「approval 後再 prompt 一次比較安全」 | 已決議步驟 8 建完不再 prompt；多一次摩擦違反設計，有誤要整批關掉重跑 |
| 「既有 sub-issue 直接忽略，疊加新的就好」 | 違反 re-run 規則，會產出重複任務與混亂依賴關係 |
| 「PRD 不完整就 hard stop」 | soft warn 後使用者有 override 權，hard stop 會讓小需求的流程卡死 |
| 「iteration 後保留原 index 比較好對照」 | 違反重新連號規則，index 不連號會讓後續引用混亂 |

## 警訊

- 步驟 3 未讀 codebase 就直接進 slicing
- 步驟 4 的 dependency graph 被公開展示給使用者（設計上應內部化）
- slice 命名出現 `Build API for X`、`Add schema for Y`（horizontal 信號）
- 步驟 7 自由文字意圖未經 diff list 回放就套用
- 步驟 7 套用後未重新連號，index 出現跳號或重號
- 步驟 8 中途失敗 skill 嘗試 rollback（設計上不做）
- Re-run 時未偵測既有 sub-issue 就開始建新的
- sub-issue title 缺 `[PRD-<parent-number>/<index>]` 前綴、或 label 不只 `Task`（帶了多餘 label）

## 驗證

- [ ] PRD issue 已成功取得（來自參數 / context / 互動選擇其中一條路徑）
- [ ] Re-run 偵測已執行；若有既有 sub-issue 已完成關閉重建或使用者取消
- [ ] 步驟 3 完成 codebase 探索與完整性檢查，PRD 缺口已 soft warn
- [ ] 步驟 6 的 breakdown 已展示編號清單 + 依賴
- [ ] 步驟 7 的修改都經過 diff list 回放後才套用，且最終已重新連號
- [ ] 每個 sub-issue title 為 `[PRD-<parent-number>/<index>] <標題>`，index 從 1 連號
- [ ] 每個 sub-issue 只帶 `Task` label
- [ ] 每個 sub-issue 有正確的 parent 關聯與 Blocked by 依賴
- [ ] 步驟 8 完成後已回報所有新 sub-issue 的 URL 與編號

## 錯誤處理

- 若 slash command 參數的 issue number / URL 無效，告知使用者並 fallback 到互動選擇
- 若 PRD issue 已 closed，拒絕執行，提示使用者重開或另建新 PRD
- 若步驟 3 探索失敗（repo 結構異常、權限問題），停下並回報具體錯誤，不強行進 slicing
- 若使用者 iteration 時的自由文字無法 parse 成明確 diff（例如只說「改好一點」），追問具體想改什麼，不亂套用
- 若步驟 8 中途任一 sub-issue 建立失敗（label 建立失敗、sub-issue API 失敗、dependency API 失敗），立即停下，回報已建哪些、哪個失敗、錯誤訊息原文，由使用者手動清理（skill 不 rollback）
- 若 repo 未啟用 GitHub 原生 sub-issue 或 issue dependencies 功能，步驟 8 會在第一次 API call 失敗時得知；停下並告知使用者 repo 需啟用對應功能
- 若使用者在步驟 6/7 中途說「先結束不建了」，skill 停下，不建任何 issue

## 延伸參考

- `references/issue-template.md`：sub-issue body 模板
- `references/vertical-slicing-examples.md`：vertical vs horizontal 對照範例與判斷基準
- `references/re-run-precheck.md`：重跑時的既有 sub-issue 偵測與批次關閉流程
