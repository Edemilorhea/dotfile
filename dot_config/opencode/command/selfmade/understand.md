---
description: Build or query an Understand knowledge graph for codebase comprehension
agent: OpenAgent
subtask: false
---

# Understand Codebase

Target and options: `$ARGUMENTS`.

Execute the Understand workflow; do not merely describe its commands. First select and load the matching `understand-*` skill:

- Default graph generation or update → `understand`, using `--language zh-TW` unless the user explicitly asks for another language.
- Focused question about an existing graph → `understand-chat`.
- Explain a file, symbol, or module after graph generation → `understand-explain`.
- Diff, domain, onboarding, knowledge-base, or dashboard request → load the matching `understand-diff`, `understand-domain`, `understand-onboard`, `understand-knowledge`, or `understand-dashboard` skill.

Preserve the selected skill's phased workflow and report meaningful phase progress. For graph generation or update, respect supported flags such as `--full`, `--auto-update`, `--no-auto-update`, and `--review`. If a dashboard is requested, launch it non-blockingly; never wait on a Vite server or block the command session for the dashboard process.

Usage examples:
- `/understand . --full`
- `/understand src/auth --review`
- `/understand explain AuthService`
- `/understand dashboard`
