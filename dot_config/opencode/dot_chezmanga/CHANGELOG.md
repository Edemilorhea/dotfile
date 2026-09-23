# OpenCode Chezmoi Changelog

## 2026-09-22T09:25:00+08:00 - Allow Magic Context in the ESG project

- Status: Partial
- Machine: TC-TSENG
- Platform: Windows 10.0.26200 amd64
- Scope: `opencode.json.tmpl`
- Summary: Removed the V1 global DCP registration so Magic Context no longer detects a global V1 DCP conflict. The V2 global DCP registration remains available for ordinary V2 projects; this project requests a project-level DCP exclusion.
- Important records:
  - The project historian uses `anthropic/claude-sonnet-5`.
  - OpenCode's official V2 documentation does not document a project-level inherited-plugin exclusion syntax; the project uses the V2 negative entry as an experimental compatibility attempt.
- Portability: No machine-specific path or credential was added.
- Chezmoi: Updated the managed V1 template and applied it to the runtime target.
- Verification: Source and target synchronization and plugin startup logs remain to be checked after service restart.
- Remaining: Confirm whether the V2 negative plugin entry prevents `@tarquinen/opencode-dcp@3.2.0` from loading for this project.

## 2026-09-22T11:29:16+08:00 - Give the Asset Manager a V1/V2 runtime dimension

- Status: Completed
- Machine: TC-TSENG
- Platform: Windows 10.0.26200 amd64
- Scope: `scripts/opencode-assets.ps1`, `config/external-assets.json`,
  `config/skills-registry.md`, and the repository-root
  `run_onchange_after_install-opencode-external-assets.ps1.tmpl`
- Summary: The Asset Manager now installs for OpenCode V1, V2, or both, and
  refuses assets whose payload cannot run on a selected runtime instead of
  silently installing a broken one. Catalog schema moved to 5, the lock to 3,
  and the project manifest to 3.
- Important records:
  - New `runtimes` catalog block declares each runtime's command, config root,
    and plugin config key. `{configRoot}` in a target path is expanded per
    runtime. `OPENCODE_ASSETS_V1_CONFIG_ROOT` and
    `OPENCODE_ASSETS_V2_CONFIG_ROOT` override the root on a machine that does
    not isolate V2.
  - `Get-CanonicalPath` resolves every path segment through reparse points. When
    two runtimes resolve one target to the same real path, the manager installs
    once and records both runtime IDs. `agent/`, `commands/`, `skills/`, and
    `.oh-my-opencode-slim/` are junctions, so they install once; `plugins/` and
    `opencode.json` are separate, so they install once per runtime. Narrowing
    the runtime set now deletes the orphaned copy instead of leaking it.
  - `Set-ManagedPluginSpec` no longer refuses a config that already has the
    V2-native `plugins` key. It writes the spec under each selected runtime's own
    key, preserves hand-written `{ package, options }` entries, and strips the
    spec from a deselected key. The lock records `pluginConfig` as key/spec
    pairs; legacy `pluginSpecs` entries are read as the V1 `plugin` key.
  - Slim8 global tombstones are written for every known runtime config root, not
    only the selected ones, because a global copy in any root would shadow the
    project skills. Backup metadata moved to schema 2 with one record per target;
    restore still accepts schema 1.
  - Per-asset `runtimes` and `runtimeBlocked` drive the refusal. Default is every
    known runtime. `apply` throws unless `-SkipUnsupported` is passed; `list`,
    `plan`, `status`, and `doctor` report the reason; the TUI renders the item as
    `[-]` and cannot select it. A new TUI page picks runtimes after scope.
  - Runtime compatibility was verified against upstream code, not assumed:
    `oh-my-opencode-slim@2.2.22` exports both `server` and `setup`;
    `@dietrichgebert/ponytail` 4.9.0 and 4.10.0 default-export a V1 plugin
    function; `@opengsd/gsd-core` 1.10.0 and 1.14.0 deploy
    `.opencode/plugins/gsd-core.js`, which exports `{ server }` only. `gsd` and
    `ponytail` are now declared V1-only with those reasons.
  - V2 normalizes supported V1 config, so `mcp.<name>` and `permission.<key>`
    stay in V1 shape and work on both runtimes. Only the plugin key needed to
    diverge.
  - Fixed two latent bugs found while testing: `Test-Catalog` threw on an empty
    `overlays` array, and the removal manifest rebuild lacked `runtimeIds`.
  - `doctor` gained a runtime report, a shared-path report that proves which
    junctions really collapse, and `driftReasons` on each row.
  - The global lock path now comes from `managerPaths.globalLock` instead of a
    hardcoded V1 path. It stays one file, with runtime ownership per entry.
- Portability: All catalog paths stay `~`-relative. The V2 root matches the
  convention already hardcoded in `run_onchange_after_setup-opencode-v2.ps1.tmpl`
  and is overridable by environment variable for other machines.
- Chezmoi: Updated four existing managed files and applied the three under
  `dot_config/opencode`. The lock files and `.agents/skills` payloads remain
  outside chezmoi by design.
- Verification: `pwsh` parsed the script cleanly and `chezmoi status` for the
  three applied targets is clean and LF-only. Throwaway catalogs in `%TEMP%`
  exercised shared-target dedupe, per-runtime splitting, stale-path pruning on
  narrowing, the explicit-asset refusal, `status` reporting `unsupported`, the
  plugin key matrix across v1/v2/v1+v2 transitions with a hand-written V2 entry
  present, and removal cleanup; all probe fixtures were deleted afterwards.
  `slim8-migration -MigrationMode plan` against the pinned revision reported one
  deduplicated target covering both runtimes with tombstones ready.
  `apply -Scope global -Profiles core -Runtimes v1,v2` re-recorded the 16 core
  assets, and `doctor -Scope global` now reports `valid=True` with zero drift.
  The interactive TUI was not launched. The two legacy `claude-marketplace`
  entries still carry no runtime IDs and will show `runtime-coverage` drift until
  the `claude` profile is re-applied.
  `run_onchange_after_install-opencode-external-assets.ps1` remains pending in
  `chezmoi status`; its only effect is the global apply already performed.

