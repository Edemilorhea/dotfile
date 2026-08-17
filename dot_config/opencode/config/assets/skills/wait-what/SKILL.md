---
name: wait-what
description: Use whenever the user says they are lost, confused, cannot connect the explanation, must reread it, finds it too complex, or asks to explain again in another way. Repair the failed explanation with minimal context, project vocabulary, direct language, and one smaller understanding step. Do not merely repeat or summarize the same answer.
---

# Wait, What?

Repair an explanation after the reader loses the thread. This skill adapts Matt Pocock's `wait-what` prompt: add the missing context, use ASD-STE100 Simplified Technical English discipline, and use the project's ubiquitous language.

The failure is evidence about the explanation, not about the reader. Do not defend the previous answer or tell the user to reread it.

## Recovery Method

1. Identify the last point the user appears to understand and the first missing bridge.
2. Give only the context required to cross that bridge.
3. Re-pitch one smaller unit through a different path: a concrete example, cause and effect, before and after, or input to output.
4. Use short, direct sentences and stable terms. Define each necessary term before using it.
5. Connect the repaired unit back to the larger map in one sentence.
6. Ask one high-information check question, or offer two specific points the user can choose to expand.

If the missing bridge cannot be inferred, ask one precise diagnostic question instead of repeating the full explanation.

## Project Language

Use the terms that the project uses in its nearest `AGENTS.md`, `CONTEXT.md`, requirements, domain model, public API, and code. Keep identifiers exact.

- Do not invent synonyms for established domain terms.
- If the project uses two competing terms, name the conflict and choose one for the current explanation.
- Define a project term in plain language before relying on it.

## Default Response Shape

```markdown
你卡住的橋接點可能是：[one specific gap].

先保留這個背景：[minimum context].

[Re-pitch one small unit with a concrete path.]

它在整體流程的位置是：[one-sentence reconnection].

[One check question or two focused next choices.]
```

Do not force the labels when a natural short answer is clearer.

## Constraints

- Do not repeat the previous structure with fewer words.
- Do not restart from the beginning unless the foundational model is the actual gap.
- Do not add branches, edge cases, architecture history, or alternatives before the main bridge works.
- Do not introduce more than three new technical terms in one recovery chunk.
- Do not trade away technical correctness. Mark a simplified model's limits.

## Combining With Other Skills

- Use `asd-ste100` for the sentence-level re-pitch.
- Use `eli5-explainer` if the blocked unit is an abstract concept that needs intuition.
- Use `iso-24495-plain-language` if the failure came from poor order, navigation, or excessive information density.
