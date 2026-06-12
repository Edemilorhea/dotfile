return {
  "stevearc/conform.nvim",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({
          async = true,
          lsp_format = "fallback",
        })
      end,
      mode = { "n", "v" },
      desc = "格式化",
    },
  },
  opts = function(_, opts)
    local function has_config(ctx, names)
      local filename = ctx.filename
      if not filename or filename == "" then
        return false
      end

      if filename:match("unnamed_temp") then
        return false
      end

      if vim.fn.filereadable(filename) == 0 then
        return false
      end

      return vim.fs.find(names, {
        path = vim.fs.dirname(filename),
        upward = true,
      })[1] ~= nil
    end

    ---@type conform.setupOpts
    opts = opts or {}
    opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
      lua = { "stylua" },
      python = { "black" },
      javascript = { "dprint", "biome", "prettier", stop_after_first = true },
      typescript = { "dprint", "biome", "prettier", stop_after_first = true },
      javascriptreact = { "dprint", "biome", "prettier", stop_after_first = true },
      typescriptreact = { "dprint", "biome", "prettier", stop_after_first = true },
      json = { "dprint", "biome", "prettier", stop_after_first = true },
      jsonc = { "dprint", "biome", "prettier", stop_after_first = true },
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
    })

    opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
        stylua = {
          prepend_args = { "--indent-type", "Spaces", "--indent-width", "4" },
        },
        black = {
          prepend_args = { "--line-length", "88", "--target-version", "py38" },
        },
        prettier = {
          prepend_args = { "--tab-width", "4", "--use-tabs", "false" },
          condition = function(_, ctx)
            return has_config(ctx, {
              ".prettierrc",
              ".prettierrc.json",
              ".prettierrc.json5",
              ".prettierrc.yml",
              ".prettierrc.yaml",
              ".prettierrc.js",
              ".prettierrc.cjs",
              ".prettierrc.mjs",
              "prettier.config.js",
              "prettier.config.cjs",
              "prettier.config.mjs",
            })
          end,
        },
        biome = {
          condition = function(_, ctx)
            return has_config(ctx, { "biome.json", "biome.jsonc" })
          end,
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
        dprint = {
          command = vim.fn.expand("~/.dprint/bin/dprint"),
          condition = function(_, ctx)
            return has_config(ctx, { "dprint.json", "dprint.jsonc" })
          end,
          args = function(_, ctx)
            return {
              "fmt",
              "--stdin",
              ctx.filename,
            }
          end,
          stdin = true,
        },
      })

    return opts
  end,
}
