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
