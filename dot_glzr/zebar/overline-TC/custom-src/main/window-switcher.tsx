import { StrictMode, useEffect, useMemo, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { Check, CornerDownLeft, Minus, X } from 'lucide-react';
import * as zebar from 'zebar';
import type { GlazeWmOutput } from 'zebar';
import './index.css';
import '@overline-zebar/ui/fonts.css';
import '@overline-zebar/ui/index.css';
import '@overline-zebar/ui/theme.css';

const providers = zebar.createProviderGroup({
  glazewm: { type: 'glazewm' },
});

type WorkspaceWindow = GlazeWmOutput['allWindows'][number];
type TreeContainer = {
  id: string;
  type: string;
  children?: TreeContainer[];
};

function collectWindowIds(container: TreeContainer): string[] {
  if (container.type === 'window') return [container.id];
  return (container.children ?? []).flatMap(collectWindowIds);
}

function WindowSwitcher() {
  const [glazewm, setGlazewm] = useState(providers.outputMap.glazewm);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const closing = useRef(false);
  const modeWasActive = useRef(false);
  const windowListRef = useRef<HTMLElement>(null);

  const windows = useMemo(() => {
    if (!glazewm) return [];

    const windowsById = new Map(
      glazewm.allWindows.map((window) => [window.id, window])
    );
    const windowIds = collectWindowIds(
      glazewm.displayedWorkspace as TreeContainer
    );

    return windowIds
      .map((id) => windowsById.get(id))
      .filter(
        (window): window is WorkspaceWindow =>
          window !== undefined && window.processName.toLowerCase() !== 'zebar'
      )
      .map((window, order) => ({ window, order }))
      .sort((a, b) => {
        const aMinimized = a.window.state.type === 'minimized' ? 0 : 1;
        const bMinimized = b.window.state.type === 'minimized' ? 0 : 1;
        return aMinimized - bMinimized || a.order - b.order;
      })
      .map(({ window }) => window);
  }, [glazewm]);

  const close = async () => {
    if (closing.current) return;
    closing.current = true;
    const widget = zebar.currentWidget();

    try {
      if (
        glazewm?.bindingModes.some((mode) => mode.name === 'window-switcher')
      ) {
        await glazewm.runCommand(
          'wm-disable-binding-mode --name window-switcher'
        );
      }
    } finally {
      await widget.close();
    }
  };

  const activate = async (window: WorkspaceWindow) => {
    if (!glazewm || closing.current) return;

    closing.current = true;
    const widget = zebar.currentWidget();

    try {
      if (
        glazewm.bindingModes.some((mode) => mode.name === 'window-switcher')
      ) {
        await glazewm.runCommand(
          'wm-disable-binding-mode --name window-switcher'
        );
      }

      if (window.state.type === 'minimized') {
        await glazewm.runCommand('toggle-minimized', window.id);
      }
      await glazewm.runCommand(`focus --container-id ${window.id}`);
    } finally {
      await widget.close();
    }
  };

  useEffect(() => {
    const widget = zebar.currentWidget();
    widget.setZOrder('top_most');
    widget.tauriWindow.setFocus();

    providers.onOutput(() => setGlazewm(providers.outputMap.glazewm));
  }, []);

  useEffect(() => {
    const modeActive = glazewm?.bindingModes.some(
      (mode) => mode.name === 'window-switcher'
    );
    if (modeActive) modeWasActive.current = true;
    if (!modeActive && modeWasActive.current) close();
  }, [glazewm?.bindingModes]);

  useEffect(() => {
    setSelectedIndex((index) =>
      Math.min(index, Math.max(windows.length - 1, 0))
    );
  }, [windows.length]);

  useEffect(() => {
    const windowList = windowListRef.current;
    const selectedButton = windowList?.querySelector<HTMLButtonElement>(
      '[data-selected="true"]'
    );
    if (!windowList || !selectedButton) return;

    const listBounds = windowList.getBoundingClientRect();
    const selectedBounds = selectedButton.getBoundingClientRect();
    if (selectedBounds.top < listBounds.top) {
      windowList.scrollTop -= listBounds.top - selectedBounds.top;
    } else if (selectedBounds.bottom > listBounds.bottom) {
      windowList.scrollTop += selectedBounds.bottom - listBounds.bottom;
    }
  }, [selectedIndex]);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        close();
        return;
      }
      if (!windows.length) return;

      if (event.key === 'ArrowDown' || event.key.toLowerCase() === 'j') {
        event.preventDefault();
        setSelectedIndex((index) => (index + 1) % windows.length);
      } else if (event.key === 'ArrowUp' || event.key.toLowerCase() === 'k') {
        event.preventDefault();
        setSelectedIndex(
          (index) => (index - 1 + windows.length) % windows.length
        );
      } else if (event.key === 'Home') {
        event.preventDefault();
        setSelectedIndex(0);
      } else if (event.key === 'End') {
        event.preventDefault();
        setSelectedIndex(windows.length - 1);
      } else if (event.key === 'Enter') {
        const selectedWindow = windows[selectedIndex];
        event.preventDefault();
        if (selectedWindow) activate(selectedWindow);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [glazewm, selectedIndex, windows]);

  return (
    <main className="h-screen overflow-hidden rounded-xl border border-border bg-background/95 p-3 font-mono text-text shadow-2xl backdrop-blur-xl">
      <header className="mb-2 flex h-11 items-center justify-between border-b border-border px-2">
        <div>
          <div className="text-sm font-semibold">Workspace windows</div>
          <div className="text-xs text-muted-foreground">
            Workspace{' '}
            {glazewm?.displayedWorkspace.displayName ??
              glazewm?.displayedWorkspace.name ??
              ''}
            {' · '}minimized first
          </div>
        </div>
        <button
          type="button"
          className="rounded-md p-2 text-muted-foreground hover:bg-button-hover hover:text-text"
          title="關閉 (Esc)"
          onClick={close}
        >
          <X className="h-4 w-4" />
        </button>
      </header>

      <section ref={windowListRef} className="h-[332px] overflow-y-auto pr-1">
        {windows.length === 0 ? (
          <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
            目前 workspace 沒有視窗
          </div>
        ) : (
          <div className="space-y-1">
            {windows.map((window, index) => {
              const minimized = window.state.type === 'minimized';
              const effectiveState =
                minimized && window.prevState ? window.prevState : window.state;
              const stateLabel =
                effectiveState.type === 'fullscreen'
                  ? effectiveState.maximized
                    ? 'maximized'
                    : 'fullscreen'
                  : effectiveState.type;
              const selected = index === selectedIndex;

              return (
                <button
                  key={window.id}
                  type="button"
                  data-selected={selected ? 'true' : undefined}
                  className={`flex w-full items-center gap-3 rounded-lg border px-3 py-2.5 text-left transition-colors ${
                    selected
                      ? 'border-primary bg-primary/15'
                      : 'border-transparent hover:bg-button-hover'
                  }`}
                  onMouseEnter={() => setSelectedIndex(index)}
                  onClick={() => activate(window)}
                >
                  <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-md bg-button text-sm font-bold uppercase text-icon">
                    {(window.processName || '?').slice(0, 1)}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="flex items-center gap-2">
                      <span className="truncate text-sm font-semibold">
                        {window.processName || 'Unknown'}
                      </span>
                      <span className="shrink-0 rounded bg-primary/15 px-1.5 py-0.5 text-[10px] text-primary">
                        {stateLabel}
                      </span>
                      {minimized && (
                        <span className="flex shrink-0 items-center gap-1 rounded bg-button px-1.5 py-0.5 text-[10px] text-muted-foreground">
                          <Minus className="h-2.5 w-2.5" /> minimized
                        </span>
                      )}
                    </span>
                    <span className="block truncate text-xs text-muted-foreground">
                      {window.title || '(untitled)'}
                    </span>
                  </span>
                  {window.hasFocus ? (
                    <Check className="h-4 w-4 shrink-0 text-success" />
                  ) : selected ? (
                    <CornerDownLeft className="h-4 w-4 shrink-0 text-primary" />
                  ) : null}
                </button>
              );
            })}
          </div>
        )}
      </section>

      <footer className="mt-2 flex h-8 items-center justify-between border-t border-border px-2 pt-2 text-[11px] text-muted-foreground">
        <span>↑ ↓ / J K 選擇</span>
        <span>Enter 開啟 · Esc 關閉</span>
      </footer>
    </main>
  );
}

const rootElement = document.getElementById('root');
if (!rootElement) throw new Error('Failed to find the root element');

createRoot(rootElement).render(
  <StrictMode>
    <WindowSwitcher />
  </StrictMode>
);
