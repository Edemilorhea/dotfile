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
        init = function()
            -- 讓 markdown code block 的 cs / csharp 都對應到 c_sharp parser
            -- (info string 別名，兩種寫法都能正確高亮)
            vim.treesitter.language.register("c_sharp", { "cs", "csharp" })
        end,
        opts = {
            ensure_installed = {
                "vue",
                "c_sharp",
                "sql",
                "mermaid",
            },
        },
    },

    -- 彩虹括號：依照巢狀層級顯示不同顏色
    -- 注意：html/jsx/tsx/vue 使用 rainbow-parens，只彩虹括號，不彩虹 tag 層級
    {
        "HiPhish/rainbow-delimiters.nvim",
        event = "LazyFile",
        cond = not vim.g.vscode,
        config = function()
            local rainbow_delimiters = require("rainbow-delimiters")

            vim.g.rainbow_delimiters = {
                strategy = {
                    [""] = rainbow_delimiters.strategy["global"],
                },
                query = {
                    [""] = "rainbow-delimiters", -- 其他語言：括號 + block
                    html = "rainbow-parens", -- HTML：只有括號，tag 不變色
                    jsx = "rainbow-parens",
                    tsx = "rainbow-parens",
                    vue = "rainbow-parens",
                },
            }
        end,
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

    -- Diffview：單一 tabpage 對比所有變更檔案 / 檔案歷史
    -- 用於解決 lazygit 內建 diff 面板與 `git diff` 不易並排對比的問題
    -- lazygit.nvim 負責 stage/commit/branch 等操作，diffview 專注於「看對比」
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewFocusFiles", "DiffviewToggleFiles" },
        cond = not vim.g.vscode,
        keys = {
            { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview：對比目前變更" },
            { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview：目前檔案歷史" },
        },
        -- opts 用 function 延遲 require，避免插件尚未安裝完成時 require 失敗
        -- 按鍵（lhs）與動作（rhs）皆與官方預設相同，只把 desc 翻成中文
        -- 供 g? 說明面板顯示中文（git 專有名詞 OURS/THEIRS/BASE 保留原文）
        opts = function()
            local actions = require("diffview.actions")

            return {
                keymaps = {
                    view = {
                        { "n", "<tab>", actions.select_next_entry, { desc = "開啟下一個檔案的 diff" } },
                        { "n", "<s-tab>", actions.select_prev_entry, { desc = "開啟上一個檔案的 diff" } },
                        { "n", "[F", actions.select_first_entry, { desc = "開啟第一個檔案的 diff" } },
                        { "n", "]F", actions.select_last_entry, { desc = "開啟最後一個檔案的 diff" } },
                        { "n", "gf", actions.goto_file_edit, { desc = "在前一個分頁開啟檔案" } },
                        { "n", "<C-w><C-f>", actions.goto_file_split, { desc = "在新分割視窗開啟檔案" } },
                        { "n", "<C-w>gf", actions.goto_file_tab, { desc = "在新分頁開啟檔案" } },
                        { "n", "<leader>e", actions.focus_files, { desc = "把焦點移到檔案面板" } },
                        { "n", "<leader>b", actions.toggle_files, { desc = "切換檔案面板顯示" } },
                        { "n", "g<C-x>", actions.cycle_layout, { desc = "切換可用的版面配置" } },
                        { "n", "[x", actions.prev_conflict, { desc = "合併工具：跳到上一個衝突" } },
                        { "n", "]x", actions.next_conflict, { desc = "合併工具：跳到下一個衝突" } },
                        { "n", "<leader>co", actions.conflict_choose("ours"), { desc = "選擇衝突的 OURS 版本" } },
                        { "n", "<leader>ct", actions.conflict_choose("theirs"), { desc = "選擇衝突的 THEIRS 版本" } },
                        { "n", "<leader>cb", actions.conflict_choose("base"), { desc = "選擇衝突的 BASE 版本" } },
                        { "n", "<leader>ca", actions.conflict_choose("all"), { desc = "保留衝突的所有版本" } },
                        { "n", "dx", actions.conflict_choose("none"), { desc = "刪除該衝突區塊" } },
                        { "n", "<leader>cO", actions.conflict_choose_all("ours"), { desc = "整檔選擇 OURS 版本" } },
                        { "n", "<leader>cT", actions.conflict_choose_all("theirs"), { desc = "整檔選擇 THEIRS 版本" } },
                        { "n", "<leader>cB", actions.conflict_choose_all("base"), { desc = "整檔選擇 BASE 版本" } },
                        { "n", "<leader>cA", actions.conflict_choose_all("all"), { desc = "整檔保留所有版本" } },
                        { "n", "dX", actions.conflict_choose_all("none"), { desc = "整檔刪除衝突區塊" } },
                    },
                    diff1 = {
                        { "n", "g?", actions.help({ "view", "diff1" }), { desc = "開啟說明面板" } },
                    },
                    diff2 = {
                        { "n", "g?", actions.help({ "view", "diff2" }), { desc = "開啟說明面板" } },
                    },
                    diff3 = {
                        { { "n", "x" }, "2do", actions.diffget("ours"), { desc = "取得 OURS 版本的 diff hunk" } },
                        { { "n", "x" }, "3do", actions.diffget("theirs"), { desc = "取得 THEIRS 版本的 diff hunk" } },
                        { "n", "g?", actions.help({ "view", "diff3" }), { desc = "開啟說明面板" } },
                    },
                    diff4 = {
                        { { "n", "x" }, "1do", actions.diffget("base"), { desc = "取得 BASE 版本的 diff hunk" } },
                        { { "n", "x" }, "2do", actions.diffget("ours"), { desc = "取得 OURS 版本的 diff hunk" } },
                        { { "n", "x" }, "3do", actions.diffget("theirs"), { desc = "取得 THEIRS 版本的 diff hunk" } },
                        { "n", "g?", actions.help({ "view", "diff4" }), { desc = "開啟說明面板" } },
                    },
                    file_panel = {
                        { "n", "j", actions.next_entry, { desc = "游標移到下一個檔案項目" } },
                        { "n", "<down>", actions.next_entry, { desc = "游標移到下一個檔案項目" } },
                        { "n", "k", actions.prev_entry, { desc = "游標移到上一個檔案項目" } },
                        { "n", "<up>", actions.prev_entry, { desc = "游標移到上一個檔案項目" } },
                        { "n", "<cr>", actions.select_entry, { desc = "開啟選取項目的 diff" } },
                        { "n", "o", actions.select_entry, { desc = "開啟選取項目的 diff" } },
                        { "n", "l", actions.select_entry, { desc = "開啟選取項目的 diff" } },
                        { "n", "<2-LeftMouse>", actions.select_entry, { desc = "開啟選取項目的 diff" } },
                        { "n", "-", actions.toggle_stage_entry, { desc = "Stage / unstage 選取項目" } },
                        { "n", "s", actions.toggle_stage_entry, { desc = "Stage / unstage 選取項目" } },
                        { "n", "S", actions.stage_all, { desc = "Stage 全部項目" } },
                        { "n", "U", actions.unstage_all, { desc = "Unstage 全部項目" } },
                        { "n", "X", actions.restore_entry, { desc = "還原項目到左側狀態" } },
                        { "n", "L", actions.open_commit_log, { desc = "開啟 commit log 面板" } },
                        { "n", "zo", actions.open_fold, { desc = "展開摺疊" } },
                        { "n", "h", actions.close_fold, { desc = "收合摺疊" } },
                        { "n", "zc", actions.close_fold, { desc = "收合摺疊" } },
                        { "n", "za", actions.toggle_fold, { desc = "切換摺疊" } },
                        { "n", "zR", actions.open_all_folds, { desc = "展開所有摺疊" } },
                        { "n", "zM", actions.close_all_folds, { desc = "收合所有摺疊" } },
                        { "n", "<c-b>", actions.scroll_view(-0.25), { desc = "向上捲動畫面" } },
                        { "n", "<c-f>", actions.scroll_view(0.25), { desc = "向下捲動畫面" } },
                        { "n", "<tab>", actions.select_next_entry, { desc = "開啟下一個檔案的 diff" } },
                        { "n", "<s-tab>", actions.select_prev_entry, { desc = "開啟上一個檔案的 diff" } },
                        { "n", "[F", actions.select_first_entry, { desc = "開啟第一個檔案的 diff" } },
                        { "n", "]F", actions.select_last_entry, { desc = "開啟最後一個檔案的 diff" } },
                        { "n", "gf", actions.goto_file_edit, { desc = "在前一個分頁開啟檔案" } },
                        { "n", "<C-w><C-f>", actions.goto_file_split, { desc = "在新分割視窗開啟檔案" } },
                        { "n", "<C-w>gf", actions.goto_file_tab, { desc = "在新分頁開啟檔案" } },
                        { "n", "i", actions.listing_style, { desc = "切換 list / tree 顯示模式" } },
                        { "n", "f", actions.toggle_flatten_dirs, { desc = "在 tree 模式下攤平空子目錄" } },
                        { "n", "R", actions.refresh_files, { desc = "重新整理檔案清單" } },
                        { "n", "<leader>e", actions.focus_files, { desc = "把焦點移到檔案面板" } },
                        { "n", "<leader>b", actions.toggle_files, { desc = "切換檔案面板顯示" } },
                        { "n", "g<C-x>", actions.cycle_layout, { desc = "切換可用的版面配置" } },
                        { "n", "[x", actions.prev_conflict, { desc = "跳到上一個衝突" } },
                        { "n", "]x", actions.next_conflict, { desc = "跳到下一個衝突" } },
                        { "n", "g?", actions.help("file_panel"), { desc = "開啟說明面板" } },
                        { "n", "<leader>cO", actions.conflict_choose_all("ours"), { desc = "整檔選擇 OURS 版本" } },
                        { "n", "<leader>cT", actions.conflict_choose_all("theirs"), { desc = "整檔選擇 THEIRS 版本" } },
                        { "n", "<leader>cB", actions.conflict_choose_all("base"), { desc = "整檔選擇 BASE 版本" } },
                        { "n", "<leader>cA", actions.conflict_choose_all("all"), { desc = "整檔保留所有版本" } },
                        { "n", "dX", actions.conflict_choose_all("none"), { desc = "整檔刪除衝突區塊" } },
                    },
                    file_history_panel = {
                        { "n", "g!", actions.options, { desc = "開啟選項面板" } },
                        { "n", "<C-A-d>", actions.open_in_diffview, { desc = "在 diffview 開啟游標下的項目" } },
                        { "n", "y", actions.copy_hash, { desc = "複製游標下項目的 commit hash" } },
                        { "n", "L", actions.open_commit_log, { desc = "顯示 commit 詳細訊息" } },
                        { "n", "X", actions.restore_entry, { desc = "還原檔案到選取項目的狀態" } },
                        { "n", "zo", actions.open_fold, { desc = "展開摺疊" } },
                        { "n", "zc", actions.close_fold, { desc = "收合摺疊" } },
                        { "n", "h", actions.close_fold, { desc = "收合摺疊" } },
                        { "n", "za", actions.toggle_fold, { desc = "切換摺疊" } },
                        { "n", "zR", actions.open_all_folds, { desc = "展開所有摺疊" } },
                        { "n", "zM", actions.close_all_folds, { desc = "收合所有摺疊" } },
                        { "n", "j", actions.next_entry, { desc = "游標移到下一個檔案項目" } },
                        { "n", "<down>", actions.next_entry, { desc = "游標移到下一個檔案項目" } },
                        { "n", "k", actions.prev_entry, { desc = "游標移到上一個檔案項目" } },
                        { "n", "<up>", actions.prev_entry, { desc = "游標移到上一個檔案項目" } },
                        { "n", "<cr>", actions.select_entry, { desc = "開啟選取項目的 diff" } },
                        { "n", "o", actions.select_entry, { desc = "開啟選取項目的 diff" } },
                        { "n", "l", actions.select_entry, { desc = "開啟選取項目的 diff" } },
                        { "n", "<2-LeftMouse>", actions.select_entry, { desc = "開啟選取項目的 diff" } },
                        { "n", "<c-b>", actions.scroll_view(-0.25), { desc = "向上捲動畫面" } },
                        { "n", "<c-f>", actions.scroll_view(0.25), { desc = "向下捲動畫面" } },
                        { "n", "<tab>", actions.select_next_entry, { desc = "開啟下一個檔案的 diff" } },
                        { "n", "<s-tab>", actions.select_prev_entry, { desc = "開啟上一個檔案的 diff" } },
                        { "n", "[F", actions.select_first_entry, { desc = "開啟第一個檔案的 diff" } },
                        { "n", "]F", actions.select_last_entry, { desc = "開啟最後一個檔案的 diff" } },
                        { "n", "gf", actions.goto_file_edit, { desc = "在前一個分頁開啟檔案" } },
                        { "n", "<C-w><C-f>", actions.goto_file_split, { desc = "在新分割視窗開啟檔案" } },
                        { "n", "<C-w>gf", actions.goto_file_tab, { desc = "在新分頁開啟檔案" } },
                        { "n", "<leader>e", actions.focus_files, { desc = "把焦點移到檔案面板" } },
                        { "n", "<leader>b", actions.toggle_files, { desc = "切換檔案面板顯示" } },
                        { "n", "g<C-x>", actions.cycle_layout, { desc = "切換可用的版面配置" } },
                        { "n", "g?", actions.help("file_history_panel"), { desc = "開啟說明面板" } },
                    },
                    option_panel = {
                        { "n", "<tab>", actions.select_entry, { desc = "變更目前選項" } },
                        { "n", "q", actions.close, { desc = "關閉面板" } },
                        { "n", "g?", actions.help("option_panel"), { desc = "開啟說明面板" } },
                    },
                    help_panel = {
                        { "n", "q", actions.close, { desc = "關閉說明選單" } },
                        { "n", "<esc>", actions.close, { desc = "關閉說明選單" } },
                    },
                },
            }
        end,
    },
}
