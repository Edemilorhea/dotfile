local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

----------------------------------------------------------------
-- 2. 基礎外觀與系統設定
----------------------------------------------------------------
config.initial_cols = 120
config.initial_rows = 28
config.font_size = 14
config.color_scheme = "Ocean (dark) (terminal.sexy)"

-- 跨平台預設 Shell 設定
config.default_prog = { "pwsh.exe" } -- Windows: PowerShell

-- 跨平台字型設定
config.font = wezterm.font_with_fallback({
    "Maple Mono Normal NF CN",
    "Maple Mono Normal CN",
    "FiraCode Nerd Font Mono",
    "Consolas", -- Windows 備用
    "Cascadia Code", -- Windows Terminal 預設
})

-- 視覺效果: 毛玻璃 + 透明度
config.window_background_opacity = 0
config.win32_system_backdrop = "Acrylic"
config.text_background_opacity = 0.8
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines = 3000

-- 非活動 pane 變暗
config.inactive_pane_hsb = {
    saturation = 0.24,
    brightness = 0.5,
}

-- Tab Bar 樣式
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = false

-- 設定 Leader Key (Alt + a)
config.leader = { key = "a", mods = "ALT", timeout_milliseconds = 1000 }

----------------------------------------------------------------
-- 3. 快捷鍵設定 (含超級入口)
----------------------------------------------------------------
config.keys = {
    -- [通用] 開啟純淨新分頁
    { key = "w", mods = "ALT", action = act.SpawnCommandInNewTab({ cwd = "~" }) },

    -- [通用] 開啟單一目錄清單 (原本的 Launcher)
    { key = "l", mods = "ALT", action = act.ShowLauncher },

    -- [通用] Workspace 切換器 (切換工作環境)
    { key = "s", mods = "ALT", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

    -- [通用] 顯示所有分頁 (當前 workspace)
    { key = "t", mods = "ALT", action = act.ShowTabNavigator },

    -- [Leader] Tab 管理
    { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
    { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
    { key = "q", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
    {
        key = "e",
        mods = "LEADER",
        action = act.PromptInputLine({
            description = wezterm.format({
                { Attribute = { Intensity = "Bold" } },
                { Foreground = { AnsiColor = "Fuchsia" } },
                { Text = "重命名分頁:" },
            }),
            action = wezterm.action_callback(function(window, pane, line)
                if line then
                    window:active_tab():set_title(line)
                end
            end),
        }),
    },

    -- [Leader] Workspace 管理
    {
        key = "w",
        mods = "LEADER",
        action = act.PromptInputLine({
            description = wezterm.format({
                { Attribute = { Intensity = "Bold" } },
                { Foreground = { AnsiColor = "Green" } },
                { Text = "切換到 Workspace:" },
            }),
            action = wezterm.action_callback(function(window, pane, line)
                if line then
                    window:perform_action(
                        act.SwitchToWorkspace({
                            name = line,
                        }),
                        pane
                    )
                end
            end),
        }),
    },

    -- [Leader] Pane 分割 (tmux 風格，保留 CWD)
    {
        key = '"',
        mods = "LEADER|SHIFT",
        action = wezterm.action_callback(function(window, pane)
            local cwd = pane:get_current_working_dir()
            local cwd_path = cwd and cwd.file_path:gsub("^/", "") or nil
            window:perform_action(act.SplitVertical({ domain = "CurrentPaneDomain", cwd = cwd_path }), pane)
        end),
    },
    {
        key = "%",
        mods = "LEADER|SHIFT",
        action = wezterm.action_callback(function(window, pane)
            local cwd = pane:get_current_working_dir()
            local cwd_path = cwd and cwd.file_path:gsub("^/", "") or nil
            window:perform_action(act.SplitHorizontal({ domain = "CurrentPaneDomain", cwd = cwd_path }), pane)
        end),
    },
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
    { key = "o", mods = "LEADER", action = act.RotatePanes("Clockwise") },

    -- [Leader] Pane 導航 (vim 風格 hjkl)
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

    -- [Leader] Pane 調整大小 (進入 resize mode)
    { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

    -- [導覽] 分割視窗切換 (Alt + 方向鍵，保留原有習慣)
    { key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
    { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },
    { key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
    { key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },

    -- [切換分頁] (Alt + { / })
    { key = "{", mods = "ALT", action = act.ActivateTabRelative(-1) },
    { key = "}", mods = "ALT", action = act.ActivateTabRelative(1) },
}

----------------------------------------------------------------
-- 4. 快速切換分頁 (Leader + 1~9)
----------------------------------------------------------------
for i = 1, 9 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = "LEADER",
        action = act.ActivateTab(i - 1),
    })
end

----------------------------------------------------------------
-- 5. Key Tables (Resize Mode)
----------------------------------------------------------------
config.key_tables = {
    resize_pane = {
        { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
        { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
        { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
        { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
        { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
        { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
        { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
        { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
        { key = "Escape", action = "PopKeyTable" },
        { key = "Enter", action = "PopKeyTable" },
    },
}

----------------------------------------------------------------
-- 6. 動態狀態列
----------------------------------------------------------------
wezterm.on("update-status", function(window, pane)
    -- 左側: 顯示 Leader 狀態 / Key Table
    local stat = window:active_workspace()
    local stat_color = "#f7768e"

    if window:active_key_table() then
        stat = window:active_key_table()
        stat_color = "#7dcfff"
    end
    if window:leader_is_active() then
        stat = "LDR"
        stat_color = "#bb9af7"
    end

    -- 右側: 目錄 | 程序 | 時間
    local basename = function(s)
        return string.gsub(s, "(.*[/\\])(.*)", "%2")
    end

    local cwd = pane:get_current_working_dir()
    cwd = cwd and basename(cwd.path) or ""

    local cmd = pane:get_foreground_process_name()
    cmd = cmd and basename(cmd) or ""

    local time = wezterm.strftime("%H:%M")

    -- 設定左側狀態
    window:set_left_status(wezterm.format({
        { Foreground = { Color = stat_color } },
        { Text = "  " },
        { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
        { Text = " |" },
    }))

    -- 設定右側狀態
    window:set_right_status(wezterm.format({
        { Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
        { Text = " | " },
        { Foreground = { Color = "#e0af68" } },
        { Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
        "ResetAttributes",
        { Text = " | " },
        { Text = wezterm.nerdfonts.md_clock .. "  " .. time },
        { Text = "  " },
    }))
end)

----------------------------------------------------------------
-- 路徑管理: 動態偵測 + 本機配置
----------------------------------------------------------------
-- 輔助函數: 檢查路徑是否存在 (改良版，支援目錄檢查)
local function path_exists(path)
    -- 使用 wezterm 內建函數檢查目錄
    local success = pcall(function()
        wezterm.read_dir(path)
    end)
    return success
end

-- 輔助函數: 找到第一個存在的路徑
local function find_first_existing(paths)
    for _, path in ipairs(paths) do
        if path_exists(path) then
            return path, true -- 返回路徑和找到標記
        end
    end
    return nil, false -- 都找不到，返回 nil
end

-- 嘗試載入本機配置
local ok, local_config = pcall(require, "wezterm_local")
local paths = {}
local paths_not_found = {} -- 記錄找不到的路徑

if ok and local_config and local_config.paths then
    -- 使用本機配置
    paths = local_config.paths
    wezterm.log_info("✅ 使用本機配置: wezterm_local.lua")
else
    -- 動態偵測路徑
    wezterm.log_info("⚠️ 未找到 wezterm_local.lua，使用動態偵測")

    -- 偵測專案目錄
    local projects_path, projects_found = find_first_existing({
        "D:/work/projects",
        "C:/projects",
        wezterm.home_dir .. "/projects",
    })
    if projects_found then
        paths.projects = projects_path
    else
        paths.projects = wezterm.home_dir .. "/projects" -- 預設值
        table.insert(paths_not_found, "專案目錄")
    end

    -- 偵測配置目錄
    local config_path, config_found = find_first_existing({
        "C:/Users/tc_tseng/Desktop/config",
        wezterm.home_dir .. "/Desktop/config",
        wezterm.home_dir .. "/config",
    })
    if config_found then
        paths.config = config_path
    else
        paths.config = wezterm.home_dir .. "/config" -- 預設值
        table.insert(paths_not_found, "Config 配置")
    end

    -- 偵測筆記目錄
    local notes_path, notes_found = find_first_existing({
        "D:/notes",
        "C:/OneDrive/notes",
        wezterm.home_dir .. "/notes",
    })
    if notes_found then
        paths.notes = notes_path
    else
        paths.notes = wezterm.home_dir .. "/notes" -- 預設值
        table.insert(paths_not_found, "筆記目錄")
    end

    -- 如果有找不到的路徑，顯示警告
    if #paths_not_found > 0 then
        wezterm.log_warn("❌ 以下路徑找不到，使用預設值: " .. table.concat(paths_not_found, ", "))
        wezterm.log_warn("💡 建議建立 wezterm_local.lua 配置檔")
        wezterm.log_warn("📝 範例內容:")
        wezterm.log_warn("   return {")
        wezterm.log_warn("       paths = {")
        wezterm.log_warn("           projects = 'C:/your/projects',")
        wezterm.log_warn("           config = 'C:/your/config',")
        wezterm.log_warn("           notes = 'C:/your/notes',")
        wezterm.log_warn("       }")
        wezterm.log_warn("   }")
    end
end
----------------------------------------------------------------
-- Launch Menu 設定
----------------------------------------------------------------
config.launch_menu = {
    {
        label = "🏠 Home 目錄",
        args = { "pwsh.exe" },
        cwd = wezterm.home_dir,
    },
    {
        label = "📁 專案目錄",
        args = { "pwsh.exe" },
        cwd = paths.projects,
    },
    -- {
    --     label = "💻 Config 配置",
    --     args = { "pwsh.exe" },
    --     cwd = paths.config,
    -- },
    -- {
    --     label = "📝 筆記目錄",
    --     args = { "pwsh.exe" },
    --     cwd = paths.notes,
    -- },
}

return config
