-- keymap/vscode.lua
local M = {}

function M.setup()
    local vscode = require("vscode")
    local opts = { noremap = true, silent = true }

    -- 基本按鍵映射
    vim.keymap.set("i", "<C-[>", "<Esc>", opts)

    -- 程式碼導航
    local navigation_mappings = {
        { key = "gd", command = "editor.action.revealDefinition" },
        { key = "gy", command = "editor.action.goToTypeDefinition" },
        { key = "gi", command = "editor.action.goToImplementation" },
        { key = "gr", command = "editor.action.goToReferences" },
    }

    for _, map in ipairs(navigation_mappings) do
        vim.keymap.set("n", map.key, function()
            vscode.call(map.command)
        end, opts)
    end

    -- 程式碼摺疊
    local fold_mappings = {
        { key = "zM", command = "editor.foldAll" },
        { key = "zR", command = "editor.unfoldAll" },
        { key = "zc", command = "editor.fold" },
        { key = "zC", command = "editor.foldRecursively" },
        { key = "zo", command = "editor.unfold" },
        { key = "zO", command = "editor.unfoldRecursively" },
        { key = "za", command = "editor.toggleFold" },
        { key = "z1", command = "editor.foldLevel1" },
        { key = "z2", command = "editor.foldLevel2" },
        { key = "z3", command = "editor.foldLevel3" },
        { key = "z4", command = "editor.foldLevel4" },
        { key = "z5", command = "editor.foldLevel5" },
        { key = "z6", command = "editor.foldLevel6" },
        { key = "z7", command = "editor.foldLevel7" },
        { key = "zj", command = "editor.gotoNextFold" },
        { key = "zk", command = "editor.gotoPreviousFold" },
    }

    for _, map in ipairs(fold_mappings) do
        vim.keymap.set("n", map.key, function()
            vscode.action(map.command)
        end, opts)
    end

    -- 視覺行移動（優化版）
    local function visual_line_move(direction)
        return function()
            local count = vim.v.count > 0 and vim.v.count or 1
            vscode.action("cursorMove", {
                args = {
                    to = direction,
                    by = "wrappedLine",
                    value = count,
                },
            })
        end
    end

    vim.keymap.set("n", "j", visual_line_move("down"), opts)
    vim.keymap.set("n", "k", visual_line_move("up"), opts)

    -- 其他功能按鍵
    local other_mappings = {
        { key = "<Leader>qq", command = "workbench.action.findInFiles" },
        { key = "<Leader>xm", command = "workbench.action.terminal.toggleTerminal" },
        { key = "<Leader>xx", command = "editor.action.smartSelect.expand" },
    }

    for _, map in ipairs(other_mappings) do
        vim.keymap.set("n", map.key, function()
            vscode.action(map.command)
        end, opts)
    end

    -- 註解功能
    vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Comment line" })
    vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Comment line" })
    vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Comment selection" })
    vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Comment selection" })

    -- 視窗導航快捷鍵
    vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
    vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
    vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
    vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
end

return M
