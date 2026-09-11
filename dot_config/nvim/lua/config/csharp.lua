local M = {}

local uv = vim.uv or vim.loop
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local excluded_directories = { [".git"] = true, bin = true, obj = true }

local function normalize(path)
    if not path or path == "" then
        return nil
    end
    return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function path_key(path)
    local result = normalize(path)
    return is_windows and result:lower() or result
end

local function is_within(root, path)
    local root_key = path_key(root)
    local path_value = path_key(path)
    return path_value == root_key or path_value:sub(1, #root_key + 1) == root_key .. "/"
end

local function read_file(path)
    local ok, lines = pcall(vim.fn.readfile, path, "b")
    return ok and table.concat(lines, "\n") or nil
end

local function write_file(path, content)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    return vim.fn.writefile({ content }, path) == 0
end

local function default_dependencies()
    return {
        state_path = vim.fn.stdpath("state") .. "/csharp-solutions.json",
        -- OmniSharp 1.39.15 only parses .sln and .slnf. Keep .slnx hidden until support is verified.
        slnx_supported = false,
        select = vim.ui.select,
        notify = vim.notify,
        defer = vim.defer_fn,
        get_clients = function()
            return vim.lsp.get_clients({ name = "omnisharp", _uninitialized = true })
        end,
        start = function(config, bufnr)
            return vim.lsp.start(config, { bufnr = bufnr, reuse_client = config.reuse_client })
        end,
        attach = vim.lsp.buf_attach_client,
        get_buffer_name = vim.api.nvim_buf_get_name,
        is_buffer_valid = vim.api.nvim_buf_is_valid,
        get_config = function()
            require("lazy").load({ plugins = { "nvim-lspconfig" } })
            return vim.deepcopy(vim.lsp.config.omnisharp)
        end,
    }
end

local function merge_callbacks(existing, callback)
    if not existing then
        return callback
    end
    if type(existing) == "table" then
        local callbacks = vim.deepcopy(existing)
        table.insert(callbacks, callback)
        return callbacks
    end
    return { existing, callback }
end

local function client_stopped(client)
    return client.is_stopped and client:is_stopped() or false
end

local function client_root(client)
    return client.config and client.config.root_dir and normalize(client.config.root_dir) or nil
end

local function client_solution(client)
    for index, argument in ipairs((client.config and client.config.cmd) or {}) do
        if argument == "-s" or argument == "--solution" then
            return normalize(client.config.cmd[index + 1])
        end
    end
end

local Controller = {}
Controller.__index = Controller

function Controller.new(overrides)
    local dependencies = default_dependencies()
    for key, value in pairs(overrides or {}) do
        dependencies[key] = value
    end
    return setmetatable({
        dependencies = dependencies,
        sessions = {},
        pending_prompts = {},
        selections = nil,
        persistence_warning_shown = false,
    }, Controller)
end

function Controller:_load_selections()
    if self.selections then
        return self.selections
    end

    self.selections = {}
    local content = read_file(self.dependencies.state_path)
    if not content or content == "" then
        return self.selections
    end

    local ok, decoded = pcall(vim.json.decode, content)
    if ok and type(decoded) == "table" and type(decoded.selections) == "table" then
        self.selections = decoded.selections
    elseif not self.persistence_warning_shown then
        self.persistence_warning_shown = true
        self.dependencies.notify(
            "C# solution selection state is invalid; select a solution again.",
            vim.log.levels.WARN
        )
    end
    return self.selections
end

function Controller:_save_selections()
    local ok, encoded = pcall(vim.json.encode, { version = 1, selections = self:_load_selections() })
    if not ok or not write_file(self.dependencies.state_path, encoded) then
        self.dependencies.notify("Could not save C# solution selection state.", vim.log.levels.ERROR)
    end
end

function Controller:_remember(root, solution)
    self:_load_selections()[path_key(root)] = normalize(solution)
    self:_save_selections()
end

function Controller:_forget(root)
    self:_load_selections()[path_key(root)] = nil
    self:_save_selections()
end

function Controller:_list_candidates(directory)
    local candidates = {}
    local ok, iterator = pcall(vim.fs.dir, directory)
    if not ok or not iterator then
        return candidates
    end

    for name, entry_type in iterator do
        if entry_type == "file" then
            local extension = name:match("(%.[^.]+)$")
            extension = extension and extension:lower()
            if
                extension == ".sln"
                or extension == ".slnf"
                or (extension == ".slnx" and self.dependencies.slnx_supported)
            then
                table.insert(candidates, normalize(directory .. "/" .. name))
            end
        end
    end
    table.sort(candidates)
    return candidates
end

function Controller:discover(path)
    path = normalize(path)
    if not path then
        return nil
    end

    local start = vim.fs.dirname(path)
    local git_root = vim.fs.root(start, { ".git" })
    git_root = git_root and normalize(git_root) or nil
    local relative = git_root and path_key(path):sub(#path_key(git_root) + 2) or path_key(start)
    for component in relative:gmatch("[^/\\]+") do
        if excluded_directories[component:lower()] then
            return nil
        end
    end

    local directory = start
    local nearest_boundary
    for _ = 1, 32 do
        local local_candidates = self:_list_candidates(directory)
        if #local_candidates > 0 then
            nearest_boundary = directory
            return {
                root = git_root or nearest_boundary,
                target_root = nearest_boundary,
                candidates = local_candidates,
            }
        end

        if (git_root and path_key(directory) == path_key(git_root)) or vim.fs.dirname(directory) == directory then
            break
        end
        directory = vim.fs.dirname(directory)
    end

    return nil
end

function Controller:_clients_for_root(root)
    local clients = {}
    for _, client in ipairs(self.dependencies.get_clients()) do
        if not client_stopped(client) and client_root(client) and path_key(client_root(client)) == path_key(root) then
            table.insert(clients, client)
        end
    end
    return clients
end

function Controller:_start(context, solution, bufnr)
    local root_key = path_key(context.root)
    local config = self.dependencies.get_config()
    config.name = "omnisharp"
    config.root_dir = context.root
    config.cmd = vim.deepcopy(config.cmd)
    table.insert(config.cmd, 2, solution)
    table.insert(config.cmd, 2, "-s")
    -- Apply diagnostic limits at startup, before solution loading begins.
    -- Keep the global omnisharp.json aligned: it takes precedence over CLI options.
    vim.list_extend(config.cmd, {
        "RoslynExtensionsOptions:EnableAnalyzersSupport=false",
        "RoslynExtensionsOptions:AnalyzeOpenDocumentsOnly=true",
        "RoslynExtensionsOptions:DiagnosticWorkersThreadCount=2",
    })
    config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
        RoslynExtensionsOptions = {
            EnableAnalyzersSupport = false,
            AnalyzeOpenDocumentsOnly = true,
            DiagnosticWorkersThreadCount = 2,
        },
    })
    config.reuse_client = function(client)
        return client.name == "omnisharp"
            and not client_stopped(client)
            and client_root(client) ~= nil
            and path_key(client_root(client)) == root_key
            and client_solution(client) ~= nil
            and path_key(client_solution(client)) == path_key(solution)
    end

    config.on_init = merge_callbacks(config.on_init, function(client)
        local session = self.sessions[root_key]
        if session and session.id == client.id then
            session.phase = "running"
        end
    end)
    config.on_exit = merge_callbacks(config.on_exit, function(code, signal, client_id)
        local session = self.sessions[root_key]
        if session and session.id == client_id and session.phase ~= "stopping" then
            session.phase = "exited"
            session.detail = string.format("exit code %s, signal %s", code, signal)
        end
    end)

    local session = {
        root = context.root,
        target_root = context.target_root,
        solution = solution,
        phase = "starting",
    }
    self.sessions[root_key] = session
    session.id = self.dependencies.start(config, bufnr)
    if not session.id then
        session.phase = "start failed"
    end
