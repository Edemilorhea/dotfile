---
description: Route a message as a correction or constraint for the active task.
---

Routing mode: `STEER_CURRENT`.

Treat the instruction below as a correction, clarification, or additional constraint for the active task. Incorporate it at the next safe boundary, before continuing work that the instruction could invalidate. Re-evaluate the current plan, implementation, and acceptance criteria. Do not defer it as a separate follow-up task.

After handling the steering instruction, resume the original active task from its latest valid checkpoint and carry it through verification and completion. Do not replace, cancel, or silently abandon the original task unless the user explicitly instructs you to do so.

Preserve valid completed work and unrelated user changes. If the instruction conflicts with an irreversible action or makes the current task unsafe, stop and explain the conflict before proceeding.

User instruction:

$ARGUMENTS
