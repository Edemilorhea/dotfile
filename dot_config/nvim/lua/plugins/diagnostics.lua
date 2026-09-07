-- plugins/diagnostics.lua
-- 保留診斷資料與側邊標記，但不在程式碼內直接顯示訊息或底線。
-- 只在純 Neovim 中使用，不影響 VSCode 模式

return {
    {
        "neovim/nvim-lspconfig",
        cond = function()
            return not vim.g.vscode
        end,
        opts = {
            diagnostics = {
                virtual_text = false,
                virtual_lines = false,
                underline = false,
            },
        },
    },
}
