-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--#region

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.opt_local.spell = false
    end,
})

-- Markdown 檔案使用 2 格縮排
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "md" },
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.bo.softtabstop = 4
        vim.bo.expandtab = true
    end,
})

-- Markdown 智慧動作
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        -- 跟隨連結
        vim.keymap.set("n", "gf", function()
            local ok, obs = pcall(require, "obsidian")
            if ok and obs and obs.util and obs.util.gf_passthrough then
                return obs.util.gf_passthrough()
            end
            return "gf"
        end, { buffer = true, expr = true, noremap = true, silent = true })

        -- 切換複選框
        vim.keymap.set("n", "<leader>ch", function()
            local ok, obs = pcall(require, "obsidian")
            if ok and obs and obs.util and obs.util.toggle_checkbox then
                obs.util.toggle_checkbox()
            end
        end, { buffer = true, noremap = true, silent = true })

        -- 智慧動作
        vim.keymap.set("n", "<CR>", function()
            local ok, obs = pcall(require, "obsidian")
            if ok and obs and obs.util and obs.util.smart_action then
                return obs.util.smart_action()
            end
            return "<CR>"
        end, { buffer = true, expr = true, noremap = true, silent = true })
    end,
})

if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    local im_select_path = "im-select-imm.exe"

    vim.api.nvim_create_autocmd("InsertLeave", {
        callback = function()
            os.execute(im_select_path .. " 1033") -- 離開 Insert 模式自動切回英文
        end,
    })
end
