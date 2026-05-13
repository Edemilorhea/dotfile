<!-- Context: project-intelligence/technical | Priority: critical | Version: 1.0 | Updated: 2026-05-13 -->

# Technical Domain — GSS ESG Frontend

**Purpose**: GSS ESG 前端技術棧、架構模式、API 呼叫慣例、元件設計規範。
**Last Updated**: 2026-05-13

## Quick Reference
- **Update When**: 技術棧升級、新增核心函式庫、架構決策變更
- **Audience**: 前端開發者、AI agents

## Primary Stack

| Layer      | Technology              | Version      | Notes                               |
| ---------- | ----------------------- | ------------ | ----------------------------------- |
| Language   | TypeScript              | ^5.2         | strict mode, ES2020 target          |
| Framework  | React                   | ^18.2        | Functional components + Hooks       |
| Build Tool | Vite                    | ^5.2         | vite-tsconfig-paths, checker plugin |
| UI Library | Kendo React             | ^8.1         | 主要 UI 元件庫                      |
| Styling    | styled-components       | ^6.1         | CSS-in-JS，搭配 theme               |
| HTTP       | RxJS ajax               | ^7.8         | Observable 模式，非 fetch/axios     |
| Form       | Formik + Yup            | ^2.4 / ^1.4  | 表單管理與驗證                      |
| Routing    | React Router DOM        | ^7.7         | Hash Router (#/)                    |
| i18n       | i18next + react-i18next | ^25 / ^15    | 多語系                              |
| Testing    | Vitest + Testing Library| ^1.0         | jsdom 環境                          |
| Icons      | FontAwesome Pro         | ^7.0         | Pro 版，需 license                  |

## Architecture Pattern

```
SPA (Single Page Application)
├── Hash Router (#/) — 搭配後端 ASP.NET Core 部署
├── Context API — 全域狀態 (User, Alert, Dialog, Window)
├── RxJS Observable — 所有 API 呼叫
├── Service 物件 — API 封裝 (e.g., LayoutService)
└── Subject 模式 — 跨元件通訊 (alertSubject, dialogSubject)
```

## Project Structure

```
src/
├── components/     # 可重用 UI 元件 (kebab-case 目錄, PascalCase 檔名)
├── pages/          # 頁面元件 (kebab-case 目錄)
├── hooks/          # Custom hooks (use 前綴)
├── contexts/       # React Context 定義
├── layout/         # 版面配置元件與 service
├── models/         # TypeScript 型別/介面 (.model.ts)
├── utils/          # 工具函式 (api.ts, handle-error.ts...)
├── constants/      # 常數
├── route/          # 路由設定
├── theme/          # styled-components theme
└── types/          # 全域型別定義
```

## API 呼叫模式

所有 API 呼叫透過 `src/utils/api.ts` 的 `api` 物件，回傳 **RxJS Observable**。

```typescript
// ✅ 正確：Service 物件封裝 API
export const LayoutService = {
    getUserInfo: () => api.get('/api/Layout/User'),
    updateUser: (data: any) => api.post('/api/0/Common/UpdateSCUser', data),
    switchTenant: (id: string) => api.put(`/api/Common/Switch/Tenant/${id}`),
}

// ✅ 正確：元件中訂閱 Observable
LayoutService.getUserInfo().subscribe({
    next: (res) => setUser(res.response),
    error: (err) => console.error(err)
});

// ❌ 錯誤：不使用 fetch/axios，不直接呼叫 ajax
```

**API URL 規則**：
- `/api/...` → 後端 ASP.NET Core API
- `/api/0/...` → 租戶 0（系統管理）
- `/bizapi/...` → BizForm 獨立服務

## 元件設計模式

```typescript
// ✅ 標準元件：interface Props + React.FC + styled-components
export interface FieldItemProps {
    label?: string;
    required?: boolean;
    disabled?: boolean;
    errorMsg?: string;
    children?: ReactNode;
}

export const FieldItem: React.FC<FieldItemProps> = (props) => {
    return (
        <FieldContainer>
            {props.label && <FieldLabel required={props.required}>{props.label}</FieldLabel>}
            {props.children}
            {props.errorMsg && <ErrorLabel>{props.errorMsg}</ErrorLabel>}
        </FieldContainer>
    );
}

// ✅ 效能敏感元件：使用 memo
export default memo(VitalDesignButton);
```

## Naming Conventions

| Type       | Convention                | Example                              |
| ---------- | ------------------------- | ------------------------------------ |
| 元件目錄   | kebab-case                | `action-bar/`, `search-bar/`         |
| 元件檔案   | PascalCase                | `Button.tsx`, `FieldItem.tsx`        |
| Hook       | camelCase + use 前綴      | `useGlobalContext.ts`                |
| Service    | PascalCase + Service 後綴 | `LayoutService`, `layout.service.ts` |
| Model      | camelCase + .model.ts     | `layout.model.ts`                    |
| Utils      | kebab-case                | `handle-error.ts`, `api.ts`          |
| CSS-in-JS  | PascalCase (styled)       | `const FieldContainer = styled.div` |

## Code Standards

- TypeScript strict mode（`"strict": true`），但 `strictNullChecks: false`
- 路徑別名：`src/*` → `./src/*`（使用 `src/` 前綴 import，非相對路徑）
- 所有 API 呼叫使用 RxJS Observable，**不使用** async/await + fetch/axios
- 全域通知透過 Subject：`alertSubject`、`dialogSubject`、`loaderSubject`
- 全域 Context 透過 `useGlobalContext()` hook 取得（含 currentUser、t、sendAlert 等）
- 表單驗證：Formik + Yup schema
- 多語系：`useTranslation()` hook，`t('key')` 翻譯

## Security Requirements

- XSRF/CSRF 防護：所有 POST/PUT/DELETE 自動附加 `X-XSRF-TOKEN` header
- Token 自動刷新：401 時自動呼叫 `/api/Account/Jwt/Refresh`
- Antiforgery token 失效（400）時自動重取並重送請求
- 登出時清除 `localStorage`、`sessionStorage`、XSRF cookie
- 使用者輸入透過 DOMPurify 消毒（`dompurify ^3.2`）
- 環境變數透過 `import.meta.env.VITE_*` 存取，敏感值不寫入程式碼

## 📂 Codebase References

| 功能              | 路徑                                                  |
| ----------------- | ----------------------------------------------------- |
| API 工具          | `src/utils/api.ts`                                    |
| 錯誤處理          | `src/utils/handle-error.ts`                           |
| 全域 Context Hook | `src/hooks/useGlobalContext.ts`                       |
| 元件範例          | `src/components/form/item/FieldItem.tsx`              |
| 按鈕元件          | `src/components/button/Button.tsx`                    |
| Layout Service    | `src/layout/layout.service.ts`                        |
| 路由設定          | `src/route/route-config.ts`                           |
| 主題設定          | `src/theme/`                                          |
| 環境變數          | `.env`, `.env.dev`, `.env.staging`, `.env.production` |

## Related Files

- `business-domain.md` — 業務領域說明
- `business-tech-bridge.md` — 業務需求與技術實作對應
- `decisions-log.md` — 技術決策歷史
