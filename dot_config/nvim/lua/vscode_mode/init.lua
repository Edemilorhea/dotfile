-- vscode-neovim 專用入口：不載入 LazyVim，只載入 lua/core/ 的共用設定與 plugin。
-- 目錄不叫 vscode，是為了避免蓋掉 vscode-neovim 提供的 require("vscode") 模組。
local M = {}

function M.setup()
    require("core.options").setup()
    require("core.bootstrap")()

    require("lazy").setup({
        spec = {
            { import = "core.plugins" },
            -- S 改由 vscode_mode/keymaps.lua 對應 VSCode Smart Select
            { "folke/flash.nvim", keys = { { "S", false, mode = { "n", "x", "o" } } } },
        },
        defaults = { lazy = true },
        -- plugin 由完整 Neovim 負責安裝；VSCode 內不自動安裝或檢查更新。
        install = { missing = false },
        checker = { enabled = false },
        rocks = { enabled = false },
        performance = {
            rtp = {
                disabled_plugins = {
                    "gzip",
                    "matchit",
                    "matchparen",
                    "netrwPlugin",
                    "rplugin",
                    "tarPlugin",
                    "tutor",
                    "zipPlugin",
                },
            },
        },
    })

    require("core.keymaps").setup()
    require("vscode_mode.keymaps").setup()
end

return M
