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
        },
        
        -- 補全設定
        completion = {
            accept = {
                auto_brackets = {
                    enabled = true,
                },
            },
            menu = {
                draw = {
                    treesitter = { "lsp" },
                },
            },
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
