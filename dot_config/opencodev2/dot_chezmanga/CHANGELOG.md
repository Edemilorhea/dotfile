# OpenCode v2 Configuration Changelog

Management root: `~/.config/opencodev2`

This tree holds every OpenCode v2 configuration file. `opencode2.cmd` points
`XDG_CONFIG_HOME` here, so OpenCode v2 reads `~/.config/opencodev2/opencode`.
The v2 binary, database, credentials, and other runtime state stay in
`~/.opencode-v2` and are excluded from chezmoi.

## 2026-09-24T01:05:04+08:00 - Keep compact paste mode in the V2 CLI

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / AMD64
- Scope: `opencode/cli.json`
- Summary: `prompt.paste` is now `compact` in the managed source, matching the local target. Pasted text collapses into a summary in the prompt instead of being shown in full.
- Important records:
  - The target had drifted to `compact` while the source still said `full` (`chezmoi status` reported `MM`). The local value was chosen as authoritative, so the source was updated with `chezmoi re-add` rather than overwriting the target with `chezmoi apply`.
- Portability: A literal UI preference with no machine-specific path.
- Chezmoi: Re-added the already-managed target. The auto-commit `6128975` also carried the pending OpenCode 2.0.15 upgrade in the sandbox tree.
- Verification: Scoped `chezmoi status` for `cli.json` is clean after the re-add, and the committed diff changes only `"paste": "full"` to `"paste": "compact"`.

## 2026-09-22T10:41:00+08:00 - Add a local v2 plugin that routes shell commands through RTK

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 11 10.0.26200.0 / AMD64
- Scope: `opencode/plugins/rtk/index.ts`
- Summary: Shell commands are now passed to `rtk rewrite` before they run, so `git status` executes as `rtk git status` and returns RTK's compact output instead of the raw output. Measured savings on the first two commands were about 50% of output tokens.
- Important records:
  - RTK ships no v2 integration. `rtk init --global --opencode` emits a v1 plugin that imports `@opencode-ai/plugin`, destructures the `$` Bun shell helper, and returns a `tool.execute.before` hook object. V2 loads that shape with no id and it does nothing, so the delegation was reimplemented locally. The rewrite logic itself stays in the Rust binary.
  - `shell.create.before` was chosen over `tool.execute.before` because the v2 event exposes `command` and `env` as plain fields. It also runs after the permission decision, which is the important property: `permission.bash` still matches the original `git status`, not the rewritten `rtk git status`. No `rtk`-prefixed allow entries were needed, and a rewritten command can never escape an `ask` or `deny` rule.
  - `rtk rewrite` signals its result through stdout, not the exit code: exit 3 means rewritten, exit 1 means passed through. The plugin therefore ignores the exit code and reads stdout, and treats any spawn failure as a pass-through.
  - The binary is installed at `~/.local/bin/rtk.exe`, which is deliberately not on the user PATH. The hook prepends that directory to the per-shell `env.PATH` only when it actually rewrote a command, so a rewritten `rtk ...` can resolve while the machine PATH stays untouched. `RTK_BIN` overrides the location.
  - Removal is three independent deletions: this plugin directory (plugins are auto-discovered, so `opencode.json` never references it), `~/.local/bin/rtk.exe`, and nothing else. The file header repeats these steps for whoever retires the shim once upstream ships a v2 plugin.
  - `rtk init -g --opencode` was deliberately not run. It would write a v1 plugin into `~/.config/opencode/plugins/`, which belongs to the v1 runtime.
  - The binary is not managed by chezmoi. It is a 4 MB release artifact; another machine must download `rtk-x86_64-pc-windows-msvc.zip` from the rtk-ai/rtk releases and place `rtk.exe` at the same path. The plugin no-ops when it is absent, so an unprovisioned machine degrades silently instead of failing.
