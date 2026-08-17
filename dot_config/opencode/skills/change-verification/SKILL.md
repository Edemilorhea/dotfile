---
name: change-verification
description: Use whenever the user asks to test, verify, QA, or validate current frontend, backend, API, full-stack, PR, branch, or uncommitted code changes. Derives focused scenarios from the diff, runs existing automated checks, selects agent-browser for exploration and Playwright for precise browser assertions, verifies backend effects, and reports PASS, FAIL, or BLOCKED with evidence. Also trigger on requests such as 完整測試這次修改、驗證前後端、測試剛修好的 bug、確認改動沒有 regression.
---

# Change Verification

Verify the behavior affected by a code change. Treat implementation, automated coverage, and observed runtime behavior as separate claims. A completed command is not proof that a feature works.

## Boundaries

- Use this skill for change-focused verification, not broad exploratory QA of an unrelated live site.
- Prefer the smallest test set that provides credible evidence for the affected behavior.
- Never target production, shared staging, or destructive real data without explicit user authorization.
- Never place credentials in scripts, command arguments, reports, screenshots, or repository files.
- Do not add permanent tests automatically unless the user requested implementation or the task clearly includes fixing the regression. For a verification-only request, recommend the missing regression test instead.

## Workflow

### 1. Establish scope and expected behavior

Read the nearest `AGENTS.md` and relevant project instructions first. Determine the comparison scope in this order:

1. A commit, range, PR, or files named by the user.
2. Changes implemented in the current conversation.
3. Staged and unstaged changes versus `HEAD`.
4. Current branch versus its upstream or clear base branch.

Do not silently guess a base when multiple choices would materially change the test scope. State the selected baseline.

Inspect the diff, changed files, adjacent code, routes, handlers, schemas, tests, and configuration. Build a compact impact map:

`changed code -> entry point -> dependency or state effect -> observable result`

For each expected behavior, mark the source as `Confirmed`, `Inferred`, or `Unknown`. Resolve unknown behavior from tests, requirements, issue text, or surrounding code before claiming a result.

### 2. Discover the project runtime

Read [references/project-discovery.md](references/project-discovery.md). Prefer repository evidence over conventional defaults. Identify:

- Existing lint, type-check, unit, integration, API, and E2E commands
- Frontend and backend start commands
- Application and health-check URLs
- Test environment and safe test-data strategy
- Authentication requirements
- Existing Playwright configuration, fixtures, and conventions

Ask one focused question only when missing information blocks safe execution or changes correctness. Do not invent credentials, URLs, seed data, or startup commands.

### 3. Define the verification matrix

Create scenarios directly from the impact map. Include only applicable cases:

- Primary success path
- Validation or backend error path
- Authentication or authorization boundary
- Adjacent regression path
- Reload or revisit when persistence is expected
- Desktop and mobile viewport when layout or responsive behavior changed

Define the observable assertion before running each scenario. Good assertions include a specific URL, visible state, accessible element, response status, request payload shape, persisted value, or deterministic backend result.

Prioritize by risk. Core user paths, data mutation, security boundaries, and changed contracts receive deeper verification than styling or isolated internal refactors.

### 4. Run the closest automated checks

Run the narrowest existing checks first, then broaden only when useful:

1. Tests directly covering changed symbols or behavior
2. Relevant type-check, lint, unit, integration, or API suite
3. Existing project E2E tests for the affected flow
4. Build or broader suite when the risk or project convention warrants it

Record exact commands and outcomes. Never report a skipped, unavailable, or unrelated test as passing evidence.

### 5. Select browser automation deliberately

Read [references/browser-strategy.md](references/browser-strategy.md) before browser work.

- Use `agent-browser` when the workflow, selectors, or actual UI state must be discovered; for exploratory QA; or for interactive bug reproduction.
- Use the installed `playwright` skill for precise one-off assertions, network inspection, responsive checks, tracing, or a deterministic scripted flow.
- Use the repository's `@playwright/test` setup when a permanent regression test already exists or the requested scope includes adding one.
- Use both when discovery is necessary before a stable Playwright assertion can be written.

Before the first `agent-browser` command, load version-matched guidance with `agent-browser skills get core`. Also load `agent-browser skills get dogfood` only for broad exploratory testing or bug hunting.

Before using the installed Playwright executor, load the `playwright` skill and follow its setup, server detection, and execution contract. When the repository already has Playwright tests, preserve its fixtures, locator conventions, web-server setup, reporters, and artifact configuration instead of using the temporary executor.

### 6. Verify the full observable flow

For each browser scenario:

1. Establish a known initial state.
2. Navigate and wait for a specific readiness condition.
3. Perform the user action.
4. Wait for an observable result rather than sleeping for a fixed duration.
5. Assert the expected UI state.
6. Inspect relevant console errors and failed network requests.
7. Verify the backend effect when the action crosses an API boundary.
8. Reload or revisit when persistence is part of the contract.

For API-backed behavior, verify as many applicable links as evidence allows:

`UI action -> request method and endpoint -> response -> state change -> rendered result`

Browser evidence does not replace transaction, queue, retry, database constraint, concurrency, or service-level tests. Run the closest backend checks for those concerns.

### 7. Diagnose failures without changing scope

Retry once from a clean known state to distinguish a reproducible failure from stale state or timing. Capture evidence immediately when reproducible:

- Expected and observed result
- Exact reproduction steps
- Relevant console or network output
- Screenshot, trace, or video path when useful
- Suspected layer, clearly labeled as hypothesis unless confirmed

Do not fix product code during a verification-only request. If the user asked to implement or fix the change, diagnose, apply the smallest correction, and rerun the failed scenario plus the nearest regression checks.

### 8. Report outcome-first

Use this structure:

```markdown
## Verification Result

Overall: PASS | FAIL | BLOCKED
Scope: <baseline and affected behavior>

| Scenario | Result | Evidence |
|---|---|---|
| <behavior> | PASS/FAIL/BLOCKED | <assertion, command, artifact> |

## Failures
<reproduction and evidence, or "None">

## Automated Checks
<exact commands and results>

## Coverage Gaps
<untested behavior, environmental limits, and assumptions>

## Artifacts
<screenshots, traces, videos, or reports>
```

Use `PASS` only when the expected result was directly observed. Use `FAIL` for a reproducible mismatch. Use `BLOCKED` when environment, credentials, dependencies, or unavailable data prevented the observation.

### 9. Clean up

Close browser sessions. Stop only services started during this verification, and preserve screenshots, traces, videos, and reports. Do not remove user data or unrelated runtime processes.
