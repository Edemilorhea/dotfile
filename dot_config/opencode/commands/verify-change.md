---
description: Analyze and verify current frontend, backend, API, or full-stack changes with focused automated and browser testing.
agent: build
---

Load and follow the `change-verification` skill.

Verify the current code changes end-to-end. Use the scope or emphasis below when provided:

$ARGUMENTS

If no scope is provided, derive it from the current conversation, staged and unstaged changes, or the current branch as defined by the skill. Run the closest existing automated checks, select `agent-browser`, the installed `playwright` skill, or repository Playwright tests according to the required evidence, and report PASS, FAIL, or BLOCKED with exact commands and artifacts.
