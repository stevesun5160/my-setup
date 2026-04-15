---
name: explore
description: |
  結構化搜尋 skill，涵蓋 codebase 搜尋與網路搜尋。遇到以下情況時主動啟動：
  1. 使用者有明確搜尋意圖（「找一下」、「在哪裡」、「查一下」、「有沒有」、「幫我搜」）
  2. 問題需要最新資訊（套件 API、library 行為、GitHub issue、近期 bug）
  3. Claude 推理出假設後，應搜尋驗證再作答

  不要只靠訓練資料回答有可能過時或與 codebase 現況不符的問題——主動啟動此 skill，確保使用正確工具、過濾低品質來源、並標注資料出處。
---

## 判斷要搜 codebase 還是網路

- 明確是 **codebase 問題**（例如「`getUserById` 定義在哪？」、「找所有呼叫這個 function 的地方」）→ 只搜 codebase。
- 明確是 **外部知識問題**（例如「React 18 Suspense 怎麼用？」、「prisma@5 有沒有已知 bug？」）→ 只搜網路。
- **語意模糊** → 先問使用者一句：「你是要在 codebase 裡找，還是查網路資料？」
- **兩者都需要**（例如「為什麼這裡這樣呼叫 X？這樣符合 library 的預期嗎？」）→ 同時執行兩種搜尋。

---

## 執行原則：一律另開 agent

**所有搜尋必須透過 Agent tool 委派給獨立 agent 執行**，避免大量原始搜尋結果污染主 context。子 agent 負責搜尋與整合，你負責呈現最終答案。

- 搜尋之間無依賴關係 → 同一回合並行 spawn 多個 Agent call。
- 有依賴關係（後一個搜尋需要前一個結果才能決定查什麼）→ 循序執行。

---

## Codebase 搜尋

依以下優先順序選工具，前一個不可用或找不到結果再往下：

1. **LSP** — 語意操作：go-to-definition、find-references、call hierarchy。適合「X 在哪裡被使用」或「X 呼叫了什麼」。
2. **ast-grep** — 結構性 pattern 比對：`ast-grep --lang <lang> -p '<pattern>'`。適合搜尋特定語法結構或 AST pattern，或 LSP 未安裝時。
3. **Grep / Glob** — 純文字搜尋與檔名比對。LSP 和 ast-grep 都不可用，或要搜尋字串 literal、註解、config 值時使用。

**Codebase 搜尋的回答格式：**
列出原始位置（file path + 行號，例如 `src/users/service.ts:142`），每筆附一到兩句摘要。讓使用者可以直接跳到原始碼位置。

---

## 網路搜尋

以下工具可依問題性質組合使用，不限定只用一個。搜尋有多個角度（官方文件 + 實際 bug 回報 + 社群討論）時，主動組合多個工具。

| 工具 | 使用時機 |
|------|----------|
| **find-docs**（ctx7） | 查套件最新 API、設定選項、官方文件。library 相關問題優先從這裡開始。若 ctx7 CLI 無法執行，直接 fallback 至 WebFetch / WebSearch。 |
| **deepwiki** | 深入了解特定 GitHub repo 的架構、設計決策、未文件化的行為。find-docs 結果不足時補充。 |
| **gh CLI** | 搜尋 GitHub issue、PR、討論串。適合找 bug 回報、feature request、已知的 workaround。 |
| **exa MCP** | 一般網路搜尋：部落格文章、技術社群討論、hands-on 教學。優先選有實際操作經驗的文章（個人 blog、dev.to、詳細的踩坑記錄）。 |
| **WebFetch / WebSearch** | 內建 fallback，exa MCP 不可用或前述工具均無法執行時使用。 |

### 內容品質過濾

納入任何網路結果前，依序套用兩層過濾：

1. **Domain blocklist** — 讀取 `references/content-farm-domains.md`，排除清單內的所有來源。
2. **AI 語意判斷** — 對不在 blocklist 的來源，評估內容品質。出現以下特徵則排除：標題堆砌關鍵字、內容空洞只是重述問題、AI 生成的填充文字、抓取或翻譯自 Stack Overflow 的內容。搜尋優先以英文資源為主。技術討論類文章，優先保留作者明顯親自執行過程式的文章（有錯誤訊息截圖、說明嘗試過什麼、分享完整 config）。

### 網路搜尋的回答格式

寫成整合式回答，不要直接列連結清單。把各來源的發現融合成一段連貫的答案。

來源互相矛盾時（例如官方文件說 X 可以這樣用，但 issue 說 v5.2 有 bug），明確告知使用者衝突存在：

> 「官方文件說 X，但 [GitHub issue #1234](url) 回報這在 v5.2 搭配 Y 時會出錯。」

所有引用來源統一以連結清單附在回答結尾：

```
**Sources**
- [標題](url)
- [標題](url)
```

---

## 搜尋失敗時

所有工具都找不到有用結果時：

1. 明確告知使用者搜了哪些地方（例如「我查過 find-docs、GitHub issue 和 exa，都沒找到相關資料」）。
2. **不要**用訓練資料假裝是搜尋結果來回答——這會讓使用者誤以為資訊是最新的。
3. 建議下一步：換關鍵字、去 library 的官方 Discord/Slack 問、或把問題範圍縮小再試。
