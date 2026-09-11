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

## 2026-09-07T00:17:13+08:00 - Fix empty Overlay selection

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `scripts/opencode-assets.ps1`
- Summary: Kept the TUI Overlay candidates as an array when the selected asset has no matching Overlay.
- Important records:
  - PowerShell pipeline unrolling previously converted an empty conditional result to `$null`, causing `.Count` to fail under strict mode.
- Portability: The fix uses standard PowerShell array-subexpression behavior without machine-specific values.
- Chezmoi: Updated the managed script source and applied only its exact runtime target.
- Verification: PowerShell syntax parsing passed; asset catalog `doctor` returned `valid: true` with no errors or drift; the `human-skill-tree` zero-Overlay case returned a count of zero; source and runtime scripts remained LF-only.

## 2026-09-07T00:47:56+08:00 - Hide non-applicable assets

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `scripts/opencode-assets.ps1`
- Summary: Removed provenance-only assets and their empty Profiles from the TUI installation choices while preserving catalog visibility and execution safeguards.
- Important records:
  - `human-skill-tree` remains a provenance record with no pinned revision and cannot be applied.
- Portability: The filter uses catalog metadata and contains no machine-specific paths.
- Chezmoi: Updated the existing managed script source and applied only the script and changelog targets.
- Verification: PowerShell syntax parsing passed; catalog `doctor` remained valid with the provenance warning; a simulated TUI session excluded `human-skill-tree` and the empty `education` Profile.

## 2026-09-07T10:24:02+08:00 - Set GPT-6 as the default model

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode.json`, `agent/selfmade/fable-agent.md`
- Summary: Changed the global default and every explicit agent model override to the non-Fast GPT-6 model.
- Important records:
  - OpenCode exposes the requested model as `openai/gpt-6-astra`; `openai/gpt-6-astra-fast` remains unused.
  - Embedding, memory, and fallback model settings serve separate purposes and remain unchanged.
- Portability: The provider/model ID is machine-neutral; each machine still requires access to the configured OpenAI provider.
- Chezmoi: Updated the existing managed source files and applied only their exact runtime targets.
- Verification: `opencode models openai` listed `openai/gpt-6-astra`; runtime configuration matched source after scoped apply; all explicit default agent models used the non-Fast GPT-6 ID; edited files remained LF-only.

## 2026-09-07T10:36:54+08:00 - Add OpenAI subscription usage display

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode.json`, `tui.json`, `package.json`, `package-lock.json`, `plugins/openai-usage.ts`, `plugins/openai-usage-tui.ts`
- Summary: Added a pinned plugin that fetches ChatGPT subscription usage and displays the remaining quota in the OpenCode TUI sidebar and command palette.
- Important records:
  - `@a-r-m-i-n/opencode-openai-usage` is pinned at 0.1.5; it reads the local OpenAI OAuth session and calls the undocumented `https://chatgpt.com/backend-api/wham/usage` endpoint, which can change without notice.
  - The plugin's cache contains the OpenAI account email and ID and remains unmanaged under OpenCode runtime storage.
  - Local wrappers correct the plugin's Windows state-directory lookup without changing the process environment permanently.
  - OpenTUI peer dependencies are pinned. This machine's user-level npm configuration forces `os=linux`, so runtime installation used explicit `--os=win32 --cpu=x64` overrides without modifying `.npmrc`.
- Portability: The lockfile retains OpenTUI optional binaries for all supported platforms; installations must select the actual host OS and architecture rather than a conflicting npm `os` override.
- Chezmoi: Added two managed wrapper plugins and updated the existing managed configuration and package files, then applied only their exact runtime targets.
- Verification: The server wrapper fetched live usage with no error; the TUI wrapper registered its sidebar slot, commands, nine event handlers, and cleanup callbacks; OpenTUI imports succeeded; `opencode debug config` passed; npm audit reported no high or critical findings, with four low findings in the new TUI dependency chain and two unrelated moderate findings in the existing notifier chain.

