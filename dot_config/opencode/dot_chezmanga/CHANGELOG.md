# OpenCode Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for OpenCode configuration and managed extensions.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - Secrets, runtime state, caches, and generated dependency directories remain excluded.
- Portability: Marker metadata contains no host-specific paths; the machine name is audit metadata only.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-08-21T21:40:51+08:00 - Add selective chezmoi management workflow

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `AGENTS.md.tmpl`, `skills/chezmoi-management/SKILL.md`
- Summary: Added a dedicated workflow for detecting marked scopes, selecting appropriate files, preserving portability, and recording functional changes.
- Important records:
  - OpenCode now checks target `.chezmanga/` and source `dot_chezmanga/` ancestors before changing configuration, themes, scripts, or deployment assets.
  - The workflow defaults to scoped operations and does not treat every descendant of a marker as automatically approved for management.
- Portability: The workflow prefers relative paths, environment variables, and chezmoi templates or data over machine-specific absolute paths.
- Chezmoi: Updated the source template and added the skill under the OpenCode-managed scope.
- Verification: Source and runtime files matched after scoped apply; skill frontmatter, LF line endings, and scoped chezmoi diff were validated.

## 2026-08-21T22:02:53+08:00 - Reduce routine task overhead

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `AGENTS.md.tmpl`, `skills/chezmoi-management/SKILL.md`
- Summary: Limited routine validation and line-ending checks to the smallest relevant scope and added a fast path for ordinary edits to existing managed files.
- Important records:
  - Code and behavior validation now runs once after the task's final edit instead of after every intermediate edit.
  - Routine managed-file edits no longer require Git status, repository-wide diff, candidate inventory, secret scanning, or portability analysis.
  - The full workflow remains required for new files, generated or binary assets, sensitive or machine-specific content, conflicts, audits, and commit or push requests.
- Portability: No platform behavior changed; the lighter workflow still preserves scoped source-to-target synchronization.
- Chezmoi: Updated the managed OpenCode instructions and skill, then applied both exact targets.
- Verification: Runtime content matched source after scoped apply, scoped status was clean, and the two manually edited configuration files remained LF-only.

## 2026-08-26T14:01:45+08:00 - Bound adversarial review workflow

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `commands/selfmade/adv-review.md`, `agent/selfmade/subagents/adversarial/*.md`, `config/assets/commands/adversarial-review/adv-review.md`, `config/assets/agents/adversarial-review/*.md`, `config/assets/overlays/oh-my-opencode-slim/orchestrator/adversarial-plan-review.md`
- Summary: Replaced majority-vote and automatic re-review behavior with immutable review contracts, fixed call budgets, evidence-based decisions, and explicit terminal states.
- Important records:
  - Reviewer output now separates blockers, qualifiers, and out-of-scope objections and records evidence strength.
  - Decisive new facts require independent orchestrator verification; reviewer votes alone do not establish truth.
  - Reviews stop after one round by default. Revised claims require version 2 or a new review ID, an explicit decision, and remain within one optional extra review.
  - Reviewer failures degrade coverage or produce an inconclusive result according to the number of effective responses.
- Portability: Prompts contain no machine-specific paths or runtime assumptions.
- Chezmoi: Updated nine existing managed source files and applied only their exact runtime targets.
- Verification: `git diff --check` passed; deprecated majority-vote and automatic-loop rules were absent; all six reviewer definitions exposed the four verdicts; edited files were LF-only; scoped dry-run, apply, and status completed with source and runtime synchronized.

