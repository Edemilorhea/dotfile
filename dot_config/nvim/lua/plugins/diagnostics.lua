-- plugins/diagnostics.lua
-- 行內診斷美化，支援長訊息多行換行顯示 (解決筆電窄螢幕看不完問題)
-- 只在純 Neovim 中使用，不影響 VSCode 模式

return {
  -- tiny-inline-diagnostic: 漂亮的行內診斷，支援多行換行
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    cond = not vim.g.vscode,
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup({
        preset = "modern",
        options = {
          -- 顯示診斷來源 (eslint / ts 等)
          show_source = true,
          -- 關鍵：長訊息換多行顯示
          multilines = {
            enabled = true,
            always_show = true, -- 非游標行也展開多行
          },
          -- 游標所在行顯示該行所有診斷
          show_all_diags_on_cursorline = true,
          -- 依視窗寬度自動斷行
          break_line = {
            enabled = true,
          },
        },
      })
    end,
  },

  -- 關閉 LazyVim 內建 virtual_text，避免和外掛重複顯示兩份診斷
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
      },
    },
  },
}
