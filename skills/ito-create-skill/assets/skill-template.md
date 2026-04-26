---
name: [skill-name]
description: [以第三人稱陳述此 skill 的功能]。適用於 [trigger 1]。適用於 [trigger 2]。不適用於 [明確的負面觸發條件]。上限 250 Unicode 字元。
---

# [Skill 標題]

## 概覽

[一至兩句話：此 skill 做什麼、為何重要。陳述成果而非機制。]

## 使用時機

- [正向觸發條件 1——問題、任務類型或請求模式]
- [正向觸發條件 2]
- [正向觸發條件 3]

**不應使用的情況：** [明確排除項——看似相似、但應路由至他處的相鄰任務。]

## 核心流程

### 步驟 1：[行動階段名稱]

1. [以第三人稱祈使句撰寫的指示，例：「擷取 query parameters⋯」]
2. [引用 asset 的指示，例：「讀取 `assets/template.json` 以建構最終輸出。」]

### 步驟 2：[行動階段名稱]

1. [決策樹／條件，例：「若需要 source maps，執行 `scripts/build.sh`；否則跳至步驟 3。」]
2. [JIT 載入的 reference，例：「讀取 `references/auth-flow.md` 以對應具體的 error code。」]
3. 執行 `python scripts/[script-name].py` 以 [進行確定性動作]。

### 步驟 3：[行動階段名稱]

1. [步驟]
2. [步驟]

## 常見合理化藉口

| 合理化藉口 | 實際情況 |
|---|---|
| [agent 用來跳過步驟的藉口] | [事實反駁——點明跳過的具體代價] |
| [藉口 2] | [反駁 2] |

## 警訊

- [skill 遭違反時可觀察到的徵兆]
- [審查時要留意的行為]
- [顯示流程被走捷徑的產出型態]

## 驗證

- [ ] [結束條件附具體證據，例：「所有測試通過：`npm test` 回傳 0」]
- [ ] [結束條件，例：「螢幕截圖儲存於 `assets/verify.png`」]
- [ ] [結束條件，例：「無跳過或停用的測試」]

## 錯誤處理

- 若 `scripts/[script-name].py` 因 [特定邊界情境] 失敗，執行 [還原步驟]。
- 若 [發生條件 B]，讀取 `references/[troubleshooting-file].md`。

## 延伸參考

- [以名稱交叉引用其他 skill，不重複內容，例：「遵循 `test-driven-development` 撰寫測試。」]
- [連結到 `references/[deep-dive].md` 以取得延伸背景。]
- [連結到 `assets/[template].md` 以取得延伸背景。]
- [連結到 `scripts/[script].md` 以取得相關腳本。]
