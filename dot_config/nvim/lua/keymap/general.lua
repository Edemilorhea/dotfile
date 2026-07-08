-- keymap/general.lua
-- VSCode 和 Neovim 共用的核心按鍵映射

local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }

    -- 清除搜尋高亮
    vim.keymap.set("n", "<Esc>", "<Esc>:nohlsearch<CR>", { silent = true, desc = "清除搜尋高亮" })

    -- Visual 模式下的跳轉和復原
    vim.keymap.set("v", "<C-o>", "<Esc>:normal! <C-o><CR>", { desc = "跳回上一個位置" })
    vim.keymap.set("v", "<C-i>", "<Esc>:normal! <C-i><CR>", { desc = "跳到下一個位置" })
    vim.keymap.set("v", "<C-r>", "<Esc>:normal! <C-r><CR>", { desc = "重做" })

    -- Visual 模式下的大小寫轉換
    vim.keymap.set("v", "U", "gU", { desc = "轉成大寫" })
    vim.keymap.set("v", "u", "gu", { desc = "轉成小寫" })

    -- Normal 模式下的 undo，確保不會停留在 visual mode
    -- vim.keymap.set("n", "u", function()
    --     vim.cmd("normal! u")
    --     if vim.fn.mode():match("[vV]") then
    --         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    --     end
    -- end, { desc = "Undo and exit visual mode" })
    --
    -- vim.keymap.set("n", "<C-R>", function()
    --     vim.cmd("normal! \\<C-R>")
    --     if vim.fn.mode():match("[vV]") then
    --         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    --     end
    -- end, { desc = "Redo and exit visual mode" })

    -- 核心編輯行為（個人偏好設定，VSCode + Neovim 共用）
    vim.keymap.set("n", "o", "o<Esc>", { desc = "下方新增空行" })
    vim.keymap.set("n", "O", "O<Esc>", { desc = "上方新增空行" })

    -- 刪除到黑洞暫存器（避免覆蓋剪貼簿）
    vim.keymap.set({ "n", "v" }, "d", '"_d', { desc = "刪除但不覆蓋剪貼簿" })
    vim.keymap.set("n", "D", '"_D', { desc = "刪到行尾但不覆蓋剪貼簿" })
    vim.keymap.set("n", "dd", '"_dd', { desc = "刪除整行但不覆蓋剪貼簿" })

    -- 縮排控制
    vim.keymap.set("i", "<S-Tab>", "<C-d>", { desc = "減少縮排" })

    -- Visual 模式下貼上不覆蓋暫存器，保護黑洞寄存器
    vim.keymap.set("x", "p", '"zdP', { desc = "貼上且保留原剪貼簿" })

    -- Mark 跳轉：互換 ' 和 ` 的功能，讓 'a 直接跳到 mark 的精確位置
    vim.keymap.set({ "n", "v", "o" }, "'", "`", { desc = "跳到 mark 精確位置（與 ` 互換）" })
    vim.keymap.set({ "n", "v", "o" }, "`", "'", { desc = "跳到 mark 行首非空白（與 ' 互換）" })

    -- 基本文字選取和移動（兩邊通用）
    vim.keymap.set("n", "H", "^", { desc = "移到行首非空白字元" })
    vim.keymap.set("n", "L", "$", { desc = "移到行尾" })
    vim.keymap.set("v", "H", "^", { desc = "移到行首非空白字元" })
    vim.keymap.set("v", "L", "$", { desc = "移到行尾" })

    -- 快速儲存（兩邊通用）
    vim.keymap.set("n", "<C-s>", "<cmd>w<cr>", { desc = "儲存檔案" })
    vim.keymap.set("i", "<C-s>", "<Esc><cmd>w<cr>", { desc = "儲存檔案" })

    -- 純 Neovim 環境專用設定
    if not vim.g.vscode then
        -- Ctrl+Q 作為 Visual Block（替代 Ctrl+V，避免終端貼上衝突）
        vim.keymap.set({ "n", "x" }, "<C-q>", "<C-v>", { desc = "進入區塊選取模式" })

        -- Insert / Command-line (含 / 搜尋) 模式：Ctrl+V 貼上系統剪貼簿
        -- Normal 模式維持預設 Ctrl+V = Visual Block
        vim.keymap.set("i", "<C-v>", "<C-r>+", { desc = "貼上系統剪貼簿" })
        vim.keymap.set("c", "<C-v>", "<C-r>+", { desc = "貼上系統剪貼簿" })

        -- Alacritty: Ctrl+/ 鍵碼修正
        vim.keymap.set('n', '<C-_>', 'gcc', { noremap = true, silent = true })
        vim.keymap.set('v', '<C-_>', 'gc',  { noremap = true, silent = true })

        -- 視窗導航：原生 Neovim window 切換（不依賴 tmux-navigation 插件）
        -- <C-h> 需搭配 Alacritty 送出 \x1b[104;5u，避免終端機將 Ctrl+H 解讀為 Backspace
        vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "切換左視窗" })
        vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "切換下視窗" })
        vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "切換上視窗" })
        vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "切換右視窗" })

        -- 完整重啟 Neovim 並自動還原上一個 Session
        -- 用 <leader>rr（雙鍵）取代原本的 <leader>r，避免跟其他 <leader>r* 鍵誤觸
        --
        -- 為什麼要這樣繞：
        -- LazyVim 的 LSP/Treesitter/gitsigns 是靠 LazyFile 事件（= BufReadPost/BufNewFile/
        -- BufWritePre）延遲載入。session 還原時 source session 檔會開檔案並觸發 BufReadPost，
        -- 進而載入這些 plugin 並 attach LSP。但這只有在「整個啟動流程完全跑完、所有 lazy
        -- handler 就緒後」才會正確運作 —— 這正是 <leader>ql 手動還原時的時機。
        -- 若在 VeryLazy callback 內同步還原（太早、又是巢狀 autocmd），BufReadPost 事件無法
        -- 正確驅動 LazyFile → LSP 不會 attach。
        -- 解法：寫 flag 檔 → plain :restart → 新 process 在 VimEnter 後用 vim.schedule
        --       把還原排到啟動流程的最尾端，模擬手動按 <leader>ql 的時機。
        local restart_flag = vim.fn.stdpath("state") .. "/restart_session_pending"
        vim.keymap.set("n", "<leader>rr", function()
            local f = io.open(restart_flag, "w")
            if f then
                f:close()
            end
            vim.cmd("restart")
        end, { desc = "重啟 Neovim 並還原上次 Session" })

        -- 新 process 啟動：若偵測到 restart flag，於 VimEnter 之後 defer 還原 session。
        -- 用 nested + vim.schedule 確保排在所有啟動 autocmd（含 LazyFile handler 註冊）之後。
        if vim.uv.fs_stat(restart_flag) then
            os.remove(restart_flag)
            vim.api.nvim_create_autocmd("VimEnter", {
                once = true,
                nested = true, -- 允許 source session 時開檔案觸發的 BufReadPost 再驅動其他 autocmd
                callback = function()
                    vim.schedule(function()
                        local ok, persistence = pcall(require, "persistence")
                        if ok then
                            persistence.load({ last = true })
                        end
                    end)
                end,
            })
        end
    end
end

return M
