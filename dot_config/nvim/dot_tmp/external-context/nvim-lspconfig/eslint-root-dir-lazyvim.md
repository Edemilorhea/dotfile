---
source: Context7 API + official docs fallback
library: nvim-lspconfig / LazyVim
package: nvim-lspconfig
topic: ESLint root_dir gating and LazyVim setup
fetched: 2026-06-10T00:00:00Z
official_docs: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/eslint.lua; https://www.lazyvim.org/extras/linting/eslint
---

# ESLint language server in Neovim / LazyVim

## nvim-lspconfig current eslint behavior

Official `nvim-lspconfig` `lsp/eslint.lua` defines the ESLint config file list:

```lua
local eslint_config_files = {
  '.eslintrc',
  '.eslintrc.js',
  '.eslintrc.cjs',
  '.eslintrc.yaml',
  '.eslintrc.yml',
  '.eslintrc.json',
  'eslint.config.js',
  'eslint.config.mjs',
  'eslint.config.cjs',
  'eslint.config.ts',
  'eslint.config.mts',
  'eslint.config.cts',
}
```

The current upstream `root_dir` first determines a project root from lock files or `.git`, excludes Deno projects, then only calls `on_dir(project_root)` if an ESLint config file or `package.json` with `eslintConfig` is found upward from the buffer, stopping at the project root parent. If no ESLint config is found, it returns without starting ESLint.

Key upstream logic:

```lua
root_dir = function(bufnr, on_dir)
  local root_markers = { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock' }
  root_markers = vim.fn.has('nvim-0.11.3') == 1 and { root_markers, { '.git' } }
    or vim.list_extend(root_markers, { '.git' })

  if vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc', 'deno.lock' }) then
    return
  end

  local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local eslint_config_files_with_package_json =
    util.insert_package_json(eslint_config_files, 'eslintConfig', filename)
  local is_buffer_using_eslint = vim.fs.find(eslint_config_files_with_package_json, {
    path = filename,
    type = 'file',
    limit = 1,
    upward = true,
    stop = vim.fs.dirname(project_root),
  })[1]
  if not is_buffer_using_eslint then
    return
  end

  on_dir(project_root)
end
```

Other relevant upstream defaults:

```lua
workspace_required = true
settings = {
  workingDirectory = { mode = 'auto' },
  format = true,
}
```

## LazyVim ESLint extra

LazyVim's ESLint extra configures `nvim-lspconfig` with:

```lua
opts = {
  ---@type table<string, vim.lsp.Config>
  servers = {
    eslint = {
      settings = {
        -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
        workingDirectories = { mode = "auto" },
        format = auto_format,
      },
    },
  },
}
```

## New lspconfig API compatibility

nvim-lspconfig documents that since Nvim 0.11 configs are provided through Neovim's built-in `vim.lsp.config` interface. The old `require('lspconfig').SERVER.setup({})` framework is deprecated and old configs under `lua/lspconfig/configs/` will be deleted.

Current style examples:

```lua
vim.lsp.config("eslint", {
  -- config overrides
})
vim.lsp.enable("eslint")
```

LazyVim still exposes plugin `opts.servers.eslint` as the normal override point, with server config typed as `vim.lsp.Config`.

## Focused example: only start ESLint when config exists

For current upstream nvim-lspconfig, this behavior is already built into `eslint.lua`. If overriding in LazyVim, preserve the same gating idea: return `nil` / do not call `on_dir` when no ESLint config is found.

```lua
{
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      eslint = {
        root_dir = function(bufnr, on_dir)
          local eslint_config_files = {
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.yaml",
            ".eslintrc.yml",
            ".eslintrc.json",
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
            "eslint.config.ts",
            "eslint.config.mts",
            "eslint.config.cts",
          }

          if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
            return
          end

          local fname = vim.api.nvim_buf_get_name(bufnr)
          local project_root = vim.fs.root(bufnr, {
            { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" },
            { ".git" },
          }) or vim.fn.getcwd()

          local config = vim.fs.find(eslint_config_files, {
            path = fname,
            upward = true,
            type = "file",
            limit = 1,
            stop = vim.fs.dirname(project_root),
          })[1]

          if config then
            on_dir(project_root)
          end
        end,
        settings = {
          workingDirectory = { mode = "auto" },
        },
      },
    },
  },
}
```
