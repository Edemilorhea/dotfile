return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            -- roslyn.nvim owns startup and solution selection.
            opts.servers.omnisharp = { enabled = false }
            opts.servers.roslyn_ls = { enabled = false }
        end,
    },
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.registries = opts.registries or { "github:mason-org/mason-registry" }
            local registry = "github:Crashdummyy/mason-registry"
            if not vim.tbl_contains(opts.registries, registry) then
                table.insert(opts.registries, registry)
            end
            opts.ensure_installed = opts.ensure_installed or {}
            if not vim.tbl_contains(opts.ensure_installed, "roslyn") then
                table.insert(opts.ensure_installed, "roslyn")
            end
        end,
    },
    {
        "seblyng/roslyn.nvim",
        ft = { "cs", "razor" },
        dependencies = { "neovim/nvim-lspconfig", "mason-org/mason.nvim" },
        opts = {
            broad_search = false,
            lock_target = false,
        },
        config = function(_, opts)
            vim.lsp.config("roslyn", {
                settings = {
                    ["csharp|background_analysis"] = {
                        ["background_analysis.dotnet_analyzer_diagnostics_scope"] = "openFiles",
                        ["background_analysis.dotnet_compiler_diagnostics_scope"] = "openFiles",
                    },
                },
            })
            require("roslyn").setup(opts)
        end,
    },
}
