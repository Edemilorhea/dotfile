local M = {}

-- 1. 定義這台電腦的「工作空間套餐」
M.workspaces = {
    {
        label = "📦 啟動：蝦皮開發環境 (三個獨立分頁)",
        id = "shopee_tabs",
        tabs = {
            { title = "API", cwd = "E:/Work/AntQ_Shopee/Program/shopee-api/" },
            { title = "Backend", cwd = "E:/Work/AntQ_Shopee/Program/sip-pos-backend/" },
            { title = "Frontend", cwd = "E:/Work/AntQ_Shopee/Program/sip-pos-frontend/" },
        },
    },
    -- 你可以繼續增加其他套餐...
    -- {
    --     label = "🎨 啟動：個人專案",
    --     id = "personal",
    --     tabs = { { title = "Web", cwd = "C:/Users/User/MyWeb" } }
    -- }
}

-- 2. 定義這台電腦的「單一目錄選單」
M.launch_menu = {
    { label = "ShopeeApi", cwd = "E:/Work/AntQ_Shopee/Program/shopee-api/" },
    { label = "前端VB", cwd = "E:/Work/AntQ_Shopee/Program/sip-pos-frontend-vb/" },
    { label = "後端React", cwd = "E:/Work/AntQ_Shopee/Program/sip-pos-backend/" },
    { label = "前端React", cwd = "E:/Work/AntQ_Shopee/Program/sip-pos-frontend/" },
}

return M
