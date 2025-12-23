-- plugins/shared.lua
-- VSCode 和 Neovim 都支援的插件
return {
    -- nvim-surround - 兩邊都能用的文字包圍插件
    {
        "kylechui/nvim-surround",
        version = "^3.0.0",
        event = "VeryLazy",
        vscode = true,
        config = function()
            require("nvim-surround").setup({
                -- 保持預設設定，確保 VSCode 和 Neovim 行為一致
                keymaps = {
                    insert = "<C-g>s",
                    insert_line = "<C-g>S",
                    normal = "ys",
                    normal_cur = "yss",
                    normal_line = "yS",
                    normal_cur_line = "ySS",
                    visual = "S",
                    visual_line = "gS",
                    delete = "ds",
                    change = "cs",
                    change_line = "cS",
                },
            })
        end,
    },

    -- flash.nvim - 快速移動插件，兩邊都支援
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        vscode = true,
        opts = {
            modes = {
                search = {
                    enabled = true,
                    autojump = false,
                    autohide = false,
                    highlight = {
                        backdrop = true,
                        matches = true,
                    },
                    jump = {
                        history = true,
                    },
                },
                char = {
                    enabled = true,
                    autojump = true,
                    autohide = false,
                    jump = {
                        history = true,
                    },
                },
            },
        },
        keys = {
            {
                "s",
                mode = { "n", "x", "o" },
                function()
                    require("flash").jump()
                end,
                desc = "Flash",
            },
            {
                "S",
                mode = { "n", "x", "o" },
                function()
                    require("flash").treesitter()
                end,
                desc = "Flash Treesitter",
            },
            {
                "r",
                mode = "o",
                function()
                    require("flash").remote()
                end,
                desc = "Remote Flash",
            },
            {
                "R",
                mode = { "o", "x" },
                function()
                    require("flash").treesitter_search()
                end,
                desc = "Treesitter Search",
            },
        },
    },

    -- mini.comment - 輕量級註解插件（替代 Comment.nvim）
    {
        "echasnovski/mini.comment",
        event = "VeryLazy",
        vscode = true,
        opts = {
            options = {
                custom_commentstring = nil,
                ignore_blank_line = false,
                start_of_line = false,
                pad_comment_parts = true,
            },
            mappings = {
                comment = "gc",
                comment_line = "gcc",
                comment_visual = "gc",
                textobject = "gc",
            },
            hooks = {
                pre = function() end,
                post = function() end,
            },
        },
        config = function(_, opts)
            require("mini.comment").setup(opts)
        end,
        keys = {
            { "<C-/>", "gcc", mode = "n", remap = true, desc = "Comment line" },
            { "<C-_>", "gcc", mode = "n", remap = true, desc = "Comment line" },
            { "<C-/>", "gc", mode = "v", remap = true, desc = "Comment selection" },
            { "<C-_>", "gc", mode = "v", remap = true, desc = "Comment selection" },
        },
    },
}