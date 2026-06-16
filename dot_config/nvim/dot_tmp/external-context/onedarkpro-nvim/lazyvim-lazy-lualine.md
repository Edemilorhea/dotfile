---
source: Context7 API + official README/GitHub API
library: olimorris/onedarkpro.nvim
package: onedarkpro.nvim
topic: lazy.nvim LazyVim setup, colorscheme names, lualine compatibility
tech_stack: lazy.nvim, LazyVim, Neovim
fetched: 2026-06-11T00:00:00Z
official_docs: https://github.com/olimorris/onedarkpro.nvim
---

# onedarkpro.nvim with lazy.nvim / LazyVim

## Minimal lazy.nvim spec

Official lazy.nvim example:

```lua
{
  "olimorris/onedarkpro.nvim",
  priority = 1000, -- Ensure it loads first
}

-- somewhere in your config:
vim.cmd("colorscheme onedark")
```

For LazyVim, prefer a colorscheme plugin spec that loads on startup:

```lua
return {
  {
    "olimorris/onedarkpro.nvim",
    lazy = false,
    priority = 1000,
    opts = {}, -- call setup() with defaults; customize here if needed
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
    },
  },
}
```

If you do not use LazyVim's `colorscheme` option, apply it in `config` after setup:

```lua
{
  "olimorris/onedarkpro.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("onedarkpro").setup({})
    vim.cmd.colorscheme("onedark")
  end,
}
```

## Setup requirements

- Neovim 0.9.2+
- `termguicolors` enabled for true color support
- Tree-sitter for full syntax highlighting
- For semantic tokens, an LSP server that supports semantic tokens
- `require("onedarkpro").setup(...)` is only required when changing defaults, but using `opts = {}` in lazy.nvim is safe and explicit.
- If using custom options, setup must happen before `:colorscheme`.

## Correct colorscheme names

The current built-in themes are:

- `onedark`
- `onelight`
- `onedark_vivid`
- `onedark_dark`
- `vaporwave`

Use the exact underscore names, for example:

```lua
vim.cmd.colorscheme("onedark_vivid")
```

## priority / lazy=false guidance

- Official docs recommend `priority = 1000` so the theme loads first.
- In lazy.nvim/LazyVim, add `lazy = false` for startup colorschemes to avoid flash/fallback themes and ensure highlights are available early.
- If other plugins consume onedarkpro colors during setup, ensure onedarkpro loads before them.

## Lualine compatibility

The plugin provides lualine themes out of the box under `lua/lualine/themes` for:

- `onedark`
- `onelight`
- `onedark_vivid`
- `onedark_dark`
- `vaporwave`

Use matching theme names in lualine:

```lua
require("lualine").setup({
  options = {
    theme = "onedark", -- or "onedark_vivid", "onedark_dark", "onelight", "vaporwave"
  },
})
```

For LazyVim's lualine plugin override:

```lua
{
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      theme = "onedark",
    },
  },
}
```

The onedarkpro option `options.lualine_transparency` controls center bar transparency when using custom lualine themes based on onedarkpro colors.

## Sources used

- Context7 library ID: `/olimorris/onedarkpro.nvim`
- Official README: https://github.com/olimorris/onedarkpro.nvim
- Lualine theme files listing: https://github.com/olimorris/onedarkpro.nvim/tree/main/lua/lualine/themes
