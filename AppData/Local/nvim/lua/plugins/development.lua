-- plugins/development.lua
-- 開發相關插件 (LSP、自動完成、搜尋工具)

return {
    -- Plenary - 基礎工具庫 (被依賴時自動載入)
    {
        "nvim-lua/plenary.nvim",
        lazy = true, -- 被其他插件依賴時會自動載入
        vscode = true,
    },

    -- Mason LSP 管理器 (只在 Neovim 中使用)
    {
        "williamboman/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonLog" },
        build = ":MasonUpdate",
        cond = not vim.g.vscode,
        opts = {},
    },

    {
        "williamboman/mason-lspconfig.nvim",
        event = "VeryLazy",
        cond = not vim.g.vscode,
        opts = {
            ensure_installed = {
                "lua_ls",
                "jsonls",
                "ts_ls",
                "html",
                "cssls",
                "volar",
                "emmet_ls",
                "eslint",
                "omnisharp",
                "pyright",
                "marksman",
            },
        },
    },

    -- LSP 配置 (只在 Neovim 中使用)
    {
        "neovim/nvim-lspconfig",
        cond = not vim.g.vscode,
        opts = function()
            local Keys = require("lazyvim.plugins.lsp.keymaps").get()
            vim.list_extend(Keys, {
                { "gd", false },
                { "gr", false },
                { "gI", false },
                { "gy", false },
            })
        end,
    },

    -- 自動完成增強 (按需載入)
    {
        "hrsh7th/nvim-cmp",
        cond = not vim.g.vsocde,
        event = "InsertEnter", -- 進入插入模式時載入
        dependencies = {
            "hrsh7th/cmp-emoji",
        },
    },
}

