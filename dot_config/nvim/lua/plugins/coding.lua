-- 列出目前檔案類型可用的 snippet（prefix + 說明 + 預覽），不必記 prefix。
-- 資料來源與 blink.cmp 相同：friendly-snippets 與 stdpath("config")/snippets。
local function pick_snippets()
    local ft = vim.bo.filetype
    local registry = require("blink.cmp.sources.snippets.default.registry").new({})
    local snippets = registry:get_snippets_for_ft(ft)
    vim.list_extend(snippets, registry:get_global_snippets())

    local items = {}
    for _, s in ipairs(snippets) do
        local body = type(s.body) == "table" and table.concat(s.body, "\n") or s.body
        local desc = s.description ~= s.prefix and s.description or ""
        table.insert(items, {
            text = s.prefix .. " " .. desc,
            prefix = s.prefix,
            desc = desc,
            body = body,
            preview = { text = body, ft = ft },
        })
    end
    table.sort(items, function(a, b)
        return a.prefix < b.prefix
    end)

    Snacks.picker({
        title = "Snippets (" .. ft .. ")",
        items = items,
        preview = "preview",
        format = function(item)
            return { { item.prefix, "Function" }, { "  " }, { item.desc, "Comment" } }
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then
                return
            end
            vim.schedule(function()
                local ok, body = pcall(registry.expand_vars, registry, item.body, os.time())
                vim.snippet.expand(ok and body or item.body)
            end)
        end,
    })
end

return {
    {
        "folke/snacks.nvim",
        keys = {
            { "<leader>sy", pick_snippets, desc = "Snippets（目前檔案類型）" },
        },
    },

    -- blink.cmp：版本與 Enter 確認交給 LazyVim 預設。
    {
        "saghen/blink.cmp",
        opts = {
            keymap = {
                -- <Tab>：有選單時接受 → snippet 下一欄 → Copilot 建議 → 一般 Tab。
                -- 自訂 <Tab> 後 LazyVim 不再注入 snippet/AI 行為，所以在這裡補上。
                ["<Tab>"] = {
                    "select_and_accept",
                    function(cmp)
                        return LazyVim.cmp.map({ "snippet_forward", "ai_nes", "ai_accept" })(cmp)
                    end,
                    "fallback",
                },
            },
            sources = {
                providers = {
                    lsp = { score_offset = 100 },
                    path = { score_offset = 80 },
                    snippets = { score_offset = 60 },
                    buffer = { score_offset = 0 },
                },
            },
            completion = {
                list = { selection = { preselect = false, auto_insert = false } },
                -- 關閉 auto_brackets：避免對每個 C# 補全項做 semantic 解析判斷是否補括號
                accept = { auto_brackets = { enabled = false } },
            },
            signature = { enabled = true },
        },
    },

    -- Visual 貼上不覆蓋暫存器（與 core/keymaps.lua 一致）。
    -- 必須寫在 yanky 的 keys：yanky 載入時會重設它自己的 p。
    {
        "gbprod/yanky.nvim",
        keys = {
            { "p", "P", mode = "x", desc = "貼上且不覆蓋暫存器" },
        },
    },
}