## 2026-09-22T11:05:00+08:00 - Drop three v1 plugins that builtins or skills already cover

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / AMD64
- Scope: `opencode.json`
- Summary: Removed `opencode-large-image-optimizer`, `opencode-chrome-devtools`, and `opencode-command-inject` from the v1 `plugin` array, and added an `attachment.image` block so image downscaling keeps the behavior the removed plugin provided.
- Important records:
  - `opencode-large-image-optimizer` duplicated a builtin. V1 already resizes image attachments through `attachment.image`, and v2 renamed the same settings to `media.image`. The plugin targeted 1568px, Anthropic's internal downscale target, while the builtin defaults to 2000px, so the new block pins 1568px to preserve behavior. The builtin covers prompt attachments and the `read` tool; images returned by MCP or other plugin tools are the one case the plugin also caught.
  - `opencode-chrome-devtools` shipped only 7 basic CDP tools. A string scan of its bundle found no `Performance.`, `Network.enable`, `Runtime.consoleAPICalled`, `Profiler.`, or `Tracing.` usage, so it never provided the DevTools capabilities its name suggests. The `playwright`, `playwright-cli`, `playwright-trace`, and `agent-browser` skills already cover v1 browser work. Its only unique ability was attaching to an arbitrary external CDP endpoint, such as an Electron app.
  - `opencode-command-inject` auto-generated `/make:<target>`, `/<runner>:<script>`, and `/skill:<name>` commands. Skills and argument substitution are native in both versions, so only Makefile and package-script discovery was lost. Restore it by putting `"opencode-command-inject@1.3.0"` back in the array.
  - None of the three can run in v2 anyway: all are v1 implementations with no `Plugin.define` or `setup()` export.
- Portability: The `attachment.image` block contains only numeric limits. No machine path was added.
- Chezmoi: Updated `dot_config/opencode/opencode.json.tmpl`.
- Verification: `chezmoi diff` showed only the three removals, the removal comment, and the new `attachment` block; `chezmoi apply` and a follow-up scoped `chezmoi status` both exited clean. The file keeps its existing JSONC comment style. Runtime behavior is unverified until v1 restarts.

## 2026-09-22T10:12:00+08:00 - Correct the V1 and V2 boundaries in AGENTS.md

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / AMD64
- Scope: `AGENTS.md`
- Summary: Replaced the "V1 and V2 boundaries" section with the layout that the two installations actually use. The old text claimed that V1 reads `command/` and V2 reads `commands/`, and that the two versions share one configuration tree.
- Important records:
  - `~/.config/opencode/command/` does not exist. Both versions read `commands/`. V1 documents plural subdirectory names with singular names kept for backwards compatibility, so the old rule had no basis.
  - The versions do not share one configuration tree. V1 uses `~/.config/opencode`; V2 uses `~/.config/opencodev2/opencode`, because `opencode2.cmd` sets `XDG_CONFIG_HOME` to `~/.config/opencodev2`. Only `agent/`, `commands/`, `skills/`, `.oh-my-opencode-slim/`, and `AGENTS.md` are linked back to the v1 tree.
  - `opencode.json`, `plugins/`, terminal preferences, and data directories are separate per version. V1 uses the singular `plugin` array and `tui.json`; V2 uses the plural `plugins` array and `cli.json`. `tools/` reaches V1 only, because V2 removed file-based custom tools.
  - Verified against the running v2 service rather than documentation alone: `opencode2 api get /api/agent` returns path-derived IDs such as `selfmade/subagents/CodeInvestigator` while the v2 `opencode.json` defines no `agents`, which proves v2 loads the shared `agent/` directory. `api get /api/command` matches `~/.config/opencode/commands/` exactly.
  - The path-derived agent ID rule and the shared-`skills/` installation rule were correct and were kept.
- Portability: The section names `~/.config/opencodev2` and `~/.opencode-v2`, which exist only on this machine, inside a paragraph that already declares them machine-specific. No other file gained a machine path.
- Chezmoi: Updated `dot_config/opencode/AGENTS.md.tmpl` and applied it.
- Verification: `chezmoi diff` showed only the intended section; `chezmoi apply` and a follow-up scoped `chezmoi status` both exited clean. The template remains LF-only.

## 2026-09-21T22:49:19+08:00 - Templatize MCP server paths and repair them on this machine

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: Microsoft Windows NT 10.0.26200.0 / X64
- Scope: `opencode.json`, now `opencode.json.tmpl`
- Summary: `jev-review`, `office-mcp`, and `markitdown` all reported `Failed`
  in the MCP server list because the config hard-coded `C:\Users\tc_tseng\...`
  absolute paths from the machine that installed them, and none of the three
  servers existed here. The MCP paths are now rendered from
  `.chezmoi.homeDir`, `jev-review` and `markitdown` are installed locally, and
  `office-mcp` is disabled until its sources are restored.
- Important records:
  - The 2026-09-21T10:22:31 entry already predicted this: it recorded the
    `tc_tseng` literals as a known portability debt to "convert to a template
    when a second machine or user is added". This is that second machine.
  - `jev-review` was re-cloned from https://github.com/NiazMorshed2007/jev-review
    at commit `57690af54ef7d862c2483342c1e61c14dffcf727` into
    `~/.local/share/opencode/jev-review`, per the earlier entry's recovery
    note. The committed `dist/server.js` runs directly; no `npm install` ran.
    That directory stays unmanaged because `.chezmoiignore.tmpl` excludes
    `~/.local/share/opencode/` on Windows.
  - `markitdown-mcp` 0.0.1a7 was installed with `pip install markitdown-mcp`
    into the user Python 3.13 at
    `~/AppData/Local/Programs/Python/Python313`. Its console script is already
    on PATH, so the config keeps the bare `markitdown-mcp` command and needs no
    path template.
  - `office-mcp` is a locally built Python server. Neither chezmoi nor any
    changelog records an upstream, and `~/.local/share/opencode/office-mcp`
    does not exist here, so it cannot be rebuilt. Its entry is kept, templated,
    and set to `"enabled": false` with a comment describing how to restore it.
    The `office-documents` skill stays unusable until then.
  - `JEV_API_KEY` is still unset on this machine. The server starts and lists
    `jev_review` without it; the key is only needed when the tool is called.
- Portability: All MCP paths now render from `{{ .chezmoi.homeDir }}`, which
  chezmoi returns with forward slashes on Windows, so the rendered JSON needs
  no backslash escaping and matches the repository's forward-slash convention.
  Remaining machine-specific assumption: both `jev-review` and `office-mcp`
  expect their unmanaged directories under `~/.local/share/opencode/`, which
  every new machine must recreate by hand.
