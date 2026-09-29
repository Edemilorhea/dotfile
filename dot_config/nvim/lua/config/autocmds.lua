-- LazyVim 在 VeryLazy（開啟檔案時會更早）載入本檔。
-- Default autocmds: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local function augroup(name)
    return vim.api.nvim_create_augroup("user_" .. name, { clear = true })
end

-- Markdown：關閉 LazyVim 預設開啟的拼字檢查，並加入 TOC 工具（\mt \mT \mr \mg）。
-- 縮排 4 格由 Neovim 內建的 markdown ftplugin 設定。
vim.api.nvim_create_autocmd("FileType", {
    group = augroup("markdown"),
    pattern = "markdown",
    callback = function(event)
        vim.opt_local.spell = false
        require("config.markdown_toc").set_keymaps(event.buf)
    end,
})

require("config.highlights").setup()

local function convert_line_endings(fileformat)
    vim.cmd([[silent! %s/\r$//e]])
    vim.bo.fileformat = fileformat
    vim.cmd.write()
end

vim.api.nvim_create_user_command("ToCRLF", function()
    convert_line_endings("dos")
end, { desc = "Convert current file to CRLF" })

vim.api.nvim_create_user_command("ToLF", function()
    convert_line_endings("unix")
end, { desc = "Convert current file to LF" })
