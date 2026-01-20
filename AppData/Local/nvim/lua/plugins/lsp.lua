return {
    {
        "neovim/nvim-lspconfig",
        vscode = false,
        lazy = true,
        cond = function()
            return not vim.g.vscode
        end,
        opts = {
            -- LazyVim 15.x: 使用原生 LSP 折疊
            inlay_hints = { enabled = true },
            codelens = { enabled = false },
            document_highlight = { enabled = true },
            -- 啟用 LazyVim 原生 LSP 折疊功能
            folds = {
                enabled = true, -- 改為 true，使用原生功能
            },
            -- 語言伺服器設定
            servers = {
                -- 全域設定
                lua_ls = {
                    settings = {
                        Lua = {
                            workspace = { checkThirdParty = false },
                            telemetry = { enable = false },
                            diagnostics = { globals = { "vim" } },
                        },
                    },
                },
            },
        },
    },
    {
        "mason-org/mason.nvim",
        -- LazyVim 15.x: mason 倉庫已重命名為 mason-org/mason.nvim
        cmd = { "Mason", "MasonInstall", "MasonLog" },
        build = ":MasonUpdate",
        vscode = false,
        lazy = true,
        cond = function()
            return not vim.g.vscode
        end,
        opts = {},
    },
    {
        "mason-org/mason-lspconfig.nvim",
        -- LazyVim 15.x: mason-lspconfig 倉庫已重命名為 mason-org/mason-lspconfig.nvim
        lazy = true,
        event = "VeryLazy",
        vscode = false,
        cond = function()
            return not vim.g.vscode
        end,
        opts = {
            ensure_installed = {
                "lua_ls",
                "jsonls",
                "ts_ls",
                "html",
                "cssls",
                "vue-language-server",
                "emmet_ls",
                "eslint",
                "omnisharp",
                "pyright",
                "marksman",
            },
        },
    },
}
