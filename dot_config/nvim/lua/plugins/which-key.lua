-- plugins/which-key.lua
-- which-key 提示完全對齊實際 keymaps（中文化）
-- 來源對照：
--   keymap/general.lua、keymap/neovim.lua、keymap/hotKeyMaps.lua
--   plugins/tools.lua（Telescope <leader>f / floaterm <leader>t）
--   plugins/markdown-enhanced.lua（obsidian / preview / peek <leader>m）
--   config/keymaps.lua（覆寫 <leader>cf、ESLint <leader>uE）
--   以及 LazyVim 內建鍵

return {
  {
    "folke/which-key.nvim",
    -- 用 function 形式：LazyVim 以 opts_extend={"spec"} 把下列 spec「追加」到其英文預設後面，
    -- 會造成同一 lhs 中英文群組名重複 (checkhealth duplicate)。於 merged 後去重，
    -- 由後往前掃保留「最後定義」(即本檔中文)，移除 LazyVim 英文重複項。
    opts = function(_, opts)
      local user_spec = {
        -- ── Leader 主群組 ─────────────────────────────
        { "<leader>b", group = "Buffer 管理" },
        { "<leader>c", group = "程式碼 / LSP" },
        { "<leader>d", group = "除錯 / Profiler" },
        { "<leader>f", group = "檔案 / 搜尋（Telescope）" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Flash 跳轉" },
        { "<leader>i", group = "插入 / Inlay" },
        { "<leader>m", group = "Markdown" },
        { "<leader>q", group = "Session / 離開" },
        { "<leader>s", group = "搜尋 / 視窗分割" },
        { "<leader>sn", group = "Noice 訊息" },
        { "<leader>t", group = "終端機（Floaterm）" },
        { "<leader>o", group = "其他 / Neo-tree" },
        { "<leader>u", group = "UI 切換" },
        { "<leader>w", group = "視窗" },
        { "<leader>x", group = "診斷 / Trouble" },
        { "<leader><Tab>", group = "分頁 Tab" },

        -- ── 頂層常用（LazyVim 內建）───────────────────
        { "<leader><space>", desc = "搜尋檔案（專案根目錄）" },
        { "<leader>,", desc = "切換 Buffer" },
        { "<leader>/", desc = "全文搜尋（專案根目錄）" },
        { "<leader>:", desc = "命令歷史" },
        { "<leader>`", desc = "切換上一個 Buffer" },
        { "<leader>?", desc = "顯示目前 Buffer 快捷鍵" },
        { "<leader>r", desc = "重新載入 LazyVim 設定" },

        -- ── Buffer 管理 ───────────────────────────────
        { "<leader>bb", desc = "切換上一個 Buffer" },
        { "<leader>bc", desc = "選擇關閉 Buffer（BufferLinePick）" },
        { "<leader>bd", desc = "刪除 Buffer" },
        { "<leader>bD", desc = "刪除 Buffer 和視窗" },
        { "<leader>bo", desc = "刪除其他 Buffer" },
        { "<leader>bp", desc = "釘選 / 取消釘選 Buffer" },

        -- ── 程式碼 / LSP ──────────────────────────────
        { "<leader>ca", desc = "程式碼動作" },
        { "<leader>cd", desc = "顯示本行診斷" },
        { "<leader>cf", desc = "格式化（dprint→biome→prettier→LSP）" },
        { "<leader>ch", desc = "切換複選框（Markdown）" },
        { "<leader>cm", desc = "開啟 Mason" },
        { "<leader>cr", desc = "重新命名符號" },
        { "<leader>cs", desc = "符號清單（Trouble）" },
        { "<leader>cS", desc = "LSP 參考 / 定義（Trouble）" },

        -- ── 檔案 / 搜尋（Telescope，tools.lua）─────────
        { "<leader>ff", desc = "搜尋檔案" },
        { "<leader>fg", desc = "全文搜尋（live grep）" },
        { "<leader>fb", desc = "搜尋 Buffer" },
        { "<leader>fh", desc = "搜尋說明文件" },
        { "<leader>fr", desc = "最近開啟檔案" },
        { "<leader>fw", desc = "搜尋游標文字" },

        -- ── Flash 跳轉（hotKeyMaps.lua）───────────────
        { "<leader>hf", desc = "Flash 跳轉" },
        { "<leader>hF", desc = "Flash 語法樹跳轉" },
        { "<leader>hr", desc = "語法樹搜尋" },
        { "<leader>he", desc = "切換 Flash 搜尋" },

        -- ── 插入 / Inlay（neovim.lua / markdown）──────
        { "<leader>ih", desc = "臨時顯示 Inlay Hints（3 秒）" },
        { "<leader>ip", desc = "貼上圖片並插入 Markdown 語法" },

        -- ── Git（LazyVim 內建）────────────────────────
        { "<leader>gg", desc = "Lazygit（專案根目錄）" },
        { "<leader>gG", desc = "Lazygit（目前目錄）" },
        { "<leader>gb", desc = "Git blame 目前行" },
        { "<leader>gd", desc = "Git diff hunks" },
        { "<leader>gD", desc = "Git diff origin" },
        { "<leader>gf", desc = "目前檔案 Git 歷史" },
        { "<leader>gh", desc = "Diffview：目前檔案歷史" },
        { "<leader>gl", desc = "Git log" },
        { "<leader>gL", desc = "Git log（目前目錄）" },
        { "<leader>gs", desc = "Git 狀態" },
        { "<leader>gS", desc = "Git stash" },
        { "<leader>gv", desc = "Diffview：對比目前變更" },

        -- ── Markdown（obsidian / preview / peek）──────
        { "<leader>mt", desc = "生成 Wiki 格式 TOC" },
        { "<leader>mT", desc = "生成標準 Markdown TOC" },
        { "<leader>mr", desc = "移除 TOC" },
        { "<leader>mg", desc = "跳轉到 TOC" },
        { "<leader>mp", desc = "開啟 Markdown 預覽" },
        { "<leader>mP", desc = "停止 Markdown 預覽" },
        { "<leader>mv", desc = "切換 Markdown 預覽" },
        { "<leader>mpo", desc = "開啟 Peek 預覽" },
        { "<leader>mpc", desc = "關閉 Peek 預覽" },

        -- ── Session / 離開（LazyVim 內建）─────────────
        { "<leader>qs", desc = "還原 Session" },
        { "<leader>ql", desc = "還原上一個 Session" },
        { "<leader>qS", desc = "選擇 Session" },
        { "<leader>qd", desc = "目前 Session 不儲存" },
        { "<leader>qq", desc = "全部退出" },

        -- ── 搜尋 / 視窗分割 ───────────────────────────
        -- 搜尋（LazyVim 內建）
        { "<leader>sg", desc = "全文搜尋（專案根目錄）" },
        { "<leader>sG", desc = "全文搜尋（目前目錄）" },
        { "<leader>sb", desc = "搜尋目前 Buffer 行" },
        { "<leader>sB", desc = "搜尋所有開啟 Buffer" },
        { "<leader>sd", desc = "搜尋診斷" },
        { "<leader>sD", desc = "搜尋本 Buffer 診斷" },
        { "<leader>sk", desc = "搜尋快捷鍵" },
        { "<leader>sR", desc = "恢復上次搜尋" },
        { "<leader>sw", desc = "搜尋游標文字（根目錄）" },
        { "<leader>sW", desc = "搜尋游標文字（目前目錄）" },
        -- 視窗分割 / 取代（neovim.lua，覆寫部分 LazyVim 搜尋鍵）
        { "<leader>sv", desc = "垂直分割視窗" },
        { "<leader>sh", desc = "水平分割視窗" },
        { "<leader>sx", desc = "關閉分割視窗" },
        { "<leader>sr", desc = "取代游標文字 / 選取範圍" },
        -- Noice 訊息（LazyVim 內建）
        { "<leader>snl", desc = "上一則 Noice 訊息" },
        { "<leader>snh", desc = "Noice 訊息歷史" },
        { "<leader>sna", desc = "全部 Noice 訊息" },
        { "<leader>snd", desc = "關閉所有 Noice 訊息" },

        -- ── 終端機（Floaterm，tools.lua）──────────────
        { "<leader>tc", desc = "新增終端機" },
        { "<leader>tt", desc = "切換終端機" },
        { "<leader>tp", desc = "上一個終端機" },
        { "<leader>tn", desc = "下一個終端機" },
        { "<leader>tg", desc = "開啟 Lazygit" },
        { "<leader>tq", desc = "關閉終端機" },
        { "<leader>th", desc = "隱藏終端機" },

        -- ── 其他 / Neo-tree（LazyVim / Snacks）────────
        { "<leader>e", desc = "Snacks Explorer（專案根目錄）" },
        { "<leader>E", desc = "Snacks Explorer（目前工作目錄）" },
        { "<leader>oe", desc = "切換 Neo-tree" },
        { "<leader>oE", desc = "Neo-tree 顯示目前檔案" },

        -- ── UI 切換 ───────────────────────────────────
        { "<leader>ud", desc = "切換診斷顯示" },
        { "<leader>uE", desc = "切換 ESLint LSP" },
        { "<leader>uf", desc = "切換自動格式化（全域）" },
        { "<leader>uF", desc = "切換自動格式化（Buffer）" },
        { "<leader>uh", desc = "開關 Inlay Hints" },
        { "<leader>ul", desc = "切換行號" },
        { "<leader>uL", desc = "切換相對行號" },
        { "<leader>us", desc = "切換拼字檢查" },
        { "<leader>uw", desc = "切換自動換行" },

        -- ── 診斷 / Trouble（neovim.lua + LazyVim）─────
        { "<leader>xx", desc = "顯示本行診斷（浮動）" },
        { "<leader>xX", desc = "目前 Buffer 診斷（Trouble）" },
        { "<leader>xq", desc = "Quickfix 清單（Trouble）" },
        { "<leader>xl", desc = "Location 清單（Trouble）" },
        { "<leader>xt", desc = "Todo 清單（Trouble）" },
        { "<leader>xT", desc = "Todo / Fix / FIXME（Trouble）" },
        { "<leader>xm", desc = "切換診斷多行顯示" },

        -- ══ 非 Leader 內建鍵中文化 ════════════════════

        -- ── z：摺疊 / 捲動 / 拼字 ─────────────────────
        { "z", group = "摺疊 / 捲動 / 拼字" },
        -- 摺疊（fold）
        { "za", desc = "切換摺疊" },
        { "zA", desc = "遞迴切換摺疊" },
        { "zc", desc = "關閉摺疊" },
        { "zC", desc = "遞迴關閉摺疊" },
        { "zo", desc = "開啟摺疊" },
        { "zO", desc = "遞迴開啟摺疊" },
        { "zv", desc = "展開以顯示游標行" },
        { "zM", desc = "關閉所有摺疊" },
        { "zR", desc = "開啟所有摺疊" },
        { "zm", desc = "摺疊增加一級" },
        { "zr", desc = "摺疊減少一級" },
        { "zj", desc = "移到下一個摺疊" },
        { "zk", desc = "移到上一個摺疊" },
        { "zf", desc = "建立摺疊" },
        { "zd", desc = "刪除摺疊" },
        { "zD", desc = "遞迴刪除摺疊" },
        { "zE", desc = "刪除所有摺疊" },
        -- 捲動 / 游標定位
        { "zz", desc = "游標行置中" },
        { "zt", desc = "游標行移到頂端" },
        { "zb", desc = "游標行移到底端" },
        { "z.", desc = "游標行置中並移到行首" },
        { "zh", desc = "向左捲動" },
        { "zl", desc = "向右捲動" },
        { "zH", desc = "向左捲動半畫面" },
        { "zL", desc = "向右捲動半畫面" },
        -- 拼字
        { "zg", desc = "加入拼字字典" },
        { "zw", desc = "標記為拼字錯誤" },
        { "zug", desc = "取消加入拼字字典" },
        { "zuw", desc = "取消標記拼字錯誤" },
        { "z=", desc = "拼字建議" },

        -- ── g：跳轉 / LSP / 註解 ──────────────────────
        { "g", group = "跳轉 / LSP / 註解" },
        -- 跳轉
        { "gg", desc = "移到檔案開頭" },
        { "gd", desc = "跳到定義" },
        { "gD", desc = "跳到宣告" },
        { "gy", desc = "跳到型別定義" },
        { "gi", desc = "跳到實作" },
        { "gr", desc = "跳到參考" },
        { "gx", desc = "用外部程式開啟連結" },
        { "gf", desc = "跳到游標下的檔案" },
        { "gO", desc = "文件符號大綱" },
        { "g;", desc = "跳到上一次修改處" },
        { "g,", desc = "跳到下一次修改處" },
        { "gv", desc = "重新選取上次選取範圍" },
        { "gn", desc = "選取下一個搜尋符合" },
        { "gN", desc = "選取上一個搜尋符合" },
        -- LSP（Neovim 內建 grX 系列）
        { "gra", desc = "程式碼動作（Code Action）" },
        { "gri", desc = "跳到實作（LSP）" },
        { "grn", desc = "重新命名符號（LSP）" },
        { "grr", desc = "跳到參考（LSP）" },
        { "grt", desc = "跳到型別定義（LSP）" },
        { "grx", desc = "診斷動作（LSP）" },
        -- 註解
        { "gc", desc = "註解（運算子 / 選取範圍）" },
        { "gcc", desc = "註解目前行" },
        { "gco", desc = "下方新增註解行" },
        { "gcO", desc = "上方新增註解行" },
        { "gcA", desc = "行尾新增註解" },
        -- 大小寫 / 格式
        { "gu", desc = "轉小寫（運算子）" },
        { "gU", desc = "轉大寫（運算子）" },
        { "g~", desc = "大小寫互換（運算子）" },
        { "gq", desc = "格式化文字（運算子）" },
        { "gw", desc = "格式化文字（游標不動）" },
        { "gJ", desc = "合併行（不加空白）" },

        -- ── [ ：上一個 / 向前導覽 ─────────────────────
        { "[", group = "上一個 / 向前導覽" },
        { "[b", desc = "上一個 Buffer" },
        { "[B", desc = "第一個 Buffer" },
        { "[d", desc = "上一個診斷" },
        { "[D", desc = "第一個診斷" },
        { "[q", desc = "上一個 Quickfix 項目" },
        { "[Q", desc = "第一個 Quickfix 項目" },
        { "[l", desc = "上一個 Location 項目" },
        { "[L", desc = "第一個 Location 項目" },
        { "[a", desc = "上一個 Argument 檔案" },
        { "[A", desc = "第一個 Argument 檔案" },
        { "[t", desc = "上一個分頁 Tab" },
        { "[T", desc = "第一個分頁 Tab" },
        { "[<Space>", desc = "上方新增空行" },
        { "[<C-L>", desc = "上一個 Location（含換行）" },
        { "[<C-Q>", desc = "上一個 Quickfix（含換行）" },
        { "[<C-T>", desc = "上一個標籤 Tag" },
        { "[c", desc = "上一個變更（diff / hunk）" },
        { "[%", desc = "上一個未配對的括號" },
        { "[m", desc = "上一個方法開頭" },

        -- ── ] ：下一個 / 向後導覽 ─────────────────────
        { "]", group = "下一個 / 向後導覽" },
        { "]b", desc = "下一個 Buffer" },
        { "]B", desc = "最後一個 Buffer" },
        { "]d", desc = "下一個診斷" },
        { "]D", desc = "最後一個診斷" },
        { "]q", desc = "下一個 Quickfix 項目" },
        { "]Q", desc = "最後一個 Quickfix 項目" },
        { "]l", desc = "下一個 Location 項目" },
        { "]L", desc = "最後一個 Location 項目" },
        { "]a", desc = "下一個 Argument 檔案" },
        { "]A", desc = "最後一個 Argument 檔案" },
        { "]t", desc = "下一個分頁 Tab" },
        { "]T", desc = "最後一個分頁 Tab" },
        { "]<Space>", desc = "下方新增空行" },
        { "]<C-L>", desc = "下一個 Location（含換行）" },
        { "]<C-Q>", desc = "下一個 Quickfix（含換行）" },
        { "]<C-T>", desc = "下一個標籤 Tag" },
        { "]c", desc = "下一個變更（diff / hunk）" },
        { "]%", desc = "下一個未配對的括號" },
        { "]m", desc = "下一個方法開頭" },

        -- ── <C-w>：視窗操作 ───────────────────────────
        { "<C-w>", group = "視窗操作" },
        { "<C-w>s", desc = "水平分割視窗" },
        { "<C-w>v", desc = "垂直分割視窗" },
        { "<C-w>w", desc = "切換到下一個視窗" },
        { "<C-w>p", desc = "切換到上一個視窗" },
        { "<C-w>h", desc = "移到左側視窗" },
        { "<C-w>j", desc = "移到下方視窗" },
        { "<C-w>k", desc = "移到上方視窗" },
        { "<C-w>l", desc = "移到右側視窗" },
        { "<C-w>q", desc = "關閉視窗" },
        { "<C-w>c", desc = "關閉視窗（保留 Buffer）" },
        { "<C-w>o", desc = "只保留目前視窗" },
        { "<C-w>=", desc = "視窗大小均分" },
        { "<C-w>+", desc = "增高視窗" },
        { "<C-w>-", desc = "降低視窗" },
        { "<C-w>>", desc = "加寬視窗" },
        { "<C-w><", desc = "縮窄視窗" },
        { "<C-w>_", desc = "視窗高度最大化" },
        { "<C-w>|", desc = "視窗寬度最大化" },
        { "<C-w>H", desc = "視窗移到最左" },
        { "<C-w>J", desc = "視窗移到最下" },
        { "<C-w>K", desc = "視窗移到最上" },
        { "<C-w>L", desc = "視窗移到最右" },
        { "<C-w>x", desc = "與下一個視窗互換" },
        { "<C-w>r", desc = "旋轉視窗順序" },
        { "<C-w>T", desc = "視窗移到新分頁" },
        { "<C-w>d", desc = "顯示游標下診斷" },
      }

      -- 把本檔 spec 追加到 LazyVim 既有 spec 後面
      opts.spec = opts.spec or {}
      for _, item in ipairs(user_spec) do
        table.insert(opts.spec, item)
      end

      -- 去重：同一 lhs (item[1]) 只保留最後一次定義 (本檔中文覆蓋 LazyVim 英文)
      local seen = {}
      local deduped = {}
      for i = #opts.spec, 1, -1 do
        local item = opts.spec[i]
        if type(item) == "table" and type(item[1]) == "string" then
          if not seen[item[1]] then
            seen[item[1]] = true
            table.insert(deduped, 1, item)
          end
        else
          table.insert(deduped, 1, item)
        end
      end
      opts.spec = deduped

      return opts
    end,
  },
}
