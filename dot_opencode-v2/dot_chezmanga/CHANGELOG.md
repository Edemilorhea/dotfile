# OpenCode v2 Sandbox Changelog

Management root: `~/.opencode-v2`

Since 2026-09-21 this tree holds only the launcher and runtime state. The v2
configuration moved to `~/.config/opencodev2`, which has its own `.chezmanga`
changelog.

## 2026-09-21T19:40:00+08:00 - Keep only the launcher and runtime state here

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `opencode2.cmd`, `xdg/config` (removed from chezmoi)
- Summary: `opencode2.cmd` now sets `XDG_CONFIG_HOME` to
  `%USERPROFILE%\.config\opencodev2`; the configuration files it used to carry are
  managed under `~/.config/opencodev2`.
- Important records:
  - `XDG_DATA_HOME`, `XDG_STATE_HOME`, and `XDG_CACHE_HOME` still resolve through
    `%~dp0`, so the database, credentials, and cache stay isolated from v1.
  - The stale `~/.opencode-v2/xdg/config` directory is still on disk for the
    running service and can be removed after a verified restart.
- Portability: The wrapper uses `%USERPROFILE%` for the configuration root and
  `%~dp0` for everything else.
- Chezmoi: `.chezmoiignore` now excludes the whole `.opencode-v2/xdg/**` runtime tree.
- Verification: The applied `opencode2.cmd` contains the new `XDG_CONFIG_HOME`
  value; the v2 configuration resolves at the new path.

## 2026-09-21T18:08:45+08:00 - Restore V2 session todos with a temporary plugin

- Status: Completed
- Machine: TC-TSENG
- Platform: Windows x64
- Scope: `xdg/config/opencode/opencode.json`
- Summary: Added the archived community `opencode2-todo` plugin from GitHub to restore the V2 `todowrite` tool and per-round todo injection.
- Important records:
  - This is not an official OpenCode package and is intentionally temporary.
  - The plugin provides `todowrite`, but not a separate `todoread` tool.
  - V1 was not changed because it has its own native/plugin configuration.
  - The `plan` agent now uses Opus 5 so the default session model is Opus 5. `general` is a subagent and cannot be a default primary agent. Fable stays limited to the adversarial agents and manual selection.
- Portability: The plugin is loaded from a Git package specification; no machine-specific absolute path was added.
- Chezmoi: Updated the V2 source configuration and will apply only the V2 configuration target.
- Verification: Confirmed local V2 is `opencode v2.0.11`; before the change, `opencode2 plugin list` showed no todo plugin. Post-apply plugin health verification remains pending.

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

## 2026-09-21T10:40:37+08:00 - Bridge tuios and scoop config into the sandbox

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `run_onchange_after_setup-opencode-v2.ps1.tmpl`, `xdg/config/tuios`,
  `xdg/config/scoop`
- Summary: Junctioned `~/.config/tuios` and `~/.config/scoop` into the sandbox
  as well, after confirming that their sandbox copies were generated defaults
  rather than an intentional split.
- Important records:
  - The previous entry recorded these two as deliberately divergent. That was
    wrong, and this entry corrects it. Diffing the files showed the sandbox
    copies were written by the tools themselves when they found no config:
    `xdg/config/tuios/config.toml` at 2026-09-21 09:57 and
    `xdg/config/scoop/config.json` at 2026-09-18 16:34.
  - The generated TUIOS file was the full 6993-byte default template with
    `leader_key='ctrl+b'` and with `alt+h/j/k/l` and `alt+1..9` bound. The
    managed 1515-byte config releases exactly those keys because GlazeWM owns
    them, so a sandboxed TUIOS session had colliding bindings.
  - The generated Scoop file kept only `last_update` and lost `scoop_repo`,
    `scoop_branch`, and `lastupdate`.
  - Both generated copies were renamed to `<name>_backup_20260921_103935`
    inside `xdg/config` rather than deleted. They hold no user content and can
    be removed.
- Portability: The three bridged names now share one `foreach` loop over the
  existing Windows-only `Set-Junction` helper.
