# Deep Modules

來自《A Philosophy of Software Design》

## 定義

**Deep module** = 小 interface + 深實作

```
┌─────────────────────┐
│   Small Interface   │  ← 少數方法，簡單參數
├─────────────────────┤
│                     │
│  Deep Implementation│  ← 複雜邏輯隱藏在內
│                     │
└─────────────────────┘
```

**Shallow module** = 大 interface + 薄實作（避免）

```
┌─────────────────────────────────┐
│       Large Interface           │  ← 方法多，參數複雜
├─────────────────────────────────┤
│  Thin Implementation            │  ← 只是 pass-through
└─────────────────────────────────┘
```

## 與 TDD 的關係

設計 interface 時問：

- 能減少方法數量嗎？
- 能簡化參數嗎？
- 能把更多複雜度藏進去嗎？

Deep module 讓測試更簡單：interface 小 → test setup 少 → 測試更易讀。

## Refactor 時的應用

在 refactor phase，若發現某個 module 是 shallow 的（interface 大但實作薄），這是重構機會：將複雜度下沉到更深的 interface 後面，讓呼叫端的測試更簡單。
