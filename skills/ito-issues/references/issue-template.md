## 用途

提供 sub-issue body 的固定結構樣板。從本檔提取 markdown 模板，將 `<placeholder>` 替換為該 slice 的實際內容。

## 模板

```markdown
## 父 Issue

#<parent-issue-number>

## 功能範圍

<一段端到端行為描述，說明這個 vertical slice 完成後從使用者觀點看到的效果。不要 layer-by-layer 拆法，不要描述實作細節。>

## 驗收條件

- [ ] <條件 1：可被驗證的具體行為或產出>
- [ ] <條件 2>
- [ ] <條件 3>

## Blocked by

- Blocked by #<issue-number>

或 "None - 可立即執行"
```

## 填寫準則

- **父 Issue**：填 PRD issue 號碼，保留 `#` 前綴
- **功能範圍**：以使用者看得到的行為撰寫；若只能描述出內部實作（例如「新增一個 function」），代表 slice 可能是 horizontal，應回步驟 3 重切
- **驗收條件**：每條必須可獨立驗證，偏好從 PRD 原有 User Story 的驗收條件複製並收斂到本 slice 範圍；至少 2 條
- **Blocked by**：只列直接依賴，不列遞迴依賴；若此 slice 無依賴，填 `None - 可立即執行`
