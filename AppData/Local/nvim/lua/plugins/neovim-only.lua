-- plugins/neovim-only.lua
-- 只在 Neovim 中使用的插件
return {
    -- 程式碼折疊：已改用 LazyVim 15.x 原生 LSP 折疊
    -- nvim-ufo 已停用，避免與原生功能衝突
    -- 如需啟用 nvim-ufo，請在 lua/plugins/lsp.lua 中設定 folds.enabled = false
    {
        "kevinhwang91/nvim-ufo",
        enabled = false, -- 停用，改用 LazyVim 原生 LSP 折疊
        dependencies = { "kevinhwang91/promise-async" },
        event = "BufReadPost",
        cond = not vim.g.vscode,
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
    -- LazyVim 15.x: 使用 LazyVim 原生的 treesitter 配置
    -- 不需要自訂配置，LazyVim 會自動處理
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "lua", "vim", "vimdoc", "query",
                "html", "javascript", "vue", "css",
                "python", "c_sharp", "typescript",
                "sql", "mermaid", "markdown", "bash",
            },
        },
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