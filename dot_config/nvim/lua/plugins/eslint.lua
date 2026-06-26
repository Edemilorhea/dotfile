-- lua/plugins/eslint.lua
-- 需求：預設完全不要 eslint —— 不管專案有沒有 .eslintrc / eslint.config 都一樣。
--       只有手動按 \uE / :EslintToggle 才啟用。
--
-- 作法：用 LspAttach 當「最後一道關卡」。不去管 LazyVim / mason / 內建 config
--       到底用什麼時機、什麼方式啟動 eslint —— 任何 eslint client 要 attach 到
--       buffer，都必經 LspAttach。此時只要 vim.g.eslint_enabled 為 false，就立刻
--       把它停掉並清除殘留診斷。完全不依賴啟用時序，因此 100% 可靠。
--
-- 啟用流程（:EslintToggle）會先把 vim.g.eslint_enabled 設為 true，
-- 之後這個攔截器就會放行，eslint 改由內建 config 正常運作（內建本身就有
-- 「沒有 eslint 設定檔就不啟動」的 gating，不需我們再自訂 root_dir）。

return {
    {
        "neovim/nvim-lspconfig",
        cond = function()
            return not vim.g.vscode
        end,
        init = function()
            vim.api.nvim_create_autocmd("LspAttach", {
                desc = "預設攔停 eslint（除非 :EslintToggle 已開啟）",
                callback = function(args)
                    -- 已手動開啟 → 放行
                    if vim.g.eslint_enabled then
                        return
                    end
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if not client or client.name ~= "eslint" then
                        return
                    end
                    -- 清掉這次 attach 可能已產生的診斷，再強制停掉 client
                    vim.schedule(function()
                        pcall(vim.diagnostic.reset, vim.lsp.diagnostic.get_namespace(client.id, true))
                        pcall(vim.diagnostic.reset, vim.lsp.diagnostic.get_namespace(client.id, false))
                        vim.lsp.stop_client(client.id, true)
                    end)
                end,
            })
        end,
    },
}
