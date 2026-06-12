return {
    -- vim-visualrepeat 插件
    {
        "inkarkat/vim-visualrepeat",
        event = "VeryLazy",
    },
    {
        "nvim-telescope/telescope.nvim",
        vscode = false,
        version = false,
        cmd = { "Telescope" }, -- 使用命令時載入
        dependencies = {
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                enabled = vim.fn.executable("make") == 1,
            },
        },
        config = function()
            require("telescope").setup({
                defaults = {
                    prompt_prefix = "> ",
                    selection_caret = "> ",
                    path_display = { "smart" },
                    file_ignore_patterns = { "node_modules", ".git/" },
                    layout_config = {
                        horizontal = {
                            preview_width = 0.55,
                            results_width = 0.8,
                        },
                        vertical = {
                            mirror = false,
                        },
                        width = 0.87,
                        height = 0.80,
                        preview_cutoff = 120,
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                },
            })
            -- 載入 fzf 擴展
            pcall(require("telescope").load_extension, "fzf")
        end,
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "搜尋檔案" },
            { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "全文搜尋" },
            { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "搜尋 Buffer" },
            { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "搜尋說明文件" },
            { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "最近開啟檔案" },
            { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "搜尋游標文字" },
        },
    },
    {
        -- Float term
        "voldikss/vim-floaterm",
        lazy = false,
        config = function()
            local keymap = vim.keymap

            keymap.set("n", "<leader>tc", ":FloatermNew --height=0.95 --width=0.95<CR>", { desc = "新增終端機" })
            keymap.set("n", "<leader>tt", ":FloatermToggle<CR>", { desc = "切換終端機" })
            keymap.set("n", "<leader>tp", ":FloatermPrev<CR>", { desc = "上一個終端機" })
            keymap.set("n", "<leader>tn", ":FloatermNext<CR>", { desc = "下一個終端機" })
            keymap.set("n", "<leader>tg", ":FloatermNew --height=0.95 --width=0.95 lazygit<CR>", { desc = "開啟 Lazygit" })
            keymap.set("n", "<leader>tq", ":FloatermKill<CR>", { desc = "關閉終端機" })
            keymap.set("n", "<leader>th", ":FloatermHide<CR>", { desc = "隱藏終端機" })
        end,
    },
    {
        -- Tmux & neovim navigator
        "alexghergh/nvim-tmux-navigation",
        keys = { "<C-h>", "<C-j>", "<C-k>", "<C-l>", "<C-\\>", "<C-Space>" },
        config = function()
            local nav = require("nvim-tmux-navigation")

            nav.setup({
                keybindings = {
                    left = "<C-h>",
                    down = "<C-j>",
                    up = "<C-k>",
                    right = "<C-l>",
                    last_active = "<C-\\>",
                    next = "<C-Space>",
                },
            })
        end,
    },
}
