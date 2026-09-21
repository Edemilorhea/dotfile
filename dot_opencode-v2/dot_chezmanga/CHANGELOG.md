# OpenCode v2 Sandbox Changelog

Management root: `~/.opencode-v2`

This tree runs OpenCode v2 (`opencode2`) side by side with the v1 install that
owns `~/.config/opencode` and `~/.local/share/opencode`. Only configuration is
managed by chezmoi. The 215 MB binary, the SQLite database, credentials, and
runtime state are deliberately excluded and are recreated by the setup script.

## 2026-09-17T14:08:56+08:00 - Install OpenCode v2 beside v1 under an isolated XDG root

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / X64
- Scope: `opencode2.cmd`, `xdg/config/opencode/opencode.json`, `.chezmanga/`,
  plus `run_onchange_after_setup-opencode-v2.ps1.tmpl` and `.chezmoiignore`
  in the chezmoi source root
- Summary: OpenCode v2.0.5 now runs as `opencode2` with its own config, data,
  state, and cache directories. The v1 install keeps `opencode` and is not
  modified. `agent/`, `commands/`, and `skills/` are junctions back to
  `~/.config/opencode` so those files stay managed exactly once.
- Important records:
  - v2 resolves every path from `XDG_*`, verified on Windows with
    `opencode debug paths`. `opencode2.cmd` sets the four variables with
    `setlocal`, so they never leak into the calling shell.
  - Sharing the default directories is unsafe: v2 runs a one-shot v1 to v2
    database migration and records it as completed, which hides sessions from
    both versions afterwards (upstream issue #49412). A v2-format `permissions`
    array in the shared config also crashes v1 outright (#49333, closed as
    `not_planned`).
  - The v2 binary is installed from the platform tarball
    `@opencode/cli-windows-x64` rather than `npm install -g @opencode/cli`,
    whose postinstall fails on Windows and then empties the package directory.
  - Three dead `opencode2.*` shims in `%APPDATA%\npm` pointed at a removed
    `@opencode-ai/cli` build and shadowed the wrapper. They are backed up in
    `removed-dead-shims/` and deleted.
  - v2 derives file-based agent IDs from the path under `agent/`, not the
    frontmatter `name`. The `agent` keys were rewritten to the full paths;
    before that, eight override entries created empty agents instead of
    configuring the real ones (27 agents became the correct 19).
  - v1 plugins cannot load: v2 moved the SDK from `@opencode-ai/plugin` to
    `@opencode/plugin`. Only `@ex-machina/opencode-anthropic-auth@next` has a
    v2 build, and it restores Claude Pro/Max OAuth, which v2 does not offer
    natively. `mandatory-format.ts` is replaced by the builtin `formatter`
    plus a `dprint` entry.
- Portability: `opencode2.cmd` locates everything through `%~dp0`, so it has no
  machine-specific literals. The setup script uses `$HOME` and pins the v2
  version in one variable. `opencode.json` still carries absolute paths for the
  `office-mcp` server, matching the existing untemplated
  `dot_config/opencode/opencode.json`; templating both is a separate decision.
- Chezmoi: added `opencode2.cmd`, `xdg/config/opencode/opencode.json`, and this
  changelog; added `run_onchange_after_setup-opencode-v2.ps1.tmpl`; extended
  `.chezmoiignore` to exclude `bin/`, `xdg/data`, `xdg/state`, `xdg/cache`,
  `service.json`, `cli.json`, `PATH-user-backup.txt`, `removed-dead-shims/`,
  and the three junctioned directories.
- Verification: `opencode2 --version` reports 2.0.5; `opencode2 debug paths`
  keeps `db`, `data`, `config`, `state`, and `cache` inside `~/.opencode-v2`;
  `Get-Command opencode2 -All` resolves only to the wrapper; `opencode2 debug
  agents` lists 19 agents with the overrides bound; `opencode2 plugin list`
  shows `ex-machina.anthropic-auth 2.0.0-next.1`; the v1 9.75 GB
  `opencode.db` was never opened by v2.

## 2026-09-17T14:21:05+08:00 - Restore the alt+m leader and the v1 keybinds in cli.json

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / X64
- Scope: `xdg/config/opencode/cli.json`, `.chezmoiignore` in the chezmoi source root
- Summary: v2 was using its default `ctrl+x` leader because terminal settings
  moved from `tui.json` to `cli.json` and the command IDs were renamed, so
  nothing carried over. `cli.json` now sets the `alt+m` leader and every v1
  binding that differs from a v2 default.
- Important records:
  - v1 `tui.json` uses snake_case IDs such as `app_exit` and `session_new`.
    v2 `cli.json` uses dotted IDs such as `app.exit` and `session.new`, and
    rejects unknown IDs, so the old file cannot be copied across.
  - Only the 18 bindings that differ from a v2 default are declared. Entries
    such as `<leader>e`, `<leader>m`, and `<leader>c` already match.
  - `session.permissions` is `autoaccept`, which approves every permission
    request without prompting. It was already present and is preserved here
    rather than silently changed.
  - The two TUI plugins in `tui.json`, `./plugins/openai-usage-tui.ts` and
    `opencode-claude-usage`, are not carried over because they target the v1
    plugin SDK.
  - `oh-my-opencode-slim` fails to load under v2 when a project deploys its
    pinned spec into `.opencode/opencode.json`. Even `3.0.0-beta.13` still
    depends on `@opencode-ai/plugin@1.18.23`, so no v2 build exists yet. The
    failure is reported per plugin and does not stop the session.
- Portability: `cli.json` holds only key names and has no machine-specific
  paths.
- Chezmoi: added `xdg/config/opencode/cli.json` and removed its
  `.chezmoiignore` exclusion, which was written before the file had content.
- Verification: every declared keybind ID was checked against the 239 IDs in
  `https://opencode.ai/v2/cli.json`; all 18 are valid and the top-level keys
  are valid. `chezmoi status` for `~/.opencode-v2` is clean.

## 2026-09-17T15:27:02+08:00 - Port the locu custom tool to a v2 plugin

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / X64
- Scope: `xdg/config/opencode/plugins/locu/index.ts`, plus `.chezmoiignore` and
  `run_onchange_after_setup-opencode-v2.ps1.tmpl` in the chezmoi source root
- Summary: `locu_tasks`, `locu_sessions`, and `locu_timer` are available in v2 again.
  V2 removed file-based custom tools, so the registration layer was rewritten as a
  plugin while the HTTP client stays shared with the v1 tool.
- Important records:
  - V1 discovers `~/.config/opencode/tools/*.ts` and derives tool names from
    `<file>_<export>`. V2 has no such path: `/v2/docs/custom-tools` is absent, no
    tool endpoint exists among the 111 API routes, and the tools guide lists only
    MCP servers and skills as extensions. Tools must come from
    `ctx.tool.transform()` inside a plugin.
  - `core/` is a junction to `~/.config/opencode/tools/locu`, so `client.ts`,
    `config.ts`, and `types.ts` exist once and cannot drift between runtimes. The
    server's watcher subscribes to those files through the junction, so edits still
    hot-reload. Those three files import nothing from OpenCode.
  - The default export is a plain object, not `Plugin.define(...)`. A first attempt
    using `import { Plugin } from "@opencode/plugin"` failed to load with
    `Cannot find package '@opencode/plugin'`: OpenCode does not resolve its SDK for
    a local plugin directory. `define` is only `(plugin) => plugin` and OpenCode
    validates the exported shape, so dropping the import keeps the plugin free of
    any installed dependency and of a `node_modules` tree.
  - Two v1 tool-context fields are gone in v2. `context.directory` became
    `ctx.location.directory`, read once during setup. `context.abort` became a
    plugin-lifetime `AbortController` that the cleanup function aborts; the client
    keeps its own 10s per-request timeout regardless.
  - Arguments moved from Zod to JSON Schema, which `Tool.ValueSchema` accepts
    directly and which avoids depending on a resolvable `zod`.
- Portability: The plugin uses no absolute paths. The setup script creates the
  `core` junction from `$HOME`.
- Chezmoi: Added `plugins/locu/index.ts`, excluded `plugins/locu/core/**`, and
  extended the setup script with the junction. Also re-added `cli.json` to capture
  the `session.sidebar`, `session.thinking`, and `tabs` values changed in the v2 TUI.
- Verification: `opencode2 plugin list` reports `selfmade.locu` with a resolved ID,
  and the server log shows no load error. Running `setup` against a stub context
  registers namespace `locu` and exactly three tools whose effective names and
  argument shapes match v1: `locu_tasks` with `done`, `limit`, `projectId`,
  `section`; `locu_sessions` with `startAfter` and `startBefore` required; and
  `locu_timer` with no arguments. The cleanup function is returned. V1's
  `tools/locu.ts` is untouched and its scoped `chezmoi status` is clean. Live tool
  invocation is unverified because the v2 provider is not authenticated yet.

## 2026-09-18T14:01:18+08:00 - Rebind tab navigation around Rio, psmux, and GlazeWM

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / X64
- Scope: `xdg/config/opencode/cli.json`
- Summary: `session.tab.next`, `session.tab.previous`, and `session.tab.reopen`
  now use bindings that survive the Rio to psmux to OpenCode key path and do not
  collide with the window manager. The remaining tab bindings keep their
  defaults.
- Important records:
  - The defaults `ctrl+tab`, `ctrl+shift+tab`, and `ctrl+shift+t` cannot be
    transmitted. Rio runs with `TERM=xterm-256color` and its `[keyboard]` table
    only sets `ime-cursor-positioning`, so legacy encoding sends `0x09` for both
    `Tab` and `Ctrl+Tab`. OpenCode therefore receives `tab`, which this config
    binds to `agent.cycle`.
  - The fallback defaults `alt+down` and `alt+up` are consumed by GlazeWM
    (`alt+j, alt+down` and `alt+k, alt+up`). `alt+shift+down` and `alt+shift+up`,
    used by `session.tab.next_unread`, are consumed for the same reason.
  - `ctrl+pageup` and `ctrl+pagedown` are encodable in legacy mode as
    `CSI 5;5~` and `CSI 6;5~`. GlazeWM defines no Ctrl binding at all, and
    `psmux.conf` only unbinds bare `PageUp`, so the pair is free end to end.
  - `]`, `[`, and `z` are unused as leader keys by both the v2 defaults and this
    file. The leader `alt+m` is safe: GlazeWM binds `alt+shift+m` but not
    `alt+m`, and the psmux prefix is `alt+a`.
  - `session.tab.close` (`<leader>w`) and `session.tab.select.1` through `.10`
    (`<leader>1` to `<leader>0`) already work, because a leader sequence sends
    the modifier and the plain key in separate strokes.
  - `tabs.scope` stays `cwd` by explicit request, so each working directory keeps
    its own tab set.
- Portability: The bindings name keys only and contain no machine-specific path.
  They assume a terminal without the Kitty keyboard protocol; a terminal that
  negotiates it would also accept the upstream defaults.
- Chezmoi: Updated `cli.json`. A scoped `chezmoi re-add` ran first because the
  source was stale relative to the live file, which had gained `new_location`,
  `theme`, `animations`, `diffs`, `attention`, and `terminal`, and had changed
  `tabs.indicators` from `numbers` to `status`. The live file was authoritative:
  its mtime was 2026-09-18 and the source tree had been clean since 2026-09-17.
- Verification: Scoped `chezmoi diff` showed only the three added lines, and
  scoped `chezmoi status` is clean after `chezmoi apply`. The applied
  `cli.json` parses as JSON, reports the three new bindings, and remains LF-only.
  The bindings are not yet exercised in a live TUI session.

## 2026-09-18T23:39:13+08:00 - Capture the disabled session tab bar

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / X64
- Scope: `xdg/config/opencode/cli.json`
- Summary: `tabs.enabled` is now `false`, so the v2 session tab bar is off. The
  tab keybindings added earlier today remain declared and take effect again if
  tabs are re-enabled.
- Important records:
  - The value was written by the v2 TUI itself at 2026-09-18 15:54, after the
    14:00 source commit, so it existed only on this machine. The live file was
    declared authoritative and the source was updated from it.
  - `tabs.scope` and `tabs.indicators` are unchanged. Turning the tab bar off
    does not remove `session.tab.next`, `session.tab.previous`, or
    `session.tab.reopen` from `keybinds`; the CLI still accepts those IDs.
- Portability: The change is a single boolean and contains no machine-specific
  path.
- Chezmoi: Scoped `chezmoi re-add` of `cli.json`; chezmoi's autocommit and
  autopush published it.
- Verification: The scoped `chezmoi status` is clean, the file parses as JSON,
  and it remains LF-only. No TUI restart was performed to observe the tab bar.

## 2026-09-21T10:33:12+08:00 - Bridge ~/.config/git into the sandbox XDG root

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `run_onchange_after_setup-opencode-v2.ps1.tmpl`,
  `xdg/config/git`
- Summary: Junctioned `~/.config/git` into the sandbox so Git keeps the user's
  own configuration inside an OpenCode v2 session instead of falling back to
  the Git for Windows system defaults.
- Important records:
  - `opencode2.cmd` redirects all four XDG variables for the whole process
    tree, so every tool an agent runs loses `~/.config`, not only opencode.
  - Measured inside a session before the change: `core.autocrlf=true`,
    `core.safecrlf` unset, `init.defaultBranch=master`,
    `push.autoSetupRemote` unset, and no `user.name` or `user.email`. The
    `autocrlf` default can rewrite LF to CRLF in repositories without a
    `.gitattributes`, which contradicts the repository line-ending rules.
  - A commit made before the change, `a10c790` in the dotfiles repository,
    recorded the OS-guessed author `Tc Tseng (曾靖文)`. The user confirmed the
    identity is theirs on another machine, so it was left unamended.
  - The same leak already had two downstream workarounds: the TUIOS changelog
    note about pointing `XDG_CONFIG_HOME` back at `~/.config`, and the
    `openai-usage` plugins temporarily restoring `XDG_DATA_HOME`.
  - `~/.config/tuios` and `~/.config/scoop` have sandbox copies whose contents
    differ, so they were deliberately left split rather than junctioned.
  - `xdg/config/git` did not exist, so the junction needed no backup rename.
- Portability: The junction is created by the existing Windows-only
  `Set-Junction` helper from `$HOME`, and the script remains guarded by
  `{{ if eq .chezmoi.os "windows" }}`.
- Chezmoi: Updated the managed setup script; the junction was created directly
  so the runtime matches now, and the idempotent script will reproduce it on
  the next apply and on other machines.
- Verification: The rendered template parses as PowerShell and the source is
  LF-only. The junction reports `LinkType=Junction` to
  `C:\Users\tc_tseng\.config\git`. Git inside this session now reports
  `user.name=TC Tseng`, `user.email=tc_tseng@gss.com.tw`,
  `core.autocrlf=false`, `core.safecrlf=true`, `init.defaultBranch=main`, and
  `push.autoSetupRemote=true`, which includes values from `config.local`. The
  script itself was not re-executed through `chezmoi apply`.