- Chezmoi: renamed `dot_config/opencode/opencode.json` to
  `dot_config/opencode/opencode.json.tmpl` and templated its MCP paths.
- Verification: `chezmoi status` is empty for the applied target. The rendered
  `~/.config/opencode/opencode.json` contains no `tc_tseng` occurrence and is
  pure LF. `git -C ~/.local/share/opencode/jev-review rev-parse HEAD` reports
  `57690af54ef7d862c2483342c1e61c14dffcf727` and `dist/server.js` exists;
  `node --version` is v24.15.0, above the required 20. `markitdown-mcp --help`
  runs and confirms STDIO is its default transport. Live MCP startup for this
  v1 config is unverified; restart OpenCode v1 to load it.

## 2026-09-21T18:15:00+08:00 - Strengthen command and process lifecycle safety

- Status: Completed
- Machine: TC-TSENG
- Platform: Windows x64
- Scope: `AGENTS.md.tmpl`
- Summary: Added an explicit lifecycle gate for shell commands, persistent services, test servers, readiness probes, PID cleanup, and timeout handling.
- Important records:
  - Foreground servers, watchers, TUIs, polling loops, and log followers are prohibited.
  - A process started for a task must have a recorded PID and bounded cleanup path.
- Portability: Uses Windows `Start-Process -PassThru` wording while retaining platform-neutral lifecycle rules.
- Chezmoi: Updated the managed shared agent instructions.
- Verification: Source edit completed; scoped apply and runtime behavior verification remain pending.

## 2026-09-21T18:30:00+08:00 - Keep Opus 5 as the default model and limit Fable to adversarial agents

- Status: Completed
- Machine: TC-TSENG
- Platform: Windows x64
- Scope: `opencode.json`
- Summary: Set the global model and the `plan` agent to `anthropic/claude-opus-5` so new sessions no longer default to the more expensive Fable model.
- Important records:
  - `plan` is the configured default primary agent, so its model determined the effective default. `general` is a subagent and cannot be a default primary agent.
  - `Skeptic` and `RedTeam` intentionally keep `anthropic/claude-fable-5-1`; manual model selection is unaffected.
- Portability: Model identifiers only; no machine-specific values.
- Chezmoi: Updated the managed V1 configuration source.
- Verification: Source edit completed; scoped apply and a new-session model check remain pending.

## 2026-09-21T16:21:23+08:00 - Make implementation-understanding output readable: scenario sentence first, author checklists internal

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: config/assets/skills/implementation-understanding-tutor/{SKILL.md,
  references/full-feature-example.md, evals/evals.json},
  config/assets/skills/implementation-understanding-code-teach-contract/SKILL.md,
  config/assets/skills/implementation-understanding-quality-contract/SKILL.md,
  config/assets/skills/implementation-understanding-report-contract/SKILL.md
- Summary: A live Code Teach session on a 1043-line handler showed the skill
  was complete but painful to read: six meta headings per guided unit, the
  same method rendered three times (map, five-field causal node, walkthrough),
  a `Confirmed` tag on every paragraph, and no fixed slot answering "why does
  this code exist" in the user's language. The reader's own words were "我根
  本不知道你為了什麼而做". Rewrote the output rules so the author's
  completeness checks stay internal and the reader gets a scenario sentence
  before every code block.
- Important records:
  - Explanation chain is now `為了什麼 → Responsibility → Input/Pre-state →
    Result → Handoff → Downstream impact`. The new first slot is a scenario
    sentence in user-facing language, taken from the shared example; the
    example is promoted from decoration to skeleton.
  - Reading budget is measured in structural elements (1 diagram or table,
    3 code blocks per round), not code lines. Progress, lens, and goal
    collapse to one opening line; content headings are named by question or
    scenario step, not work stage.
  - The five-field causal node is now an internal self-check in
    code-teach-contract ("內部 Causal Node"); it is not rendered. The
    Method-chain map is the only diagram in a Code unit.
  - Confidence: `Confirmed` is the default and not written; only `Inferred`
    and `Unknown` are labelled, with reasons.
  - Evidence rules (file:line-range, caller-first, Unknown over invention)
    are unchanged; they caught a wrong claim during the session and stay.
  - Guided and Focused skeletons in the tutor were replaced; Report six-layer
    headings are unchanged. full-feature-example.md Layer 4 groups now open
    with a scenario sentence instead of a rendered node. evals.json
    assertions 4, 7, 8, 9, 10, 11, 12 updated to the new format.
  - `opencode-assets.ps1 -Assets <ids>` still applies the whole profile
    recorded in assets.lock.json (`core`), so the sync re-ran all 16 core
    assets including skills-cli clones. First attempt hit the 120 s tool
    timeout mid-clone; second attempt completed. Lock file is not managed.
- Portability: No absolute paths added; all content is prose and JSON.
- Chezmoi: Updated six managed files under
  dot_config/opencode/config/assets/skills/implementation-understanding-*.
  Applied the four skill directories with scoped `chezmoi apply`, then
  synced ~/.agents/skills copies via the core asset profile.
- Verification: evals.json parses. Grep for `five-field`, rendered `causal
  node`, `閱讀進度`, `本次理解目標`, `Evidence 與導讀` finds only internal-check
  or negative-example mentions. All six source files LF-only. Scoped
  `chezmoi status` is clean for the four skill directories. SHA256 of the
  four ~/.agents/skills SKILL.md files match ~/.config copies. Pre-existing
  unrelated pending source (love-tutor content profile) was left unapplied.
  Live teaching behaviour with the new format is unverified; restart
  OpenCode to load it.

## 2026-09-21T10:22:31+08:00 - Install jev-review MCP and require it for code review

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: opencode.json, AGENTS.md.tmpl, commands/selfmade/review.md,
  skills/jev-review/, and `~/.opencode-v2/xdg/config/opencode/opencode.json`
- Summary: Registered the `jev-review` local MCP server (tool `jev_review`,
  shown as `jev-review_jev_review`) in both the v1 and v2 OpenCode configs,
  installed its `jev-review` skill, and added an AGENTS.md rule plus a `/review`
  step so code-review tasks call `jev_review` for per-dimension quality scores.
