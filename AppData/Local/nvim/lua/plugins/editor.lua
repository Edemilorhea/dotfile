-- plugins/editor.lua
-- 此檔案已重構，插件已分類到 shared.lua 和 neovim-only.lua
-- 保留此檔案以維持相容性，但實際插件在新檔案中

-- 提示訊息：插件已重新組織
if vim.g.vscode then
    vim.defer_fn(function()
        print("✨ VSCode 環境已啟用 shared 插件")
    end, 500)
else
    vim.defer_fn(function()
        print("🚀 Neovim 環境已啟用全套插件")
    end, 500)
end

-- 為了向後相容，返回空表
return {}
