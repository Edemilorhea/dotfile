---
source: Context7 API
library: conform.nvim + LazyVim
package: conform.nvim
topic: LazyVim dprint formatting configuration
fetched: 2026-06-12T00:00:00Z
official_docs: https://www.lazyvim.org/plugins/formatting | https://github.com/stevearc/conform.nvim/blob/master/doc/conform.txt
---

# LazyVim + conform.nvim + dprint

Relevant current docs excerpts from Context7:

## LazyVim conform.nvim options

LazyVim configures `stevearc/conform.nvim` via plugin `opts`. Do not override `plugin.config` for conform.nvim because LazyVim warns this breaks LazyVim formatting. Extend `opts` instead.

LazyVim default formatting options include:

```lua
default_format_opts = {
  timeout_ms = 3000,
  async = false,
  quiet = false,
  lsp_format = "fallback",
}
```

LazyVim docs show custom formatters are configured under `formatters`, and filetype mappings under `formatters_by_ft`. It also documents a dprint condition example:

```lua
formatters = {
  injected = { options = { ignore_errors = true } },
  -- Example of using dprint only when a dprint.json file is present
  -- dprint = {
  --   condition = function(ctx)
  --     return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
  --   end,
  -- },
}
```

## conform.nvim formatters_by_ft

Conform maps filetypes to formatter names:

```lua
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "goimports", "gofmt" }, -- sequential formatters
    rust = { "rustfmt", lsp_format = "fallback" },
  },
  default_format_opts = {
    lsp_format = "fallback",
  },
  format_on_save = {
    lsp_format = "fallback",
    timeout_ms = 500,
  },
})
```

## Custom formatter command and args

Conform formatter definitions support `command`, `args`, `prepend_args`, `append_args`, `stdin`, `cwd`, `require_cwd`, `condition`, `inherit`, and more:

```lua
formatters = {
  my_formatter = {
    command = "my_cmd",
    args = { "--stdin-from-filename", "$FILENAME" },
    stdin = true,
    cwd = require("conform.util").root_file({ ".editorconfig", "package.json" }),
    require_cwd = true,
    condition = function(self, ctx)
      return vim.fs.basename(ctx.filename) ~= "README.md"
    end,
    inherit = true,
  },
}
```

For overriding a built-in formatter, Conform supports adding arguments:

```lua
require("conform").formatters.shfmt = {
  append_args = { "-i", "2" },
}
```

## Actionable LazyVim example: dprint for TS/JS/JSON

```lua
-- lua/plugins/formatting.lua
return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        typescript = { "dprint" },
        typescriptreact = { "dprint" },
        javascript = { "dprint" },
        javascriptreact = { "dprint" },
        json = { "dprint" },
        jsonc = { "dprint" },
      },
      formatters = {
        dprint = {
          -- Use only in projects with dprint config
          condition = function(_, ctx)
            return vim.fs.find({ "dprint.json", "dprint.jsonc" }, {
              path = ctx.filename,
              upward = true,
            })[1]
          end,
        },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
    },
  },
}
```

## Custom dprint executable or args

Use this when `dprint` is not on PATH, or when you want explicit config args:

```lua
return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        dprint = {
          command = "/absolute/path/to/dprint",
          args = { "fmt", "--stdin", "$FILENAME" },
          stdin = true,
          cwd = require("conform.util").root_file({ "dprint.json", "dprint.jsonc", ".git" }),
          require_cwd = true,
        },
      },
    },
  },
}
```

If keeping Conform's built-in dprint definition, prefer `prepend_args`/`append_args` over replacing all `args` unless you know the built-in invocation shape.

## LSP fallback guidance

- `lsp_format = "fallback"`: run configured formatter; use LSP only if no formatter is available.
- LazyVim defaults to `fallback` and says this is not recommended to change globally.
- You can set fallback globally in `default_format_opts`, for save in `format_on_save`, or per filetype entry such as `{ "dprint", lsp_format = "fallback" }`.
