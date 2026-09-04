---
description: Route a message as a dependent follow-up after the active task.
---

Routing mode: `QUEUE_AFTER_CURRENT`.

Treat the instruction below as a separate follow-up that depends on the active task. Record it as a pending Todo now, but do not let it change the active task's scope or acceptance criteria. Finish and verify the active task first. Then promote this follow-up to `in_progress` and execute it in the same session unless it is blocked.

Do not mark the follow-up complete based on intent. If execution cannot continue, preserve it as pending and report the blocker clearly.

Follow-up instruction:

$ARGUMENTS
