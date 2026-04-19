# 何時 Mock

## 原則

只在 **系統邊界** mock，不 mock 自己控制的東西。

**可以 mock：**

- 外部 API（payment、email、SMS 等）
- Database（偏好使用 test DB；若設定困難才 mock）
- Time / randomness
- File system（若設定困難）

**不要 mock：**

- 自己的 class / module
- 內部 collaborator
- 任何自己控制的邏輯

## 設計易於 Mock 的 Interface

若某個 AC 需要 mock 外部服務，在撰寫測試前先確認 interface 設計符合以下規則，才能讓 mock 保持簡單。

**使用 dependency injection，不在函式內部建立外部依賴：**

```typescript
// 容易 mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// 難以 mock（需要 patch 環境變數或 module）
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**偏好 SDK-style interface，而非 generic fetcher：**

```typescript
// 好：每個函式獨立 mockable，測試清楚看到哪個 endpoint 被呼叫
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// 壞：mock 需要條件邏輯，測試難以理解
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

若 interface 設計不符合上述規則，先重構 interface 再寫測試（見 `tdd-interface-design.md`）。
