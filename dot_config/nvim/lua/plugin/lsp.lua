local M = {}

-- 自訂語言伺服器設定
local function get_custom_server_config()
    local ok_ext, omnisharp_extended = pcall(require, "omnisharp_extended")

    return {
        omnisharp = {
            handlers = ok_ext and {
                ["textDocument/definition"] = omnisharp_extended.definition_handler,
                ["textDocument/typeDefinition"] = omnisharp_extended.type_definition_handler,
                ["textDocument/references"] = omnisharp_extended.references_handler,
                ["textDocument/implementation"] = omnisharp_extended.implementation_handler,
            } or nil,
            settings = {
                FormattingOptions = { EnableEditorConfigSupport = true },
                RoslynExtensionsOptions = { EnableAnalyzersSupport = true },
                Sdk = { IncludePrereleases = true },
            },
        },

        -- 新增 marksman 設定
        marksman = {
            root_dir = require("lspconfig.util").root_pattern(
                ".obsidian",
                ".markdownlintrc",
                ".git",
                ".markdownlint.json",
                ".markdownlint.yaml"
            ),
            settings = {},
            filetypes = { "markdown" },
        },
    }
end

-- 綁定 buffer local 的 LSP 功能（非 VSCode）
local function on_attach(client, bufnr)
    if vim.g.vscode then
        return
    end

    -- 移除 LazyVim 預設快捷鍵
    for _, key in ipairs({ "gd", "gr", "gI", "gy" }) do
        pcall(vim.keymap.del, "n", key)
        pcall(vim.keymap.del, "n", key, { buffer = bufnr })
    end
end

-- 註冊所有 LSP server
local function setup_installed_servers()
    local lspconfig = require("lspconfig")
    local mason_lspconfig = require("mason-lspconfig")
    local custom_servers = get_custom_server_config()

    for _, name in ipairs(mason_lspconfig.get_installed_servers()) do
        local opts = custom_servers[name] or {}
        opts.on_attach = on_attach
        lspconfig[name].setup(opts)
    end
end

-- VSCode 全域快捷鍵註冊
local function setup_lsp_keymaps()
    if vim.g.vscode then
        local vscode = require("vscode")
        vim.keymap.set("n", "gd", function()
            vscode.call("editor.action.revealDefinition")
        end, { silent = true })
        vim.keymap.set("n", "gy", function()
            vscode.call("editor.action.goToTypeDefinition")
        end, { silent = true })
        vim.keymap.set("n", "gi", function()
            vscode.call("editor.action.goToImplementation")
        end, { silent = true })
        vim.keymap.set("n", "gr", function()
            vscode.call("editor.action.goToReferences")
        end, { silent = true })
    else
        local map = vim.keymap.set
        local opts = { silent = true }

        map("n", "gd", function()
            Snacks.picker.lsp_definitions()
        end, vim.tbl_extend("force", opts, { desc = "Goto Definition", has = "Definition" }))

        map("n", "gr", function()
            Snacks.picker.lsp_references()
        end, vim.tbl_extend("force", opts, { nowait = true, desc = "references" }))

        map("n", "gI", function()
            Snacks.picker.lsp_implementations()
        end, vim.tbl_extend("force", opts, { desc = "Goto Implementation" }))

        map("n", "gy", function()
            Snacks.picker.lsp_type_definitions()
        end, vim.tbl_extend("force", opts, { desc = "Goto T[y]pe Definition" }))
    end
end

-- 可呼叫的開關函式
function M.toggle_lsp()
    local clients = vim.lsp.get_clients()
    if #clients > 0 then
        for _, client in ipairs(clients) do
            client.stop()
        end
        vim.notify("[LSP] 所有語言伺服器已停止")
    else
        setup_installed_servers()
        vim.cmd("LspStart")
        vim.notify("[LSP] 已註冊並啟動所有已安裝的語言伺服器")
    end

    if vim.g.vscode then
        setup_lsp_keymaps()
    end
end

-- 自動啟用（非 VSCode）
function M.auto_enable_lsp()
    if not vim.g.vscode then
        setup_installed_servers()
        vim.notify("[LSP] Neovim 啟動：已註冊語言伺服器", vim.log.levels.INFO)
    end
end

-- 附加功能
function M.clear_references()
    if not vim.g.vscode and vim.lsp.buf.clear_references then
        vim.lsp.buf.clear_references()
    end
end

function M.hover()
    if vim.lsp.buf.hover then
        vim.lsp.buf.hover()
    end
end

function M.rename()
    if vim.lsp.buf.rename then
        vim.lsp.buf.rename()
    end
end

function M.definition()
    if vim.lsp.buf.definition then
        vim.lsp.buf.definition()
    end
end

function M.code_action()
    if vim.lsp.buf.code_action then
        vim.lsp.buf.code_action()
    end
end

-- 註冊 MasonToggle 指令
vim.api.nvim_create_user_command("MasonToggle", function()
    require("plugin.lsp").toggle_lsp()
end, {})

return M
