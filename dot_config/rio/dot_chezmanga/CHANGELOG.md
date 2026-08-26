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
