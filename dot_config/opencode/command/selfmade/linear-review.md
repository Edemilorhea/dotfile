---
description: Review current Linear progress, recover the last active task, and identify blockers and next actions.
agent: build
subtask: true
---

# Linear Review

Scope: `$ARGUMENTS`

1. 使用 `skill` tool 載入 `linear-workflow` 與 `to-tickets`。
2. 若審閱內容包含需求品質、acceptance criteria 或 issue 是否可執行，載入 `deliver-prd` 與 `deliver-acceptance-criteria`；若包含技術設計或架構決策，載入 `to-spec` 與 `develop-adr`。
3. 以 `linear-workflow` skill 的 `review` 模式審閱 `$ARGUMENTS` 指定的 team、project 或 issue，並用 `to-tickets` 檢查拆解、依賴與可執行性。
4. `$ARGUMENTS` 為空時，執行 skill 的「恢復上次工作」流程；高可信候選不存在時，以 `question` tool 逐層提供 Teams → Projects / Issues 選擇。
5. 本命令永遠唯讀。不得呼叫任何 `linear_save_*`、delete、merge 或其他會改變 Linear 狀態的 tool。
6. 回報 current focus、實際 progress、下一步、blockers、risks、最近完成與未知資訊。

## Examples

```text
/selfmade:linear-review

/selfmade:linear-review GSS

/selfmade:linear-review GSS-123

/selfmade:linear-review customer-import-reliability
```
