return {
    -- \h 系列 Flash 跳轉（s / S / r / R 定義在 core/plugins.lua，兩個環境共用）
    {
        "folke/flash.nvim",
        keys = {
            { "<leader>hf", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash 跳轉" },
            { "<leader>hF", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash 語法樹跳轉" },
            { "<leader>hr", function() require("flash").treesitter_search() end, mode = { "o", "x" }, desc = "語法樹搜尋" },
            { "<leader>he", function() require("flash").toggle() end, desc = "切換 Flash 搜尋" },
        },
    },

    -- \sr 保留給 config/keymaps.lua 的 :s 取代；grug-far 改用 :GrugFar 開啟。
    {
        "MagicDuck/grug-far.nvim",
        keys = {
            { "<leader>sr", false, mode = { "n", "x" } },
        },
    },

    -- 程式碼摺疊：nvim-ufo（解決 treesitter foldtext 在 JSX/TSX 巢狀表達式回傳空字串、
    -- 導致摺疊列整行空白的問題）。LSP folds 已在 plugins/lsp.lua 關閉。
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        event = "BufReadPost",
        init = function()
            -- ufo 需要很高的 foldlevel，否則開檔會被全部摺疊
            vim.o.foldcolumn = "1"
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
        end,
        config = function()
            -- 摺疊列顯示：保留第一行內容 + 顯示折疊行數
            local handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = ("  󰁂 %d lines"):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        table.insert(newVirtText, { chunkText, chunk[2] })
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, "MoreMsg" })
                return newVirtText
            end

            local ufo = require("ufo")
            ufo.setup({
                fold_virt_text_handler = handler,
                provider_selector = function()
                    return { "treesitter", "indent" }
                end,
            })

            vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "開啟所有摺疊" })
            vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "關閉所有摺疊" })
        end,
    },

    -- Treesitter：只補充額外 parser，其餘交給 LazyVim（opts_extend 會合併清單）
    {
        "nvim-treesitter/nvim-treesitter",
        init = function()
            -- 讓 markdown code block 的 cs / csharp 都對應到 c_sharp parser
            vim.treesitter.language.register("c_sharp", { "cs", "csharp" })
        end,
        opts = {
            ensure_installed = { "vue", "c_sharp", "sql", "mermaid" },
        },
    },

    -- 彩虹括號；html/jsx/tsx/vue 只彩虹括號，不彩虹 tag 層級
    {
        "HiPhish/rainbow-delimiters.nvim",
        event = "LazyFile",
        config = function()
            local rainbow_delimiters = require("rainbow-delimiters")
            vim.g.rainbow_delimiters = {
                strategy = {
                    [""] = rainbow_delimiters.strategy["global"],
                },
                query = {
                    [""] = "rainbow-delimiters",
                    html = "rainbow-parens",
                    jsx = "rainbow-parens",
                    tsx = "rainbow-parens",
                    vue = "rainbow-parens",
                },
            }
        end,
    },

    {
        "chentoast/marks.nvim",
        event = "VeryLazy",
        opts = {
            default_mappings = true, -- 保留原生 m + 字母 操作
            signs = true,
            mappings = {},
        },
    },

    -- Visual 模式下也能用 . 重複上一個動作
    {
        "inkarkat/vim-visualrepeat",
        event = "VeryLazy",
    },
}
