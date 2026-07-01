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
        dependencies = {
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                enabled = vim.fn.executable("make") == 1,
            },
        },
        opts = {
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
        },
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "搜尋檔案" },
            { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "全文搜尋" },
            { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "搜尋 Buffer" },
            { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "搜尋說明文件" },
            { "<leader>fr", "<cmd>Telescope oldfiles cwd_only=true<CR>", desc = "最近開啟檔案（專案內）" },
            { "<leader>fR", "<cmd>Telescope oldfiles<CR>", desc = "最近開啟檔案（全域）" },
            { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "搜尋游標文字" },
            { "<leader>fp", "<cmd>Telescope projects<CR>", desc = "切換專案" },
        },
    },
    {
        -- Float term（改為按鍵/命令觸發的 lazy load，加速啟動）
        "voldikss/vim-floaterm",
        cmd = { "FloatermNew", "FloatermToggle", "FloatermPrev", "FloatermNext", "FloatermKill", "FloatermHide" },
        keys = {
            { "<leader>tc", ":FloatermNew --height=0.95 --width=0.95<CR>", desc = "新增終端機" },
            { "<leader>tt", ":FloatermToggle<CR>", desc = "切換終端機" },
            { "<leader>tp", ":FloatermPrev<CR>", desc = "上一個終端機" },
            { "<leader>tn", ":FloatermNext<CR>", desc = "下一個終端機" },
            { "<leader>tg", ":FloatermNew --height=0.95 --width=0.95 lazygit<CR>", desc = "開啟 Lazygit" },
            { "<leader>tq", ":FloatermKill<CR>", desc = "關閉終端機" },
            { "<leader>th", ":FloatermHide<CR>", desc = "隱藏終端機" },
        },
    },
    {
        "mikavilpas/yazi.nvim",
        event = "VeryLazy",
        dependencies = {
            { "nvim-lua/plenary.nvim", lazy = true },
        },
        keys = {
            { "<leader>ty", "<cmd>Yazi<cr>", mode = { "n", "v" }, desc = "開啟 Yazi（當前檔案）" },
            { "<leader>tw", "<cmd>Yazi cwd<cr>", desc = "開啟 Yazi（工作目錄）" },
            { "<C-Up>", "<cmd>Yazi toggle<cr>", desc = "恢復上次 Yazi" },
        },
        opts = {
            open_for_directories = false,
            floating_window_scaling_factor = 0.95,
            yazi_floating_window_border = "rounded",
            keymaps = {
                show_help = "<f1>",
                open_file_in_vertical_split = "<c-v>",
                open_file_in_horizontal_split = "<c-x>",
                open_file_in_tab = "<c-t>",
                grep_in_directory = "<c-s>",
                cycle_open_buffers = "<tab>",
                copy_relative_path_to_selected_files = "<c-y>",
                send_to_quickfix_list = "<c-q>",
            },
            integrations = {
                grep_in_directory = "telescope",
            },
        },
    },
    {
        "natecraddock/workspaces.nvim",
        event = "VeryLazy",
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("workspaces").setup({
                cd_type = "global", -- 切換專案時全域 cd
                sort = true,
                mru_sort = true, -- 最近使用的排前面
                auto_open = false,
                hooks = {
                    open = { "Telescope find_files" }, -- 開啟專案後自動搜尋檔案
                },
            })
            require("telescope").load_extension("workspaces")
        end,
        keys = {
            { "<leader>fW", "<cmd>Telescope workspaces<CR>", desc = "切換工作區" },
            { "<leader>wa", ":WorkspacesAdd ", desc = "新增工作區" },
            { "<leader>wr", ":WorkspacesRemove ", desc = "移除工作區" },
            { "<leader>wl", "<cmd>WorkspacesList<CR>", desc = "列出工作區" },
        },
    },
    {
        "chentoast/marks.nvim",
        event = "VeryLazy",
        opts = {
            default_mappings = true, -- 保留原生 m + 字母 操作
            signs = true, -- sign column 顯示 marks
            mappings = {},
        },
    },
    -- {
    --     -- Tmux & neovim navigator（不使用：psmux 下 vim.fn.system() 開銷大會卡頓）
    --     -- pane 切換改用 tmux/psmux 自己的 prefix 指令
    --     "alexghergh/nvim-tmux-navigation",
    --     cond = function()
    --         return os.getenv("TMUX") ~= nil
    --     end,
    --     event = "VeryLazy",
    --     config = function()
    --         local nav = require("nvim-tmux-navigation")
    --         nav.setup({
    --             keybindings = {
    --                 left = "<C-h>",
    --                 down = "<C-j>",
    --                 up = "<C-k>",
    --                 right = "<C-l>",
    --                 last_active = "<C-\\>",
    --                 next = "<C-Space>",
    --             },
    --         })
    --     end,
    -- },
}
