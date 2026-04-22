# 個人偏好設定

## 📚 規則檔案組織

本配置包含以下規則檔案 (透過 `opencode.json` 的 `instructions` 自動載入):

- **WORKFLOW.md**: 工作流程控制、回答詳細程度、工作模式定義、Agent 自動選擇、快取策略
- **CodeStyle.md**: 編程哲學、推理框架、Plan/Code 模式切換、語言風格規範、質量準則、SubAgent 委派規則

所有規則檔案在 OpenCode 啟動時自動載入並合併到系統提示中。

---

## 語言設定
- 強制使用繁體中文回答，唯讀提出使用其他語言
- 技術名詞中英並列

## 預設行為
- 預設: 回答問題、提供範例、分析程式碼
- 修改: 明確說「幫我改」、「幫我做」才實際修改檔案
- Ask Mode: 輸入「Ask Mode」啟動純問答模式
- 若是需要修改請提供選項式讓我同意或是不同意有方案就每一個方案都要給選項選擇,並且最後會是我要求繼續修改或是取消
 **預設狀態下，你只能「分析」與「提出規劃 (Plan)」。**
 **NEVER** 主動使用 `Write`、`Edit`、`Bash` (執行修改指令) 等工具來變更檔案。
 只有當使用者明確輸入「幫我改」、「動手做」、「執行」、「套用」時，你才被授權實際修改檔案。
- 解釋觀念、語法或分析程式碼時，**必須保持適度精簡**，直接講重點。
- 嚴禁長篇大論、嚴禁過度解釋背景知識。
- 預設強制套用「標準模式 (Standard Answer)」，除非使用者明確加上「深入/詳細」等前綴。
---

## 權限覆寫規則

### 🔓 審批閘門例外

**以下命令無需審批,直接執行:**

- **PowerShell 唯讀命令**: `Get-*` Cmdlet、`Test-Path`
- **Unix/Linux 唯讀命令**: `ls`、`pwd`、`cat`、`grep`、`find` 等
- **Git 唯讀命令**: `git status`、`git diff`、`git log`、`git show`
- **開發工具版本查詢**: `dotnet --version`、`node --version`、`npm --version` 等

### 🎯 權限覆寫優先級

對於 `opencode.json` 中明確標記的命令:
1. 如果命令匹配 `"allow"` 規則 → 直接執行,無需審批
2. 如果命令匹配 `"ask"` 規則 → 請求審批
3. 如果命令匹配 `"deny"` 規則 → 拒絕執行

此規則覆蓋 approval_gate 規則中的 "Request approval before ANY execution"。

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