end

function Controller:_activate(context, solution, bufnr)
    solution = normalize(solution)
    self:_remember(context.root, solution)
    local root_key = path_key(context.root)
    local session = self.sessions[root_key]
    local clients = self:_clients_for_root(context.root)

    if #clients == 1 then
        local client = clients[1]
        if client_solution(client) and path_key(client_solution(client)) == path_key(solution) then
            self.sessions[root_key] = {
                root = context.root,
                target_root = context.target_root,
                solution = solution,
                id = client.id,
                phase = client.initialized and "running" or "starting",
            }
            self.dependencies.attach(bufnr, client.id)
            return
        end
    end

    if session and session.solution == solution and (session.phase == "starting" or session.phase == "stopping") then
        return
    end
    if #clients == 0 then
        self:_start(context, solution, bufnr)
        return
    end

    local generation = (session and session.generation or 0) + 1
    self.sessions[root_key] = {
        root = context.root,
        target_root = context.target_root,
        solution = solution,
        phase = "stopping",
        generation = generation,
    }
    for _, client in ipairs(clients) do
        client:stop()
    end

    local attempts = 0
    local function start_after_stop()
        local current = self.sessions[root_key]
        if not current or current.generation ~= generation then
            return
        end
        if #self:_clients_for_root(context.root) == 0 then
            self:_start(context, solution, bufnr)
            return
        end
        attempts = attempts + 1
        if attempts >= 200 then
            current.phase = "stop timeout"
            current.detail = "Old workspace client did not stop; new client was not started."
            self.dependencies.notify(current.detail, vim.log.levels.ERROR)
            return
        end
        self.dependencies.defer(start_after_stop, 50)
    end
    self.dependencies.defer(start_after_stop, 50)
