-- plugins/neovim-only.lua
-- 只在 Neovim 中使用的插件
return {
    -- 程式碼折疊：使用 nvim-ufo（解決 treesitter foldtext 在 JSX/TSX 巢狀表達式
    -- 回傳空字串、導致摺疊列整行空白的問題）。lsp.lua 已設 folds.enabled = false。
    {
        "kevinhwang91/nvim-ufo",
        enabled = true,
        dependencies = { "kevinhwang91/promise-async" },
        event = "BufReadPost",
        cond = not vim.g.vscode,
        init = function()
            -- ufo 需要很高的 foldlevel，否則開檔會被全部摺疊
            vim.o.foldcolumn = "1"
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
        end,
        config = function()
            -- 摺疊列顯示：保留第一行內容 + 顯示折疊行數（取代空白問題）
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

            require("ufo").setup({
                fold_virt_text_handler = handler,
                provider_selector = function()
                    return { "treesitter", "indent" }
                end,
            })

            -- ufo 強化版 zR / zM（跨整個 buffer 展開／摺疊）
            vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
            vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
        end,
    },

    -- Markdown 自動列表
    {
        "gaoDean/autolist.nvim",
        ft = { "markdown", "text", "tex", "plaintex", "norg" },
        cond = not vim.g.vscode,
        config = function()
            local autolist = require("autolist")
            autolist.setup()

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "markdown", "text", "tex", "plaintex", "norg" },
                callback = function()
                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc })
                    end

                    map("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>", "Auto continue list")
                    map("n", "<a-r>", "<cmd>AutolistRecalculate<cr>", "Recalculate list")
                    map("n", "cn", autolist.cycle_next_dr, "cycle next list type")
                    map("n", "cp", autolist.cycle_prev_dr, "cycle prev list type")
                    map("n", ">>", ">><cmd>AutolistRecalculate<cr>", "Indent and recalc")
                    map("n", "<<", "<<<cmd>AutolistRecalculate<cr>", "Dedent and recalc")
                    map("n", "dd", function()
                        vim.cmd('normal! "_dd')
                        vim.cmd("AutolistRecalculate")
                    end, "Delete line and recalc")
                    map("v", "p", '"zdP<cmd>AutolistRecalculate<cr>', "Paste without yanking and recalc")
                end,
            })
        end,
    },

    -- Treesitter 語法高亮和解析
    -- LazyVim 15.x (main branch): 僅補充額外 parser，其餘交給 LazyVim 處理
    -- 移除 event 覆寫 (LazyVim 已設 LazyFile/VeryLazy)，opts_extend 會自動合併此清單
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "vue",
                "c_sharp",
                "sql",
                "mermaid",
            },
        },
    },

    -- LazyGit 整合
    -- 注意：\lg 已移除，改用 floaterm \tg (tools.lua)
    -- LazyVim 內建的 \gg / \gG 也可使用
    {
        "kdheepak/lazygit.nvim",
        cmd = "LazyGit",
        cond = not vim.g.vscode,
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            vim.g.lazygit_floating_window_winblend = 0
            vim.g.lazygit_floating_window_scaling_factor = 0.9
            vim.g.lazygit_use_neovim_remote = 1
        end,
    },
}

