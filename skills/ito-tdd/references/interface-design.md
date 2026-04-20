# Interface Design for Testability

本檔作為資料來源，供 `SKILL.md` 在步驟 4（Refactor）或錯誤處理（測試寫不出來）時讀取。內容為「為可測試而設計的介面」原則、判斷啟示與範例。

## 原則 1：Deep Modules（窄介面、深實作）

好的介面應讓外部只需要知道**做什麼**，內部封裝**怎麼做**。

- **窄介面（small interface）**：對外只暴露少量 method 或 property，每一個都有明確語意。
- **深實作（deep implementation）**：內部吸收複雜度（邊界條件、狀態轉換、分支處理），不向外滲漏。

相對的**淺模組**是反模式：對外介面比內部邏輯還肥大，幾乎是基本型別的 pass-through。這種 module 無法為 test 提供保護，因為它沒有封裝任何決策。

### 判斷啟示

- 對外 method 的數量比內部實作 method 還多 → 淺模組訊號。
- 每個對外 method 幾乎只是 delegate 給另一層，沒有做任何決策或轉換 → 淺模組。
- 寫一條 test 需要大量 setup、替換多個依賴才能驗證一件小事 → 介面切得太大、或封裝不足。

## 原則 2：所有 behavior 都能透過 public interface 觀察

如果某條 behavior 只能透過窺探 private 欄位、或驗證 method 被呼叫幾次才能確認，代表介面設計有缺陷。常見調整方向：

- 把副作用改寫為明確的回傳值。
- 把內部狀態改寫為可查詢的 method（例如狀態查詢、snapshot 輸出）。
- 把隱含的觸發條件改寫為明確的輸入參數。

## 原則 3：以依賴注入取代內部 new

test 必須能替換外部依賴。讓依賴透過建構子或函式參數注入，不要在內部直接 `new` 或直接讀全域設定。

### 反模式（難測試）

```ts
class OrderService {
  async place(order: Order) {
    const gateway = new PaymentGateway(process.env.PAYMENT_KEY);
    return gateway.charge(order.total);
  }
}
```

test 被迫 mock `PaymentGateway` 的 constructor 或 mock `process.env`，整段測試會緊緊耦合到實作細節。

### 正模式（可注入、易驗 behavior）

```ts
// NestJS 範例
@Injectable()
export class OrderService {
  constructor(private readonly gateway: PaymentGateway) {}

  async place(order: Order): Promise<PaymentResult> {
    return this.gateway.charge(order.total);
  }
}
```

test 可將 `PaymentGateway` 換成 real、fake 或 stub，完全不需要碰 `OrderService` 內部。

## 原則 4：輸入最小化

函式或 method 只接收自己真的會用到的欄位，不要整個 domain object 照收。例如折扣計算只需要 `(tier, subtotal)`，不需要把整個 `User` 與 `Order` 傳進來。test 不必建構完整 domain object，介面本身也自證「此函式只受這兩個輸入影響」。

## 原則 5：純函式優先

能純函式化的邏輯不要包進有狀態的 class。純函式天然可測——同輸入同輸出、無外部依賴。

- 計算、驗證、轉換類邏輯：優先寫成純函式。
- 需要 persistence、I/O、或外部副作用：隔離到薄薄一層 boundary layer（adapter 或 repository），把核心邏輯留在純函式。

### 範例（React 元件的邏輯抽離）

```ts
// 不好測：邏輯與 component 綁死
function PriceTag({ item, user }: Props) {
  const price = user.tier === 'gold'
    ? item.price * 0.8
    : item.price;
  return <span>{price}</span>;
}
```

```ts
// 好測：純函式分離
export function applyMemberDiscount(price: number, tier: MembershipTier): number {
  return tier === 'gold' ? price * 0.8 : price;
}

function PriceTag({ item, user }: Props) {
  return <span>{applyMemberDiscount(item.price, user.tier)}</span>;
}
```

折扣邏輯可獨立 unit test，不必 render 整個元件。

## 原則 6：錯誤情境在介面上明示

錯誤不該只靠拋出未分類的 `Error`。把可能的錯誤情境明示在回傳型別上，test 才能逐一列舉並驗證每條錯誤路徑。

```ts
type PlaceResult =
  | { ok: true; transactionId: string }
  | { ok: false; reason: 'insufficient_funds' | 'gateway_timeout' };
```

相較於「`Promise<string>` + 拋錯」的風格，這種介面能讓 test 直接對 `reason` 做斷言，不必依賴 `try/catch` 與錯誤訊息字串比對。

## 常見問題

- **「介面開太窄，未來擴充不方便」**：TDD 的 refactor 階段就是為了擴充而存在。先開窄、需要時再擴，勝過預先開一堆卻沒被驗證過的 method。
- **「依賴注入讓建構子參數過多」**：如果一個 class 的依賴多到建構子臃腫，代表該 class 承擔了太多職責，應該拆分。這是介面設計的訊號，不是 DI 的缺點。
- **「純函式處理不了 I/O」**：正確。把 I/O 推到邊界（adapter／repository），核心邏輯保持純函式，測試焦點放在核心。
