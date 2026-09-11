---
description: Run a task through the isolated, evidence-first Fable workflow
agent: FableAgent
subtask: false
---

# Fable Workflow

FABLE_COMMAND_ENTRY: /selfmade/fable

Task: `$ARGUMENTS`.

This is an explicit Fable command entry. Use `Read`, not the `skill` tool, to load the exact home-relative payload `~/.config/opencode/config/assets/fable/fable-method/METHOD.md` first. Use `Read` on `~/.config/opencode/config/assets/fable/fable-loop/LOOP.md` only when the request is explicitly a loop request or the task is non-trivial enough to require its evidence, planning, execution, adversarial verification, and audit stages. Use `Read` on `~/.config/opencode/config/assets/fable/fable-judge/JUDGE.md` only when the user requests judgment or the active workflow reaches adversarial verification. Follow nested references with `Read` only while this command is active.

Use the Fable workflow as the sole orchestration authority. Do not delegate planning or review to non-Fable workflows.

Use this command for high-consequence or high-uncertainty work that requires traceable evidence: security, authorization, payments, data migrations, cross-system correctness, conflicting specifications, production-impacting changes, or an explicit audit request. Use the built-in `build` agent for ordinary feature work, fixes, and refactors.
