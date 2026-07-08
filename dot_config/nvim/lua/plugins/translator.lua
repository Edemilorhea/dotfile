return {
  -- 選字 + 快捷鍵 -> 彈窗顯示翻譯結果（單次查詢，不互動）
  {
    "voldikss/vim-translator",
    keys = {
      -- normal/visual 需要不同的 <Plug> 標籤，不能共用同一個
      { "<leader>tr", "<Plug>Translate", mode = "n", desc = "Translate: popup (auto→繁中)" },
      { "<leader>tr", "<Plug>TranslateV", mode = "v", desc = "Translate: popup (auto→繁中)" },
      -- 不用 :Translate! (bang)：因為 source_lang='auto' 時 bang 交換邏輯不會觸發，改成明確指定 target_lang
      { "<leader>tR", ":Translate --target_lang=en<CR>", mode = { "n", "v" }, desc = "Translate: popup reverse (auto→en)" },
      { "<leader>tW", "<Plug>TranslateW", mode = "n", desc = "Translate: window" },
      { "<leader>tW", "<Plug>TranslateWV", mode = "v", desc = "Translate: window" },
      { "<leader>tx", "<Plug>TranslateX", mode = { "n" }, desc = "Translate: clipboard" },
    },
    init = function()
      vim.g.translator_default_engines = { "google" }
      vim.g.translator_source_lang = "auto"
      vim.g.translator_target_lang = "zh-TW" -- 繁體中文
      vim.g.translator_window_type = "popup"
      vim.g.translator_history_enable = true
    end,
  },

  -- 打字互動查詢，雙向查（中查英 / 英查中），視窗內按 gS 切換方向
  {
    "potamides/pantran.nvim",
    keys = {
      {
        "<leader>ti",
        function()
          return require("pantran").motion_translate()
        end,
        mode = { "n", "v" },
        expr = true,
        desc = "Translate: interactive window",
      },
    },
    opts = {
      default_engine = "google",
      engines = {
        google = {
          default_source = vim.NIL, -- 自動偵測來源語言（官方 API，需要 API key 才會用到）
          default_target = "zh-TW", -- 繁體中文（保留給以後有 API key 時用）
          fallback = {
            -- 沒設定 GOOGLE_API_KEY / GOOGLE_BEARER_TOKEN 時，pantran 實際使用這個免費 fallback 引擎
            default_source = "auto",
            default_target = "zh-TW", -- 目前實際生效的是這一層
          },
        },
      },
    },
  },
}