- Chezmoi: Updated the managed setup script; the junctions were created
  directly so the runtime matches now, and the idempotent script reproduces
  them on the next apply and on other machines.
- Verification: The rendered template parses as PowerShell and the source is
  LF-only. Reading through `$XDG_CONFIG_HOME` inside this session now returns
  `leader_key='alt+a'`, `preferred_shell='nu'`, `theme='tokyonight'`, and
  `dockbar_position='top'` for TUIOS, and the full four-key Scoop config. No
  TUIOS or Scoop process was launched to confirm runtime behavior.

## 2026-09-21T15:12:17+08:00 - Upgrade to OpenCode 2.0.11 and share the slim skills manifest with v1

- Status: Completed
- Machine: TC-TSENG
- Platform: Microsoft Windows 10.0.26200 / X64
- Scope: `run_onchange_after_setup-opencode-v2.ps1.tmpl` and `.chezmoiignore`
  in the chezmoi source root; runtime `bin/opencode.exe` and
  `xdg/config/opencode/.oh-my-opencode-slim`
- Summary: The sandbox binary moved from 2.0.5 to 2.0.11, the minimum for
  `oh-my-opencode-slim@2.2.22` is 2.0.7. A fourth junction now maps
  `xdg/config/opencode/.oh-my-opencode-slim` to
  `~/.config/opencode/.oh-my-opencode-slim` so the plugin's skill tombstones
  are the same file under both runtimes.
- Important records:
  - This corrects the 2026-09-17T14:21 entry, which recorded that no
    `oh-my-opencode-slim` build worked on v2. Since `2.2.19` (2026-09-12) the
    stable `2.2.x` line exports both `server()` and `setup()`; `2.2.22`
    (2026-09-19) pins the 2.0.7 baseline. The `3.0.0-beta.*` line is the
    marketplace branch and is not the v2 port.
  - `oh-my-opencode-slim` copies its bundled skills into
    `$XDG_CONFIG_HOME/opencode/skills` on every top-level session unless
    `$XDG_CONFIG_HOME/opencode/.oh-my-opencode-slim/skills-manifest.json`
    marks them `deleted`. Because `skills/` is already a junction to the v1
    tree, a missing v2 manifest would have written the eight skills into the
    shared directory, and v1 would then have adopted them back as `managed`.
    The v1 manifest, its `skills.lock` directory, and `skill-updates/` are all
    content-hash based and safe to share.
  - `Install-Binary` now renames a running `opencode.exe` to
    `opencode.exe.previous` before moving the new one in. This apply ran from
    inside a v2 session, and Windows refuses to overwrite a mapped image but
    allows renaming it. `opencode.exe.previous` (2.0.5) can be deleted after
    the service restarts; it is under the ignored `bin/`.
  - The five `opencode.exe` processes alive during the apply still run 2.0.5.
    `opencode2 service restart` (or closing all sessions) is required before
    2.0.11 is actually used.
  - `xdg/config/opencode/cli.json` differs from its source (`theme.name`
    changed from `github` to `ayu` by the TUI). It was deliberately not
    touched or re-added; it remains an open conflict for a separate decision.
- Portability: The junction reuses the existing `foreach` over `Set-Junction`
  from `$HOME`. The rename-aside logic is Windows-only, like the rest of the
  script. The version stays in the single `$version` variable.
- Chezmoi: Updated the managed setup script and `.chezmoiignore`; applied with
  `chezmoi apply --include=scripts` to avoid the unrelated `cli.json` prompt.
  The onchange script re-ran and downloaded `@opencode/cli-windows-x64@2.0.11`.
- Verification: `bin/.version` and `bin/opencode.exe --version` both report
  2.0.11. The new junction reports `LinkType=Junction` to
  `C:\Users\tc_tseng\.config\opencode\.oh-my-opencode-slim`, and reading the
  manifest through it lists all eight skills as `deleted`. The rendered
  template is LF-only. Loading `oh-my-opencode-slim@2.2.22` in a v2 project
  session was not exercised because no project has been re-applied yet.
