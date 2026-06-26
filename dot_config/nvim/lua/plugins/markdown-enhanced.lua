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

            -- 停用 latex 渲染 (未安裝 latex parser / utftex，避免健檢警告)
            latex = { enabled = false },

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
                -- v8.x: pad 已移除，改用 left_pad / right_pad
                left_pad = 3,
                right_pad = 3,
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
                -- v8.12.0: filler 已移除，head/row 已涵蓋邊框/填充高亮
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
        vscode = false,
        ft = "markdown",
        enabled = vault_exists,
        cond = function()
            return vault_exists
        end,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        opts = function()
            if not vault_exists then
                return {}
            end

            return {
                -- 工作區設定
                workspaces = {
                    { name = "main", path = vault_path },
                },
                -- 筆記管理設定
                notes_subdir = "notes",
                new_notes_location = "notes_subdir",
                -- 日記設定
                daily_notes = {
                    folder = "dailies",
                    date_format = "%Y-%m-%d",
                    alias_format = "%B %-d, %Y",
                    default_tags = { "daily-notes" },
                    template = nil,
                },
                -- 自動完成設定
                completion = {
                    nvim_cmp = false,
                    min_chars = 2,
                },
                -- 筆記 ID 生成函數
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
                -- 筆記路徑生成函數
                note_path_func = function(spec)
                    local path = spec.dir / tostring(spec.id)
                    return path:with_suffix(".md")
                end,
                -- 自訂 Wiki 連結函數處理中文標題
                wiki_link_func = function(opts)
                    if opts.anchor then
                        local anchor = opts.anchor.anchor
                        if opts.path then
                            return string.format("[[%s#%s]]", opts.path, anchor)
                        else
                            return string.format("[[#%s]]", anchor)
                        end
                    end
                    if opts.label and opts.label ~= opts.path then
                        return string.format("[[%s|%s]]", opts.path or opts.id, opts.label)
                    else
                        return string.format("[[%s]]", opts.path or opts.id)
                    end
                end,
                markdown_link_func = function(opts)
                    return require("obsidian.util").markdown_link(opts)
                end,
                preferred_link_style = "markdown",
                -- 前置資料 (frontmatter) 設定
                disable_frontmatter = false,
                note_frontmatter_func = function(note)
                    if note.title then
                        note:add_alias(note.title)
                    end
                    local out = { id = note.id, aliases = note.aliases, tags = note.tags }
                    if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                        for k, v in pairs(note.metadata) do
                            out[k] = v
                        end
                    end
                    return out
                end,
                -- 模板設定
                templates = {
                    folder = "templates",
                    date_format = "%Y-%m-%d",
                    time_format = "%H:%M",
                    substitutions = {
                        yesterday = function()
                            return os.date("%Y-%m-%d", os.time() - 86400)
                        end,
                    },
                },
                -- 外部連結處理 (跨平台)
                follow_url_func = function(url)
                    local os_name = vim.loop.os_uname().sysname
                    if os_name == "Windows_NT" then
                        vim.cmd(':silent exec "!start ' .. url .. '"')
                    elseif os_name == "Darwin" then
                        vim.fn.jobstart({ "open", url })
                    else
                        vim.fn.jobstart({ "xdg-open", url })
                    end
                end,
                -- 圖片處理 (跨平台)
                follow_img_func = function(img)
                    local os_name = vim.loop.os_uname().sysname
                    if os_name == "Windows_NT" then
                        vim.cmd(':silent exec "!start ' .. img .. '"')
                    elseif os_name == "Darwin" then
                        vim.fn.jobstart({ "qlmanage", "-p", img })
                    else
                        vim.fn.jobstart({ "xdg-open", img })
                    end
                end,
                -- 選擇器設定
                picker = {
                    name = "telescope.nvim",
                    note_mappings = {
                        new = "<C-x>",
                        insert_link = "<C-l>",
                    },
                    tag_mappings = {
                        tag_note = "<C-x>",
                        insert_tag = "<C-l>",
                    },
                },
                -- 搜尋設定
                sort_by = "modified",
                sort_reversed = true,
                search_max_lines = 1000,
                open_notes_in = "current",
                -- 附件設定
                attachments = {
                    img_folder = "assets/imgs",
                    img_name_func = function()
                        return string.format("%s-", os.time())
                    end,
                    img_text_func = function(client, path)
                        path = client:vault_relative_path(path) or path
                        return string.format("![%s](%s)", path.name, path)
                    end,
                },
                -- 停用 UI 功能，使用 render-markdown.nvim
                ui = {
                    enable = false,
                    update_debounce = 50,
                    checkboxes = {
                        [" "] = { char = " ", hl_group = "Normal" },
                        ["x"] = { char = "x", hl_group = "Normal" },
                        [">"] = { char = ">", hl_group = "Normal" },
                        ["~"] = { char = "~", hl_group = "Normal" },
                        ["!"] = { char = "!", hl_group = "Normal" },
                        ["*"] = { char = "*", hl_group = "Normal" },
                        ["-"] = { char = "-", hl_group = "Normal" },
                        ["?"] = { char = "?", hl_group = "Normal" },
                        ["/"] = { char = "/", hl_group = "Normal" },
                    },
                },
                -- 按鍵對應
                mappings = {
                    ["gf"] = {
                        action = function()
                            return require("obsidian").util.gf_passthrough()
                        end,
                        opts = { buffer = true, expr = true, noremap = true, desc = "跟隨連結" },
                    },
                    ["<leader>ch"] = {
                        action = function()
                            require("obsidian").util.toggle_checkbox()
                        end,
                        opts = { buffer = true, noremap = true, desc = "切換複選框" },
                    },
                    ["<CR>"] = {
                        action = function()
                            return require("obsidian").util.smart_action()
                        end,
                        opts = { buffer = true, expr = true, noremap = true, desc = "智慧動作" },
                    },
                    -- TOC 功能
                    ["<leader>mt"] = {
                        action = function()
                            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                            local toc = { "<!-- TOC -->" }
                            for _, line in ipairs(lines) do
                                local level, title = line:match("^(#+)%s+(.+)")
                                if level and title then
                                    local indent = string.rep("    ", #level - 1)
                                    table.insert(toc, string.format("%s* [[#%s]]", indent, title))
                                end
                            end
                            table.insert(toc, "<!-- /TOC -->")
                            table.insert(toc, "")
                            local start_line, end_line = nil, nil
                            local current_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                            for i, line in ipairs(current_lines) do
                                if line:match("<!-- TOC -->") then
                                    start_line = i - 1
                                elseif line:match("<!-- /TOC -->") and start_line then
                                    end_line = i
                                    break
                                end
                            end
                            if start_line and end_line then
                                vim.api.nvim_buf_set_lines(0, start_line, end_line, false, toc)
                                print("TOC 已更新")
                            else
                                vim.api.nvim_buf_set_lines(0, 0, 0, false, toc)
                                print("TOC 已生成")
                            end
                        end,
                        opts = { buffer = true, noremap = true, desc = "生成 Wiki 格式 TOC" },
                    },
                    ["<leader>mT"] = {
                        action = function()
                            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                            local toc = { "<!-- TOC -->" }
                            for _, line in ipairs(lines) do
                                local level, title = line:match("^(#+)%s+(.+)")
                                if level and title then
                                    local indent = string.rep("  ", #level - 1)
                                    local anchor = title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
                                    table.insert(toc, string.format("%s- [%s](#%s)", indent, title, anchor))
                                end
                            end
                            table.insert(toc, "<!-- /TOC -->")
                            table.insert(toc, "")
                            local start_line, end_line = nil, nil
                            local current_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                            for i, line in ipairs(current_lines) do
                                if line:match("<!-- TOC -->") then
                                    start_line = i - 1
                                elseif line:match("<!-- /TOC -->") and start_line then
                                    end_line = i
                                    break
                                end
                            end
                            if start_line and end_line then
                                vim.api.nvim_buf_set_lines(0, start_line, end_line, false, toc)
                                print("Markdown TOC 已更新")
                            else
                                vim.api.nvim_buf_set_lines(0, 0, 0, false, toc)
                                print("Markdown TOC 已生成")
                            end
                        end,
                        opts = { buffer = true, noremap = true, desc = "生成標準 Markdown TOC" },
                    },
                    ["<leader>mr"] = {
                        action = function()
                            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                            local start_line, end_line = nil, nil
                            for i, line in ipairs(lines) do
                                if line:match("<!-- TOC -->") then
                                    start_line = i - 1
                                elseif line:match("<!-- /TOC -->") and start_line then
                                    end_line = i
                                    break
                                end
                            end
                            if start_line and end_line then
                                vim.api.nvim_buf_set_lines(0, start_line, end_line, false, {})
                                print("TOC 已移除")
                            else
                                print("未找到 TOC")
                            end
                        end,
                        opts = { buffer = true, noremap = true, desc = "移除 TOC" },
                    },
                    ["<leader>mg"] = {
                        action = function()
                            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                            for i, line in ipairs(lines) do
                                if line:match("<!-- TOC -->") then
                                    vim.api.nvim_win_set_cursor(0, { i, 0 })
                                    print("跳轉到 TOC")
                                    return
                                end
                            end
                            print("未找到 TOC")
                        end,
                        opts = { buffer = true, noremap = true, desc = "跳轉到 TOC" },
                    },
                },
                -- Obsidian 應用設定
                use_advanced_uri = false,
                open_app_foreground = false,
                -- 回調函數
                callbacks = {
                    post_setup = function(client)
                        print("Obsidian.nvim 已載入")
                    end,
                    enter_note = function(client, note) end,
                    leave_note = function(client, note) end,
                    pre_write_note = function(client, note)
                        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                        for _, line in ipairs(lines) do
                            if line:match("<!-- TOC -->") then
                                break
                            end
                        end
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
        build = "cd app && npm install --package-lock=false",
        config = function()
            -- 基本設定
            vim.g.mkdp_auto_start = 0
            vim.g.mkdp_auto_close = 1
            vim.g.mkdp_browser = ""
            vim.g.mkdp_echo_preview_url = 1
            vim.g.mkdp_theme = "dark"
            vim.g.mkdp_port = ""
            vim.g.mkdp_page_title = "「${name}」"
            vim.g.mkdp_open_to_the_world = 0

            -- CSS 檔案路徑 (確保檔案存在)
            local css_dir = vim.fn.expand("~/.config/nvim/lua/customfile/")
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

            -- 創建主題切換指令 (已註解 - 暫時不使用)
            -- vim.api.nvim_create_user_command("MarkdownThemeDark", function()
            --     vim.g.mkdp_theme = "dark"
            --     vim.notify("Markdown Preview 主題已切換為：Dark", vim.log.levels.INFO)
            -- end, { desc = "切換到深色主題" })

            -- vim.api.nvim_create_user_command("MarkdownThemeLight", function()
            --     vim.g.mkdp_theme = "light"
            --     vim.notify("Markdown Preview 主題已切換為：Light", vim.log.levels.INFO)
            -- end, { desc = "切換到淺色主題" })

            -- 切換自訂 CSS 主題的指令 (已註解 - 暫時不使用)
            -- vim.api.nvim_create_user_command("MarkdownThemeCustom", function()
            --     if vim.fn.filereadable(markdown_css) == 1 then
            --         vim.g.mkdp_markdown_css = markdown_css
            --         vim.g.mkdp_highlight_css = highlight_css
            --         vim.notify("已啟用自訂 CSS 主題", vim.log.levels.INFO)
            --     else
            --         vim.notify("自訂 CSS 檔案不存在，請先下載到: " .. css_dir, vim.log.levels.ERROR)
            --     end
            -- end, { desc = "啟用自訂 CSS 主題" })

            -- vim.api.nvim_create_user_command("MarkdownThemeDefault", function()
            --     vim.g.mkdp_markdown_css = ""
            --     vim.g.mkdp_highlight_css = ""
            --     vim.notify("已重置為預設主題", vim.log.levels.INFO)
            -- end, { desc = "重置為預設主題" })

            -- 建立 CSS 目錄的指令 (已註解 - 暫時不使用)
            -- vim.api.nvim_create_user_command("MarkdownSetupCSS", function()
            --     vim.fn.system("mkdir -p " .. css_dir)
            --     vim.notify("CSS 目錄已建立: " .. css_dir, vim.log.levels.INFO)
            --     vim.notify("請手動下載 CSS 檔案到此目錄", vim.log.levels.INFO)
            -- end, { desc = "建立 CSS 目錄" })
        end,
        keys = {
            { "<leader>mp", "<cmd>MarkdownPreview<cr>", desc = "開啟 Markdown 預覽" },
            { "<leader>mP", "<cmd>MarkdownPreviewStop<cr>", desc = "停止 Markdown 預覽" },
            { "<leader>mv", "<cmd>MarkdownPreviewToggle<cr>", desc = "切換 Markdown 預覽" },
            -- 主題切換快捷鍵 (已註解 - 暫時不使用)
            -- { "<leader>mtd", "<cmd>MarkdownThemeDark<cr>", desc = "Dark Theme" },
            -- { "<leader>mtl", "<cmd>MarkdownThemeLight<cr>", desc = "Light Theme" },
            -- { "<leader>mtc", "<cmd>MarkdownThemeCustom<cr>", desc = "Custom CSS Theme" },
            -- { "<leader>mtr", "<cmd>MarkdownThemeDefault<cr>", desc = "Reset Theme" },
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
            { "<leader>mpo", "<cmd>PeekOpen<cr>", desc = "開啟 Peek 預覽" },
            { "<leader>mpc", "<cmd>PeekClose<cr>", desc = "關閉 Peek 預覽" },
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
        keys = {
            {
                "<leader>ip",
                function()
                    require("img-clip").paste_image()
                end,
                desc = "貼上圖片並插入 Markdown 語法",
                mode = "n",
            },
        },
    },
}
