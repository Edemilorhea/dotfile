---
description: Turn a requirement into the right Linear structure, priorities, milestones, and dependencies.
agent: build
subtask: true
---

# Linear Plan

Arguments: `$ARGUMENTS`

1. 使用 `skill` tool 載入 `linear-workflow`。
2. 以 skill 的 `plan` 模式完整處理 `$ARGUMENTS`。
3. `$ARGUMENTS` 以 `preview` 開頭時保持唯讀；否則本次 command 呼叫已授權在需求範圍內建立或沿用 Linear items，不得重複詢問執行確認。
4. 缺少 requirement 時，使用 `question` tool 要求目標、完成條件與已知期限。
5. 不得在此命令另行發明 issue/project 判斷、priority 或輸出規則；以 `linear-workflow` skill 為唯一規則來源。

## Examples

```text
/selfmade:linear-plan 修正匯入流程偶發 timeout，完成條件是失敗時能安全重試並有測試

/selfmade:linear-plan preview 規劃新版會員中心，包含需求盤點、API、前端、測試與 rollout
```
