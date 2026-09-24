require("core.bootstrap")()

require("lazy").setup({
    spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        -- LazyVim extras 由 lazyvim.json 管理（:LazyExtras）。
        { import = "core.plugins" }, -- 與 VSCode 共用的 plugin
        { import = "plugins" }, -- lua/plugins/*.lua：只在 Neovim 使用
    },
    -- 沒有 plugin 需要 luarocks；停用可避免 :checkhealth 的 hererocks 警告。
    rocks = { enabled = false },
    defaults = {
        lazy = true,
        -- 很多 plugin 的 release 過舊，LazyVim 建議追最新 commit。
        version = false,
    },
    install = { colorscheme = { "rose-pine-moon", "tokyonight-night", "habamax" } },
    checker = { enabled = true, notify = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "netrwPlugin",
                "rplugin",
                "tarPlugin",
                "tutor",
                "zipPlugin",
            },
        },
    },
})
