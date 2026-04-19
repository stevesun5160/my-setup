---
name: ito-tasks
description: 根據 GitHub PRD Issue 探索 codebase，以 vertical slice 策略切出可執行的 GitHub sub-issues。使用者說「幫我拆 tasks」或「把 PRD 切成 issues」時觸發。不適用於尚未有 PRD Issue、直接實作、bug 修復或重構規劃。
---

# ito-tasks

## 概覽

根據 GitHub PRD Issue 的 User Stories，結合 codebase 現況，以 vertical slice 策略切出可獨立交付的 GitHub sub-issues，並依 dependency 順序掛載於 parent issue 下。

## 使用時機

- 使用者說「幫我拆 tasks」、「把 PRD 切成 issues」
- `/ito-prd` 完成後，準備進入實作前
- 從 `/ito-debug` 或 `/ito-refactor` 銜接過來，需要拆出執行任務

**不應使用的情況：** 尚未有 PRD Issue（先跑 `/ito-prd`）、需要直接實作、bug 修復規劃、重構規劃。

---

## 核心流程

### 步驟 1：驗證 argument

檢查是否有 `<issue-number>` argument：

- 有 argument → 繼續步驟 2
- 無 argument → 報錯並中止：

  > 請提供 issue number：`/ito-tasks <issue-number>`

### 步驟 2：讀取 parent issue 並驗證 label

```bash
gh issue view <issue-number> --json title,body,comments,labels
```

取得 issue 標題、body（PRD 內容）、comments（補充討論）。

確認 labels 中包含 `PRD`，否則中止：

```bash
gh issue view <issue-number> --json labels -q '.labels[].name' | grep -qx "PRD" || {
  echo "ERROR: issue #<issue-number> 沒有 PRD label，請先執行 /ito-prd 建立 PRD Issue。"
  exit 1
}
```

### 步驟 3：偵測既有 sub-issues

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api repos/${REPO}/issues/<issue-number>/sub_issues
```

- **無 sub-issues** → 繼續步驟 4（建立模式）
- **有 sub-issues** → 進入步驟 3.5

### 步驟 3.5：Edit mode 觸發（有 sub-issues 時執行）

詢問使用者：

> 偵測到 parent issue #X 下已有 N 個 sub-issues，請選擇：
> - A）重新規劃：請先手動刪除現有 sub-issues，再重新執行
> - B）編輯現有：對照最新 PRD 做 diff，新增／更新／關閉對應 issues

使用者選 **A** → 提示手動清理後中止。  
使用者選 **B** → 進入步驟 3.6。

### 步驟 3.6：Edit mode diff 分析

1. 讀取現有 sub-issues 清單（標題、body、issue number）。
2. 對照 parent PRD 最新 User Stories，識別三類差異：
   - **新增的 US**：需建立新 sub-issue
   - **修改的 US**：對應 sub-issue 以 `gh issue edit` 更新 body
   - **刪除的 US**：對應 sub-issue 建議以 `gh issue close` 關閉
3. 呈現 diff 摘要供使用者確認後執行對應動作。
4. 執行完成後，跳至步驟 8 回報結果。

### 步驟 4：探索 codebase

Spawn sub-agent（Explore 類型），傳入以下 prompt：

```
以 deep module 視角分析此 codebase。
讀取 .claude/skills/ito-tasks/references/deep-modules.md，提取 shallow module 的 5 個 code-level 偵測訊號與「對 Slice 切分的影響」表格。

