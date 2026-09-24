-- \rr：完整重啟 Neovim 並自動還原上一個 Session。
--
-- 為什麼要這樣繞：
-- LazyVim 的 LSP/Treesitter/gitsigns 靠 LazyFile 事件（BufReadPost/BufNewFile/BufWritePre）延遲載入。
-- 還原 session 時 source session 檔會開檔並觸發 BufReadPost，但只有在啟動流程完全跑完、
-- 所有 lazy handler 就緒後才會正確驅動 LazyFile —— 也就是手動按 \ql 的時機。
-- 在 VeryLazy callback 內同步還原太早，LSP 不會 attach。
-- 解法：寫 flag 檔 → :restart → 新 process 在 VimEnter 後用 vim.schedule 把還原排到最尾端。
local M = {}

local flag = vim.fn.stdpath("state") .. "/restart_session_pending"

function M.restart()
    local file = io.open(flag, "w")
    if file then
        file:close()
    end
    vim.cmd("restart")
end

-- 由 config/options.lua 在啟動期間呼叫。
function M.restore_pending_session()
    if not vim.uv.fs_stat(flag) then
        return
    end
    os.remove(flag)
    vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        nested = true, -- 讓 source session 時開檔觸發的 BufReadPost 繼續驅動其他 autocmd
        callback = function()
            vim.schedule(function()
                local ok, persistence = pcall(require, "persistence")
                if ok then
                    persistence.load({ last = true })
                end
            end)
        end,
    })
end

return M
