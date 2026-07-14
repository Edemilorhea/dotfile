# OpenCode Discord Bot SDK Development Plan

## Purpose

Build a reliable single-machine Discord bridge for OpenCode. Discord may submit and monitor work; OpenCode remains the authority for execution and local human approval.

## Non-negotiable constraints

- Use the official OpenCode server and TypeScript SDK. Do not spawn `opencode run` per Discord message or parse CLI stdout.
- Bind the OpenCode server to `127.0.0.1` only.
- Discord must never approve permissions. It may only show `waiting for local approval`.
- Keep existing global OpenCode configuration and plugins intact: OAC workflow, DCP, manual `opencode-mem`, Handoff, Command Inject, Smart Title, and Notifier.
- A Discord thread maps to exactly one OpenCode session. A Discord channel maps only to an allowlisted project.
- Every inbound Discord event is durable and idempotent before it is processed.
- One session has one active prompt writer. New messages queue explicitly; they never silently interrupt or duplicate work.
- No automatic approval, merge, push, delete, credential access, or arbitrary working-directory selection from Discord.
- Secrets are supplied through the OS secret store or environment variables, never source control, Discord, logs, or error messages.

## Scope

### In scope

- Discord slash commands and thread-based conversation.
- Project/channel and thread/session mapping.
- SQLite-backed queue, state, retries, and audit trail.
- OpenCode server/SDK lifecycle, SSE event consumption, prompt dispatch, abort, and recovery.
- Local-only human-in-the-loop permission workflow.
- Read-only and write-task policies, including optional worktree isolation.
- Operational health checks, logging, and tests.

### Explicitly out of scope for v1

- Discord-side permission approval.
- Multi-machine execution, public hosting, DMs, arbitrary repository cloning, or user-provided absolute paths.
- Auto-merge, auto-push, auto-delete, auto-commit, or autonomous deployment.
- Reimplementing OpenCode agents, plugins, MCPs, compaction, memory, or model routing.
- General multi-platform bot support beyond Discord.

## Target architecture

```text
Discord Gateway
  -> Authorization and input validation
  -> SQLite durable queue and idempotency store
  -> Per-session worker and lock
  -> OpenCode SDK connected to localhost server
  -> SSE event projector and status publisher
  -> Discord thread updates

Local OpenCode TUI or OpenChamber
  -> Same localhost server
  -> Permission approval and interactive supervision
```

The bridge is an adapter, not an execution engine. OpenCode owns session state and tool permissions; the bridge owns Discord identity, durable delivery, correlation, and status projection.

## Recommended technology choices

| Concern | Recommendation | Reason |
| --- | --- | --- |
| Runtime | Node.js 22 + TypeScript | Matches the OpenCode SDK ecosystem and current local runtime. |
| Discord | `discord.js` | Mature gateway, interactions, threads, and rate-limit handling. |
| OpenCode | Official `@opencode-ai/sdk` against a long-running server | Stable typed API and SSE; avoids process/stdout fragility. |
| Persistence | SQLite in WAL mode | Durable single-machine queue without an additional service. |
| SQLite access | A synchronous prepared-statement library or a well-tested async wrapper | Transactions must make event intake atomic. |
| Validation | Zod or equivalent schema validation | Treat Discord input as untrusted data. |
| Logging | Structured JSON logger with redaction | Enables reconciliation without leaking secrets. |
| Tests | Vitest/Jest + integration harness | Covers state transitions, retries, and SDK contracts. |

Use the repository's existing package manager and test framework if they differ. Do not add a framework merely to follow this table.

## Security model

### Trust boundaries

1. **Discord is an untrusted trigger surface.** It can request work only after immutable-ID allowlist checks.
2. **The bridge is trusted to dispatch approved project work but cannot approve OpenCode permissions.** Do not implement a Discord endpoint for permission responses.
3. **OpenCode running locally is the execution authority.** Its normal permission policy remains in force.
4. **The local operator is the human approval authority.** Use the TUI via `opencode attach` or OpenChamber connected to the same server.

### Required controls

