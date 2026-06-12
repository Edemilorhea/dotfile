-- keymap/neovim.lua
-- 純 Neovim 環境的專用按鍵映射

local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }

    -- 只在 Neovim 中使用的功能按鍵
    -- Buffer 管理
    vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
    vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
    vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
    -- 視窗分割管理
    vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertically" })
    vim.keymap.set("n", "<leader>sh", "<cmd>split<cr>", { desc = "Split horizontally" })
    vim.keymap.set("n", "<leader>sx", "<cmd>close<cr>", { desc = "Close split" })
    -- 搜尋和取代
    vim.keymap.set("n", "<leader>sr", ":%s/\\<<C-r><C-w>\\>/", { desc = "Replace word under cursor" })
    vim.keymap.set("v", "<leader>sr", ":s/", { desc = "Replace in selection" })
    -- Terminal 相關 (Neovim 專用)
    -- \tt 已移至 floaterm (tools.lua)，保留 terminal mode 退出鍵
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
    -- LSP / 診斷：已由 LazyVim 內建，不重複定義
    -- (gd, gy, gi, gr, K, [d, ]d, \ca, \rn 皆由 LazyVim 處理)
    vim.keymap.set("n", "<leader>xx", vim.diagnostic.open_float, { desc = "Show line diagnostic" })
    vim.keymap.set("n", "<leader>xl", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })
    vim.keymap.set("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list" })
    -- 摺疊相關：使用 Neovim 原生摺疊 (nvim-ufo 已停用)

    -- Inlay Hints 開關（使用 <leader>uh，避免 <C-c> 衝突）
    vim.keymap.set("n", "<leader>uh", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
        vim.notify("Inlay Hints: " .. (not enabled and "ON" or "OFF"), vim.log.levels.INFO)
    end, { desc = "開關 Inlay Hints" })

    -- 臨時顯示 Inlay Hints（按 <C-i> 顯示 3 秒後自動關閉）
    vim.keymap.set("n", "<C-i>", function()
        vim.lsp.inlay_hint.enable(true, { bufnr = 0 })
        vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(0) then
                vim.lsp.inlay_hint.enable(false, { bufnr = 0 })
            end
        end, 3000)
    end, { desc = "臨時顯示 Inlay Hints (3秒)" })
end

return M

