-- core/options.lua
local opt = vim.opt
local g = vim.g
local bo = vim.bo
local wo = vim.wo

vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- ESLint LSP 開關 (預設關閉,用 \uE 或 :EslintToggle 即時切換)
vim.g.eslint_enabled = false

-- 啟動時即把 mason bin 加入 PATH，避免 mason 延遲載入時
-- tree-sitter-cli 等工具在 :checkhealth（未開專案時 mason 未載入）找不到
if not g.vscode then
    local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
    if vim.fn.isdirectory(mason_bin) == 1 and not string.find(vim.env.PATH or "", mason_bin, 1, true) then
        vim.env.PATH = mason_bin .. (vim.fn.has("win32") == 1 and ";" or ":") .. vim.env.PATH
    end
end

vim.g.markdown_fenced_languages = {
    "csharp=cs",
    "cs",
    "python",
    "javascript",
    "bash=sh",
}

opt.number = true
wo.relativenumber = true
-- 不再設 syntax="on"，避免與 treesitter 雙重高亮（純 Neovim 用 treesitter，VSCode 用內建高亮）
opt.clipboard = "unnamedplus"
opt.ignorecase = true
opt.smartcase = true
opt.backup = false

-- 縮排設定（4 格空白）
opt.tabstop = 4 -- Tab 字元顯示寬度
opt.shiftwidth = 4 -- 自動縮排寬度
opt.softtabstop = 4 -- 編輯時 Tab 的行為寬度（新增）
opt.expandtab = true -- 將 Tab 轉換為空格

opt.encoding = "utf-8"
opt.fileencodings = "utf-8,big5,gbk,gb18030,gb2312,ucs-bom,cp936,euc-jp,euc-kr,shift-jis,latin1"
opt.langmenu = "zh_TW.UTF-8"
opt.termguicolors = true

if not g.vscode then
    -- fold 顯示改由 nvim-ufo 接管（見 lua/plugins/neovim-only.lua）。
    -- 不再設 foldmethod="expr" / foldexpr / foldtext，避免與 ufo provider 衝突
    -- 以及 treesitter foldtext 在 JSX/TSX 巢狀表達式回傳空字串的問題。
    opt.foldcolumn = "1"
    opt.foldlevel = 99
    opt.foldlevelstart = 99
    opt.foldenable = true
end

-- 延遲載入縮排設定以加速啟動
vim.defer_fn(function()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        callback = function()
            vim.bo.tabstop = 4
            vim.bo.shiftwidth = 4
            vim.bo.softtabstop = 4
            vim.bo.expandtab = true
        end,
    })
end, 50)

-- 剪貼簿改由 Neovim 自動偵測 provider，不再手動指定 PowerShell（避免每次 yank/paste 啟動行程造成卡頓）：
--   Windows → win32yank.exe（需自行安裝並加入 PATH）
--   WSL/SSH → 同樣安裝 win32yank.exe 可直接走 Windows 剪貼簿
--   原生 Linux → wl-copy/wl-paste（Wayland）或 xclip/xsel（X11）
