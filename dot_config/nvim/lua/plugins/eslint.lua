-- lua/plugins/eslint.lua
-- ESLint 預設啟用；nvim-lspconfig 只會在找到 ESLint 設定的專案啟動 client。
-- 可用 \uE / :EslintToggle 暫時停用或重新啟用。

return {
    {
        "neovim/nvim-lspconfig",
        cond = function()
            return not vim.g.vscode
        end,
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.eslint = opts.servers.eslint or {}
            opts.servers.eslint.enabled = true
        end,
    },
}
