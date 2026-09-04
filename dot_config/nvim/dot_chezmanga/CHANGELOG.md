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

## 2026-08-27T00:49:24+08:00 - Replace dashboard logo

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `lua/plugins/ui-restructured.lua`
- Summary: Replaced the LazyVim Snacks dashboard header with a static ANSI Shadow rendering of `EDEMILORHEA`.
- Important records:
  - The customization overrides only `dashboard.preset.header`; existing dashboard keys and Explorer settings remain intact.
  - The generated banner is stored statically, so Neovim startup does not invoke Node.js or FIGlet.
- Portability: The header uses terminal block and box-drawing glyphs without machine-specific paths.
- Chezmoi: Updated the managed plugin configuration and applied only that target.
- Verification: Headless Neovim resolved the merged Snacks options and printed the complete six-line custom header without errors.

## 2026-08-28T01:23:05+08:00 - Manage persistence session override

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `lua/plugins/persistence.lua`
- Summary: Added the persistence.nvim override to chezmoi so Neovim skips Git branch lookup when saving sessions on exit.
- Important records:
  - `branch = false` keeps one session per working directory instead of deriving a branch-specific session name.
  - The configured chezmoi add hook created commit `6e54095`, but its automatic push was rejected because the remote branch is ahead; no pull, rebase, or retry was performed.
- Portability: The override uses no machine-specific paths and applies across worktrees and supported operating systems.
- Chezmoi: Added the previously unmanaged runtime file as `dot_config/nvim/lua/plugins/persistence.lua`.
- Verification: `chezmoi source-path` resolved the target; scoped diff was empty; headless Neovim parsed the Lua file successfully; Git reported LF in the index and worktree.

## 2026-09-04T16:49:11+08:00 - Keep Telescope searches inside cwd

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `lua/plugins/tools.lua`
- Summary: Changed common Telescope file and text searches to stay below Neovim's current working directory and enabled `Ctrl+V` clipboard paste in Telescope prompts.
- Important records:
  - LazyVim's later Telescope extra replaced the existing shortcuts with project-root searches, which could resolve to a parent backend Git repository.
  - The mappings now resolve `vim.uv.cwd()` when each picker opens, so workspace changes remain effective without changing LSP root detection.
- Portability: Uses Neovim APIs and the system clipboard register without machine-specific paths.
- Chezmoi: Updated the existing managed source and applied only the corresponding Neovim target.
- Verification: Headless Neovim loaded Telescope, confirmed the effective file and grep callbacks received the current working directory, and found the `Ctrl+V` insert mapping; Lua parsing and Git whitespace checks passed; source and target were synchronized with LF line endings.
