return {
    -- blink.cmp：版本、<Tab>（snippet 跳轉 → Copilot 接受）與 Enter 確認都交給 LazyVim 預設。
    {
        "saghen/blink.cmp",
        opts = {
            sources = {
                providers = {
                    lsp = { score_offset = 100 },
                    path = { score_offset = 80 },
                    snippets = { score_offset = 60 },
                    buffer = { score_offset = 0 },
                },
            },
            completion = {
                list = { selection = { preselect = false, auto_insert = false } },
                -- 關閉 auto_brackets：避免對每個 C# 補全項做 semantic 解析判斷是否補括號
                accept = { auto_brackets = { enabled = false } },
            },
            signature = { enabled = true },
        },
    },

    -- Visual 貼上不覆蓋暫存器（與 core/keymaps.lua 一致）。
    -- 必須寫在 yanky 的 keys：yanky 載入時會重設它自己的 p。
    {
        "gbprod/yanky.nvim",
        keys = {
            { "p", "P", mode = "x", desc = "貼上且不覆蓋暫存器" },
        },
    },
}
