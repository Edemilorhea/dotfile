# psmux 狀態列配置說明

## 📋 概述

本配置為 psmux 建立了類似 Zellij zjstatus 的狀態列，使用 Ocean Dark 配色方案，完美對應您的 Alacritty 和 Zellij 配置。

## 🎨 狀態列布局

```
┌────────────────────────────────────────────────────────────┐
│ [main] 1:pwsh    1:pwsh│2:nvim*│3:htop    2026-04-02 14:30 │
└────────────────────────────────────────────────────────────┘
```

### 區域說明

| 區域 | 內容                       | 對應 zjstatus       |
| ---- | -------------------------- | ------------------- |
| 左側 | Session 名稱 + 當前視窗    | `{session}`         |
| 中間 | 所有視窗列表               | `{tabs}`            |
| 右側 | 日期時間 (台北時區)        | `{datetime}`        |

## 🎯 視窗狀態指示

### 視窗旗標 (Flags)

| 符號 | 意義           | 顏色   |
| ---- | -------------- | ------ |
| `*`  | 當前活動視窗   | 藍色   |
| `-`  | 最後活動視窗   | 青色   |
| `#`  | 有新活動       | 黃色   |
| `!`  | 有響鈴通知     | 紅色   |
| `~`  | 靜音           | 灰色   |
| `Z`  | 縮放模式       | 藍色   |

### 視窗樣式

- **活動視窗**: 藍色、粗體、斜體 (`#8fa1b3`)
- **非活動視窗**: 灰色 (`#65737e`)
- **有活動的視窗**: 黃色、粗體 (`#ebcb8b`)
- **有響鈴的視窗**: 紅色、粗體 (`#bf616a`)

## 🎨 配色對應

### Ocean Dark 配色

| 元素           | 顏色      | 用途                 |
| -------------- | --------- | -------------------- |
| 背景           | `#1c1f24` | 狀態列背景           |
| 前景           | `#c0c5ce` | 一般文字             |
| 藍色 (Blue)    | `#8fa1b3` | Session、活動視窗    |
| 綠色 (Green)   | `#a3be8c` | Git 分支、命令提示   |
| 黃色 (Yellow)  | `#ebcb8b` | 活動通知、複製模式   |
| 紅色 (Red)     | `#bf616a` | 響鈴通知             |
| 青色 (Cyan)    | `#96b5b4` | 最後活動視窗         |
| 灰色 (Dim)     | `#65737e` | 非活動視窗           |

## 🔧 自訂配置

### 更改狀態列位置

```toml
[status]
position = "top"  # 或 "bottom"
```

### 更改更新間隔

```toml
[status]
interval = 5  # 秒
```

### 自訂左側狀態

```toml
[status]
# 添加主機名稱
left = "#[fg=#8fa1b3,bg=#1c1f24,bold] [#S@#H] #[fg=#c0c5ce]#I:#W "

# 添加使用者名稱
left = "#[fg=#8fa1b3,bg=#1c1f24,bold] #(whoami)@[#S] #[fg=#c0c5ce]#I:#W "
```

### 自訂右側狀態

```toml
[status]
# 只顯示時間
right = "#[fg=#c0c5ce,bg=#1c1f24,bold] %H:%M "

# 添加系統負載
right = "#[fg=#c0c5ce,bg=#1c1f24,bold] Load: #(uptime | awk '{print $(NF-2)}') | %H:%M "

# 添加電池狀態 (需要外部腳本)
right = "#[fg=#c0c5ce,bg=#1c1f24,bold] 🔋 #(battery-status.ps1) | %H:%M "
```

### 添加 Git 分支顯示

```toml
[status]
left = "#[fg=#8fa1b3,bg=#1c1f24,bold] [#S] #[fg=#a3be8c]#(git rev-parse --abbrev-ref HEAD 2>/dev/null) #[fg=#c0c5ce]#I:#W "
```

## 📋 格式變數

### 可用變數

| 變數 | 說明                     | 範例         |
| ---- | ------------------------ | ------------ |
| `#S` | Session 名稱             | `main`       |
| `#I` | 視窗索引                 | `1`          |
| `#W` | 視窗名稱                 | `pwsh`       |
| `#F` | 視窗旗標                 | `*`, `-`, `#` |
| `#P` | Pane 索引                | `0`          |
| `#T` | Pane 標題                | `~`          |
| `#H` | 主機名稱                 | `DESKTOP-PC` |

### 時間格式 (strftime)

| 格式 | 說明           | 範例   |
| ---- | -------------- | ------ |
| `%Y` | 年份 (4位數)   | `2026` |
| `%m` | 月份 (01-12)   | `04`   |
| `%d` | 日期 (01-31)   | `02`   |
| `%H` | 小時 (00-23)   | `14`   |
| `%M` | 分鐘 (00-59)   | `30`   |
| `%S` | 秒數 (00-59)   | `45`   |
| `%a` | 星期簡寫       | `Thu`  |
| `%A` | 星期全名       | `Thursday` |
| `%b` | 月份簡寫       | `Apr`  |
| `%B` | 月份全名       | `April` |

