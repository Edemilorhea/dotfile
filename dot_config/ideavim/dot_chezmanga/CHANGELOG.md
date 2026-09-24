# IdeaVim Chezmoi Changelog

## 2026-08-21T21:26:29+08:00 - Initialize management scope

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `.`
- Summary: Added a dedicated marker and changelog for IdeaVim configuration.
- Important records:
  - The nearest ancestor marker owns future records; nested markers take precedence.
  - The home-level `.ideavimrc` symlink remains represented by this application scope.
- Portability: Marker metadata contains no host-specific paths; the machine name is audit metadata only.
- Chezmoi: Added and managed as `dot_chezmanga/CHANGELOG.md`.
- Verification: `chezmoi source-path` resolved the target, scoped apply created it, and scoped diff was empty.

## 2026-09-24T11:57:20+08:00 - Align IdeaVim keys with Neovim

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `ideavimrc`
- Summary: Remapped Rider actions to the same keys as the Neovim (LazyVim) config. Rider-only actions keep their keys unless they collided with a Neovim key.
- Important records:
  - Moved: `gm`→`gI` implementation, `<Tab>`/`<S-Tab>`→`]b`/`[b`, `\co`/`\cl`/`\cr`/`\cua`→`\bo`/`\bl`/`\br`/`\bP`, `<C-m>`→`\wm`, `\f`→`\fg`/`\sg`/`\/`, `\r`→`\cf`, `\b`→`\db` breakpoint, `\fm`→`\ss`, `\ot`→`\tt`/`\ft`, `\tf`→`\e`, `\fcf`→`\fn`, `\ty`→`\tr` translate.
  - Added: `gr`, `K`, `gK`, `]]`/`[[`, `]d`/`[d`, `]f`/`[f`, `\sS`, `\ca`, `\cr` rename, `\cR`, `\xx`, `\xX`, `\bd`, `\bp`, `\1`-`\9`, `\sv`/`\sh`/`\sx`, `\ff`, `\<Space>`, `\fb`, `\fr`, `\sr`, and the `'`/`` ` `` swap.
  - Removed `map Q gq`; Neovim's `Q` replays the last macro.
  - Kept pending discussion: `jj`, `\sc`, `\gd` (database; Neovim uses it for git diff), `z1`-`z5`/`za1`-`za5`.
- Portability: No paths; the home `.ideavimrc` symlink is unchanged.
- Chezmoi: Updated the managed source and applied the scoped target.
- Verification: File is LF-only and scoped `chezmoi status` is clean. Rider was not reloaded, so action IDs such as `PinActiveTabToggle`, `GotoNextElementUnderCaretUsage`, and `GoToTab1` are unverified.
## 2026-09-24T16:24:23+08:00 - Move database tool window key

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `ideavimrc`
- Summary: The Database tool window moved from `\gd` to `\dd`, so `\g` stays git-only like Neovim.
- Important records:
  - Action IDs used by the Neovim alignment (`PinActiveTabToggle`, `GotoNextElementUnderCaretUsage`, `GoToTab1`-`9`, `CloseContent`, `RenameFile`, and others) were confirmed in the installed Rider 2026.2 `intellij.platform.ide.impl.jar`.
  - SQL console actions found in `database-plugin.jar`: `Jdbc.OpenConsole.Any` (Jump to Query Console, `Ctrl+Shift+F10`), `Jdbc.OpenConsole.New` (`Ctrl+Shift+Q`), `Jdbc.OpenConsole.New.Generate` (current `\doc`). Not remapped yet.
- Portability: No paths.
- Chezmoi: Updated the managed source and applied the scoped target.
- Verification: File is LF-only and scoped `chezmoi status` is clean. Rider was not reloaded.
## 2026-09-24T16:40:00+08:00 - Add SQL console key

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `ideavimrc`
- Summary: `\dq` runs `Jdbc.OpenConsole.Any` (Jump to Query Console), which asks for a data source and then opens an existing or new query console from any context.
- Important records:
  - `\doc` (`Jdbc.OpenConsole.New.Generate`) is kept; it needs a selected data source.
  - Insert-mode `jj` stays as it is. CapsLock-to-Esc was rejected because CapsLock is still used, and `jk` would have the same `notimeout` wait.
- Portability: No paths.
- Chezmoi: Updated the managed source and applied the scoped target.
- Verification: File is LF-only and scoped `chezmoi status` is clean. Rider was not reloaded, so the popup behavior outside the Database tool window is unverified.