- Portability: The install path is derived from `os.homedir()` and the executable name switches on `process.platform`, so the same file works on a non-Windows machine. `path.delimiter` is used for PATH joining. No absolute machine path is written into the source.
- Chezmoi: Added `dot_config/opencodev2/opencode/plugins/rtk/index.ts`.
- Verification: `rtk --version` reports 0.49.0 and the downloaded archive matched the published SHA-256. Running `git status` from an OpenCode shell returned RTK's compact format with no permission prompt, and `rtk gain` advanced from 1 to 2 tracked commands, confirming the hook fires inside OpenCode. `chezmoi status ~/.config/opencodev2` exits clean.

## 2026-09-22T10:40:00+08:00 - Add subscription quota display with opencode-usage-stat

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / AMD64
- Scope: `opencode/opencode.json`
- Summary: Added `opencode-usage-stat` 2.4.5 to `plugins`, with `providerUsage` enabled for `claude` and `codex` and `providerUsageDisplay` set to `remaining`. It shows how much of each subscription's rolling quota window is left, in the TUI sidebar and under `/usage`.
- Important records:
  - It is the only usage plugin that covers both Claude Pro/Max and Codex. Of roughly 20 OpenCode usage packages on npm, only three use the v2 plugin API; `opencode-usage-bars` reads Codex only, and `@mynameistito/opencode-usage-limits` has no Claude support.
  - Claude quota comes from `api.anthropic.com/api/oauth/usage`, the same endpoint Claude Code uses, and requires an OAuth token rather than an API key. Codex quota uses the v2 OAuth access token.
  - Credentials resolve at runtime and respect `XDG_DATA_HOME`, so the plugin reads v2's own credential store at `~/.opencode-v2/xdg/data/opencode/opencode.db`. No wrapper is needed, unlike the v1 `openai-usage.ts` shim.
  - The package was installed with `opencode2 plugin add opencode-usage-stat`, which wrote a plain string entry directly into the managed target. The entry was then rewritten in the chezmoi source as an object with `options`, and the target was reconciled with `chezmoi apply --force`.
  - Every provider check is off by default. Only `claude` and `codex` are enabled, so no other provider endpoint is contacted.
- Portability: The entry is a plain npm package name with no machine path. Credential resolution is environment-driven, so it stays portable.
- Chezmoi: Updated `dot_config/opencodev2/opencode/opencode.json.tmpl`.
- Verification: `opencode2 plugin list` reports `opencode-usage-stat 2.4.5` as loaded both before and after the object-form rewrite. `chezmoi status` for the target exits clean. The sidebar rendering and the quota values are unverified until the v2 TUI is restarted and the two providers are signed in.

## 2026-09-21T23:10:00+08:00 - Capture the cli.json prompt block and diagnose the two failing MCP servers

- Status: Partial
- Machine: DESKTOP-3JHKCAP
- Platform: Microsoft Windows NT 10.0.26200.0 / X64
- Scope: `opencode/cli.json`
- Summary: `chezmoi status` reported `MM` for `opencode/cli.json`. The runtime
  file carried a `prompt` block (`"paste": "full"`, `"image_preview": true`)
  that the source never captured, so the next `chezmoi apply` would have
  deleted the v2 image-paste setting. The target was authoritative and is now
  re-added to the source. No MCP configuration was changed.
- Important records:
  - The two MCP servers the user reported as unusable are `markitdown` and
    `linear`. Neither needs a configuration change.
  - `markitdown` fails only because `markitdown-mcp` was installed at
    `14:42:26Z`, after the running OpenCode v2 process attempted its MCP
    connections at `14:33:47Z`. The server itself is healthy: a direct stdio
    handshake answers `initialize` and `tools/list`, and `Bun.spawn` starts the
    bare `markitdown-mcp` command in 1.3 s. A restart is the fix.
  - `opencode mcp list` queries the background service and reports its cached
    connection state, so it cannot re-test a server without a restart. A second
    service cannot be started against a scratch `XDG_CONFIG_HOME`; it fails with
    "Timed out waiting for the background service to start".
  - `linear` reports `needs_auth`. `~/.opencode-v2/xdg/data/opencode/` has no
    `mcp-auth.json`, so v2 never completed the OAuth flow. Run
    `opencode2.cmd mcp auth linear` and authorize in the browser. That
    credential lives outside chezmoi.
  - `opencode/service.json` holds a service password and is deliberately left
    unmanaged.
