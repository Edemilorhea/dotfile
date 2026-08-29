# Rio Chezmoi Changelog

## 2026-08-26T10:00:45+08:00 - Initialize Rio configuration

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.toml`
- Summary: Added a Rio configuration aligned with the current Alacritty appearance, shell, and terminal key sequences.
- Important records:
  - Rio 0.5.26 uses its documented Webgpu default; no obsolete DX12 backend override is set.
  - The Plain navigation mode leaves tab and pane management to terminal multiplexers.
  - Control+F12, Control+Slash, and Control+H preserve the psmux and Neovim escape sequences from Alacritty.
- Portability: Rio platform-neutral settings are shared; the user-scoped `RIO_CONFIG_HOME` selects this path on Windows.
- Chezmoi: Added and managed as `dot_config/rio/config.toml` with a dedicated Rio marker and changelog.
- Verification: Nushell parsed the TOML, scoped apply deployed the config, and Rio 0.5.26 ran for three seconds with an empty warning log; final scoped synchronization was clean.

## 2026-08-26T15:08:51+08:00 - Stabilize Windows renderer startup

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.toml`
- Summary: Selected Rio's OpenGL WebGPU backend on Windows to remove the multi-second startup tail from automatic Vulkan adapter initialization.
- Important records:
  - TRACE diagnostics showed the automatic path creating Vulkan, DX12, and OpenGL backends before selecting the Intel Vulkan adapter.
  - Controlled measurements reproduced 1.85-4.33 second automatic-backend starts; OpenGL completed in 0.89-1.85 seconds under the same test.
  - DX12 was not selected because it was inconsistent and reached 2.71 seconds in the comparison.
- Portability: The backend override is under `platform.windows`; other operating systems retain Rio's default renderer selection.
- Chezmoi: Updated the already managed `config.toml` source and applied only that target.
- Verification: A Windows platform override created only the OpenGL backend and selected the Intel OpenGL adapter. Five bounded checks of the applied configuration reached a responding Rio window in 329-599 ms with no timeout; full Rio, Nushell, and first-prompt checks completed in 721-1025 ms before the portability refinement.

## 2026-08-28T01:00:06+08:00 - Automate Rio config path

- Status: Completed
- Machine: DESKTOP-3JHKCAP
- Platform: windows/x64
- Scope: `run_onchange_after_set-rio-config-home.ps1.tmpl`
- Summary: Added a Windows chezmoi script that persists `RIO_CONFIG_HOME` at the user level so Rio reads configuration and themes from `~/.config/rio`.
- Important records:
  - The script also sets the variable in its own process; existing shells and applications must be restarted to inherit the persisted user environment.
  - `run_onchange` reruns only when the managed script content changes.
- Portability: The script renders only on Windows and derives the path from the active user's home directory without a machine-specific absolute path.
- Chezmoi: Added a managed root-level script associated with the Rio configuration scope.
- Verification: The rendered PowerShell parsed successfully, scoped chezmoi application persisted the expected user environment value, and the Rio targets remained synchronized.

## 2026-08-29T12:13:06+08:00 - Deepen terminal background

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `config.toml`
- Summary: Changed the Rio background from `#1c1f24` to the deeper gray `#121417` to improve contrast for Nushell completion selections.
- Important records:
  - Foreground and selection colors remain unchanged so the adjustment is limited to the terminal background.
  - Existing target-only comments and `navigation.mode` casing were preserved instead of applying the full source file over them.
- Portability: The color is platform-neutral and contains no machine-specific paths or values.
- Chezmoi: Updated the managed source and the active target directly because unrelated target differences already existed.
- Verification: The source and active target use the same background value; TOML parsing and scoped synchronization were checked after the edit.
