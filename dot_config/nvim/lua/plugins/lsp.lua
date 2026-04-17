return {
    {
        "neovim/nvim-lspconfig",
        vscode = false,
        lazy = true,
        cond = function()
            return not vim.g.vscode
        end,
        opts = {
            -- LazyVim 15.x: 使用原生 LSP 折疊
            inlay_hints = { enabled = false }, -- 暫時停用,避免錯誤
            codelens = { enabled = false },
            document_highlight = { enabled = true },
            -- 啟用 LazyVim 原生 LSP 折疊功能
            folds = {
                enabled = true, -- 改為 true，使用原生功能
            },
            -- 語言伺服器設定
            servers = {
                -- Lua LSP 設定
                lua_ls = {
                    settings = {
                        Lua = {
                            workspace = { checkThirdParty = false },
                            telemetry = { enable = false },
                            diagnostics = { globals = { "vim" } },
                        },
                    },
                },
                
                -- 明確停用 ts_ls (使用 vtsls 取代)
                ts_ls = {
                    enabled = false,
                },
                
                -- TypeScript/Solid.js LSP 設定 (使用 vtsls,效能更好)
                -- 注意: lang.typescript extra 已啟用,此處僅覆寫 monorepo 優化設定
                vtsls = {
                    -- Monorepo 優化: 只分析當前 package
                    root_dir = function(fname)
                        local util = require("lspconfig.util")
                        -- 優先尋找最近的 package.json (當前 package)
                        return util.root_pattern("package.json")(fname)
                            -- 如果找不到,才往上找 tsconfig.json
                            or util.root_pattern("tsconfig.json")(fname)
                            -- 最後才找 .git
                            or util.root_pattern(".git")(fname)
                    end,
                    settings = {
                        typescript = {
                            -- 效能優化
                            tsserver = {
                                maxTsServerMemory = 4096, -- 限制記憶體使用
                            },
                        },
                        -- Monorepo 優化
                        vtsls = {
                            experimental = {
                                completion = {
                                    enableServerSideFuzzyMatch = true,
                                },
                            },
                        },
                    },
                },
                
                -- OmniSharp (C# LSP) 自訂設定
                omnisharp = {
                    handlers = {
                        ["textDocument/definition"] = function(...)
                            local ok, omnisharp_extended = pcall(require, "omnisharp_extended")
                            if ok then
                                return omnisharp_extended.definition_handler(...)
                            end
                            return vim.lsp.handlers["textDocument/definition"](...)
                        end,
                        ["textDocument/typeDefinition"] = function(...)
                            local ok, omnisharp_extended = pcall(require, "omnisharp_extended")
                            if ok then
                                return omnisharp_extended.type_definition_handler(...)
                            end
                            return vim.lsp.handlers["textDocument/typeDefinition"](...)
                        end,
                        ["textDocument/references"] = function(...)
                            local ok, omnisharp_extended = pcall(require, "omnisharp_extended")
                            if ok then
                                return omnisharp_extended.references_handler(...)
                            end
                            return vim.lsp.handlers["textDocument/references"](...)
                        end,
                        ["textDocument/implementation"] = function(...)
                            local ok, omnisharp_extended = pcall(require, "omnisharp_extended")
                            if ok then
                                return omnisharp_extended.implementation_handler(...)
                            end
                            return vim.lsp.handlers["textDocument/implementation"](...)
                        end,
                    },
                    settings = {
                        FormattingOptions = { EnableEditorConfigSupport = true },
                        RoslynExtensionsOptions = { EnableAnalyzersSupport = true },
                        Sdk = { IncludePrereleases = true },
                    },
                },
                
                -- Marksman (Markdown LSP) 自訂設定
                marksman = {
                    root_dir = function(fname)
                        local util = require("lspconfig.util")
                        return util.root_pattern(
                            ".obsidian",
                            ".markdownlintrc",
                            ".git",
                            ".markdownlint.json",
                            ".markdownlint.yaml"
                        )(fname)
                    end,
                    settings = {},
                    filetypes = { "markdown" },
                },
            },
        },
    },
    {
        "mason-org/mason.nvim",
        -- LazyVim 15.x: mason 倉庫已重命名為 mason-org/mason.nvim
        cmd = { "Mason", "MasonInstall", "MasonLog" },
        build = ":MasonUpdate",
        vscode = false,
        lazy = true,
        cond = function()
            return not vim.g.vscode
        end,
        opts = {},
    },
    {
        "mason-org/mason-lspconfig.nvim",
        -- LazyVim 15.x: mason-lspconfig 倉庫已重命名為 mason-org/mason-lspconfig.nvim
        lazy = true,
        event = "VeryLazy",
        vscode = false,
        cond = function()
            return not vim.g.vscode
        end,
        opts = {
            ensure_installed = {
                "lua_ls",
                "jsonls",
                "vtsls",        -- TypeScript/Solid.js LSP (推薦,效能更好)
                "html",
                "cssls",
                "tailwindcss",  -- Tailwind CSS LSP
                "emmet_ls",
                -- "eslint",    -- ESLint LSP (已停用,專案不需要)
                "omnisharp",
                "pyright",
                "marksman",
            },
        },
    },
}
