-- plugins/markdown-enhanced.lua
-- 完整的 Markdown 生態系統插件

-- 安全檢查函數
local function check_obsidian_vault()
    local vault_path = vim.fn.expand("~/Documents/Obsidian_Note")
    if vim.fn.isdirectory(vault_path) == 1 and vim.fn.isdirectory(vault_path .. "/.obsidian") == 1 then
        return true, vault_path
    end
    return false, nil
end

local function check_deno()
    return vim.fn.executable("deno") == 1
end

local vault_exists, vault_path = check_obsidian_vault()
local deno_exists = check_deno()

return {
    -- Markdown 渲染增強 (只在 Neovim 中使用)
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        ft = { "markdown" },
        cond = not vim.g.vscode,
        opts = {
            enabled = true,
            debounce = 150,
            max_file_size = 5.0,

            heading = {
                enabled = true,
                sign = true,
                position = "overlay",
                icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
                signs = { "󰫎 " },
                width = "full",
                backgrounds = {
                    "RenderMarkdownH1Bg",
                    "RenderMarkdownH2Bg",
                    "RenderMarkdownH3Bg",
                    "RenderMarkdownH4Bg",
                    "RenderMarkdownH5Bg",
                    "RenderMarkdownH6Bg",
                },
                foregrounds = {
                    "RenderMarkdownH1",
                    "RenderMarkdownH2",
                    "RenderMarkdownH3",
                    "RenderMarkdownH4",
                    "RenderMarkdownH5",
                    "RenderMarkdownH6",
                },
            },

            code = {
                enabled = true,
                sign = true,
                style = "full",
                position = "left",
                language_pad = 2,
                width = "full",
                pad = 3,
                border = "thick",
                above = "▀",
                below = "▄",
                highlight_border = "RenderMarkdownCodeBorder",
                highlight = "RenderMarkdownCode",
                highlight_inline = "RenderMarkdownCodeInlineBg",
            },

            bullet = {
                enabled = true,
                icons = { "◉", "○", "✸", "✿" },
                left_pad = 0,
                right_pad = 1,
                highlight = "RenderMarkdownBullet",
            },

            checkbox = {
                enabled = true,
                unchecked = { icon = "⬜", highlight = "RenderMarkdownUnchecked" },
                checked = { icon = "✅", highlight = "RenderMarkdownChecked" },
                custom = {
                    todo = { raw = "[-]", rendered = "⏳ ", highlight = "RenderMarkdownTodo" },
                    important = { raw = "[!]", rendered = "❗ ", highlight = "RenderMarkdownImportant" },
                    question = { raw = "[?]", rendered = "❓ ", highlight = "RenderMarkdownQuestion" },
                    progress = { raw = "[/]", rendered = "🔄 ", highlight = "RenderMarkdownProgress" },
                    cancelled = { raw = "[~]", rendered = "❌ ", highlight = "RenderMarkdownCancelled" },
                    star = { raw = "[*]", rendered = "⭐ ", highlight = "RenderMarkdownStar" },
                },
                right_pad = 1,
            },

            quote = {
                enabled = true,
                icon = "┃",
                repeat_linebreak = false,
                highlight = "RenderMarkdownQuote",
            },

            pipe_table = {
                enabled = true,
                preset = "round",
                style = "full",
                cell = "padded",
                border = { "╭", "┬", "╮", "├", "┼", "┤", "╰", "┴", "╯", "│", "─" },
                alignment_indicator = "━",
                head = "RenderMarkdownTableHead",
                row = "RenderMarkdownTableRow",
                filler = "RenderMarkdownTableFill",
            },

            link = {
                enabled = true,
                image = "🖼️ ",
                email = "📧 ",
                hyperlink = "🔗 ",
                highlight = "RenderMarkdownLink",
                custom = {
                    web = { pattern = "^http", icon = "🌐 ", highlight = "RenderMarkdownLink" },
                    github = { pattern = "github%.com", icon = "🐙 ", highlight = "RenderMarkdownLink" },
                    youtube = { pattern = "youtube%.com", icon = "📺 ", highlight = "RenderMarkdownLink" },
                    wiki = { pattern = "%[%[.*%]%]", icon = "📝 ", highlight = "RenderMarkdownWikiLink" },
                    obsidian = { pattern = "obsidian://", icon = "🔮 ", highlight = "RenderMarkdownLink" },
                    pdf = { pattern = "%.pdf$", icon = "📄 ", highlight = "RenderMarkdownLink" },
                    markdown = { pattern = "%.md$", icon = "📋 ", highlight = "RenderMarkdownLink" },
                },
            },

            callout = {
                note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
                tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
                important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
                warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
                caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
            },

            win_options = {
                conceallevel = { default = vim.o.conceallevel, rendered = 3 },
                concealcursor = { default = vim.o.concealcursor, rendered = "" },
            },
        },
    },

    -- Obsidian 整合 (只在檢測到 vault 時啟用)
    {
        "epwalsh/obsidian.nvim",
        version = "*",
        enabled = vault_exists,
        cond = function()
            return vault_exists and not vim.g.vscode
        end,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "hrsh7th/nvim-cmp",
            "nvim-telescope/telescope.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        opts = function()
            if not vault_exists then
                return {}
            end

            return {
                workspaces = {
                    { name = "main", path = vault_path },
                },
                notes_subdir = "notes",
                new_notes_location = "notes_subdir",
                daily_notes = {
                    folder = "dailies",
                    date_format = "%Y-%m-%d",
                    alias_format = "%B %-d, %Y",
                    default_tags = { "daily-notes" },
                },
                completion = {
                    nvim_cmp = true,
                    min_chars = 2,
                },
                note_id_func = function(title)
                    local suffix = ""
                    if title ~= nil then
                        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
                    else
                        for _ = 1, 4 do
                            suffix = suffix .. string.char(math.random(65, 90))
                        end
                    end
                    return tostring(os.time()) .. "-" .. suffix
                end,
                ui = { enable = false },
                mappings = {
                    ["gf"] = {
                        action = function()
                            return require("obsidian").util.gf_passthrough()
                        end,
                        opts = { buffer = true, expr = true, noremap = true },
                    },
                    ["<leader>ch"] = {
                        action = function()
                            require("obsidian").util.toggle_checkbox()
                        end,
                        opts = { buffer = true, noremap = true },
                    },
                    ["<CR>"] = {
                        action = function()
                            return require("obsidian").util.smart_action()
                        end,
                        opts = { buffer = true, expr = true, noremap = true },
                    },
                },
                callbacks = {
                    post_setup = function()
                        print("Obsidian.nvim 已載入")
                    end,
                    post_set_workspace = function(client, workspace)
                        print("切換到工作區: " .. workspace.name)
                    end,
                },
            }
        end,
    },

    -- Markdown 預覽插件 (使用系統瀏覽器，適合有防火牆限制的環境)
    {
        "iamcco/markdown-preview.nvim",
        ft = "markdown",
        cond = not vim.g.vscode,
        build = "cd app && npm install",
        config = function()
            -- 基本設定
            vim.g.mkdp_auto_start = 0
            vim.g.mkdp_auto_close = 1
            vim.g.mkdp_browser = ""
            vim.g.mkdp_echo_preview_url = 1
            vim.g.mkdp_theme = "dark"
            vim.g.mkdp_port = "8080"
            vim.g.mkdp_page_title = "「${name}」"
            vim.g.mkdp_open_to_the_world = 0

            -- CSS 檔案路徑 (確保檔案存在)
            local css_dir = vim.fn.expand("~/dotfiles/nvim/lua/customfile")
            local markdown_css = css_dir .. "github-markdown-dark.min.css"
            local highlight_css = css_dir .. "tomorrow-night-eighties.css"

            -- 檢查檔案是否存在，如果存在則使用自訂 CSS
            if vim.fn.filereadable(markdown_css) == 1 then
                vim.g.mkdp_markdown_css = markdown_css
            else
                vim.g.mkdp_markdown_css = "" -- 使用預設
                vim.notify("自訂 Markdown CSS 檔案不存在: " .. markdown_css, vim.log.levels.WARN)
            end

            if vim.fn.filereadable(highlight_css) == 1 then
                vim.g.mkdp_highlight_css = highlight_css
            else
                vim.g.mkdp_highlight_css = "" -- 使用預設
                vim.notify("自訂 Highlight CSS 檔案不存在: " .. highlight_css, vim.log.levels.WARN)
            end

            -- 預覽選項
            vim.g.mkdp_preview_options = {
                mkit = {},
                katex = {},
                uml = {},
                maid = {},
                disable_sync_scroll = 0,
                sync_scroll_type = "middle",
                hide_yaml_meta = 1,
                sequence_diagrams = {},
                flowchart_diagrams = {},
                content_editable = false,
                disable_filename = 0,
                toc = {},
            }

            -- 創建主題切換指令
            vim.api.nvim_create_user_command("MarkdownThemeDark", function()
                vim.g.mkdp_theme = "dark"
                vim.notify("Markdown Preview 主題已切換為：Dark", vim.log.levels.INFO)
            end, { desc = "切換到深色主題" })

            vim.api.nvim_create_user_command("MarkdownThemeLight", function()
                vim.g.mkdp_theme = "light"
                vim.notify("Markdown Preview 主題已切換為：Light", vim.log.levels.INFO)
            end, { desc = "切換到淺色主題" })

            -- 切換自訂 CSS 主題的指令
            vim.api.nvim_create_user_command("MarkdownThemeCustom", function()
                if vim.fn.filereadable(markdown_css) == 1 then
                    vim.g.mkdp_markdown_css = markdown_css
                    vim.g.mkdp_highlight_css = highlight_css
                    vim.notify("已啟用自訂 CSS 主題", vim.log.levels.INFO)
                else
                    vim.notify("自訂 CSS 檔案不存在，請先下載到: " .. css_dir, vim.log.levels.ERROR)
                end
            end, { desc = "啟用自訂 CSS 主題" })

            vim.api.nvim_create_user_command("MarkdownThemeDefault", function()
                vim.g.mkdp_markdown_css = ""
                vim.g.mkdp_highlight_css = ""
                vim.notify("已重置為預設主題", vim.log.levels.INFO)
            end, { desc = "重置為預設主題" })

            -- 建立 CSS 目錄的指令
            vim.api.nvim_create_user_command("MarkdownSetupCSS", function()
                vim.fn.system("mkdir -p " .. css_dir)
                vim.notify("CSS 目錄已建立: " .. css_dir, vim.log.levels.INFO)
                vim.notify("請手動下載 CSS 檔案到此目錄", vim.log.levels.INFO)
            end, { desc = "建立 CSS 目錄" })
        end,
        keys = {
            { "<leader>mpp", "<cmd>MarkdownPreview<cr>", desc = "Markdown Preview" },
            { "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", desc = "Stop Preview" },
            { "<leader>mt", "<cmd>MarkdownPreviewToggle<cr>", desc = "Toggle Preview" },
            -- 主題切換快捷鍵
            { "<leader>mtd", "<cmd>MarkdownThemeDark<cr>", desc = "Dark Theme" },
            { "<leader>mtl", "<cmd>MarkdownThemeLight<cr>", desc = "Light Theme" },
            { "<leader>mtc", "<cmd>MarkdownThemeCustom<cr>", desc = "Custom CSS Theme" },
            { "<leader>mtr", "<cmd>MarkdownThemeDefault<cr>", desc = "Reset Theme" },
        },
    },

    -- Peek 瀏覽器預覽 (需要 deno)
    {
        "toppair/peek.nvim",
        enabled = deno_exists,
        cond = function()
            return deno_exists and not vim.g.vscode
        end,
        build = deno_exists and "deno task --quiet build:fast" or nil,
        cmd = { "PeekOpen", "PeekClose" },
        ft = "markdown",
        config = function()
            require("peek").setup({
                auto_load = false, -- 改為手動啟動，避免自動檢查衝突
                close_on_bdelete = true,
                syntax = true,
                theme = "dark",
                update_on_change = true,
                app = "webview",
                filetype = { "markdown", "md" }, -- 加上 md 副檔名支援
                throttle_at = 200000,
                throttle_time = "auto",
            })

            -- 手動註冊指令
            vim.api.nvim_create_user_command("PeekOpen", function()
                local filetype = vim.bo.filetype
                if filetype == "markdown" then
                    require("peek").open()
                else
                    vim.notify(
                        "PeekOpen: 只支援 markdown 檔案，當前檔案類型: " .. filetype,
                        vim.log.levels.WARN
                    )
                end
            end, {})

            vim.api.nvim_create_user_command("PeekClose", function()
                require("peek").close()
            end, {})
        end,
        keys = {
            { "<leader>mpo", "<cmd>PeekOpen<cr>", desc = "Peek Open" },
            { "<leader>mpc", "<cmd>PeekClose<cr>", desc = "Peek Close" },
        },
    },

    -- 圖片貼上工具
    {
        "HakonHarnes/img-clip.nvim",
        ft = "markdown",
        cond = not vim.g.vscode,
        opts = {
            default = {
                dir_path = "assets",
                extension = "png",
                file_name = function()
                    local input = vim.fn.input("Image file name (no extension, leave blank for timestamp): ")
                    return input ~= "" and input or os.date("%Y%m%d-%H%M%S")
                end,
                use_absolute_path = false,
                relative_to_current_file = true,
                template = "![$CURSOR]($FILE_PATH)",
                url_encode_path = true,
                relative_template_path = true,
                use_cursor_in_template = true,
                insert_mode_after_paste = true,
                prompt_for_file_name = false,
                drag_and_drop = { enabled = true, insert_mode = false },
            },
            filetypes = {
                markdown = {
                    template = "![$CURSOR]($FILE_PATH)",
                    url_encode_path = true,
                    download_images = false,
                },
            },
        },
    },
}