### 樣式格式

```
#[fg=顏色,bg=顏色,屬性]
```

**可用屬性**:
- `bold` - 粗體
- `dim` - 暗淡
- `underscore` - 底線
- `italics` - 斜體
- `reverse` - 反轉前景/背景

**顏色格式**:
- 顏色名稱: `red`, `green`, `blue`, `yellow`, `cyan`, `magenta`, `white`, `black`
- 256色: `colour0` - `colour255`
- RGB: `#RRGGBB` (例如: `#8fa1b3`)

## 🚀 快速測試

### 1. 測試配置

```powershell
# 執行測試腳本
.\test-statusbar.ps1
```

### 2. 啟動 psmux

```powershell
# 啟動新 session
psmux

# 或建立命名 session
psmux new -s 工作區
```

### 3. 測試狀態列

```powershell
# 建立多個視窗
Ctrl+B, C  # 建立新視窗
Ctrl+B, C  # 再建立一個
Ctrl+B, C  # 再建立一個

# 切換視窗觀察狀態列變化
Ctrl+B, 0  # 切換到視窗 0
Ctrl+B, 1  # 切換到視窗 1
Ctrl+B, 2  # 切換到視窗 2
```

### 4. 重新載入配置

如果修改了配置檔案:

```
Ctrl+B, :source-file ~/.config/psmux/psmux.conf
```

## 🔍 問題排查

### 狀態列未顯示

1. **檢查狀態列是否啟用**:
   ```
   Ctrl+B, :show-options -g | grep status
   ```

2. **手動啟用狀態列**:
   ```
   Ctrl+B, :set -g status on
   ```

3. **檢查配置檔案路徑**:
   ```powershell
   Test-Path "$env:USERPROFILE\.config\psmux\psmux.conf"
   ```

### 顏色顯示不正確

1. **檢查終端支援 256 色**:
   ```powershell
   $env:TERM
   # 應該顯示: xterm-256color
   ```

2. **測試顏色**:
   ```powershell
   # 在 psmux 中執行
   Ctrl+B, :display-message "#{client_termtype}"
   ```

### 字型顯示異常

1. **確認字型已安裝**:
   ```powershell
   [System.Drawing.Text.InstalledFontCollection]::new().Families | 
     Where-Object { $_.Name -match "Maple" }
   ```

2. **檢查 Alacritty 字型設定**:
   - 開啟 `alacritty.toml`
   - 確認 `family = "Maple Mono NF CN"`

### 時間不更新

1. **檢查更新間隔**:
   ```
   Ctrl+B, :show-options -g status-interval
   ```

2. **設定更新間隔**:
   ```
   Ctrl+B, :set -g status-interval 1
   ```

## 📚 進階技巧

### 1. 條件式顯示

根據視窗數量調整狀態列:

```toml
[status]
# 只有一個視窗時隱藏視窗列表
window_status_format = "#{?window_last_flag,#I:#W,}"
```

### 2. 動態內容

使用外部命令顯示動態內容:

```toml
[status]
# 顯示 Git 狀態
left = "... #(git status --short | wc -l) changes ..."

# 顯示記憶體使用
right = "... Mem: #(free -h | awk '/^Mem:/ {print $3}') ..."
```

### 3. 多行狀態列

psmux 不支援多行狀態列，但可以使用 pane 標題:

```toml
[status]
# 在 pane 標題顯示額外資訊
pane_border_format = "#[fg=#8fa1b3]#{pane_index}: #{pane_title}"
```

## 🎯 與 zjstatus 的對應

| zjstatus 功能              | psmux 對應                    |
| -------------------------- | ----------------------------- |
| `format_left`              | `status.left`                 |
| `format_center`            | `status.justify = "centre"`   |
| `format_right`             | `status.right`                |
| `mode_normal`              | `message_style`               |
| `tab_normal`               | `window_status_format`        |
| `tab_active`               | `window_status_current_format`|
| `tab_separator`            | `window_status_separator`     |
| `command_git_branch`       | `#(git rev-parse ...)`        |
| `datetime`                 | `%Y-%m-%d %H:%M:%S`           |
| `session`                  | `#S`                          |

## 📖 參考資源

- [psmux 官方文件](https://github.com/psmux/psmux)
- [tmux 狀態列指南](https://github.com/tmux/tmux/wiki/Getting-Started#status-bar)
- [Alacritty 配色](https://github.com/alacritty/alacritty-theme)
- [Zellij zjstatus](https://github.com/dj95/zjstatus)

## 💡 提示

1. **備份配置**: 修改前先備份 `psmux.conf`
2. **測試變更**: 使用 `:source-file` 即時測試
3. **漸進式調整**: 一次修改一個設定，觀察效果
4. **參考範例**: 查看 `test-statusbar.ps1` 的輸出

---

**最後更新**: 2026-04-02  
**配置版本**: v1.0  
**作者**: OpenCode AI Assistant
