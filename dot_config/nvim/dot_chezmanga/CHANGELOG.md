# Neovim Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for Neovim configuration.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - Plugin caches and downloaded dependencies are not approved by this marker.
- Portability: Marker metadata contains no host-specific paths; the machine name is audit metadata only.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-08-24T15:11:30+08:00 - Require project dprint configuration

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `lua/plugins/formatting.lua`
- Summary: Prevented Conform from running dprint without a project configuration so LSP formatting can handle those buffers instead.
- Important records:
  - Set `dprint.require_cwd = true`; projects with `dprint.json` continue to use dprint.
  - A scoped `chezmoi apply` was interrupted and did not update the target, so the verified source change was synchronized directly to the single runtime file.
- Portability: Uses Conform's project-root detection and contains no machine-specific path.
- Chezmoi: Updated the existing managed source and synchronized the corresponding target file.
- Verification: Isolated headless Neovim checks reported dprint unavailable with `Root directory not found` outside a configured project and available inside the Neovim project; the Lua file parsed successfully; source and target hashes matched; line endings were LF; scoped `chezmoi status` was empty.
