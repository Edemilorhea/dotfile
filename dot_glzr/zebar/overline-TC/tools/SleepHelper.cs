using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

internal static class SleepHelper
{
    private static readonly string LogPath = Path.Combine(
        AppDomain.CurrentDomain.BaseDirectory,
        "SleepHelper.log");

    private const byte VirtualKeyLeftWindows = 0x5B;
    private const byte VirtualKeyX = 0x58;
    private const byte VirtualKeyU = 0x55;
    private const byte VirtualKeyS = 0x53;
    private const uint KeyEventKeyUp = 0x0002;

    [DllImport("user32.dll")]
    private static extern void keybd_event(
        byte virtualKey,
        byte scanCode,
        uint flags,
        UIntPtr extraInfo);

    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            Log("Started with args: " + string.Join(" ", args));

            if (args.Length == 1 && args[0] == "--check")
            {
                Console.WriteLine("Native power menu automation is configured.");
                return 0;
            }

            var sleepNow = args.Length == 1 && args[0] == "--sleep-now";
            if (!sleepNow)
            {
                Log("Showing the five-second countdown.");
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                using (var countdown = new SleepCountdownForm())
                {
                    countdown.ShowDialog();
                    if (!countdown.Completed)
                    {
                        Log("Sleep cancelled from the countdown window.");
                        return 0;
                    }
                }
            }

            Log("Opening the native Windows power menu.");
            PressChord(VirtualKeyLeftWindows, VirtualKeyX);
            Thread.Sleep(500);
            PressKey(VirtualKeyU);
            Thread.Sleep(500);
            PressKey(VirtualKeyS);
            Log("Sent Win+X, U, S to the native Windows power menu.");
            return 0;
        }
        catch (Exception error)
        {
            Log("Failed: " + error);
            Console.Error.WriteLine(error.Message);
            return 1;
        }
    }

    private static void PressChord(byte modifier, byte key)
    {
        keybd_event(modifier, 0, 0, UIntPtr.Zero);
        keybd_event(key, 0, 0, UIntPtr.Zero);
        keybd_event(key, 0, KeyEventKeyUp, UIntPtr.Zero);
        keybd_event(modifier, 0, KeyEventKeyUp, UIntPtr.Zero);
    }

    private static void PressKey(byte key)
    {
        keybd_event(key, 0, 0, UIntPtr.Zero);
        keybd_event(key, 0, KeyEventKeyUp, UIntPtr.Zero);
    }

    private static void Log(string message)
    {
        File.AppendAllText(
            LogPath,
            string.Format("{0:O} [session {1}] {2}{3}",
                DateTimeOffset.Now,
                Process.GetCurrentProcess().SessionId,
                message,
                Environment.NewLine));
    }

    private sealed class SleepCountdownForm : Form
    {
        private readonly Label messageLabel;
        private readonly System.Windows.Forms.Timer timer;
        private int secondsRemaining = 5;

        public bool Completed { get; private set; }

        public SleepCountdownForm()
        {
            Text = "睡眠倒數";
            ClientSize = new Size(340, 150);
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            TopMost = true;

            messageLabel = new Label
            {
                Dock = DockStyle.Fill,
                Font = new Font("Microsoft JhengHei UI", 16F, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleCenter,
            };

            var cancelButton = new Button
            {
                Dock = DockStyle.Bottom,
                Height = 42,
                Text = "取消",
            };
            cancelButton.Click += delegate { Close(); };

            Controls.Add(messageLabel);
            Controls.Add(cancelButton);

            timer = new System.Windows.Forms.Timer { Interval = 1000 };
            timer.Tick += OnTimerTick;
            Shown += delegate
            {
                UpdateMessage();
                timer.Start();
            };
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                timer.Dispose();
            }

            base.Dispose(disposing);
        }

        private void OnTimerTick(object sender, EventArgs args)
        {
            secondsRemaining--;
            if (secondsRemaining <= 0)
            {
                Completed = true;
                Close();
                return;
            }

            UpdateMessage();
        }

        private void UpdateMessage()
        {
            messageLabel.Text = string.Format(
                "系統將在 {0} 秒後進入睡眠",
                secondsRemaining);
        }
    }
}
