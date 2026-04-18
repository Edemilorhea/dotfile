# psmux 配置完成摘要

## ✅ 已完成的工作

### 1. 配置檔案建立 (tmux 格式)

**檔案位置**: `C:\Users\tc_tseng\.config\psmux\psmux.conf`

- ✅ 使用正確的 tmux 語法 (不是 TOML)
- ✅ 包含 47 個 `set` 命令
- ✅ 包含 35 個 `bind` 快捷鍵設定
- ✅ 總共 430 行配置

### 2. zjstatus 風格狀態列

**對應關係**:

| Zellij zjstatus | psmux 配置 |
|-----------------|-----------|
| `format_left` | `status-left` |
| `format_center` | 視窗列表 (居中對齊) |
| `format_right` | `status-right` |
| `mode_*` 樣式 | 訊息樣式 |
| `tab_active` | 活動視窗樣式 (藍色粗體) |
| `tab_normal` | 非活動視窗樣式 (灰色) |
| `tab_separator` | 視窗分隔符 `│` |

### 3. Ocean Dark 配色移植

**完整對應 Alacritty 配色**:

- 背景: `#1c1f24`
- 前景: `#c0c5ce`
- 藍色: `#8fa1b3` (Session、活動視窗)
- 綠色: `#a3be8c` (命令提示)
- 黃色: `#ebcb8b` (活動通知)
- 紅色: `#bf616a` (響鈴)
- 灰色: `#65737e` (非活動視窗)

### 4. 輔助工具檔案

建立了以下輔助檔案:

1. **`test-statusbar.ps1`** - 配置驗證測試腳本
   - 檢查 psmux 安裝
   - 驗證配置格式 (tmux 語法)
   - 檢查所有必要設定
   - 顯示配置摘要

2. **`preview-colors.ps1`** - 配色預覽腳本
   - 視覺化顯示 Ocean Dark 配色
   - 狀態列預覽
   - Pane 邊框預覽
   - 訊息樣式預覽

3. **`QUICK_REFERENCE.md`** - 快速參考卡片
   - 快捷鍵速查表
   - 配色對應表
   - 使用場景範例
   - 問題排查指南

4. **`STATUSBAR_README.md`** - 詳細說明文件
   - 完整配置說明
   - 自訂配色指南
   - 格式變數說明
   - 進階技巧

## 🎯 測試結果

### ✅ 所有檢查通過

```
✓ psmux 已安裝
✓ 配置檔案存在
✓ 配置格式正確 (tmux 語法)
✓ 狀態列啟用
✓ 狀態列位置 (bottom)
✓ 左側狀態
✓ 右側狀態
✓ 視窗格式
✓ 活動視窗格式
✓ 視窗分隔符
✓ 狀態列樣式
✓ Pane 邊框
✓ Maple Mono 字型已安裝
```

### 📊 配置統計

- **更新間隔**: 1 秒
- **對齊方式**: centre (置中)
- **滑鼠支援**: on
- **視窗索引起始**: 1
- **位置**: bottom (底部)
- **歷史記錄**: 10000 行

## 🚀 快速開始

### 1. 啟動 psmux

```powershell
psmux
```

### 2. 測試狀態列

```bash
# 建立多個視窗
Ctrl+B, C  # 建立新視窗
Ctrl+B, C  # 再建立一個
Ctrl+B, 0  # 切換到視窗 0
Ctrl+B, 1  # 切換到視窗 1

# 觀察狀態列變化
# - 左側顯示 Session 名稱
# - 中間顯示視窗列表
# - 右側顯示當前時間
# - 活動視窗以藍色粗體顯示
```

### 3. 測試 Pane 分割

```bash
Ctrl+B, |  # 垂直分割
Ctrl+B, -  # 水平分割
Ctrl+B, h/j/k/l  # Vim 風格切換
Ctrl+B, z  # 最大化/還原
```

## 🎨 狀態列預覽

```
┌────────────────────────────────────────────────────────────┐
│ [main] 1:pwsh    1:pwsh│2:nvim*│3:htop    2026-04-02 14:30 │
└────────────────────────────────────────────────────────────┘
```

- **左側**: `[Session名稱] 視窗索引:視窗名稱`
- **中間**: 所有視窗列表 (活動視窗藍色粗體)
- **右側**: 日期時間 (台北時區)

## ⌨️ 重要快捷鍵

| 快捷鍵 | 功能 |
|--------|------|
| `Ctrl+B, c` | 建立新視窗 |
| `Ctrl+B, 0-9` | 切換視窗 |
| `Ctrl+B, \|` | 垂直分割 |
| `Ctrl+B, -` | 水平分割 |
| `Ctrl+B, h/j/k/l` | 切換 Pane (Vim) |
| `Ctrl+B, z` | 最大化/還原 Pane |
| `Ctrl+B, R` | 重新載入配置 |
| `Ctrl+B, ?` | 顯示所有快捷鍵 |

