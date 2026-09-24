-- 只在 vscode-neovim 內使用的 keymap：把動作交給 VSCode 指令。
-- 鍵位盡量與完整 Neovim（LazyVim + lua/config/keymaps.lua）一致，Rider 的 ideavimrc 也照同一套。
local M = {}

function M.setup()
    local ok, vscode = pcall(require, "vscode")
    if not ok then
        vim.notify("vscode-neovim 的 vscode 模組無法載入，略過 VSCode keymap", vim.log.levels.WARN)
        return
    end

    local map = vim.keymap.set

    ---@param mode string|string[]
    ---@param maps table<string, string|{ [1]: string, desc: string, args?: table|fun(): table }>
    ---@param call? boolean 同步呼叫（等 VSCode 完成才繼續）
    local function bind(mode, maps, call)
        for lhs, spec in pairs(maps) do
            local command, desc, args = spec, nil, nil
            if type(spec) == "table" then
                command, desc, args = spec[1], spec.desc, spec.args
            end
            map(mode, lhs, function()
                local opts = args and { args = type(args) == "function" and args() or args } or nil
                if call then
                    vscode.call(command, opts)
                else
                    vscode.action(command, opts)
                end
            end, { desc = desc })
        end
    end

    map("n", "<Esc>", "<Esc><cmd>nohlsearch<CR>", { silent = true, desc = "清除搜尋高亮" })
    map("i", "<C-[>", "<Esc>")

    -- ── 程式碼導航（同 LazyVim LSP keymap）──────────
    bind("n", {
        gd = "editor.action.revealDefinition",
        gD = "editor.action.revealDeclaration",
        gy = "editor.action.goToTypeDefinition",
        gI = "editor.action.goToImplementation",
        gr = "editor.action.goToReferences",
        gK = "editor.action.triggerParameterHints",
    }, true)

    bind("n", {
        ["]]"] = { "editor.action.wordHighlight.next", desc = "下一個參照" },
        ["[["] = { "editor.action.wordHighlight.prev", desc = "上一個參照" },
        ["]d"] = { "editor.action.marker.next", desc = "下一個診斷" },
        ["[d"] = { "editor.action.marker.prev", desc = "上一個診斷" },
        ["<leader>ss"] = { "workbench.action.gotoSymbol", desc = "目前檔案符號" },
        ["<leader>sS"] = { "workbench.action.showAllSymbols", desc = "工作區符號" },
        ["<leader>ca"] = { "editor.action.quickFix", desc = "Code Action" },
        ["<leader>cr"] = { "editor.action.rename", desc = "重新命名" },
        ["<leader>cf"] = { "editor.action.formatDocument", desc = "格式化" },
        ["<leader>xx"] = { "editor.action.showHover", desc = "顯示本行診斷" },
        ["<leader>xX"] = { "workbench.actions.view.problems", desc = "問題清單" },
    })
    -- VSCode 的 renameFile 只作用在檔案總管的選取項目，所以先在總管中定位目前檔案
    map("n", "<leader>cR", function()
        vscode.call("workbench.files.action.showActiveFileInExplorer")
        vscode.action("renameFile")
    end, { desc = "重新命名檔案" })

    bind("x", {
        ["<leader>cf"] = { "editor.action.formatSelection", desc = "格式化選取範圍" },
    })

    -- S：Neovim 用 treesitter 選取語法節點；VSCode 對應 Smart Select（flash 的 S 已在 vscode_mode/init.lua 停用）
    bind({ "n", "x" }, {
        S = { "editor.action.smartSelect.expand", desc = "擴大語法選取" },
    })

    -- ── 分頁（同 bufferline / LazyVim buffer keymap）──
    bind("n", {
        ["]b"] = { "workbench.action.nextEditorInGroup", desc = "下一個分頁" },
        ["[b"] = { "workbench.action.previousEditorInGroup", desc = "上一個分頁" },
        ["<leader>bd"] = { "workbench.action.closeActiveEditor", desc = "關閉分頁" },
        ["<leader>bo"] = { "workbench.action.closeOtherEditors", desc = "關閉其他分頁" },
        ["<leader>bl"] = { "workbench.action.closeEditorsToTheLeft", desc = "關閉左側分頁" },
        ["<leader>br"] = { "workbench.action.closeEditorsToTheRight", desc = "關閉右側分頁" },
        ["<leader>b."] = { "workbench.action.moveEditorRightInGroup", desc = "分頁右移" },
        ["<leader>b,"] = { "workbench.action.moveEditorLeftInGroup", desc = "分頁左移" },
    })
    for i = 1, 9 do
        bind("n", { ["<leader>" .. i] = { "workbench.action.openEditorAtIndex" .. i, desc = "跳到第 " .. i .. " 個分頁" } })
    end

    -- ── 視窗（編輯器群組）────────────────────────────
    bind("n", {
        ["<C-h>"] = { "workbench.action.focusLeftGroup", desc = "切到左側群組" },
        ["<C-j>"] = { "workbench.action.focusBelowGroup", desc = "切到下方群組" },
        ["<C-k>"] = { "workbench.action.focusAboveGroup", desc = "切到上方群組" },
        ["<C-l>"] = { "workbench.action.focusRightGroup", desc = "切到右側群組" },
        ["<leader>sv"] = { "workbench.action.splitEditorRight", desc = "垂直分割" },
        ["<leader>sh"] = { "workbench.action.splitEditorDown", desc = "水平分割" },
        ["<leader>sx"] = { "workbench.action.closeEditorsAndGroup", desc = "關閉分割" },
        ["<leader>wm"] = { "workbench.action.toggleMaximizeEditorGroup", desc = "最大化目前群組" },
    })

    -- ── 搜尋 / 檔案 / 工具 ───────────────────────────
    bind("n", {
        ["<leader>ff"] = { "workbench.action.quickOpen", desc = "搜尋檔案" },
        ["<leader><space>"] = { "workbench.action.quickOpen", desc = "搜尋檔案" },
        ["<leader>fb"] = { "workbench.action.showAllEditors", desc = "搜尋已開分頁" },
        ["<leader>fr"] = { "workbench.action.openRecent", desc = "最近開啟" },
        ["<leader>fg"] = { "workbench.action.findInFiles", desc = "全文搜尋" },
        ["<leader>sg"] = { "workbench.action.findInFiles", desc = "全文搜尋" },
        ["<leader>/"] = { "workbench.action.findInFiles", desc = "全文搜尋" },
        ["<leader>fw"] = {
            "workbench.action.findInFiles",
            desc = "搜尋游標文字",
            args = function()
                return { query = vim.fn.expand("<cword>") }
            end,
        },
        ["<leader>fn"] = { "workbench.action.files.newUntitledFile", desc = "新增檔案" },
        ["<leader>e"] = { "workbench.files.action.showActiveFileInExplorer", desc = "在檔案總管顯示" },
        ["<leader>sr"] = { "editor.action.startFindReplaceAction", desc = "取代" },
        ["<leader>tt"] = { "workbench.action.terminal.toggleTerminal", desc = "切換終端機" },
        ["<leader>ft"] = { "workbench.action.terminal.toggleTerminal", desc = "切換終端機" },
        ["<leader>tc"] = { "workbench.action.terminal.new", desc = "新增終端機" },
    })

    -- ── 摺疊（Neovim 原生 z 系列）─────────────────────
    bind("n", {
        zM = "editor.foldAll",
        zR = "editor.unfoldAll",
        zc = "editor.fold",
        zC = "editor.foldRecursively",
        zo = "editor.unfold",
        zO = "editor.unfoldRecursively",
        za = "editor.toggleFold",
        zj = "editor.gotoNextFold",
        zk = "editor.gotoPreviousFold",
    })

    -- VSCode 獨有：收合到第 N 層。三個編輯器的層級摺疊邏輯不同，刻意不統一。
    for i = 1, 7 do
        bind("n", { ["z" .. i] = "editor.foldLevel" .. i })
    end
end

return M
