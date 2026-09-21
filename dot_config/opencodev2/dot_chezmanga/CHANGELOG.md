# OpenCode v2 Configuration Changelog

Management root: `~/.config/opencodev2`

This tree holds every OpenCode v2 configuration file. `opencode2.cmd` points
`XDG_CONFIG_HOME` here, so OpenCode v2 reads `~/.config/opencodev2/opencode`.
The v2 binary, database, credentials, and other runtime state stay in
`~/.opencode-v2` and are excluded from chezmoi.

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