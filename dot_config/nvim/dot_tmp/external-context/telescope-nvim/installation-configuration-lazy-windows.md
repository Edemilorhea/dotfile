---
source: Context7 API + official project docs
library: telescope.nvim
package: nvim-telescope/telescope.nvim
topic: installation/configuration with lazy.nvim or LazyVim; fzf-native Windows caveats; commands/pickers/colorscheme
fetched: 2026-06-11T00:00:00Z
official_docs: https://github.com/nvim-telescope/telescope.nvim
---

# telescope.nvim — lazy.nvim / LazyVim actionable notes

## lazy.nvim spec

From telescope.nvim README, minimal lazy.nvim install requires `plenary.nvim`:

```lua
return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8", -- or branch = "0.1.x"
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("telescope").setup({
      defaults = {},
      pickers = {},
      extensions = {},
    })
  end,
}
```

Verify after install:

```vim
:checkhealth telescope
:Telescope find_files
```

Lua invocation:

```lua
require("telescope.builtin").find_files()
```

## Optional fzf-native extension

`telescope-fzf-native.nvim` is optional, compiled C sorter support. It must be built; binaries are not shipped.

Recommended lazy.nvim dependency:

```lua
{
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install",
    },
  },
  config = function()
    require("telescope").setup({
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    })
    require("telescope").load_extension("fzf")
  end,
}
```

### Windows build caveats

- CMake path works on Windows, Linux, macOS.
- On Windows, install **CMake** and **Microsoft C++ Build Tools**.
- Alternative `build = "make"` only works on Windows if using MinGW with `gcc`/`clang` and `make` available.
- If fzf-native fails to load, rebuild the plugin and restart Neovim.

## Core commands and pickers

Command-line examples:

```vim
:Telescope find_files
:Telescope live_grep
:Telescope buffers
:Telescope help_tags
:Telescope colorscheme enable_preview=true
```

Lua/keymap examples:

```lua
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>uC", function()
  builtin.colorscheme({ enable_preview = true })
end, { desc = "Colorscheme with preview" })
```

`builtin.colorscheme(opts)` supports:

- `colors`: extra colorschemes to make available
- `enable_preview`: preview selected color
- `ignore_builtins`: omit built-in colorschemes

## Picker theme example

```lua
require("telescope").setup({
  pickers = {
    find_files = {
      theme = "dropdown",
    },
  },
})
```

Or command-line:

```vim
:Telescope find_files theme=dropdown
```

## LazyVim notes

LazyVim provides a Telescope extra:

```vim
:LazyExtras
```

Select `editor.telescope`, or set:

```lua
-- lua/config/options.lua
vim.g.lazyvim_picker = "telescope"
```

LazyVim's Telescope extra includes `telescope.nvim`, optional `telescope-fzf-native.nvim`, and default keymaps such as:

- `<leader><space>` / `<leader>ff`: find files
- `<leader>/` / `<leader>sg`: live grep
- `<leader>,`: buffers
- `<leader>uC`: colorscheme with preview
- `<leader>sh`: help tags
- `<leader>sk`: keymaps
- `<leader>sC`: commands

LazyVim chooses file commands in order: `rg`, `fd`, `fdfind`, Unix `find`, then Windows `where`.

## Sources

- Context7: `/nvim-telescope/telescope.nvim`, query: installation/configuration lazy.nvim LazyVim plenary fzf-native Windows commands pickers colorscheme
- telescope.nvim README/docs: https://github.com/nvim-telescope/telescope.nvim
- telescope-fzf-native README: https://github.com/nvim-telescope/telescope-fzf-native.nvim
- LazyVim Telescope extra: https://www.lazyvim.org/extras/editor/telescope