- Allowlist Discord guild IDs, channel IDs, user IDs, and optionally role IDs; never authorize by display name.
- Disable DMs by default.
- Map channel IDs to configured project roots. Reject arbitrary `cwd`, paths, URLs, and repository identifiers from Discord.
- Apply attachment MIME type, size, count, and storage-path limits before download.
- Redact tokens, Authorization headers, cookies, `.env` values, provider credentials, and private paths from Discord-visible output.
- Restrict bridge service permissions to only its state directory, log directory, and allowlisted project roots.
- Use a dedicated Discord bot token and least-privilege Discord intents.
- Run server and bridge under a normal user, never Administrator.
- Do not expose OpenCode directly through a tunnel in v1. If remote access is later needed, require VPN or authenticated access proxy.

## Domain model

Use a single SQLite database with WAL mode and foreign keys enabled. Store timestamps in UTC ISO-8601 or integer milliseconds consistently.

### Core tables

| Table | Essential fields | Purpose |
| --- | --- | --- |
| `projects` | `id`, `discord_channel_id`, `project_root`, `enabled` | Immutable channel-to-project allowlist. |
| `sessions` | `id`, `project_id`, `discord_thread_id`, `opencode_session_id`, `status` | One Discord thread to one OpenCode session mapping. |
| `jobs` | `id`, `session_id`, `discord_message_id`, `operation`, `payload_hash`, `status`, `attempts`, `available_at`, `error` | Durable queued commands. |
| `dispatches` | `job_id`, `opencode_message_id`, `dispatched_at`, `result_state` | Prevents duplicate prompt dispatch after uncertain failures. |
| `events` | `source`, `source_event_id`, `received_at`, `payload_hash` | Inbound Discord idempotency ledger. |
| `audit_log` | `correlation_id`, `action`, `actor_id`, `metadata_redacted`, `created_at` | Operational trace without secrets. |

### State transitions

```text
pending -> running -> waiting_approval -> running -> completed
pending -> running -> failed
pending -> cancelled
running -> unknown
unknown -> completed | failed | pending_manual_review
```

- Only transactional code changes a job state.
- A retry may occur only from `pending` or a classified transient `failed` state.
- `waiting_approval` never becomes approved by timeout; it remains pending until OpenCode reports progress or the operator cancels it.
- An `unknown` job is reconciled against OpenCode before any retry. Never blindly resend its prompt.

## Discord UX and command contract

Keep the command surface small and explicit.

| Command | Behavior | Permission policy |
| --- | --- | --- |
| `/start` | Creates or attaches a Discord thread to a session for the channel project. | Read-only bridge operation. |
| `/ask <prompt>` | Enqueues a prompt for the current thread/session. | OpenCode controls tool approval. |
| `/status` | Shows queue position, session status, last event, and correlation ID. | Read-only. |
| `/queue` | Displays queued jobs for the current thread. | Read-only. |
| `/cancel` | Requests OpenCode abort for the current active job after authorization. | Local policy decides whether confirmation is required. |
| `/new` | Starts a new mapped Discord thread/session. | Read-only bridge operation. |

Do not add a generic shell command, arbitrary agent selection, raw MCP invocation, permission buttons, arbitrary directory selector, or secret/config inspection command.

### Discord status messages

Publish concise status changes, not tool-output streams:

```text
Queued: job 42
Running: job 42
Waiting for local OpenCode approval
Completed: job 42
Failed: job 42 (correlation: abc123)
```

Use a stable Discord message per job and edit it as state changes. This avoids noisy channel spam and simplifies recovery after gateway reconnects.

## OpenCode integration design

### Server ownership

- Start one long-running OpenCode server per trusted project or one shared server only if the SDK supports clear project isolation in the selected deployment.
- Health-check before accepting queued jobs.
- Record server endpoint and project association, but never expose credentials to Discord.
- Connect local TUI/OpenChamber to the same server for inspection and approval.

### Session behavior

