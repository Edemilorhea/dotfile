-- LSP 快取優化 - 避免每次重新載入
return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            -- 啟用 LSP 快取
            vim.lsp.set_log_level("warn") -- 減少日誌輸出
            
            -- 確保 servers 表存在
            opts.servers = opts.servers or {}
            opts.servers["*"] = opts.servers["*"] or {}
            
            -- 優化 LSP 啟動 (使用新的 LazyVim 格式)
            opts.servers["*"].capabilities = vim.tbl_deep_extend(
                "force",
                opts.servers["*"].capabilities or {},
                {
                    workspace = {
                        -- 啟用檔案監視快取
                        didChangeWatchedFiles = {
                            dynamicRegistration = true,
                        },
                    },
                }
            )
            
            return opts
        end,
    },
}
