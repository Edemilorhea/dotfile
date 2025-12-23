-- plugins/development.lua
-- 開發相關插件 (LSP、自動完成、搜尋工具)
-- 注意：mason 和 mason-lspconfig 已在 lsp.lua 中定義，此處移除避免重複

return {
    -- Plenary - 基礎工具庫 (被依賴時自動載入)
    {
        "nvim-lua/plenary.nvim",
        lazy = true, -- 被其他插件依賴時會自動載入
        vscode = true,
    },

    -- 注意：mason.nvim 和 mason-lspconfig.nvim 已在 lua/plugins/lsp.lua 中定義
    -- 避免重複定義，已移除

    -- 注意：nvim-lspconfig 已在 lua/plugins/lsp.lua 中定義
    -- 避免重複定義，已移除

    -- 自動完成增強 (按需載入)
    -- 注意：LazyVim 15.x 預設使用 blink.cmp，nvim-cmp 已被替換
    -- 如果你需要 nvim-cmp，請啟用 coding.nvim-cmp extra
    {
        "hrsh7th/nvim-cmp",
        enabled = false, -- LazyVim 15.x 已改用 blink.cmp
        cond = not vim.g.vscode,
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-emoji",
        },
    },
}