## 🔧 自訂配置

### 更改狀態列位置

編輯 `psmux.conf`:

```bash
set -g status-position top  # 移到頂部
```

重新載入: `Ctrl+B, R`

### 更改配色

編輯 `psmux.conf`:

```bash
# 更改活動視窗顏色為紅色
set -g window-status-current-style "fg=#bf616a,bg=#1c1f24,bold"
```

重新載入: `Ctrl+B, R`

### 添加 Git 分支顯示

編輯 `psmux.conf`:

```bash
set -g status-left "#[fg=#8fa1b3,bg=#1c1f24,bold] [#S] #[fg=#a3be8c]#(git rev-parse --abbrev-ref HEAD 2>/dev/null) #[fg=#c0c5ce]#I:#W "
```

## 🐛 問題排查

### 問題 1: 狀態列未顯示

**解決方案**:

```bash
# 在 psmux 中執行
Ctrl+B, :set -g status on
```

### 問題 2: 配置未生效

**解決方案**:

```bash
# 重新載入配置
Ctrl+B, R

# 或手動載入
Ctrl+B, :source-file ~/.config/psmux/psmux.conf
```

### 問題 3: 顏色顯示不正確

**解決方案**:

```powershell
# 檢查終端類型
$env:TERM  # 應為 xterm-256color

# 在 Alacritty 中啟動 psmux
# 確保 Alacritty 配置正確
```

## 📁 檔案清單

配置目錄: `C:\Users\tc_tseng\.config\psmux\`

```
psmux/
├── psmux.conf              # 主配置檔案 (tmux 格式)
├── test-statusbar.ps1      # 配置測試腳本
├── preview-colors.ps1      # 配色預覽腳本
├── QUICK_REFERENCE.md      # 快速參考卡片
├── STATUSBAR_README.md     # 詳細說明文件
└── SUMMARY.md              # 本摘要檔案
```

## 📚 學習資源

### 1. 快速參考

```powershell
# 查看快速參考卡片
notepad $env:USERPROFILE\.config\psmux\QUICK_REFERENCE.md
```

### 2. 詳細說明

```powershell
# 查看詳細說明文件
notepad $env:USERPROFILE\.config\psmux\STATUSBAR_README.md
```

### 3. 測試配置

```powershell
# 執行測試腳本
Set-Location $env:USERPROFILE\.config\psmux
.\test-statusbar.ps1
```

### 4. 預覽配色

```powershell
# 執行配色預覽
Set-Location $env:USERPROFILE\.config\psmux
.\preview-colors.ps1
```

## 🎯 與其他工具的整合

### Alacritty + psmux + Zellij

您現在有一套完整的終端環境配置:

1. **Alacritty** - 終端模擬器
   - Ocean Dark 配色
   - Maple Mono NF CN 字型
   - 透明度 0.95

2. **Zellij** - 終端多工器
   - Dracula 主題
   - zjstatus 狀態列
   - Vim 風格快捷鍵

3. **psmux** - 終端多工器 (備用)
   - Ocean Dark 配色
   - zjstatus 風格狀態列
   - tmux 相容快捷鍵

### 使用建議

- **日常工作**: 使用 Alacritty + Zellij
- **需要 tmux 相容性**: 使用 Alacritty + psmux
- **遠端連線**: 使用 psmux (tmux 相容)

## 💡 下一步建議

### 1. 熟悉快捷鍵

建議印出或保存 `QUICK_REFERENCE.md` 作為速查表。

### 2. 自訂配置

根據個人習慣調整:
- 狀態列位置 (頂部/底部)
- 配色方案
- 快捷鍵映射
- 添加 Git 分支顯示

### 3. 建立工作流

建立專案專用的 Session:

```powershell
# 工作 Session
psmux new -s work

# 學習 Session
psmux new -s study

# 專案 Session
psmux new -s project-name
```

### 4. 整合開發環境

在 psmux 中設定開發環境:

```bash
# 視窗 1: 編輯器
Ctrl+B, c
nvim

# 視窗 2: 終端
Ctrl+B, c
pwsh

# 視窗 3: 測試/日誌
Ctrl+B, c
# 執行測試或查看日誌
```

## 🎉 完成！

您的 psmux 配置已完全準備就緒！

- ✅ zjstatus 風格狀態列
- ✅ Ocean Dark 配色方案
- ✅ Vim 風格快捷鍵
- ✅ CJK 字元優化
- ✅ 完整文件和測試工具

**立即開始**: 執行 `psmux` 並享受新的終端體驗！

---

**最後更新**: 2026-04-02  
**配置版本**: v1.0 (tmux 格式)  
**作者**: OpenCode AI Assistant

**📧 回饋**: 如有任何問題或建議，請查閱 `STATUSBAR_README.md` 或執行測試腳本。
