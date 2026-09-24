-- LazyVim 在 VeryLazy 載入本檔，時機晚於 LazyVim 的預設 keymap，同一個 lhs 以這裡為準。
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- 例外：plugin spec 的 `keys` 會在該 plugin 載入時重設同一個 lhs。
-- 要覆寫這類 key，請在 plugin spec 用 `{ lhs, false }` 停用（例如 plugins/ui.lua 的 bufferline）。

require("core.keymaps").setup()

local map = vim.keymap.set

-- ── 編輯與剪貼簿 ───────────────────────────────
map({ "n", "x" }, "<C-q>", "<C-v>", { desc = "區塊選取（取代 <C-v>）" })
map({ "i", "c" }, "<C-v>", "<C-r>+", { desc = "貼上系統剪貼簿" })

-- <C-/> 改為註解（LazyVim 預設是開終端機）。<C-_> 是部分終端機送出的 <C-/>。
for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
    pcall(vim.keymap.del, "t", lhs)
    map("n", lhs, "gcc", { remap = true, desc = "註解目前行" })
    map("x", lhs, "gc", { remap = true, desc = "註解選取範圍" })
end

map({ "n", "x" }, "<leader>cf", function()
    require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "格式化" })

-- ── Session / 離開 ─────────────────────────────
map("n", "<leader>rr", function()
    require("config.restart").restart()
end, { desc = "重啟 Neovim 並還原上次 Session" })

-- 單獨的 :q 改為「關 buffer」，最後一個 buffer 才真正退出。
-- 不碰 window 佈局（關分割窗用 \sx），也不影響 :q! :wq :qa 與巨集。
local function smart_quit()
    local listed = vim.tbl_filter(function(buf)
        return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
    if #listed > 1 then
        Snacks.bufdelete()
    else
        vim.cmd("quit")
    end
end

map("c", "<CR>", function()
    if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "q" then
        vim.schedule(smart_quit)
        return "<C-c>"
    end
    return "<CR>"
end, { expr = true, desc = "單獨的 :q 改為關閉 buffer" })

-- ── 視窗分割與取代（覆寫 LazyVim 的 \sh 說明文件搜尋）──
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "垂直分割視窗" })
map("n", "<leader>sh", "<cmd>split<cr>", { desc = "水平分割視窗" })
map("n", "<leader>sx", "<cmd>close<cr>", { desc = "關閉分割視窗" })
map("n", "<leader>sr", ":%s/\\<<C-r><C-w>\\>/", { desc = "取代游標下的字" })
map("x", "<leader>sr", ":s/", { desc = "在選取範圍內取代" })

-- ── 診斷與 LSP ────────────────────────────────
map("n", "<leader>xx", function()
    local _, win = vim.diagnostic.open_float({ scope = "line" })
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
    end
end, { desc = "顯示並進入本行診斷浮窗" })

map("n", "<leader>ih", function()
    local buf = vim.api.nvim_get_current_buf()
    vim.lsp.inlay_hint.enable(true, { bufnr = buf })
    vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(buf) then
            vim.lsp.inlay_hint.enable(false, { bufnr = buf })
        end
    end, 3000)
end, { desc = "臨時顯示 Inlay Hints（3 秒）" })

map("n", "<leader>i.", function()
    local root = LazyVim.root()
    local cwd = vim.fn.getcwd()
    local message = root == cwd and (" " .. root) or (" Root: " .. root .. "\n CWD:  " .. cwd)
    vim.notify(message, vim.log.levels.INFO, { title = "工作目錄" })
end, { desc = "顯示工作目錄路徑" })

-- ESLint LSP 總開關（實際 client 仍由專案的 ESLint 設定決定是否啟動）
vim.api.nvim_create_user_command("EslintToggle", function()
    vim.g.eslint_enabled = not vim.g.eslint_enabled
    if vim.g.eslint_enabled then
        vim.lsp.enable("eslint")
        vim.notify("ESLint 已啟用（僅套用至有 ESLint 設定的專案）", vim.log.levels.INFO)
        return
    end
    vim.lsp.enable("eslint", false)
    -- 清除已附掛 client 的殘留診斷（含 pull diagnostics）
    for _, client in ipairs(vim.lsp.get_clients({ name = "eslint" })) do
        vim.diagnostic.reset(vim.lsp.diagnostic.get_namespace(client.id, true))
        vim.diagnostic.reset(vim.lsp.diagnostic.get_namespace(client.id, false))
    end
    vim.notify("ESLint 已停用", vim.log.levels.WARN)
end, { desc = "切換 ESLint LSP" })

map("n", "<leader>uE", "<cmd>EslintToggle<cr>", { desc = "切換 ESLint LSP" })
