# 個人偏好設定

## 📚 規則檔案組織

本配置包含以下規則檔案 (透過 `opencode.json` 的 `instructions` 自動載入):

- **WORKFLOW.md**: 工作流程控制、回答詳細程度、工作模式定義、Agent 自動選擇、快取策略
- **CodeStyle.md**: 編程哲學、推理框架、Plan/Code 模式切換、語言風格規範、質量準則

所有規則檔案在 OpenCode 啟動時自動載入並合併到系統提示中。

---

## 語言設定
- 永遠使用繁體中文回答
- 技術名詞中英並列

## 預設行為
- 預設: 回答問題、提供範例、分析程式碼
- 修改: 明確說「幫我改」、「幫我做」才實際修改檔案
- Ask Mode: 輸入「Ask Mode」啟動純問答模式
- 若是需要修改請提供選項式讓我同意或是不同意有方案就每一個方案都要給選項選擇，並且最後會是我要求繼續修改或是取消。

## 權限覆寫規則 (Permission Override Rules)

### 🔓 審批閘門例外 (Approval Gate Exceptions)

**以下命令無需審批，直接執行：**

#### PowerShell 唯讀命令 (Read-Only Commands)
- `Get-ChildItem` 及其所有變體 (`Get-ChildItem *`, `Get-ChildItem -Path ...`, `Get-ChildItem -Recurse`)
- `Get-Content` 及其所有變體
- `Get-Location`, `Get-Date`, `Get-Host`
- `Get-Command`, `Get-Process`, `Get-Service`
- `Test-Path` 及其所有變體
- 所有 `Get-*` Cmdlet (唯讀操作)

#### Unix/Linux 唯讀命令
- `ls` 及其所有變體 (`ls`, `ls *`, `ls -la`, `ls -lah`)
- `pwd`, `whoami`, `hostname`
- `cat`, `head`, `tail`, `less`, `more`
- `find`, `which`, `grep`, `rg`, `ag`
- `echo`, `printenv`, `env`, `date`

#### Git 唯讀命令
- `git status`, `git diff`, `git log`, `git show`
- `git branch`, `git remote`, `git config --get`, `git config --list`

#### 開發工具版本查詢
- `dotnet --version`, `dotnet --info`, `dotnet --list-*`
- `node --version`, `npm --version`, `npm list`
- `pnpm --version`, `pnpm list`
- `yarn --version`, `bun --version`

### 🎯 權限覆寫優先級

```xml
<execution_priority_override>
  <tier level="0" desc="Permission Configuration Override" priority="HIGHEST">
    <!-- 此規則優先級高於所有其他規則，包括 approval_gate -->
    <rule id="permission_config_override" scope="all_execution" priority="absolute">
      對於 opencode.json 中明確標記為 "allow" 的命令：
      1. 檢查 opencode.json 的 permission.bash 配置
      2. 如果命令匹配 "allow" 規則 → 直接執行，無需審批
      3. 如果命令匹配 "ask" 規則 → 請求審批
      4. 如果命令匹配 "deny" 規則 → 拒絕執行
      
      此規則覆蓋 approval_gate 規則中的 "Request approval before ANY execution"
    </rule>
  </tier>
  
  <tier level="1" desc="Safety & Approval Gates">
    <!-- 原有的 approval_gate 規則降級為 Tier 1 -->
    <rule id="approval_gate" scope="all_execution">
      Request approval before execution (bash, write, edit, task)
      EXCEPT for commands explicitly marked "allow" in opencode.json (see Tier 0)
    </rule>
  </tier>
</execution_priority_override>
```

### 📋 實際效果

| 命令 | opencode.json 配置 | 實際行為 |
|------|-------------------|---------|
| `Get-ChildItem` | `"allow"` | ✅ 直接執行，無需審批 |
| `ls -la` | `"allow"` | ✅ 直接執行，無需審批 |
| `git status` | `"allow"` | ✅ 直接執行，無需審批 |
| `npm install` | `"ask"` | ⚠️ 請求審批 |
| `rm -rf *` | `"deny"` | ❌ 拒絕執行 |

---

## CRITICAL: File Editing on Windows

### ⚠️ MANDATORY: Always Use Backslashes on Windows for File Paths

**When using Edit or MultiEdit tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).**

#### ❌ WRONG - Will cause errors:
```
Edit(file_path: "D:/repos/project/file.tsx", ...)
MultiEdit(file_path: "D:/repos/project/file.tsx", ...)
```

#### ✅ CORRECT - Always works:
```
Edit(file_path: "D:\repos\project\file.tsx", ...)
MultiEdit(file_path: "D:\repos\project\file.tsx", ...)
```
