import { StrictMode, useEffect, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { ConfigProvider } from "@overline-zebar/config";
import { Keyboard, Search, X } from "lucide-react";
import * as zebar from "zebar";
import "./index.css";
import "@overline-zebar/ui/fonts.css";
import "@overline-zebar/ui/index.css";
import "@overline-zebar/ui/theme.css";

type Shortcut = { action: string; keys: string[][] };
type ShortcutGroup = { category: string; shortcuts: Shortcut[] };

const shortcutGroups: ShortcutGroup[] = [
  {
    category: "焦點與導覽",
    shortcuts: [
      {
        action: "聚焦左側視窗",
        keys: [
          ["Alt", "H"],
          ["Alt", "Left"],
        ],
      },
      {
        action: "聚焦右側視窗",
        keys: [
          ["Alt", "L"],
          ["Alt", "Right"],
        ],
      },
      {
        action: "聚焦上方視窗",
        keys: [
          ["Alt", "K"],
          ["Alt", "Up"],
        ],
      },
      {
        action: "聚焦下方視窗",
        keys: [
          ["Alt", "J"],
          ["Alt", "Down"],
        ],
      },
      {
        action: "目前工作區上一個／下一個視窗",
        keys: [
          ["Alt", "["],
          ["Alt", "]"],
        ],
      },
      { action: "在平鋪、浮動與全螢幕之間循環聚焦", keys: [["Alt", "C"]] },
      { action: "切換至最近使用的工作區", keys: [["Alt", "D"]] },
      { action: "聚焦工作區 1 至 9", keys: [["Alt", "1…9"]] },
    ],
  },
  {
    category: "視窗移動與狀態",
    shortcuts: [
      {
        action: "向左移動視窗",
        keys: [
          ["Alt", "Shift", "H"],
          ["Alt", "Shift", "Left"],
        ],
      },
      {
        action: "向右移動視窗",
        keys: [
          ["Alt", "Shift", "L"],
          ["Alt", "Shift", "Right"],
        ],
      },
      {
        action: "向上移動視窗",
        keys: [
          ["Alt", "Shift", "K"],
          ["Alt", "Shift", "Up"],
        ],
      },
      {
        action: "向下移動視窗",
        keys: [
          ["Alt", "Shift", "J"],
          ["Alt", "Shift", "Down"],
        ],
      },
      {
        action: "置中浮動視窗（900 × 650）",
        keys: [["Alt", "Shift", "Space"]],
      },
      { action: "切換平鋪", keys: [["Alt", "T"]] },
      { action: "切換全螢幕", keys: [["Alt", "F"]] },
      { action: "最大化全螢幕（保留面板）", keys: [["Alt", "Z"]] },
      { action: "最小化視窗", keys: [["Alt", "Shift", "M"]] },
      { action: "關閉視窗", keys: [["Alt", "Shift", "Q"]] },
      { action: "停止管理聚焦視窗", keys: [["Alt", "Shift", "U"]] },
    ],
  },
  {
    category: "調整大小",
    shortcuts: [
      { action: "寬度減少 30px", keys: [["Alt", "U"]] },
      { action: "寬度增加 30px", keys: [["Alt", "P"]] },
      { action: "高度增加 30px", keys: [["Alt", "O"]] },
      { action: "高度減少 30px", keys: [["Alt", "I"]] },
      { action: "進入調整大小模式", keys: [["Alt", "R"]] },
      { action: "調整大小模式：寬度 -30px", keys: [["H"], ["Left"]] },
      { action: "調整大小模式：寬度 +30px", keys: [["L"], ["Right"]] },
      { action: "調整大小模式：高度 +30px", keys: [["K"], ["Up"]] },
      { action: "調整大小模式：高度 -30px", keys: [["J"], ["Down"]] },
      {
        action: "調整大小模式：寬度 -1px",
        keys: [
          ["Shift", "H"],
          ["Shift", "Left"],
        ],
      },
      {
        action: "調整大小模式：寬度 +1px",
        keys: [
          ["Shift", "L"],
          ["Shift", "Right"],
        ],
      },
      {
        action: "調整大小模式：高度 +1px",
        keys: [
          ["Shift", "K"],
          ["Shift", "Up"],
        ],
      },
      {
        action: "調整大小模式：高度 -1px",
        keys: [
          ["Shift", "J"],
          ["Shift", "Down"],
        ],
      },
      { action: "離開調整大小模式", keys: [["Enter"], ["Esc"]] },
    ],
  },
  {
    category: "工作區與螢幕",
    shortcuts: [
      {
        action: "將視窗移至工作區 1 至 9 並跟隨",
        keys: [["Alt", "Shift", "1…9"]],
      },
      {
        action: "將工作區移至左／右／上／下螢幕",
        keys: [
          ["Alt", "Shift", "A"],
          ["Alt", "Shift", "F"],
          ["Alt", "Shift", "D"],
          ["Alt", "Shift", "S"],
        ],
      },
    ],
  },
  {
    category: "GlazeWM 與工具",
    shortcuts: [
      { action: "切換平鋪方向", keys: [["Alt", "V"]] },
      { action: "開啟目前工作區視窗選擇器", keys: [["Alt", "Shift", "G"]] },
      { action: "進入／離開直通模式", keys: [["Alt", "Shift", "P"]] },
      { action: "暫停／繼續 GlazeWM", keys: [["Alt", "Shift", "]"]] },
      { action: "重新載入設定", keys: [["Alt", "Shift", "R"]] },
      { action: "重繪視窗", keys: [["Alt", "Shift", "W"]] },
      { action: "安全結束 GlazeWM", keys: [["Alt", "Shift", "E"]] },
    ],
  },
];

const shortcutCount = shortcutGroups.reduce(
  (count, group) => count + group.shortcuts.length,
  0,
);

const shortcutGuideLayout = `
  @media (max-width: 480px) {
    .shortcut-guide-row { align-items: stretch; flex-direction: column; gap: 0.375rem; padding-bottom: 0.5rem; padding-top: 0.5rem; }
    .shortcut-guide-action { width: 100%; }
    .shortcut-guide-keycaps { flex: none; width: 100%; }
  }
`;

function Keycaps({ keys }: { keys: string[][] }) {
  return (
    <span className="shortcut-guide-keycaps flex min-w-0 flex-1 flex-wrap justify-end gap-1.5">
      {keys.map((keySet, keySetIndex) => (
        <span key={keySet.join("-")} className="flex items-center gap-0.5">
          {keySetIndex > 0 && (
            <span className="px-0.5 text-muted-foreground">/</span>
          )}
          {keySet.map((key, keyIndex) => (
            <span key={key} className="flex items-center gap-0.5">
              {keyIndex > 0 && <span className="text-muted-foreground">+</span>}
              <kbd className="rounded border border-border bg-button px-1.5 py-0.5 text-[10px] leading-4 text-text shadow-sm">
                {key}
              </kbd>
            </span>
          ))}
        </span>
      ))}
    </span>
  );
}

function ShortcutGuide() {
  const [query, setQuery] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const closing = useRef(false);

  const close = async () => {
    if (closing.current) return;
    closing.current = true;
    await zebar.currentWidget().close();
  };

  const normalizedQuery = query.trim().toLowerCase();
  const filteredGroups = shortcutGroups
    .map((group) => ({
      ...group,
      shortcuts: group.shortcuts.filter((shortcut) =>
        [group.category, shortcut.action, shortcut.keys.flat(2).join(" ")].some(
          (value) => value.toLowerCase().includes(normalizedQuery),
        ),
      ),
    }))
    .filter((group) => group.shortcuts.length > 0);

  useEffect(() => {
    const widget = zebar.currentWidget();
    widget.setZOrder("top_most");
    widget.tauriWindow.setFocus();
    inputRef.current?.focus();

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        void close();
      }
    };
    const handleBlur = () => void close();

    window.addEventListener("keydown", handleKeyDown);
    window.addEventListener("blur", handleBlur);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      window.removeEventListener("blur", handleBlur);
    };
  }, []);

  return (
    <main className="flex h-screen flex-col overflow-hidden rounded-xl border border-border bg-background/95 p-3 font-mono text-text shadow-2xl backdrop-blur-xl">
      <style>{shortcutGuideLayout}</style>
      <header className="flex h-10 shrink-0 items-center justify-between border-b border-border px-2 pb-2">
        <div className="flex min-w-0 items-center gap-2">
          <Keyboard className="h-4 w-4 shrink-0 text-primary" />
          <h1 className="truncate text-sm font-semibold">GlazeWM 快捷鍵</h1>
          <span className="rounded bg-button px-1.5 py-0.5 text-[10px] text-muted-foreground">
            {shortcutCount}
          </span>
        </div>
        <button
          type="button"
          className="rounded-md p-2 text-muted-foreground outline-none transition-colors hover:bg-button-hover hover:text-text focus-visible:ring-1 focus-visible:ring-primary"
          title="關閉 (Esc)"
          onClick={() => void close()}
        >
          <X className="h-4 w-4" />
        </button>
      </header>

      <label className="mt-3 flex h-9 shrink-0 items-center gap-2 rounded-lg border border-border bg-button px-2 text-muted-foreground focus-within:ring-1 focus-within:ring-primary">
        <Search className="h-3.5 w-3.5" />
        <input
          ref={inputRef}
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="搜尋按鍵、動作或分類"
          className="min-w-0 flex-1 bg-transparent text-xs text-text outline-none placeholder:text-muted-foreground"
          type="search"
        />
      </label>

      <section
        className="min-h-0 flex-1 overflow-y-auto py-3 pr-1"
        aria-label="GlazeWM 快捷鍵列表"
      >
        {filteredGroups.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center gap-2 text-center text-sm text-muted-foreground">
            <Search className="h-5 w-5" />
            <p>找不到符合的快捷鍵</p>
            <button
              type="button"
              className="rounded-md border border-border bg-button px-2 py-1 text-xs font-semibold text-text outline-none transition-colors hover:text-primary focus-visible:ring-1 focus-visible:ring-primary"
              onClick={() => setQuery("")}
            >
              清除搜尋
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredGroups.map((group) => (
              <section
                key={group.category}
                className="overflow-hidden rounded-lg border border-border"
                aria-labelledby={`category-${group.category}`}
              >
                <header className="flex h-8 items-center justify-between border-b border-border bg-button px-3">
                  <h2
                    id={`category-${group.category}`}
                    className="text-xs font-semibold tracking-wide text-text"
                  >
                    {group.category}
                  </h2>
                  <span className="text-[10px] font-medium text-muted-foreground">
                    {group.shortcuts.length} 項
                  </span>
                </header>
                <div>
                  {group.shortcuts.map((shortcut, index) => (
                    <div
                      key={shortcut.action}
                      className={`shortcut-guide-row flex min-h-10 items-center justify-between gap-3 px-3 py-1.5 ${index > 0 ? "border-t border-border" : ""}`}
                    >
                      <span className="shortcut-guide-action w-52 shrink-0 text-xs leading-5 text-text">
                        {shortcut.action}
                      </span>
                      <Keycaps keys={shortcut.keys} />
                    </div>
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}
      </section>

      <footer className="flex h-7 shrink-0 items-center justify-between border-t border-border px-2 pt-2 text-[10px] text-muted-foreground">
        <span>輸入即可篩選</span>
        <span>Esc 關閉</span>
      </footer>
    </main>
  );
}

const rootElement = document.getElementById("root");
if (!rootElement) throw new Error("Failed to find the root element");

createRoot(rootElement).render(
  <StrictMode>
    <ConfigProvider>
      <ShortcutGuide />
    </ConfigProvider>
  </StrictMode>,
);
