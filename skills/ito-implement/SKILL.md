---
name: ito-implement
description: 根據 GitHub Issue 的 Acceptance Criteria 自動執行完整 TDD 循環（red-green-refactor）。使用者說「幫我實作」或從 `/ito-tasks` 銜接時觸發。不適用於無 Issue、直接修 bug、或探索性 spike。
---

# ito-implement

## 概覽

讀取 GitHub Issue 的 Acceptance Criteria，在 plan mode 確認測試行為後，自動執行 red-green-refactor 循環，強制工程師不跳過任何 TDD 步驟。

## 使用時機

- 使用者說「幫我實作」、「開始寫 code」
- `/ito-tasks` 完成後，準備進入實作
- 針對單一 sub-issue 或整個 PRD 執行 TDD

**不應使用的情況：** 尚未有 GitHub Issue（先跑 `/ito-prd`）、探索性 spike、直接修 bug 不走 TDD、branch 建立與 PR 開立（工程師自行處理）。

---

## 核心原則：Vertical Slices，不做 Horizontal Slices

**禁止做法（horizontal slices）：** 先把所有 AC 的測試全部寫完，再寫所有實作。

```
錯誤：
  RED:   test1, test2, test3, test4
  GREEN: impl1, impl2, impl3, impl4

正確：
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  ...
```

Horizontal slices 產生的測試是「想像出來的行為」，不是「實際行為」——寫實作前對 interface 還沒有足夠理解。每個 AC 獨立完成 red-green-refactor，再進下一個。

---

## 核心流程

### 步驟 1：驗證 argument

檢查是否有 `<issue-number>` argument：

- 有 argument → 繼續步驟 2
- 無 argument → 報錯並中止：

  > 請提供 issue number：`/ito-implement <issue-number>`

### 步驟 2：偵測 issue 類型

```bash
gh issue view <issue-number> --json title,body,labels
```

判斷規則：
- Issue 有 `task` label → **Task issue**，直接進步驟 3
- Issue 無 `task` label → **PRD issue**，進步驟 2.5

### 步驟 2.5：展開 PRD 的 sub-issues

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api repos/${REPO}/issues/<issue-number>/sub_issues \
  --jq '[.[] | select(.state == "open") | {number: .number, title: .title, body: .body}]'
```

- 若無 open sub-issues → 報錯中止：

  > Issue #X 沒有 open sub-issues。請先執行 `/ito-tasks <issue-number>`。

- 讀取每個 sub-issue 的 body，提取 "Blocked by" 欄位，依 dependency 排序（blockers 優先）
- 此清單為固定順序，不可調整；若只想跑部分 sub-issues，改用 `/ito-implement <task-issue-number>`

### 步驟 3：偵測測試框架

依以下優先序決定 test runner 與執行指令：

1. **CLAUDE.md 明確指定**：若 `CLAUDE.md` 有 test runner 指令，優先採用
2. **自動偵測**：
   - Node.js：讀取 `package.json`，找 `scripts.test` 或 `devDependencies` 中的 jest / vitest / mocha
   - Python：找 `pyproject.toml` / `pytest.ini` / `setup.cfg`
   - Go：預設 `go test ./...`
3. **偵測失敗** → 詢問使用者：

   > 無法自動偵測測試框架，請說明使用的 test runner 與執行指令：

### 步驟 4：進入 plan mode，確認測試行為

進入 plan mode，呈現以下清單（唯讀，不可調整順序或取消選取）：

讀取每個 sub-issue body 的 `## Interface` 區塊（由 `/ito-tasks` 步驟 5.5 填入）。若欄位為 TBD，在清單中標注，**整個 skill 暫停執行**，提示工程師：

> Issue #N 的 `## Interface` 欄位仍為 TBD。請更新 sub-issue body 的 Interface 描述後，重新執行 `/ito-implement <issue-number>`。

有任何一個 Interface 為 TBD 時，不進入 plan mode 確認，直接中止。

```
即將執行的 TDD 循環：

Issue #N：[title]
Interface：[sub-issue ## Interface 內容，或「TBD — 請先確認 interface 設計」]
測試行為（來自 Acceptance Criteria）：
  - [ ] [AC 1]
  - [ ] [AC 2]

Issue #M：[title]（Blocked by #N）
Interface：[...]
測試行為：
  - [ ] [AC 1]

Test runner：[偵測到的指令]

確認後退出 plan mode 開始執行。
```

工程師確認後退出 plan mode；若工程師中止，整個 skill 停止執行。

### 步驟 5：退出 plan mode，執行 TDD 循環

退出 plan mode，依行為順序全自動執行，不在行為之間暫停。

**第一個行為為 tracer bullet**：驗證整條 end-to-end path 可以跑通（test runner 正常、import 路徑正確、基本 scaffolding 到位）。若 tracer bullet 失敗（環境問題，而非邏輯問題），立即中斷，修好環境後重跑。

對每個行為依序執行：

#### Red phase

