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

-- 離開 Insert 模式時把輸入法切回英文。
-- 優先使用 PATH 上的 im-select.exe，其次使用設定目錄內的 im-select-imm.exe。
if vim.fn.has("win32") == 1 then
    local im_select = vim.fn.exepath("im-select.exe")
    if im_select == "" then
        local bundled = vim.fn.stdpath("config") .. "/im-select-imm.exe"
        im_select = vim.fn.executable(bundled) == 1 and bundled or ""
    end
    if im_select ~= "" then
        vim.api.nvim_create_autocmd("InsertLeave", {
            group = augroup("im_select"),
            callback = function()
                -- 非阻塞呼叫，避免每次離開 Insert 模式同步 spawn 行程凍結 UI
                vim.fn.jobstart({ im_select, "1033" }, { detach = true })
            end,
        })
    end
end

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