## 2026-08-26T14:30:00+08:00 - Replace OpenCode notifier with kdco/notify

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode.json`, `kdco-notify.json`, `plugins/notify*`, `plugins/kdco-primitives/*`, `package.json`, `package-lock.json`
- Summary: Replaced the managed notifier source with the KDCO file-based plugin, configured parent-session-only notifications, and pinned its runtime dependencies.
- Important records:
  - Preserved runtime `autoupdate: true` and `default_agent: plan` by synchronizing them into source before replacement.
  - Removed `@mohak34/opencode-notifier` from the config and stopped managing `opencode-notifier.json`; `opencode-notifier-state.json` remains unmanaged runtime state.
  - Runtime dependencies are installed locally with lifecycle scripts disabled; `node_modules` remains unmanaged.
- Portability: No Windows-specific sound override is configured; KDCO defaults handle platform notification delivery.
- Chezmoi: Added and applied the source-managed plugin, configuration, and package files; removed the obsolete managed notifier configuration.
- Verification: Scoped apply succeeded; all 15 runtime plugin files exist; `node-notifier@10.0.1` and `detect-terminal@2.0.0` resolve at depth 0; Bun imported `plugins/notify.ts`; source and runtime package locks match; `git diff --check` passed.

## 2026-08-26T14:54:19+08:00 - Remove legacy notifier remnants

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode-notifier-state.json`, `opencode-test-no-pty.json`
- Summary: Removed the legacy notifier runtime state and the final obsolete plugin reference from a source-only test configuration.
- Important records:
  - Historical changelog references remain as audit records and do not load or install the old plugin.
  - The KDCO notification plugin and `kdco-notify.json` remain unchanged.
- Portability: Removed only obsolete runtime state and a package reference; no machine-specific configuration was added.
- Chezmoi: Updated the source-only test configuration and removed an unmanaged runtime state file.
- Verification: No legacy notifier files, configuration references, or installed top-level dependency remain; edited files are LF-only and `git diff --check` passed.

## 2026-08-26T14:57:58+08:00 - Fix Windows notification identity

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `plugins/notify/backend.ts`
- Summary: Assigned KDCO notifications to the registered OpenCode Windows App ID so SnoreToast no longer reports `DisabledForApplication` into the terminal UI.
- Important records:
  - Windows notifications use the registered `ai.opencode.desktop` App ID.
  - Other platforms retain the upstream KDCO notification options.
- Portability: The App ID is added only on Windows; it matches the OpenCode Start Menu registration on this machine.
- Chezmoi: Updated the managed KDCO notification backend and applied the exact runtime target.
- Verification: A live `node-notifier` toast with the App ID completed without an error; the runtime option builder emits the App ID; scoped chezmoi status and diff are clean.

## 2026-08-26T20:00:06+08:00 - Prefer forward slashes in Windows paths

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `AGENTS.md.tmpl`
- Summary: Added a global instruction to prefer forward slashes in Windows command and configuration path examples.
- Important records:
  - Backslashes remain available when a tool explicitly requires Windows-native separators.
- Portability: The rule improves cross-platform readability without changing tool-specific path requirements.
- Chezmoi: Updated the managed global instruction template and applied its exact runtime target.
- Verification: The rendered global `AGENTS.md` contains the new rule and scoped chezmoi status is clean.

## 2026-08-28T13:46:35+08:00 - Add ASCII explanation guidance

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `AGENTS.md.tmpl`
- Summary: Added a global instruction to use ASCII diagrams when they improve concept explanations.
- Important records:
  - ASCII visualization is expected for useful relationships, flows, and structures rather than as decoration.
- Portability: The instruction uses plain text and has no platform-specific dependency.
- Chezmoi: Updated the managed global instruction template and applied its exact runtime target.
- Verification: The rendered global `AGENTS.md` contains the new rule, scoped status is clean, `git diff --check` passed, and the edited template is LF-only.

## 2026-08-28T13:59:45+08:00 - Add architecture diagram assets

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config/external-assets.json`, `config/skills-registry.md`
- Summary: Added Diagram Design and Archify to the optional project-local `design` asset profile.
- Important records:
  - Diagram Design is pinned to `cathrynlavery/diagram-design` commit `ac490fd1ac4b4014100f93e729cb4ad198700bd4`.
  - Archify is pinned to `tt-a1i/archify` commit `49a7821d194a70c531219f48fd0d6a08ba9ba9d7`.
  - Both assets remain explicit project selections and are not part of the global `core` profile.
- Portability: Both assets use repository URLs and immutable revisions without machine-specific paths.
- Chezmoi: Updated two existing managed source files and applied only their exact runtime targets.
- Verification: Asset catalog `doctor` returned `valid: true` with no errors or drift; rendered catalog and registry contain both pinned assets.

## 2026-09-04T13:52:27+08:00 - Add code understanding assets

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config/external-assets.json`, `scripts/opencode-assets.ps1`, `config/skills-registry.md`, `commands/selfmade/assets.md`
- Summary: Added pinned Graphify and Serena assets to the project-local `understand` profile and added recommendation metadata to asset discovery views.
- Important records:
  - Graphify is the recommended first-pass repository map; its pinned upstream skill can require a future OpenCode compatibility overlay for the complete semantic subagent pipeline.
  - Serena is a second-stage symbol-level MCP, not a skill, and requires `uv`; the manager merges only `mcp.serena` into project `.opencode/opencode.json`.
  - The new `opencode-mcp` channel refuses unmanaged overwrites and refuses removal after config drift, while preserving unrelated configuration and lock ownership.
- Portability: Both upstream sources use immutable revisions; Serena starts through `uvx` with IDE context and discovers the project from the current working directory.
- Chezmoi: Updated five existing managed source files and applied only their exact runtime targets.
- Verification: PowerShell parsing, JSON parsing, catalog `doctor` and `plan`, LF checks, and `git diff --check` passed; isolated Serena apply/status/remove, unmanaged-conflict, and drift-protection scenarios preserved unrelated project configuration.

## 2026-09-04T14:15:26+08:00 - Add message routing commands

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `commands/message-steer.md`, `commands/message-next.md`, `commands/message-new.md`
- Summary: Added explicitly named slash commands that mark incoming instructions as active-task steering, a dependent follow-up, or an independent deliverable.
- Important records:
  - `/message-new` marks an independent message but does not override or reproduce the built-in `/new` session command.
  - The commands inject routing instructions only; they do not add a durable scheduler or create a new TUI session.
- Portability: The command names and prompts contain no machine-specific assumptions.
- Chezmoi: Added three managed command files and applied their exact runtime targets.
- Verification: OpenCode loaded all three commands, scoped chezmoi status was clean, and the command files remained LF-only.

## 2026-09-04T15:00:28+08:00 - Repair persistent project memory

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode.json`, `opencode-mem.jsonc`, `plugins/opencode-mem/package.json`, `run_onchange_after_build-opencode-mem.ps1.tmpl`
- Summary: Replaced the broken cached npm memory plugin with the managed local fork, made its build portable on Windows, and enabled conservative project-context capture and recall.
- Important records:
  - The cached `opencode-mem` 2.19.4 installation could not load `@huggingface/transformers` because its exported ESM file was absent; the local fork uses the working `@xenova/transformers` backend.
  - Recall remains project-scoped, injects at most three memories on the first message, and restores at most five after compaction.
  - Idle auto-capture uses the authenticated GitHub Copilot `gemini-3.5-flash` model; learned user profiles remain excluded from automatic injection.
  - Generated dependencies and `dist/` remain unmanaged. A Windows `run_onchange` script installs the locked dependencies without lifecycle scripts and rebuilds the plugin when its deployment revision changes.
- Portability: The OpenCode config uses a home-relative plugin path; the deployment script is Windows-conditional and derives the target from `USERPROFILE`.
- Chezmoi: Updated three managed configuration/source files, added one managed deployment script, and applied the exact runtime targets.
- Verification: The build and TypeScript check passed; dependency-boundary tests passed; local embedding produced a finite 768-dimensional vector; memory add, project search, and delete passed; a second directory returned zero project results and one all-projects result for the same sentinel; OpenCode resolved the local plugin file without reporting a plugin-load error.

## 2026-09-04T16:36:53+08:00 - Resume active task after steering

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `commands/message-steer.md`
- Summary: Required steering work to return to the original active task and continue it through verification and completion.
- Important records:
  - A steering message cannot silently replace, cancel, or abandon the original task.
  - Only an explicit user instruction can cancel or replace the original task.
- Portability: The prompt contains no machine-specific paths or platform assumptions.
- Chezmoi: Updated the managed command source and applied its exact runtime target.
- Verification: OpenCode loaded the updated command, scoped chezmoi status was clean, and the command remained LF-only.
