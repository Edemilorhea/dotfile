return {
    "mfussenegger/nvim-lint",
    event = "LazyFile",
    opts = {
        -- Event to trigger linters
        events = { "BufWritePost", "BufReadPost", "InsertLeave" },
        linters_by_ft = {
            fish = { "fish" },
            markdown = {}, -- 改為空陣列，關閉 markdown linting
            -- 或者直接刪除這一行：
            -- markdown = { "markdownlint-cli2" },
        },
        -- LazyVim extension to easily override linter options
        -- or add custom linters.
        ---@type table<string,table>
        linters = {},
    },
}
