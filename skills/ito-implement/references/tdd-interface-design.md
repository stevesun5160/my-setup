# Interface Design for Testability

## 原則

良好的 interface 設計讓 AC 測試自然發生，不需要繞過 interface 或 mock 內部邏輯。

**1. 接受依賴，不在內部建立**

```typescript
// 可測試：依賴從外部傳入
function processOrder(order, paymentGateway) {}

// 難以測試：內部建立外部依賴
function processOrder(order) {
  const gateway = new StripeGateway();
}
```

**2. 回傳結果，不產生 side effect**

```typescript
// 可測試：回傳值可直接斷言
function calculateDiscount(cart): Discount {}

// 難以測試：side effect 難以從 interface 驗證
function applyDiscount(cart): void {
  cart.total -= discount;
}
```

**3. 小 surface area**

- 方法越少，需要的測試越少
- 參數越少，test setup 越簡單

## 與 AC 的對應

若某條 AC 的測試需要大量 setup 或複雜 mock，通常是 interface 設計有問題，不是測試寫法有問題。先修 interface，再寫測試。
