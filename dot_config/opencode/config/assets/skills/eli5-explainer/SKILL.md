---
name: eli5-explainer
description: Use whenever the user asks for ELI5, a beginner-friendly explanation, an analogy, a simple mental model, or says a concept feels too abstract. Explain the intuition first, then restore the precise technical meaning and limits. Do not use merely to shorten otherwise understood text.
---

# ELI5 Explainer

Lower the entry cost of a difficult concept without leaving the user with an inaccurate model. ELI5 means "explain like I'm five" as a technique, not a childish tone or a claim about the user's ability.

## Method

1. Identify the one idea the user must understand first.
2. Explain that idea with familiar objects, actions, or cause and effect. Avoid unexplained domain terms.
3. Map each important part of the analogy to the real system.
4. State where the analogy stops matching reality.
5. Restate the idea in precise technical language, now defining necessary terms.
6. Give one small example or prediction that lets the user check the model.

## Two-Layer Output

Use this order unless the user requests another format:

```markdown
## 先有直覺
[A short concrete explanation or analogy.]

## 對回真正的技術
- [analogy part] → [real concept]
- ...

## 精確版本
[The accurate technical explanation, including important limits.]
```

For a small question, compress the same sequence into a few paragraphs instead of forcing headings.

## Accuracy Rules

- Do not replace an explanation with an analogy. Use the analogy as temporary scaffolding.
- Do not hide safety conditions, destructive effects, permission boundaries, data-loss risks, or required preconditions.
- Preserve code identifiers, commands, paths, API names, and protocol terms exactly.
- Introduce only the terms needed for the current layer. Define each term before relying on it.
- Prefer one analogy that remains consistent across the answer. Do not stack unrelated metaphors.
- If no honest analogy helps, use a concrete worked example instead.

## Combining With Other Skills

- Use `iso-24495-plain-language` to organize a long explanation around the reader's task.
- Use `asd-ste100` to make the precise layer direct and unambiguous.
- If the user is repairing an explanation they already failed to understand, let `wait-what` control the recovery and use this skill only for the blocked concept.
