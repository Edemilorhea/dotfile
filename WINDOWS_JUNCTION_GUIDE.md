# Windows 配置文件 Junction 管理指南

## 設計理念

### 問題
Windows 上不同軟體的配置文件路徑不統一:
- Neovim: `%LOCALAPPDATA%\nvim`
- Alacritty: `%APPDATA%\alacritty`
- 某些軟體: `~/.config/軟體名`

這導致 dotfiles 管理混亂,無法遵循 XDG 標準。

### 解決方案
**統一存放 + Junction 連結**

```
~/.config/          ← 統一的配置源 (chezmoi 管理)
├── nvim/           → Junction → %LOCALAPPDATA%\nvim
├── alacritty/      → Junction → %APPDATA%\alacritty
└── wezterm/        ← 直接使用 (Wezterm 支援 .config)
```

## 核心優勢

✅ **統一管理**: 所有配置都在 `~/.config/` 下,遵循 XDG 標準  
✅ **自動化**: `chezmoi apply` 自動建立 Junction  
✅ **無需權限**: Junction 不需要管理員權限  
✅ **跨機器**: 新電腦 `chezmoi init` 自動設定所有 Junction  
✅ **易擴展**: 新增軟體只需修改一個腳本

## 實現機制

### 1. chezmoi 源碼結構

```
~/.local/share/chezmoi/
├── dot_config/
│   ├── nvim/                    ← Neovim 配置源
│   ├── alacritty/               ← Alacritty 配置源
│   └── wezterm/                 ← Wezterm 配置源
└── run_once_before_windows_config_junctions.cmd.tmpl  ← Junction 管理腳本
```

### 2. Junction 管理腳本

**檔案名**: `run_once_before_windows_config_junctions.cmd.tmpl`

**執行時機**: 
- `run_once_before`: chezmoi apply **之前**執行一次
- 只在 Windows 平台執行
- 檢測到腳本內容變更時會重新執行

**主要功能**:
1. 檢查 `~/.config/軟體名` 是否存在
2. 如果目標位置有實體目錄,自動備份
3. 建立 Junction: `軟體路徑` → `~/.config/軟體名`
4. 下次啟動軟體時,自動讀取 `~/.config/` 的配置

### 3. Junction vs Symlink vs Hard Link

| 類型          | 適用對象 | 需要權限        | 跨磁碟 | 說明                       |
| ------------- | -------- | --------------- | ------ | -------------------------- |
| Junction      | 目錄     | ❌ 不需要       | ❌     | **推薦!** 適合配置目錄     |
| Symlink       | 檔案/目錄 | ✅ 需要(或開發者模式) | ✅     | 最靈活,但需要權限          |
| Hard Link     | 檔案     | ❌ 不需要       | ❌     | 適合單一檔案,但不適合目錄 |

我們選擇 **Junction**,因為:
- ✅ 適用於目錄
- ✅ 不需要管理員權限
- ✅ 適合 Windows 本地磁碟使用

## 使用方法

### 新增軟體配置

假設要新增 **Zellij** 配置:

#### 步驟 1: 將配置放入 `dot_config`

```bash
# 在 chezmoi 源碼中建立
mkdir ~/.local/share/chezmoi/dot_config/zellij
# 複製配置檔案
cp %APPDATA%\zellij\config.kdl ~/.local/share/chezmoi/dot_config/zellij/
```

#### 步驟 2: 編輯 Junction 腳本

編輯 `run_once_before_windows_config_junctions.cmd.tmpl`,在 `:main` 區塊加入:

```batch
:: Zellij: .config/zellij -> %APPDATA%\zellij
call :create_junction "%USERPROFILE%\.config\zellij" "%APPDATA%\zellij"
```

#### 步驟 3: 測試

```bash
# 清除腳本執行狀態,強制重新執行
chezmoi state delete-bucket --bucket=scriptState

# Apply 並檢查
chezmoi apply -v

# 驗證 Junction
cmd /c dir /al %APPDATA% | Select-String "zellij"
```

### 檢視現有 Junction

```powershell
# 檢視 AppData\Roaming 的 Junction
cmd /c dir /al %APPDATA%

# 檢視 AppData\Local 的 Junction  
cmd /c dir /al %LOCALAPPDATA%

# 使用 PowerShell
Get-ChildItem "$env:APPDATA" | Where-Object LinkType -eq "Junction"
```

### 手動建立 Junction (測試用)

```powershell
# 建立 Junction
New-Item -ItemType Junction -Path "目標路徑" -Target "來源路徑"

# 範例: Alacritty
New-Item -ItemType Junction -Path "$env:APPDATA\alacritty" -Target "$env:USERPROFILE\.config\alacritty"

# 刪除 Junction (不會刪除來源)
Remove-Item -Path "$env:APPDATA\alacritty"
```

## 故障排除

### Junction 沒有建立?

1. **檢查腳本是否執行過**:
   ```bash
   chezmoi state dump | Select-String "junction"
   ```

2. **強制重新執行**:
   ```bash
   # 刪除腳本狀態
   chezmoi state delete-bucket --bucket=scriptState
   # 重新 apply
   chezmoi apply
   ```

3. **手動執行腳本測試**:
   ```bash
   # 渲染腳本
   chezmoi execute-template < ~/.local/share/chezmoi/run_once_before_windows_config_junctions.cmd.tmpl > test.cmd
   # 執行
   cmd /c test.cmd
   ```

### 目標位置有舊配置?

腳本會自動備份為 `目錄名_backup_日期_時間`,例如:
- `nvim_backup_20260426_030307`
- `alacritty_backup_20260426_030308`

### Junction 指向錯誤?

```powershell
# 刪除錯誤的 Junction
Remove-Item -Path "錯誤的Junction路徑"

# 重新建立
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

## 跨平台考量

### Linux/macOS

在 Linux/macOS 上,大部分軟體已經支援 `~/.config/`,不需要額外處理:

```toml
# .chezmoiignore.tmpl
{{- if eq .chezmoi.os "windows" }}
# Linux/macOS 忽略 Windows Junction 腳本
run_once_before_windows_config_junctions.cmd.tmpl
{{- end }}
```

### WSL

WSL 內的軟體使用 Linux 路徑 (`~/.config/`),不需要 Junction。  
但如果要在 WSL 中使用 Windows 的配置:

```bash
# 在 WSL 中建立 Symlink 到 Windows 路徑
ln -s /mnt/c/Users/你的用戶名/.config/nvim ~/.config/nvim
```

## 未來改進

- [ ] 支援條件式 Junction (透過 chezmoi data 開關)
- [ ] 自動檢測軟體安裝並建立 Junction
- [ ] 提供 PowerShell 版本 (更好的錯誤處理)

## 參考資料

- [chezmoi 官方文檔 - Scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
- [Microsoft Docs - mklink](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/mklink)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