- Portability: `cli.json` contains no machine-specific paths, so it stays a
  plain file with no template.
- Chezmoi: re-added `dot_config/opencodev2/opencode/cli.json` from the target.
- Verification: `chezmoi status` is empty after the re-add. The source and
  target `cli.json` are both pure LF. Live MCP recovery for `markitdown` and
  `linear` stays unverified until OpenCode v2 restarts, which is why this entry
  is `Partial`.

## 2026-09-21T22:49:19+08:00 - Templatize MCP server paths and repair them on this machine

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: Microsoft Windows NT 10.0.26200.0 / X64
- Scope: `opencode/opencode.json`, now `opencode/opencode.json.tmpl`
- Summary: The v2 MCP server list showed `jev-review`, `office-mcp`, and
  `markitdown` as `Failed`. The config carried `C:\Users\tc_tseng\...`
  absolute paths from the machine that installed them, and none of the three
  servers existed here. The MCP paths now render from `.chezmoi.homeDir`,
  `jev-review` and `markitdown` are installed locally, and `office-mcp` is
  disabled until its sources are restored. The v1 config received the same
  change in the same task.
- Important records:
  - `jev-review` was re-cloned from https://github.com/NiazMorshed2007/jev-review
    at commit `57690af54ef7d862c2483342c1e61c14dffcf727` into the shared
    `~/.local/share/opencode/jev-review`, which both v1 and v2 reference.
  - `markitdown-mcp` 0.0.1a7 is installed in the user Python 3.13 and resolves
    on PATH, so its bare command needs no path template.
  - `office-mcp` has no recorded upstream and no local sources, so it is kept
    as a templated entry with `"enabled": false` and a restore comment.
  - The applied file also carried a pending unrelated source change: the
    `github:gabparrot/opencode2-todo-tool` plugin was already uncommented in
    the chezmoi source but had never been applied. The user confirmed keeping
    it enabled, so this apply activated it. Its effect is unverified here.
  - `chezmoi` needs `--config ~/.config/chezmoi/chezmoi.toml -S
    ~/.local/share/chezmoi` inside a v2 session: `opencode2.cmd` redirects
    `XDG_CONFIG_HOME` and `XDG_DATA_HOME`, so bare `chezmoi` resolves its
    source directory to the empty `~/.opencode-v2/xdg/data/chezmoi` and reports
    managed files as "not managed".
- Portability: All MCP paths render from `{{ .chezmoi.homeDir }}`, which
  chezmoi returns with forward slashes on Windows, so the rendered JSON needs
  no backslash escaping. Remaining machine-specific assumption: `jev-review`
  and `office-mcp` expect unmanaged directories under
  `~/.local/share/opencode/` that each new machine must recreate by hand.
- Chezmoi: renamed `dot_config/opencodev2/opencode/opencode.json` to
  `dot_config/opencodev2/opencode/opencode.json.tmpl` and templated its MCP
  paths.
- Verification: `chezmoi status` is empty for the applied target. The rendered
  `~/.config/opencodev2/opencode/opencode.json` contains no `tc_tseng`
  occurrence and is pure LF. The running v2 session picked up the new config
  and exposed the `jev-review` MCP namespace, so that server now starts.
  `markitdown-mcp --help` runs and confirms STDIO is its default transport, but
  its live MCP startup is unverified; restart OpenCode to re-check the list.

