-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

require("keymap.general").setup()

require("keymap.hotKeyMaps").setup()

if vim.g.vscode then
    require("keymap.vscode").setup()
end

vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        -- 安全地移除 LazyVim 綁定
        print("移除terminal 快捷鍵綁定")
        pcall(vim.keymap.del, "n", "<C-/>")
        pcall(vim.keymap.del, "t", "<C-/>")
        pcall(vim.keymap.del, "n", "<C-_>")
        pcall(vim.keymap.del, "t", "<C-_>")
        vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Comment line" })
        vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Comment line" })
        vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Comment selection" })
        vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Comment selection" })
    end,
})
