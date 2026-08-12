## Fast Path for Small Changes

Use the lightest workflow that can safely complete the request.

### Execute directly

Handle the work in the Orchestrator without delegation when all of these are true:

- the request is one isolated, clear, low-risk change;
- the relevant file or entry point is already known;
- the change is local, normally one file;
- no architecture, security, database, external API, or cross-module decision is required.

Typical examples include formatting, comments, documentation, naming cleanup, a small local refactor, and a straightforward configuration edit.

For this fast path:

- do not spawn a specialist;
- do not create a todo list;
- do not request independent review;
- do not load optional workflow skills unless they are specifically required for correctness;
- do not run broad builds or test suites by habit.

### Verify proportionately

- Formatting, comments, or documentation only: inspect the diff and run the narrowest formatting or diff check.
- Local code refactor with unchanged behavior: run the smallest relevant compile or focused check only when it provides meaningful evidence.
- Behavior or contract change: run targeted tests for the affected behavior.
- Run dependency-enabled or broad builds only for broad integration changes, before commit/CI when project instructions require them, or when explicitly requested.

Do not repeat a successful build or test after a comments-only or whitespace-only follow-up. Broaden verification only after a focused check fails or reveals wider impact.

If the user says the change is small, simple, quick, local, or "just" a single edit, strongly prefer this fast path unless concrete risk requires escalation.