- Create the OpenCode session at `/start` or lazily at the first `/ask`.
- Persist the returned session ID before prompt dispatch.
- Use a stable OpenCode message ID associated with the job ID if the SDK/API supports it.
- Serialize all prompt sends per OpenCode session using an in-process mutex plus transactional database claim.
- Consume SSE events to update session and job state; do not infer completion merely because a request returned.

### Permission behavior

- The bridge may observe a permission request and report `waiting for local approval`.
- The bridge must not invoke the permission-response endpoint.
- Keep OpenCode `edit`, `bash`, external directory, and sensitive MCP permissions at `ask` or `deny` according to the existing configuration.
- If no local TUI/OpenChamber is attached, the job waits or expires into `pending_manual_review`; it never auto-allows.

## Queue and recovery algorithm

### Intake

1. Verify guild/channel/user/role allowlists.
2. Validate interaction schema and rate-limit the actor.
3. Begin a database transaction.
4. Insert the source event with a unique Discord event/message ID.
5. If it already exists, return the existing job status without redispatching.
6. Resolve the project and session mapping.
7. Insert the `pending` job and audit record.
8. Commit, then acknowledge Discord.

### Worker

1. Atomically claim the earliest eligible `pending` job for a session.
2. Acquire the session lock.
3. Verify OpenCode health and reconcile unfinished dispatches.
4. Dispatch exactly once, recording the OpenCode message ID before releasing ambiguity.
5. Project relevant SSE events into job state and Discord status.
6. Release the lock only after terminal state or explicit `waiting_approval` handoff.

### Startup reconciliation

1. Verify database integrity and acquire the bridge singleton lock.
2. Check each configured OpenCode server health endpoint.
3. Load `running`, `waiting_approval`, and `unknown` jobs.
4. Query OpenCode session/message state and resubscribe to SSE.
5. Mark jobs completed only with explicit completion evidence.
6. Mark unprovable jobs `unknown`; require operator review or a safe, idempotent retry path.

### Retry policy

- Retry Discord 429/5xx and transient network errors with exponential backoff and jitter.
- Retry OpenCode-unavailable errors only after health recovery.
- Do not retry validation, authorization, policy denial, or permission-waiting states.
- Cap attempts and surface correlation IDs for manual investigation.

## Write-task isolation

For v1, choose one of these policies per project, never per untrusted Discord request:

1. **Read-only pilot** — only inspect, search, explain, and plan. Recommended first deployment.
2. **Local working tree** — write tasks use the normal project tree but require local tool approval. Suitable only for a trusted solo project.
3. **Mandatory worktree** — every write task receives an isolated worktree; merge, push, delete, and cleanup require local approval. Recommended for multi-task or shared repositories.

Never allow Discord to request automatic merge, push, branch deletion, worktree deletion, or deployment.

## Phased implementation plan

### Phase 0 — Baseline and architecture audit

Deliverables:

- Inspect the existing bot repository, dependencies, startup model, state persistence, Discord event handling, and OpenCode integration.
- Classify the current bot as either reusable SDK/server architecture or CLI/subprocess architecture requiring replacement.
- Write an architecture decision record for server ownership, state directory, channel/project allowlist, and approval policy.

Exit criteria:

- Existing failure modes are reproducible or documented.
- No code changes are made before the current integration path is understood.

### Phase 1 — Foundation and read-only vertical slice

Deliverables:

- Typed configuration loader with fail-closed allowlists.
- SQLite migrations, WAL mode, queue tables, idempotency, and audit logging.
- `/start`, `/ask`, `/status`, and one Discord thread-to-session mapping.
- Official SDK connection to localhost OpenCode server.
- SSE subscription and stable status-message editing.

Exit criteria:

- A duplicate Discord interaction does not create a duplicate OpenCode prompt.
- Restarting the bridge preserves queued work and session mapping.
- Read-only session completes and posts its final status.

### Phase 2 — Recovery, locking, and observability

Deliverables:

- Per-session worker lock and explicit queue ordering.
- Dispatch ledger, restart reconciliation, classified retries, and cancellation behavior.
- Structured logs with correlation IDs and redaction tests.
- Health endpoint and operator diagnostics command.

