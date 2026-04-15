# Commit 計畫輸出模版

所有文字（commit message、改動描述、標籤）皆須使用當次確認的語言，不得混用。

---

## 標準模式（多個 commits）

**中文：**
```
Commit 計畫：

📦 Commit 1: <type>(<scope>): <message>
詳細內容：
- <改動描述 1>
- <改動描述 2>
檔案：
- path/to/file1
- path/to/file2

📦 Commit 2: <type>(<scope>): <message>
詳細內容：
- <改動描述>
檔案：
- path/to/file3
```

**English:**
```
Commit Plan:

📦 Commit 1: <type>(<scope>): <message>
Changes:
- <change description 1>
- <change description 2>
Files:
- path/to/file1
- path/to/file2

📦 Commit 2: <type>(<scope>): <message>
Changes:
- <change description>
Files:
- path/to/file3
```

---

## 快速模式（單一 commit）

**中文：**
```
📦 <type>(<scope>): <message>
詳細內容：
- <改動描述 1>
- <改動描述 2>
檔案：
- path/to/file1
- path/to/file2
```

**English:**
```
📦 <type>(<scope>): <message>
Changes:
- <change description 1>
- <change description 2>
Files:
- path/to/file1
- path/to/file2
```

---

## Conventional Commits type 對照

| type | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修 bug |
| `docs` | 文件變更 |
| `style` | 格式調整（不影響邏輯） |
| `refactor` | 重構（非新功能、非 bug fix） |
| `test` | 新增或修正測試 |
| `chore` | 建構系統、依賴更新等雜務 |
| `ci` | CI/CD 設定 |
