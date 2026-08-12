return {
    "mfussenegger/nvim-lint",
    event = "LazyFile",
    opts = {
        events = { "BufWritePost", "BufReadPost" },
        linters_by_ft = {
            fish = { "fish" },
        },
        linters = {
            ["markdownlint-cli2"] = {
                condition = function()
                    return false
                end,
            },
        },
    },
}
