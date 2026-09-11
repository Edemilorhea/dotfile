-- plugins/diagnostics.lua
-- 保留診斷資料、側邊標記與底線，但不在程式碼內直接顯示訊息文字。
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
                underline = true,
            },
        },
    },
}
