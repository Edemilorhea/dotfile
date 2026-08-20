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

1. Produce a self-contained review packet with the plan, evidence, assumptions, affected components, and intended verification.
2. In one message, call `Skeptic`, `RedTeam`, and `Simplifier` through the task tool in parallel. Do not merge their roles or run them serially.
3. Give each reviewer the same review packet, relevant file paths, and its assigned review lens.
4. Incorporate every concrete objection into the plan or explicitly record why the objection does not apply.
5. If two or more reviewers return `REFUTED`, revise the plan and repeat the review before implementation.
6. If zero or one reviewer returns `REFUTED`, continue only after reporting the remaining objection as a known risk.

The review is a planning gate. It does not replace implementation verification after the change.
