-- 兩個環境共用的編輯習慣。
-- Visual 類 mapping 一律用 "x"（不用 "v"），避免在 Select 模式（snippet 佔位符）
-- 輸入 d、u、H、L、p 等字母時被 mapping 攔走。
local M = {}

function M.setup()
    local map = vim.keymap.set

    -- Visual 模式下的跳轉與重做：先離開 Visual 再執行
    map("x", "<C-o>", "<Esc><C-o>", { desc = "跳回上一個位置" })
    map("x", "<C-i>", "<Esc><C-i>", { desc = "跳到下一個位置" })
    map("x", "<C-r>", "<Esc><C-r>", { desc = "重做" })

    -- Visual 模式下的大小寫轉換
    map("x", "U", "gU", { desc = "轉成大寫" })
    map("x", "u", "gu", { desc = "轉成小寫" })

    -- o / O 新增空行後留在 Normal 模式
    map("n", "o", "o<Esc>", { desc = "下方新增空行" })
    map("n", "O", "O<Esc>", { desc = "上方新增空行" })

    -- 刪除改用黑洞暫存器，不覆蓋剪貼簿
    map({ "n", "x" }, "d", '"_d', { desc = "刪除但不覆蓋剪貼簿" })
    map("n", "D", '"_D', { desc = "刪到行尾但不覆蓋剪貼簿" })
    map("n", "dd", '"_dd', { desc = "刪除整行但不覆蓋剪貼簿" })

    -- Visual 貼上不覆蓋暫存器（原生 v_P）。Neovim 另在 plugins/coding.lua 的 yanky 設定同一個鍵。
    map("x", "p", "P", { desc = "貼上且不覆蓋暫存器" })

    map("i", "<S-Tab>", "<C-d>", { desc = "減少縮排" })

    -- 互換 ' 和 `，讓 'a 直接跳到 mark 的精確位置
    map({ "n", "x", "o" }, "'", "`", { desc = "跳到 mark 精確位置" })
    map({ "n", "x", "o" }, "`", "'", { desc = "跳到 mark 所在行首" })

    -- H / L 到行首 / 行尾（取代 LazyVim 的切換 buffer）
    map({ "n", "x" }, "H", "^", { desc = "移到行首非空白字元" })
    map({ "n", "x" }, "L", "$", { desc = "移到行尾" })

    -- 與 Rider 一致；<Esc> 清除高亮也保留
    map("n", "<leader>sc", "<cmd>nohlsearch<cr>", { desc = "清除搜尋高亮" })

    map("n", "<C-s>", "<cmd>w<cr>", { desc = "儲存檔案" })
    map("i", "<C-s>", "<Esc><cmd>w<cr>", { desc = "儲存檔案" })
end

return M
