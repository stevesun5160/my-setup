# Vertical Slice 規則

參考來源：Matt Pocock `to-issues`、Addy Osmani `planning-and-task-breakdown`

## 定義

Vertical slice 是一條穿越所有整合層的端對端功能路徑，完成後可獨立交付與展示。

```
Vertical slice（正確）           Horizontal slice（避免）
──────────────────────          ───────────────────────
UI  ──┐                         Issue 1：DB schema
API   ├── 一個 slice              Issue 2：API endpoints
DB  ──┘                         Issue 3：UI components
```

## 切分規則

1. **可交付性**：完成的 slice 必須可獨立 demo 或驗證。
2. **N US : 1 sub-issue**：多個 User Stories 若共享同一條 end-to-end path，合併成一個 slice。
3. **薄優於厚**：偏向切多個薄 slice，而非少數幾個厚 slice。
4. **Layer 中性**：Slice 標題描述使用者可見的行為，不描述實作 layer。

## 禁止事項

- Slice 標題只包含單一 layer 名稱（e.g., "新增 DB migration"、"建立 API endpoint"、"實作 UI component"）
- Slice 在未完成另一個 slice 的情況下無法測試（除非 dependency 已明確標注）
- 每個 User Story 各自對應一個 slice（當多個 US 共享同一條 path 時）

## Dependency 建立順序

依 blocker 優先順序建立，確保「Blocked by #N」可填入真實 issue number。無 blocker 的 slice 可立即開始。

## 粒度參考

| 訊號 | 建議動作 |
|------|---------|
| 單一 slice 的 AC 超過 5 條 | 考慮拆分 |
| 兩個 slice 的 AC 重疊超過 50% | 考慮合併 |
| Slice 需要修改 module interface | 標注並建議先開 `/ito-refactor` |
