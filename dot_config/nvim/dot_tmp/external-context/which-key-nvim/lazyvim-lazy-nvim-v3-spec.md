---
source: Context7 API + official LazyVim/lazy.nvim docs
library: folke/which-key.nvim
package: which-key.nvim
topic: LazyVim/lazy.nvim v3 spec API groups and descriptions
tech_stack: LazyVim, lazy.nvim, Neovim Lua
fetched: 2026-06-12T00:00:00Z
official_docs: https://github.com/folke/which-key.nvim/blob/main/doc/which-key.nvim.txt
related_docs:
  - https://www.lazyvim.org/configuration/plugins
  - https://lazy.folke.io/spec
---

# which-key.nvim v3 spec API in LazyVim/lazy.nvim

## Relevant current API

- Use `require("which-key").add(spec, opts?)` for v3 registration.
- Legacy `require("which-key").register(...)` is the old v1 API and should be migrated to `wk.add(...)`.
- A spec item has the shape `{ lhs, rhs?, desc=..., group=..., mode=..., icon=..., ... }`.
- A group label is created with `group = "name"` and no right-hand side; this does not create a keymap.
- Existing keymap labels shown by which-key come from the mapping `desc` field. To override a displayed description, define a lazy.nvim `keys` entry or a which-key spec with the same lhs/mode and the desired `desc`.
- `wk.add()` can be called multiple times; calls are queued until setup completes.
- Attributes such as `mode`, `buffer`, `icon`, `cond`, and similar fields can be inherited by nested specs.

## LazyVim/lazy.nvim placement

LazyVim plugin overrides go under `lua/plugins/*.lua`, for example `lua/plugins/which-key.lua`.

LazyVim uses lazy.nvim spec merging:

- `opts` tables are merged with the parent/default spec.
- `keys` lists are extended.
- To override a keymap, add another keymap with the same lhs/mode and a new rhs/desc.
- lazy.nvim recommends `opts` instead of manually calling `setup()` in `config` when possible.

## Example: add group labels via which-key v3 `spec`

```lua
-- lua/plugins/which-key.lua
return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "ai" },
        { "<leader>m", group = "markdown" },
        { "<leader>o", group = "open" },
        { "<leader>r", group = "run" },
        { "<leader>t", group = "test" },
      },
    },
  },
}
```

## Example: override descriptions through LazyVim/lazy.nvim `keys`

Use this when the keymap already exists or when you also want lazy.nvim to own the mapping.

```lua
-- lua/plugins/which-key.lua
return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>g", group = "git" },
        { "<leader>s", group = "search" },
      },
    },
  },

  -- Example plugin whose LazyVim key descriptions you want to override
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep text" },
    },
  },
}
```

## Example: add descriptions without creating mappings

Use `wk.add()` when you only need which-key metadata for mappings defined elsewhere.

```lua
-- lua/plugins/which-key.lua
return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>f", group = "file/find" },
        { "<leader>ff", desc = "Find files" },
        { "<leader>fr", desc = "Recent files" },

        { "<leader>c", group = "code" },
        { "<leader>ca", desc = "Code action" },
        { "<leader>cr", desc = "Rename symbol" },
      },
    },
  },
}
```

## Example: direct `wk.add()` call from `config`

Prefer `opts.spec` in LazyVim when possible. Use this only if you need to compute specs at load time.

```lua
-- lua/plugins/which-key.lua
return {
  {
    "folke/which-key.nvim",
    opts = {},
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>n", group = "notes" },
        { "<leader>nn", desc = "New note" },
        { "<leader>ns", desc = "Search notes" },
      })
    end,
  },
}
```

## v1 to v3 migration pattern

```lua
-- old/deprecated style
require("which-key").register({
  ["<leader>"] = {
    f = { name = "+file" },
  },
})

-- current v3 spec style
require("which-key").add({
  { "<leader>f", group = "file" },
})
```

## Notes for LazyVim configs

- Put the returned plugin spec in `lua/plugins/which-key.lua`.
- For label-only group headings, use `opts.spec` with `{ lhs, group = "..." }`.
- For actual keymap descriptions, prefer the plugin's `keys = { { lhs, rhs, desc = "..." } }` override when you need to replace LazyVim defaults.
- Match the same `mode` when overriding or disabling keymaps; normal mode can omit `mode`.