## 2026-09-07T11:34:59+08:00 - Route subagents by workload

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode.json`, `agent/selfmade/subagents/CodeInvestigator.md`, `agent/selfmade/subagents/Implementer.md`
- Summary: Assigned different OpenAI models and variants to investigation, learning, general implementation, and plan-execution workloads.
- Important records:
  - `plan`, `CodeInvestigator`, `Skeptic`, and `RedTeam` use `openai/gpt-6-astra` with its default variant for difficult diagnosis, planning, and adversarial review.
  - `general`, `explore`, the learning agents, and `Simplifier` use `openai/gpt-5.6-sol-fast` with `variant: high`.
  - `Implementer` uses `openai/gpt-5.6-luna` with `variant: xhigh` and is limited by its description to complete, explicit implementation plans.
- Portability: Agent definitions contain provider model IDs only and no machine-specific paths; each machine still requires access to the configured OpenAI provider.
- Chezmoi: Updated the managed OpenCode config, added two managed subagent definitions, and applied only their exact runtime targets.
- Verification: `opencode debug config` parsed the merged configuration and showed the intended model and variant assignments; `opencode agent list` discovered both new agents; scoped chezmoi status was clean after apply; `git diff --check` passed.

## 2026-09-07T20:05:12+08:00 - Enable reviewed Human Skill Tree installation

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `config/external-assets.json`, `config/assets/skills/human-skill-tree-frontmatter.json`, `scripts/opencode-assets.ps1`
- Summary: Made the 34 top-level Human Skill Tree skills installable from a pinned upstream revision by adding the OpenCode frontmatter that upstream omits.
- Important records:
  - The bundle is pinned to commit `be589ddd04c945cd64642702ed7f6cfbd2466e03`; skill names are enumerated instead of using wildcard ownership discovery.
  - Installation adapts only temporary checkout copies. Installed skill bodies remain byte-equivalent to upstream after the managed frontmatter is removed.
  - Review caveats remain for deployment commands, incomplete Supabase RLS examples, learner-data handling, professional advice, emergency precedence, and cross-cultural compliance guidance.
  - The upstream root license offers `skills/` under AGPL-3.0 or MIT but omits the full MIT grant text; preserve upstream license provenance before redistribution.
- Portability: The catalog uses a public repository, immutable revision, home-relative metadata path, and project-relative skill destinations without host-specific paths.
- Chezmoi: Added the frontmatter metadata file and updated the managed catalog and installer before applying only those runtime targets and this changelog.
- Verification: PowerShell parsing and catalog `doctor` passed; an isolated project installed and locked all 34 skills, reported no drift, preserved every upstream body, removed all 34 skills cleanly, and all edited configuration files remained LF-only.

## 2026-09-07T21:13:56+08:00 - Replace broken NotebookLM MCP package

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `opencode.json`
- Summary: Replaced `notebooklm-mcp@latest` with the maintained Gemini Notebook fork that supports Google's `notebook.google.com` domain.
- Important records:
  - The previous `notebooklm-mcp@2.0.0` release only recognized `notebooklm.google.com`, so successful Google sign-in timed out and remained unauthenticated after the July 2026 product rebrand.
  - `@charlie.act7/gemini-notebook-mcp` preserves the existing browser-driven authentication, notebook library, question, citation, and session workflows.
  - The package is pinned to `2.3.11` so an unreviewed future release cannot silently change the MCP behavior.
- Portability: The npm package command and version are machine-neutral; authentication profiles and cookies remain unmanaged runtime state.
- Chezmoi: Updated the existing managed OpenCode configuration and applied only its runtime target.
- Verification: Node.js satisfies the package requirement; the rendered OpenCode configuration matches source and keeps the expected MCP command shape.

## 2026-09-08T16:53:56+08:00 - Add dependency-aware verification scheduling

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config/external-assets.json`, `config/assets/overlays/oh-my-opencode-slim/orchestrator/*.md`, external project `.opencode/assets*.json` and `orchestrator_append.md`
- Summary: Added and deployed an OMOS Orchestrator append that schedules validation from actual writer and artifact dependencies instead of file ownership alone.
- Important records:
  - Disjoint writers may still feed the same validation; checks wait for every writer or artifact producer whose output they consume unless the check is proven isolated.
  - Local success is reported only for its completed scope and does not become an integrated pass without the required combined-output check.
  - The existing generic Overlay generator emits the selected source as `.opencode/oh-my-opencode-slim/orchestrator_append.md`; no deployment script change was necessary.
  - The GSS project append moved from unowned legacy content to hash-protected Overlay output while preserving its Explorer, MVP-first, and Fast Path instructions.
