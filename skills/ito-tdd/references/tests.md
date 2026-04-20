# Behavior-focused Tests：模式與範例

本檔作為資料來源，供 `SKILL.md` 的 Tracer Bullet、Incremental Loop、Bug 流程讀取。內容為「好 test」的判斷原則、命名模式、以及 TypeScript／React／NestJS 範例。

## 好 test 的判斷標準

一條 test 要同時符合下列全部條件才算合格：

- **驗 behavior 而非驗 implementation**：描述「系統對外做了什麼」，不是「系統內部怎麼做」。
- **透過 public interface 驗證**：由對外 API、元件 render 輸出、HTTP response 等可觀察面向做斷言。
- **能 survive refactor**：內部結構改動（rename、搬檔、extract／inline）後，test 仍應通過。
- **一次只驗一件事**：test 名稱一句話講得完；斷言集中，失敗訊息能直接指向壞掉的那條行為。
- **寫出時能觀察到 RED**：初次寫成時先看到失敗，並確認失敗訊息符合預期，才算真的鎖定目標行為。

## 命名模式

test 名稱採「情境 + 觸發 + 預期」三段式，每一段都具體可讀。

**合格的命名**：

- 「gold 會員下單時對總價打 8 折」
- 「付款 gateway timeout 時訂單狀態保持 pending」
- 「購物車為空時送出訂單回傳 invalid_order 錯誤」

**不合格的命名**：

- 「test OrderService」——太籠統，既沒指明情境也沒指明行為。
- 「should work」——完全沒有資訊量。
- 「呼叫 save 後 repository.save 被呼叫一次」——描述的是 implementation，不是 behavior。

## DAMP over DRY

test 的程式碼應該讀起來像規格書；閱讀上的重複比過度抽象更有價值。

- **DAMP（Descriptive And Meaningful Phrases）**：每一條 test 盡量自成完整故事，讀者不必跳到其他地方拼湊情境。
- **DRY 僅適度使用**：可以抽出資料建構工具（例如 `createValidOrder`、`renderWithProviders`）供多處重用，但不要把 test 層級的共用流程包成「跑某某情境」這種高階封裝。

```ts
// ❌ 過度 DRY：讀者看不到這個 test 在驗什麼
test('下單情境', () => {
  runScenario('gold-member-with-discount');
  expectResult(80);
});

// ✅ DAMP：一眼看出情境
test('gold 會員下單時對總價打 8 折', () => {
  const user = { id: 'u1', tier: 'gold' as const };
  const order = { id: 'o1', total: 100 };
  const result = applyMemberDiscount(order.total, user.tier);
  expect(result).toBe(80);
});
```

## 範例：React 元件（behavior via render）

透過 render 輸出與使用者互動驗證元件 behavior，不碰內部 state 或 props 細節。

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { PriceTag } from './PriceTag';

describe('PriceTag', () => {
  test('gold 會員看到折扣後價格', () => {
    render(<PriceTag item={{ price: 100 }} user={{ tier: 'gold' }} />);
    expect(screen.getByText('80')).toBeInTheDocument();
  });

  test('一般會員看到原價', () => {
    render(<PriceTag item={{ price: 100 }} user={{ tier: 'regular' }} />);
    expect(screen.getByText('100')).toBeInTheDocument();
  });

  test('點擊「套用會員價」按鈕後切換為折扣顯示', async () => {
    const user = userEvent.setup();
    render(<PriceTag item={{ price: 100 }} user={{ tier: 'gold' }} />);
    await user.click(screen.getByRole('button', { name: '套用會員價' }));
    expect(screen.getByText('80')).toBeInTheDocument();
  });
});
```

應避免：

- `expect(component.state('price')).toBe(80)`——驗到了 internal state。
- `expect(useDiscount).toHaveBeenCalled()`——驗到了 hook 的呼叫細節（implementation detail）。

## 範例：NestJS service（real + fake）

優先用 real domain object ＋ in-memory fake，非必要不 mock。是否需要 mock 可讀取 `references/mocking.md`。

```ts
import { Test } from '@nestjs/testing';
import { OrderService } from './order.service';
import { OrderRepository } from './order.repository';
import { InMemoryOrderRepository } from './testing/in-memory-order-repository';

describe('OrderService', () => {
  let service: OrderService;
  let repo: InMemoryOrderRepository;

  beforeEach(async () => {
    repo = new InMemoryOrderRepository();
    const module = await Test.createTestingModule({
      providers: [
        OrderService,
        { provide: OrderRepository, useValue: repo },
      ],
    }).compile();
    service = module.get(OrderService);
  });

  test('下單後可透過 id 查到同筆訂單', async () => {
    const created = await service.place({ total: 100 });
    const fetched = await repo.findById(created.id);
    expect(fetched?.total).toBe(100);
  });

  test('下單金額為 0 時回傳 invalid_order 錯誤', async () => {
    const result = await service.place({ total: 0 });
    expect(result).toEqual({ ok: false, reason: 'invalid_order' });
  });
});
```

## 範例：Prove-It（Bug 流程）

為 bug 寫一條能重現的 failing test，是 Prove-It 的起點。

```ts
// bug report：gold 會員折扣在 total 為小數時出現浮點誤差
// 先寫 failing test 重現
test('gold 會員折扣於非整數 total 仍精確', () => {
  expect(applyMemberDiscount(99.99, 'gold')).toBeCloseTo(79.992, 3);
});

// 執行 → 看到 RED（例如實際為 79.99199999999999）
// 修正實作（使用 decimal 運算或四捨五入策略）
// 執行 → GREEN
```

關鍵在於 test 描述「正確的 behavior 應該是什麼」，而不是「目前錯誤的輸出是什麼」。

## 斷言的優先順序

由高到低：

1. **State／output 斷言（最優先）**：`expect(result).toBe(...)`、`expect(fetched).toEqual(...)`。
2. **可觀察的副作用斷言（其次）**：寄出的 email、發出的 HTTP 請求、寫入後再查回的資料。
3. **互動斷言（最後）**：`expect(mock).toHaveBeenCalledWith(...)`。僅在 behavior 本身就是「對外呼叫」、且該副作用無法經由前兩種方式觀察時才使用。

## Anti-patterns

- **一條 test 散射多個斷言**：一次驗 5 件事，失敗時無法定位哪件壞了，應拆成 5 條 test。
- **test 之間互相依賴執行順序**：test A 準備好資料、test B 讀取。每一條 test 都應該自我包含 setup。
- **用 `.skip` 或 `.todo` 佔位**：behavior 尚未實作時不應預先寫 test 佔位。TDD 流程中每一條 test 都應該是可驗證的。
- **以 snapshot 作為主斷言**：快照無法描述 behavior 意圖，僅適合輔助用途（例如複雜 render 結構的 regression 檢查）。
- **繞過 domain layer 直接查 DB**：應透過 service 或 repository 的 public method 驗證資料，而不是直接對資料庫下查詢。

## 常見問題

- **「一條 test 同時驗多件事比較節省」**：短期看是，長期維護成本高。失敗時的定位成本與閱讀成本都會上升。
- **「測 public interface 需要準備好多 fixture」**：是。這種情況可抽出 builder 函式（例如 `createValidOrder`、`createGoldUser`），服務於 test 本身，而不是 production code。
- **「React hook 要不要單獨 test」**：hook 屬於 implementation detail，優先透過使用該 hook 的元件驗證 behavior。除非該 hook 是對外公開的 library API，才另當別論。