1. 撰寫對應該行為的測試
   - 測試名稱直接對應 AC 描述（描述 WHAT，不描述 HOW）
   - 只使用 public interface，不測試實作細節
   - 讀取 `references/tdd-tests.md` 提取好/壞測試的判斷標準
   - 若 AC 需要 mock 外部服務，讀取 `references/tdd-mocking.md` 提取 mock 邊界規則
2. 執行 test runner
3. 確認測試**失敗**（red）
   - 若測試未失敗（誤過）→ 修正測試直到確認 red，才繼續
   - **絕不在 red 未確認時進入 green phase**

**Per-cycle 確認：**
```
[ ] 測試名稱對應 AC，描述行為而非實作
[ ] 只使用 public interface
[ ] 重構後此測試仍應通過（行為不變）
[ ] 僅為此 AC 新增最少量測試 code
```

#### Green phase

1. 撰寫最小實作讓目標測試通過（不多寫、不預測下一個 AC）
2. 執行 test runner
3. 確認目標測試通過（green）
4. **若既有測試同時變紅**：
   - 嘗試調整實作讓新舊測試同時為綠
   - 超過 3 次仍無法同時通過 → 中斷，呈現卡住報告（格式見步驟 6），停止執行

### 步驟 5.5：統一 Refactor phase

所有行為的 red→green 全部通過後，對整體 codebase 執行一次 refactor。

讀取 `references/tdd-refactor-checklist.md` 提取審視步驟，逐項執行：

1. 四個主要方向逐一審視整體 codebase（duplication、deepen modules、SOLID、what new code reveals）
2. 若發現 code smell，對照 checklist 的 code smell 表確認重構範圍
3. 有機會 → 執行重構，每步後重跑 test runner 確認全綠
4. 無機會 → 直接進步驟 6

若重構涉及 module interface 調整，讀取 `references/tdd-deep-modules.md` 和 `references/tdd-interface-design.md` 提取設計原則。

**絕不在任何測試為 red 時執行 refactor。**

### 步驟 6：完成報告

所有行為跑完（或中斷）後，依結果呈現：

**全部通過：**
```
TDD 循環完成
通過行為：N 個
下一步：確認 branch 已推送後執行 /ito-review
```

**有失敗 / 中斷：**
```
TDD 循環中斷

通過（N 個）：
  - [行為 1]
  - [行為 2]

失敗（M 個）：
  Issue #X — [行為描述]
  原因：[說明卡在哪]
  嘗試過：[摘要]

請工程師介入解決失敗項目後，重新執行 /ito-implement <issue-number>。
```

---

## 常見合理化藉口

| 合理化藉口 | 實際情況 |
|---|---|
| 「先把所有 AC 的測試寫完比較有效率」 | 這是 horizontal slices，寫出來的測試是對想像行為的猜測，不是對實際行為的驗證 |
| 「測試寫了就好，不需要確認 red」 | 未確認 red 的測試可能本身就是錯的，讓錯誤實作通過 |
| 「refactor 不重要，先跑完所有行為」 | 跳過 refactor 讓技術債在每個循環累積，後期修復成本更高 |
| 「有行為失敗，先跳過繼續跑」 | 後續行為的實作建立在不穩定基礎上，衝突更難定位 |

## 警訊

- 多個 AC 的測試在 green phase 之前就存在（horizontal slices）
- Green phase 開始前未確認測試為 red
- 測試名稱描述 HOW（e.g., 「呼叫 repository.save」）而非 WHAT（e.g., 「使用者可以登入」）
- Refactor 在個別 AC 的 green 後立即執行（應為 all-at-end，待所有 AC 通過後統一執行）
- 既有測試變紅後直接跳過，未嘗試修復

## 驗證

- [ ] 行為清單已在 plan mode 與 AC 一一對應確認，每個 issue 的 Interface 欄位已呈現（非 TBD）
- [ ] 第一個行為（tracer bullet）已驗證 end-to-end path 可通
- [ ] 每個行為的 red phase 已確認測試失敗
- [ ] 每個行為的 green phase 已確認全部測試通過（含既有測試）
- [ ] 步驟 5.5 統一 Refactor：checklist 四個方向已審視，全部測試仍為綠
- [ ] 完成報告已呈現，格式對應結果（全通過 / 有失敗）

## 錯誤處理

- 若 `gh issue view` 失敗 → 檢查 `gh auth status`，提示執行 `! gh auth login`
- 若 `gh api .../sub_issues` 失敗（repo 未啟用 sub-issues）→ 改以 `/ito-implement <task-number>` 逐一執行各 task issue，不自動全域搜尋
- 若 test runner 執行失敗（找不到指令或環境問題）→ 停止並提示確認測試環境後重跑

## 延伸參考

- 在進入此 skill 前，使用 `/ito-tasks` 建立 sub-issues
- 完成後銜接 `/ito-review` 進行 PR review
- `references/tdd-tests.md`：好/壞測試判斷標準
- `references/tdd-mocking.md`：mock 邊界規則
- `references/tdd-refactor-checklist.md`：refactor 審視項目與 code smells
- `references/tdd-deep-modules.md`：deep module 設計原則
- `references/tdd-interface-design.md`：interface 設計與可測試性
