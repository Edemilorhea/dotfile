## Adversarial Review for Major Plans

Before implementing a non-trivial or high-risk plan, challenge the plan with three independent adversarial reviews.

### When to run the review

Run it when the plan includes one or more of these conditions:

- architecture or cross-module design decisions;
- authentication, authorization, secrets, or other security-sensitive behavior;
- database schemas, migrations, destructive operations, or possible data loss;
- public API or compatibility changes;
- concurrency, deployment, infrastructure, or partial-failure risks;
- a root-cause conclusion whose failure would cause substantial rework.

Do not run it for work that qualifies for the small-change fast path.

### Review procedure

1. Create an immutable review contract with `review_id`, `version`, `object_type`, `original_question`, one falsifiable `claim`, `decision`, `evidence`, `scope`, `out_of_scope`, `pass_criteria`, and `budget`.
2. Keep the budget fixed: at most two claims, three reviewers per claim, six initial task calls, one explicitly authorized extra review, and twelve total calls. Do not automatically batch additional claims.
3. In one message, call `Skeptic`, `RedTeam`, and `Simplifier` through the task tool in parallel. Do not merge their roles, run them serially, or retry automatically.
4. Require each objection to state its classification (`BLOCKER`, `QUALIFIER`, or `OUT_OF_SCOPE`), relation to the claim, decision impact, evidence strength (`VERIFIED`, `OBSERVED`, `INFERRED`, or `SPECULATIVE`), and evidence.
5. Deduplicate objections that have the same failure condition, evidence, and decision impact. Qualifiers, out-of-scope concerns, and speculative concerns alone do not block the plan.
6. Treat reviewer verdicts as leads, not votes. The orchestrator must independently verify every new fact that would change the final decision.

### Decision and stop rules

- `REFUTED`: at least one decisive blocker was independently verified.
- `INCONCLUSIVE`: decisive evidence is missing or conflicting, or at least two reviewers failed or were cancelled.
- `SURVIVED`: at least two reviewers completed effectively and no verified blocker or unresolved decisive evidence remains. This means only that the claim survived this bounded review.
- `ABORTED`: the claim is missing, the contract must change, scope or budget must expand, or the call limit prevents completion.

One reviewer failure permits a degraded-coverage result and must be reported. Stop after one round or when any terminal condition is reached. Do not revise and repeat automatically. A revised plan uses version 2 or a new review ID and requires an explicit orchestrator or user decision; scope, decision, or budget expansion requires user approval.

The review is a planning gate. It does not replace implementation verification after the change.
