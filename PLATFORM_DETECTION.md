# 🎯 Chezmoi 平台偵測與判斷邏輯說明

## 📌 重要觀念

### ⚠️ 常見錯誤判斷

```go
// ❌ 錯誤：只區分 Windows 和「非 Windows」
{{- if ne .chezmoi.os "windows" }}
// 這會把 Linux, macOS, BSD 等都當成同一類
{{- end }}

// ✅ 正確：明確判斷每個平台
{{- if eq .chezmoi.os "linux" }}
// Linux 專用配置
{{- else if eq .chezmoi.os "darwin" }}
// macOS 專用配置
{{- else if eq .chezmoi.os "windows" }}
// Windows 專用配置
{{- end }}
```

---

## 🖥️ Chezmoi 支援的作業系統值

### 主要平台

| 平台 | `.chezmoi.os` 值 | 說明 |
|------|-----------------|------|
| **Windows** | `windows` | Windows 10/11, Windows Server |
| **Linux** | `linux` | 所有 Linux 發行版 (含 WSL) |
| **macOS** | `darwin` | macOS / Mac OS X |
| **FreeBSD** | `freebsd` | FreeBSD 系統 |
| **OpenBSD** | `openbsd` | OpenBSD 系統 |
| **NetBSD** | `netbsd` | NetBSD 系統 |

### 重要細節

1. **WSL (Windows Subsystem for Linux)** 會被識別為 `linux`，不是 `windows`
2. **macOS** 使用 `darwin` (不是 `macos`)
3. **判斷時使用 `eq`** (等於) 而不是 `ne` (不等於)，邏輯更清晰

---

## ✅ 正確的判斷模式

### 模式 1: 單一平台判斷

```go
# 只在 Windows 生效
{{- if eq .chezmoi.os "windows" }}
config.default_prog = { "pwsh.exe" }
{{- end }}
```

### 模式 2: 多平台 if-else

```go
{{- if eq .chezmoi.os "windows" }}
# Windows 專用
editor = code --wait
{{- else if eq .chezmoi.os "linux" }}
# Linux 專用 (含 WSL)
editor = nvim
{{- else if eq .chezmoi.os "darwin" }}
# macOS 專用
editor = nvim
{{- else }}
# 其他平台備用
editor = vi
{{- end }}
```

### 模式 3: 多平台 OR 判斷

當 Linux 和 macOS 使用相同配置時：

```go
{{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") }}
# Linux 和 macOS 共用配置
autocrlf = input
{{- else if eq .chezmoi.os "windows" }}
# Windows 獨立配置
autocrlf = true
{{- end }}
```

### 模式 4: 忽略檔案判斷

在 `.chezmoiignore` 中：

```bash
# ✅ 正確：在非 Windows 平台忽略 Windows 專用檔案
{{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") }}
AppData/**
Documents/**
{{- end }}

# ✅ 正確：在 Windows 忽略 Linux/macOS 專用檔案
{{- if eq .chezmoi.os "windows" }}
.bashrc
.zshrc
.config/nvim/**
{{- end }}

# ✅ 正確：在 Windows 和 macOS 忽略 Linux 專用檔案
{{- if or (eq .chezmoi.os "windows") (eq .chezmoi.os "darwin") }}
.config/i3/**
.config/sway/**
{{- end }}
```

---

## 🔍 如何判斷當前環境

### 方法 1: 查看完整的 chezmoi 環境資訊

```bash
chezmoi data
```

輸出範例：
```json
{
  "chezmoi": {
    "os": "linux",                  # ← 作業系統
    "arch": "amd64",                # ← 架構
    "hostname": "wsl-dev",          # ← 主機名稱
    "kernel": {
      "ostype": "linux",
      "osrelease": "5.15.0-...-WSL2"  # WSL 會顯示 WSL2
    }
  }
}
```

### 方法 2: 只查看作業系統

```bash
chezmoi execute-template "{{ .chezmoi.os }}"
```

### 方法 3: 區分 WSL 和原生 Linux

雖然 WSL 的 `.chezmoi.os` 是 `linux`，但可以透過其他方式區分：

```go
{{- if eq .chezmoi.os "linux" }}
  {{- if .chezmoi.kernel.osrelease | regexMatch "WSL" }}
# WSL 專用配置
  {{- else }}
# 原生 Linux 配置
  {{- end }}
{{- end }}
```

