local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {
        -- add LazyVim and import its plugins
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        -- VSCode 環境僅載入必要插件
        vim.g.vscode and { import = "plugins.shared" }
            or {
                -- 結構化插件分類 (按載入順序)
                { import = "plugins.shared" }, -- VSCode + Neovim 共用插件
                { import = "plugins.development" }, -- 開發工具 (兩邊都需要)
                { import = "plugins.neovim-only", cond = not vim.g.vscode }, -- 純 Neovim 插件
                { import = "plugins.ui-restructured", cond = not vim.g.vscode }, -- UI 插件
                { import = "plugins.markdown-enhanced", cond = not vim.g.vscode }, -- Markdown 生態系統
                -- 其他插件 (向後相容性)
                { import = "plugins" },
            },
    },
    defaults = {
        -- 啟用 lazy loading 以提升啟動速度
        lazy = true,
        -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
        -- have outdated releases, which may break your Neovim install.
        version = false, -- always use the latest git commit
        -- version = "*", -- try installing the latest stable version for plugins that support semver
    },
    install = {
        colorscheme = { "tokyonight", "habamax" },
        missing = true,
    },
    checker = {
        enabled = not vim.g.vscode, -- 在 VSCode 中停用更新檢查
        notify = false,
    },
    performance = {
        cache = {
            enabled = true,
        },
        reset_packpath = true, -- reset the package path to improve startup time
        rtp = {
            reset = true, -- reset the runtime path to $VIMRUNTIME and your config directory
            -- disable some rtp plugins
            disabled_plugins = {
                "gzip",
                "matchit",
                "matchparen",
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
                "rplugin", -- disable rplugin.vim loading
                "syntax", -- disable syntax.vim loading
                "synmenu", -- disable synmenu.vim loading
                "optwin", -- disable optwin.vim loading
                "compiler", -- disable compiler.vim loading
                "bugreport", -- disable bugreport.vim loading
                "ftplugin", -- disable ftplugin.vim loading (performance improvement)
            },
        },
    },
})