end

function Controller:_choose(context, bufnr)
    local root_key = path_key(context.root)
    if self.pending_prompts[root_key] then
        return
    end
    self.pending_prompts[root_key] = true
    self.dependencies.select(context.candidates, {
        prompt = "Select C# solution",
        format_item = function(item)
            return vim.fs.relpath(context.root, item) or vim.fs.basename(item)
        end,
    }, function(choice)
        self.pending_prompts[root_key] = nil
        if not choice then
            if not self.sessions[root_key] then
                self.sessions[root_key] = {
                    root = context.root,
                    target_root = context.target_root,
                    phase = "cancelled",
                }
            end
            return
        end
        self:_activate(context, choice, bufnr)
    end)
end

function Controller:on_buffer(bufnr)
    if not self.dependencies.is_buffer_valid(bufnr) then
        return
    end
    local context = self:discover(self.dependencies.get_buffer_name(bufnr))
    if not context then
        return
    end

    local root_key = path_key(context.root)
    local session = self.sessions[root_key]
    if session then
        if session.id then
            self.dependencies.attach(bufnr, session.id)
        end
        return
    end

    local saved = self:_load_selections()[root_key]
    local extension = saved and saved:match("(%.[^.]+)$")
    local supported = extension == ".sln"
        or extension == ".slnf"
        or (extension == ".slnx" and self.dependencies.slnx_supported)
    if saved and supported and uv.fs_stat(saved) and is_within(context.root, saved) then
        self:_activate(context, saved, bufnr)
        return
    end
    if saved then
        self:_forget(context.root)
        self.dependencies.notify(
            "Saved C# solution is missing or unsupported; select another solution.",
            vim.log.levels.WARN
        )
    end
    self:_choose(context, bufnr)
end

function Controller:select_solution(bufnr)
    local context = self:discover(self.dependencies.get_buffer_name(bufnr))
    if not context then
        self.dependencies.notify("No C# solution was found in this workspace.", vim.log.levels.WARN)
        return
    end
    self:_choose(context, bufnr)
end

function Controller:status(path)
    local context = self:discover(path)
    if not context then
        return {
            "Selection root: not found",
            "Client ID: none",
            "Client initialized: no",
            "Full analysis ready: unknown (not exposed by OmniSharp)",
        }
    end
    local session = self.sessions[path_key(context.root)]
    local saved = self:_load_selections()[path_key(context.root)]
    local initialized = "no"
    if session and session.id then
        for _, client in ipairs(self.dependencies.get_clients()) do
            if client.id == session.id and not client_stopped(client) then
                initialized = client.initialized and "yes" or "no"
                break
            end
        end
    end
    return {
        "Selection root: " .. context.root,
        "Solution root: " .. ((session and session.target_root) or context.target_root),
        "Solution: " .. ((session and session.solution) or saved or "not selected"),
        "Client ID: " .. (session and session.id or "none"),
        "State: " .. (session and session.phase or "not started"),
        "Client initialized: " .. initialized,
        "Full analysis ready: unknown (not exposed by OmniSharp)",
        session and session.detail and ("Detail: " .. session.detail) or nil,
    }
end

function Controller:show_status(bufnr)
    local lines = self:status(self.dependencies.get_buffer_name(bufnr))
    self.dependencies.notify(
        table.concat(
            vim.tbl_filter(function(line)
                return line ~= nil
            end, lines),
            "\n"
        ),
        vim.log.levels.INFO,
        { title = "C# / OmniSharp" }
    )
end

M.Controller = Controller

function M.setup()
    if M.controller then
        return
    end
    M.controller = Controller.new()
    local group = vim.api.nvim_create_augroup("csharp_solution_selection", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "cs",
        callback = function(event)
            M.controller:on_buffer(event.buf)
        end,
    })
    vim.api.nvim_create_user_command("CSharpSolution", function()
        M.controller:select_solution(vim.api.nvim_get_current_buf())
    end, { desc = "Select or switch the C# solution" })
    vim.api.nvim_create_user_command("CSharpStatus", function()
        M.controller:show_status(vim.api.nvim_get_current_buf())
    end, { desc = "Show C# solution and OmniSharp status" })
end

return M