## 2026-09-21T19:40:00+08:00 - Move v2 configuration under ~/.config and enable DCP

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode/opencode.json`, `opencode/cli.json`, `opencode/dcp.jsonc`,
  `opencode/plugins/locu/index.ts`, plus `.chezmoiignore`,
  `run_onchange_after_setup-opencode-v2.ps1.tmpl`, and
  `dot_opencode-v2/executable_opencode2.cmd` in the chezmoi source root
- Summary: Relocated the v2 configuration from `~/.opencode-v2/xdg/config/opencode`
  to `~/.config/opencodev2/opencode`, repointed the wrapper and setup script, and
  enabled Dynamic Context Pruning for v2.
- Important records:
  - `xdg/config` was a local sandbox convention, not an OpenCode requirement.
    OpenCode only resolves `$XDG_CONFIG_HOME/opencode`, so the wrapper now sets
    `XDG_CONFIG_HOME=%USERPROFILE%\.config\opencodev2`.
  - Runtime isolation is unchanged: data, state, cache, and the binary stay in
    `~/.opencode-v2`, so v1 and v2 still keep separate databases and credentials.
  - The migration was copy-based. The old `~/.opencode-v2/xdg/config` tree was left
    in place so the running v2 service kept working; it can be deleted after a
    verified restart.
  - `agent`, `commands`, `skills`, `.oh-my-opencode-slim`, `AGENTS.md`, and
    `plugins/locu/core` are junctions or a symlink back into `~/.config/opencode`,
    and `git`, `tuios`, and `scoop` are junctions into `~/.config`, so the
    wholesale `XDG_CONFIG_HOME` redirect does not lose user configuration.
  - `@tarquinen/opencode-dcp@3.2.0` is v2-capable: its entry exports a `setup()`
    built on `@opencode/plugin` (`ctx.tool.transform`, `ctx.session.hook`,
    `ctx.rpc`), so it is enabled with a v2 `dcp.jsonc` copied from the v1 settings.
  - `oh-my-tokens@0.2.9` was deliberately not installed. Its entry is a v1-only
    plugin function with no v2 `setup` export, and its postinstall rewrites
    `opencode.json`, which would fight chezmoi and duplicate the existing
    `openai-usage-windows` plugin on v1.
- Portability: The wrapper uses `%USERPROFILE%` and the setup script uses `$HOME`;
  no machine-specific literals were added.
- Chezmoi: Moved the source tree with `git mv`, rewrote the `.chezmoiignore`
  entries for the new paths, and added this changelog.
- Verification: `Test-Json -Options IgnoreComments,AllowTrailingCommas` passes for
  `opencode.json`, `cli.json`, and `dcp.jsonc` at the new location; the rendered
  setup script parses with the PowerShell parser; junction and symlink targets
  resolve; a sandboxed `opencode.exe serve --port 49911` using this config
  directory started and served HTTP. Plugin load status was not verified because
  the managed-service port is held by the running v2 service; run
  `opencode2 service restart` and then `opencode2 api get /api/plugin`.

## 2026-09-22T00:34:46+08:00 - Install the todo plugin from npm instead of a git subdirectory spec

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: Windows 11 x64
- Scope: opencode/opencode.json.tmpl
- Summary: The `plugins` entry for the community todo plugin changed from
  `github:gabparrot/opencode2-todo-tool#main::path:opencode2-todo` to
  `opencode2-todo@0.2.1`, so the plugin installs and the repeated startup
  failure stops.
- Important records:
  - OpenCode installs plugins with npm. npm git specifiers cannot select a
    subdirectory; the `::path:` suffix is pnpm syntax. npm cloned the
    repository, found no `package.json` at its root, and failed with
    `NpmInstallFailedError` on every plugin reconciliation.
  - The author publishes the package to npm as `opencode2-todo`; `0.2.1` is
    the latest published version. Repository `main` is `0.2.3` but unpublished.
  - Server-side load succeeds and the `todowrite` tool is registered. The CLI
    side still fails to load `src/tui.tsx` with
    `Cannot find package 'react'`: the file has no
    `/** @jsxImportSource solid-js */` pragma and the published tarball omits
    `tsconfig.json` (`files` is `["src", "tool"]`), so the JSX transform
    defaults to the React runtime. This is an upstream packaging bug and only
    disables the optional TUI sidebar.
- Portability: Plugin spec is a plain npm version; no machine-specific literals.
- Chezmoi: Updated one existing managed template and applied it.
- Verification: `chezmoi status` for `.config/opencodev2/opencode/opencode.json`
  is clean. The server log shows
  `loading plugin id=opencode2-todo@0.2.1` with no failure for `role=server`.
  A live `todowrite` call succeeded. `role=cli` still logs the react JSX error.
