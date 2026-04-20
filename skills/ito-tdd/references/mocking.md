# Mocking 哲學與優先序

本檔作為資料來源，供 `SKILL.md` 在 Tracer Bullet、Incremental Loop 或 Bug 流程中遇到外部依賴時讀取。內容為 mocking 的判斷原則、替代方案優先序、反模式與 TypeScript 範例。

## 核心哲學：驗 behavior，不驗 interaction

test 的主體是「系統對外產生什麼結果」，不是「系統內部呼叫了誰幾次」。過度 mock 會把 test 牢牢綁在 implementation 上：內部結構一換，test 就失敗，但 behavior 其實沒變。

- **好 test**：只關心輸入 → 輸出、狀態變化、可觀察的副作用。
- **壞 test**：主要斷言是「某個 mock 被呼叫幾次、帶了什麼參數」；覆蓋率看起來很高，但經不起 refactor。

判斷啟示：**如果 refactor 內部結構會讓大量 test 失敗，但 behavior 並沒有改變，代表 test 過度依賴 mock**。

## 優先序：real → fake → stub → mock

當需要替換依賴時，依這個順序逐一評估；越上面的選項越貼近真實行為，test 越能驗證有意義的事。

### 1. Real（真實依賴）

直接使用實際依賴，不做任何替換。適用情境：

- 純函式、純 value object。
- 可以安全在 test 中執行的 in-memory 工具（例如 in-memory 資料庫、本地起的 test container）。
- 執行成本低、沒有外部副作用的依賴。

### 2. Fake（有行為的替身）

自行實作一個輕量替身，保留真實依賴的行為語意，但拿掉外部連線或高成本操作。適用情境：

- Repository、gateway 類依賴，需要行為（存／取／更新）但不需要真實資料庫或網路。
- 想驗證「寫入依賴後能讀回」這類後果型 behavior。

```ts
// InMemoryOrderRepository 是 fake：有行為（存／取）但不連真 DB
class InMemoryOrderRepository implements OrderRepository {
  private store = new Map<string, Order>();
  async save(order: Order) { this.store.set(order.id, order); }
  async findById(id: string) { return this.store.get(id) ?? null; }
}

test('下單後可透過 id 取回', async () => {
  const repo = new InMemoryOrderRepository();
  const service = new OrderService(repo);
  const order = await service.place({ total: 100 });
  const fetched = await repo.findById(order.id);
  expect(fetched?.total).toBe(100);
});
```

fake 讓 test 能驗證「後果」而非「呼叫」；fake 本身寫一次即可供多個 test 共用。

### 3. Stub（回傳固定值）

僅負責提供固定輸入，不驗證互動。適用情境：

- 依賴無法做成 fake，且 test 只需要某個特定輸入條件（例如模擬特定時間、特定 feature flag 值）。
- 依賴的真實實作成本太高（遠端 API、付費服務），而 test 只想驗證系統在該輸入下的行為。

```ts
test('付款 gateway 回 success 時，訂單狀態變 paid', async () => {
  const gatewayStub: PaymentGateway = {
    charge: async () => ({ ok: true, transactionId: 'tx_1' }),
  };
  const service = new OrderService(gatewayStub, new InMemoryOrderRepository());
  const result = await service.place({ total: 100 });
  expect(result.status).toBe('paid');
});
```

stub 只負責「提供輸入」，不負責「驗證互動」。

### 4. Mock（驗證互動）

帶有「驗證被呼叫」能力的替身。只在以下兩個條件同時成立時才使用：

- 要驗證的 behavior 本身就是「對外系統產生副作用」（例如「有寄出通知 email」「有送出 analytics 事件」）。
- 該副作用無法透過系統輸出或可查詢狀態觀察（無回傳值、無狀態可查）。

```ts
import { vi, expect, test } from 'vitest';

test('訂單完成後寄送通知 email', async () => {
  const mailer = { send: vi.fn() };
  const service = new OrderService(new InMemoryOrderRepository(), mailer);
  await service.complete('order_1');
  expect(mailer.send).toHaveBeenCalledWith(
    expect.objectContaining({ subject: '訂單完成' })
  );
});
```

即便走到 mock，斷言焦點仍應放在**對外可觀察的行為**（email 真的被寄出、訊息內容正確），而不是內部 method 的呼叫細節。

## 判斷流程

1. 這個依賴能不能用 real？→ 可以則用 real，結束。
2. 無法用 real：有沒有 in-memory fake，或是容易寫一個？→ 有則用 fake。
3. 無法 fake：test 只需要依賴回傳固定輸入嗎？→ 是則用 stub。
4. 以上都不行，且 behavior 本身就是「對該依賴產生互動」→ 才用 mock。

如果走到第 4 步仍覺得 test 脆弱、refactor 後容易失敗，回頭檢視要驗證的究竟是 behavior，還是其實驗到了 implementation。

## 反模式

- **Mock 氾濫**：每個依賴都 mock，test 變成「呼叫順序的快照」；refactor 時得先改 test 才能改 code，違反 TDD 的反饋方向。
- **Mock 自己擁有的 value object**：`User`、`Order` 這類 domain object 直接建構即可，不需要替身。
- **Partial mock**：在同一個 class 上 mock 部分 method、保留其他為真；test 的語意變得模糊、邊界不清。要替換就替換整個 interface。
- **以 call count 作為主斷言**：`toHaveBeenCalledTimes(1)` 絕大多數時候是 implementation 斷言。除非「呼叫次數」本身就是 behavior（例如「失敗後重試三次」），否則不應成為主斷言。

## 常見藉口與反駁

| 藉口 | 反駁 |
|---|---|
| 「mock 寫起來最快」 | 當下最快，維護最貴。real 與 fake 讓 test 面對真實 behavior，長期節省 refactor 成本。 |
| 「fake 要自己寫一份實作，太麻煩」 | fake 寫一次可供所有相關 test 共用。相較於 mock 散落在每個 test、每次 refactor 都要同步更新，一次性成本反而更低。 |
| 「mock 才能確認某個 method 被呼叫」 | 如果「被呼叫」並非對外可觀察的 behavior，就不應該成為 test 的斷言目標。重新檢視要驗證的究竟是什麼 behavior。 |
