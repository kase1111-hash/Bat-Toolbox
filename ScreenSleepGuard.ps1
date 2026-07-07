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
    const int VK_MENU = 0x12;    // Alt key (either)
    const int VK_TAB = 0x09;     // Tab key
    const int VK_SHIFT = 0x10;   // Shift key (either)
    const int VK_CONTROL = 0x11; // Ctrl key (either)
    const int VK_LSHIFT = 0xA0;
    const int VK_RSHIFT = 0xA1;
    const int VK_LCONTROL = 0xA2;
    const int VK_RCONTROL = 0xA3;
    const int VK_LMENU = 0xA4;   // Left Alt
    const int VK_RMENU = 0xA5;   // Right Alt

    // Keys that must NOT count as "unauthorized input" on their own. Alt/Tab
    // are the safe combo; the L/R modifier variants are set alongside the
    // generic VK_MENU/VK_SHIFT/VK_CONTROL when a modifier is held, so they must
    // be skipped too or a legitimate Alt+Tab trips the intruder branch.
    static bool IsModifierKey(int key) {
        return key == VK_TAB || key == VK_SHIFT || key == VK_CONTROL || key == VK_MENU
            || key == VK_LSHIFT || key == VK_RSHIFT || key == VK_LCONTROL || key == VK_RCONTROL
            || key == VK_LMENU || key == VK_RMENU;
    }

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

        // Drain the "pressed since last call" (LSB) state for every key so the
        // keystrokes used to launch this script (e.g. Enter) are not mistaken
        // for intruder input on the first sweep.
        for (int key = 8; key < 255; key++) {
            GetAsyncKeyState(key);
        }

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

            // Check for any other key that is physically down right now. Use the
            // high bit (0x8000 = currently pressed) only - not 0x0001, which
            // reports keys pressed at any point since the previous poll.
            for (int key = 8; key < 255; key++) {
                // Skip modifier keys (Alt/Tab/Shift/Ctrl and their L/R variants)
                // so holding a modifier alone - or the Alt of Alt+Tab landing a
                // tick before Tab - does not trigger a logout.
                if (IsModifierKey(key)) continue;

                if ((GetAsyncKeyState(key) & 0x8000) != 0) {
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
