local M = {}

function M.setup()
    -- Buffer 快捷鍵 (只在純 Neovim 環境中設定)
    if not vim.g.vscode then
        vim.keymap.set("n", "<leader>bc", "<cmd>BufferLinePickClose<CR>", {
            desc = "選擇關閉 Buffer",
        })
    end

    -- Flash 快捷鍵
    local flash = require("flash")
    vim.keymap.set({ "n", "x", "o" }, "<leader>hf", flash.jump, {
        silent = true,
        desc = "Flash 跳轉",
    })
    vim.keymap.set({ "n", "x", "o" }, "<leader>hF", flash.treesitter, {
        silent = true,
        desc = "Flash 語法樹跳轉",
    })
    vim.keymap.set({ "o", "x" }, "<leader>hr", flash.treesitter_search, {
        silent = true,
        desc = "語法樹搜尋",
    })
    vim.keymap.set("n", "<leader>he", flash.toggle, {
        silent = true,
        desc = "切換 Flash 搜尋",
    })


    -- LSP 快捷鍵：gd/ca 由 LazyVim 內建處理

    -- 僅為了 WhichKey 顯示用，不重新綁定
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            vim.keymap.set("n", "gnn", "", {
                desc = "初始化選取區塊",
            })
            vim.keymap.set("n", "grn", "", {
                desc = "擴展選取區塊",
            })
            vim.keymap.set("n", "grc", "", {
                desc = "擴展至範圍",
            })
            vim.keymap.set("n", "grm", "", {
                desc = "縮減選取區塊",
            })
        end,
    })

    -- nvim-cmp（補全）
    vim.keymap.set("i", "<C-Space>", "", {
        desc = "觸發補全",
    })
    vim.keymap.set("i", "<C-y>", "", {
        desc = "確認補全 (Ctrl + y)",
    })
end

return M
