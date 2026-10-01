const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const direction = process.argv[2];
if (direction !== 'previous' && direction !== 'next') process.exit(1);

const configPath = path.join(__dirname, 'cycle-workspace-window.config.json');
const lockPath = path.join(os.tmpdir(), 'glazewm-cycle-workspace-window.lock');
const sleepBuffer = new Int32Array(new SharedArrayBuffer(4));
let lockHandle;

function acquireLock() {
  for (let attempt = 0; attempt < 100; attempt++) {
    try {
      lockHandle = fs.openSync(lockPath, 'wx');
      return true;
    } catch (error) {
      if (error.code !== 'EEXIST') return false;

      try {
        if (Date.now() - fs.statSync(lockPath).mtimeMs > 10000) fs.unlinkSync(lockPath);
      } catch {}
      Atomics.wait(sleepBuffer, 0, 0, 25);
    }
  }
  return false;
}

function collectWindows(container, windows) {
  if (container.type === 'window') {
    windows.push(container);
    return;
  }

  for (const child of container.children) collectWindows(child, windows);
}

function loadConfig() {
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  if (!['same-state', 'workspace'].includes(config.scope)) {
    throw new Error('scope must be "same-state" or "workspace"');
  }
  if (!['exclude', 'fullscreen-only', 'include'].includes(config.minimizedPolicy)) {
    throw new Error('minimizedPolicy must be "exclude", "fullscreen-only", or "include"');
  }
  return config;
}

function effectiveState(window) {
  return window.state.type === 'minimized' && window.prevState
    ? window.prevState
    : window.state;
}

function stateKey(window) {
  const state = effectiveState(window);
  return state.type === 'fullscreen'
    ? `${state.type}:${state.maximized === true}`
    : state.type;
}

function glazewm(args, captureOutput = false) {
  return execFileSync('glazewm', args, {
    encoding: captureOutput ? 'utf8' : undefined,
    stdio: captureOutput ? ['ignore', 'pipe', 'ignore'] : 'ignore',
    windowsHide: true,
  });
}

function main() {
  if (!acquireLock()) return 1;

  const config = loadConfig();
  const response = JSON.parse(glazewm(['query', 'workspaces'], true));
  if (!response.success) return 1;

  const workspace = response.data.workspaces.find(candidate => candidate.hasFocus);
  if (!workspace) return 1;

  const windows = [];
  collectWindows(workspace, windows);

  const focused = windows.find(window => window.hasFocus);
  if (!focused) return 1;

  const candidates = windows.filter(window => {
    if (window.state.type === 'minimized') {
      if (config.minimizedPolicy === 'exclude') return false;
      if (config.minimizedPolicy === 'fullscreen-only' && effectiveState(window).type !== 'fullscreen') {
        return false;
      }
    }
    return config.scope === 'workspace' || stateKey(window) === stateKey(focused);
  });
  if (candidates.length < 2) return 0;

  const currentIndex = candidates.findIndex(window => window.id === focused.id);
  if (currentIndex < 0) return 1;

  const offset = direction === 'next' ? 1 : -1;
  const target = candidates[(currentIndex + offset + candidates.length) % candidates.length];

  if (target.state.type === 'minimized') {
    glazewm(['command', '--id', target.id, 'toggle-minimized']);
  }
  glazewm(['command', 'focus', '--container-id', target.id]);
  return 0;
}

let exitCode = 1;
try {
  exitCode = main();
} catch (error) {
  console.error(error);
  exitCode = 1;
} finally {
  if (lockHandle !== undefined) fs.closeSync(lockHandle);
  try {
    fs.unlinkSync(lockPath);
  } catch {}
}
process.exitCode = exitCode;
