---
name: ito-how
description: 探索當前本地 codebase 並解釋子系統、功能流程或函式運作，產出結構化說明；若問題涉及架構缺陷或改進，額外執行批評模式。適用於「X 在此 repo 怎麼運作」類問題。不做外部文件搜尋、不做跨 repo 歷史或 blame 調查，不用於需直接實作或修改程式碼的任務。
---

# ito-how

## 概覽

在當前本地 codebase 探索並解釋某項功能、子系統或函式的運作方式，產出供工程師建立心智模型的結構化說明，而非註解化的原始碼傾倒。若使用者問題牽涉架構缺陷或改進，接續執行單 critic 批評。

## 使用時機

- 使用者問「X 在這個 repo 怎麼運作」、「Y 功能的資料流長怎樣」、「這個 service 為何這樣設計」
- 新人 onboarding 階段想快速建立特定子系統的心智模型
- 使用者問題含「架構問題 / 缺陷 / 改進 / issues / problems / improvements / 哪裡可以優化 / 有什麼毛病」等關鍵字 → 接續 Critique mode

**不應使用的情況：** 任務是直接修改、重構或新增功能；外部 library／framework 概念解釋（改用 `ctx7`）；跨 repo 的歷史調查或 blame 類任務。

## 核心流程

### 步驟 1：判定模式

1. 檢視使用者問題，若含「架構問題 / 缺陷 / 改進 / issues / problems / improvements / 哪裡可以優化 / 有什麼毛病」等關鍵字 → 模式設為 **Critique**；否則 → 模式 **Explain**（預設）。
2. 解析問題的 scope 並擇一可執行子集（子系統 / 功能流程 / 函式 / 整體架構擇一）。若問題 scope 模糊，或涵蓋三個以上子系統／整個 repo 架構，不反問，以一句話向使用者宣告採用的子集後直接開始。

### 步驟 2：Explain 階段（Explain 與 Critique 模式皆執行）— spawn explainer subagent

1. 使用 Agent tool spawn 一個 readonly subagent：
    *   `subagent_type`：優先 `Explore`；若不可用則 `general-purpose`
    *   `description`：「探索並解釋 {scope}」
    *   `prompt`：以「Explainer Subagent Prompt」章節內容為模板，填入使用者原始問題與主 agent 對 scope 的解讀
2. 等待 subagent 返回說明文字。
3. 主 agent 僅修正錯字、標點與 markdown 格式（列表縮排、標題層級、code fence 閉合）；不增刪段落、不改章節順序、不改結論或判斷用語。

### 步驟 3：Critique mode 延伸（僅當步驟 1 判定為 Critique 時執行）

1. 將步驟 2 的 Explain 輸出與相關檔案路徑清單傳給新 critic subagent：
    *   `subagent_type`：`general-purpose`（readonly）
    *   `description`：「依 rubric 批評 {scope} 的架構」
    *   `prompt`：以「Critic Subagent Prompt」章節為骨架，並將「架構批評 Rubric」章節完整內容附加於 prompt 尾端作為評估依據，不作摘要或節錄
2. 取得 critic 輸出後，主 agent 扮演務實 lead，逐條覆核並分入四個類別：
    *   **該處理**（Act on）— 架構問題，值得現在修
    *   **值得考慮**（Consider）— 真實 concern，成本／效益不明
    *   **已記下**（Noted）— 對，但優先級低
    *   **不採納**（Dismissed）— 錯、缺脈絡、或僅屬風格偏好
3. 不採納項不隱藏，明列並附一句理由，讓使用者知道已評估過。

### 步驟 4：呈現

1. 先完整輸出 Explain 結果（步驟 2 的 5 節模板）。
2. 若為 Critique mode，於其下接續「### 架構批評」段，再依四類分條列出。Explain 段必須能獨立看懂，只想理解運作的讀者不被批評淹沒。
3. 全程純 chat 輸出，不建立、修改或刪除任何檔案。

## Explainer Subagent Prompt

