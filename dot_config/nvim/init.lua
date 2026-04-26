-- 必須在所有載入之前設定 mapleader
-- vim.g.mapleader = "\\"
-- vim.g.maplocalleader = "\\"

-- VSCode 環境最小化載入
if vim.g.vscode then
    -- 通知系統優化（完全停用通知）
    vim.notify = function() end

    -- LSP 清理補丁
    vim.lsp.buf.clear_references = function() end

    -- 最小化插件載入
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    end
    vim.opt.rtp:prepend(lazypath)

    -- 僅載入 VSCode 必需插件
    require("lazy").setup({
        spec = {
            -- 從 plugins.shared 載入 VSCode 兼容插件
            { import = "plugins.shared" },
        },
        defaults = { lazy = true },
        install = { missing = false },
        checker = { enabled = false },
        performance = {
            cache = { enabled = true },
            reset_packpath = true,
            rtp = {
                reset = true,
                disabled_plugins = {
                    "gzip",
                    "matchit",
                    "matchparen",
                    "netrwPlugin",
                    "tarPlugin",
                    "tohtml",
                    "tutor",
                    "zipPlugin",
                    "rplugin",
                    "syntax",
                    "synmenu",
                    "optwin",
                    "compiler",
                    "bugreport",
                    "ftplugin",
                },
            },
        },
    })

    -- 載入 VSCode 基礎設定和快捷鍵
    require("config.options") -- 載入基礎選項設定
    require("keymap.general").setup()
    require("keymap.vscode").setup()

    return -- 提前結束，不執行下面的完整載入
end

-- === 完整 Neovim 環境 ===
-- 初始化 LazyVim (優化版本)
require("config.lazy")

-- === 純 Neovim 環境繼續載入 ===
-- 載入按鍵設定
require("config.keymaps")

-- 注意：plugin.lsp 已停用，改用 LazyVim 原生 LSP 配置
-- 如需自訂 LSP，請在 lua/plugins/lsp.lua 中設定

-- 載入 LSP 診斷工具
-- require("config.lsp-diagnostic")
-- require("config.lsp-performance")

-- 根據系統設定 Neovim / LazyVim 預設 shell
-- Windows: pwsh / powershell
-- Linux / WSL / macOS: zsh -> bash

if vim.fn.has("win32") == 1 then
    -- Windows：優先用 PowerShell 7 (pwsh)，沒有就退回舊 powershell
    if vim.fn.executable("pwsh") == 1 then
        vim.o.shell = "pwsh"
    else
        vim.o.shell = "powershell"
    end

    -- 官方建議的 PowerShell 參數，避免編碼 / pipe 問題
    -- :help shell-powershell
    vim.o.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned -Command "
        .. "[Console]::InputEncoding=[Console]::OutputEncoding="
        .. "[System.Text.UTF8Encoding]::new();"
        .. "$PSDefaultParameterValues['Out-File:Encoding']='utf8';"

    vim.o.shellredir = "2>&1 | %%{ '$_' } | Out-File %s; exit $LastExitCode"

    vim.o.shellpipe = "2>&1 | %%{ '$_' } | Tee-Object %s; exit $LastExitCode"

    vim.o.shellquote = ""
    vim.o.shellxquote = ""
else
    -- 非 Windows（Linux / WSL / macOS）：優先用 zsh，沒有就用 bash
    if vim.fn.executable("zsh") == 1 then
        vim.o.shell = "zsh"
    else
        vim.o.shell = "bash"
    end
end

vim.notify("🚀 Neovim 完整環境已啟動")
