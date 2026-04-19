# Deep Modules

出自《A Philosophy of Software Design》（John Ousterhout）：

**Deep module** = 小型 interface + 大量實作（複雜度隱藏在內部）
**Shallow module** = 大型 interface + 少量實作（呼叫者要知道太多）

---

## Shallow Module 的 Code-Level 偵測訊號

探索 codebase 時，逐一對照以下訊號判斷一個 module 是否為 shallow。

### 1. Pass-Through Method

方法體只有 1–2 行且直接轉發參數，無額外驗證、轉換或聚合邏輯。

```typescript
// shallow：UserService 只是把呼叫轉給 UserRepository，毫無附加價值
@Injectable()
export class UserService {
  constructor(private readonly userRepo: UserRepository) {}

  findById(id: string) {
    return this.userRepo.findById(id); // 純轉發，沒有驗證或轉換
  }

  save(user: User) {
    return this.userRepo.save(user); // 同上
  }
}
```

**偵測重點**：
- 方法體 ≤ 2 行且是純轉發
- 參數列表與底層被呼叫函式相同（無轉換）
- 方法名只是底層函式的別名

---

### 2. Leaky Abstraction（資訊洩漏）

呼叫者必須了解 module 內部狀態或呼叫順序才能正確使用。

```typescript
// shallow：呼叫者要記住 initialize → use → teardown 的順序
const emailService = new EmailService();
await emailService.connect();          // 忘記呼叫 → runtime error
await emailService.authenticate();     // 順序錯 → 靜默失敗
await emailService.send(to, subject, body);
await emailService.disconnect();       // 忘記呼叫 → connection leak

// deep：生命週期管理隱藏在內部
await emailService.send(to, subject, body);
```

**偵測重點**：
- 多個 method 之間存在強制呼叫順序（temporal coupling）
- 文件寫著「must call X before Y」
- 修改此 module 的資料格式，導致其他 module 也需更新（知識重複）

---

### 3. Getter/Setter 氾濫

幾乎所有欄位都有對應的 getter/setter，等同於沒有封裝。

```typescript
// shallow：只是資料容器，業務邏輯全在呼叫者
export class User {
  name: string;
  email: string;
  role: string;
  isActive: boolean;
  // 沒有任何行為 method，呼叫者自行處理所有邏輯
}

// 呼叫者散落著 user.isActive = false; user.role = 'guest' 等直接操作
```

**偵測重點**：
- getter/setter 數量 > 實質行為 method 數量
- Class 沒有私有方法（或只有 1–2 個）
- 業務邏輯散落在呼叫者而非 module 本身

---

### 4. 分散的例外處理

呼叫者需要處理 3 個以上的例外情況，代表 module 沒有將複雜度向內收攏。

```typescript
// shallow：NestJS controller 要自己處理 service 的所有錯誤路徑
async createOrder(@Body() dto: CreateOrderDto) {
  try {
    return await this.orderService.create(dto);
  } catch (e) {
    if (e instanceof InsufficientStockError) throw new BadRequestException(...);
    if (e instanceof PaymentGatewayError) throw new ServiceUnavailableException(...);
    if (e instanceof DuplicateOrderError) throw new ConflictException(...);
    throw new InternalServerErrorException();
  }
}

// deep：service 對外只丟 HTTP-ready exception，controller 不需要知道內部錯誤
async createOrder(@Body() dto: CreateOrderDto) {
  return this.orderService.create(dto); // service 內部統一處理並轉換
}
```

**偵測重點**：
- 單一操作的 try-catch 有 3 個以上分支
- 文件寫著「caller must handle case X, Y, Z」

---

### 5. Interface 寬度遠超實作深度

Public method 數量多，但每個 method 的實作都很短，沒有共享的複雜邏輯。

**偵測重點**：
- public method 數 > 8
- 每個 method 實作 < 5 行
- 沒有共享的資料結構或演算法被多個 method 使用

---

## 對 Slice 切分的影響

發現 shallow module 時：

| 情況 | 建議 |
|------|------|
| Slice 需要修改 shallow module 的 interface | 標注 ⚠️，提示考慮先開 `/ito-refactor` |
| Shallow module 只是讀取，不修改 interface | 可繼續，不需特別處理 |
| Multiple slices 都會觸及同一個 shallow module | 合併成一個 slice，或先重構 module 再切 |

---

## 來源

- John Ousterhout, *A Philosophy of Software Design*, Ch.4–5, Ch.8
- Joel Spolsky, "The Law of Leaky Abstractions" (2002)
- Tushar Sharma, Designite design smell taxonomy