- Important records:
  - Upstream: https://github.com/NiazMorshed2007/jev-review, cloned at commit
    `57690af54ef7d862c2483342c1e61c14dffcf727` into
    `~/.local/share/opencode/jev-review`. The committed `dist/server.js`
    bundle runs directly with Node 20+; no `npm install` is needed. Update with
    `git pull` in that directory.
  - The clone lives beside `office-mcp` under `~/.local/share/opencode/`,
    which `.chezmoiignore.tmpl` excludes on Windows, so it is deliberately
    unmanaged. Re-clone it on a new machine before the MCP entry can start.
  - `JEV_API_KEY` is referenced as `{env:JEV_API_KEY}` and is not stored in
    any managed file. The server starts and lists `jev_review` without the key;
    the key is only needed when the tool is called. The user will set it later.
  - `skills/jev-review/SKILL.md` is a verbatim copy of the upstream skill,
    normalized from CRLF to LF to match the repository convention.
  - Review context (task, diff, files) is sent to `https://api.typesafe.ai`;
    the AGENTS.md rule forbids sending secrets, `.env`, vendored, or unrelated
    content.
- Portability: The MCP `command` uses the same hard-coded
  `C:\Users\tc_tseng\...` form as the existing `office-mcp` entry; both
  `opencode.json` files are still plain (non-template) files. Convert to a
  template when a second machine or user is added.
- Chezmoi: Updated `dot_config/opencode/opencode.json`,
  `dot_config/opencode/AGENTS.md.tmpl`,
  `dot_config/opencode/commands/selfmade/review.md`,
  `dot_opencode-v2/xdg/config/opencode/opencode.json`; added
  `dot_config/opencode/skills/jev-review/SKILL.md`.
- Verification: Stdio probe of `dist/server.js` without `JEV_API_KEY` returned
  serverInfo `jev-review 0.1.1` and tools `[jev_review]`. Scoped
  `chezmoi apply` then `chezmoi status` is clean for all targets. Both rendered
  `opencode.json` files parse and point at an existing `server.js`; the v2
  junction exposes `skills/jev-review/SKILL.md` and the Jev section in
  `AGENTS.md`. The running OpenCode session registered the `jev-review` MCP
  server and skill. Touched source files are LF only. A live `jev_review`
  call is unverified until the key is set.

## 2026-09-21T00:00:00+08:00 - Install the TypeSafe agent skill manually

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: skills/typesafe-ai/
- Summary: Added the upstream `typesafe-ai` skill so OpenCode can load TypeSafe
  guidance for System One primitives, routing patterns, and API/SDK work.
- Important records:
  - Upstream ships this skill as a Claude Code plugin marketplace entry
    (`typesafe-ai/skills`) or via `npx skills add`. Neither targets OpenCode's
    `skills/<id>/SKILL.md` layout, so the skill was installed manually from
    `https://raw.githubusercontent.com/typesafe-ai/skills/main/skills/typesafe-ai/SKILL.md`.
  - The upstream frontmatter `license: MIT` key was dropped to match the
    name/description-only convention used by the other local skills. The MIT
    text is kept as `skills/typesafe-ai/LICENSE` for attribution.
  - The skill carries no reference files upstream; its body points at live
    `docs.typesafe.ai` Markdown pages, so updates mostly arrive through the docs
    rather than the file. Refresh the file by re-fetching the raw SKILL.md.
- Portability: No machine-specific paths. Markdown only, so it applies unchanged
  on every machine.
- Chezmoi: Added `dot_config/opencode/skills/typesafe-ai/SKILL.md` and `LICENSE`.
- Verification: Scoped `chezmoi apply` then `chezmoi status` for
  `~/.config/opencode/skills/typesafe-ai` is clean. Both files are visible
  through the v2 junction at
  `~/.opencode-v2/xdg/config/opencode/skills/typesafe-ai`, and the running
  OpenCode session registered the `typesafe-ai` skill.

## 2026-09-18T10:57:11+08:00 - Add knowledge scaffolding and bounded gap handling to Mentor

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: agent/selfmade/subagents/learning/Mentor.md
- Summary: Full-guidance mode now emits conditional prerequisite knowledge and a
  minimal teaching example, and a new bounded rule lets Mentor flag a
  comprehension gap once at a work boundary instead of interrupting active
  implementation.
- Important records:
  - Mentor referenced only LearningAgent and had no link to Facilitator or
    Deconstructor, so a user who never typed `/socratic` or `/feynman` never
    reached them. The gap was closed inside Mentor rather than by merging or
    auto-invoking those subagents.
  - Knowledge gaps and wrong mental models are handled separately. Saying "I do
    not know how" stays a knowledge gap and routes to full-guidance mode; only
    verified contradictions qualify as a comprehension gap.
  - TODO mode already produced prerequisite knowledge and a minimal teaching
    example, but full-guidance mode did not, so the user who needed the most
    explanation received the least. The new section reuses the TODO-mode
    condition and skips output when the concept was already explained or an
    in-project reference exists.
  - Comprehension-gap evidence is limited to two verifiable signals: stated
    intent contradicting workspace code, and the same wrong concept recurring
    within a ticket. Speculation must report `unknown` and stay at Level 0.
  - Detection is automatic but escalation requires consent. Level 1 is a single
    sentence plus a choice at a boundary, capped at once per
    `current_main_task`. Level 2 is at most two questions and never alters the
    task map. Nothing may interrupt active writing, running, or debugging.
  - Level 2 stays inline instead of delegating to Facilitator or Deconstructor,
    because Mentor is `mode: all` and is itself a subagent when routed by
    LearningAgent, where nested delegation is unreliable. Full verification is
    still handed back to the user through `/feynman` or `/socratic`.
- Portability: Prose-only agent instructions with no machine-specific paths.
- Chezmoi: Already managed; source updated and applied with scoped
  `chezmoi apply`.
- Verification: `git diff --stat` reports 46 insertions and 0 deletions, so no
  existing rule was modified or removed; the file remains pure LF with 169 line
  endings. Scoped `chezmoi status` for the target is clean after apply. The new
  instructions were not exercised in a live Mentor session.

