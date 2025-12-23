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

vim.notify("🚀 Neovim 完整環境已啟動")
