-- 自訂配色：縮排線、浮動視窗、TypeScript 與 C# 語意上色。
-- 全部掛在 ColorScheme 事件上，切換 colorscheme 後覆寫才不會被洗掉。
local M = {}

-- Snacks indent 配色：彩虹縮排整體調暗（每層仍不同色）+ scope 線青色突出
local function set_indent_hl()
    local ok, p = pcall(require, "rose-pine.palette")
    if not ok then
        return
    end
    -- 把顏色往背景混，降低亮度/飽和 → 變低調
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
    -- 非當前彩虹層：每層不同色但整體變暗、低調
    vim.api.nvim_set_hl(0, "SnacksIndent1", { fg = dim(p.love) }) -- 玫紅
    vim.api.nvim_set_hl(0, "SnacksIndent2", { fg = dim(p.gold) }) -- 金
    vim.api.nvim_set_hl(0, "SnacksIndent3", { fg = dim(p.rose) }) -- 粉橘
    vim.api.nvim_set_hl(0, "SnacksIndent4", { fg = dim(p.pine) }) -- 藍
    vim.api.nvim_set_hl(0, "SnacksIndent5", { fg = dim(p.foam) }) -- 青
    vim.api.nvim_set_hl(0, "SnacksIndent6", { fg = dim(p.iris) }) -- 紫
    -- 當前 scope 線：亮青色加粗，最突出
    vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = p.foam, bold = true })
    vim.api.nvim_set_hl(0, "SnacksIndentChunk", { fg = p.foam, bold = true })
end

local function set_float_hl()
    local background = "#2A2D34"
    local border = "#9CCFD8"

    vim.api.nvim_set_hl(0, "NormalFloat", { bg = background })
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = border, bg = background })
    vim.api.nvim_set_hl(0, "FloatTitle", { fg = border, bg = background, bold = true })
    vim.api.nvim_set_hl(0, "FloatFooter", { fg = border, bg = background })
    vim.api.nvim_set_hl(0, "SnacksNotifierHistory", { link = "NormalFloat" })

    for _, group in ipairs({ "NoicePopup", "NoicePopupmenu", "NoiceCmdlinePopup", "NoiceConfirm" }) do
        vim.api.nvim_set_hl(0, group, { link = "NormalFloat" })
        vim.api.nvim_set_hl(0, group .. "Border", { link = "FloatBorder" })
    end

    for _, level in ipairs({ "Trace", "Debug", "Info", "Warn", "Error" }) do
        vim.api.nvim_set_hl(0, "SnacksNotifier" .. level, { link = "NormalFloat" })
        vim.api.nvim_set_hl(0, "SnacksNotifierBorder" .. level, { link = "FloatBorder" })
    end
end

-- C#（Roslyn LSP）語意上色，配色參考 JetBrains Rider。
--
-- Roslyn 對非 Visual Studio 客戶端送的是 pure LSP token set：除了標準 type 之外，還有一批
-- C# 專屬的自訂 type（controlKeyword、field、recordClass、extensionMethod ...）。Neovim 的
-- 預設連結和 rose-pine 都沒有涵蓋這些名稱，對應的 highlight group 是空的，那些區段就掉回
-- Normal，看起來像完全沒上色。
--
-- token type 名稱取自 dotnet/roslyn 的 CustomLspSemanticTokenNames.cs 與 SemanticTokensSchema.cs，
-- 不是猜的；拼錯的話會靜默失效，看不出差別。
--
-- LSP semantic token 的 extmark priority 是 125，treesitter 是 100。凡是 treesitter 已經處理得
-- 夠好的 type，這裡一律設成空表清掉，讓既有主題與 @keyword / @comment 那組設定繼續生效。
local csharp_palette = {
    type = "#4EC9B0", -- 型別，沿用 @tag.tsx 的青綠
    method = "#39CC9B", -- 方法，沿用 TS function 的綠
    field = "#9876AA", -- Rider 的欄位紫
    doc = "#629755", -- Rider 的 XML 文件註解綠
    excluded = "#6E6A86", -- #if 排除掉的區塊，rose-pine muted
}

-- Roslyn 也服務 Razor，Razor buffer 的 filetype 是 razor，highlight group 尾綴跟著變，
-- 所以同一份規則要對兩個 filetype 各套一次。
local csharp_filetypes = { "cs", "razor" }