## 2026-09-16T15:26:24+08:00 - Make communication guidance always-on

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: AGENTS.md.tmpl communication contract
- Summary: Added a compact always-on communication contract to global `AGENTS.md` so response quality does not depend on the model remembering to load a communication skill.
- Important records:
  - The contract applies the core `iso-24495-plain-language` and `asd-ste100` behaviors directly: answer first, clear structure, direct sentences, explicit procedure conditions and results, stable terminology, and preserved technical constraints.
  - `eli5-explainer` and `wait-what` remain conditional because forcing them on every response can add unnecessary analogies, headings, or recovery behavior.
  - The skills remain available as deeper references when their full method is needed; the configuration does not claim that a skill was loaded when it was not.
- Portability: The rule is rendered into the global `AGENTS.md` from the existing portable chezmoi template and uses skill names that are discovered from the user's global skills directories.
- Chezmoi: Updated the existing managed `dot_config/opencode/AGENTS.md.tmpl` and this managed changelog.
- Verification: Inspected the four communication skills, replaced the load-dependent routing with an always-on contract, and preserved LF line endings in the edited template.

## 2026-09-16T15:21:15+08:00 - Bridge Windows OpenCode auth path for Claude usage

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: run_once_before_windows_config_junctions.ps1.tmpl and Windows OpenCode auth path
- Summary: Added a Windows junction from `%APPDATA%/opencode` to `~/.local/share/opencode` so `opencode-claude-usage` can read OpenCode's auto-refreshing Anthropic OAuth credentials.
- Important records:
  - The existing real `%APPDATA%/opencode` directory was backed up as `opencode_backup_20260916_141424` before the junction was created.
  - Removed the User-level `CLAUDE_CODE_OAUTH_TOKEN` environment variable so the plugin uses the OpenCode OAuth credential instead of short-lived or manually managed token data.
  - The token value was not written to chezmoi or this changelog.
- Portability: The junction is created only by the Windows-specific chezmoi run-once script and uses `$env:USERPROFILE`, `$env:APPDATA`, and the existing `.local/share/opencode` layout.
- Chezmoi: Updated the existing managed junction script and this managed changelog.
- Verification: `chezmoi apply --verbose "$env:USERPROFILE/windows_config_junctions.ps1"` completed; `%APPDATA%/opencode` is a junction targeting `~/.local/share/opencode`, and `auth.json` is reachable through the junction. User-level `CLAUDE_CODE_OAUTH_TOKEN` is unset.

## 2026-09-15T20:49:04+08:00 - Update DCP, retune auto-compression, add model tier switcher

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: opencode.json, dcp.jsonc, config/model-tiers.json, scripts/oc-model.ps1
- Summary: Bumped the pinned DCP plugin from 3.1.14 to 3.1.15, retuned DCP
  auto-compression so turn nudges start much later and user messages are
  preserved, and added a one-command switcher that moves every agent tier
  between the OpenAI and Anthropic subscriptions.
- Important records:
  - DCP is pinned by version in the plugin list, so `autoUpdate` never upgraded
    it. 3.1.15 fixes Windows `protectedFilePatterns`, the stuck-mode bug after
    manual compression, installation on recent OpenCode 1 builds, and the
    injected `mXXXX</parameter>` message suffix.
  - Frequent compression came from the turn-nudge path in DCP's nudge injector:
    once context passes `minContextLimit`, every user turn schedules a nudge and
    that path ignores `nudgeFrequency`. Absolute 50000/100000 thresholds were
    only 25%/50% of a 200K window, so the nudges began very early.
  - Thresholds are now percentages (`minContextLimit` 60%, `maxContextLimit`
    80%) so they scale per model. `turnProtection` is enabled (4 turns) and
    `protectUserMessages` is true, keeping recent turns and user intent intact.
    Automatic compression stays on; manual mode was deliberately not used.
  - `config/model-tiers.json` is the single tier registry: T1 deep reasoning and
    global default, T2 general work, T3 implementation. Each tier lists the
    OpenAI model, the Anthropic model, and the agents that belong to it. The
    tier membership matches the existing `fallback.json` grouping.
  - `scripts/oc-model.ps1` rewrites `opencode.json` (global default plus agent
    block), the `model:` frontmatter in `agent/**/*.md`, each agent entry in
    `fallback.json`, and the `active` field in the registry. Switching also
    flips the failover order so the inactive provider is tried first on error.
  - The switcher replaces any known model of a tier, not only the recorded
    active one, so repeated or interrupted runs converge to the same result.
    `-Tier` allows mixed setups; `-NoApply` skips deployment.
- Portability: The script resolves the source root through
  `chezmoi source-path ~/.config/opencode` instead of hard-coded paths, uses
  forward slashes, and writes LF without BOM to match the repository
  `* text=auto eol=lf` rule. It requires PowerShell 7 and chezmoi on PATH.
- Chezmoi: opencode.json and dcp.jsonc updated in source; model-tiers.json and
  oc-model.ps1 added; all four applied with scoped `chezmoi apply`.
- Verification: `oc-model.ps1 status` reports `Active provider: openai`; a
  full `anthropic` then `openai` round trip with `-NoApply` returned all six
  affected files to their original SHA256 values; a `-Tier T3` switch produced
  the `mixed (anthropic + openai)` status and reverted cleanly. Scoped
  `chezmoi status` for the four targets is clean after apply, and the applied
  `dcp.jsonc` and `opencode.json` show the new values. OpenCode was not
  restarted, so the new plugin version and settings are not yet exercised at
  runtime.

## 2026-09-15T10:02:54+08:00 - Package Love Tutor skill profile

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `config/external-assets.json`, `config/assets/skills/`, `config/assets/love-tutor.md`
- Summary: Added the project-scoped `love-tutor` profile and a seven-skill copy-template bundle for one-command installation.
- Important records:
  - Preserved skill payloads, references, tools, licenses and example profiles; excluded Git metadata, caches and platform metadata.
  - Existing project skill folders remain independent; the installer retains its unmanaged-path overwrite protection.
  - The source summaries library, project AGENTS.md and Python dependency installation are outside this bundle.
- Portability: Catalog sources use home-relative paths; installation targets use project-relative paths.
- Chezmoi: Added asset snapshots and documentation in source state; updated the managed catalog for scoped deployment.
- Verification: Inspected existing copy-template installation behavior and source changes; catalog uses consistent LF. Functional installation testing was not requested.

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

