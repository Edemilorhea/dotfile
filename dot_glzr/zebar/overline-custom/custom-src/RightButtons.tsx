import { logger } from '@overline-zebar/config/src/utils/logger';
import { Button } from '@overline-zebar/ui';
import { Moon, Power, Snowflake } from 'lucide-react';
import { useState } from 'react';
import * as zebar from 'zebar';

const sleepHelper = 'tools/SleepHelper.exe';
const widgetPackPath = zebar.currentWidget().htmlPath.replace(
  /[\\/]widgets[\\/]main[\\/]dist[\\/][^\\/]+$/,
  ''
);

export default function RightButtons() {
  return (
    <div className="flex items-center gap-2 h-full">
      <PowerOffButton />
    </div>
  );
}

function PowerOffButton() {
  const [menuOpen, setMenuOpen] = useState(false);

  const runPowerCommand = async (program: string, args: string[]) => {
    setMenuOpen(false);
    await zebar
      .shellExec(program, args, { cwd: widgetPackPath })
      .then((output) => {
        if (output.code !== 0) {
          throw new Error(
            output.stderr || `Process exited with code ${output.code}`
          );
        }
      })
      .catch((err) => {
        logger.error(`Error executing ${program}`);
        logger.error(err);
      });
  };

  return (
    <>
      {menuOpen && (
        <div className="flex h-full items-center gap-1">
          <Button
            variant="ghost"
            className="h-full gap-1 px-2"
            onClick={() => runPowerCommand('shutdown', ['/s', '/t', '60'])}
          >
            <Power className="h-4 w-4 text-danger" />
            關機（1 分鐘）
          </Button>
          <Button
            variant="ghost"
            className="h-full gap-1 px-2"
            onClick={() => runPowerCommand(sleepHelper, [])}
          >
            <Moon className="h-4 w-4" />
            睡眠
          </Button>
          <Button
            variant="ghost"
            className="h-full gap-1 px-2"
            onClick={() => runPowerCommand('shutdown', ['/h'])}
          >
            <Snowflake className="h-4 w-4" />
            休眠
          </Button>
        </div>
      )}
      <Button
        size="icon-sm"
        className="h-full"
        title="電源選單"
        aria-expanded={menuOpen}
        onClick={() => setMenuOpen((open) => !open)}
      >
        <Power strokeWidth={3} className="text-danger" />
      </Button>
    </>
  );
}
