# Refactor 階段 Checklist

本檔作為資料來源，供 `SKILL.md` 步驟 4（Refactor）讀取。內容為進入 refactor 前的前置條件、可執行的動作清單、執行順序與範例。

## 前置條件

執行 refactor 前，下列項目必須全部成立：

- [ ] 全套 test 均為 GREEN。
- [ ] 最近一次的 RED 階段已結束（禁止在 RED 狀態下做 refactor）。
- [ ] 有可快速執行的測試指令（refactor 每一步都要跑測試）。

任一項不成立就停止 refactor，先把 test 帶回 GREEN 再評估。

## 執行順序

refactor 動作由小到大逐步進行，每一步完成後立即執行全套測試：

1. **Rename**：變數／method／class 名稱不精準 → 重新命名。風險最低，優先執行。
2. **Extract**：重複出現或語意獨立的片段 → 抽成 function 或 method。
3. **Inline**：只作 pass-through 的 wrapper 層 → 拆掉。消除無價值的間接。
4. **Move**：某段職責放錯地方 → 搬到正確的 class 或 module。
5. **Deepen module**：介面相對內部實作太寬 → 把更多邏輯封裝進去、縮小介面。讀取 `references/interface-design.md` 以提取 deep modules 原則。
6. **Split／Merge**：class 或 module 職責過雜 → 拆分；過碎 → 合併。

## 每一步後的強制動作

```text
做一個 refactor 動作
  → 立即跑全套測試
    → 仍為 GREEN：繼續下一步
    → 出現 RED：revert 該動作，不要修改 test 來遷就
```

禁止連續做多個 refactor 再一起跑測試。這會讓反饋粒度變粗，測試失敗時難以定位是哪一步動作造成。

## 常見 refactor 動作範例

### Rename：訊息模糊 → 語意明確

例：`calc(u, o)` → `calculateMemberDiscount(user, order)`。命名帶出意圖，無須讀內部即可判斷用途。

### Extract：重複邏輯抽出

多處 method 開頭重複 `if (order.total <= 0) throw ...`，抽成 `assertPositiveTotal(order)` 供各處呼叫，重複敘述集中到一個斷言點。

### Deepen module：介面縮、實作深

```ts
// before：淺模組，呼叫端得自己記住步驟順序
class OrderApi {
  validate(o: Order) { /* ... */ }
  reserve(o: Order) { /* ... */ }
  charge(o: Order) { /* ... */ }
  commit(o: Order) { /* ... */ }
}
// 呼叫端：api.validate → reserve → charge → commit

// after：深模組，一個 public 介面吞掉全部步驟
class OrderApi {
  async place(o: Order): Promise<PlaceResult> {
    this.validate(o);
    await this.reserve(o);
    await this.charge(o);
    return this.commit(o);
  }
  private validate(o: Order) { /* ... */ }
  private async reserve(o: Order) { /* ... */ }
  private async charge(o: Order) { /* ... */ }
  private async commit(o: Order) { /* ... */ }
}
```

呼叫端只需要 `api.place(order)`，內部順序與錯誤處理封裝在實作裡。

## 禁止事項

- **RED 狀態下 refactor**：不允許。先回到 GREEN 再考慮。
- **修改 test 來遷就 refactor**：refactor 的定義是「behavior 不變、結構改變」。如果必須改 test 才能通過，代表這次動作實際上改變了 behavior，應立即取消。
- **一次做多項動作**：同時 rename＋extract＋move，測試失敗時無法定位是哪一步出錯。
- **在 refactor 中新增 behavior**：新 behavior 必須走 RED → GREEN，不屬於 refactor。

## Refactor 收斂訊號

出現以下任一情況時，停止 refactor，回到 Incremental Loop 下一條 behavior：

- 繼續 refactor 已無法產生明顯的可讀性、封裝性或可擴充性改善。
- 每次動作都在增加抽象層，卻沒有實際需求驅動（過度設計訊號）。
- 已經完成 3–5 個 refactor 動作，且整套 test 維持 GREEN——表示該階段已達可接受狀態，進下一條 behavior。

## 常見藉口與反駁

| 藉口 | 反駁 |
|---|---|
| 「一次改完比較快」 | 測試失敗時的定位成本遠高於分步節省的時間，也失去了每一步的 GREEN 保護。 |
| 「這個 refactor 順便多改一點 behavior」 | 混合 refactor 與新 behavior 會讓測試無法區分 regression 的來源。新 behavior 必須走 RED。 |
| 「test 失敗就改一下 test 就好」 | refactor 的定義是「behavior 不變、結構改變」。需要改 test 代表 behavior 已經變了，不是 refactor。 |
