---
description: Turn a requirement into the right Linear structure, priorities, milestones, and dependencies.
agent: build
subtask: true
---

# Linear Plan

Arguments: `$ARGUMENTS`

1. 使用 `skill` tool 載入 `linear-workflow`、`deliver-prd`、`deliver-acceptance-criteria` 與 `to-tickets`。
2. 若需求涉及跨模組邊界、系統責任、架構取捨或多個獨立工作流，再載入 `develop-solution-brief`；若涉及具體 DTO、API、command、handler、event、repository、transaction 或測試設計，再載入 `to-spec`。
3. 若需求包含需要明確記錄的架構決策或替代方案取捨，再載入 `develop-adr`。
4. 依下列順序處理：先用 `deliver-prd` 定義 why/what/outcome，再用 `deliver-acceptance-criteria` 定義可驗證條件；需要時補 `develop-solution-brief`、`to-spec`、`develop-adr`，最後用 `to-tickets` 拆成可執行工作，再交由 `linear-workflow` 建立或沿用 Linear items。
5. `$ARGUMENTS` 以 `preview` 開頭時保持唯讀；否則本次 command 呼叫已授權在需求範圍內建立或沿用 Linear items，不得重複詢問執行確認。
6. 缺少 requirement 時，使用 `question` tool 要求目標、完成條件與已知期限。
7. 不得在此命令另行發明 issue/project 判斷、priority 或輸出規則；以 `linear-workflow` skill 為唯一 Linear 結構規則來源。

## Examples

```text
/selfmade:linear-plan 修正匯入流程偶發 timeout，完成條件是失敗時能安全重試並有測試

/selfmade:linear-plan preview 規劃新版會員中心，包含需求盤點、API、前端、測試與 rollout
```
