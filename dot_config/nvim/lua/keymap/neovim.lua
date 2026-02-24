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
    vim.keymap.set("n", "<leader>tt", "<cmd>terminal<cr>", { desc = "Open terminal" })
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
    -- LSP 相關快捷鍵 (主要在 Neovim 中使用)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
    vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
    vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Show references" })
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Show hover info" })
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
    -- 診斷相關
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
    vim.keymap.set("n", "<leader>xx", vim.diagnostic.open_float, { desc = "Show line diagnostic" })
    vim.keymap.set("n", "<leader>xl", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })
    vim.keymap.set("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list" })
    -- 摺疊相關 (使用 nvim-ufo)
    vim.keymap.set("n", "zR", function()
        require("ufo").openAllFolds()
    end, { desc = "Open all folds" })
    vim.keymap.set("n", "zM", function()
        require("ufo").closeAllFolds()
    end, { desc = "Close all folds" })
    vim.keymap.set("n", "zr", function()
        require("ufo").openFoldsExceptKinds()
    end, { desc = "Open folds except kinds" })
    vim.keymap.set("n", "zm", function()
        require("ufo").closeFoldsWith()
    end, { desc = "Close folds with" })
    vim.keymap.set("n", "zp", function()
        require("ufo").peekFoldedLinesUnderCursor()
    end, { desc = "Peek folded lines" })
end

return M