Exit criteria:

- Bridge restart during a running task does not duplicate the prompt.
- Discord reconnect does not duplicate commands.
- Unknown state is visible and never auto-replayed.

### Phase 3 — Local permission workflow and controlled writes

Deliverables:

- Permission event projection as `waiting for local approval` only.
- Documented local approval operation using OpenCode TUI or OpenChamber.
- Optional project-level write policy and mandatory worktree mode.
- Explicit refusal for unsafe Discord requests.

Exit criteria:

- A write tool cannot proceed from Discord alone.
- A permission timeout does not auto-allow.
- Worktree merge/push/delete still requires local action.

### Phase 4 — Soak test and operational readiness

Deliverables:

- Failure injection tests for Discord outage, OpenCode restart, SSE reconnect, database lock, and Windows process termination.
- Metrics/dashboard for queue lag, job duration, approval wait, retry count, and server restarts.
- Runbook for startup, shutdown, incident recovery, backup, and upgrade.

Exit criteria:

- A multi-day read-only soak test is stable.
- Recovery procedures have been exercised from a clean process restart.
- Security review confirms no Discord-side permission response path exists.

## Test strategy

### Unit tests

- Allowlist evaluation, input validation, path rejection, attachment constraints.
- State-machine transitions and illegal-transition rejection.
- Idempotency for repeated interaction/message IDs.
- Per-session lock behavior and queue ordering.
- Redaction of secrets and sensitive paths.
- Retry classification and backoff scheduling.

### Integration tests

- SQLite transaction rollback and restart recovery.
- Mocked OpenCode SDK/server health, session creation, prompt dispatch, SSE completion, and permission events.
- Discord interaction acknowledgement and stable status-message updates.
- Duplicate delivery, dropped SSE connection, OpenCode server restart, and timeout scenarios.

### End-to-end pilot

- Use a disposable repository and private Discord test channel.
- Start read-only only.
- Verify that a write request reaches local permission approval and cannot be approved from Discord.
- Verify restart reconciliation before enabling any write policy.

## Acceptance criteria

- No duplicate prompt dispatch under duplicate Discord delivery or bridge restart.
- One Discord thread consistently maps to one OpenCode session.
- All sensitive execution permissions remain locally approved.
- Discord has no route to auto-allow, permanent-allow, merge, push, delete, or inspect secrets.
- Pending/running/waiting/completed/failed/unknown status is durable and observable.
- OpenCode server is local-only and project roots are allowlisted.
- Unit, integration, and pilot evidence exists for the above claims.

## Required documentation in the bot repository

- `README.md`: operator setup and safe quick start.
- `docs/architecture.md`: component boundaries and data flow.
- `docs/security-model.md`: trust boundaries, allowlists, secrets, and approval guarantees.
- `docs/operations.md`: start/stop, backup, recovery, incident response, and upgrades.
- `docs/adr/`: decisions for SDK/server integration, SQLite/WAL, local approval, and worktree policy.
- `docs/test-plan.md`: failure scenarios and evidence.

## Implementation guardrails for the coding agent

Before changing code:

1. Inspect the repository and identify the existing Discord/OpenCode integration path.
2. Read the repository's `AGENTS.md`, contribution guidance, package scripts, and test conventions.
3. Confirm the official OpenCode SDK/API signatures against current documentation; do not guess endpoints or event shapes.
4. Preserve existing OpenCode global configuration. The bot must not rewrite `opencode.json` or add permission bypasses.
5. Make the smallest vertical-slice change possible, with tests.
6. Stop and report if a requirement would require Discord-side approval, weakened permissions, arbitrary path access, or secret exposure.

## First implementation request

When this plan is invoked in the bot repository, begin only with **Phase 0**:

```text
Inspect the existing bot. Report its current OpenCode integration model, Discord session mapping, persistence, queue behavior, concurrency control, permission handling, restart recovery, and Windows process lifecycle. Compare it against DISCORD_BOT_SDK_PLAN.md. Do not modify files until the resulting gap analysis and implementation sequence are approved.
```