## 2026-09-14T14:25:34+08:00 - Configure tiered automatic model fallback

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode.json`, `fallback.json`
- Summary: Registered `opencode-auto-fallback@0.4.59` and configured cross-provider fallback pairs for T1 heavy reasoning, T2 light reasoning, and T3 implementation.
- Important records:
  - Removed the commented legacy fallback plugin registration; its old configuration and installed package are retained but inactive.
  - Explicit agent chains and an empty default fallback pool prevent T2/T3 failures from escalating into T1. New agents require an explicit chain.
  - T1 pairs gpt-6-astra with claude-fable-5-1; T2 pairs gpt-5.6-sol-fast with claude-opus-5; T3 pairs gpt-5.6-luna with claude-sonnet-5.
  - Removed eight T2 high variants. Implementer xhigh remains pending a separate decision.
  - Automatic updates and large-context switching are disabled; cooldown is 60 seconds, maxRetries is 2, and logging is enabled.
- Portability: Provider/model IDs and configuration are machine-neutral; no new absolute paths or credentials.
- Chezmoi: Updated configuration source, added managed fallback.json, and applied only the intended targets with scripts excluded.
- Verification: Scoped apply succeeded and configuration status is clean. Both edited JSON files use LF. Plugin loading and live subscription-error recovery have not been tested; restart OpenCode to load the plugin.

## 2026-09-15T18:09:43+08:00 - Enable built-in LSP servers

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode.json`
- Summary: Added the top-level `"lsp": true` option so OpenCode starts its built-in language servers on demand.
- Important records:
  - OpenCode disables LSP when the top-level `lsp` option is omitted. The existing `permission.lsp: "allow"` only authorizes the LSP tool and does not start any server.
  - Servers start only when a matching file extension is opened and the language requirement is met, for example a project `typescript` dependency, a `pyright` dependency, or an available `go` command.
  - Some servers download automatically. `OPENCODE_DISABLE_LSP_DOWNLOAD=true` disables that download.
  - The apply also delivered the previously unapplied NotebookLM MCP change to the runtime, replacing `notebooklm-mcp@latest` with `@charlie.act7/gemini-notebook-mcp@2.3.11`. The user chose the chezmoi source as authoritative.
- Portability: The boolean option is machine-neutral and adds no absolute paths.
- Chezmoi: Updated the existing managed OpenCode configuration and applied only its runtime target.
- Verification: Scoped `chezmoi diff` showed the intended change, `chezmoi apply` succeeded, scoped `chezmoi status` was clean, and both source and runtime files remained LF-only. Language-server startup was not tested; restart OpenCode to load the new configuration.

## 2026-09-17T15:12:00+08:00 - Remove the undocumented remove-tag.js plugin

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `plugins/remove-tag.js`, `.chezmoiremove` in the chezmoi source root
- Summary: Deleted a 27-line plugin that rewrote the assistant identity line in the
  system prompt. It is no longer loaded by OpenCode v1 and will not be carried into v2.
- Important records:
  - The file was created 2026-02-04, entered chezmoi on 2026-07-14, and had no
    changelog entry, so its origin could not be established. Its content matches a
    community snippet that strips "the best coding agent on the planet" from the
    system prompt.
  - It was never listed in `opencode.json` or `tui.json`. `opencode debug config`
    showed OpenCode v1 loading it through directory discovery of top-level files in
    `plugins/`, alongside `notify.ts` and `openai-usage-tui.ts`, for 16 resolved
    plugins in total.
  - It used `experimental.chat.system.transform`, a v1 hook marked experimental. The
    v2 equivalent is `ctx.session.hook("context")`, so a port would have to be
    rewritten rather than copied.
  - `.chezmoiremove` now carries the target so other machines drop it on the next apply.
- Portability: The removal is machine-neutral and adds no absolute paths.
- Chezmoi: Ran `chezmoi forget` on the target, deleted the runtime file, and recorded
  the target in `.chezmoiremove`.
- Verification: `chezmoi source-path` reports the target as not managed, the runtime
  file is gone, and `plugins/` now holds only `notify.ts`, `openai-usage.ts`, and
  `openai-usage-tui.ts`. Restart OpenCode to drop the plugin from the running server.

## 2026-09-18T14:58:44+08:00 - Realign agents, commands, and skills with three months of session evidence

- Status: Completed
- Machine: tc-tseng
- Platform: Windows x64
- Scope: gent/selfmade/**, commands/selfmade/**, skills/change-verification,
  config/assets/skills/implementation-understanding-tutor,
  config/assets/skills/copywriting, config/assets/skills/copy-editing,
  config/external-assets.json, config/skills-registry.md, .chezmoiremove
- Summary: Reviewed 581 OpenCode sessions (2026-06-18 to 2026-09-18) for user
  corrections and rewrote the definitions whose defaults contradicted them.
  Mentor now delivers complete guidance by default (TODO scaffolding is opt-in),
  uses the agreed 要做什麼/為什麼做/怎麼做 bundle with [新增]/[修改]/[刪除],
  line ranges, and paste-ready code, and no longer runs the understanding-gap
  questioning. Navigator, Facilitator, and Deconstructor lost their theory
  sections and keep only operational rules. Skeptic, RedTeam, and Simplifier
  must classify requirements outside the contract as OUT_OF_SCOPE and may not
  propose new mechanisms. LearningAgent may run read-only git so it can read
  diffs itself. /adv-review caps its report at three expanded blockers.
  /mr ignores uncommitted files. /linear-plan and /linear-review treat
  project-level deliver-*/develop-* skills as optional. /worklog writes Jira
  output to ~/Documents/jira/<range>.md with values only.
  implementation-understanding-tutor no longer exposes parameters; users
  choose scope, one of four views, and one of three delivery modes in natural
  language. change-verification reports pre-existing failures as UNRELATED
  without blocking. Deleted /deep, /cif, /jira_log_Create,
  /chezmoi-audit, and the three /supermemory-* commands (zero use).
  Moved copywriting and copy-editing out of the global skill directory
  into the optional content asset profile.
- Important records:
  - Evidence came from ~/.local/share/opencode/opencode.db (message and part
    tables); the most frequent corrections were scope expansion, learning output
    format, unnecessary questions, slow subagent workflows, and unexplained
    jargon.
  - config/external-assets.json in the chezmoi source was already ahead of the
    runtime copy (love-tutor profile, human-skill-tree revision); applying the
    new content profile also deployed those pending source changes.
  - The global core asset profile was re-applied so ~/.agents/skills copies of
    the implementation-understanding skills match the new source.
  - Project-specific facts (no EF migrations, build fast path, conventions,
    Bizform subjectTypeId) were written to E:/Project/GSS_ESG2412/AGENTS.md,
    which is outside chezmoi and excluded from that repository's git index.
