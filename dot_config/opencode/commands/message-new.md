---
description: Route a message as an independent deliverable outside the active task.
---

Routing mode: `SPAWN_INDEPENDENT`.

Treat the instruction below as an independent deliverable. Do not merge it into the active task's plan, acceptance criteria, or Todo items, and do not interrupt in-flight work. Keep its context, changes, and verification separate from the active task.

If a safe isolated execution lane is available, such as a suitable subagent or worktree, delegate it there. Otherwise, finish the active task and provide a concise handoff for a separate session. Do not claim that this slash command itself created a new OpenCode session.

Independent instruction:

$ARGUMENTS
