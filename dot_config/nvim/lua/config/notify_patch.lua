if vim.g.vscode then
  vim.notify = print
  -- or直接用這個：
  print("這是在 VSCode 顯示的訊息")
else
  vim.notify("這是 Neovim 的 notify")
end