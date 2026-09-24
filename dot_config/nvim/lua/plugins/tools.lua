return {
    {
        "nvim-telescope/telescope.nvim",
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
                -- 檔名在前、目錄在後；reverse_directories 讓最貼近檔案的目錄先出現，
                -- 深層專案即使被寬度截斷，保留的仍是最有辨識度的那一段。
                path_display = { filename_first = { reverse_directories = true } },
                -- preview 視窗標題跟著選取項目顯示完整路徑。
                dynamic_preview_title = true,
                file_ignore_patterns = { "node_modules", ".git/" },
                -- <M-f> / <M-k> 是 Telescope 預設的 results 水平捲動，但 Alt 組合被 GlazeWM 攔走，
                -- 所以改綁 <C-h> / <C-l>；<C-l> 原本的 complete_tag 移到 <C-y>。
                -- 用 closure 包住 require，避免啟動期就載入 telescope.actions。
                mappings = {
                    i = {
                        ["<C-v>"] = function()
                            local keys = vim.api.nvim_replace_termcodes("<C-r>+", true, false, true)
                            vim.api.nvim_feedkeys(keys, "n", false)
                        end,
                        ["<C-h>"] = function(bufnr)
                            require("telescope.actions").results_scrolling_left(bufnr)
                        end,
                        ["<C-l>"] = function(bufnr)
                            require("telescope.actions").results_scrolling_right(bufnr)
                        end,
                        ["<C-y>"] = function(bufnr)
                            require("telescope.actions").complete_tag(bufnr)
                        end,
                    },
                    n = {
                        ["<C-h>"] = function(bufnr)
                            require("telescope.actions").results_scrolling_left(bufnr)
                        end,
                        ["<C-l>"] = function(bufnr)
                            require("telescope.actions").results_scrolling_right(bufnr)
                        end,
                    },
                },
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
                    preview_cutoff = 0,
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
        -- Telescope 的 builtin picker 預設就用 cwd，搭配 vim.g.root_spec = { "cwd" }
        -- （見 lua/config/options.lua）即可保證不會搜到父層專案根目錄。
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "搜尋檔案（工作目錄）" },
            { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "全文搜尋（工作目錄）" },
            { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "搜尋 Buffer" },
            { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "搜尋說明文件" },
            { "<leader>fr", "<cmd>Telescope oldfiles cwd_only=true<CR>", desc = "最近開啟檔案（工作目錄）" },
            { "<leader>fR", "<cmd>Telescope oldfiles<CR>", desc = "最近開啟檔案（全域）" },
            { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "搜尋游標文字（工作目錄）" },
            { "<leader>fp", "<cmd>Telescope projects<CR>", desc = "切換專案" },
        },
    },

    -- 浮動終端機（Lazygit 請用 LazyVim 內建的 \gg）
    {
        "voldikss/vim-floaterm",
        cmd = { "FloatermNew", "FloatermToggle", "FloatermPrev", "FloatermNext", "FloatermKill", "FloatermHide" },
        config = function()
            vim.api.nvim_create_user_command("FloatermToggleLayout", function()
                if vim.bo.filetype ~= "floaterm" then
                    vim.notify("目前不在 Floaterm 中", vim.log.levels.WARN)
                    return
                end
                if vim.b.floaterm_wintype == "float" then
                    vim.cmd("FloatermUpdate --wintype=vsplit --position=botright --width=0.45")
                else
                    vim.cmd("FloatermUpdate --wintype=float --position=center --width=0.95 --height=0.95")
                end
            end, { desc = "切換 Floaterm 浮動／右側分割佈局" })
        end,
        keys = {
            { "<leader>tc", "<cmd>FloatermNew --height=0.95 --width=0.95<CR>", desc = "新增終端機" },
            { "<leader>tt", "<cmd>FloatermToggle<CR>", desc = "切換終端機" },
            { "<leader>tp", "<cmd>FloatermPrev<CR>", desc = "上一個終端機" },
            { "<leader>tn", "<cmd>FloatermNext<CR>", desc = "下一個終端機" },
            { "<leader>tq", "<cmd>FloatermKill<CR>", desc = "關閉終端機" },
            { "<leader>th", "<cmd>FloatermHide<CR>", desc = "隱藏終端機" },
            { "<leader>ts", "<cmd>FloatermToggleLayout<CR>", desc = "切換浮動／右側分割" },
            { "<leader>ts", "<C-\\><C-n><cmd>FloatermToggleLayout<CR>", mode = "t", desc = "切換浮動／右側分割" },
        },
    },

    {
        "mikavilpas/yazi.nvim",
        event = "VeryLazy",
        dependencies = {
            { "nvim-lua/plenary.nvim", lazy = true },
        },
        keys = {
            { "<leader>ty", "<cmd>Yazi<cr>", mode = { "n", "x" }, desc = "開啟 Yazi（當前檔案）" },
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

    -- 單檔程式碼快速執行（支援 dotnet / typescript / python / go 等）
    {
        "GustavEikaas/code-playground.nvim",
        cmd = "Code",
        opts = {
            split_direction = "vsplit",
            auto_change_cwd = false,
            animation = "wave",
        },
    },
}
