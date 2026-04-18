# psmux 快速參考卡片

## 🚀 快速啟動

```powershell
# 啟動 psmux
psmux

# 建立命名 Session
psmux new -s 工作區

# 連接到現有 Session
psmux attach -t 工作區

# 列出所有 Sessions
psmux ls

# Detach (分離) Session
Ctrl+B, d
```

## 🎨 狀態列布局

```
┌────────────────────────────────────────────────────────────┐
│ [main] 1:pwsh    1:pwsh│2:nvim*│3:htop    2026-04-02 14:30 │
└────────────────────────────────────────────────────────────┘
  ↑                ↑                         ↑
  Session 名稱     視窗列表                  日期時間
```

- **藍色粗體** = 當前活動視窗
- **灰色** = 非活動視窗
- **黃色** = 有新活動的視窗
- **紅色** = 有響鈴的視窗

## ⌨️ 快捷鍵速查

> **Prefix 鍵**: `Ctrl+B` (所有快捷鍵前都要先按)

### 視窗管理
| 快捷鍵 | 功能 |
|--------|------|
| `c` | 建立新視窗 |
| `,` | 重命名視窗 |
| `X` | 關閉視窗 |
| `0-9` | 切換到指定視窗 |
| `n` | 下一個視窗 |
| `p` | 上一個視窗 |
| `w` | 視窗列表 |

### Pane 分割
| 快捷鍵 | 功能 |
|--------|------|
| `"` | 水平分割 (上下) |
| `%` | 垂直分割 (左右) |
| `\|` | 垂直分割 (更直覺) |
| `-` | 水平分割 (更直覺) |
| `x` | 關閉 Pane |
| `z` | 最大化/還原 Pane |

### Pane 導航
| 快捷鍵 | 功能 |
|--------|------|
| `h` | 向左 |
| `j` | 向下 |
| `k` | 向上 |
| `l` | 向右 |
| `方向鍵` | 切換 Pane |
| `o` | 循環切換 |

### Pane 調整大小
| 快捷鍵 | 功能 |
|--------|------|
| `H` | 向左擴展 |
| `J` | 向下擴展 |
| `K` | 向上擴展 |
| `L` | 向右擴展 |
| `Ctrl+方向鍵` | 調整大小 |

### 複製模式
| 快捷鍵 | 功能 |
|--------|------|
| `[` | 進入複製模式 |
| `v` | 開始選取 (Vi 模式) |
| `y` | 複製選取內容 |
| `]` | 貼上 |

### 其他
| 快捷鍵 | 功能 |
|--------|------|
| `R` | 重新載入配置 |
| `Ctrl+L` | 清除歷史記錄 |
| `S` | 同步所有 Pane 輸入 |
| `d` | Detach Session |
| `?` | 顯示所有快捷鍵 |

## 🎨 配色方案 (Ocean Dark)

| 元素 | 顏色 | 用途 |
|------|------|------|
| 背景 | `#1c1f24` | 狀態列背景 |
| 前景 | `#c0c5ce` | 一般文字 |
| 藍色 | `#8fa1b3` | Session、活動視窗 |
| 綠色 | `#a3be8c` | 命令提示 |
| 黃色 | `#ebcb8b` | 活動通知 |
| 紅色 | `#bf616a` | 響鈴通知 |
| 灰色 | `#65737e` | 非活動視窗 |

## 🔧 自訂配置

配置檔案位置: `~\.config\psmux\psmux.conf`

### 更改狀態列位置
```bash
set -g status-position top  # 或 bottom
```

### 更改更新間隔
```bash
set -g status-interval 5  # 秒
```

### 更改 Prefix 鍵
```bash
unbind C-b
set -g prefix C-a
bind C-a send-prefix
```

### 重新載入配置
```
Ctrl+B, R  (在 psmux 中)
```

## 🐛 問題排查

### 狀態列未顯示
```bash
# 在 psmux 中執行
Ctrl+B, :set -g status on
```

### 顏色顯示不正確
```powershell
# 檢查終端類型
$env:TERM  # 應為 xterm-256color
```

### 配置未生效
```bash
# 重新載入配置
Ctrl+B, R

# 或手動載入
Ctrl+B, :source-file ~/.config/psmux/psmux.conf
```

## 📚 進階技巧

### 1. Session 管理
```powershell
# 建立多個 Session
psmux new -s 工作
psmux new -s 學習
psmux new -s 專案

# 切換 Session
Ctrl+B, s  # 選擇 Session
Ctrl+B, (  # 上一個 Session
Ctrl+B, )  # 下一個 Session
```

### 2. 視窗同步
```bash
# 同步所有 Pane 輸入
Ctrl+B, S

# 在多個伺服器上執行相同命令很有用
```

### 3. 複製到系統剪貼簿
```bash
# 在複製模式中
v  # 開始選取
y  # 複製 (自動複製到系統剪貼簿)
```

### 4. 分割並執行命令
```bash
# 垂直分割並執行命令
Ctrl+B, :split-window -h "htop"

# 水平分割並執行命令
Ctrl+B, :split-window -v "git status"
```

## 💡 使用場景

### 開發工作流
```
┌─────────────┬──────────────┐
│   編輯器    │   終端機     │
│   (nvim)    │   (pwsh)     │
├─────────────┴──────────────┤
│   測試/日誌輸出             │
└──────────────────────────────┘

Ctrl+B, |  # 垂直分割
Ctrl+B, -  # 水平分割
Ctrl+B, z  # 最大化編輯器
```

### 多專案管理
```
Session: 工作
├─ 1: 專案A (nvim)
├─ 2: 專案B (nvim)
└─ 3: 測試 (pwsh)

Session: 學習
├─ 1: 教學 (nvim)
└─ 2: 實驗 (pwsh)

Ctrl+B, s  # 切換 Session
```

## 🎯 與 zjstatus 的對應

| zjstatus 功能 | psmux 對應 |
|---------------|-----------|
| `{session}` | `#S` |
| `{tabs}` | 視窗列表 (中間對齊) |
| `{datetime}` | `%Y-%m-%d %H:%M:%S` |
| `tab_active` | 藍色粗體 |
| `tab_normal` | 灰色 |
| `mode_*` | 訊息樣式 |

## 📖 學習資源

- **psmux 說明文件**: `STATUSBAR_README.md`
- **配置檔案**: `~\.config\psmux\psmux.conf`
- **測試腳本**: `~\.config\psmux\test-statusbar.ps1`
- **快捷鍵列表**: `Ctrl+B, ?` (在 psmux 中)

---

**最後更新**: 2026-04-02  
**配置版本**: v1.0 (tmux 格式)  
**作者**: OpenCode AI Assistant

**💡 提示**: 將此卡片列印或存為書籤，方便隨時查閱！
