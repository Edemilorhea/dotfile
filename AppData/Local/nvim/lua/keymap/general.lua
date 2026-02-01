-- keymap/general.lua
-- VSCode 和 Neovim 共用的核心按鍵映射

local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }

    -- 清除搜尋高亮
    vim.keymap.set("n", "<Esc>", "<Esc>:nohlsearch<CR>", { silent = true, desc = "Clear search highlight" })

    -- Visual 模式下的跳轉和復原
    vim.keymap.set("v", "<C-o>", "<Esc>:normal! <C-o><CR>", { desc = "Jump back" })
    vim.keymap.set("v", "<C-i>", "<Esc>:normal! <C-i><CR>", { desc = "Jump forward" })
    vim.keymap.set("v", "<C-r>", "<Esc>:normal! <C-r><CR>", { desc = "Redo" })

    -- Visual 模式下的大小寫轉換
    vim.keymap.set("v", "U", "gU", { desc = "Convert to uppercase" })
    vim.keymap.set("v", "u", "gu", { desc = "Convert to lowercase" })

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
    vim.keymap.set("n", "o", "o<Esc>", { desc = "New line below without insert" })
    vim.keymap.set("n", "O", "O<Esc>", { desc = "New line above without insert" })

    -- 刪除到黑洞暫存器（避免覆蓋剪貼簿）
    vim.keymap.set({ "n", "v" }, "d", '"_d', { desc = "Delete to black hole" })
    vim.keymap.set("n", "D", '"_D', { desc = "Delete to end of line (black hole)" })
    vim.keymap.set("n", "dd", '"_dd', { desc = "Delete line (black hole)" })

    -- 縮排控制
    vim.keymap.set("i", "<S-Tab>", "<C-d>", { desc = "Unindent" })

    -- Visual 模式下貼上不覆蓋暫存器，保護黑洞寄存器
    vim.keymap.set("x", "p", '"zdP', { desc = "Paste without yanking (protect black hole)" })

    -- 基本文字選取和移動（兩邊通用）
    vim.keymap.set("n", "H", "^", { desc = "Go to first non-blank character" })
    vim.keymap.set("n", "L", "$", { desc = "Go to end of line" })
    vim.keymap.set("v", "H", "^", { desc = "Go to first non-blank character" })
    vim.keymap.set("v", "L", "$", { desc = "Go to end of line" })

    -- 快速儲存（兩邊通用）
    vim.keymap.set("n", "<C-s>", "<cmd>w<cr>", { desc = "Save file" })
    vim.keymap.set("i", "<C-s>", "<Esc><cmd>w<cr>", { desc = "Save file" })

    -- H L 代替跳轉到句首跟句尾
    vim.keymap.set("n", "L", "$", { desc = "Move to line end", remap = false})
    vim.keymap.set("n", "H", "^", { desc = "Move to line start", remap = false})

    -- LazyVim 配置重載（只在 Neovim 中有效）
    if not vim.g.vscode then
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
        vim.keymap.set("n", "<leader>r", reload_lazyvim, { desc = "Reload LazyVim config" })
    end
end

return M
