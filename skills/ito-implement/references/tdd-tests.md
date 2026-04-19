# 好測試與壞測試

## 核心原則

測試的來源是 **Acceptance Criteria**，不是實作細節。
每條 AC 描述系統對 caller 承諾的行為，測試就是驗證這個承諾。

## 好測試

透過 public interface 測試可觀察的行為（對應 AC）：

```typescript
// AC：使用者可以用有效購物車結帳
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

特徵：

- 測試名稱直接對應 AC 描述
- 只使用 public API
- 重構內部後仍能通過（行為沒變，測試就不能壞）
- 描述 WHAT，不描述 HOW
- 每個 test 只有一個邏輯斷言

## 壞測試

耦合到實作細節，而非 AC 行為：

```typescript
// 壞：測試內部呼叫關係，不對應任何 AC
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

警示訊號：

- 測試名稱描述 HOW，不描述 WHAT
- Mock 內部 collaborator
- 重構後 test 壞掉，但 AC 行為沒有改變

```typescript
// 壞：繞過 interface 驗證，對應不到任何 AC
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// 好：透過 interface 驗證，對應 AC「建立的使用者可以被查詢」
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```