local function set_csharp_hl()
    local c = csharp_palette
    local types = {
        -- C# 專屬 type，完全沒有 fallback
        controlKeyword = { link = "@keyword" },
        operatorOverloaded = { link = "@operator" },
        field = { fg = c.field },
        constant = { fg = c.field, italic = true },
        event = { fg = c.field },
        extensionMethod = { fg = c.method, italic = true },
        delegate = { fg = c.type },
        recordClass = { fg = c.type },
        recordStruct = { fg = c.type },
        array = { fg = c.type },
        pointer = { fg = c.type },
        functionPointer = { fg = c.type },
        module = { link = "@module" },
        label = { link = "@label" },
        stringVerbatim = { link = "@string" },
        stringEscapeCharacter = { link = "@string.escape" },
        preprocessorText = { link = "@comment" },
        excludedCode = { fg = c.excluded },

        -- 標準 type，但 Neovim 的預設連結給得太保守
        class = { fg = c.type },
        struct = { fg = c.type },
        enum = { fg = c.type },
        interface = { fg = c.type, italic = true },
        typeParameter = { fg = c.type, italic = true },
        method = { fg = c.method },

        -- 交回 treesitter 處理
        variable = {},
        parameter = {},
        property = {},
        namespace = {},
        string = {},
        number = {},
        operator = {},
        comment = {},
        punctuation = {},
        whitespace = {},
        text = {},
        testCodeMarkdown = {},
    }

    -- 修飾詞的 extmark priority 比 type 高，只設樣式不設顏色就能疊加上去。
    -- Rider 會把棄用的符號加刪節線、被重新賦值的變數加底線。
    local mods = {
        deprecated = { strikethrough = true },
        reassignedVariable = { underline = true },
    }

    -- /// <summary> 這類 XML 文件註解
    local xml_doc = {
        "Text",
        "Name",
        "Delimiter",
        "AttributeName",
        "AttributeQuotes",
        "AttributeValue",
        "CDataSection",
        "Comment",
        "EntityReference",
        "ProcessingInstruction",
    }
    for _, name in ipairs(xml_doc) do
        types["xmlDocComment" .. name] = { fg = c.doc, italic = true }
    end

    -- Regex 字面值內部的著色
    local regex = {
        Text = "@string",
        Comment = "@comment",
        CharacterClass = "@string.escape",
        Anchor = "@string.escape",
        Quantifier = "@string.escape",
        Grouping = "@string.escape",
        Alternation = "@string.escape",
        SelfEscapedCharacter = "@string.escape",
        OtherEscape = "@string.escape",
    }
    for name, link in pairs(regex) do
        types["regex" .. name] = { link = link }
    end

    for _, ft in ipairs(csharp_filetypes) do
        for name, spec in pairs(types) do
            vim.api.nvim_set_hl(0, "@lsp.type." .. name .. "." .. ft, spec)
        end
        for name, spec in pairs(mods) do
            vim.api.nvim_set_hl(0, "@lsp.mod." .. name .. "." .. ft, spec)
        end
    end
end

-- 通用與 TypeScript/TSX 的 JetBrains 風格上色。
local function set_lang_hl()
    local groups = {
        ["@keyword"] = { fg = "#6C95EB" },
        ["@keyword.conditional"] = { fg = "#6C95EB" },
        ["@keyword.return"] = { fg = "#6C95EB" },
        ["@keyword.import"] = { fg = "#6C95EB" },
        ["@keyword.tsx"] = { fg = "#6C95EB" },
        ["@keyword.conditional.tsx"] = { fg = "#6C95EB" },
        ["@keyword.return.tsx"] = { fg = "#6C95EB" },
        ["@lsp.typemod.function.declaration.typescript"] = { fg = "#FEFEFE" },
        ["@lsp.type.function.typescript"] = { fg = "#39CC9B" },
        ["@lsp.type.function.typescriptreact"] = { fg = "#39CC9B" },
        ["@function.call.tsx"] = { fg = "#39CC9B" },
        ["@tag.attribute.tsx"] = { fg = "#6C95EB" },
        ["@tag.tsx"] = { fg = "#4EC9B0" },
        ["@tag.builtin.tsx"] = { fg = "#4EC9B0" },
        ["@comment"] = { fg = "#85BA59", italic = true },
    }
    for group, spec in pairs(groups) do
        vim.api.nvim_set_hl(0, group, spec)
    end
end

local function set_syntax_hl()
    set_lang_hl()
    set_csharp_hl()
end

function M.setup()
    local group = vim.api.nvim_create_augroup("user_highlights", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, pattern = "rose-pine*", callback = set_indent_hl })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
            vim.schedule(set_float_hl)
        end,
    })
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_syntax_hl })

    -- 啟動時主題已經套用完成，立即補上一次
    set_indent_hl()
    vim.schedule(set_float_hl)
    set_syntax_hl()
end

return M
