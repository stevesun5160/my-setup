---
name: ito-tdd
description: 以 TDD 紅綠重構流程開發新功能或修正 bug。強制先完成 Planning 並取得使用者批准才開始動工；修 bug 時走 Prove-It 變體，先寫能重現問題的 failing test 再改 code。當使用者明確要求「TDD」「先寫測試」「紅綠重構」「Prove-It」或測試先行時觸發。不適用於純 refactor、純 debug、或使用者未要求測試先行的一般實作任務。
---

# ito-tdd

## 概覽

以 tracer bullet 流程執行 TDD：每一回合只寫一個 failing test，再補上剛好足夠讓它通過的實作，逐步逼近完整行為。修 bug 時走 Prove-It 變體，先用 failing test 重現問題再開始修。整個流程強制先完成 Planning 並取得使用者批准，才進入寫 code 階段。

## 使用時機

- 使用者明確說出「TDD」「先寫測試」「紅綠重構」「測試先行」。
- 使用者要求「用 Prove-It 修 bug」或「先寫 failing test 重現再修」。
- 實作新功能，且 behavior 需求已經明確。
- 修 bug 任務，且要求先重現再修。

**不適用情境：** 純 refactor（沒有新 behavior 需要驗證）、純 debug（只需要定位原因，不實際修復）、純讀碼或探索任務、使用者沒有要求測試先行的一般實作任務。

## 核心流程

### 步驟 1：Planning（強制執行）

1. 列出 public interface：輸入參數結構、回傳值結構、錯誤情境的對外表現。只描述對外契約，不描寫內部結構。
2. 列出要驗證的 behavior，一條一句話，句型為「給定 X，當 Y 發生時，預期 Z」。描述的是行為，不是實作步驟。
3. 標註優先序：critical path 與邊界條件排在前面，次要情境排在後面。
4. 如果 interface 或 behavior 寫不出來，代表需求尚未明確；立即停止 skill，請使用者先釐清需求（或自行透過 `/ito-grill` 收斂），不要進入步驟 2。
5. 將步驟 1–3 的 Planning 結果輸出給使用者，並**明確暫停等待批准**。使用者回覆 OK 或等義的確認後，才能進入步驟 2。
6. 如果任務屬於修 bug，跳過本步驟，改走下方「Bug 流程（Prove-It Pattern）」。

### 步驟 2：Tracer Bullet（第一顆曳光彈）

1. 從優先序最高的 behavior 挑 **一** 條作為 tracer。
2. **RED**：為這條 behavior 寫一個 failing test。讀取 `references/tests.md` 以提取 behavior-focused 測試的撰寫模式，以及 TypeScript／React／NestJS 範例。
3. 執行測試框架，確認該 test 確實失敗，而且失敗原因符合預期。如果 test 一寫就通過、或是以非預期的原因失敗，代表它沒有真的驗證到目標行為，必須重寫。
4. **GREEN**：寫出**剛好足夠**讓這條 test 通過的實作。禁止預先處理還沒寫出來的 test。
5. 執行測試，確認該 test 通過，而且沒有讓其他既有 test 失敗。

### 步驟 3：Incremental Loop（每多一條 behavior 重複一次）

對 Planning 清單上剩餘的每一條 behavior，重複 RED → GREEN：

1. 挑下一條 behavior，寫下一個 failing test。
2. 執行測試，確認失敗。
3. 寫出剛好足夠讓它通過的實作。
4. 執行測試，確認整套測試通過。

**守則：**

- 一回合只動一個 test。
- 只寫當前這條 test 需要的 code，不預判下一條 test。
- test 專注在「可觀察的 behavior」，透過 public interface 驗證，不碰 private function 或 internal state。
- 禁止 horizontal slice：不可一次寫完所有 test 再開始寫實作。讀取本檔「常見合理化藉口」章節以理解為何必須拒絕這種作法。

### 步驟 4：Refactor

1. 進入 refactor 之前，確認所有 test 都處於 GREEN。
2. 讀取 `references/refactoring.md` 以提取 refactor 前置條件、動作清單與執行順序。
3. 每完成一個 refactor 動作，立即跑全套測試，確認仍為 GREEN。
4. 如果 refactor 過程中出現測試失敗，立即 revert 該次動作，不要為了遷就 refactor 而修改 test。
5. 如果發現目前 interface 設計不便於擴充或測試，讀取 `references/interface-design.md` 以提取 deep module 與 testability 原則。

**禁止事項：** RED 狀態下禁止 refactor；先回到 GREEN，才能進入 refactor。

### 分支流程：Bug 流程（Prove-It Pattern）

當任務為修 bug 時適用，取代步驟 1–4 的主流程：

1. 閱讀 bug report，定位受影響的 public interface。
2. **RED**：寫一個 failing test 來重現該 bug。test 的描述是「給定重現條件，當觸發時，預期正確的行為」，而不是「預期目前錯誤的輸出」。
3. 執行測試，確認該 test 確實失敗，而且失敗訊息對得上 bug 描述。如果無法重現，代表還沒找到根因；立即停止修復動作，回頭釐清重現條件。
4. **GREEN**：修改 code，讓 failing test 通過。
5. 執行全套測試，確認 bug test 通過，而且沒有讓其他既有 test 失敗。
6. 如果修復過程涉及 mocking 決策，讀取 `references/mocking.md` 以提取優先序與判斷邏輯。

## 具體技巧／模式

