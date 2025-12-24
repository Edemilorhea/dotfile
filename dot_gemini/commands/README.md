# Gemini CLI Custom Commands

這些是針對 Gemini CLI 的自訂指令檔案。

## 安裝方式

### 全域指令 (所有專案可用)
```bash
cp *.toml ~/.gemini/commands/
```

### 專案指令 (僅限當前專案)
```bash
mkdir -p .gemini/commands
cp *.toml .gemini/commands/
```

## 可用指令

| 指令 | 說明 |
|------|------|
| `/consult` | 技術諮詢 - 提供多種方案比較 |
| `/d` | 深入解釋模式 - 完整詳細的技術解釋 |
| `/implement` | 快速實作功能 |
| `/jira` | 產生 Jira worklog |
| `/q` | 極簡回答 (1-3 行) |
| `/review` | .NET 程式碼審查 |
| `/s` | 標準回答 (15-30 行) |
| `/analyze` | 深度程式碼分析 |
| `/ask` | 純問答模式 |
| `/b` | 簡短回答 (5-10 行) |
| `/cif` | 元件實作流程圖 |

## 使用範例

### 極簡回答
```
> /q What is CQRS?
```

### 深入解釋
```
> /d Domain-Driven Design
```

### 程式碼審查
```
> @MyService.cs
> /review
```

### 技術諮詢
```
> /consult Should I use Redis or Memcached for caching?
```

### 產生 Jira worklog
```
> /jira 2024-12-01~2024-12-24 main TC
```

## 參數說明

所有指令都支援 `{{args}}` 參數注入:
- 在 prompt 中使用 `{{args}}` 會被替換為使用者輸入的參數
- 在 shell 指令 `!{...}` 中使用會自動進行 shell escape

## 注意事項

- 檔案遵循 Gemini CLI v1 TOML 格式
- 只包含必要的 `description` 和 `prompt` 欄位
- 已將 `$ARGUMENTS` 替換為標準的 `{{args}}` 格式