- Portability: The prompt and catalog use home-relative source paths and project-relative output paths with no machine-specific assumptions.
- Chezmoi: Added the managed Overlay sources and updated the managed asset catalog, then applied only those exact user-config targets; external project deployment metadata remains outside chezmoi.
- Verification: Catalog JSON parsing and asset `doctor` passed; overlay-only apply returned `applied: []`, generated all three selected sections with source hashes, and preserved the existing plugin configuration; subsequent project status reported the pre-existing plugin and all three Overlays as installed without drift.

## 2026-09-09T10:05:23+08:00 - Show separate OpenAI quota groups

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `lib/openai-usage-groups.mjs`, `plugins/openai-usage.ts`, `plugins/openai-usage-tui.ts`, `tests/openai-usage-groups.test.mjs`
- Summary: Display general and additional model quotas as separate groups in the upstream sidebar and usage dialog.
- Important records:
  - A live response contained only a weekly general window; Spark had independent five-hour and weekly windows, and gpt-reserve had its own weekly window. Missing general five-hour data is not evidence of unlimited usage.
  - The upstream 0.1.5 package remains unchanged. A version- and anchor-checked in-memory adapter extends its parsing, cache normalization, summary, and sidebar without extra requests or a copied plugin implementation.
  - The existing Windows state-path wrappers and upstream refresh lifecycle remain in use. Malformed optional windows are omitted; failed refreshes retain cached groups and show a stale warning in the sidebar.
  - Upgrading the pinned upstream package requires reviewing the adapter. No credentials, raw responses, or generated dependency files were added to source control.
- Portability: Module URLs resolve from the installed package; the existing home-relative Windows correction is preserved. Edited source files use LF.
- Chezmoi: Added the adapter and focused tests, updated both managed wrappers, and applied only the exact targets under the existing opencode marker.
- Verification: Three `node --test tests/openai-usage-groups.test.mjs` tests passed, covering group separation, cache round trips, legacy caches, absent/malformed windows, errors, sidebar rendering with stubs, and patch drift. Bun loaded the adapted TUI module. A live read-only request through the adapted parser returned general 7d, Spark 5h/7d, and gpt-reserve 7d. Actual terminal layout remains to be checked after restarting OpenCode.

## 2026-09-09T11:43:05+08:00 - Isolate Slim skills and Fable commands

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: Fable command payloads, agent and commands, `AGENTS.md`, ownership and registry documentation, `config/external-assets.json`, `scripts/opencode-assets.ps1`, `tests/opencode-assets-slim8.fixture.ps1`
- Summary: Moved Fable out of skill discovery and made the eight Slim bundled skills project-local through Asset Manager installation.
- Important records: Fable payloads now live under `config/assets/fable/` without `SKILL.md` entrypoints. Only explicit `/selfmade/fable`, `/fable-method`, `/fable-loop`, or `/fable-judge` commands authorize reading them; native skill grants were removed.
- Important records: Slim installation records project skill paths and hashes, refuses drift on update/removal, and establishes upstream `deleted` tombstones before adding the plugin. Existing global copies were backed up and removed; the upstream manifest must remain to prevent global recreation.
- Important records: Runtime backups are outside discovery roots at `~/.local/state/opencode/slim8-skills-isolation-backups/20260909T034251880Z-cd9cdbcb8fc248f0bc9655cbb3c9adc5` and `~/.local/state/opencode/fable-command-only-backup-20260909`. Existing application projects were not scanned or reinstalled; they need a scoped asset reapply to receive local skills.
- Portability: Project-relative skill destinations and home-relative payload/state paths; Slim upstream remains pinned to 2.2.10. Manually edited code/configuration files use LF.
- Chezmoi: Updated source first and applied exact runtime targets with run scripts excluded. Backups and upstream runtime manifest remain local state, not managed source.
- Verification: One isolated Slim fixture passed for migration, backup, tombstones, project installation, hashes, drift, removal and restore. Static Fable routing checks and edited-file line-ending checks passed. Actual global migration completed for all eight unchanged managed copies. No full suite, build, Fable workflow or application-project installation was run. Live discovery requires restarting OpenCode and has not been observed in this running session.