- **驗 behavior 而非驗 implementation**：test 透過 public interface 驗證對外行為。如果單純 rename、搬動檔案、或重構內部結構後 test 就失敗，代表它耦合到了實作細節，必須重寫。
- **反 horizontal slice**：不要把所有 test 列完再開始寫實作。這會讓 test 驗證的是「想像中的 behavior」而不是「實際需要的 behavior」。正確作法是 vertical slice：一條 test → 一段實作，下一回合再依上一回合學到的事調整。
- **最小實作**：GREEN 階段只寫剛好足夠讓當前 test 通過的 code。出現「順便把其他分支也寫一寫」的念頭時，停下來，把它留給下一條 test 驅動。
- **參考資料分布**：介面設計原則在 `references/interface-design.md`、mocking 判斷邏輯在 `references/mocking.md`、refactor checklist 在 `references/refactoring.md`、behavior test 模式在 `references/tests.md`。

## 常見合理化藉口

| 合理化藉口 | 實際情況 |
|---|---|
| 「這題太簡單不需要寫 test」 | 沒有 test 的 code path 在後續 refactor 時完全沒有保護，改壞了也不會被發現；長期累積的成本遠高於當下寫一條 test 的成本。 |
| 「先寫實作比較快，等下再補 test」 | 事後補的 test 會貼合現有 code 的形狀，而不是原本的 behavior，變成一張無法偵測 regression 的假安全網。 |
| 「一次把所有 test 寫完再開始實作比較有規劃感」 | 這是 horizontal slice 反模式。一次批次寫出的 test 驗證的是想像中的行為，常出現「behavior 改了但 test 仍通過」或「behavior 沒改但 test 卻失敗」的怪狀況。 |
| 「先 refactor 一下，等一下再把 test 跑回 GREEN」 | RED 狀態下做 refactor 會混淆「這次改壞了」與「還沒寫完」，破壞 TDD 的反饋迴路。必須先回到 GREEN，才能 refactor。 |
| 「直接 mock 最快」 | mock 是最後手段。讀取 `references/mocking.md` 以提取 real → fake → stub → mock 的優先序與判斷邏輯，再決定是否真的需要 mock。 |
| 「bug 先把 code 改好，test 之後再補」 | 這條路徑從來沒驗證過「這條 test 真的能偵測這個 bug」。正確流程是 Prove-It：先寫 failing test 並親眼看到它失敗，才算確認這條 test 真的有鎖定這個 bug。 |

## 警訊

- Planning 步驟被跳過或縮成一句話：違反強制 Planning 規則。
- 使用者還沒批准 Planning 就進入寫 test：違反 user approval 規則。
- 同一回合寫了多個 test：違反「一回合一 test」。
- test 內容檢查 method 被呼叫幾次、驗證 private 欄位、或直接查 DB 驗資料：驗到了 implementation 而不是 behavior。
- test 一寫就通過、完全沒出現 RED 階段：沒有驗證「這條 test 真的能偵測目標行為」。
- GREEN 之後沒接著寫下一條 test，直接寫下一段實作：跳過了 RED 環節。
- Refactor 過程沒有反覆跑測試：失去了 safety net 的保護。
- 修 bug 的 commit 裡只有 code 沒有 test：跳過了 Prove-It。
- 規劃描述中出現「先把所有 test 寫完」：horizontal slice 警訊。

## 驗證

- [ ] Planning 三項（interface、behaviors、priority）皆已列出且使用者已批准。
- [ ] 每一條 behavior 至少對應一條 test。
- [ ] 每條 test 寫出來時都先觀察到 RED，再靠實作變為 GREEN。
- [ ] 所有 test 都只透過 public interface 驗證，沒有碰 private 欄位或 internal state。
- [ ] Refactor 動作僅在全套 test GREEN 時進行，refactor 完成後整套 test 維持 GREEN。
- [ ] 修 bug 時，每一個 fix 都有一條對應的 failing test 先重現問題；該 test 在未修復時失敗、修復後通過。
- [ ] 交付前跑過完整測試並全部通過，沒有被 skip 或 disable 的 test。

## 錯誤處理

- Planning 階段 interface 或 behavior 寫不出來：代表需求尚未明確。停止 skill，建議使用者改用 `/ito-grill` 收斂需求，或自行釐清後再回來執行。
- 第一條 test 寫不出來（想不出怎麼驗）：代表目前 interface 設計不便於測試。讀取 `references/interface-design.md` 以提取 deep module 與 testability 原則，重新設計 interface 後再嘗試。
- bug 寫不出能重現的 failing test：代表尚未找到根因。停止 Prove-It 流程，回頭釐清重現條件，不要直接改 code。
- Refactor 過程讓既有 test 失敗：立即 revert 這次 refactor，不要修改 test 來遷就 refactor。
- test 永遠停在 RED、寫不出能通過的實作：代表 behavior 切得太大。把該 behavior 拆成更小的子 behavior，再從最小的那一條重新開始。
- 改動 behavior 後 test 卻不會失敗：代表該 test 沒有真的綁到 behavior（很可能綁到了實作形狀），必須重寫該 test。

## 延伸參考

- `references/interface-design.md`：為可測試而設計的介面原則（包含 deep modules：窄介面、深實作）。
- `references/mocking.md`：mocking 哲學與優先序（real → fake → stub → mock）的判斷邏輯。
- `references/refactoring.md`：Refactor 階段的前置條件、動作清單、執行順序與範例。
- `references/tests.md`：何謂好的 behavior test，包含判斷標準、命名、斷言模式與 TypeScript／React／NestJS 範例。