## 2026-09-22T00:47:00+08:00 - Drop the todo plugin from the v2 plugin list

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: Windows 11 x64
- Scope: opencode/opencode.json.tmpl
- Summary: `opencode2-todo@0.2.1` was removed from `plugins`. The v2 session no
  longer has a `todowrite` tool, and the repeated cli-side plugin load failure
  stops.
- Important records:
  - The npm install and the server-side load both succeeded, but the cli failed
    on every reconciliation with `Cannot find package 'react'` while loading
    `src/tui.tsx`. The file carries no `/** @jsxImportSource solid-js */`
    pragma and the published tarball omits `tsconfig.json` (`files` is
    `["src", "tool"]`), so the cli transpiles its JSX with the default React
    runtime. Upstream packaging bug, not a configuration error.
  - The reason is recorded in the `dropped on purpose` comment block so the
    plugin is not reinstalled without an upstream fix.
- Portability: No machine-specific literals.
- Chezmoi: Updated one existing managed template and applied it.
- Verification: `chezmoi status` for `.config/opencodev2` is clean, and
  `opencode2 api get /api/config` reports only
  `@ex-machina/opencode-anthropic-auth@next` and `@tarquinen/opencode-dcp@3.2.0`.

## 2026-09-21T21:08:25+08:00 - Normalize V2 MCP and permission configuration

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: opencode/opencode.json
- Summary: Converted MCP servers, provider settings, permissions, update policy, and the local locu plugin registration to OpenCode V2 configuration shapes.
- Important records:
  - Agents and skills were intentionally left unchanged because they remain shared with the V1 configuration.
  - The V2 source remains the chezmoi source of truth; the rendered target was applied separately.
