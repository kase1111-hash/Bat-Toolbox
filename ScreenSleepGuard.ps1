Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Threading;

public class ScreenGuard {
    [DllImport("user32.dll")]
    static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);

    [DllImport("user32.dll")]
    static extern short GetAsyncKeyState(int vKey);

    const int HWND_BROADCAST = 0xFFFF;
    const int WM_SYSCOMMAND = 0x0112;
    const int SC_MONITORPOWER = 0xF170;
    const int VK_MENU = 0x12;    // Alt key
    const int VK_TAB = 0x09;     // Tab key
    const int VK_SHIFT = 0x10;   // Shift key
    const int VK_CONTROL = 0x11; // Ctrl key

    public static void Main() {
        Console.WriteLine("Screen Sleep Guard Active");
        Console.WriteLine("==========================");
        Console.WriteLine("");
        Console.WriteLine("Screen will turn off in 3 seconds...");
        Console.WriteLine("Press ALT+TAB to wake safely.");
        Console.WriteLine("Any other input will log you out.");
        Console.WriteLine("");
        Thread.Sleep(3000);

        // Turn off monitor
        SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2);

        // Small delay to let monitor actually turn off
        Thread.Sleep(500);

        // Clear any existing key states
        GetAsyncKeyState(VK_MENU);
        GetAsyncKeyState(VK_TAB);

        // Monitor for input
        bool waiting = true;
        while (waiting) {
            Thread.Sleep(50);

            bool altPressed = (GetAsyncKeyState(VK_MENU) & 0x8000) != 0;
            bool tabPressed = (GetAsyncKeyState(VK_TAB) & 0x8000) != 0;

            // Check for Alt+Tab (the safe combo)
            if (altPressed && tabPressed) {
                Console.WriteLine("Welcome back!");
                waiting = false;
                return; // Exit normally
            }

            // Check for any other key press
            for (int key = 8; key < 255; key++) {
                // Skip Alt and Tab themselves when checking individually
                if (key == VK_MENU || key == VK_TAB) continue;

                if ((GetAsyncKeyState(key) & 0x8001) != 0) {
                    // Some other key was pressed - INTRUDER!
                    Console.WriteLine("Unauthorized input detected! Logging out...");
                    Thread.Sleep(500);
                    System.Diagnostics.Process.Start("shutdown", "/l /f");
                    waiting = false;
                    return;
                }
            }
        }
    }
}
'@ -ReferencedAssemblies System.Windows.Forms

[ScreenGuard]::Main()
