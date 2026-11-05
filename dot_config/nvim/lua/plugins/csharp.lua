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

-- Roslyn 載入 project 失敗時只送 window/logMessage，Neovim 預設只寫進 lsp.log，畫面不會提示。
-- 這裡收集失敗的 project，等 workspace/projectInitializationComplete 時彙總通知一次。
---@type table<integer, { projects: table<string, true>, reasons: table<string, true> }>
local load_failures = {}

---@param client_id integer
---@param message string
local function record_load_failure(client_id, message)
    local project = message:match("Error while loading (.-%.csproj)")
    if not project then
        return
    end
    local reason = message:match("Detailed error: ([^\r\n]+)") or message:match("%.csproj: ([^\r\n]+)") or "unknown"
    local failures = load_failures[client_id] or { projects = {}, reasons = {} }
    failures.projects[project] = true
    failures.reasons[reason:sub(1, 200)] = true
    load_failures[client_id] = failures
end

---@param client_id integer
local function report_load_failures(client_id)
    local failures = load_failures[client_id]
    load_failures[client_id] = nil
    if not failures then
        return
    end
    vim.notify(
        string.format(
            "%d 個 project 載入失敗，跨檔功能（定義、參考、實作）會不完整：\n- %s\n詳見 :LspLog",
            vim.tbl_count(failures.projects),
            table.concat(vim.tbl_keys(failures.reasons), "\n- ")
        ),
        vim.log.levels.ERROR,
        { title = "roslyn.nvim" }
    )
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
            -- 不讓 Neovim 端比對 watched-files glob；bin/obj 變動時避免主執行緒卡頓
            filewatching = "off",
        },
        config = function(_, opts)
            local roslyn_handlers = require("roslyn.lsp.handlers")
            vim.lsp.config("roslyn", {
                handlers = {
                    ["window/logMessage"] = function(err, params, ctx)
                        if params.type == vim.lsp.protocol.MessageType.Error then
                            record_load_failure(ctx.client_id, params.message)
                        end
                        return vim.lsp.handlers["window/logMessage"](err, params, ctx)
                    end,
                    ["workspace/projectInitializationComplete"] = function(err, res, ctx)
                        report_load_failures(ctx.client_id)
                        return roslyn_handlers["workspace/projectInitializationComplete"](err, res, ctx)
                    end,
                },
                settings = {
                    ["csharp|background_analysis"] = {
                        ["background_analysis.dotnet_analyzer_diagnostics_scope"] = "openFiles",
                        ["background_analysis.dotnet_compiler_diagnostics_scope"] = "openFiles",
                    },
                    -- 不列出尚未 import 的 namespace 成員；這是 Roslyn completion 最重的來源
                    ["csharp|completion"] = {
                        ["dotnet_show_completion_items_from_unimported_namespaces"] = false,
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
