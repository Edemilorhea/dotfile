return {
    {
        "neovim/nvim-lspconfig",
        vscode = false,
        lazy = true,
        cond = function()
            return not vim.g.vscode
        end,
        opts = function(_, opts)
            -- 強制覆蓋 LazyVim 預設的 inlay_hints.enabled = true
            opts.inlay_hints = opts.inlay_hints or {}
            opts.inlay_hints.enabled = false
            opts.codelens = opts.codelens or {}
            opts.codelens.enabled = false
            opts.document_highlight = opts.document_highlight or {}
            opts.document_highlight.enabled = true
            -- LSP 折疊已停用，改用 treesitter 折疊（vim.treesitter.foldexpr），避免兩套 fold 同時重算
            opts.folds = opts.folds or {}
            opts.folds.enabled = false

            -- 語言伺服器設定
            opts.servers = opts.servers or {}
            opts.servers.lua_ls = {
                settings = {
                    Lua = {
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                        diagnostics = { globals = { "vim" } },
                    },
                },
            }

            -- ESLint: 交給 nvim-lspconfig 上游內建 gating 處理
            -- 只有專案存在 ESLint config (.eslintrc* / eslint.config.*) 或
            -- package.json 含 eslintConfig 時才會自動啟動,沒有則不啟動也不報錯。

            -- 明確停用 ts_ls (使用 vtsls 取代)
            opts.servers.ts_ls = {
                enabled = false,
            }

            -- TypeScript/Solid.js LSP 設定 (使用 vtsls,效能更好)
            opts.servers.vtsls = {
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
                        -- 開啟內建 validate（恢復 TypeScript 即時診斷）
                        validate = {
                            enable = true,
                        },
                        -- 關閉內建 format（使用 conform.nvim）
                        format = {
                            enable = false,
                        },
                        -- 關閉所有 inlay hints（預設不顯示，用 <C-c><C-c> 手動開關）
                        inlayHints = {
                            parameterNames = {
                                enabled = "none", -- "none" | "literals" | "all"
                            },
                            parameterTypes = {
                                enabled = false,
                            },
                            variableTypes = {
                                enabled = false,
                            },
                            functionLikeReturnTypes = {
                                enabled = false,
                            },
                            enumMemberValues = {
                                enabled = false,
                            },
                            propertyDeclarationTypes = {
                                enabled = false,
                            },
                        },
                    },
                    javascript = {
                        validate = {
                            enable = true,
                        },
                        format = {
                            enable = false,
                        },
                        inlayHints = {
                            parameterNames = {
                                enabled = "none",
                            },
                            parameterTypes = {
                                enabled = false,
                            },
                            variableTypes = {
                                enabled = false,
                            },
                            functionLikeReturnTypes = {
                                enabled = false,
                            },
                            enumMemberValues = {
                                enabled = false,
                            },
                            propertyDeclarationTypes = {
                                enabled = false,
                            },
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
            }

            -- OmniSharp (C# LSP) 自訂設定
            -- 改用 roslyn.nvim 為主,OmniSharp 不自動啟動,僅作手動 fallback (:LspStart omnisharp)
            opts.servers.omnisharp = {
                autostart = false,
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
            }

            -- Marksman (Markdown LSP) 自訂設定
            opts.servers.marksman = {
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
            }

            return opts
        end,
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
        opts = {
            -- roslyn (C# LSP) 由 Crashdummyy registry 提供,roslyn.nvim 需要
            registries = {
                "github:mason-org/mason-registry",
                "github:Crashdummyy/mason-registry",
            },
        },
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
                "eslint",       -- ESLint LSP (有 config 才自動啟動)
                "omnisharp",
                "pyright",
                "marksman",
            },
            -- omnisharp: 仍由 Mason 安裝/更新,但不自動啟動 (改用 roslyn.nvim;需要時 :LspStart omnisharp)
            -- roslyn: 由 roslyn.nvim 接管啟動,排除以避免雙重啟動 (雙保險)
            automatic_enable = {
                exclude = { "omnisharp", "roslyn" },
            },
        },
    },
}