## 2026-09-09T15:48:27+08:00 - Bound autonomous work by user scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `AGENTS.md`, `agent/selfmade/subagents/Implementer.md`, `skills/chezmoi-management/SKILL.md`
- Summary: Replaced automatic validation with user-authorized verification and scope-based autonomy. Necessary edits and deployment proceed without per-command approval; extra checks, delegation and review require the corresponding user request.
- Important records: Removed conflicting unconditional verification instructions from Implementer and the chezmoi workflow. Retained existing auto-mode permissions and explicit command workflows. These are prompt constraints, not a new enforcement mechanism.
- Portability: Prompt-only changes; retained the existing source-directory template.
- Chezmoi: Updated managed source and applied only the three runtime prompt targets with scripts excluded; changelog included in scoped synchronization.
- Verification: No tests, builds, installations or review agents were run. Runtime behavior under the revised prompts remains unverified and requires restarting OpenCode.

## 2026-09-09T16:21:11+08:00 - Preserve host runtime for OpenAI usage sidebar

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `lib/openai-usage-groups.mjs`
- Summary: Resolve TUI imports of OpenTUI and Solid to host runtime module IDs instead of local package file URLs, so the adapted sidebar can share the host renderer and reactive context.
- Important records: Data URL imports bypass host source rewriting. Use `runtimeModuleIdForSpecifier` for the four supported TUI runtime specifiers; retain absolute resolution for other imports and the server entry. Preserve additional quota groups.
- Portability: Uses runtime module IDs without machine-specific paths; requires OpenCode's OpenTUI runtime support.
- Chezmoi: Updated the existing managed source and applied the exact runtime target with scripts excluded.
- Verification: Pre-fix isolated diagnosis showed normal file imports use the host module, the previous adapter bypasses it, and explicit runtime IDs use it. No post-edit functional tests were run. Actual sidebar display requires restarting OpenCode and remains unverified.

## 2026-09-11T14:45:48+08:00 - Enable opencode-claude-usage plugin

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode.json`
- Summary: Added the `opencode-claude-usage` npm plugin so the OpenCode TUI sidebar can display Claude account usage statistics.
- Important records:
  - Plugin spec pinned without a version tag; Bun installs the latest published version at startup.
- Portability: The plugin is resolved through npm and contains no machine-specific paths.
- Chezmoi: Updated `dot_config/opencode/opencode.json` scoped to this change.
- Verification: Scoped `chezmoi status` and `chezmoi diff` confirmed only this plugin entry changed; rendered target inspected after apply.

## 2026-09-11T14:58:30+08:00 - Move opencode-claude-usage to TUI config

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `tui.json`, `opencode.json`
- Summary: opencode-claude-usage is a TUI sidebar plugin and belongs in `tui.json` `plugin` array pairs; removed the mistakenly added entry from `opencode.json`.
- Important records:
  - On Windows, the plugin only supports OAuth-based fetch (env `CLAUDE_CODE_OAUTH_TOKEN` or `~/.claude/.credentials.json` or OpenCode `auth.json`); CLI probe and browser cookies are macOS/Linux only per upstream README.
- Portability: Same as before; no machine-specific paths introduced.
- Chezmoi: Updated `dot_config/opencode/tui.json` and reverted the `opencode.json` addition.
- Verification: Scoped `chezmoi apply` succeeded and rendered targets match source state.
## 2026-09-12T03:38:58+08:00 - Remove empty Fable skill directories

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `skills/fable-judge`, `skills/fable-loop`, `skills/fable-method`
- Summary: Deleted the empty source directories left behind when the Fable payloads moved to `config/assets/fable/`, so chezmoi no longer recreates unused skill folders in the runtime tree.
- Important records:
  - Git does not track empty directories, so the earlier rename commit looked complete while `chezmoi status` still reported `DA` for these paths.
  - The Fable content itself is unchanged and remains command-only under `config/assets/fable/`.
- Portability: Directory removal only; no machine-specific paths involved.
- Chezmoi: Removed `dot_config/opencode/skills/fable-judge`, `fable-loop`, and `fable-method` from the source state.
- Verification: `chezmoi status` no longer lists any `fable-*` entry.