供步驟 2 spawn subagent 時作為 prompt 模板（填入 `{}` 變數）：

> 你是 readonly code explorer。任務：在當前本地 codebase 探索「{使用者原始問題}」。主 agent 對 scope 的解讀是「{scope 描述}」。
>
> 步驟：
> 1. 廣度先行：以 Glob 找相關目錄。結構性搜尋（函式／類型／class／interface 的定義、呼叫或結構組成）預設使用 `ast-grep --lang <language> -p '<pattern>'`（via Bash，pattern 以單引號包住以保護 `$` metavariable）；複雜結構改用 `ast-grep scan --inline-rules '<yaml rule>'`。純識別名稱或字串匹配才退回 Grep。
> 2. 決策脈絡：以 Glob 檢查 repo 是否存在 ADR／DDR 目錄（常見位置：`docs/adr/`、`docs/decisions/`、`adr/`、`architecture/decisions/`、`doc/adr/`）。若有，篩出與 {scope} 相關的決策檔案閱讀，取得設計意圖與取捨脈絡，後續「眉角」節可引用；若無，略過此步。codebase 為主、文件為輔：運作方式以實際程式碼為準；若文件描述與實作分歧，於「眉角」節明列分歧點（文件說 X、實作是 Y、推測原因）。
> 3. 跟著線索：找到進入點後沿呼叫鏈追蹤 — caller、callee、資料流、type 定義。
> 4. 讀實際程式碼，不從檔名猜。
> 5. 停止條件：能不含糊地描述從輸入到輸出（或從觸發到效果）的完整路徑。
> 6. 特別記下：非直覺的點、會讓新人誤解的細節。
>
> 以下列 5 節格式寫出說明，全程繁體中文（台灣用語）；非每節必寫，依問題性質略去不相關者：
>
> **概覽** — 1–2 段：這是什麼、做什麼、為何存在。讓讀者看完能決定是否繼續讀。
>
> **關鍵概念** — 僅列理解後續內容所需的類型 / 服務 / 抽象，簡短定義，不窮舉。
>
> **運作方式** — 核心段落：走過觸發 → 步驟 → 資料流 → 決策點，用敘述而非 pseudocode。引用具體檔案路徑與函式名（例：`src/auth/session.ts` 的 `refreshToken`）讓讀者能跳過去看，但除非非貼不可，不貼大段程式碼。
>
> **相關檔案位置** — 列出進入此區域需要知道的關鍵檔案 / 目錄，不求完整。
>
> **眉角** — 非直覺的設計、歷史包袱、已知地雷。若沒有真的值得提的，整節略去。
>
> 寫作語氣：資深工程師對另一位資深工程師做 onboarding，建立心智模型即止，不寫成註解化原始碼。

## Critic Subagent Prompt

供步驟 3 spawn critic 時作為 prompt 模板：

> 你是 readonly architectural critic。以下是主 agent 對 {scope} 的解釋：
>
> ---
> {Explain 輸出全文}
> ---
>
> 相關檔案路徑：
> {檔案路徑清單}
>
> 任務：讀實際程式碼（不只讀上面的解釋），依下節 rubric 提出架構層意見。每條意見須包含：
> 1. 具體現象（引用檔案 / 函式 / 行為）
> 2. 為何是問題（說清後果）
> 3. 可能的方向（不一定要完整方案）
>
> 避免：風格偏好、微觀命名、測試覆蓋率抱怨（除非跟架構強相關）。聚焦架構層。

## 架構批評 Rubric

供 critic 對照使用（保持簡短，沒有真正的問題的類別略去，不硬填）：

- **職責邊界**：模組 / 類別 / 服務的職責是否單一且清晰？有無「什麼都做」的 god object？
- **抽象密度**：有無明顯的抽象缺失（重複邏輯散落多處）？有無過度抽象（層次多但每層薄）？
- **耦合方向**：依賴方向是否單一？有無循環依賴、跨層穿透、高階模組依賴低階細節？
- **狀態管理一致性**：同一類狀態有無多個真相來源？mutation 路徑是否可追溯？
- **錯誤處理邊界**：錯誤在哪被捕捉、哪被抬升？有無吞錯、無聲失敗、錯誤型別被迫扁平化？
- **可測試性**：關鍵邏輯能否在不跑真實依賴下被測？測試接點是否清晰？
- **併發／擴展性風險**：有無明顯的 race condition、N+1、序列化瓶頸、不必要的同步阻塞？

