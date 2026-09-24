-- LazyVim 在載入 plugin 之前執行本檔，時機晚於 LazyVim 的預設選項。
-- Default options: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
require("core.options").setup()

-- ESLint LSP 預設啟用，但只在專案有 ESLint 設定時啟動 client（見 plugins/lsp.lua）。
vim.g.eslint_enabled = true

-- LazyVim.root() 只認「開啟 Neovim 時的工作目錄」。
-- 預設值是 { "lsp", { ".git", "lua" }, "cwd" }，會往上找 .git/lua 而跳到父層專案根目錄，
-- 導致 Dashboard 的 Find File、\ff、\e 等 root 導向功能搜到目前資料夾以外的檔案。
-- 改成純 cwd 後，所有走 LazyVim.pick / LazyVim.root 的入口語意一致。
vim.g.root_spec = { "cwd" }

vim.opt.winborder = "rounded"

vim.g.markdown_fenced_languages = {
    "csharp=cs",
    "cs",
    "python",
    "javascript",
    "bash=sh",
}

-- 啟動時就把 mason bin 加入 PATH，避免 mason 延遲載入時
-- tree-sitter-cli 等工具在 :checkhealth（未開專案時 mason 未載入）找不到。
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if vim.fn.isdirectory(mason_bin) == 1 and not string.find(vim.env.PATH or "", mason_bin, 1, true) then
    vim.env.PATH = mason_bin .. (vim.fn.has("win32") == 1 and ";" or ":") .. vim.env.PATH
end

-- :! 與 :make 使用的 shell。Windows 設定依照 :help shell-powershell 與 :help shell-pwsh。
if vim.fn.has("win32") == 1 then
    local pwsh = vim.fn.executable("pwsh") == 1
    vim.o.shell = pwsh and "pwsh" or "powershell"
    vim.o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command "
        .. "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();"
        .. "$PSDefaultParameterValues['Out-File:Encoding']='utf8';"
        .. (pwsh and "$PSStyle.OutputRendering='PlainText';" or "")
    vim.o.shellpipe = "> %s 2>&1"
    vim.o.shellquote = ""
    vim.o.shellxquote = ""
    vim.o.shelltemp = false
    if pwsh then
        vim.env.__SuppressAnsiEscapeSequences = "1"
    end
else
    vim.o.shell = vim.fn.executable("zsh") == 1 and "zsh" or "bash"
end

-- \rr 重啟後還原 Session：必須在 VimEnter 之前註冊，所以放在這裡而不是 keymaps.lua。
require("config.restart").restore_pending_session()
