-- Markdown TOC 工具：在 <!-- TOC --> 與 <!-- /TOC --> 之間產生、更新或移除目錄。
local M = {}

local START = "<!-- TOC -->"
local STOP = "<!-- /TOC -->"

---@return integer? first 0-based 起始行
---@return integer? last  0-based 結束行（不含）
local function find_toc()
    local first
    for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        if not first and line:find(START, 1, true) then
            first = i - 1
        elseif first and line:find(STOP, 1, true) then
            return first, i
        end
    end
end

-- 與 GitHub 相同：轉小寫、移除 ASCII 標點（保留 - 與 _）、空白轉成 -。中文等非 ASCII 字元保留。
local function anchor(title)
    return (title:lower():gsub("[^%w%s%-_\128-\255]", ""):gsub("%s", "-"))
end

---@param style "wiki"|"markdown"
local function build(style)
    local toc = { START }
    for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        local level, title = line:match("^(#+)%s+(.+)")
        if level then
            if style == "wiki" then
                table.insert(toc, ("%s* [[#%s]]"):format(("    "):rep(#level - 1), title))
            else
                table.insert(toc, ("%s- [%s](#%s)"):format(("  "):rep(#level - 1), title, anchor(title)))
            end
        end
    end
    table.insert(toc, STOP)
    return toc
end

---@param style "wiki"|"markdown"
function M.generate(style)
    local toc = build(style)
    local first, last = find_toc()
    if first then
        vim.api.nvim_buf_set_lines(0, first, last, false, toc)
        vim.notify("TOC 已更新")
    else
        table.insert(toc, "")
        vim.api.nvim_buf_set_lines(0, 0, 0, false, toc)
        vim.notify("TOC 已生成")
    end
end

function M.remove()
    local first, last = find_toc()
    if not first then
        vim.notify("未找到 TOC", vim.log.levels.WARN)
        return
    end
    vim.api.nvim_buf_set_lines(0, first, last, false, {})
    vim.notify("TOC 已移除")
end

function M.jump()
    local first = find_toc()
    if not first then
        vim.notify("未找到 TOC", vim.log.levels.WARN)
        return
    end
    vim.api.nvim_win_set_cursor(0, { first + 1, 0 })
end

---@param buf integer
function M.set_keymaps(buf)
    local function map(lhs, fn, desc)
        vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
    end
    map("<leader>mt", function()
        M.generate("wiki")
    end, "生成 Wiki 格式 TOC")
    map("<leader>mT", function()
        M.generate("markdown")
    end, "生成標準 Markdown TOC")
    map("<leader>mr", M.remove, "移除 TOC")
    map("<leader>mg", M.jump, "跳轉到 TOC")
end

return M
