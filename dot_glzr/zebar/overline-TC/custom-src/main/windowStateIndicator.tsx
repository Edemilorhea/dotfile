import { AnimatePresence, motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { GlazeWmOutput } from 'zebar';

interface WindowStateIndicatorProps {
  glazewm: GlazeWmOutput | null;
}

interface FocusedResponse {
  messageType?: string;
  clientMessage?: string;
  error?: unknown;
  data?: {
    focused?: {
      type?: string;
      state?: { type?: string; maximized?: boolean };
    };
  };
}

function stateLabel(state?: { type?: string; maximized?: boolean }) {
  if (!state?.type) return null;
  return state.type === 'fullscreen' && state.maximized
    ? 'maximized'
    : state.type;
}

export function WindowStateIndicator({
  glazewm,
}: WindowStateIndicatorProps) {
  const providerState =
    glazewm?.focusedContainer.type === 'window'
      ? stateLabel(glazewm.focusedContainer.state)
      : null;
  const [windowState, setWindowState] = useState<string | null>(providerState);

  useEffect(() => setWindowState(providerState), [providerState]);

  useEffect(() => {
    let active = true;
    let socket: WebSocket | null = null;
    let pollTimer: number | null = null;
    let reconnectTimer: number | null = null;

    const clearPollTimer = () => {
      if (pollTimer !== null) window.clearInterval(pollTimer);
      pollTimer = null;
    };

    const connect = () => {
      if (!active) return;
      socket = new WebSocket('ws://localhost:6123');

      socket.addEventListener('open', () => {
        const queryFocused = () => {
          if (socket?.readyState === WebSocket.OPEN) {
            socket.send('query focused');
          }
        };

        queryFocused();
        pollTimer = window.setInterval(queryFocused, 250);
      });

      socket.addEventListener('message', (event) => {
        try {
          const response = JSON.parse(String(event.data)) as FocusedResponse;
          if (
            response.messageType !== 'client_response' ||
            response.clientMessage !== 'query focused' ||
            response.error
          ) {
            return;
          }

          const focused = response.data?.focused;
          setWindowState(
            focused?.type === 'window' ? stateLabel(focused.state) : null
          );
        } catch {
          // Ignore unrelated or malformed IPC messages.
        }
      });

      socket.addEventListener('close', () => {
        clearPollTimer();
        if (active) reconnectTimer = window.setTimeout(connect, 1000);
      });
    };

    connect();
    return () => {
      active = false;
      clearPollTimer();
      if (reconnectTimer !== null) window.clearTimeout(reconnectTimer);
      socket?.close();
    };
  }, []);

  return (
    <AnimatePresence mode="wait">
      {windowState && (
        <motion.span
          key={windowState}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.12, ease: 'easeInOut' }}
          title="目前聚焦視窗的 GlazeWM 狀態"
          className="flex items-center h-full rounded-md bg-black px-2 text-xs font-semibold leading-none text-white"
        >
          {windowState.toUpperCase()}
        </motion.span>
      )}
    </AnimatePresence>
  );
}
