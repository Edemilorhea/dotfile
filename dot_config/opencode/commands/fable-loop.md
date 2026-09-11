---
description: Run a task through the explicit command-only Fable Loop
agent: FableAgent
subtask: false
---

# Fable Loop

FABLE_COMMAND_ENTRY: /fable-loop

Task: `$ARGUMENTS`.

This is an explicit Fable command entry. Use `Read`, not the `skill` tool, to load the exact home-relative payload `~/.config/opencode/config/assets/fable/fable-method/METHOD.md` first, then `~/.config/opencode/config/assets/fable/fable-loop/LOOP.md`. Follow them as the sole workflow authority. Follow nested references with `Read` only while this command is active.
