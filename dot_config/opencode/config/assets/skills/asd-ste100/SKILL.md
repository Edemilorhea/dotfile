---
name: asd-ste100
description: Use whenever technical instructions, procedures, API steps, SOPs, safety-sensitive text, or explanations for mixed English proficiency must be direct and unambiguous. Apply ASD-STE100-informed sentence and vocabulary constraints. Also use when the user explicitly requests ASD-STE100 or Simplified Technical English.
---

# ASD-STE100-Informed Writing

ASD-STE100 Simplified Technical English is a controlled natural language for technical documentation. Use its sentence-level discipline to reduce ambiguity and translation burden.

The official standard includes a controlled dictionary and detailed rules. Unless the current official standard and project terminology have been checked, describe output as **ASD-STE100-informed**, not formally compliant or certified. For non-English output, apply the clarity principles but do not claim Simplified Technical English conformance.

## Writing Rules

1. Use common, concrete words. Use the same word for the same meaning.
2. Give a technical term only one meaning in the current document.
3. Write short, direct sentences. Put one main proposition in each sentence.
4. Put one action in each instruction step. Start the step with a clear action verb when practical.
5. State the actor when it is not obvious. Prefer active voice.
6. State conditions before actions. State the expected result after the action when it helps verification.
7. Replace vague references such as "it", "this", "as needed", "properly", or "regularly" when the referent or criterion is not unmistakable.
8. Split long noun clusters and nested clauses. Repeat a noun when repetition removes ambiguity.
9. Use affirmative instructions when they are safer and clearer. Use explicit prohibitions for hazards.
10. Keep identifiers, UI labels, commands, paths, code, and protocol keywords exact.

## Procedure Pattern

Use this sequence for instructions:

```markdown
1. [Condition, if needed.] [One action.]
   Expected result: [Observable result, if useful.]
2. [Next action.]
```

Put warnings before the action that can cause harm:

```markdown
Warning: [Hazard and consequence.]
[Required preventive action.]
```

## Explanation Pattern

For explanatory text:

- Start with the main claim.
- Add one reason or consequence per sentence.
- Define a necessary term at first use.
- Use a concrete example after the rule, not before an unexplained abstraction.

## Review Pass

Before returning the text, check:

- Can each pronoun refer to only one thing?
- Does each instruction contain only one required action?
- Are conditions, actions, and results visibly separate?
- Does one word keep one meaning?
- Can a sentence be split without losing the logical connection?
- Did simplification change any technical fact or omit a constraint?

## Combining With Other Skills

- `iso-24495-plain-language` controls audience, order, headings, and usability. This skill controls sentences and terms.
- `eli5-explainer` can add an intuition layer before the precise explanation. Do not apply loose analogy rules to procedures or safety statements.
- `wait-what` uses these constraints when it re-pitches a failed explanation.
