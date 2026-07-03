local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

----------------------------------------------------------------
-- 1. 基礎外觀與系統設定
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
config.use_ime = false

-- IME 預覽文字渲染模式
-- "System"   - 使用系統原生輸入法預覽視窗 (推薦,相容性最佳)
-- "Builtin"  - 使用 WezTerm 內建渲染 (可能與某些輸入法衝突)
-- "None"     - 不顯示預覽 (不推薦)
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

-- 預設 Shell 設定 (Nushell)
config.default_prog = { "nu.exe" }

-- 跨平台字型設定
config.font = wezterm.font_with_fallback({
    "Maple Mono Normal NF CN",
    "JetBrains Maple Mono",
    "FiraCode Nerd Font Mono",
    "Maple Mono Normal CN",
    "Consolas", -- Windows 備用
    "Cascadia Code", -- Windows Terminal 預設
})

-- 視覺效果: 毛玻璃 + 透明度
config.window_background_opacity = 0.85
config.win32_system_backdrop = "Acrylic"
config.text_background_opacity = 0.8
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines = 3000

-- 非活動 pane 變暗
config.inactive_pane_hsb = {
    saturation = 0.24,
    brightness = 0.5,
}

-- Tab Bar 樣式
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false

----------------------------------------------------------------
-- 2. 快捷鍵設定
----------------------------------------------------------------
-- 注意: Pane 分割/導航/Tab/Workspace 管理已交給 psmux 處理,
-- 這裡只保留 IME 相容設定與對照 Alacritty 的通用快捷鍵。
config.keys = {
    ----------------------------------------------------------------
    -- [IME 支援] Shift 鍵穿透設定 - 讓輸入法接管 Shift 鍵
    ----------------------------------------------------------------
    -- 明確告訴 WezTerm 不要處理單獨的 Shift 鍵,讓 Windows IME 接管
    -- 這樣無蝦米/注音等輸入法才能正常使用 Shift 切換中英文
    { key = "Shift", action = act.DisableDefaultAssignment },
    { key = "LeftShift", action = act.DisableDefaultAssignment },
    { key = "RightShift", action = act.DisableDefaultAssignment },

    ----------------------------------------------------------------
    -- [對照 Alacritty] 複製 / 貼上 / 字型縮放 / 新視窗
    ----------------------------------------------------------------
    { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
    { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
    { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
    { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
    { key = "0", mods = "CTRL", action = act.ResetFontSize },
    { key = "N", mods = "CTRL|SHIFT", action = act.SpawnWindow },

    ----------------------------------------------------------------
    -- [對照 Alacritty] psmux / Neovim 按鍵相容
    ----------------------------------------------------------------
    -- C-F12 送標準 xterm escape sequence 給 psmux，由 psmux 的
    -- `bind -n C-F12 send-keys -f C-c` 處理
    { key = "F12", mods = "CTRL", action = act.SendString("\x1b[24;5~") },
    { key = "/", mods = "CTRL", action = act.SendString("\x1f") },
    -- C-h 修正：避免終端機將 Ctrl+H 解讀為 Backspace (0x08)
    -- 改送 \x1b[104;5u (CSI u 格式)，讓 Neovim 正確辨識為 <C-h>
    { key = "H", mods = "CTRL", action = act.SendString("\x1b[104;5u") },
}

return config