- Portability: No absolute paths were added to shared files; /worklog uses
  ~/Documents/jira. .chezmoiremove carries the deleted commands and moved
  skill directories so other machines drop them on apply.
- Chezmoi: Updated managed files, deleted seven command sources, moved two skill
  directories with git mv, applied scoped targets, and removed the runtime
  copies of deleted and moved paths.
- Verification: Scoped chezmoi status is clean for every touched target;
  xternal-assets.json parses; all edited sources are LF-only;
  ~/.agents/skills/implementation-understanding-tutor/SKILL.md hash matches
  the source. Agent behaviour in live sessions is not yet exercised; restart
  OpenCode to load the new definitions.

## 2026-09-18T23:39:13+08:00 - Deploy the pending asset manager script and frontmatter metadata

- Status: Completed
- Machine: tc-tseng
- Platform: Microsoft Windows 10.0.26200 / X64
- Scope: `scripts/opencode-assets.ps1`, `config/assets/skills/human-skill-tree-frontmatter.json`
- Summary: Applied two managed targets that had been committed on 2026-09-12 but
  never written to this machine. The asset manager can now inject managed
  frontmatter into skills-cli assets, and its TUI hides `provenance-only`
  entries that cannot be installed.
- Important records:
  - Earlier today the new `content` profile was applied, which also carried the
    pending `external-assets.json` revision. That file declares a `frontmatter`
    block for `human-skill-tree` pointing at
    `~/.config/opencode/config/assets/skills/human-skill-tree-frontmatter.json`,
    but the deployed script had no `Add-SkillsCliFrontmatter` function and the
    metadata file was absent. Installing or refreshing that asset would have
    produced skills without frontmatter. Applying both targets removes the
    mismatch.
  - The script gains `Add-SkillsCliFrontmatter`, a `Test-Catalog` rule that
    restricts `frontmatter` to the `skills-cli` channel and rejects wildcard
    skill lists, a `selectableAssets` filter that keeps `provenance-only` assets
    out of the TUI counts and pickers, and an overlay array-construction fix.
  - The deployed copy held no local edits; every difference was an older version
    of a line the 2026-09-12 commit replaced, so applying lost nothing.
- Portability: Both files were already managed and machine-neutral. The
  frontmatter source path is expressed with `~` in `external-assets.json`.
- Chezmoi: Applied the two existing managed targets only. No source file was
  modified and no `run_` script was triggered.
- Verification: Scoped `chezmoi status` is clean for both targets, the deployed
  script now resolves `Add-SkillsCliFrontmatter` at line 752, and the metadata
  file exists. The asset manager was not executed, so frontmatter injection is
  unverified at runtime.

## 2026-09-21T15:12:17+08:00 - Upgrade oh-my-opencode-slim to the dual-host 2.2.22 release

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / X64
- Scope: `config/external-assets.json`, `scripts/opencode-assets.ps1`,
  `config/skills-registry.md`, `tests/opencode-assets-slim8.fixture.ps1`
- Summary: The `oh-my-opencode-slim` asset now pins `2.2.22` (revision
  `3685293ae6896deca1d85a14a38ba47510a50add`). That release exports
  `{ id, server, setup }`, so OpenCode V1 (`server()`, >=1.18.29) and OpenCode
  V2 (`setup()`, >=2.0.7) load the same npm spec from the same project
  `.opencode/opencode.json`. No V1/V2 split is needed in the Asset Manager.
- Important records:
  - The manager keeps writing the V1-shaped `plugin` array because V2
    normalizes it in memory and V1 would crash on V2-only shapes. A new
    `Set-ManagedPluginSpec` helper refuses to touch a project config that
    already has the V2-native `plugins` key, since V2 would then silently
    ignore the `plugin` array the manager writes.
  - `Set-ManagedPluginSpec` also removes the previous lock entry's
    `pluginSpecs` before adding the new spec. Before this fix, re-running
    `apply` after a version bump left both `@2.2.10` and `@2.2.22` in the
    project config. Both `opencode-plugin` code paths (slim and ponytail) use
    the helper.
  - The 8-skill `Slim8SkillNames` list is unchanged. `2.2.22` ships a ninth
    directory, `src/skills/loop-engineering`, but it is not in the upstream
    `CUSTOM_SKILLS` registry, so the plugin never syncs it and no tombstone is
    required.
  - The plugin resolves its tombstone manifest from `XDG_CONFIG_HOME`, so the
    V2 sandbox needs `~/.opencode-v2/xdg/config/opencode/.oh-my-opencode-slim`
    to reach the same file; that junction is recorded in the `~/.opencode-v2`
    changelog. Without it a V2 session would reinstall the eight skills into
    the shared `skills/` junction and V1 would adopt them back as `managed`.
  - Existing projects still hold `oh-my-opencode-slim@2.2.10` in their
    `.opencode/opencode.json` until `opencode-assets.ps1 apply` is re-run in
    each project. The `orchestrator` overlays were not re-reviewed for the V2
    native-delegation wording (`subagent(...)` instead of `task(...)`).
- Portability: All paths use `~` or are project-relative; no new
  machine-specific literals.
- Chezmoi: Updated four existing managed targets and applied them. The
  content-hash trigger in `run_onchange_after_install-opencode-external-assets`
  re-ran the global `core` profile install as designed.
- Verification: `tests/opencode-assets-slim8.fixture.ps1` passes, including a
  new case that upgrades `2.2.21` to `2.2.22` and asserts a single plugin spec
  in the project config and lock. `opencode-assets.ps1 doctor -Json` reports
  `valid: true` with no drift. Scoped `chezmoi status` is clean and all edited
  sources are LF-only. Loading `2.2.22` in a live V1 or V2 project session was
  not exercised.

## 2026-09-22T00:36:10+08:00 - Point V2 command frontmatter at path-derived agent IDs

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: Windows 11 x64
- Scope: commands/fable-method.md, commands/fable-judge.md,
  commands/fable-loop.md, commands/selfmade/fable.md,
  commands/selfmade/mentor.md, commands/selfmade/socratic.md,
  commands/selfmade/learning-roadmap.md, commands/selfmade/feynman.md
