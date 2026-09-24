---
description: Review an explicit diff or file scope without recursive reviewer delegation
agent: build
subtask: false
---

# Code Review

Review scope: `$ARGUMENTS`.

1. Fix the scope before looking for findings. Apply the global review and delegation rules.
   - With arguments, review only the supplied files, globs, diff range, or explicit focus.
   - Without arguments, review only the current repository's committed diff plus working-tree changes. Do not review the whole repository or adjacent modules.
2. Review the supplied diff/files directly. Priority order: correctness and security defects introduced by the change, then behavioral regressions and missing tests, then maintainability and performance.
3. Call `jev_review` with the task description and the focused diff, following the `jev-review` skill. Use the scores to confirm or extend your own findings; never report a score without a concrete observation that explains it. If `jev_review` is unavailable, state that in one line and continue.
4. For a large or mixed review, use the built-in `explore` subagent only to map bounded review slices; assess each slice under the same contract.
5. Do not recursively invoke another reviewer. If the evidence is insufficient, return `## Missing Information` to the caller.

Report only concrete findings inside the scope, in the step 2 priority order, with file/line evidence. Do not add speculative repository-wide recommendations. When `jev_review` ran, end with a short `## Jev scores` table of the weakest dimensions.

Usage examples:
- `/review` - Review the current committed and working-tree diff only
- `/review @src/components/Button.tsx` - Review one explicit file
- `/review HEAD~1..HEAD` - Review one explicit commit range
