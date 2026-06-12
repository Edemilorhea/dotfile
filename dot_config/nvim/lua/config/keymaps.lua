-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

require("keymap.general").setup()

require("keymap.hotKeyMaps").setup()

if not vim.g.vscode then
    require("keymap.neovim").setup()
end

if vim.g.vscode then
    require("keymap.vscode").setup()
end

vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        -- 完全移除 LazyVim 預設的 <C-/> 終端機綁定
        print("移除 LazyVim 預設 terminal 綁定，改為註解功能")
        -- 移除所有模式的 <C-/> 和 <C-_> 綁定（LazyVim 使用小寫 <c-/>）
        for _, mode in ipairs({ "n", "i", "v", "x", "s", "o", "t" }) do
            pcall(vim.keymap.del, mode, "<C-/>")
            pcall(vim.keymap.del, mode, "<C-_>")
            pcall(vim.keymap.del, mode, "<c-/>")
            pcall(vim.keymap.del, mode, "<c-_>")
        end
        -- 設定為註解功能（直接呼叫 mini.comment 的 API）
        vim.keymap.set("n", "<C-/>", function()
            require("mini.comment").toggle_lines(vim.fn.line("."), vim.fn.line("."))
        end, { desc = "註解目前行" })
        vim.keymap.set("n", "<C-_>", function()
            require("mini.comment").toggle_lines(vim.fn.line("."), vim.fn.line("."))
        end, { desc = "註解目前行" })
        vim.keymap.set("v", "<C-/>", function()
            local start_line = vim.fn.line("'<")
            local end_line = vim.fn.line("'>")
            require("mini.comment").toggle_lines(start_line, end_line)
        end, { desc = "註解選取範圍" })
        vim.keymap.set("v", "<C-_>", function()
            local start_line = vim.fn.line("'<")
            local end_line = vim.fn.line("'>")
            require("mini.comment").toggle_lines(start_line, end_line)
        end, { desc = "註解選取範圍" })

        -- 覆蓋 LazyVim 預設格式化，改走 conform 的 formatter chain：dprint → biome → prettier → LSP
        pcall(vim.keymap.del, "n", "<leader>cf")
        pcall(vim.keymap.del, "v", "<leader>cf")
        vim.keymap.set({ "n", "v" }, "<leader>cf", function()
            require("conform").format({
                async = true,
                lsp_format = "fallback",
            })
        end, { desc = "格式化" })

        -- 覆蓋 LazyVim 預設的 H/L (buffer 切換)
        vim.keymap.set("n", "H", "^", { desc = "移到行首非空白字元" })
        vim.keymap.set("n", "L", "$", { desc = "移到行尾" })
        vim.keymap.set("v", "H", "^", { desc = "移到行首非空白字元" })
        vim.keymap.set("v", "L", "$", { desc = "移到行尾" })
    end,
})
