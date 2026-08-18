import { useWidgetSetting } from '@overline-zebar/config';
import { useEffect, useRef, useState } from 'react';
import * as zebar from 'zebar';
import { Center } from './components/Center';
import { LeftButtons } from './components/leftButtons';
import Media from './components/media';
import RightButtons from './components/rightButtons/RightButtons';
import StatProviders from './components/statProviders';
import Systray from './components/systray';
import { TimeDisplay } from './components/TimeDisplay';
import VolumeControl from './components/volume';
import { WindowTitle } from './components/windowTitle/WindowTitle';
import { WorkspaceControls } from './components/WorkspaceControls';
import { cn } from './utils/cn';
import { useAutoTiling } from './utils/useAutoTiling';
import { openWindowSwitcher } from './utils/openWindowSwitcher';

const providers = zebar.createProviderGroup({
  media: { type: 'media' },
  network: { type: 'network' },
  glazewm: { type: 'glazewm' },
  cpu: { type: 'cpu' },
  date: { type: 'date', formatting: 'EEE d MMM t', locale: 'en-GB' },
  memory: { type: 'memory' },
  weather: { type: 'weather' },
  audio: { type: 'audio' },
  systray: { type: 'systray' },
  battery: { type: 'battery' },
});

function App() {
  const [output, setOutput] = useState(providers.outputMap);
  const windowSwitcherStarted = useRef(false);

  useEffect(() => {
    providers.onOutput(() => setOutput(providers.outputMap));
  }, []);

  useAutoTiling();
  useEffect(() => {
    const glazewm = output.glazewm;
    const isActive = glazewm?.bindingModes.some(
      (mode) => mode.name === 'window-switcher'
    );

    if (!glazewm || !isActive) {
      windowSwitcherStarted.current = false;
      return;
    }

    if (windowSwitcherStarted.current) {
      return;
    }

    windowSwitcherStarted.current = true;
    void (async () => {
      const widgetWindow = zebar.currentWidget().tauriWindow;
      const [position, size] = await Promise.all([
        widgetWindow.outerPosition(),
        widgetWindow.outerSize(),
      ]);
      const monitor = glazewm.focusedMonitor;
      const widgetCenterX = position.x + size.width / 2;
      const widgetCenterY = position.y + size.height / 2;
      const isOnFocusedMonitor =
        widgetCenterX >= monitor.x &&
        widgetCenterX < monitor.x + monitor.width &&
        widgetCenterY >= monitor.y &&
        widgetCenterY < monitor.y + monitor.height;

      if (!isOnFocusedMonitor) {
        windowSwitcherStarted.current = false;
        return;
      }

      await openWindowSwitcher(glazewm);
    })().catch(async () => {
      windowSwitcherStarted.current = false;
      await glazewm.runCommand(
        'wm-disable-binding-mode --name window-switcher'
      );
    });
  }, [output.glazewm]);

  const volumeIconClassnames = 'h-3.5 w-3.5 text-icon';
  const [marginX] = useWidgetSetting('main', 'marginX');
  const [paddingLeft] = useWidgetSetting('main', 'paddingLeft');
  const [paddingRight] = useWidgetSetting('main', 'paddingRight');

  return (
    <div
      className={cn(
        'relative flex justify-between items-center py-1 bg-background backdrop-blur-xl text-text h-screen antialiased select-none font-mono',
        marginX > 0 && 'rounded-lg border border-border'
      )}
      style={{ margin: `0 ${marginX}px` }}
    >
      {/* Left */}
      <div
        className="flex items-center gap-2 h-full z-10"
        style={{ paddingLeft: `${paddingLeft}px` }}
      >
        <div className="flex items-center gap-2 h-full">
          <LeftButtons glazewm={output.glazewm} />
        </div>
        <div className="flex items-center h-full">
          <WorkspaceControls glazewm={output.glazewm} />
        </div>
        <div className="flex items-center justify-center h-full">
          <Media media={output.media} />
        </div>
      </div>

      <div className="absolute w-full h-full flex items-center justify-center left-0">
        <Center>
          <WindowTitle glazewm={output.glazewm} />
        </Center>
      </div>

      {/* Right */}
      <div className="flex gap-2 items-center h-full z-10">
        <div className="flex items-center h-full">
          <StatProviders
            weather={output.weather}
            battery={output.battery}
            cpu={output.cpu}
            memory={output.memory}
          />
        </div>
        <div className="flex items-center h-full">
          <VolumeControl
            audio={output.audio}
            iconClassnames={volumeIconClassnames}
          />
        </div>
        <div className="h-full flex items-center px-0.5">
          <Systray systray={output.systray} />
        </div>
        <TimeDisplay dateOutput={output.date} />
        <div
          className="flex items-center h-full"
          style={{ paddingRight: `${paddingRight}px` }}
        >
          <RightButtons />
        </div>
      </div>
    </div>
  );
}

export default App;
