-- \1 ~ \9：跳到完整清單中「實際順序第 N 個」buffer。
-- go_to(i, true) 使用 absolute 實際位置，不受畫面截斷或捲動影響。
local bufferline_keys = {
    -- H / L 保留給行首 / 行尾（core/keymaps.lua），不讓 bufferline 載入時改回切換 buffer
    { "<S-h>", false },
    { "<S-l>", false },
    { "<leader>bc", "<cmd>BufferLinePickClose<cr>", desc = "選擇關閉 Buffer" },
    -- 移動 buffer 在 bufferline 上的順序（影響 [b / ]b 的切換順序）
    { "<leader>b.", "<cmd>BufferLineMoveNext<cr>", desc = "Buffer 右移" },
    { "<leader>b,", "<cmd>BufferLineMovePrev<cr>", desc = "Buffer 左移" },
}
for i = 1, 9 do
    table.insert(bufferline_keys, {
        "<leader>" .. i,
        function()
            require("bufferline").go_to(i, true)
        end,
        desc = "跳到 Buffer " .. i,
    })
end

return {
    -- 主題：rose-pine-moon（透明背景）；備用：tokyonight / catppuccin。
    -- 語法上色覆寫在 lua/config/highlights.lua 的 ColorScheme 掛鉤。
    {
        "rose-pine/neovim",
        name = "rose-pine",
        lazy = false,
        priority = 1000,
        opts = {
            variant = "moon",
            dark_variant = "moon",
            styles = {
                italic = true,
                transparency = true,
            },
        },
        config = function(_, opts)
            require("rose-pine").setup(opts)
            local ok = pcall(vim.cmd.colorscheme, "rose-pine-moon")
            if not ok then
                vim.notify("rose-pine 載入失敗，切換至 tokyonight", vim.log.levels.WARN)
                vim.cmd.colorscheme("tokyonight-night")
            end
        end,
    },
    {
        "folke/tokyonight.nvim",
        lazy = true,
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
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        priority = 900,
    },

    {
        "folke/noice.nvim",
        opts = {
            presets = {
                lsp_doc_border = true,
            },
        },
    },

    -- Snacks：Dashboard、Explorer 側邊欄、彩虹縮排
    {
        "folke/snacks.nvim",
        -- \sc 改為清除搜尋高亮（core/keymaps.lua），指令歷史仍可用 \:
        keys = { { "<leader>sc", false } },
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

            -- 移除 util.project extra 在 Dashboard 插入的重複 Projects 按鈕
            local keys = opts.dashboard.preset.keys
            if keys then
                for i, key in ipairs(keys) do
                    if type(key) == "table" and key.desc and key.desc:find("util%.project") then
                        table.remove(keys, i)
                        break
                    end
                end
            end

            -- 檔案總管改用 Neo-tree（lazyvim.json 的 editor.neo-tree extra），Snacks Explorer 不再載入。

            -- 彩虹縮排：每層縮排線不同色（顏色在 lua/config/highlights.lua）
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

            -- 同名參照標示（document_highlight）：關閉。每次游標停下都向 LSP 發請求，
            -- 在大型 C# 檔案上占游標移動成本的 75%。
            opts.words = opts.words or {}
            opts.words.enabled = false
        end,
    },

    -- \xx 改為本行診斷浮窗（config/keymaps.lua）；Trouble 清單用 \xX \xL \xQ
    {
        "folke/trouble.nvim",
        optional = true,
        opts = {
            auto_close = true,
            auto_open = false,
            use_diagnostic_signs = true,
        },
        keys = {
            { "<leader>xx", false },
        },
    },

    {
        "akinsho/bufferline.nvim",
        optional = true,
        keys = bufferline_keys,
        opts = {
            options = {
                mode = "buffers",
                numbers = "ordinal", -- 顯示視覺序號，搭配 \1 ~ \9 快跳
                sort_by = "insert_at_end", -- 新 buffer 加在最後、保留手動排序
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

    {
        "nvim-lualine/lualine.nvim",
        optional = true,
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
