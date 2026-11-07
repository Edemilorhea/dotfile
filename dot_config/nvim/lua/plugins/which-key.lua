-- which-key 中文說明，需與實際 keymap 保持一致。來源：
--   core/keymaps.lua、config/keymaps.lua、config/markdown_toc.lua
--   plugins/*.lua 的 keys，以及 LazyVim 內建鍵
-- 本檔放 Leader 鍵；非 Leader 鍵放在 config/which-key-builtin.lua。
return {
    {
        "folke/which-key.nvim",
        -- LazyVim 以 opts_extend = { "spec" } 把下列 spec 追加到它的英文預設後面，
        -- 同一個 lhs 會出現中英文重複（checkhealth duplicate）。合併後由後往前去重，保留本檔中文。
        opts = function(_, opts)
            local user_spec = {
                -- ── Leader 主群組 ─────────────────────────────
                { "<leader>b", group = "Buffer 管理" },
                { "<leader>c", group = "程式碼 / LSP" },
                { "<leader>d", group = "除錯 / Profiler" },
                { "<leader>dp", group = "Profiler" },
                { "<leader>f", group = "檔案 / 搜尋（Telescope）" },
                { "<leader>g", group = "Git" },
                { "<leader>h", group = "Flash 跳轉" },
                { "<leader>i", group = "插入 / Inlay" },
                { "<leader>m", group = "Markdown" },
                { "<leader>q", group = "Session / 離開" },
                { "<leader>s", group = "搜尋 / 視窗分割" },
                { "<leader>sn", group = "Noice 訊息" },
                { "<leader>t", group = "終端機 / 翻譯 / 工具" },
                { "<leader>u", group = "UI 切換" },
                { "<leader>w", group = "視窗", proxy = "<c-w>" },
                { "<leader>x", group = "診斷 / 清單" },
                { "<leader><Tab>", group = "分頁 Tab" },

                -- ── 頂層常用（LazyVim 內建）───────────────────
                { "<leader><space>", desc = "搜尋檔案（專案根目錄）" },
                { "<leader>,", desc = "切換 Buffer" },
                { "<leader>/", desc = "全文搜尋（專案根目錄）" },
                { "<leader>:", desc = "命令歷史" },
                { "<leader>`", desc = "切換上一個 Buffer" },
                { "<leader>?", desc = "顯示目前 Buffer 快捷鍵" },
                { "<leader>.", desc = "開關暫存 Buffer（Scratch）" },
                { "<leader>S", desc = "選擇暫存 Buffer（Scratch）" },
                { "<leader>-", desc = "水平分割視窗" },
                { "<leader>|", desc = "垂直分割視窗" },
                { "<leader>e", desc = "Neo-tree 檔案總管（專案根目錄）" },
                { "<leader>E", desc = "Neo-tree 檔案總管（目前工作目錄）" },
                { "<leader>K", desc = "用 keywordprg 查游標下的字（原生 K）" },
                { "<leader>l", desc = "Lazy 外掛管理" },
                { "<leader>L", desc = "LazyVim 更新紀錄" },
                { "<leader>n", desc = "通知歷史" },
                { "<leader>p", desc = "剪貼歷史（Yank History）", mode = { "n", "x" } },
                { "<leader>rr", desc = "重啟 Neovim 並還原上次 Session" },

                -- ── 分頁 Tab（LazyVim 內建）───────────────────
                { "<leader><Tab><Tab>", desc = "新增分頁" },
                { "<leader><Tab>[", desc = "上一個分頁" },
                { "<leader><Tab>]", desc = "下一個分頁" },
                { "<leader><Tab>d", desc = "關閉分頁" },
                { "<leader><Tab>f", desc = "第一個分頁" },
                { "<leader><Tab>l", desc = "最後一個分頁" },
                { "<leader><Tab>o", desc = "關閉其他分頁" },

                -- ── Buffer 管理 ───────────────────────────────
                { "<leader>bb", desc = "切換上一個 Buffer" },
                { "<leader>bc", desc = "選擇關閉 Buffer（BufferLinePick）" },
                { "<leader>bd", desc = "刪除 Buffer" },
                { "<leader>bD", desc = "刪除 Buffer 和視窗" },
                { "<leader>be", desc = "Buffer 總管" },
                { "<leader>bi", desc = "刪除不可見的 Buffer" },
                { "<leader>bj", desc = "選擇跳到 Buffer" },
                { "<leader>bl", desc = "刪除左側 Buffer" },
                { "<leader>br", desc = "刪除右側 Buffer" },
                { "<leader>bo", desc = "刪除其他 Buffer" },
                { "<leader>bp", desc = "釘選 / 取消釘選 Buffer" },
                { "<leader>bP", desc = "刪除未釘選的 Buffer" },
                { "<leader>b.", desc = "Buffer 右移" },
                { "<leader>b,", desc = "Buffer 左移" },

                -- ── 程式碼 / LSP ──────────────────────────────
                { "<leader>ca", desc = "程式碼動作" },
                { "<leader>cd", desc = "顯示本行診斷" },
                { "<leader>cf", desc = "格式化（Conform，非同步）" },
                { "<leader>cF", desc = "格式化內嵌語言" },
                { "<leader>ch", desc = "切換複選框（Obsidian 筆記）" },
                { "<leader>cm", desc = "開啟 Mason" },
                { "<leader>cr", desc = "重新命名符號" },
                { "<leader>cs", desc = "符號清單（Trouble）" },
                { "<leader>cS", desc = "LSP 參考 / 定義（Trouble）" },

                -- ── 除錯 / Profiler ───────────────────────────
                { "<leader>dpp", desc = "開關 Profiler" },
                { "<leader>dph", desc = "開關 Profiler 高亮" },
                { "<leader>dps", desc = "Profiler 暫存 Buffer" },

                -- ── 檔案 / 搜尋（Telescope，plugins/tools.lua）──
                { "<leader>ff", desc = "搜尋檔案" },
                { "<leader>fF", desc = "搜尋檔案（目前目錄）" },
                { "<leader>fg", desc = "全文搜尋（live grep）" },
                { "<leader>fb", desc = "搜尋 Buffer" },
                { "<leader>fB", desc = "搜尋 Buffer（全部）" },
                { "<leader>fc", desc = "搜尋設定檔" },
                { "<leader>fe", desc = "Neo-tree 檔案總管（專案根目錄）" },
                { "<leader>fE", desc = "Neo-tree 檔案總管（目前目錄）" },
                { "<leader>fh", desc = "搜尋說明文件" },
                { "<leader>fm", desc = "mini.files（目前檔案目錄）" },
                { "<leader>fM", desc = "mini.files（目前目錄）" },
                { "<leader>fn", desc = "新增檔案" },
                { "<leader>fr", desc = "最近開啟檔案（工作目錄）" },
                { "<leader>fR", desc = "最近開啟檔案（全域）" },
                { "<leader>ft", desc = "終端機（專案根目錄）" },
                { "<leader>fT", desc = "終端機（目前目錄）" },
                { "<leader>fw", desc = "搜尋游標文字" },
                { "<leader>fp", desc = "切換專案" },

                -- ── Flash 跳轉（plugins/editor.lua）───────────
                { "<leader>hf", desc = "Flash 跳轉" },
                { "<leader>hF", desc = "Flash 語法樹跳轉" },
                { "<leader>hr", desc = "語法樹搜尋" },
                { "<leader>he", desc = "切換 Flash 搜尋" },

                -- ── 插入 / Inlay ──────────────────────────────
                { "<leader>ih", desc = "臨時顯示 Inlay Hints（3 秒）" },
                { "<leader>ip", desc = "貼上圖片並插入 Markdown 語法" },
                { "<leader>i.", desc = "顯示工作目錄路徑" },

                -- ── Git ───────────────────────────────────────
                { "<leader>gg", desc = "Lazygit（專案根目錄）" },
                { "<leader>gG", desc = "Lazygit（目前目錄）" },
                { "<leader>gb", desc = "目前行的 commit 歷史" },
                { "<leader>gB", desc = "在瀏覽器開啟 Git 頁面", mode = { "n", "x" } },
                { "<leader>gY", desc = "複製 Git 頁面網址", mode = { "n", "x" } },
                { "<leader>gd", desc = "Git diff hunks" },
                { "<leader>gD", desc = "Git diff origin" },
                { "<leader>ge", desc = "Git 檔案總管（Neo-tree）" },
                { "<leader>gf", desc = "目前檔案 Git 歷史" },
                { "<leader>gi", desc = "GitHub Issues（未關閉）" },
                { "<leader>gI", desc = "GitHub Issues（全部）" },
                { "<leader>gp", desc = "GitHub PR（未關閉）" },
                { "<leader>gP", desc = "GitHub PR（全部）" },
                { "<leader>gl", desc = "Git log" },
                { "<leader>gL", desc = "Git log（目前目錄）" },
                { "<leader>gs", desc = "Git 狀態" },
                { "<leader>gS", desc = "Git stash" },
                { "<leader>gv", desc = "Diffview：對比目前變更" },
                { "<leader>gV", desc = "Diffview：目前檔案歷史" },
                { "<leader>gq", desc = "Diffview：關閉" },
                -- Hunk / Blame（gitsigns，LazyVim 內建 + plugins/git.lua）
                { "<leader>gh", group = "Hunk / Blame" },
                { "<leader>ghs", desc = "Stage hunk" },
                { "<leader>ghr", desc = "還原 hunk" },
                { "<leader>ghS", desc = "Stage 整個檔案" },
                { "<leader>ghu", desc = "取消上次 stage hunk" },
                { "<leader>ghR", desc = "還原整個檔案" },
                { "<leader>ghp", desc = "行內預覽 hunk" },
                { "<leader>ghb", desc = "Blame 目前行（浮動視窗）" },
                { "<leader>ghB", desc = "Blame 整個檔案" },
                { "<leader>ght", desc = "切換行尾 blame" },
                { "<leader>ghd", desc = "對比目前檔案（index）" },
                { "<leader>ghD", desc = "對比目前檔案（上一個 commit）" },

                -- ── Markdown ──────────────────────────────────
                { "<leader>mt", desc = "生成 Wiki 格式 TOC" },
                { "<leader>mT", desc = "生成標準 Markdown TOC" },
                { "<leader>mr", desc = "移除 TOC" },
                { "<leader>mg", desc = "跳轉到 TOC" },
                { "<leader>mp", desc = "開啟 Markdown 預覽" },
                { "<leader>mP", desc = "停止 Markdown 預覽" },
                { "<leader>mv", desc = "切換 Markdown 預覽" },

                -- ── Session / 離開（LazyVim 內建）─────────────
                { "<leader>qs", desc = "還原 Session" },
                { "<leader>ql", desc = "還原上一個 Session" },
                { "<leader>qS", desc = "選擇 Session" },
                { "<leader>qd", desc = "目前 Session 不儲存" },
                { "<leader>qq", desc = "全部退出" },

                -- ── 搜尋（LazyVim 內建）───────────────────────
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
                { '<leader>s"', desc = "搜尋暫存器" },
                { "<leader>s/", desc = "搜尋歷史" },
                { "<leader>sa", desc = "搜尋 Autocmd" },
                { "<leader>sC", desc = "搜尋命令" },
                { "<leader>sH", desc = "搜尋高亮群組" },
                { "<leader>si", desc = "搜尋圖示" },
                { "<leader>sj", desc = "搜尋跳轉紀錄" },
                { "<leader>sl", desc = "Location 清單" },
                { "<leader>sm", desc = "搜尋標記" },
                { "<leader>sM", desc = "搜尋 Man Pages" },
                { "<leader>sp", desc = "搜尋外掛設定" },
                { "<leader>sq", desc = "Quickfix 清單" },
                { "<leader>st", desc = "搜尋 Todo" },
                { "<leader>sT", desc = "搜尋 Todo / Fix / FIXME" },
                { "<leader>su", desc = "復原歷史（Undotree）" },
                -- 視窗分割 / 取代（config/keymaps.lua，覆寫 LazyVim 的 \sh、\sr）
                { "<leader>sv", desc = "垂直分割視窗" },
                { "<leader>sh", desc = "水平分割視窗" },
                { "<leader>sx", desc = "關閉分割視窗" },
                { "<leader>sr", desc = "取代游標文字 / 選取範圍" },
                { "<leader>sc", desc = "清除搜尋高亮" },
                -- Noice 訊息（LazyVim 內建）
                { "<leader>snl", desc = "上一則 Noice 訊息" },
                { "<leader>snh", desc = "Noice 訊息歷史" },
                { "<leader>sna", desc = "全部 Noice 訊息" },
                { "<leader>snd", desc = "關閉所有 Noice 訊息" },
                { "<leader>snt", desc = "Noice 訊息搜尋" },

                -- ── 終端機 / 翻譯 / 工具（plugins/tools.lua、translator.lua）──
                { "<leader>tc", desc = "新增終端機" },
                { "<leader>tt", desc = "切換終端機" },
                { "<leader>tp", desc = "上一個終端機" },
                { "<leader>tn", desc = "下一個終端機" },
                { "<leader>tq", desc = "關閉終端機" },
                { "<leader>th", desc = "隱藏終端機" },
                { "<leader>ts", desc = "切換浮動／右側分割" },
                { "<leader>ty", desc = "開啟 Yazi（當前檔案）" },
                { "<leader>tw", desc = "開啟 Yazi（工作目錄）" },
                { "<leader>tr", desc = "翻譯：彈窗（自動 → 繁中）", mode = { "n", "x" } },
                { "<leader>tR", desc = "翻譯：彈窗（自動 → 英文）", mode = { "n", "x" } },
                { "<leader>tW", desc = "翻譯：視窗", mode = { "n", "x" } },
                { "<leader>ti", desc = "翻譯：互動視窗", mode = { "n", "x" } },
                { "<leader>tx", desc = "翻譯：剪貼簿內容" },

                -- ── UI 切換 ───────────────────────────────────
                { "<leader>ua", desc = "切換動畫" },
                { "<leader>uA", desc = "切換分頁列" },
                { "<leader>ub", desc = "切換深色背景" },
                { "<leader>uc", desc = "切換隱藏字元（Conceal）" },
                { "<leader>uC", desc = "選擇配色主題" },
                { "<leader>ud", desc = "切換診斷顯示" },
                { "<leader>uD", desc = "切換非焦點區淡化" },
                { "<leader>uE", desc = "切換 ESLint LSP" },
                { "<leader>uf", desc = "切換自動格式化（全域）" },
                { "<leader>uF", desc = "切換自動格式化（Buffer）" },
                { "<leader>ug", desc = "切換縮排參考線" },
                { "<leader>uh", desc = "開關 Inlay Hints" },
                { "<leader>ui", desc = "檢查游標位置高亮" },
                { "<leader>uI", desc = "檢查語法樹" },
                { "<leader>ul", desc = "切換行號" },
                { "<leader>uL", desc = "切換相對行號" },
                { "<leader>un", desc = "關閉所有通知" },
                { "<leader>up", desc = "切換自動配對括號" },
                { "<leader>ur", desc = "重繪 / 清除搜尋高亮 / 更新 diff" },
                { "<leader>us", desc = "切換拼字檢查" },
                { "<leader>uS", desc = "切換平滑捲動" },
                { "<leader>uT", desc = "切換 Treesitter 高亮" },
                { "<leader>uw", desc = "切換自動換行" },
                { "<leader>uz", desc = "切換 Zen 模式" },
                { "<leader>uZ", desc = "切換視窗放大" },

                -- ── 視窗（<leader>w 代理 <C-w>）────────────────
                { "<leader>wd", desc = "關閉視窗" },
                { "<leader>wm", desc = "切換視窗放大" },

                -- ── 診斷 / 清單 ───────────────────────────────
                { "<leader>xx", desc = "顯示並進入本行診斷浮窗" },
                { "<leader>xX", desc = "目前 Buffer 診斷（Trouble）" },
                { "<leader>xl", desc = "Location 清單" },
                { "<leader>xq", desc = "Quickfix 清單" },
                { "<leader>xL", desc = "Location 清單（Trouble）" },
                { "<leader>xQ", desc = "Quickfix 清單（Trouble）" },
                { "<leader>xt", desc = "Todo 清單（Trouble）" },
                { "<leader>xT", desc = "Todo / Fix / FIXME（Trouble）" },
            }

            opts.spec = opts.spec or {}
            vim.list_extend(opts.spec, user_spec)
            vim.list_extend(opts.spec, require("config.which-key-builtin"))

            -- 去重：同一 lhs（item[1]）只保留最後一次定義（本檔中文覆蓋 LazyVim 英文）
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
