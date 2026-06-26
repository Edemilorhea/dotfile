-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--#region

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.opt_local.spell = false
    end,
})

-- Markdown 檔案使用 2 格縮排
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "md" },
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.bo.softtabstop = 4
        vim.bo.expandtab = true
    end,
})

-- Markdown 智慧動作
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        -- 跟隨連結
        vim.keymap.set("n", "gf", function()
            local ok, obs = pcall(require, "obsidian")
            if ok and obs and obs.util and obs.util.gf_passthrough then
                return obs.util.gf_passthrough()
            end
            return "gf"
        end, { buffer = true, expr = true, noremap = true, silent = true })

        -- 切換複選框
        vim.keymap.set("n", "<leader>ch", function()
            local ok, obs = pcall(require, "obsidian")
            if ok and obs and obs.util and obs.util.toggle_checkbox then
                obs.util.toggle_checkbox()
            end
        end, { buffer = true, noremap = true, silent = true })

        -- 智慧動作
        vim.keymap.set("n", "<CR>", function()
            local ok, obs = pcall(require, "obsidian")
            if ok and obs and obs.util and obs.util.smart_action then
                return obs.util.smart_action()
            end
            return "<CR>"
        end, { buffer = true, expr = true, noremap = true, silent = true })
    end,
})

-- LspAttach 時強制關閉 inlay hints（預設不顯示，用 <C-c><C-c> 手動開關）
-- 延遲執行確保在 LazyVim 啟用之後再關閉
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
                vim.lsp.inlay_hint.enable(false, { bufnr = args.buf })
            end
        end, 100)
    end,
})

if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    local im_select_path = "im-select.exe"

    -- 僅在 im-select.exe 存在於 PATH 時註冊，避免未安裝的機器報 E475
    if vim.fn.executable(im_select_path) == 1 then
        vim.api.nvim_create_autocmd("InsertLeave", {
            callback = function()
                -- 非阻塞呼叫，避免每次離開 Insert 模式同步 spawn 行程凍結 UI
                vim.fn.jobstart({ im_select_path, "1033" }, { detach = true })
            end,
        })
    end
end

-- Snacks indent 配色:彩虹縮排整體調暗(每層仍不同色)+ scope 線青色突出
local function set_indent_hl()
    local ok, p = pcall(require, "rose-pine.palette")
    if not ok then
        return
    end
    -- 把顏色往背景混,降低亮度/飽和 → 變低調
    local function blend(c1, c2, t)
        local function split(h)
            h = h:gsub("#", "")
            return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
        end
        local r1, g1, b1 = split(c1)
        local r2, g2, b2 = split(c2)
        return string.format(
            "#%02x%02x%02x",
            math.floor(r1 + (r2 - r1) * t + 0.5),
            math.floor(g1 + (g2 - g1) * t + 0.5),
            math.floor(b1 + (b2 - b1) * t + 0.5)
        )
    end
    local dim = function(c)
        return blend(c, p.base, 0.45)
    end
    -- 非當前彩虹層:每層不同色但整體變暗、低調
    vim.api.nvim_set_hl(0, "SnacksIndent1", { fg = dim(p.love) }) -- 玫紅
    vim.api.nvim_set_hl(0, "SnacksIndent2", { fg = dim(p.gold) }) -- 金
    vim.api.nvim_set_hl(0, "SnacksIndent3", { fg = dim(p.rose) }) -- 粉橘
    vim.api.nvim_set_hl(0, "SnacksIndent4", { fg = dim(p.pine) }) -- 藍
    vim.api.nvim_set_hl(0, "SnacksIndent5", { fg = dim(p.foam) }) -- 青
    vim.api.nvim_set_hl(0, "SnacksIndent6", { fg = dim(p.iris) }) -- 紫
    -- 當前 scope 線:亮青色加粗,最突出
    vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = p.foam, bold = true })
    vim.api.nvim_set_hl(0, "SnacksIndentChunk", { fg = p.foam, bold = true })
end

vim.api.nvim_create_autocmd("ColorScheme", { pattern = "rose-pine*", callback = set_indent_hl })
set_indent_hl() -- 啟動時立即套用
