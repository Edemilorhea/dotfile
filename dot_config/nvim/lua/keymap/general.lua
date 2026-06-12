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

        -- Alacritty: Ctrl+/ 鍵碼修正
        vim.keymap.set('n', '<C-_>', 'gcc', { noremap = true, silent = true })
        vim.keymap.set('v', '<C-_>', 'gc',  { noremap = true, silent = true })

        -- 視窗導航：由 tmux-navigation 插件處理 (psmux/tmux 整合)

        -- LazyVim 配置重載
        local function reload_lazyvim()
            local ok, reload = pcall(require, "lazy.core.reload")
            if ok and reload and reload.reload then
                reload.reload()
                vim.cmd("source $MYVIMRC")
                vim.cmd("doautocmd ColorScheme")
                vim.notify("🔁 LazyVim 設定已重新載入", vim.log.levels.INFO)
            else
                vim.notify("❌ LazyVim reload 失敗", vim.log.levels.ERROR)
            end
        end
        vim.keymap.set("n", "<leader>r", reload_lazyvim, { desc = "重新載入 LazyVim 設定" })
    end
end

return M
