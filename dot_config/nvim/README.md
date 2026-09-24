# Neovim 設定

以 [LazyVim](https://lazyvim.github.io) 為基礎，由 chezmoi 管理（變更紀錄見 `.chezmanga/CHANGELOG.md`）。

## 入口

`init.lua` 只做分流：

```text
init.lua
├─ vim.g.vscode → lua/vscode_mode/   VSCode Neovim：只載入 core
└─ 其他         → lua/config/lazy.lua 完整 LazyVim
```

## 目錄

| 路徑 | 用途 |
|---|---|
| `lua/core/` | 兩個入口共用：基本選項、習慣鍵位、輕量外掛（surround、flash、mini.comment）|
| `lua/vscode_mode/` | VSCode 專用：lazy.nvim 啟動、VSCode 指令對應鍵位 |
| `lua/config/` | 完整 Neovim：LazyVim 的 options / keymaps / autocmds，以及 highlights、markdown TOC、restart |
| `lua/plugins/` | 完整 Neovim 的外掛規格，依領域分檔（coding、editor、git、lsp、csharp、markdown、tools、ui ...）|
| `lua/customfile/` | markdown-preview 的 CSS |
| `snippets/`、`templates/` | 片段與 ESLint 範本 |

## 規則

- 兩邊都要的設定放 `lua/core/`；只給 VSCode 的放 `lua/vscode_mode/`。
- 覆寫 LazyVim 外掛的 `keys` 時，要在外掛規格用 `{ lhs, false }` 停用原鍵，不要只在 `config/keymaps.lua` 重綁。
- 修改請先改 chezmoi source，再 `chezmoi apply`。