目標：了解與以下 PRD 相關的 module 邊界與 interface 寬度。
PRD 標題：[issue title]
PRD User Stories：[issue body 中 ## User Stories section 的完整內容]

請回傳：
1. 相關 module 清單（名稱、主要職責、interface 寬度評估：deep / shallow）
2. 若有 shallow module 可能被此 PRD 的實作修改，逐一標注並說明理由
```

取得 sub-agent summary 後，繼續步驟 5。

### 步驟 5：切分 vertical slices 草稿

根據 PRD User Stories + codebase summary 切分 sub-issues。

讀取 `references/vertical-slice-rules.md`，從中提取切分規則與禁止事項。

切分完成後，以摘要清單呈現：

```
Sub-issues 草稿：

1. [標題]
   Blocked by: None（可立即開始）
   US covered: US-01, US-02

2. [標題]
   Blocked by: Slice 1
   US covered: US-03
```

若有 shallow module 被修改的 slice，附注：

> ⚠️ 此 slice 可能需要修改 [Module 名稱] 的 interface，建議先考慮開 `/ito-refactor`

詢問：

> 切分方式是否合適？（可調整粒度、合併、拆分，或修改 dependency 順序）

迭代直到使用者 approve。

### 步驟 5.5：收集每個 slice 的 public interface

對每個 slice **逐一詢問工程師**：

> Slice N「[標題]」預計新增或修改哪些 public interface？
> （例如：新 function signature、新 class method、新 API endpoint、新 exported type）
> 若此 slice 純為修改既有 interface，請描述修改方向。若尚未確定，回答「TBD」——TBD 的項目會在 `/ito-implement` 的 plan mode 確認後再填入。

此步驟的回答來源是工程師，不是 Claude 的推論。若工程師對某個 slice 回答 TBD，直接填入 TBD，不得自行猜測。

收集所有回答後，整合進對應 slice 的草稿，準備寫入 sub-issue body 的 `## Interface` 區塊。

### 步驟 6：確保 `task` label 存在

```bash
gh label list --json name -q '.[].name' | grep -qx "task" || \
  gh label create "task" --color "#e4e669" --description "Implementation task"
```

### 步驟 7：依序建立 sub-issues

依 dependency 順序建立（blockers 先建），確保 "Blocked by #N" 填入真實 issue number。

對每個 slice 執行：

```bash
# 建立 issue
ISSUE_URL=$(gh issue create \
  --title "[slice 標題]" \
  --label "task" \
  --body "$(cat <<'EOF'
## What to build
[end-to-end 行為描述，非 layer-by-layer 實作]

## Acceptance criteria
- [ ] [AC 1]
- [ ] [AC 2]

## 對應 User Stories
US-XX, US-YY

## Interface
[步驟 5.5 收集的 public interface 描述]
若未確定，填入：TBD — 待實作時決定

## Blocked by
- Blocked by #N / None - can start immediately
EOF
)")

# 掛載為 parent 的 sub-issue
NEW_NUM=$(echo "$ISSUE_URL" | grep -o '[0-9]*$')
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api "repos/${REPO}/issues/<parent-number>/sub_issues" \
  --method POST \
  --field sub_issue_id="$NEW_NUM"
```

### 步驟 8：回報結果

```
已建立 N 個 sub-issues，parent: #X

請先 review 各 issue 內容確認無誤後，再開始實作。
下一步：/ito-implement
```

---

## 常見合理化藉口

| 合理化藉口 | 實際情況 |
|---|---|
| 「每個 US 切一個 issue 最清楚」 | 水平切法讓每個 issue 無法獨立交付，工程師需等多個 issues 齊全才能 demo |
| 「codebase 探索很慢，跳過也沒關係」 | 不了解 module 邊界會讓 slice 粒度失準，事後重切成本更高 |
| 「已有 sub-issues 就直接中止」 | 不提供 edit mode 會讓 PRD 更新後的 sub-issues 失去同步能力 |

## 警訊

- 草稿清單出現純 layer 名稱的 slice（e.g., "建立 API endpoint"、"新增 DB schema"）
- 未執行 codebase 探索就直接輸出草稿
- Edit mode 跳過 diff 分析，直接建立或關閉 issues
- 同一個 end-to-end path 被切成多個 slice
- Sub-issue body 缺少 `## Interface` 區塊

## 驗證

- [ ] Parent issue 已讀取，body 與 comments 都有取得
- [ ] Parent issue 的 `PRD` label 已驗證存在
- [ ] Sub-agent 探索已完成，回傳 module 邊界 summary
- [ ] 草稿清單已呈現，使用者已 approve
- [ ] 每個 slice 的 public interface 已透過步驟 5.5 收集
- [ ] `task` label 已確認存在
- [ ] 所有 sub-issues 以 `task` label 建立，並透過 gh sub-issue API 掛載於 parent
- [ ] 每個 sub-issue body 包含 `## Interface` 及 `## 對應 User Stories` 區塊
- [ ] 完成訊息已回報，提醒使用者 review

## 錯誤處理

- 若 `gh issue view` 失敗，檢查 `gh auth status`，提示執行 `! gh auth login`
- 若 `gh api .../sub_issues` POST 失敗（repo 未啟用 sub-issues 功能），issues 仍建立完成，提示使用者手動在 GitHub UI 掛載
- 若 `task` label 建立失敗（label 已存在但大小寫不同），以 `gh label list` 取得現有 label 名稱，改用最接近的 label
- 若使用者 edit mode 選 A（重新規劃），提示手動刪除現有 sub-issues 後再跑，不自動刪除

## 延伸參考

- 在進入此 skill 前，使用 `/ito-prd` 建立 PRD Issue
- 完成後銜接 `/ito-implement` 開始實作
- `references/deep-modules.md`：deep module 定義，供 codebase 探索 sub-agent 提取
- `references/vertical-slice-rules.md`：完整切分規則與禁止事項
