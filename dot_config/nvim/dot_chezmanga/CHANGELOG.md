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

## 2026-09-09T09:58:17+08:00 - Add C# solution selection

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/config/csharp.lua`, `lua/plugins/csharp.lua`, `lua/config/lazy.lua`, `tests/csharp_solution_spec.lua`
- Summary: Added `:CSharpSolution` and `:CSharpStatus`, gated automatic OmniSharp startup on solution selection, and removed the task-only test file.
- Important records:
  - Selection is stored per Git worktree or nearest solution workspace under `stdpath("state")`; only `.sln` and `.slnf` candidates at the nearest solution boundary are offered.
  - Cancelling does not start or replace an active client; switching waits for the old client in the current selection root to stop before starting OmniSharp with `-s` and the selected absolute solution path.
  - Status reports the selection root and actual client initialization separately, and reports full analysis readiness as unknown because OmniSharp exposes no reliable readiness signal.
- Portability: Uses Neovim state storage and normalized discovered paths without hard-coded project or machine paths.
- Chezmoi: Added the C# configuration and plugin override, updated the explicit plugin import, removed the task-only test from source and runtime, and applied only this Neovim scope.
- Verification: One headless `loadfile` pass parsed the three Lua files successfully without loading the configuration or starting OmniSharp; no test suite or solution process was run.

## 2026-09-09T16:52:35+08:00 - Limit OmniSharp background diagnostics

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/config/csharp.lua`; companion user-level `~/.omnisharp/omnisharp.json`
- Summary: Disabled extra analyzer support, restricted diagnostics to open documents, and limited diagnostic workers to two to address sustained OmniSharp CPU usage.
- Important records:
  - Set both startup arguments and LSP settings in the solution controller so limits are available before project loading and remain consistent after initialization.
  - Added the existing user-level OmniSharp configuration to source state, removed obsolete VS Code Roslynator paths, and aligned its settings because the global JSON overrides command-line options.
  - Solution selection and project loading scope are unchanged; the global JSON also affects other OmniSharp clients for this user. The companion file is outside the Neovim marker's ownership scope.
  - Existing Neovim/OmniSharp processes require a restart; reduced CPU usage and navigation behavior have not yet been measured with the new settings.
- Portability: Uses portable OmniSharp options without machine-specific extension paths.
- Chezmoi: Updated the existing Neovim source, added `dot_omnisharp/omnisharp.json`, and applied only the two configuration targets and this changelog.
- Verification: Inspected the scoped deployment diff and applied the configuration successfully; no functional test or automatic process restart was performed.

## 2026-09-09T17:25:01+08:00 - Switch C# language service to Roslyn

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/plugins/csharp.lua`
- Summary: Replaced the active OmniSharp startup hook with roslyn.nvim and restricted Roslyn background compiler and analyzer diagnostics to open files.
- Important records:
  - Existing Roslyn registry settings were in an unimported plugin file; the active C# spec now adds the Crashdummyy Mason registry and ensures the `roslyn` package is installed.
  - Disabled OmniSharp and the separate nvim-lspconfig `roslyn_ls` startup path so roslyn.nvim owns C# startup. The old OmniSharp controller remains on disk but is no longer initialized.
  - Solution selection now uses `:Roslyn target`; the installed plugin supports `.sln`, `.slnx`, and `.slnf`. The old controller's persisted selection and commands are not used.
  - Installed roslyn.nvim and Mason's `roslyn` package version `5.12.0-1.26453.19`; downloaded dependencies remain runtime-only.
  - Neovim 0.12.5 meets the plugin's minimum 0.12 requirement. Existing Neovim sessions need restarting.
- Portability: Uses Mason's platform-specific packages and plugin-native discovery without hard-coded machine or project paths.
- Chezmoi: Updated the existing managed C# plugin source and applied its runtime target.
- Verification: Inspected deployment diff and the successful Mason installation receipt. No C# project was started, and navigation or CPU behavior has not been tested.

## 2026-09-11T15:09:44+08:00 - Restore diagnostic underlines

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/plugins/diagnostics.lua`
- Summary: Re-enabled diagnostic underlines so errors and warnings are marked at their source range, while inline message text stays hidden.
- Important records:
  - The 2026-09-07 change disabled `underline` together with `virtual_text` and `virtual_lines`, which left only the sign-column icon to indicate a problem and gave no in-line position.
  - Only `underline` was changed to `true`; `virtual_text` and `virtual_lines` remain `false` so the code layout does not shift.
  - The file header comment was corrected to match the new behavior.
  - Underline color comes from the colorscheme's `DiagnosticUnderline*` highlight groups and was not modified.
