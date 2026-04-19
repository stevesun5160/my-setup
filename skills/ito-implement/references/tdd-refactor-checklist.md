# TDD Refactor Checklist

測試全綠後執行 refactor 審視。每次修改後重跑 test runner 確認仍為綠。
**絕不在 red 狀態下 refactor。**

## 步驟一：四個主要方向

逐項檢查是否有重構機會：

1. **Extract duplication**：是否有重複邏輯可以提取？
2. **Deepen modules**：是否可以將複雜度移到更簡單的 interface 後面？（見 `tdd-deep-modules.md`）
3. **Apply SOLID principles**：是否有自然的 SOLID 機會（不強求）？
4. **Consider what new code reveals**：新加的 code 是否揭示了既有 code 的設計問題？

## 步驟二：Code Smell 掃描

若步驟一有發現，進一步對照以下 code smells 確認重構範圍：

| Code Smell | 說明 |
|---|---|
| **Duplication** | 重複的 code block |
| **Long Methods** | 方法做太多事 |
| **Large Classes** | class 職責過多 |
| **Feature Envy** | 方法對另一個 class 的資料比對自己更有興趣 |
| **Primitive Obsession** | 過度使用 primitive，而非小型 object |
| **Data Clumps** | 一群資料總是一起出現，應封裝為 object |
| **Shotgun Surgery** | 一個改動需要在很多地方做小修改 |
| **Divergent Change** | 同一個 class 因多種不同原因被修改 |

## 原則

- 每個重構步驟後立即重跑 test runner
- 若無明顯重構機會，直接進下一個行為，不強行重構
