# 任務格式模板

本地 Markdown 中每個垂直 slice 任務使用以下格式。

---

## Task：[使用者可見行為（跨層說明，例：schema + API + UI）]

**描述：** 一段說明此 slice 做什麼、貫穿哪些層（schema、API、UI、tests），完成後使用者可驗證什麼。

**驗收條件：**
- [ ] [具體可測試的條件]
- [ ] [具體可測試的條件]
- [ ] [具體可測試的條件]

**Blocked by：** 本地草稿填任務標題或「無」。推 GitHub 後改為 #<issue-number>

**預計碰的檔案：**
- `path/to/file.ts`
- `path/to/test.ts`

**Size：** XS / S / M / L（草稿可暫標 XL 表示需再拆，最終確認後不可有 XL）

---

## ✅ Checkpoint：[里程碑名稱]

確認以下條件後再繼續：
- [ ] [可驗證的條件]
- [ ] [可驗證的條件]

---

## Size 速查

| Size | 觸碰檔案數 | 範例 |
|------|----------|------|
| XS | 1 | 新增一條驗證規則 |
| S | 1–2 | 新增一個 API endpoint |
| M | 3–5 | 一個完整 feature slice |
| L | 5–8 | 多元件跨模組功能 |
| XL | 8+ | 太大，須再拆 |