- Portability: Uses LazyVim and Neovim diagnostic options without machine-specific paths.
- Chezmoi: Updated the existing managed source and applied only the corresponding Neovim target.
- Verification: Headless Neovim reported `underline=true`, `virtual_text=false`, `virtual_lines=false`, and signs enabled, and a seeded error diagnostic produced one `DiagnosticUnderline` extmark plus one sign extmark; source and target are synchronized with LF line endings.

## 2026-09-18T23:39:13+08:00 - Capture cwd-scoped pickers, the explorer sidebar, and Vue support

- Status: Completed
- Machine: tc-tseng
- Platform: windows/x64
- Scope: `lua/config/lazy.lua`, `lua/config/options.lua`, `lua/plugins/tools.lua`, `lua/plugins/ui-restructured.lua`
- Summary: Brought four Neovim files that had drifted on this machine back into chezmoi and added the Vue language extra. Root-directory resolution is now the current working directory, Telescope keymaps are declared once, Snacks Explorer runs as a resizable sidebar with a main-window preview, and LazyVim's Vue extra is loaded.
- Important records:
  - `vim.g.root_spec = { "cwd" }` replaces LazyVim's default `{ "lsp", { ".git", "lua" }, "cwd" }`. Dashboard Find File, `\ff`, and `\e` previously escaped to a parent project root.
  - Because `root_spec` now settles the scope, `tools.lua` dropped its `config` function and the seven manual `vim.keymap.set` wrappers that forced `cwd` on each Telescope picker. Keymaps exist only in the `keys` table.
  - The Snacks Explorer contribution sets `preset = "sidebar"` with `preview = "main"`, binds `<C-Left>` / `<C-Right>` to resize by five columns and `=` to reset, clamps the width between 20 columns and `vim.o.columns - 20`, and restores the last width through `on_show`. The custom `<leader>e` / `<leader>E` maps were removed in favour of LazyVim's `\fe` and `\fE`.
  - `lazy.lua` gained `lazyvim.plugins.extras.lang.vue`. The chezmoi source had also dropped `{ import = "plugins.persistence" }`; that import is deliberately kept. `plugins/persistence.lua` only supplies `branch = false` to the persistence.nvim instance that LazyVim already declares in `lazyvim/plugins/util.lua`, so losing the import would not disable sessions, only re-enable the slow per-exit Git branch lookup that worktrees make pointless.
  - These four targets had been edited on this machine on 2026-09-16 and never re-added, while the chezmoi source still held 2026-09-04 to 2026-09-07 versions. The machine state was declared authoritative, so the source was updated from the target rather than the reverse.
- Portability: All four files use LazyVim, Snacks, and Telescope APIs with no machine-specific paths. The explorer width is a runtime value, not a stored path.
- Chezmoi: Re-added the four existing managed sources from their targets after editing `lazy.lua` in place; chezmoi's autocommit and autopush published each one.
- Verification: Scoped `chezmoi status` is clean for all four targets and every source file is LF-only. Neovim was not restarted, so the Vue extra, the explorer sidebar bindings, and the picker scope remain unverified at runtime.

