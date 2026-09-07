import * as zebar from 'zebar';
import type { GlazeWmOutput, WidgetPlacement } from 'zebar';

export function openWindowSwitcher(glazewm: GlazeWmOutput) {
  const placement = {
    anchor: 'center',
    offsetX: '0px',
    offsetY: '0px',
    width: '640px',
    height: '440px',
    monitorSelection: {
      type: 'name',
      match: glazewm.focusedMonitor.deviceName,
    },
    dockToEdge: {
      enabled: false,
      edge: null,
      windowMargin: '0px',
    },
  } satisfies WidgetPlacement;

  return zebar.startWidget('window-switcher', placement, {});
}