## 輸出格式

### Explain 輸出

依「Explainer Subagent Prompt」章節列的 5 節格式呈現（概覽 / 關鍵概念 / 運作方式 / 相關檔案位置 / 眉角），一律繁中台灣用語。

### Critique 輸出

於 Explain 結果下方加上：

```
### 架構批評

#### 該處理
- [條目]：[一句現象] → [一句後果] → [方向提示]

#### 值得考慮
- [條目]：[現象]，[不確定的成本 / 效益面向]

#### 已記下
- [條目]：[簡短一句]

#### 不採納
- [條目]：[critic 的指控] — [為何不採納]
```

無條目的類別整個略去，不留空殼。

## 常見合理化藉口

| 合理化藉口 | 實際情況 |
|---|---|
| 「問題看起來簡單，直接在主 context 跑比較快」 | exploration 會讀多個檔案，直接進主 context 會污染後續對話 — spawn subagent 的目的就是隔離 |
| 「scope 模糊，先反問使用者」 | 模糊時以一句話宣告解讀後直接開始，反問會打斷 flow；使用者在看到結果時自然會修正方向 |
| 「critic 輸出直接列就好，不用分類」 | 不分類會讓使用者無法快速鎖定優先級；Dismissed 尤其重要，明示「已評估但不採」比悄悄忽略透明 |
| 「使用者沒用 critique keyword，但順手給點架構建議」 | Explain mode 不夾帶未被要求的 critique，避免只想理解的讀者被意見淹沒 |
| 「subagent 輸出偏離模板，改派 subagent 重跑」 | 探索已耗成本，主 agent 重整格式即可，不重跑 |
| 「ADR／DDR 寫了 X，直接以文件描述為準產出說明」 | 文件常落後於程式碼，描述的是當初決策而非現況實作；codebase 為主、文件為輔。文件只用於取設計脈絡，運作方式必須依實際程式碼，兩者分歧時明列於「眉角」節 |

## 警訊

- Explain 輸出混入批評語氣（「這裡設計不好」）而使用者未觸發 Critique
- subagent 貼出大段程式碼而非敘述
- 「運作方式」節只有 bullet points、沒有敘述流
- Critique 四類中出現標記為「無」的空類別，而非整類略去
- 主 agent 未 spawn subagent，直接在主 context 探索
- 使用者問題涵蓋三個以上子系統或整個 repo 架構，但主 agent 未在步驟 1 宣告中切出可執行子集

## 驗證

- [ ] 已判定模式（Explain / Critique）並在開始前宣告
- [ ] Explain 輸出使用 5 節模板，非每節必寫但寫出的都用繁中台灣用語
- [ ] 檔案路徑與函式名以具體形式出現（可跳過去看），未用模糊描述
- [ ] 若觸發 Critique：四類格式正確，Dismissed 項目有列出並附理由
- [ ] 全程未存檔，純 chat 輸出
- [ ] 未產出 README / INSTALLATION / 其他以人類為對象的文件

## 錯誤處理

- 若 subagent 返回內容偏離 5 節模板：主 agent 重整輸出格式即可，不再重跑 subagent。
- 若 critic 提出意見超出架構層（例如風格抱怨、命名）：歸入「不採納」並註明理由。
- 若關鍵 keyword 邊界模糊（例如「這個設計怎麼樣」）：預設走 Explain；使用者在看到結果後若要求批評，再接續 Critique。
- 若 subagent 因權限或工具缺失回報失敗：主 agent 改用 Glob / Grep / Read 在主 context 直接探索，並在輸出開頭註明「subagent 不可用，改主 context 執行，可能較精簡」。
