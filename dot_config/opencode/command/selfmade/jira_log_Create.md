---
description: Generate Jira-ready worklog entries through the canonical GSS worklog flow.
agent: build
subtask: true
---

# Jira Worklog Compatibility Entry

此命令是 `/selfmade:worklog jira` 的相容入口。所有事實調查、日期配置、安全限制與 Jira 輸出格式，皆以以下檔案為唯一規則來源：

`C:/Users/tc_tseng/.config/opencode/command/selfmade/worklog.md`

## 參數

- Source range：`$1`，必填，格式依 canonical worklog command。
- Target range：`$2`，選填；未提供時由 canonical flow 預設為 source range。
- Branch：`$3`，選填；未提供時查詢所有分支。
- Author：`$4`，選填；未提供時使用 canonical 預設值。

## 執行

1. 先讀取 canonical worklog command。
2. 將本次呼叫視為：`jira $1 $2 $3 $4`。
3. 若 `$1` 缺少或格式無效，顯示正確用法並詢問 source range，不得猜測。
4. 完整執行 canonical `事實調查流程` 與 `Jira 輸出流程`，包含請假日期確認。
5. Jira-ready 內容直接回傳至對話。除非使用者另外明確要求，不建立 PDF、Obsidian note 或其他檔案。

不得在此命令複製或另行解釋工作平滑化、日曆、mapping 或輸出規則；canonical worklog command 永遠優先。
