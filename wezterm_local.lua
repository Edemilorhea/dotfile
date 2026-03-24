-- wezterm_local.lua.example
-- 本機專屬配置範例檔
--
-- 使用方式:
-- 1. 複製這個檔案為 wezterm_local.lua
-- 2. 修改下面的路徑為你的實際路徑
-- 3. 重啟 WezTerm
--
-- 注意: wezterm_local.lua 不應該加入 git (已在 .gitignore)

return {
    -- 路徑配置
    paths = {
        projects = "E:/Project/GSS_ESG2412/", -- 專案目錄
        config = "C:/Users/tc_tseng/Desktop/config", -- 配置目錄
        notes = "C:/notes", -- 筆記目錄
    },

    -- (可選) 額外的 launch menu 項目
    -- extra_launch_items = {
    --     {
    --         label = "🗄️ 資料庫目錄",
    --         args = { "pwsh.exe" },
    --         cwd = "D:/databases",
    --     },
    --     {
    --         label = "🌐 網站根目錄",
    --         args = { "pwsh.exe" },
    --         cwd = "C:/inetpub/wwwroot",
    --     },
    -- },

    -- (可選) 本機專屬設定
    settings = {
        font_size = 12, -- 字型大小
    },
}
