# Cortexkit Chezmoi Changelog

## 2026-10-05T21:45:05+08:00 - Manage Magic Context config

- Status: Completed
- Machine: TC-TSENG
- Platform: windows/x64
- Scope: `magic-context.jsonc`
- Summary: Put the Magic Context plugin config under chezmoi. Historian and dreamer both use `omniroute/claude-sonnet`.
- Important records:
  - The plugin itself is installed through opencode-assets; this scope only holds its user config.
  - The file contains no secrets or machine-specific paths.
- Portability: Portable; the model ID depends only on the OmniRoute provider being configured.
- Chezmoi: Added `magic-context.jsonc` and `.chezmanga/` as a new management root.
- Verification: Scoped `chezmoi status` is clean after apply; source uses LF.
