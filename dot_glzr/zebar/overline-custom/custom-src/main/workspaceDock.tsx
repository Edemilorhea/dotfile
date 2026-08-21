import { motion } from 'framer-motion';
import { useEffect, useMemo, useRef, useState } from 'react';
import * as zebar from 'zebar';
import type { GlazeWmOutput } from 'zebar';

const iconHelper = 'tools/WindowIconHelper.exe';
const widgetPackPath = zebar.currentWidget().htmlPath.replace(
  /[\\/]widgets[\\/]main[\\/]dist[\\/][^\\/]+$/,
  ''
);
const expandedStorageKey = 'overline.workspaceDock.expanded';
const iconLookups = new Map<string, Promise<string | null>>();

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

function normalizeProcessName(processName: string) {
  return processName.trim().toLowerCase();
}

function getWindowIcon(processName: string) {
  const normalized = normalizeProcessName(processName);
  const existing = iconLookups.get(normalized);
  if (existing) return existing;

  const lookup = zebar
    .shellExec(iconHelper, [processName], { cwd: widgetPackPath })
    .then((output) => {
      const base64 = output.stdout.trim();
      return output.code === 0 && base64 ? base64 : null;
    })
    .catch(() => null);

  iconLookups.set(normalized, lookup);
  return lookup;
}

function getStateLabel(window: WorkspaceWindow) {
  if (window.state.type !== 'minimized') return window.state.type;
  return window.prevState ? `minimized (${window.prevState.type})` : 'minimized';
}

type WorkspaceDockProps = {
  glazewm: GlazeWmOutput | null;
};

export function WorkspaceDock({ glazewm }: WorkspaceDockProps) {
  const [expanded, setExpanded] = useState(() => {
    return window.localStorage.getItem(expandedStorageKey) !== 'false';
  });
  const [icons, setIcons] = useState<Record<string, string | null>>({});
  const railRef = useRef<HTMLDivElement>(null);

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
          window !== undefined &&
          normalizeProcessName(window.processName) !== 'zebar'
      );
  }, [glazewm]);

  useEffect(() => {
    window.localStorage.setItem(expandedStorageKey, String(expanded));
  }, [expanded]);

  useEffect(() => {
    const processNames = [...new Set(windows.map((window) => window.processName))]
      .filter(Boolean);
    let active = true;

    void Promise.all(
      processNames.map(async (processName) => [
        normalizeProcessName(processName),
        await getWindowIcon(processName),
      ])
    ).then((entries) => {
      if (!active) return;
      setIcons((current) => ({ ...current, ...Object.fromEntries(entries) }));
    });

    return () => {
      active = false;
    };
  }, [windows]);

  if (!glazewm) return null;

  const activate = async (window: WorkspaceWindow) => {
    if (window.state.type === 'minimized') {
      await glazewm.runCommand('toggle-minimized', window.id);
    }
    await glazewm.runCommand(`focus --container-id ${window.id}`);
  };

  const handleWheel = (event: React.WheelEvent<HTMLDivElement>) => {
    if (!railRef.current || event.deltaY === 0) return;
    event.preventDefault();
    railRef.current.scrollLeft += event.deltaY;
  };

  const visibleWindows = expanded ? windows : windows.slice(0, 4);
  const compactWidth = Math.min(windows.length, 4) * 32 - 4;
  const expandedWidth = Math.min(windows.length * 32 - 4, 352);
  const toggleLabel = `按住 Shift 並按一下滑鼠左鍵，以${expanded ? '收合' : '展開'}目前工作區視窗`;

  return (
    <div
      className="flex h-full min-w-0 items-center"
      data-workspace-dock
      role="group"
      title={toggleLabel}
      aria-label={toggleLabel}
      aria-expanded={expanded}
      onClick={(event) => {
        if (!event.shiftKey) return;
        event.preventDefault();
        setExpanded((value) => !value);
      }}
    >
      {windows.length > 0 && (
        <motion.div
          initial={false}
          animate={{
            width: expanded ? expandedWidth : compactWidth,
            opacity: 1,
          }}
          transition={{ duration: 0.18, ease: 'easeOut' }}
          className="h-full min-w-0 overflow-hidden"
        >
          <div
            ref={railRef}
            onWheel={handleWheel}
            className="flex h-full min-w-0 items-center gap-1 overflow-x-auto overscroll-x-contain [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          >
            {visibleWindows.map((window, index) => {
                const minimized = window.state.type === 'minimized';
                const icon = icons[normalizeProcessName(window.processName)];
                const label = `${window.processName || 'Unknown'}: ${window.title || '(untitled)'} · ${getStateLabel(window)}`;

                return (
                  <motion.button
                    key={window.id}
                    type="button"
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: minimized ? 0.5 : 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.8 }}
                    transition={{ duration: 0.14, delay: index * 0.025 }}
                    className={`relative flex h-7 w-7 shrink-0 items-center justify-center border text-[10px] font-semibold uppercase transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary ${
                      window.hasFocus
                        ? 'border-primary bg-primary/15 text-primary ring-1 ring-primary/70'
                        : 'border-transparent bg-button text-icon hover:bg-button-hover'
                    }`}
                    title={label}
                    aria-label={label}
                    aria-current={window.hasFocus ? 'true' : undefined}
                    onClick={(event) => {
                      if (!event.shiftKey) void activate(window);
                    }}
                  >
                    {icon ? (
                      <img
                        src={`data:image/png;base64,${icon}`}
                        alt=""
                        className={`h-4 w-4 object-contain ${
                          window.hasFocus
                            ? 'brightness-125'
                            : minimized
                              ? 'grayscale saturate-0 brightness-75 opacity-70'
                              : 'brightness-110 saturate-100 opacity-90'
                        }`}
                      />
                    ) : (
                      <span>{(window.processName || '?').slice(0, 1)}</span>
                    )}
                    {minimized && (
                      <span
                        className="absolute right-0.5 top-0.5 h-1 w-1 bg-muted-foreground"
                        aria-label="已最小化"
                      />
                    )}
                    {window.hasFocus && (
                      <motion.span
                        layoutId="workspaceDockFocusedWindow"
                        className="absolute inset-x-0 bottom-0 h-1 bg-primary"
                      />
                    )}
                  </motion.button>
                );
            })}
          </div>
        </motion.div>
      )}
    </div>
  );
}
