# 🐧 WSL 環境 chezmoi 設定指南

## 📋 目錄
1. [快速開始](#快速開始)
2. [WSL 環境差異說明](#wsl-環境差異說明)
3. [初始化步驟](#初始化步驟)
4. [驗證配置](#驗證配置)
5. [常見問題](#常見問題)

---

## 🚀 快速開始

### 前置需求
```bash
# 在 WSL 中安裝 chezmoi
sudo apt update
sudo apt install chezmoi

# 或使用官方腳本
sh -c "$(curl -fsLS get.chezmoi.io)"
```

### 一鍵初始化
```bash
# 從你的 GitHub 倉庫初始化 (假設你已經推送到 GitHub)
chezmoi init https://github.com/YOUR_USERNAME/dotfiles.git

# 或從 Windows 本地目錄初始化
chezmoi init --source /mnt/c/Users/tc_tseng/.local/share/chezmoi
```

---

## 🔍 WSL 環境差異說明

### 自動處理的差異

你的 chezmoi 配置已經自動處理以下差異：

| 項目 | Windows | WSL/Linux |
|------|---------|-----------|
| **Neovim 路徑** | `AppData/Local/nvim/` | `.config/nvim/` |
| **Shell** | PowerShell | Zsh/Bash |
| **預設編輯器** | VS Code | Neovim |
| **換行符號** | CRLF | LF |
| **專案配置** | `projects_work` | 需重新選擇 |

### 同步開關建議

在 WSL 中建議的配置：

```toml
[data]
    syncGit = true          # ✅ Git 配置通用
    syncZsh = true          # ✅ WSL 使用 Zsh
    syncNvim = true         # ✅ WSL 使用 Neovim
    syncPowershell = false  # ❌ WSL 不需要 PowerShell
    syncIdeavimrc = true    # ✅ 如果使用 IntelliJ
```

---

## 📝 初始化步驟

### 方法 1: 從現有倉庫初始化 (推薦)

```bash
# 1. 初始化並克隆配置
chezmoi init https://github.com/YOUR_USERNAME/dotfiles.git

# 2. 查看將要應用的變更 (不實際修改)
chezmoi diff

# 3. 確認無誤後套用
chezmoi apply

# 4. 根據提示設定 WSL 專用參數
# - WezTerm 專案: 選擇 projects_home 或其他
# - 同步開關: 依照上方建議設定
```

### 方法 2: 從 Windows 本地目錄同步

```bash
# 1. 從 Windows 目錄初始化
chezmoi init --source /mnt/c/Users/tc_tseng/.local/share/chezmoi

# 2. 預覽變更
chezmoi diff

# 3. 套用配置
chezmoi apply
```

### 方法 3: 手動調整配置

```bash
# 1. 初始化空配置
chezmoi init

# 2. 編輯 WSL 專用配置
chezmoi edit-config

# 3. 加入以下內容：
```

```toml
[git]
    autoCommit = true
    autoPush = false  # WSL 可能不需要自動推送

[data]
    gitName = "TC"
    gitEmail = "leon8847@gmail.com"
    weztermProject = "projects_home"  # WSL 專用專案配置
    
    syncGit = true
    syncZsh = true
    syncNvim = true
    syncPowershell = false
    syncIdeavimrc = true

[merge]
    command = "nvim"
    args = ["-d"]
```

---

## ✅ 驗證配置

### 1. 檢查 chezmoi 識別的環境

```bash
chezmoi data | jq .chezmoi
```

應該看到：
```json
{
  "os": "linux",
  "hostname": "your-wsl-hostname",
  ...
}
```

### 2. 檢查將要同步的檔案

```bash
# 查看管理的檔案列表
chezmoi managed

# 應該看到 Linux 路徑，例如：
# .config/nvim/init.lua
# .zshrc
# .gitconfig
# .ideavimrc

# 不應該看到 Windows 路徑：
# AppData/Local/nvim/  ❌
# Documents/PowerShell/ ❌
```

### 3. 驗證模板正確渲染

```bash
# 查看 .gitconfig 的實際內容
chezmoi cat ~/.gitconfig

# 應該看到 autocrlf = input (Linux)
# 而不是 autocrlf = true (Windows)
```

### 4. 測試 Neovim 配置

```bash
# 確認 Neovim 配置路徑正確
ls -la ~/.config/nvim/

# 啟動 Neovim 測試
nvim
```

---

## 🐛 常見問題

### Q1: 套用後發現 Windows 的檔案也同步過來了

**原因**: `.chezmoiignore` 沒有正確執行

**解決方式**:
```bash
# 1. 檢查 ignore 規則
chezmoi execute-template < ~/.local/share/chezmoi/.chezmoiignore.tmpl

# 2. 重新套用
chezmoi apply --force
```

---

### Q2: WezTerm 配置在 WSL 中無法使用

**原因**: WezTerm 在 WSL 中通常透過 Windows 執行

**解決方式**:
- 如果你在 Windows 使用 WezTerm 連接 WSL，配置應該保持 Windows 版本
- 如果需要 WSL 專用配置，可以建立 `dot_config/wezterm/wezterm.lua.tmpl`

---

### Q3: Git 換行符號問題

**檢查配置**:
```bash
git config --global core.autocrlf
# WSL 應該返回: input
# Windows 應該返回: true
```

---

### Q4: Zsh 配置沒有同步

**原因**: `syncZsh = false` 或 Windows 阻擋了 `.zshrc`

**解決方式**:
```bash
# 1. 編輯 WSL 的配置
chezmoi edit-config

# 2. 確保設定為 true
syncZsh = true

# 3. 重新套用
chezmoi apply
```

---

### Q5: 如何在 Windows 和 WSL 共用部分配置？

**方法 1**: 使用 symlink (WSL 可以存取 Windows 檔案)
```bash
# 在 WSL 中建立指向 Windows 配置的連結
ln -s /mnt/c/Users/tc_tseng/.ideavimrc ~/.ideavimrc
```

**方法 2**: 使用 chezmoi 的 `run_once` 腳本自動同步
```bash
# 建立 run_once_sync_from_windows.sh.tmpl
{{- if eq .chezmoi.os "linux" }}
#!/bin/bash
cp /mnt/c/Users/tc_tseng/.ideavimrc ~/.ideavimrc
{{- end }}
```

---

## 🔄 持續同步

### 在 WSL 中更新配置

```bash
# 1. 拉取最新配置 (如果使用 Git)
chezmoi update

# 2. 或手動拉取並套用
cd $(chezmoi source-path)
git pull
chezmoi apply
```

### 在 WSL 中修改配置

```bash
# 1. 編輯檔案
chezmoi edit ~/.zshrc

# 2. 查看變更
chezmoi diff

# 3. 套用變更
chezmoi apply

# 4. 提交並推送 (如果需要)
chezmoi cd
git add .
git commit -m "Update zsh config from WSL"
git push
```

---

## 🎯 最佳實踐

### 1. 分離環境特定配置
- Windows 專用: `projects_work.lua`
- WSL 專用: `projects_home.lua`
- 通用: `.gitconfig`, `.ideavimrc`

### 2. 使用環境變數
在 `.zshrc` 或 `.bashrc` 中：
```bash
# 偵測是否在 WSL 中
if grep -qi microsoft /proc/version; then
    export IS_WSL=true
    # WSL 專用設定
else
    export IS_WSL=false
fi
```

### 3. 定期同步
```bash
# 在 .zshrc 加入 alias
alias dotfiles-sync='chezmoi update && chezmoi apply'
```

---

## 📚 進階技巧

### 使用不同的 chezmoi 配置檔

你可以在不同環境使用不同的配置：

```bash
# Windows
chezmoi --config ~/.config/chezmoi/chezmoi-windows.toml apply

# WSL
chezmoi --config ~/.config/chezmoi/chezmoi-wsl.toml apply
```

### 條件式腳本執行

建立 `run_onchange_install_tools.sh.tmpl`:
```bash
{{- if eq .chezmoi.os "linux" }}
#!/bin/bash
# WSL 專用工具安裝
sudo apt install -y zsh neovim ripgrep fd-find
{{- end }}
```

---

## 🆘 支援

如有問題，請檢查：
1. `chezmoi doctor` - 診斷工具
2. `chezmoi diff` - 查看變更差異
3. `chezmoi execute-template` - 測試模板渲染

---

**最後更新**: 2026-02-09
**維護者**: TC (leon8847@gmail.com)
