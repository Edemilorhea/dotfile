-- LazyVim LSP 覆寫。C# / Roslyn 在 plugins/csharp.lua。
return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            -- 保留診斷資料、側邊標記與底線，但不在程式碼內顯示訊息文字（\xx 查看本行診斷）
            diagnostics = {
                virtual_text = false,
                virtual_lines = false,
                underline = true,
            },
            -- 預設不顯示 inlay hints；需要時用 \uh 切換，或 \ih 暫時顯示 3 秒
            inlay_hints = { enabled = false },
            -- 摺疊交給 nvim-ufo（plugins/editor.lua），不讓 LSP 另外設定 foldexpr
            folds = { enabled = false },
            servers = {
                -- ESLint 預設啟用；nvim-lspconfig 只會在找到 ESLint 設定的專案啟動 client。
                -- 可用 \uE / :EslintToggle 暫時停用（config/keymaps.lua）。
                eslint = { enabled = true },
            },
        },
    },
}
