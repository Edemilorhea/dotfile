local M = {}

function M.setup()
    -- Buffer 快捷鍵 (只在純 Neovim 環境中設定)
    if not vim.g.vscode then
        vim.keymap.set("n", "<leader>bc", "<cmd>BufferLinePickClose<CR>", {
            desc = "選擇關閉 Buffer",
        })

        -- 移動 buffer 在 bufferline 上的順序（影響 Shift+h/Shift+l cycle 順序）
        vim.keymap.set("n", "<leader>b.", "<cmd>BufferLineMoveNext<CR>", {
            desc = "Buffer 右移",
        })
        vim.keymap.set("n", "<leader>b,", "<cmd>BufferLineMovePrev<CR>", {
            desc = "Buffer 左移",
        })

        -- 數字快跳：\1~\9 跳到 bufferline 上「畫面實際第 N 個」buffer
        -- 用 go_to(i, false) → visible 視覺位置，pin 移到最前時也能正確對應
        for i = 1, 9 do
            vim.keymap.set("n", "<leader>" .. i, function()
                require("bufferline").go_to(i, false)
            end, { desc = "跳到 Buffer " .. i })
        end
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
