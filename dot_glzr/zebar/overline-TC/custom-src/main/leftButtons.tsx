import { useWidgetSetting } from '@overline-zebar/config';
import { Button } from '@overline-zebar/ui';
import { AnimatePresence, motion } from 'framer-motion';
import { ChevronRight, Keyboard, LayoutGrid, List } from 'lucide-react';
import { useRef } from 'react';
import * as zebar from 'zebar';
import { GlazeWmOutput } from 'zebar';
import { calculateWidgetPlacementFromLeft } from '../../utils/calculateWidgetPlacement';
import { cn } from '../../utils/cn';
import { openWindowSwitcher } from '../../utils/openWindowSwitcher';

interface LeftButtonsProps {
  glazewm: GlazeWmOutput | null;
}

export function LeftButtons({ glazewm }: LeftButtonsProps) {
  const buttonRef = useRef<HTMLButtonElement>(null);
  const shortcutGuideButtonRef = useRef<HTMLButtonElement>(null);
  const [marginX] = useWidgetSetting('main', 'marginX');

  if (!glazewm) return null;

  const calculatePlacementFromRef = async () => {
    return await calculateWidgetPlacementFromLeft(
      buttonRef,
      {
        width: 400,
        height: 400,
      },
      marginX
    );
  };

  const handleOpenScriptLauncher = async () => {
    const placement = await calculatePlacementFromRef();
    await zebar.startWidget('script-launcher', placement, {});
  };

  const handleOpenShortcutGuide = async () => {
    const placement = await calculateWidgetPlacementFromLeft(
      shortcutGuideButtonRef,
      {
        width: 680,
        height: 620,
      },
      marginX
    );
    await zebar.startWidget('shortcut-guide', placement, {});
  };

  return (
    <div className="flex items-center h-full gap-1.5">
      <AnimatePresence>
        {glazewm.isPaused && (
          <motion.div
            key="paused"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.15, ease: 'easeInOut' }}
            exit={{ opacity: 0 }}
            className="flex items-center h-full"
          >
            <Button
              size="sm"
              onClick={() => glazewm.runCommand('wm-toggle-pause')}
            >
              PAUSED
            </Button>
          </motion.div>
        )}

        {glazewm.bindingModes.map((bindingMode) => (
          <motion.div
            key={bindingMode.name}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.15, ease: 'easeInOut' }}
            exit={{ opacity: 0 }}
            className="flex items-center h-full"
          >
            <Button size="sm">
              {bindingMode.displayName ?? bindingMode.name}
            </Button>
          </motion.div>
        ))}
      </AnimatePresence>

      <Button
        size="icon-sm"
        ref={buttonRef}
        className="h-full"
        onClick={handleOpenScriptLauncher}
      >
        <LayoutGrid strokeWidth={2.5} className="h-3 w-3" />
      </Button>

      <Button
        size="icon-sm"
        ref={shortcutGuideButtonRef}
        className="h-full"
        title="GlazeWM 快捷鍵"
        onClick={handleOpenShortcutGuide}
      >
        <Keyboard strokeWidth={2.5} className="h-3 w-3" />
      </Button>

      <Button
        size="icon-sm"
        className="h-full"
        title="目前 workspace 的視窗 (Alt+Shift+G)"
        onClick={() => openWindowSwitcher(glazewm)}
      >
        <List strokeWidth={2.5} className="h-3 w-3" />
      </Button>

      <Button
        size="icon-sm"
        onClick={() => glazewm.runCommand('toggle-tiling-direction')}
        className="h-full"
      >
        <ChevronRight
          className={cn(
            'h-3 w-3 transition-transform duration-200 ease-in-out',
            glazewm.tilingDirection === 'vertical' ? 'rotate-90' : ''
          )}
          strokeWidth={3}
        />
      </Button>
    </div>
  );
}
