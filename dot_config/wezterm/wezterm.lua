local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local mux = wezterm.mux

----------------------------------------------------------------
-- 1. Resurrect 插件設定 (Session 狀態管理)
----------------------------------------------------------------
-- local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- 設定狀態檔案儲存目錄 (Windows 必須設定)
-- local state_dir = wezterm.home_dir .. "\\Desktop\\wezterm_state\\"
-- resurrect.state_manager.change_state_save_dir(state_dir)
-- wezterm.log_info("📁 Resurrect 狀態目錄: " .. state_dir)

-- 啟用自動定期儲存 (每 15 分鐘)
-- resurrect.state_manager.periodic_save({
--     interval_seconds = 900, -- 15 分鐘 = 900 秒
--     save_workspaces = true,
--     save_windows = true,
--     save_tabs = false, -- 不單獨儲存 tab (已包含在 workspace 中)
-- })
-- wezterm.log_info("✅ Resurrect 自動儲存已啟用 (每 15 分鐘)")

----------------------------------------------------------------
-- 2. 基礎外觀與系統設定
----------------------------------------------------------------
config.initial_cols = 120
config.initial_rows = 28
config.font_size = 12
config.color_scheme = "Ocean (dark) (terminal.sexy)"

----------------------------------------------------------------
-- 渲染器設定 (OpenGL 對 IME 相容性較佳)
----------------------------------------------------------------
-- OpenGL  - 傳統渲染器,IME 相容性最佳 (推薦用於中文輸入法)
-- WebGpu  - 新一代渲染器,效能較好但可能與 IME 衝突
-- Software - 軟體渲染,最慢但最穩定
config.front_end = "Software"

-- ===== 輸入法相關設定 =====
-- ===== Windows 穩定性設定 =====
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    config.front_end = "OpenGL"
    config.max_fps = 60
    config.animation_fps = 30
end

----------------------------------------------------------------
-- IME 輸入法支援設定 (修復無蝦米/注音等輸入法 Shift 切換問題)
----------------------------------------------------------------
-- 核心設定: 啟用 IME 支援
-- config.use_ime = true
config.use_ime = false

-- IME 預覽文字渲染模式
-- "System"   - 使用系統原生輸入法預覽視窗 (推薦,相容性最佳)
-- "Builtin"  - 使用 WezTerm 內建渲染 (可能與某些輸入法衝突)
-- "None"     - 不顯示預覽 (不推薦)
-- config.ime_preedit_rendering = "Builtin"
config.ime_preedit_rendering = "System"

-- 防止 Alt 鍵干擾輸入法組合鍵
-- 設為 false 可避免 Alt 鍵被 WezTerm 攔截,讓輸入法正常運作
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- 禁用死鍵處理 (Dead Keys)
-- 死鍵是用於輸入重音符號的機制,可能干擾中文輸入法
config.use_dead_keys = false

-- 禁用 Kitty 鍵盤協議
-- Kitty 協議會改變按鍵事件處理方式,可能導致 IME 事件被攔截
config.enable_kitty_keyboard = false

-- 說明:
-- 1. front_end = "OpenGL" - 切換到相容性更好的渲染器
-- 2. use_ime = true - 啟用 Windows IME 支援
-- 3. ime_preedit_rendering = "System" - 使用系統原生輸入法視窗
-- 4. use_dead_keys = false - 避免死鍵機制干擾
-- 5. enable_kitty_keyboard = false - 避免按鍵協議衝突
--
-- 如果仍無效,可能需要:
-- - 檢查 Windows 設定 > 時間與語言 > 語言 > 進階鍵盤設定
-- - 確認「切換輸入法」快速鍵設定為 Shift
-- - 嘗試重新安裝無蝦米輸入法

-- 跨平台預設 Shell 設定
config.default_prog = { "pwsh.exe", "-NoLogo" }

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
-- 3. 快捷鍵速查表功能 (使用 InputSelector 彈出式選單)
----------------------------------------------------------------
local function show_keybindings_help()
    local keybindings = {
        {
            label = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            id = "header",
        },
        { label = "                    🎯 WezTerm 快捷鍵速查表                    ", id = "title" },
        {
            label = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            id = "divider1",
        },
        { label = "", id = "space1" },
        { label = "📌 通用快捷鍵", id = "section1" },
        { label = "  Alt + ?              顯示此快捷鍵速查表", id = "key1" },
        { label = "  Alt + W              開啟新分頁 (Home 目錄)", id = "key2" },
        { label = "  Alt + L              開啟目錄清單 (Launcher)", id = "key3" },
        { label = "  Alt + S              Workspace 切換器", id = "key4" },
        { label = "  Alt + T              顯示所有分頁", id = "key5" },
        { label = "  Alt + { / }          切換上/下一個分頁", id = "key6" },
        { label = "  Alt + 方向鍵         切換分割視窗", id = "key7" },
        { label = "", id = "space2" },
        { label = "🔄 Session 狀態管理 (Resurrect)", id = "section2" },
        { label = "  Alt + Shift + W      儲存當前 Workspace 狀態", id = "key8" },
        { label = "  Alt + Shift + R      載入當前 Workspace 的已儲存狀態", id = "key9" },
        { label = "", id = "space3" },
        { label = "🎮 Leader 模式 (先按 Alt + A，再按以下按鍵)", id = "section3" },
        { label = "", id = "space4" },
        { label = "📑 Tab 管理", id = "section4" },
        { label = "  c                    建立新分頁", id = "key11" },
        { label = "  n / p                下一個/上一個分頁", id = "key12" },
        { label = "  q                    關閉當前分頁", id = "key13" },
        { label = "  e                    重命名分頁", id = "key14" },
        { label = "  1~9                  快速切換到第 N 個分頁", id = "key15" },
        { label = "  Shift + $            重命名 Workspace", id = "key16" },
        { label = "", id = "space5" },
        { label = "🪟 Workspace 管理", id = "section5" },
        { label = "  w                    切換到指定 Workspace", id = "key17" },
        { label = "", id = "space6" },
        { label = "✂️  Pane 分割", id = "section6" },
        { label = '  Shift + "            水平分割 (上下)', id = "key18" },
        { label = "  Shift + %            垂直分割 (左右)", id = "key19" },
        { label = "  x                    關閉當前 Pane", id = "key20" },
        { label = "  z                    最大化/還原當前 Pane", id = "key21" },
        { label = "  o                    旋轉 Pane 佈局", id = "key22" },
        { label = "", id = "space7" },
        { label = "🧭 Pane 導航 (Vim 風格)", id = "section7" },
        { label = "  h / j / k / l        左/下/上/右切換 Pane", id = "key23" },
        { label = "", id = "space8" },
        { label = "📏 Pane 調整大小", id = "section8" },
        { label = "  r                    進入 Resize 模式 (h/j/k/l 調整，Esc 退出)", id = "key24" },
        { label = "", id = "space9" },
        {
            label = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            id = "divider2",
        },
        { label = "💡 提示: Leader Key = Alt + A (1 秒內按下後續按鍵)", id = "tip" },
        {
            label = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
            id = "divider3",
        },
    }

    return act.InputSelector({
        title = "⌨️  快捷鍵速查表",
        choices = keybindings,
        fuzzy = true,
        description = "按 Esc 或 Ctrl+C 關閉 | 按 / 搜尋",
        action = wezterm.action_callback(function(window, pane, id, label)
            -- 不執行任何動作，只是顯示
        end),
    })
