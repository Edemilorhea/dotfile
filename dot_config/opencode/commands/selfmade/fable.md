---
description: Run a task through the isolated, evidence-first Fable workflow
agent: FableAgent
subtask: false
---

# Fable Workflow

Task: `$ARGUMENTS`.

Use the Fable workflow as the sole orchestration authority. Load `fable-method` first; use `fable-loop` only when the request is explicitly a loop request or the task is non-trivial enough to require its evidence, planning, execution, adversarial verification, and audit stages. Do not delegate planning or review to non-Fable workflows.

Use this command for high-consequence or high-uncertainty work that requires traceable evidence: security, authorization, payments, data migrations, cross-system correctness, conflicting specifications, production-impacting changes, or an explicit audit request. Use the built-in `build` agent for ordinary feature work, fixes, and refactors.
