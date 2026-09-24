-- 兩個環境共用的 plugin。VSCode 只載入這個檔案；Neovim 會再與 LazyVim 的同名設定合併。
return {
    {
        "kylechui/nvim-surround",
        version = "^3.0.0",
        event = "VeryLazy",
        opts = {},
    },

    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            modes = {
                search = {
                    enabled = true,
                    autojump = false,
                    autohide = false,
                    highlight = { backdrop = true, matches = true },
                    jump = { history = true },
                },
                char = {
                    enabled = true,
                    autojump = true,
                    autohide = false,
                    jump = { history = true },
                },
            },
        },
        keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash 跳轉" },
            { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash 語法樹跳轉" },
            { "r", mode = "o", function() require("flash").remote() end, desc = "遠端 Flash 跳轉" },
            { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "語法樹搜尋" },
        },
    },

    {
        "nvim-mini/mini.comment",
        event = "VeryLazy",
        opts = {},
    },
}
