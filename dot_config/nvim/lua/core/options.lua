-- 兩個環境共用的基本選項。
-- Neovim：由 lua/config/options.lua 呼叫，時機晚於 LazyVim 預設值，所以能覆寫它們。
-- VSCode：由 lua/vscode_mode/init.lua 呼叫。
local M = {}

function M.setup()
    vim.g.mapleader = "\\"
    vim.g.maplocalleader = "\\"

    local opt = vim.opt

    opt.fileformats = { "unix", "dos" }
    opt.fileformat = "unix"
    -- ucs-bom 必須在最前面，否則帶 BOM 的檔案會被前面的編碼先吃掉。
    opt.fileencodings = "ucs-bom,utf-8,big5,gb18030,euc-jp,euc-kr,shift-jis,latin1"

    opt.clipboard = "unnamedplus"
    opt.ignorecase = true
    opt.smartcase = true

    -- 預設 4 格空白；個別 filetype 的 ftplugin 或專案的 .editorconfig 仍可覆寫。
    opt.tabstop = 4
    opt.shiftwidth = 4
    opt.softtabstop = 4
    opt.expandtab = true
end

return M
