---
description: Prepare a safe GitLab Merge Request without rewriting branch history
agent: OpenAgent
subtask: false
---

# GitLab Merge Request

Arguments: `$ARGUMENTS`.

1. Inspect the current branch, working tree, remotes, and target branch. Do not modify branches, stash changes, rebase, merge, push, or change Git configuration automatically.
2. Default the target branch to `develop` only when it exists and the user did not provide another target. Compare the current branch to the selected target using Git logs and diff statistics.
3. Draft an MR title and description covering motivation, change summary, validation, and risks. Keep the source branch after merge by default.
4. Never hardcode an assignee or reviewer. Use a reviewer only when the user explicitly supplies one.
5. Before `glab mr create`, pushing, or any other external submission, show the exact proposed command and request explicit confirmation. If `glab` is unavailable, provide the prepared title/body and the next safe manual step.
