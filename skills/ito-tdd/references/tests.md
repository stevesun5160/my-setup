# 好測試與壞測試

## 好測試

**整合式**：透過真實介面測試，不 mock 內部元件。

```typescript
// GOOD：測試可觀察的行為
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

特徵：

- 測試使用者或呼叫端在意的行為
- 只使用公開 API
- 能存活內部重構
- 描述「做什麼」而非「怎麼做」
- 每個測試一個邏輯斷言

## 壞測試

**實作細節測試**：耦合內部結構。

```typescript
// BAD：測試實作細節
test("checkout calls paymentService.process", async () => {
  const spy = vi.spyOn(paymentService, 'process');
  await checkout(cart, payment);
  expect(spy).toHaveBeenCalledWith(cart.total);
});
```

警訊：

- Mock 內部協作者
- 測試私有方法
- 斷言呼叫次數或順序
- 重構時測試失敗但行為沒變
- 測試名稱描述「怎麼做」而非「做什麼」
- 繞過介面直接驗證外部狀態

```typescript
// BAD：繞過介面驗證
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD：透過介面驗證
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

---

# 何時 Mock

只在**系統邊界**處 mock：

- 外部 API（金流、Email 等）
- 資料庫（偶爾，偏好用測試 DB）
- 時間或亂數
- 檔案系統（偶爾）

不要 mock：

- 你自己的 class 或 module
- 內部協作者
- 任何你能控制的東西

## 為可 mock 性設計

在系統邊界處，設計容易 mock 的介面：

**1. 使用 dependency injection**

把外部依賴傳入，而非在內部建立：

```typescript
// 容易 mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// 難以 mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. 偏好 SDK-style 介面而非通用 fetcher**

為每個外部操作建立獨立函式，而非一個帶條件邏輯的通用函式：

```typescript
// GOOD：每個函式可獨立 mock
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD：mock 需要在內部寫條件邏輯
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

SDK-style 的好處：每個 mock 只回傳一種 shape，測試設置不需要條件邏輯，容易看出一個測試使用了哪些 endpoint，且每個 endpoint 有型別安全。

---

# 寫好測試的實務守則

## DAMP 優先於 DRY

Production code 裡 DRY 通常是對的。在測試裡，**DAMP（Descriptive And Meaningful Phrases）** 更重要，每個測試應自給自足，不需要讀者追蹤共用 helper 才能理解在測什麼。

## AAA Pattern

```typescript
it('截止日期過後標記任務為逾期', () => {
  // Arrange：設置測試情境
  const task = createTask({ title: 'Test', deadline: new Date('2024-01-01') });
  // Act：執行被測行為
  const result = checkOverdue(task, new Date('2024-01-02'));
  // Assert：驗證結果
  expect(result.isOverdue).toBe(true);
});
```

## One Assertion Per Concept

```typescript
// GOOD：每個測試驗證一個行為
it('拒絕空白標題', () => { ... });
it('去除標題前後空白', () => { ... });

// BAD：把所有驗證塞進一個測試
it('正確驗證標題', () => {
  expect(() => createTask({ title: '' })).toThrow();
  expect(createTask({ title: '  hello  ' }).title).toBe('hello');
});
```