- Summary: Eight V2 commands referenced agents by the bare `name:` value from
  the agent frontmatter. V2 ignores `name:` and derives the agent ID from the
  file path, so every one of them failed with `Agent not found`. Each command
  now names the full V2 agent ID.
- Important records:
  - V1 honors the agent frontmatter `name:` field, so `agent/selfmade/fable-agent.md`
    is `FableAgent` on V1 and `selfmade/fable-agent` on V2. The same split
    applies to `Mentor`, `Facilitator`, `Navigator`, and `Deconstructor`, which
    become `selfmade/subagents/learning/<Name>` on V2.
  - Only `commands/` was edited. V2 reads `commands/` and V1 reads `command/`:
    the V2 server lists exactly the 21 files in `commands/` plus four builtin
    and plugin commands, and none of the `command/`-only names. V1 behavior is
    unchanged.
  - The agent Markdown files were deliberately left alone. Renaming them to
    match the V1 `name:` value would flatten the `selfmade/` hierarchy and risk
    ID collisions.
- Portability: Agent IDs are repository-relative; no machine-specific literals.
- Chezmoi: Updated eight existing managed targets and applied them.
- Verification: Scoped `chezmoi status` for `.config/opencode/commands` is
  clean, all eight sources remain LF-only, and the rendered targets show the
  full agent IDs. The registered V2 agent IDs were read from
  `opencode2 api get /api/agent`. Running the commands interactively was not
  exercised.
## 2026-09-22T01:02:00+08:00 - Make AGENTS.md runtime-neutral and record the V1/V2 boundaries

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: Windows 11 x64
- Scope: AGENTS.md.tmpl, skills/ (slim8 isolation, unmanaged)
- Summary: `AGENTS.md.tmpl` no longer renders a chezmoi source directory, and a
  new `V1 and V2 boundaries` section records the four rules that caused this
  week's failures. The eight `oh-my-opencode-slim` skills were also moved out of
  the shared global `skills/` tree into the two projects that use them.
- Important records:
  - The AGENTS.md drift was not a manual edit. Line 67 rendered
    `{{ .chezmoi.sourceDir }}`, and chezmoi resolves that through the V2
    junction as `~/.opencode-v2/xdg/data/chezmoi` but as `~/.local/share/chezmoi`
    under V1. Whichever runtime applied last won, so the target flip-flopped.
    The template now tells the reader to run `chezmoi source-path` instead, and
    the file renders identically from both runtimes.
  - Recorded boundaries: V1 reads `command/` and V2 reads `commands/`; V2
    derives agent IDs from the file path and ignores frontmatter `name:`; the
    global `skills/` tree is shared and must not receive third-party installs;
    no shared file may contain a runtime-specific absolute path.
  - `opencode-assets.ps1 slim8-migration -MigrationMode apply` backed up and
    removed `simplify`, `codemap`, `clonedeps`, `deepwork`,
    `verification-planning`, `reflect`, `oh-my-opencode-slim`, and `worktrees`
    from `~/.config/opencode/skills`, then wrote `deleted` tombstones. Backup:
    `~/.local/state/opencode/slim8-skills-isolation-backups/20260921T164641265Z-c5163ef6812c435e8720ff710ca08ba6`.
    Restore with `slim8-migration -MigrationMode restore`. None of the eight was
    chezmoi-managed, and the manifest showed `lastManagedHash == lastSeenHash`,
    so nothing hand-written was lost. The migration classified them as
    `customized` only because it compares on-disk 2.2.10 content against the
    pinned 2.2.22 bundle.
  - `officialWebsite` and `sip-pos-ezpay/invoice-service` were re-applied at
    `oh-my-opencode-slim@2.2.22`, which is dual-host, so the plugin now loads on
    both runtimes. Their eight skills are project-local under `.opencode/skills`.
    `@dietrichgebert/ponytail@4.9.0` was dropped from both: it has no V2
    entrypoint and upstream has five unmerged V2 pull requests.
- Portability: The template no longer emits any absolute path. The boundary
  rules name only `~`-relative locations.
- Chezmoi: Updated one existing managed template and applied it. The slim8
  migration and the project assets are outside chezmoi by design.
- Verification: `chezmoi status` for the whole home directory is clean, the
  rendered `AGENTS.md` is LF-only and contains no source directory literal, and
  `opencode-assets.ps1 status` reports every asset and overlay as `installed` in
  both projects. The `sippos-pre` MCP block in `invoice-service` survived the
  apply unchanged. Running the slim orchestrator in a live session was not
  exercised.

## 2026-09-23T11:07:46+08:00 - Move opencode-mem to a pinned shared clone

- Status: Partial
- Machine: TC-TSENG
- Platform: Windows 10.0.26200 amd64
- Scope: `opencode.json.tmpl` (V1 and V2), `run_onchange_after_build-opencode-mem.ps1.tmpl`
- Summary: opencode-mem now loads from one clone at
  `~/.local/share/opencode-plugins/opencode-mem`, pinned to upstream commit
  `cec1de4` (PR #311, native V2 adapter). V1 loads `dist/plugin.js`; V2 loads
  the package directory.
- Important records:
  - The chezmoi-managed copy under `~/.config/opencode/plugins/opencode-mem`
    was forgotten (107 files). The old clone was moved to
    `~/.local/share/opencode-plugins/opencode-mem.bak-20260923`.
  - The build script now clones, checks out the pinned commit, installs root and
    `web/` dependencies, and builds. Change `$commit` to upgrade.
  - Both runtimes share `~/.config/opencode/opencode-mem.jsonc` and
    `~/.opencode-mem` (hardcoded upstream). Do not run V1 and V2 together.
- Portability: Paths use `.chezmoi.homeDir` in a `file:///` URL; the script is
  Windows-only, as before.
- Chezmoi: `chezmoi forget` auto-committed and pushed all pending source changes
  as `dd6fd07`.
- Verification: Build succeeded; `dist/plugin.js` exports `id`, `setup`, and
  `server`. After `opencode2 reload`, `opencode2 plugin list` did not show
  opencode-mem yet; a V2 service restart is required to confirm. V1 loading was
  not exercised.