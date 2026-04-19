---
name: ito-prd
description: 對功能需求進行動態訪談，收斂後產出結構化 PRD 存至本地或建立 GitHub Issue。使用者說「幫我做 PRD」或「幫我寫 spec」、需求待展開，或從 /ito-grill 銜接過來時觸發。不適用於 bug 修復、重構規劃、技術調研，或需求已明確無需訪談。
---

# ito-prd

## 概覽

對功能需求進行動態訪談，產出包含 4 個必要 section 的結構化 PRD，存至 `docs/prd/` 本地檔案或以 `gh` CLI 建立 GitHub Issue。支援從 `/ito-grill` context 無縫銜接，以及修訂模式（`/ito-prd <issue-number>`）。

## 使用時機

- 使用者說「幫我做 PRD」、「幫我寫 spec」、「我要開一個功能」
- 功能需求需要展開成正式 spec
- 從 `/ito-grill` 銜接過來，conversation 已有需求 summary

**不應使用的情況：** bug 修復（用 `/ito-debug`）與重構規劃（用 `/ito-refactor`），或需求已完整定義無需訪談。

## 核心流程

### 步驟 1：判斷模式

檢查是否有 `<issue-number>` argument：

- 有 argument → 進入**修訂模式**，跳至「修訂模式」章節
- 無 argument → 進入**訪談模式**，繼續步驟 2

### 步驟 2：偵測 ito-grill Context

檢查當前 conversation 是否包含來自 `/ito-grill` 的需求 summary：

**有 context：** 整理已知資訊，以下列格式呈現：

> 根據剛才的討論，我整理到以下資訊：
> - 問題描述：[摘要]
> - 目標使用者：[摘要]
> - [其他已知項目]
>
> 確認後我會從不足的部分繼續追問。

使用者確認後，繼續步驟 3，已知資訊的問題不重複問。

**無 context：** 直接進入步驟 3，從問題描述開始訪談。

### 步驟 3：動態訪談

逐一追問計畫或設計的每個決策分支，直到與使用者達成共識。依照決策樹的每個分支逐步深挖，先解決有依賴關係的決策，直到 4 個必要 section 都有足夠資訊。

**收斂條件（4 個必要 sections）：**

1. **問題描述**：情境 + 痛點 + 目標。偵測到回答模糊時（例如只說「很不方便」），立即依序追問：
   - 情境：是否有具體場景（誰、在什麼情況下、做什麼事）
   - 痛點：是否有受影響的使用者角色與發生頻率
   - 目標：是否有可驗證的成功狀態

2. **User Stories**：行為級別，每條附編號（US-XX）、簡短標題、Given/When/Then。US 只描述使用者行為，不需考量 vertical slice 切法。

3. **Out of Scope**：
   - **即時**：每當使用者提到一個功能，確認「這次要做嗎，還是先排除？」
   - **收斂前**：統一列出訪談中提到的所有功能，確認每項的包含／排除狀態

4. **已知侷限**：硬限制 + 已知風險已記錄。收斂前主動盤點以下：
   - 效能限制（例如：QPS、回應時間 SLA）
   - 第三方依賴（例如：API 可用性、SDK 版本相容性）
   - 時程限制（例如：外部 deadline、依賴其他 milestone）

**訪談守則：**

1. 一回合只問一題。
2. 每當前一個決策解鎖新子問題，且有明確因果關係時，先用一句話宣告依賴關係，再提下一題。
3. 遇到技術問題，優先問使用者；若使用者不確定，標記為 Open Question，不得自行查驗 codebase。
4. 根據問題性質選擇對應格式（見「問題格式」章節）。
5. 主動偵測技術不確定性（使用者提到「不確定」/「可能」/「還沒決定」、涉及套件選型、API 設計或第三方整合），偵測到時立即標記，計入步驟 4 清單。

### 步驟 4：收斂確認

當 4 個必要 sections 資訊充足時，列出 checklist：

> 訪談接近收斂，確認以下項目：
> - [ ] 問題描述：情境、痛點、目標都已涵蓋
> - [ ] User Stories：所有主要行為都有對應 story
> - [ ] Out of Scope：明確列出不做的功能
> - [ ] 已知侷限：效能／第三方依賴／時程 已盤點

若訪談中偵測到技術不確定點，列出清單供使用者確認：

> 我在訪談中偵測到以下技術不確定點，確認要加入 開放性問題 嗎？（可多選或自行補充）
> - [ ] [偵測到的不確定點 1]
> - [ ] [偵測到的不確定點 2]

若未偵測到任何技術不確定點，改為詢問：

> 訪談中是否有技術上尚未確定的地方？（例如：套件選型、API 設計、第三方整合）

