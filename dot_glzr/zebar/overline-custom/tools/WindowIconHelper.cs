using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

internal static class WindowIconHelper
{
    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length == 1 && args[0] == "--check")
        {
            Console.WriteLine("WindowIconHelper ready.");
            return 0;
        }

        if (args.Length != 1 || string.IsNullOrWhiteSpace(args[0]))
        {
            Console.Error.WriteLine("Expected exactly one process name.");
            return 2;
        }

        try
        {
            var processName = Path.GetFileNameWithoutExtension(args[0].Trim());
            foreach (var process in Process.GetProcessesByName(processName))
            {
                using (process)
                {
                    string executablePath;
                    try
                    {
                        executablePath = process.MainModule.FileName;
                    }
                    catch (InvalidOperationException)
                    {
                        continue;
                    }
                    catch (System.ComponentModel.Win32Exception)
                    {
                        continue;
                    }

                    using (var icon = Icon.ExtractAssociatedIcon(executablePath))
                    {
                        if (icon == null) continue;
                        using (var source = icon.ToBitmap())
                        using (var bitmap = new Bitmap(32, 32, PixelFormat.Format32bppArgb))
                        using (var graphics = Graphics.FromImage(bitmap))
                        using (var stream = new MemoryStream())
                        {
                            graphics.Clear(Color.Transparent);
                            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                            graphics.DrawImage(source, new Rectangle(0, 0, bitmap.Width, bitmap.Height));
                            bitmap.Save(stream, ImageFormat.Png);
                            Console.Write(Convert.ToBase64String(stream.ToArray()));
                            return 0;
                        }
                    }
                }
            }

            Console.Error.WriteLine("No accessible process icon found.");
            return 1;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine(error.Message);
            return 1;
        }
    }
}
