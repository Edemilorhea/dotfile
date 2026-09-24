-- 入口只負責分流，兩個環境各自有獨立的載入路徑：
--   lua/core/          兩邊共用：基本選項、編輯習慣 keymap、少量 plugin
--   lua/vscode_mode/   只在 vscode-neovim 內載入（不載入 LazyVim）
--   lua/config/ + lua/plugins/   完整 Neovim（LazyVim）
if vim.g.vscode then
    require("vscode_mode").setup()
else
    require("config.lazy")
end
