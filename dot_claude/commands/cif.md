# CIF - 元件實作流程圖

請為我製作一個元件實作流程圖 (Component Implementation Flow),展示每個元件需要新增/修改的內容和相互關聯。

## 流程圖應包含:

1. **元件框架圖** - 顯示每個元件需要新增/修改的內容
2. **Props 傳遞關係** - 箭頭表示資料流向
3. **實作步驟順序** - 建議的開發順序
4. **資料流向圖** - 簡化的使用者互動流程

## 格式範例:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            ParentComponent.tsx                           │
│  新增:                                                                   │
│  ✓ state: showModal, selectedId                                        │
│  ✓ function: handleAction(id)                                          │
│  ✓ 新增 ChildModal 元件                                                │
└────────────────────────┬────────────────────────────────────────────────┘
                         │
                         │ 傳遞 props:
                         │ - onAction={handleAction}
                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            ChildComponent.tsx                            │
│  新增:                                                                   │
│  ✓ props: onAction?: (id: string) => void                             │
│  ✓ 修改 handler 呼叫 onAction                                          │
└─────────────────────────────────────────────────────────────────────────┘

實作步驟順序:
1. ChildComponent.tsx - 修改 props 和事件處理
2. ParentComponent.tsx - 加入狀態管理和 callback

資料流向: 使用者操作 → Child → Parent → Modal → API → 更新
```

請根據當前討論的功能,產生對應的 CIF 流程圖。
