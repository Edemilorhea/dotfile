-- plugins/ui-restructured.lua
-- UI 相關插件，只在 Neovim 中使用

return {
  -- 主題設定 (只在 Neovim 中使用)
  -- 主題：rose-pine-moon (透明背景)；備用：tokyonight / catppuccin
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode,
    opts = {
      variant = "moon",
      dark_variant = "moon",
      styles = {
        italic = true,
        transparency = true, -- 透明背景
      },
    },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      local ok = pcall(vim.cmd, "colorscheme rose-pine-moon")
      if not ok then
        vim.notify("rose-pine 載入失敗，切換至 tokyonight", vim.log.levels.WARN)
        vim.cmd("colorscheme tokyonight-night")
      end
    end,
  },
  -- tokyonight 備用主題 (可用 :colorscheme tokyonight-night 切換)
  {
    "folke/tokyonight.nvim",
    lazy = true,
    cond = not vim.g.vscode,
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
      },
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true, -- 作為 fallback，不主動套用
    priority = 900,
    cond = not vim.g.vscode,
  },
  
  -- Neo-tree 檔案管理器 (只在 Neovim 中使用)
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false, -- 已停用，改用 Snacks Explorer（<leader>e / <leader>E）
    cmd = { "Neotree" },
    cond = not vim.g.vscode,
    keys = {
      { "<leader>oe", "<cmd>Neotree toggle<cr>", desc = "切換 Neo-tree" },
      { "<leader>oE", "<cmd>Neotree reveal<cr>", desc = "Neo-tree 顯示目前檔案" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = true,
        open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
        sort_case_insensitive = false,
        
        default_component_configs = {
          container = { enable_character_fade = true },
          indent = {
            indent_size = 2,
            padding = 1,
            with_markers = true,
            indent_marker = "│",
            last_indent_marker = "└",
            highlight = "NeoTreeIndentMarker",
            with_expanders = nil,
            expander_collapsed = "",
            expander_expanded = "",
            expander_highlight = "NeoTreeExpander",
          },
          icon = {
            folder_closed = "",
            folder_open = "",
            folder_empty = "ﰊ",
            folder_empty_open = "",
            default = "*",
            highlight = "NeoTreeFileIcon",
          },
          modified = { symbol = "[+]", highlight = "NeoTreeModified" },
          name = {
            trailing_slash = false,
            use_git_status_colors = true,
            highlight = "NeoTreeFileName",
          },
          git_status = {
            symbols = {
              added = "",
              modified = "",
              deleted = "✖",
              renamed = "",
              untracked = "",
              ignored = "",
              unstaged = "",
              staged = "",
              conflict = "",
            },
          },
        },
        
        window = {
          position = "left",
          width = 25,
          mapping_options = { noremap = true, nowait = true },
        },
        
        filesystem = {
          filtered_items = {
            visible = false,
            hide_dotfiles = false,
            hide_gitignored = true,
            hide_hidden = true,
            hide_by_name = { "node_modules" },
            hide_by_pattern = {},
            always_show = {},
            never_show = {},
            never_show_by_pattern = {},
          },
          follow_current_file = { enabled = true },
          group_empty_dirs = false,
          hijack_netrw_behavior = "open_default",
          use_libuv_file_watcher = false,
          
          window = {
            mappings = {
              ["<bs>"] = "navigate_up",
              ["."] = "set_root",
              ["H"] = "toggle_hidden",
              ["/"] = "fuzzy_finder",
              ["D"] = "fuzzy_finder_directory",
              ["#"] = "fuzzy_sorter",
              ["f"] = "filter_on_submit",
              ["<c-x>"] = "clear_filter",
              ["[g"] = "prev_git_modified",
              ["]g"] = "next_git_modified",
            },
          },
        },
        
        buffers = {
          follow_current_file = { enabled = true },
          group_empty_dirs = true,
          show_unloaded = true,
          window = {
            mappings = {
              ["bd"] = "buffer_delete",
              ["<bs>"] = "navigate_up",
              ["."] = "set_root",
            },
          },
        },
        
        git_status = {
          window = {
            position = "float",
            mappings = {
              ["A"] = "git_add_all",
              ["gu"] = "git_unstage_file",
              ["ga"] = "git_add_file",
              ["gr"] = "git_revert_file",
              ["gc"] = "git_commit",
              ["gp"] = "git_push",
              ["gg"] = "git_commit_and_push",
            },
          },
        },
      })
    end,
  },
  
  -- Snacks Explorer：LazyVim 新版預設檔案瀏覽器
  {
    "folke/snacks.nvim",
    cond = not vim.g.vscode,
    opts = function(_, opts)
      opts.explorer = opts.explorer or {}
    end,
    keys = {
      {
        "<leader>e",
        function()
          Snacks.explorer({ cwd = LazyVim.root() })
        end,
        desc = "Snacks Explorer（專案根目錄）",
      },
      {
        "<leader>E",
        function()
          Snacks.explorer()
        end,
        desc = "Snacks Explorer（目前工作目錄）",
      },
    },
  },
  
  -- Trouble 診斷視窗 (只在 Neovim 中使用)
  {
    "folke/trouble.nvim",
    optional = true,
    cond = not vim.g.vscode,
    opts = {
      auto_close = true,
      auto_open = false,
      use_diagnostic_signs = true,
    },
  },
  
  -- Bufferline 標籤列 (只在 Neovim 中使用)
  {
    "akinsho/bufferline.nvim",
    optional = true,
    cond = not vim.g.vscode,
    opts = {
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",
        separator_style = "slant",
        show_buffer_close_icons = true,
        show_close_icon = false,
        always_show_bufferline = true,
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            highlight = "Directory",
            separator = true,
          },
        },
      },
    },
  },
  
  -- Lualine 狀態列 (只在 Neovim 中使用)
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    cond = not vim.g.vscode,
    opts = {
      options = {
        theme = "auto",
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
}