## 2026-09-21T14:04:14+08:00 - Telescope path display for deep project trees

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `lua/plugins/tools.lua`
- Summary: Made Telescope distinguish identically named files in deeply nested projects. Results now show the filename first with its directory chain after it, and the preview window is always available with a title that tracks the selected entry.
- Important records:
  - `path_display` changed from `{ "smart" }` to `{ filename_first = { reverse_directories = true } }`. The `smart` display collapsed the shared prefix into `..`, so files such as `SystemSettings/ApiConnectionQuery.cs` and `Impl/ApiConnectionQuery.cs` rendered almost identically. `reverse_directories` puts the closest parent directory first so width truncation keeps the most distinguishing segment.
  - `dynamic_preview_title = true` makes the preview border title show the selected file path.
  - `layout_config.preview_cutoff` changed from `120` to `0`. At 120 the preview was suppressed whenever the terminal was narrower than 120 columns, which also hid the dynamic title.
  - Telescope has no built-in footer for the selected entry; a prompt-border footer was considered and rejected because the border title is truncated to the prompt window width and solves nothing that the two settings above do not already cover.
  - Rebound horizontal results scrolling to `<C-h>` and `<C-l>` in both insert and normal mode. Telescope's defaults `<M-f>` and `<M-k>` are captured by GlazeWM on this machine and never reach Neovim.
  - `<C-l>` previously held `actions.complete_tag`, which was moved to `<C-y>`. That action only applies to pickers built on `prefilter_sorter` (`lsp_document_symbols`, `lsp_workspace_symbols`, `treesitter`, `diagnostics`) and raises `No tag pre-filtering set for this picker` elsewhere. Losing the key would not disable `:tag:` prefiltering itself, only the completion popup.
  - Every action mapping wraps `require("telescope.actions")` in a closure. The `opts` table is a literal evaluated when lazy.nvim reads the spec at startup, so a bare `require` there would force Telescope to load eagerly.
- Portability: Pure Telescope options with no machine-specific paths. The `<C-h>` / `<C-l>` choice is driven by a GlazeWM keybinding present on this machine but is harmless on hosts without it.
- Chezmoi: Updated the existing managed source and applied the scoped target.
- Verification: Scoped `chezmoi diff` showed only the intended hunks and scoped `chezmoi status` is clean; the source file is LF-only; `loadfile` on the applied target reported no syntax error. Neovim was not restarted, so the rendered picker layout and the new keymaps are unverified at runtime.
## 2026-09-21T14:37:24+08:00 - Rider-style C# semantic highlighting

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `lua/config/autocmds.lua`
- Summary: Added a JetBrains Rider inspired highlight set for C# LSP semantic tokens. C# previously had no colour rules at all, and Roslyn's tokens suppressed the generic treesitter ones.
- Important records:
  - The existing JetBrains-style overrides in `lua/plugins/ui-restructured.lua` are bound to `tsx`, `typescript`, and `typescriptreact` apart from the generic `@keyword*` and `@comment` rules. No `.cs` rule existed anywhere in the configuration.
  - Roslyn negotiates the pure LSP token schema for non Visual Studio clients. Beyond the standard types it emits C# specific custom types such as `controlKeyword`, `field`, `constant`, `recordClass`, `recordStruct`, `delegate`, `extensionMethod`, `stringVerbatim`, `excludedCode`, `xmlDocComment*`, and `regex*`. Neither Neovim's default links nor rose-pine define those groups, so the spans fell back to `Normal`.
  - Token names were taken from `CustomLspSemanticTokenNames.cs` and `SemanticTokensSchema.cs` in dotnet/roslyn rather than guessed. A misspelled group fails silently with no visible difference.
  - Semantic token extmarks use priority 125 against treesitter's 100. Types that treesitter already renders well (`variable`, `parameter`, `property`, `namespace`, `string`, `number`, `operator`, `comment`, `punctuation`, `whitespace`, `text`) are cleared to an empty table so the theme and the existing `@keyword` and `@comment` overrides keep winning.
  - Palette reuses the existing TypeScript hexes for shared concepts (`#4EC9B0` types, `#39CC9B` methods) and adds Rider's field purple `#9876AA` and doc-comment green `#629755`. It is not Darcula: the user's established keyword colour is blue `#6C95EB`, so `controlKeyword` links to `@keyword` instead of Darcula orange.
  - Modifier groups carry style only and no colour, so they compose on top of the type mark: `deprecated` strikethrough and `reassignedVariable` underline, matching Rider.
  - Installed under a `ColorScheme` autocommand plus an immediate call, following the `set_indent_hl` and `set_float_hl` pattern already in this file, so the colours survive a colourscheme switch. The TypeScript overrides still live in rose-pine's `config` function and do not have that protection; left unchanged.
  - Only the `cs` filetype is covered. Razor buffers use the `razor` filetype and were not addressed.
