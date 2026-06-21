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
        -- 結構化插件分類 (init.lua 已處理 VSCode 分支，此處只載入 Neovim 插件)
        { import = "plugins.shared" }, -- VSCode + Neovim 共用插件
        { import = "plugins.blink" }, -- blink.cmp 覆寫配置
        { import = "plugins.development" }, -- 開發工具
        { import = "plugins.formatting" }, -- 格式化設定 (conform.nvim)
        { import = "plugins.tools" }, -- 工具插件 (Telescope、浮動終端等)
        { import = "plugins.neovim-only" }, -- 純 Neovim 插件
        { import = "plugins.ui-restructured" }, -- UI 插件
        { import = "plugins.which-key" }, -- which-key 中文化覆寫
        { import = "plugins.markdown-enhanced" }, -- Markdown 生態系統
        { import = "plugins.csharp" }, -- C# roslyn.nvim + nvim-dap 除錯
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
        colorscheme = { "rose-pine-moon", "tokyonight-night", "habamax" },
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