- 確認有不確定點 → 記錄為 Open Questions
- 確認無不確定點 → 繼續步驟 5

### 步驟 5：建立本地 PRD 檔案

讀取 `assets/prd-template.md`，提取各 section 結構與 placeholder 格式。所有文字使用繁體中文台灣用語，proper nouns 保留英文。

依訪談結果填入各 section。Slug 生成規則：
- 若使用者以英文描述功能（e.g., "user auth login"）→ 直接轉小寫 kebab-case：`user-auth-login`
- 若使用者以中文描述（e.g., "用戶登入"）→ 翻譯為對應英文片語再轉 kebab-case：`user-auth-login`
- 規則：全小寫、空格與底線皆換為 `-`、移除特殊符號

```bash
mkdir -p docs/prd
# 寫入 PRD markdown 至 docs/prd/{slug}.md
```

建立後執行驗證：

```bash
bash .claude/skills/ito-prd/scripts/validate-prd.sh docs/prd/{slug}.md
```

若驗證失敗，依 stderr 錯誤補齊缺漏 section 後重新寫入。

建立後告知使用者路徑，詢問：

> PRD 已存至 `docs/prd/{slug}.md`，請 review 後告知。
>
> 要直接建立 GitHub Issue，還是先存檔 review？

**若選擇直接建立 Issue：** 跳至步驟 6，以當前 PRD 內容建立。
**若選擇存檔 review：** 等使用者回覆確認後，Read `docs/prd/{slug}.md` 取得最新內容，再進入步驟 6。

### 步驟 6：建立 GitHub Issue

以 PRD 檔案內容建立 Issue：

```bash
gh issue create \
  --title "[PRD] {功能名稱}" \
  --label "PRD" \
  --body "$(cat docs/prd/{slug}.md)"
```

若 `PRD` label 不存在，先執行：

```bash
gh label create "PRD" --color "#0075ca" --description "Product Requirements Document"
```

建立成功後，回報 Issue URL。

---

## 修訂模式（`/ito-prd <issue-number>`）

### 修訂步驟 1：讀取現有 Issue

```bash
gh issue view <issue-number> --json title,body,comments
```

### 修訂步驟 1.5：偵測 Sub-issues

執行以下指令偵測是否有 sub-issues：

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api repos/${REPO}/issues/<issue-number>/sub_issues
```

- **無 sub-issues**：繼續修訂步驟 2。
- **有 sub-issues**：記錄清單（標題、issue number），在修訂步驟 3 的 Preview 後附上影響分析（見修訂步驟 2.5）。

### 修訂步驟 2：精簡訪談

只追問「哪些部分需要修訂、原因是什麼」，不重複問已有的資訊。

### 修訂步驟 2.5：US 差異分析（有 sub-issues 時執行）

比對修訂前後的 US 清單，整理以下三類：

- **新增的 US**：需要新建 task 的項目
- **修改的 US**：對應的 sub-issue 編號，說明可能需要更新
- **刪除的 US**：對應的 sub-issue 編號，提示使用者考慮是否關閉

### 修訂步驟 3：Preview 修訂版 PRD

以 fenced code block（` ```markdown `）完整輸出修訂版 PRD，逐 section 呈現，供使用者 review 後確認。

若有 sub-issues 差異，在 Preview 後附上：

> **Sub-issues 影響分析：**
> - 需新建 task（對應新 US）：[US-XX] ...
> - 需更新的 sub-issues：#[issue-number] [標題]（對應修改的 US-XX）
> - 可能關閉的 sub-issues：#[issue-number] [標題]（對應刪除的 US-XX）
>
> 請確認後告知是否繼續覆蓋 PRD，以及如何處理受影響的 sub-issues。

### 修訂步驟 4：覆蓋 Issue 並新增 Changelog

使用者確認後，依序執行：

覆蓋 issue body：

```bash
gh issue edit <issue-number> --body "{新版 PRD markdown}"
```

新增 changelog comment：

```bash
gh issue comment <issue-number> --body "$(cat <<'EOF'
## Changelog

**日期：** {YYYY-MM-DD}

**改了什麼：**
- {改動項目 1}
- {改動項目 2}

**原因：**
- {原因說明}
EOF
)"
```

同步更新本地 PRD 檔案：

```bash
# 以 docs/prd/ 目錄中的現有檔案比對 issue title，找出對應 slug
ls docs/prd/
```

找到對應的 `docs/prd/{slug}.md` 後，將新版 PRD markdown 覆寫至該檔案。若 `docs/prd/` 不存在或找不到對應檔案，提示使用者確認本地路徑後再寫入。

