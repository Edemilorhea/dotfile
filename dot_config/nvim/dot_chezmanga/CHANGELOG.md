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

## 2026-09-07T10:26:42+08:00 - Disable default ESLint diagnostics

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/config/lazy.lua`, `lua/config/keymaps.lua`, `lua/keymap/neovim.lua`, `lua/plugins/eslint.lua`, `lua/plugins/diagnostics.lua`, `lua/plugins/which-key.lua`
- Summary: Disabled automatic ESLint startup and removed inline diagnostic text and underlines while preserving diagnostic signs and Trouble workflows.
- Important records:
  - Imported only the ESLint and diagnostics overrides instead of the broader unused LSP override, avoiding unrelated LSP behavior changes.
  - `:EslintToggle` now uses `vim.lsp.enable()` directly without reloading the buffer or redundantly stopping clients.
  - Removed the tiny-inline-diagnostic plugin configuration and its obsolete `<leader>xm` mapping and which-key label.
- Portability: Uses LazyVim and Neovim APIs without machine-specific paths; ESLint diagnostics still require a project ESLint dependency and configuration.
- Chezmoi: Updated six existing managed source files and applied only their corresponding Neovim targets.
- Verification: Lua parsing passed for all six files; headless Neovim confirmed ESLint was off by default, toggled on and off successfully, and resolved diagnostics with virtual text, virtual lines, and underlines disabled while signs remained enabled; obsolete inline-diagnostic references were absent; Git whitespace checks passed; edited Lua files used LF line endings.

## 2026-09-07T10:42:34+08:00 - Focus line diagnostic popup

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/keymap/neovim.lua`, `lua/plugins/ui-restructured.lua`, `lua/plugins/which-key.lua`
- Summary: Changed `<leader>xx` to open diagnostics for the current line in a focused floating window so its text can be selected and copied.
- Important records:
  - The previous mapping opened a native diagnostic float without entering it; moving the source cursor triggered Neovim's default `CursorMoved` close event.
  - Disabled LazyVim's `<leader>xx` Trouble key in the plugin spec so loading Trouble cannot replace the custom float mapping; `<leader>xX` remains available for buffer diagnostics in Trouble.
- Portability: Uses only native Neovim diagnostic and window APIs without machine-specific paths.
- Chezmoi: Updated three existing managed source files and applied only their corresponding Neovim targets.
- Verification: A fresh headless Neovim session retained the custom callback after Trouble loaded, opened a real floating window, focused it, and kept it open after cursor movement inside the popup; Lua parsing, Git whitespace checks, and LF line-ending checks passed.

## 2026-09-07T11:03:30+08:00 - Style diagnostic popup

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/keymap/neovim.lua`
- Summary: Added a soft cyan rounded border and dark gray background to the focused current-line diagnostic popup so its boundaries are visually clear.
- Important records:
  - The change affects only `<leader>xx`; Trouble diagnostic splits retain their existing appearance.
- Portability: Uses Neovim's built-in floating-window and highlight APIs without machine-specific paths.
- Chezmoi: Updated the existing managed source and applied only its corresponding Neovim target.
- Verification: A fresh headless Neovim session retained the mapping after Trouble loaded and reported the expected window highlight mapping, `#9CCFD8` border, and `#2A2D34` background; Lua parsing, Git whitespace, and LF line-ending checks passed.

## 2026-09-07T11:10:17+08:00 - Enable ESLint only for configured projects

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/config/options.lua`, `lua/config/keymaps.lua`, `lua/plugins/eslint.lua`
- Summary: Enabled ESLint by default while allowing nvim-lspconfig to start its client only when the current project contains an ESLint configuration.
- Important records:
  - Reuses nvim-lspconfig's built-in detection for `.eslintrc*`, `eslint.config.*`, and `eslintConfig` in `package.json` instead of maintaining duplicate root logic.
  - `<leader>uE` and `:EslintToggle` remain global session controls; disabling waits for the LSP client's asynchronous shutdown.
- Portability: Relies on project-relative configuration discovery and contains no machine-specific paths.
- Chezmoi: Updated three existing managed source files and applied only their corresponding Neovim targets.
- Verification: Fresh headless sessions confirmed no ESLint client for a JavaScript buffer without configuration, automatic attachment for a buffer with `eslint.config.js`, and successful manual disable and re-enable after client shutdown; Lua parsing, Git whitespace, and LF line-ending checks passed.

## 2026-09-07T14:16:00+08:00 - Unify floating window styling

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/config/options.lua`, `lua/config/autocmds.lua`, `lua/keymap/neovim.lua`
- Summary: Added rounded borders and a dark gray background to standard floating windows, including LSP information popups and Snacks notifications, so popup content is visually distinct from the source buffer.
- Important records:
  - Set Neovim's global `winborder` default to `rounded` and reapplied the shared float highlights after every colorscheme change.
  - Snacks notifier uses dedicated highlight groups, so its message, history, and border groups now inherit the same shared float colors.
  - The focused `<leader>xx` diagnostic popup now uses the global style instead of maintaining duplicate private highlights.
- Portability: Uses Neovim 0.12 options and highlight APIs without machine-specific paths.
- Chezmoi: Updated three existing managed source files and applied only their corresponding Neovim targets.
- Verification: Headless Neovim confirmed rounded borders with `#2A2D34` backgrounds and `#9CCFD8` borders for a generic LSP-style float, the focused diagnostic popup, and Snacks notifier groups; the colors remained correct after switching colorschemes; Lua parsing, Git whitespace, and LF line-ending checks passed.

## 2026-09-07T14:44:02+08:00 - Add borders to Noice popups

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/config/autocmds.lua`, `lua/plugins/ui-restructured.lua`
- Summary: Added the shared rounded border and float colors to Noice LSP hover windows and other Noice popups that bypass Neovim's global floating-window defaults.
- Important records:
  - Noice's hover view explicitly used `border.style = "none"`, so the global `winborder` option could not affect the popup opened by `K`.
  - Enabled Noice's official `lsp_doc_border` preset and linked its popup, popup-menu, command-line, and confirmation highlight groups to the shared float style.
- Portability: Uses Noice's documented preset and Neovim highlight APIs without machine-specific paths.
- Chezmoi: Updated two existing managed source files and applied only their corresponding Neovim targets.
- Verification: A real `K` mapping with `lua_ls` attached opened a rounded floating window; merged Noice options resolved the hover border to `rounded`; Lua parsing and Git whitespace checks passed.
