-- 同一個資料夾有多個 .sln / .slnf / .slnx 時，roslyn.nvim 會要求用 :Roslyn target 選擇。
-- 這裡記住每個 solution 最後一次載入的時間；下次遇到同一組候選時，直接選最近用過的那一個。
local target_file = vim.fn.stdpath("data") .. "/roslyn-targets.json"

local function target_key(path)
    return vim.fs.normalize(path):lower()
end

---@return table<string, integer>
local function load_targets()
    local ok, lines = pcall(vim.fn.readfile, target_file)
    if not ok or #lines == 0 then
        return {}
    end
    local decoded, data = pcall(vim.json.decode, table.concat(lines, "\n"))
    return decoded and type(data) == "table" and data or {}
end

---@param solution string
local function remember_target(solution)
    local targets = load_targets()
    targets[target_key(solution)] = os.time()
    pcall(vim.fn.writefile, { vim.json.encode(targets) }, target_file)
end

---@param candidates string[]
---@return string?
local function choose_remembered_target(candidates)
    local used = load_targets()
    local best, best_time
    for _, candidate in ipairs(candidates) do
        local time = used[target_key(candidate)]
        if time and (not best_time or time > best_time) then
            best, best_time = candidate, time
        end
    end
    return best
end

return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            -- roslyn.nvim 負責啟動與 solution 選擇
            opts.servers.omnisharp = { enabled = false }
            opts.servers.roslyn_ls = { enabled = false }
        end,
    },
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            -- roslyn 由 Crashdummyy registry 提供
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
            choose_target = choose_remembered_target,
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

            -- 每個 roslyn client 只記錄一次它載入的 solution（含 :Roslyn target 手動選的）
            local remembered = {}
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("user_roslyn_target", { clear = true }),
                callback = function(event)
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if not client or client.name ~= "roslyn" or remembered[client.id] then
                        return
                    end
                    local solution = require("roslyn.store").get(client.id)
                    if solution then
                        remembered[client.id] = true
                        remember_target(solution)
                    end
                end,
            })
        end,
    },
}
