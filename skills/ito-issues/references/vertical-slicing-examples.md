## 用途

提供 vertical vs horizontal slicing 的對照範例。從本檔提取範例格式，在步驟 3 推理 slice 切分時作為判斷基準。

## Bad: Horizontal slicing

以層為單位切，每個 task 只完成一個技術層，合起來才能交付功能：

```
Task 1: 建立所有 database schema
Task 2: 建立所有 API endpoints
Task 3: 建立所有 UI components
Task 4: 串接所有層
```

**為什麼不好：**
- 單一 task 完成後無法 demo、無法驗證整體行為
- 整合風險集中在最後一個 task，爆炸半徑大
- 多人併行時前面的 task 完成但後面卡住，時間浪費

## Good: Vertical slicing

每個 slice 切穿所有層（schema + API + UI + tests），交付一個端到端的使用者行為：

```
Task 1: 使用者可以註冊帳號（註冊相關的 schema + API + UI）
Task 2: 使用者可以登入（登入相關的 auth schema + API + UI）
Task 3: 使用者可以建立任務（任務建立的 schema + API + UI）
Task 4: 使用者可以檢視任務列表（查詢用的 query + API + UI）
```

**為什麼好：**
- 每個 slice 完成即可獨立 demo / verify
- 整合風險分散到每個 slice，早期暴露
- 任一 slice 完成都是 shippable 的進度

## 判斷基準

| 基準 | 問題 |
|------|------|
| 可獨立 demo | 完成此 slice 後，能不能不靠其他未完成 slice 就展示一個完整行為？ |
| 穿透所有層 | 此 slice 是否觸及 schema / API / UI / test（視 PRD 範圍適用的層）？ |
| 薄但完整 | 能否再切薄一點，且切後每片仍可獨立 demo？若可，就該切 |

若 slice 無法通過「可獨立 demo」檢驗，代表是 horizontal，回步驟 3 重切。

## 例外：單層 PRD

若 PRD 只涉及單一層（純 CSS 調整、純文件改動、純 config），vertical slicing 的概念不適用。此時 slice = commit-size task，用工作量或行為邊界切分即可，不強求穿透多層。
