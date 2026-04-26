# 為 Testability 設計介面

好的介面讓測試自然發生：

1. **接受依賴，不要自己建立**

   ```typescript
   // 可測試
   function processOrder(order, paymentGateway) {}

   // 難以測試
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **回傳結果，不要產生 side effect**

   ```typescript
   // 可測試
   function calculateDiscount(cart): Discount {}

   // 難以測試
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **小介面面積**
   - 更少方法 = 需要更少測試
   - 更少參數 = 更簡單的測試設置

---

# Deep Modules

出自《A Philosophy of Software Design》：

**Deep module** = 小介面 + 大量實作

```
┌─────────────────────┐
│     小介面          │  ← 少量方法，簡單參數
├─────────────────────┤
│                     │
│                     │
│     深度實作        │  ← 複雜邏輯隱藏在內部
│                     │
│                     │
└─────────────────────┘
```

**Shallow module** = 大介面 + 少量實作（避免）

```
┌─────────────────────────────────┐
│           大介面                │  ← 大量方法，複雜參數
├─────────────────────────────────┤
│       薄薄的實作                │  ← 只是簡單帶過
└─────────────────────────────────┘
```

設計介面時問：

- 我能減少方法數量嗎？
- 我能簡化參數嗎？
- 我能把更多複雜度藏進內部嗎？
