---
description: Turn a requirement into the right Linear structure, priorities, milestones, and dependencies.
agent: build
subtask: true
---

# Linear Plan

Arguments: `$ARGUMENTS`

1. 使用 `skill` tool 載入 `linear-workflow` 與 `to-tickets`（全域必備）。
2. 以下為專案層級的可選 skill，只在目前專案已安裝時載入；未安裝時直接以 `linear-workflow` 的規則處理，不得報錯或停止：
   - `deliver-prd`、`deliver-acceptance-criteria`：定義 why/what/outcome 與可驗證條件。
   - `develop-solution-brief`：需求涉及跨模組邊界、系統責任、架構取捨或多個獨立工作流。
   - `to-spec`：涉及具體 DTO、API、command、handler、event、repository、transaction 或測試設計。
   - `develop-adr`：需要明確記錄架構決策或替代方案取捨。
3. 處理順序：先定義 why/what/outcome 與完成條件，需要時補技術方案，最後用 `to-tickets` 拆成可執行工作，再交由 `linear-workflow` 建立或沿用 Linear items。
4. 使用者明確說「一個 Task 就好」或「建 Project」時，依使用者決定；未指定時由 `linear-workflow` 判斷 issue 或 project。
5. `$ARGUMENTS` 以 `preview` 開頭時保持唯讀；否則本次 command 呼叫已授權在需求範圍內建立或沿用 Linear items，不得重複詢問執行確認。
6. 缺少 requirement 時，使用 `question` tool 要求目標、完成條件與已知期限。
7. 不得在此命令另行發明 issue/project 判斷、priority 或輸出規則；以 `linear-workflow` skill 為唯一 Linear 結構規則來源。

## Examples

```text
/selfmade:linear-plan 修正匯入流程偶發 timeout，完成條件是失敗時能安全重試並有測試

/selfmade:linear-plan preview 規劃新版會員中心，包含需求盤點、API、前端、測試與 rollout
```
