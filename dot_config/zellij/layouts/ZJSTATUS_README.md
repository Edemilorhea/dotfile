# zjstatus 配置說明

## 📦 已安裝位置
- Plugin: `~/.local/share/zellij/plugins/zjstatus.wasm`
- 配置目錄: `~\AppData\Roaming\Zellij\config\layouts\`

## 🎨 可用配置

### 1. zjstatus.kdl (完整功能)
功能最完整的配置,包含:
- 完整模式顯示 (NORMAL, LOCKED, RESIZE 等)
- Git 分支顯示
- 會話名稱
- 詳細日期時間
- Catppuccin Mocha 配色

**啟動方式:**
```bash
zellij --layout zjstatus
```

### 2. zjstatus-minimal.kdl (簡約風格)
最簡潔的配置,適合小螢幕:
- 簡化模式圖示
- 只顯示時間 (HH:MM)
- 無 Git 分支
- 極簡配色

**啟動方式:**
```bash
zellij --layout zjstatus-minimal
```

### 3. zjstatus-powerline.kdl (Powerline 風格)
仿 Powerline 的斜角風格:
- 使用  分隔符
- 完整功能
- 視覺效果更豐富

**啟動方式:**
```bash
zellij --layout zjstatus-powerline
```

## ⚙️ 設定為預設 Layout

### 方法 1: 修改 config.kdl
編輯 `~\AppData\Roaming\Zellij\config\config.kdl`,新增:

```kdl
default_layout "zjstatus"
```

### 方法 2: 建立別名
在 PowerShell 設定檔中新增:

```powershell
# 編輯設定檔
notepad $PROFILE

# 新增別名
function zj { zellij --layout zjstatus }
function zjm { zellij --layout zjstatus-minimal }
function zjp { zellij --layout zjstatus-powerline }
```

然後使用 `zj` 啟動完整版,`zjm` 啟動簡約版。

## 🎨 自訂顏色

所有配置都使用 Catppuccin Mocha 配色方案,你可以修改以下顏色變數:

```kdl
color_bg        "#1e1e2e"  // 背景色
color_fg        "#cdd6f4"  // 前景色 (文字)
color_blue      "#89b4fa"  // 藍色 (NORMAL 模式)
color_green     "#a6e3a1"  // 綠色 (PANE 模式、Git)
color_yellow    "#f9e2af"  // 黃色 (SCROLL 模式)
color_orange    "#fab387"  // 橘色 (SEARCH 模式)
color_red       "#f38ba8"  // 紅色 (LOCKED 模式)
color_mauve     "#cba6f7"  // 紫色 (TAB 模式)
```

## 🔧 常用調整

### 修改時區
```kdl
datetime_timezone "Asia/Taipei"  // 台北時間
```

### 修改日期格式
```kdl
datetime_format "%Y-%m-%d %H:%M:%S"  // 2026-04-01 13:45:30
datetime_format "%H:%M"              // 13:45
datetime_format "%m/%d %H:%M"        // 04/01 13:45
```

### 調整 Git 更新頻率
```kdl
command_git_branch_interval "10"  // 每 10 秒更新一次
```

### 顯示/隱藏 Pane 邊框
```kdl
hide_frame_for_single_pane "true"   // 單一 pane 時隱藏
hide_frame_for_single_pane "false"  // 永遠顯示
```

## 🚀 首次使用

1. **啟動 Zellij**:
   ```bash
   zellij --layout zjstatus
   ```

2. **授權權限**:
   - 首次啟動會提示權限請求
   - 游標移到 zjstatus 的 pane
   - 按 `y` 允許權限

3. **驗證顯示**:
   - 應該看到狀態列顯示模式、會話名稱、標籤、時間
   - 如果在 Git 倉庫中,應該會顯示分支名稱

## 🐛 疑難排解

### 權限錯誤
刪除快取後重新啟動:
```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\zellij\cache"
zellij --layout zjstatus
```

### Git 分支不顯示
確認當前目錄在 Git 倉庫中:
```bash
git rev-parse --abbrev-ref HEAD
```

### 顏色顯示異常
確認終端機支援 True Color:
```powershell
$env:COLORTERM = "truecolor"
```

## 📚 更多資源

- 官方文檔: https://github.com/dj95/zjstatus/wiki
- 社群配置: https://github.com/dj95/zjstatus/discussions/44
- Zellij 文檔: https://zellij.dev/documentation

## 🎯 快速切換配置

建立 PowerShell 函數快速切換:

```powershell
function Switch-ZjStatus {
    param([ValidateSet("full", "minimal", "powerline")]$Style = "full")
    
    $layout = switch ($Style) {
        "full"      { "zjstatus" }
        "minimal"   { "zjstatus-minimal" }
        "powerline" { "zjstatus-powerline" }
    }
    
    zellij --layout $layout
}

# 使用方式
Switch-ZjStatus -Style minimal
```
