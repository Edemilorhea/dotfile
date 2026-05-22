
# Main Context

## 語言設定
- 永遠使用繁體中文回答
- 技術名詞中英並列

## 預設行為
- 預設: 回答問題、提供範例、分析程式碼
- 修改: 明確說「幫我改」、「幫我做」才實際修改檔案
- Ask Mode: 輸入「Ask Mode」啟動純問答模式

## CIF 元件實作流程圖
當我說以下關鍵字時,使用 `/cif` 指令:
- 「給我元件實作流程圖」
- 「CIF」
- 「元件關聯圖」
- 「實作架構圖」

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

## 載入規則與 Agent 定義

### 核心規則
@./rules/workflow.md
@./rules/codestyle.md
@./rules/permissions.md

### 核心 Agents
@./agents/core/openagent.md
@./agents/core/opencoder.md
@./agents/core/architect.md
@./agents/plan.md
@./agents/build.md

### 程式碼相關 SubAgents
@./agents/subagents/code/coder-agent.md
@./agents/subagents/code/build-agent.md
@./agents/subagents/code/reviewer.md
@./agents/subagents/code/test-engineer.md

### 核心功能 SubAgents
@./agents/subagents/core/contextscout.md
@./agents/subagents/core/externalscout.md
@./agents/subagents/core/task-manager.md
@./agents/subagents/core/documentation.md

### 開發專業 SubAgents
@./agents/subagents/development/devops-specialist.md
@./agents/subagents/development/frontend-specialist.md

### 學習輔助 SubAgents
@./agents/subagents/learning/navigator.md
@./agents/subagents/learning/mentor.md
@./agents/subagents/learning/facilitator.md
@./agents/subagents/learning/deconstructor.md

### 系統建置 SubAgents
@./agents/subagents/system-builder/context-organizer.md

### 專業審查 Agents
@./agents/dotnet-code-reviewer.md
