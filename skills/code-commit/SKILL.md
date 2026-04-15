---
name: code-commit
description: 自動掃描 git 工作區的所有改動（staged + unstaged），以語意分析智慧分組，生成符合 Conventional Commits 規範的 commit 計畫，向使用者確認後依序執行——全程不需要手動寫任何 commit message。當使用者輸入 /code-commit、想整理工作區 commits、自動生成 commit message、或希望一次提交多個不同性質改動時，主動觸發此 skill。支援 --fast 旗標跳過分組，直接將所有改動壓成單一 commit。
model: claude-sonnet-4-6
---

# code-commit

幫助工程師零心智負擔地提交規範的 git commits：AI 讀懂所有改動、語意分組、生成 Conventional Commits message，使用者確認後自動執行。

**支援模式：**
- `/code-commit` 標準模式，語意分組 → 生成多個 commit 計畫 → 確認後依序執行
- `/code-commit --fast`：快速模式，跳過分組，將所有改動壓成單一 commit，適合小幅改動或快速存檔

---

## 執行步驟

### 第一步：掃描工作區

執行以下命令，全面了解工作區狀態：

```bash
git status
git diff HEAD
git log --oneline -10
```

偵測到 untracked files 時，一律執行 `git add <untracked files>` 將其納入本次分析。

### 第二步：偵測 commit message 語言

讀取 `git log --oneline -10` 的輸出，分析近期 commit message 使用的自然語言：

- **單一語言**：若近期 commits 都使用同一種語言（例如全部中文、全部英文），後續生成的 commit message 一律使用該語言。
- **多種語言混用**：在對話中直接詢問使用者：

  > 「偵測到近期 commit message 使用了多種語言（如：中文、英文）。請問本次要使用哪種語言來撰寫 commit message？」

  等使用者明確回覆後，再繼續下一步。

### 第三步：判斷模式

- 若使用者帶有 `--fast` 旗標：跳過第四步，直接執行**快速模式**（見文末）
- 否則：進行語意分組

### 第四步：語意分組（標準模式）

根據 `git diff` 的完整內容，以**語意邏輯**（而非目錄結構）判斷哪些改動應歸在同一個 commit。

分組原則：
- **功能相關**：同一個 feature 的前端元件、後端邏輯、對應測試，放同一個 commit
- **獨立性**：與其他改動無邏輯依賴的修改（如獨立的文件更新、chore），單獨成一個 commit
- **跟隨慣例**：讀 `git log` 了解現有 scope 命名方式（例如 `auth`、`api`、`ui`）；新專案則根據目錄或模組名稱自行推斷合理的 scope

### 第五步：生成 Commit 計畫

依照 `references/output-template.md` 的**標準模式**格式呈現完整計畫。type 對照表也在同一份檔案。

### 第六步：確認計畫

展示計畫後，在對話中直接提供兩個選項：

> **A）確認執行** — 依序執行上述所有 commit
> **B）提供修改意見** — 輸入意見，整個計畫重新生成

等使用者明確回覆後，再繼續執行。若使用者選 B，讀取意見後回到第四步重新分組與生成，反覆直到確認為止。

### 第七步：執行 Commits

確認後，**依照計畫順序**逐一執行：

```bash
git add <commit-1 的檔案>
git commit -m "<commit-1 message>"

git add <commit-2 的檔案>
git commit -m "<commit-2 message>"
# 以此類推...
```

全部完成後，輸出執行摘要：

```
✅ 完成！共執行 N 個 commits：
- <sha> <message>
- <sha> <message>
```

---

## 快速模式（--fast）

跳過語意分組，將所有選定的改動壓成**單一 commit**：

1. `git add <所有選定的檔案>`
2. 讀 `git diff --cached`，依照 `references/output-template.md` 的**快速模式**格式生成涵蓋所有改動的提案
3. 在對話中直接展示提案並詢問確認（同樣支援提供意見重新生成），等使用者明確回覆後再繼續
4. 執行 `git commit -m "<message>"`

---

## 規則速查

| 規則 | 說明 |
|------|------|
| 不詢問意圖 | AI 全自動讀 diff 生成 message，不問「你想寫什麼 commit message？」|
| 不自動 push | commit 完成即停止，不執行 push |
| 不支援局部修改 | 不同意時整個計畫重來，不支援只調整某一個 commit |
| 不偵測 breaking change | 使用者自行判斷，如有需要請手動在 message 加上 `!` 或 `BREAKING CHANGE:` |
| 跟隨現有慣例 | 讀 git log 了解 scope 命名，維持 codebase 一致性 |
| 不使用 AskUserQuestion 工具 | 所有詢問皆以對話文字進行，等使用者明確回覆後才繼續下一步 |
