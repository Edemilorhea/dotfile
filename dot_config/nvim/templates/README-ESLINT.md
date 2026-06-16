# ESLint 配置範本使用說明

## 📁 檔案說明

- `.eslintrc.json` - ESLint 8.x 及以下版本使用 (舊版格式)
- `eslint.config.js` - ESLint 9.x 使用 (新版 Flat Config)

## 🚀 使用方法

### 方法 1: 複製到你的 React 專案

```powershell
# 進入你的 React 專案目錄
cd C:\path\to\your\react-project

# 複製 ESLint 配置檔案 (選擇其中一個)
# 舊版格式 (ESLint 8.x):
Copy-Item "C:\Users\tc_tseng\.config\nvim\templates\.eslintrc.json" .

# 新版格式 (ESLint 9.x):
Copy-Item "C:\Users\tc_tseng\.config\nvim\templates\eslint.config.js" .
```

### 方法 2: 安裝必要的依賴

```bash
# 使用 npm
npm install --save-dev eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-react eslint-plugin-react-hooks

# 使用 pnpm
pnpm add -D eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-react eslint-plugin-react-hooks

# 使用 yarn
yarn add -D eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-react eslint-plugin-react-hooks
```

### 方法 3: 檢查 ESLint 版本

```bash
# 檢查專案中的 ESLint 版本
npx eslint --version

# 如果是 9.x 使用 eslint.config.js
# 如果是 8.x 使用 .eslintrc.json
```

## ⚙️ Neovim 中的 ESLint

配置完成後,重新啟動 Neovim,ESLint LSP 應該會自動啟動。

### 檢查 LSP 狀態

在 Neovim 中執行:
```vim
:LspInfo
```

應該會看到 `eslint` 已連接。

## 🔧 常見問題

### Q: 為什麼還是顯示 "Could not find config file"?

A: 確認以下事項:
1. ESLint 配置檔案在專案根目錄
2. 已安裝必要的依賴套件
3. 重新啟動 Neovim
4. 檢查 `package.json` 中是否有 `eslint` 依賴

### Q: 如何停用某些規則?

A: 在配置檔案的 `rules` 區塊中設定:
```json
"rules": {
  "規則名稱": "off"
}
```

### Q: TypeScript 專案需要額外配置嗎?

A: 如果使用 TypeScript,建議在 `parserOptions` 中加入:
```json
"parserOptions": {
  "project": "./tsconfig.json"
}
```

## 📚 參考資源

- [ESLint 官方文件](https://eslint.org/docs/latest/)
- [TypeScript ESLint](https://typescript-eslint.io/)
- [ESLint Plugin React](https://github.com/jsx-eslint/eslint-plugin-react)