end

----------------------------------------------------------------
-- 4. 快捷鍵設定 (含超級入口)
----------------------------------------------------------------
config.keys = {
    ----------------------------------------------------------------
    -- [IME 支援] Shift 鍵穿透設定 - 讓輸入法接管 Shift 鍵
    ----------------------------------------------------------------
    -- 明確告訴 WezTerm 不要處理單獨的 Shift 鍵,讓 Windows IME 接管
    -- 這樣無蝦米/注音等輸入法才能正常使用 Shift 切換中英文
    {
        key = "Shift",
        action = act.DisableDefaultAssignment, -- 禁用預設行為,讓系統處理
    },
    {
        key = "LeftShift",
        action = act.DisableDefaultAssignment,
    },
    {
        key = "RightShift",
        action = act.DisableDefaultAssignment,
    },

    -- [通用] 顯示快捷鍵速查表 (Alt + ?)
    {
        key = "?",
        mods = "ALT|SHIFT",
        action = wezterm.action_callback(function(window, pane)
            window:perform_action(show_keybindings_help(), pane)
        end),
    },

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

    {
        mods = "LEADER|SHIFT",
        key = "$",
        action = act.PromptInputLine({
            description = "Rename current workspace",
            action = wezterm.action_callback(function(window, pane, line)
                if line and #line > 0 then
                    local old = mux.get_active_workspace()
                    mux.rename_workspace(old, line)
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

    ----------------------------------------------------------------
    -- [Resurrect] Session 狀態管理
    ----------------------------------------------------------------
    -- 儲存當前 Workspace 狀態 (Alt + Shift + W)
    -- {
    --     key = "W",
    --     mods = "ALT|SHIFT",
    --     action = wezterm.action_callback(function(win, pane)
    --         local workspace = mux.get_active_workspace()
    --         resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    --
    --         -- 顯示通知
    --         win:toast_notification("WezTerm - Resurrect", "✅ Workspace 已儲存: " .. workspace, nil, 3000)
    --         wezterm.log_info("✅ Workspace 狀態已儲存: " .. workspace)
    --     end),
    -- },

    -- 載入最近儲存的 Workspace 狀態 (Alt + Shift + R)
    --     {
    --         key = "R",
    --         mods = "ALT|SHIFT",
    --         action = wezterm.action_callback(function(win, pane)
    --             local workspace = mux.get_active_workspace()
    --             local success, state = pcall(function()
    --                 return resurrect.state_manager.load_state(workspace, "workspace")
    --             end)
    --
    --             if success and state then
    --                 local opts = {
    --                     relative = true,
    --                     restore_text = true,
    --                     on_pane_restore = resurrect.tab_state.default_on_pane_restore,
    --                 }
    --                 resurrect.workspace_state.restore_workspace(state, opts)
    --                 win:toast_notification("WezTerm - Resurrect", "✅ Workspace 已恢復: " .. workspace, nil, 3000)
    --                 wezterm.log_info("✅ Workspace 已恢復: " .. workspace)
    --             else
    --                 win:toast_notification(
    --                     "WezTerm - Resurrect",
    --                     "❌ 找不到已儲存的狀態: " .. workspace,
    --                     nil,
    --                     3000
    --                 )
    --                 wezterm.log_warn("❌ 找不到已儲存的狀態: " .. workspace)
    --             end
    --         end),
    --     },
    -- }
} -- 結束 config.keys

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
-- 7. Resurrect 啟動時自動恢復
----------------------------------------------------------------
-- wezterm.on("gui-startup", function(cmd)
--     -- 先執行預設的啟動行為
--     resurrect.state_manager.resurrect_on_gui_startup(cmd)
--     wezterm.log_info("🔄 已嘗試恢復上次的 Workspace 狀態")
-- end)

----------------------------------------------------------------
-- 路徑管理: 動態偵測 + 本機配置
----------------------------------------------------------------
-- 輔助函數: 檢查路徑是否存在 (改良版，支援目錄檢查)
local function path_exists(path)
    -- 使用 io.open 快速檢查路徑 (避免讀取整個目錄)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
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
