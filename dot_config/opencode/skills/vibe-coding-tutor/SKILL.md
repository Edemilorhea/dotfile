---
name: vibe-coding-tutor
description: Use when the user asks to explain a completed multi-file feature, generate a project walkthrough, or create a tutorial from existing code. Produces an architecture-focused learning guide and safe hands-on experiments.
---

# Vibe-Coding Tutor

Based on `tortoiseknightma/vibe-coding-tutor` at commit `5ab79ac18cf943f3040f1c6bb6b4e511a65f3904`.

Turn completed implementation work into a human-oriented tutorial so the user understands what was built, why it is structured that way, and how to extend it safely.

## OpenCode Guardrails

- Use this skill only when the user explicitly asks for a tutorial, walkthrough, or explanation of completed work. Do not trigger automatically after a feature or refactor.
- Read only the files necessary to explain the requested scope. Never read secret, credential, environment, or key files.
- Default to returning the tutorial inline. Write `docs/tutorial-YYYY-MM-DD-[feature].md` only after the user explicitly approves file creation.
- Treat suggested experiments as instructions for the user. Do not modify project files while generating a tutorial.
- Follow the repository's existing approval, context-loading, and test-validation rules.

## Teaching Framework

Create a focused tutorial with these sections, omitting irrelevant ones rather than padding:

1. **Project Map** — purpose, essential directories, and the central mental model.
2. **Tech Stack Primer** — at most 3–5 relevant technologies: what, why, and one key concept.
3. **Architecture Walkthrough** — trace one concrete request or user action through the system.
4. **Key Patterns Explained** — 2–4 non-obvious decisions with `file:line`, rationale, and trade-offs.
5. **Try It Yourself** — 2–3 small, observable, low-risk experiments the user can perform.
6. **Extension Points** — where and how to add likely follow-up features, including pitfalls.

## Process

1. Establish the requested feature or project scope and the user's current level.
2. Read the relevant entry point, core logic, tests, configuration manifest, and README when present.
3. Trace one representative execution path. Explain why decisions were made, not merely what files contain.
4. Cite concrete `file:line` evidence for code-specific claims.
5. Return the tutorial inline, then offer one focused follow-up deep dive.

## Output Shape

```markdown
# [Project or Feature] Tutorial

## Project Map
...

## Architecture Walkthrough
...

## Key Patterns
...

## Try It Yourself
...
```

Use Traditional Chinese for explanations. Keep code identifiers, paths, and commands in English.