- Portability: Plain Neovim highlight APIs and literal hex colours with no machine-specific paths.
- Chezmoi: Updated the existing managed source and applied the scoped target.
- Verification: `loadfile` reported no syntax error, and sourcing the file in a headless session resolved every representative group to the intended value (`@lsp.type.field.cs` 0x9876AA, `@lsp.type.class.cs` 0x4EC9B0, `@lsp.type.extensionMethod.cs` 0x39CC9B italic, `@lsp.type.xmlDocCommentText.cs` 0x629755, `@lsp.type.variable.cs` empty, `@lsp.mod.reassignedVariable.cs` underline). Scoped `chezmoi status` is clean and the file is LF-only. No C# solution was opened against a live Roslyn server, so the rendered result in a real buffer is unverified.

## 2026-09-21T14:51:24+08:00 - Centralize syntax overrides and cover Razor

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `lua/config/autocmds.lua`, `lua/plugins/ui-restructured.lua`
- Summary: Closed the two items left open by the previous entry. The C# highlight set now also covers Razor buffers, and the generic plus TypeScript overrides moved out of rose-pine's config function into the same ColorScheme hook so they survive a colourscheme switch.
- Important records:
  - Roslyn also serves Razor. Razor buffers use the `razor` filetype, and Neovim appends the filetype to every semantic token highlight group, so the same rules had to be registered twice. `set_csharp_hl` was restructured to key the table by bare token name and loop over `{ "cs", "razor" }`.
  - The fifteen `nvim_set_hl` calls previously at the end of rose-pine's `config` function ran exactly once at startup. Any later `:colorscheme` reset them, including the tokyonight fallback path in that same function. They are now `set_lang_hl` in `autocmds.lua`, called through `set_syntax_hl` together with the C# rules from one `ColorScheme` autocommand plus an immediate call.
  - rose-pine's `config` now only applies the theme. Hex literals were normalized to uppercase during the move; the colour values themselves are unchanged.
  - Startup ordering is safe either way. If `autocmds.lua` loads before the colourscheme, the autocommand reapplies the overrides; if it loads after, the immediate call covers it. This matches the existing `set_indent_hl` and `set_float_hl` pattern in the same file.
- Portability: Plain Neovim highlight APIs and literal hex colours with no machine-specific paths.
- Chezmoi: Updated two existing managed sources and applied both scoped targets.
- Verification: `loadfile` reported no syntax error for either file. A headless session sourced `autocmds.lua` and confirmed `@keyword` #6C95EB, `@comment` #85BA59, `@tag.tsx` #4EC9B0, `@lsp.type.field.cs` #9876AA, `@lsp.type.field.razor` #9876AA, `@lsp.type.controlKeyword.razor` linked to `@keyword`, and `@lsp.type.variable.razor` empty; every value was identical after `:colorscheme desert`, which is the regression this change targets. Scoped `chezmoi status` is clean and both files are LF-only. No Razor or C# project was opened against a live Roslyn server, so the rendered result in a real buffer is unverified.
