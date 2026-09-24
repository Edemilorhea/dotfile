-- Markdown 相關 plugin。TOC 工具（\mt \mT \mr \mg）在 config/markdown_toc.lua。

local vault_path = vim.fn.expand("~/Documents/Obsidian_Note")
local vault_exists = vim.fn.isdirectory(vault_path .. "/.obsidian") == 1

return {
    -- Markdown 渲染增強
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        ft = { "markdown" },
        opts = {
            enabled = true,
            debounce = 150,
            max_file_size = 5.0,

            -- 停用 latex 渲染（未安裝 latex parser / utftex，避免健檢警告）
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

    -- Obsidian 整合（社群維護版），只在 vault 存在時啟用。
    -- 指令改為 :Obsidian <子指令>（例如 :Obsidian new、:Obsidian search）。
    -- 筆記內 <CR> 是 smart_action（跟隨連結 / 切換複選框）；\ch 切換複選框。
    {
        "obsidian-nvim/obsidian.nvim",
        version = "*",
        ft = "markdown",
        enabled = vault_exists,
        dependencies = { "nvim-telescope/telescope.nvim" },
        ---@module 'obsidian'
        ---@type obsidian.config
        opts = {
            legacy_commands = false,
            workspaces = {
                { name = "main", path = vault_path },
            },
            notes_subdir = "notes",
            new_notes_location = "notes_subdir",
            daily_notes = {
                folder = "dailies",
                alias_format = "MMMM D, YYYY",
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
            link = { style = "markdown" },
            frontmatter = {
                func = function(note)
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
            },
            templates = {
                folder = "templates",
                substitutions = {
                    yesterday = function()
                        return os.date("%Y-%m-%d", os.time() - 86400)
                    end,
                },
            },
            picker = { name = "telescope.nvim" },
            attachments = {
                folder = "assets/imgs",
                img_name_func = function()
                    return string.format("%s-", os.time())
                end,
            },
            -- 畫面渲染交給 render-markdown.nvim
            ui = { enable = false },
            callbacks = {
                enter_note = function()
                    vim.keymap.set("n", "<leader>ch", "<cmd>Obsidian toggle_checkbox<cr>", {
                        buffer = true,
                        desc = "切換複選框",
                    })
                end,
            },
        },
    },

    -- Markdown 預覽（使用系統瀏覽器，適合有防火牆限制的環境）
    {
        "iamcco/markdown-preview.nvim",
        ft = "markdown",
        -- 上游 app 會 require msgpack-lite，卻未將它列為直接依賴。
        build = "cd app && npm install --package-lock=false && npm install --no-save --package-lock=false msgpack-lite",
        config = function()
            -- markdown-preview.nvim 的預設 opener 在 Windows 偶爾無法喚起瀏覽器，改由 vim.ui.open 處理。
            _G.markdown_preview_open = function(url)
                local process, err = vim.ui.open(url)
                if not process then
                    vim.notify("無法開啟 Markdown 預覽: " .. tostring(err), vim.log.levels.ERROR)
                end
            end
            vim.cmd([[
                function! MarkdownPreviewOpen(url) abort
                    call v:lua.markdown_preview_open(a:url)
                endfunction
            ]])

            vim.g.mkdp_auto_start = 0
            vim.g.mkdp_auto_close = 1
            vim.g.mkdp_browser = ""
            vim.g.mkdp_browserfunc = "MarkdownPreviewOpen"
            vim.g.mkdp_echo_preview_url = 1
            vim.g.mkdp_theme = "dark"
            vim.g.mkdp_port = ""
            vim.g.mkdp_page_title = "「${name}」"
            vim.g.mkdp_open_to_the_world = 0

            -- 自訂 CSS：檔案不存在時改用 plugin 預設樣式
            local css_dir = vim.fn.stdpath("config") .. "/lua/customfile/"
            for var, name in pairs({
                mkdp_markdown_css = "github-markdown-dark.min.css",
                mkdp_highlight_css = "tomorrow-night-eighties.css",
            }) do
                local path = css_dir .. name
                if vim.fn.filereadable(path) == 1 then
                    vim.g[var] = path
                else
                    vim.g[var] = ""
                    vim.notify("自訂 CSS 檔案不存在: " .. path, vim.log.levels.WARN)
                end
            end

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
        end,
        keys = {
            { "<leader>mp", "<cmd>MarkdownPreview<cr>", desc = "開啟 Markdown 預覽" },
            { "<leader>mP", "<cmd>MarkdownPreviewStop<cr>", desc = "停止 Markdown 預覽" },
            { "<leader>mv", "<cmd>MarkdownPreviewToggle<cr>", desc = "切換 Markdown 預覽" },
        },
    },

    -- 圖片貼上
    {
        "HakonHarnes/img-clip.nvim",
        ft = "markdown",
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
            },
        },
    },

    -- 自動延續清單
    {
        "gaoDean/autolist.nvim",
        ft = { "markdown", "text", "tex", "plaintex", "norg" },
        config = function()
            local autolist = require("autolist")
            autolist.setup()

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("user_autolist", { clear = true }),
                pattern = { "markdown", "text", "tex", "plaintex", "norg" },
                callback = function(event)
                    local function map(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
                    end

                    map("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>", "自動延續清單")
                    map("n", "<a-r>", "<cmd>AutolistRecalculate<cr>", "重新計算清單編號")
                    map("n", "cn", autolist.cycle_next_dr, "切換到下一種清單樣式")
                    map("n", "cp", autolist.cycle_prev_dr, "切換到上一種清單樣式")
                    map("n", ">>", ">><cmd>AutolistRecalculate<cr>", "縮排並重新計算")
                    map("n", "<<", "<<<cmd>AutolistRecalculate<cr>", "反縮排並重新計算")
                    map("n", "dd", function()
                        vim.cmd('normal! "_dd')
                        vim.cmd("AutolistRecalculate")
                    end, "刪除整行並重新計算")
                    map("x", "p", "P<cmd>AutolistRecalculate<cr>", "貼上（不覆蓋暫存器）並重新計算")
                end,
            })
        end,
    },
}