---

## 問題格式

根據問題性質挑選格式：若能列出 2–4 個互斥選項，優先採用決策型或現況確認型。只有當問題本質發散時才使用開放型。

### 格式 1 — 決策型

使用者需要在幾個方向中做出設計或產品決策，且不同選項有不同的技術含義。**必須附推薦與理由。**

```
---
問題 N：[問題標題]

[一到兩句情境說明，讓使用者知道為何要問這題]

 - A）[選項一]
 - B）[選項二]
 - C）[選項三，視情況加]

我的建議：B（[選項關鍵字]），理由是：
 - 1）[理由一]
 - 2）[理由二]

你傾向哪個方向？
```

### 格式 2 — 現況確認型

了解現有系統、流程或情境；使用者自己最清楚，**不需要附推薦**。

```
---
問題 N：[問題標題]

[一到兩句說明為何需要確認這個現況]

 - A）[可能情況一]
 - B）[可能情況二]
 - C）[其他情況]

你們目前是哪一種？
```

### 格式 3 — 開放型

問題本質發散（背景脈絡、使用者樣貌、動機來源），列選項反而會強行收斂。

```
---
問題 N：[問題標題]

[一到兩句情境說明，點出為何這題需要開放回答]

你的情況是？
```

**選項設計原則：**
- 涵蓋 2–4 個最常見的情況，選項之間互斥。
- 若情境複雜，可加複合選項：`D）以上都有，但⋯`。
- 開放題拿到答案後，立即以決策型或現況確認型往下深挖。

## 常見合理化藉口

| 合理化藉口 | 實際情況 |
|---|---|
| 「需求看起來夠清楚了，不用訪談」 | 跳過訪談會累積隱性假設，導致 PRD 缺漏關鍵邊界條件 |
| 「User Stories 寫幾條就好」 | Stories 是 `/ito-tasks` 拆 sub-issues 的依據，不完整會讓拆分失準 |
| 「技術不確定的事先不管」 | Open Questions 若不在 PRD 階段標記，進入實作才發現會導致需求返工 |
| 「這個技術問題我查一下 code 就好」 | 技術細節只能來自使用者陳述，探索 codebase 會讓 PRD 混入實作假設 |

## 警訊

- 一回合出現兩個以上問題
- User Stories 只有功能級別（「使用者可以登入」），缺乏行為細節與 Given/When/Then
- PRD 沒有 Out of Scope section
- 遇到技術問題自行查驗 codebase，而非問使用者或標記 Open Question
- Out of Scope 完全靠使用者主動說，沒有即時追問
- 修訂模式有 sub-issues 但跳過差異分析直接覆蓋 PRD
- 修訂模式跳過 Preview 直接覆蓋 issue body

## 驗證

- [ ] 4 個必要 sections 都已填入（問題描述、User Stories、Out of Scope、已知侷限）
- [ ] 每條 User Story 都有編號（US-XX）、簡短標題、Given/When/Then
- [ ] 問題描述三項（情境／痛點／目標）回答模糊時都有深追
- [ ] Out of Scope：訪談中每個提到的功能都有即時確認，收斂前有統一盤點
- [ ] 已知侷限：效能／第三方依賴／時程已盤點
- [ ] `docs/prd/{slug}.md` 本地檔案已建立
- [ ] 若選擇建立 Issue：從本地檔案讀取內容後建立，title 以 `[PRD]` 開頭，label 含 `PRD`
- [ ] 修訂模式：sub-issues 偵測已執行；若有，差異分析已呈現且使用者已確認
- [ ] 修訂模式：issue body 已覆蓋，changelog comment 已新增

## 錯誤處理

- 若 `gh issue create` 失敗，檢查 `gh auth status`，提示使用者執行 `! gh auth login`
- 若 `gh api .../sub_issues` 失敗（例如：repo 未啟用 sub-issues 功能或權限不足），回報錯誤訊息，提示使用者手動確認是否有相關 task，繼續修訂流程
- 若使用者在訪談中途說「先跳過」，記錄為未解問題，計入收斂 checklist
- 若使用者回答「我不知道」，用反向問題追問（從結果或相反情境切入）；依然不知道則記錄為未解問題繼續訪談
- 若修訂模式的 issue number 找不到，回報錯誤並要求確認正確的 issue number

## 延伸參考

- 在進入訪談前，使用 `/ito-grill` 釐清模糊需求
- 多個 US 可能對應一個 task，由未來的 `ito-tasks` 依 vertical slice 策略合併；US 本身只需描述使用者行為，不需考量切分方式
- 使用 `/ito-tasks` 根據完成的 PRD issue 拆分 sub-issues