- Portability: Existing machine-specific MCP command paths were preserved because they point to installed local runtimes.
- Chezmoi: Updated source and applied the single V2 configuration target.
- Verification: JSON parsing passed; scoped chezmoi dry-run showed only the intended V2 configuration update; target apply completed.
## 2026-09-22T17:36:00+08:00 - Disable v2 global DCP plugin loading

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode/opencode.json.tmpl`
- Summary: Commented out the global `@tarquinen/opencode-dcp@3.2.0` plugin entry for OpenCode V2. The existing `dcp.jsonc` settings remain preserved but are no longer loaded through the global plugin list.
- Important records:
  - This avoids the DCP `magic` conflict where the plugin is treated as conflicting even when its setting is disabled or loading fails.
- Portability: The change is in the shared chezmoi source template and contains no machine-specific path.
- Chezmoi: Updated the existing managed source template; runtime target will be applied below.
- Verification: Scoped chezmoi diff and JSONC parsing will be checked after applying the source change.

## 2026-09-23T10:18:23+08:00 - Re-enable global DCP; keep Magic Context off

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / AMD64
- Scope: `opencode/opencode.json.tmpl`
- Summary: Uncommented `@tarquinen/opencode-dcp@3.2.0` in the V2 global `plugins` array, reversing the 2026-09-22T17:36 entry. The existing `dcp.jsonc` is loaded again unchanged.
- Important records:
  - Magic Context (`@cortexkit/opencode-magic-context@0.42.6`, latest on 2026-09-23) ships a `dist/v2` lane but is not usable on V2 yet. Upstream issue #493 reports V2 prompts that hang forever; the maintainer confirmed a 0.42.6 bug where a V1 store migrated in place (legacy `message`/`part` tables kept beside `session_message`) is classified as V1 and every prompt is interrupted. #492 and #488 list further open V2 gaps: stale state reconciliation, 10 of 12 Dreamer tasks filtered out, partial commands, and tool-transform accumulation. This machine's V2 store was migrated from V1, so it is exposed to #493.
  - DCP 3.2.0 contains no Magic Context detection; the extracted package has no `magic` string. The earlier conflict came from the Magic Context side, and no V2 config file references Magic Context, so DCP loads without it.
  - DCP and Magic Context both rewrite session context and must not be loaded together. The new inline comment next to the plugin entry records that DCP must be removed before Magic Context is enabled.
- Portability: The change is a plugin spec and comments, with no machine-specific path.
- Chezmoi: Updated the managed source template and applied only the `opencode.json` target.
- Verification: Scoped `chezmoi diff` showed only the uncommented entry and two comment edits; scoped `chezmoi status` is clean after apply; the source stays LF-only. `opencode2 plugin list` resolves `opencode-dcp 3.2.0` from `@tarquinen/opencode-dcp@3.2.0`. `dcp.jsonc` validates against the DCP schema and matches the active V1 settings (the V1 file differs only by a commented-out alternative block). Behavior in a live session is unverified until OpenCode V2 restarts.

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
## 2026-09-23T19:51:47+08:00 - Port handoff to V2 and surface DCP compression

- Status: Completed
- Machine: TC-TSENG
- Platform: Windows 10.0.26200 AMD64
- Scope: `opencode/plugins/handoff/`, `opencode/plugins/dcp-notify/`, `opencode/dcp.jsonc`, `opencode/opencode.json.tmpl`
- Summary: V2 now has a local `/handoff` command with `handoff_session` and
  `read_session` tools, and shows a toast whenever DCP compresses the context.
- Important records:
  - `opencode-handoff` (npm 0.5.0) is v1-only. `plugins/handoff/index.ts`
    reimplements it against the v2 plugin context: `command.transform` for
    `/handoff`, `tool.transform` for both tools, `session.create` plus
    `session.synthetic` for the new session.
  - The v1 editable prompt draft cannot be ported. `client.tui.appendPrompt` has
    no v2 equivalent: `tui.prompt.append` exists in `@opencode/protocol` and the
    CLI listens for it, but nothing on the server publishes it, there is no HTTP
    or RPC route for it, and the CLI plugin context exposes no prompt writer. The
    handoff text is attached with `session.synthetic` instead, so it is context
    rather than an editable draft. The user chose this over a clipboard plus
    `prompt.paste` workaround.
  - v1 preloaded `@file` references into the new session. Synthetic text is not
    scanned for attachments, so files are listed as a reading list instead.
  - `plugins/handoff/tui.ts` navigates to the new session. The server half sets
    `metadata.handoff` on `session.create`; the CLI half matches it on
    `session.created` and calls `ui.router.navigate`.
  - DCP 3.2.0 never shows a V2 notification: `lib/v2/index.ts` wires both
    `session.prompt` and `tui.showToast` to `report()`, which only writes a
    debug log ("V2 report (display pending)"). `pruneNotificationType` and
    `compress.showCompression` have no effect on V2. npm `latest` is 3.2.0, so
    there is nothing to upgrade to.
  - `plugins/dcp-notify/tui.ts` rebuilds the notification from the `compress`
    tool's own events: `session.tool.input.started` for the name,
    `session.tool.called` for `input.topic`, and `session.tool.success` or
    `session.tool.failed` for the outcome. Delete the whole directory once DCP
    implements V2 display.
  - Each plugin directory carries an `index.ts` and a `tui.ts`, the documented
    discovery layout. `dcp-notify/index.ts` registers nothing and exists only so
    the directory is discovered and its CLI half loads.
  - Both plugins export a plain `{ id, setup }` object instead of importing
    `@opencode/plugin`, matching `plugins/locu/index.ts`.
- Portability: No machine-specific path. Both plugins are V2-only by location;
  V1 keeps the npm `opencode-handoff` plugin unchanged.
- Chezmoi: Added `plugins/handoff/{index,tui}.ts` and
  `plugins/dcp-notify/{index,tui}.ts`; updated `dcp.jsonc` and
  `opencode.json.tmpl`; applied only those four targets.
- Verification: Scoped `chezmoi diff` showed only the intended changes and
  scoped `chezmoi status` is clean for every touched target (`cli.json` was
  already `MM` before this task and was left alone). All six files are LF-only.
  `opencode2 plugin list` shows `selfmade.handoff` and `selfmade.dcp-notify`,
  and the service log records no plugin error. The live tool catalog of the
  running session now offers `handoff_session` and `read_session` with the new
  schemas, which confirms the tool transform. The `/handoff` command, the DCP
  toast, and the handoff navigation run in the CLI process and stay unverified
  until OpenCode V2 restarts.