return {
  "stevearc/conform.nvim",
  opts = function()
    ---@type conform.setupOpts
    local opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        vue = { "prettier" },
        svelte = { "prettier" },
        go = { "gofmt" },
        rust = { "rustfmt" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        java = { "google-java-format" },
        php = { "php_cs_fixer" },
        sh = { "shfmt" },
        fish = { "fish_indent" },
      },
      formatters = {
        stylua = {
          prepend_args = { "--indent-type", "Spaces", "--indent-width", "4" },
        },
        black = {
          prepend_args = { "--line-length", "88", "--target-version", "py38" },
        },
        prettier = {
          prepend_args = { "--tab-width", "4", "--use-tabs", "false" },
        },
        gofmt = {
          prepend_args = { "-s" },
        },
        rustfmt = {
          prepend_args = { "--edition", "2021" },
        },
        clang_format = {
          prepend_args = { "--style={IndentWidth: 4, UseTab: Never}" },
        },
        ["google-java-format"] = {
          prepend_args = { "--aosp" },
        },
        php_cs_fixer = {
          prepend_args = { "--rules=@PSR12,array_indentation" },
        },
        shfmt = {
          prepend_args = { "-i", "4", "-ci" },
        },
        fish_indent = {
          prepend_args = {},
        },
      },
    }
    return opts
  end,
}
