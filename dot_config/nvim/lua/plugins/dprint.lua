return {
  {
    "neovim/nvim-lspconfig",
    cond = function()
      return not vim.g.vscode
    end,
    opts = {
      servers = {
        dprint = {
          mason = false,
          filetypes = {
            "cs",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "json",
            "jsonc",
            "markdown",
            "css",
            "scss",
            "sass",
            "less",
            "html",
          },
        },
      },
    },
  },
}
