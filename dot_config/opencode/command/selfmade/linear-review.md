---
description: Review current Linear progress, recover the last active task, and identify blockers and next actions.
agent: build
subtask: true
---

# Linear Review

Scope: `$ARGUMENTS`

1. 使用 `skill` tool 載入 `linear-workflow`。
2. 以 skill 的 `review` 模式審閱 `$ARGUMENTS` 指定的 team、project 或 issue。
3. `$ARGUMENTS` 為空時，執行 skill 的「恢復上次工作」流程；高可信候選不存在時，以 `question` tool 逐層提供 Teams → Projects / Issues 選擇。
4. 本命令永遠唯讀。不得呼叫任何 `linear_save_*`、delete、merge 或其他會改變 Linear 狀態的 tool。
5. 回報 current focus、實際 progress、下一步、blockers、risks、最近完成與未知資訊。

## Examples

```text
/selfmade:linear-review

/selfmade:linear-review GSS

/selfmade:linear-review GSS-123

/selfmade:linear-review customer-import-reliability
```
