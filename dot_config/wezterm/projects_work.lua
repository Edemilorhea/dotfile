-- projects_work.lua
-- WezTerm workspace configuration
-- This file should be managed by chezmoi or manually updated

local M = {}

-- Workspace bundles for Alt+9 menu
-- Each workspace can open multiple tabs at once
M.workspaces = {
    -- Example workspace:
    -- {
    --     label = "My Project",
    --     tabs = {
    --         { title = "Editor", cwd = "D:/repos/my-project" },
    --         { title = "Server", cwd = "D:/repos/my-project/backend" },
    --     }
    -- },
}

-- Single directory launch menu items for Alt+L
M.launch_menu = {
    -- Example entries:
    -- { label = "Home", args = { "pwsh.exe" }, cwd = os.getenv("USERPROFILE") },
    -- { label = "Projects", args = { "pwsh.exe" }, cwd = "D:/repos" },
}

return M
