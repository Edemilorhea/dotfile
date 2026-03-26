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
