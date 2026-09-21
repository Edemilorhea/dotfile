# OpenCode v2 Configuration Changelog

Management root: `~/.config/opencodev2`

This tree holds every OpenCode v2 configuration file. `opencode2.cmd` points
`XDG_CONFIG_HOME` here, so OpenCode v2 reads `~/.config/opencodev2/opencode`.
The v2 binary, database, credentials, and other runtime state stay in
`~/.opencode-v2` and are excluded from chezmoi.

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
