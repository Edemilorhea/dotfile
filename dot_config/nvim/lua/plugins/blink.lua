-- blink.cmp 完整配置
return {
    "saghen/blink.cmp",
    version = "v0.*",
    dependencies = {
        "rafamadriz/friendly-snippets",
    },
    event = { "InsertEnter", "CmdlineEnter" },
    
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        -- 外觀設定
        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono",
        },
        
        -- 補全來源
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
            providers = {
                lsp = { score_offset = 100 },      -- LSP 最優先
                path = { score_offset = 80 },
                snippets = { score_offset = 60 },
                buffer = { score_offset = 0 },     -- buffer 最低
            },
        },
        
        -- 補全設定
        completion = {
            accept = {
                -- 關閉 auto_brackets：避免對每個 C# 補全項做 semantic 解析判斷是否補括號
                -- （C# 補全項目多，會拖慢選單）
                auto_brackets = {
                    enabled = false,
                },
            },
            -- 移除 draw.treesitter：不對每個補全項跑 treesitter 高亮，加快選單繪製
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 200,
            },
        },
        
        -- 簽名幫助
        signature = {
            enabled = true,
        },
        
        -- 按鍵設定
        keymap = {
            preset = "enter",
            ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-e>"] = { "hide" },
            ["<C-y>"] = { "select_and_accept" },

            -- Tab：有補全選單時接受選取，否則走原本縮排 (fallback)
            ["<Tab>"] = { "select_and_accept", "fallback" },
            ["<S-Tab>"] = { "select_prev", "fallback" },
        },
        
        -- 命令列補全 (修復 keymap 問題)
        cmdline = {
            enabled = true,
            keymap = {
                preset = "cmdline",
                -- 修復: 不使用 false,改用空陣列
                ["<Right>"] = {},
                ["<Left>"] = {},
            },
        },
    },
}