或檢查 hostname：

```bash
chezmoi execute-template "{{ .chezmoi.hostname }}"
```

---

## 📂 實際應用案例

### 案例 1: Neovim 路徑判斷

```bash
# .chezmoiignore.tmpl
{{- if not .syncNvim }}
# 不同步時，全部忽略
AppData/Local/nvim/**
.config/nvim/**
{{- else }}
  {{- if eq .chezmoi.os "windows" }}
# Windows: 忽略 Linux 路徑
.config/nvim/**
  {{- else if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") }}
# Linux/macOS: 忽略 Windows 路徑
AppData/Local/nvim/**
  {{- end }}
{{- end }}
```

### 案例 2: Shell 配置選擇

```lua
-- .wezterm.lua.tmpl
{{- if eq .chezmoi.os "windows" }}
config.default_prog = { "pwsh.exe" }
{{- else if eq .chezmoi.os "linux" }}
config.default_prog = { "/usr/bin/zsh", "-l" }
{{- else if eq .chezmoi.os "darwin" }}
config.default_prog = { "/bin/zsh", "-l" }
{{- else }}
-- 未知平台，使用系統預設
config.default_prog = nil
{{- end }}
```

### 案例 3: Git 換行符號處理

```gitconfig
# .gitconfig.tmpl
[core]
{{- if eq .chezmoi.os "windows" }}
    autocrlf = true      # Windows: CRLF ↔ LF 雙向轉換
{{- else if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") }}
    autocrlf = input     # Linux/macOS: 只在 commit 時轉 LF
{{- end }}
```

---

## 🎓 最佳實踐

### ✅ DO (應該做)

1. **使用 `eq` 進行正向判斷**
   ```go
   {{- if eq .chezmoi.os "windows" }}
   ```

2. **對每個平台明確判斷**
   ```go
   {{- if eq .chezmoi.os "linux" }}
   {{- else if eq .chezmoi.os "darwin" }}
   {{- else if eq .chezmoi.os "windows" }}
   {{- end }}
   ```

3. **使用 `or` 合併相同邏輯的平台**
   ```go
   {{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") }}
   ```

4. **提供 fallback 預設值**
   ```go
   {{- else }}
   # 未知平台的預設行為
   {{- end }}
   ```

### ❌ DON'T (不應該做)

1. **避免使用 `ne` (不等於) 做主要判斷**
   ```go
   # ❌ 不好：把所有非 Windows 當同一類
   {{- if ne .chezmoi.os "windows" }}
   
   # ✅ 改用明確判斷
   {{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") }}
   ```

2. **不要假設「非 X 就是 Y」**
   ```go
   # ❌ 錯誤假設
   {{- if ne .chezmoi.os "windows" }}
   # 會誤把 macOS, FreeBSD 等也當成 Linux
   {{- end }}
   ```

3. **避免沒有 else 的 ne 判斷**
   ```go
   # ❌ 危險：不知道會影響哪些平台
   {{- if ne .chezmoi.os "windows" }}
   AppData/**
   {{- end }}
   
   # ✅ 改用明確列舉
   {{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") (eq .chezmoi.os "freebsd") }}
   AppData/**
   {{- end }}
   ```

---

## 🧪 測試你的模板

### 模擬不同平台渲染

```bash
# 模擬 Linux
chezmoi execute-template --init \
  --promptString chezmoi.os=linux \
  < .chezmoiignore.tmpl

# 模擬 macOS
chezmoi execute-template --init \
  --promptString chezmoi.os=darwin \
  < .chezmoiignore.tmpl

# 模擬 Windows
chezmoi execute-template --init \
  --promptString chezmoi.os=windows \
  < .chezmoiignore.tmpl
```

### 快速驗證邏輯

```bash
# 測試單一條件
chezmoi execute-template '{{ eq .chezmoi.os "linux" }}'
# 輸出: true 或 false

# 測試 or 條件
chezmoi execute-template '{{ or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") }}'
```

---

## 📚 參考資源

- [Chezmoi 官方文件 - Template Variables](https://www.chezmoi.io/reference/templates/)
- [Go Template 語法](https://pkg.go.dev/text/template)
- [Chezmoi GitHub Issues - Platform Detection](https://github.com/twpayne/chezmoi/issues)

---

**維護者**: TC (leon8847@gmail.com)  
**最後更新**: 2026-02-09
