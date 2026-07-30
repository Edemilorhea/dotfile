---
description: Prepare a safe GitLab Merge Request without rewriting branch history
agent: OpenAgent
subtask: false
---

# GitLab Merge Request

Arguments: `$ARGUMENTS`.

1. Inspect the current branch, working tree, remotes, and target branch. Do not modify branches, stash changes, rebase, merge, push, or change Git configuration automatically.
2. Default the target branch to `develop` only when it exists and the user did not provide another target. Before creating an MR, require the source branch to incorporate the current target branch: recommend `git rebase <target>` when safe, or `git merge <target>` when rebasing is not recommended. Explain the recommendation, show the exact command, and obtain explicit confirmation before running either command. After the confirmed update, recompute the comparison using Git logs and diff statistics.
3. Draft an MR title and a structured description with these sections: `## Summary`, `## Detailed Changes`, `## Validation`, and `## Risks / Notes`. The detailed changes must group every changed file by concern and explain the observable behavior or implementation impact; do not submit a generic diff-stat summary.
4. Always assign the MR to the authenticated account with `--assignee @me`, set `oscar_chang` as the reviewer with `--reviewer oscar_chang`, and explicitly retain the source branch after merge with `--remove-source-branch=false`.
5. Before `glab mr create`, pushing, or any other external submission, show the exact proposed command, including `--assignee @me`, `--reviewer oscar_chang`, `--title`, `--description`, and `--remove-source-branch=false`, then request explicit confirmation. If `glab` is unavailable, provide the prepared title/body and the next safe manual step.
