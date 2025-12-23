-- plugins/neovim-only.lua
-- 只在 Neovim 中使用的插件
return {
    -- 程式碼折疊增強
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        event = "BufReadPost",
        cond = not vim.g.vscode,
        config = function()
            require("ufo").setup({
                provider_selector = function(_, _, _)
                    return { "treesitter", "indent" }
                end,
            })

            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
        end,
        keys = {
            {
                "zR",
                function()
                    require("ufo").openAllFolds()
                end,
                desc = "打開所有折疊",
            },
            {
                "zM",
                function()
                    require("ufo").closeAllFolds()
                end,
                desc = "關閉所有折疊",
            },
            {
                "zr",
                function()
                    require("ufo").openFoldsExceptKinds()
                end,
                desc = "打開一層折疊",
            },
            {
                "zm",
                function()
                    require("ufo").closeFoldsWith()
                end,
                desc = "關閉一層折疊",
            },
            {
                "zp",
                function()
                    require("ufo").peekFoldedLinesUnderCursor()
                end,
                desc = "預覽折疊內容",
            },
        },
    },

    -- Markdown 自動列表
    {
        "gaoDean/autolist.nvim",
        ft = { "markdown", "text", "tex", "plaintex", "norg" },
        cond = not vim.g.vscode,
        config = function()
            local autolist = require("autolist")
            autolist.setup()

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "markdown", "text", "tex", "plaintex", "norg" },
                callback = function()
                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc })
                    end

                    map("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>", "Auto continue list")
                    map("n", "<a-r>", "<cmd>AutolistRecalculate<cr>", "Recalculate list")
                    map("n", "cn", autolist.cycle_next_dr, "cycle next list type")
                    map("n", "cp", autolist.cycle_prev_dr, "cycle prev list type")
                    map("n", ">>", ">><cmd>AutolistRecalculate<cr>", "Indent and recalc")
                    map("n", "<<", "<<<cmd>AutolistRecalculate<cr>", "Dedent and recalc")
                    map("n", "dd", function()
                        vim.cmd('normal! "_dd')
                        vim.cmd("AutolistRecalculate")
                    end, "Delete line and recalc")
                    map("v", "p", '"zdP<cmd>AutolistRecalculate<cr>', "Paste without yanking and recalc")
                end,
            })
        end,
    },

    -- Treesitter 語法高亮和解析
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        cond = not vim.g.vscode,
        config = function()
            require("nvim-treesitter.install").prefer_git = true
            require("nvim-treesitter.install").compilers = { "clang", "gcc", "cl", "zig" }

            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "lua", "vim", "vimdoc", "query",
                    "html", "javascript", "vue", "css",
                    "python", "c_sharp", "typescript",
                    "sql", "mermaid", "markdown", "bash",
                },
                sync_install = false,
                auto_install = true,
                ignore_install = {},
                modules = {},
                highlight = {
                    enable = true,
                    disable = function(lang, buf)
                        local max_filesize = 100 * 1024 -- 100 KB
                        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                    end,
                },
                indent = {
                    enable = true,
                },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "gnn",
                        node_incremental = "grn",
                        scope_incremental = "grc",
                        node_decremental = "grm",
                    },
                },
            })
        end,
    },

    -- LazyGit 整合
    {
        "kdheepak/lazygit.nvim",
        cmd = "LazyGit",
        cond = not vim.g.vscode,
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            {
                "<leader>lg",
                "<cmd>LazyGit<CR>",
                desc = "開啟 LazyGit",
            },
        },
        config = function()
            vim.g.lazygit_floating_window_winblend = 0
            vim.g.lazygit_floating_window_scaling_factor = 0.9
            vim.g.lazygit_use_neovim_remote = 1
        end,
    },
}