-- plugins/ui-restructured.lua
-- UI 相關插件，只在 Neovim 中使用

return {
    -- 主題設定 (只在 Neovim 中使用)
    -- 主題：rose-pine-moon (透明背景)；備用：tokyonight / catppuccin
    {
        "rose-pine/neovim",
        name = "rose-pine",
        lazy = false,
        priority = 1000,
        cond = not vim.g.vscode,
        opts = {
            variant = "moon",
            dark_variant = "moon",
            styles = {
                italic = true,
                transparency = true, -- 透明背景
            },
        },
        config = function(_, opts)
            require("rose-pine").setup(opts)
            local ok = pcall(vim.cmd, "colorscheme rose-pine-moon")
            if not ok then
                vim.notify("rose-pine 載入失敗，切換至 tokyonight", vim.log.levels.WARN)
                vim.cmd("colorscheme tokyonight-night")
            end

            vim.api.nvim_set_hl(0, "@keyword.tsx", { fg = "#6C95EB" })
            vim.api.nvim_set_hl(0, "@keyword.conditional.tsx", { fg = "#6C95EB" })
            vim.api.nvim_set_hl(0, "@keyword.return.tsx", { fg = "#6C95EB" })
            vim.api.nvim_set_hl(0, "@keyword", { fg = "#6C95EB" })
            vim.api.nvim_set_hl(0, "@keyword.conditional", { fg = "#6C95EB" })
            vim.api.nvim_set_hl(0, "@keyword.return", { fg = "#6C95EB" })
            vim.api.nvim_set_hl(0, "@keyword.import", { fg = "#6C95EB" })
            vim.api.nvim_set_hl(0, "@lsp.typemod.function.declaration.typescript", { fg = "#fefefe" })
            vim.api.nvim_set_hl(0, "@lsp.type.function.typescript", { fg = "#39cc9b" })
            vim.api.nvim_set_hl(0, "@function.call.tsx", { fg = "#39cc9b" })
            vim.api.nvim_set_hl(0, "@lsp.type.function.typescriptreact", { fg = "#39cc9b" })
            vim.api.nvim_set_hl(0, "@tag.attribute.tsx", { fg = "#6c95eb" })
            vim.api.nvim_set_hl(0, "@tag.tsx", { fg = "#4EC9B0" })
            vim.api.nvim_set_hl(0, "@tag.builtin.tsx", { fg = "#4EC9B0" })
            vim.api.nvim_set_hl(0, "@comment", { fg = "#85ba59", italic = true })
        end,
    },
    -- tokyonight 備用主題 (可用 :colorscheme tokyonight-night 切換)
    {
        "folke/tokyonight.nvim",
        lazy = true,
        cond = not vim.g.vscode,
        opts = {
            style = "night",
            transparent = false,
            terminal_colors = true,
            styles = {
                comments = { italic = true },
                keywords = { italic = true },
                functions = {},
                variables = {},
            },
        },
        config = function(_, opts)
            require("tokyonight").setup(opts)
        end,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true, -- 作為 fallback，不主動套用
        priority = 900,
        cond = not vim.g.vscode,
    },
    {
        "folke/noice.nvim",
        opts = {
            presets = {
                lsp_doc_border = true,
            },
        },
    },

    -- Neo-tree 檔案管理器 (只在 Neovim 中使用)
    {
        "nvim-neo-tree/neo-tree.nvim",
        enabled = false, -- 已停用，改用 Snacks Explorer（<leader>e / <leader>E）
        cmd = { "Neotree" },
        cond = not vim.g.vscode,
        keys = {
            { "<leader>oe", "<cmd>Neotree toggle<cr>", desc = "切換 Neo-tree" },
            { "<leader>oE", "<cmd>Neotree reveal<cr>", desc = "Neo-tree 顯示目前檔案" },
        },
        config = function()
            require("neo-tree").setup({
                close_if_last_window = true,
                popup_border_style = "rounded",
                enable_git_status = true,
                enable_diagnostics = true,
                open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
                sort_case_insensitive = false,

                default_component_configs = {
                    container = { enable_character_fade = true },
                    indent = {
                        indent_size = 2,
                        padding = 1,
                        with_markers = true,
                        indent_marker = "│",
                        last_indent_marker = "└",
                        highlight = "NeoTreeIndentMarker",
                        with_expanders = nil,
                        expander_collapsed = "",
                        expander_expanded = "",
                        expander_highlight = "NeoTreeExpander",
                    },
                    icon = {
                        folder_closed = "",
                        folder_open = "",
                        folder_empty = "ﰊ",
                        folder_empty_open = "",
                        default = "*",
                        highlight = "NeoTreeFileIcon",
                    },
                    modified = { symbol = "[+]", highlight = "NeoTreeModified" },
                    name = {
                        trailing_slash = false,
                        use_git_status_colors = true,
                        highlight = "NeoTreeFileName",
                    },
                    git_status = {
                        symbols = {
                            added = "",
                            modified = "",
                            deleted = "✖",
                            renamed = "",
                            untracked = "",
                            ignored = "",
                            unstaged = "",
                            staged = "",
                            conflict = "",
                        },
                    },
                },

                window = {
                    position = "left",
                    width = 25,
                    mapping_options = { noremap = true, nowait = true },
                },

                filesystem = {
                    filtered_items = {
                        visible = false,
                        hide_dotfiles = false,
                        hide_gitignored = true,
                        hide_hidden = true,
                        hide_by_name = { "node_modules" },
                        hide_by_pattern = {},
                        always_show = {},
                        never_show = {},
                        never_show_by_pattern = {},
                    },
                    follow_current_file = { enabled = true },
                    group_empty_dirs = false,
                    hijack_netrw_behavior = "open_default",
                    use_libuv_file_watcher = false,

                    window = {
                        mappings = {
                            ["<bs>"] = "navigate_up",
                            ["."] = "set_root",
                            ["H"] = "toggle_hidden",
                            ["/"] = "fuzzy_finder",
                            ["D"] = "fuzzy_finder_directory",
                            ["#"] = "fuzzy_sorter",
                            ["f"] = "filter_on_submit",
                            ["<c-x>"] = "clear_filter",
                            ["[g"] = "prev_git_modified",
                            ["]g"] = "next_git_modified",
                        },
                    },
                },

                buffers = {
                    follow_current_file = { enabled = true },
                    group_empty_dirs = true,
                    show_unloaded = true,
                    window = {
                        mappings = {
                            ["bd"] = "buffer_delete",
                            ["<bs>"] = "navigate_up",
                            ["."] = "set_root",
                        },
                    },
                },

                git_status = {
                    window = {
                        position = "float",
                        mappings = {
                            ["A"] = "git_add_all",
                            ["gu"] = "git_unstage_file",
                            ["ga"] = "git_add_file",
                            ["gr"] = "git_revert_file",
                            ["gc"] = "git_commit",
                            ["gp"] = "git_push",
                            ["gg"] = "git_commit_and_push",
                        },
                    },
                },
            })
        end,
    },

    -- Snacks Dashboard 與 Explorer
    {
        "folke/snacks.nvim",
        cond = not vim.g.vscode,
        opts = function(_, opts)
            opts.dashboard = opts.dashboard or {}
            opts.dashboard.preset = opts.dashboard.preset or {}
            opts.dashboard.preset.header = [[
███████╗██████╗ ███████╗███╗   ███╗██╗██╗      ██████╗ ██████╗ ██╗  ██╗███████╗ █████╗
██╔════╝██╔══██╗██╔════╝████╗ ████║██║██║     ██╔═══██╗██╔══██╗██║  ██║██╔════╝██╔══██╗
█████╗  ██║  ██║█████╗  ██╔████╔██║██║██║     ██║   ██║██████╔╝███████║█████╗  ███████║
██╔══╝  ██║  ██║██╔══╝  ██║╚██╔╝██║██║██║     ██║   ██║██╔══██╗██╔══██║██╔══╝  ██╔══██║
███████╗██████╔╝███████╗██║ ╚═╝ ██║██║███████╗╚██████╔╝██║  ██║██║  ██║███████╗██║  ██║
╚══════╝╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝]]

            opts.explorer = opts.explorer or {}

            -- Snacks Explorer（左側常駐側邊欄）
            -- preview = "main"：游標移動時在主編輯區即時預覽，類似 yazi 的右側預覽欄。
            --   想改成側邊欄內的小預覽框改成 preview = true；執行中按 P 可隨時切換。
            -- 寬度用 <C-Left> / <C-Right> 調整，= 還原成預設值，調整後的寬度會記住到本次 Neovim 結束。
            local explorer_width_default = 40
            local explorer_width = explorer_width_default

            local function set_explorer_width(picker, width)
                local root = picker.layout and picker.layout.root
                if not (root and root.win and vim.api.nvim_win_is_valid(root.win)) then
                    return
                end
                -- 夾在 20 欄與「螢幕寬度 - 20 欄」之間，避免縮到看不見或吃掉整個編輯區
                explorer_width = math.max(20, math.min(width, math.max(20, vim.o.columns - 20)))
                vim.api.nvim_win_set_width(root.win, explorer_width)
                picker.layout:update()
            end

            ---@param delta number? 正數變寬、負數變窄；傳 nil 代表還原預設寬度
            local function resize_explorer(delta)
                return function(picker)
                    local root = picker.layout and picker.layout.root
                    if not (root and root.win and vim.api.nvim_win_is_valid(root.win)) then
                        return
                    end
                    set_explorer_width(
                        picker,
                        delta and (vim.api.nvim_win_get_width(root.win) + delta) or explorer_width_default
                    )
                end
            end

            opts.picker = opts.picker or {}
            opts.picker.sources = opts.picker.sources or {}
            opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
                layout = { preset = "sidebar", preview = "main" },
                -- 重新開啟 explorer 時沿用上次調整過的寬度
                on_show = function(picker)
                    vim.schedule(function()
                        set_explorer_width(picker, explorer_width)
                    end)
                end,
                win = {
                    list = {
                        keys = {
                            ["<C-Right>"] = "explorer_width_inc",
                            ["<C-Left>"] = "explorer_width_dec",
                            ["="] = "explorer_width_reset",
                        },
                    },
                },
                actions = {
                    explorer_width_inc = resize_explorer(5),
                    explorer_width_dec = resize_explorer(-5),
                    explorer_width_reset = resize_explorer(nil),
                },
            })

            -- 彩虹縮排:每層縮排線不同色
            opts.indent = opts.indent or {}
            opts.indent.indent = vim.tbl_deep_extend("force", opts.indent.indent or {}, {
                char = "│",
                hl = {
                    "SnacksIndent1",
                    "SnacksIndent2",
                    "SnacksIndent3",
                    "SnacksIndent4",
                    "SnacksIndent5",
                    "SnacksIndent6",
                },
            })
            opts.indent.scope = vim.tbl_deep_extend("force", opts.indent.scope or {}, { char = "│" })
        end,
        -- 不再自訂 <leader>e / <leader>E。
        -- LazyVim 的 snacks_explorer extra 已提供 \fe（root）與 \fE（cwd），
        -- 且 \e / \E 會 remap 過去；搭配 vim.g.root_spec = { "cwd" } 兩者都等於目前工作目錄。
    },

    -- Trouble 診斷視窗 (只在 Neovim 中使用)
    {
        "folke/trouble.nvim",
        optional = true,
        cond = not vim.g.vscode,
        opts = {
            auto_close = true,
            auto_open = false,
            use_diagnostic_signs = true,
        },
        keys = {
            { "<leader>xx", false },
        },
    },

    -- Bufferline 標籤列 (只在 Neovim 中使用)
    {
        "akinsho/bufferline.nvim",
        optional = true,
        cond = not vim.g.vscode,
        opts = {
            options = {
                mode = "buffers",
                numbers = "ordinal", -- tab 顯示視覺序號 1,2,3…（搭配 \1~\9 快跳）
                sort_by = "insert_at_end", -- 新 buffer 加在最後、保留手動排序（同 VSCode 規則）
                diagnostics = "nvim_lsp",
                separator_style = "slant",
                show_buffer_close_icons = true,
                show_close_icon = false,
                always_show_bufferline = true,
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "File Explorer",
                        highlight = "Directory",
                        separator = true,
                    },
                },
            },
        },
    },

    -- Lualine 狀態列 (只在 Neovim 中使用)
    {
        "nvim-lualine/lualine.nvim",
        optional = true,
        cond = not vim.g.vscode,
        opts = {
            options = {
                theme = "auto",
                section_separators = { left = "", right = "" },
                component_separators = { left = "", right = "" },
                globalstatus = true,
            },
        },
    },
}
