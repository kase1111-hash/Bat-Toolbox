================================================================================
 ScreenSleepGuard.bat - Instructions
================================================================================

DESCRIPTION
-----------
Turns off your monitor and sets a trap - if someone tries to wake the
computer without knowing the secret key combination, they get logged out
immediately. Useful for stepping away briefly while deterring snoopers.


HOW TO USE
----------
1. Double-click ScreenSleepGuard.bat (no administrator required)
2. Read the on-screen instructions (3 second countdown)
3. The monitor will turn off
4. To safely wake: Press ALT+TAB
5. Any other key will LOG YOU OUT immediately

IMPORTANT: Remember ALT+TAB is the safe wake key!


BEFORE YOU RUN
--------------
- Save all open work (in case you forget the key combination)
- Close any unsaved documents
- Remember: ALT+TAB = safe, any other key = logout

Requirements:
- ScreenSleepGuard.ps1 must be in the same folder as the .bat file


THE SECRET KEY COMBINATION
--------------------------
  *** ALT + TAB ***

Press ALT+TAB together to safely wake the computer and return to your
desktop without being logged out.


HOW TO RESTORE / UNDO
---------------------
This script does not make permanent changes to your system.

If you got logged out:
  1. Log back in normally with your password
  2. Your running programs may have been closed
  3. Unsaved work may be lost

If the monitor won't turn back on:
  1. Move the mouse or press a key (you may get logged out)
  2. Press the power button briefly (not hold) to wake from sleep
  3. Check monitor power and cable connections


WHAT HAPPENS IF YOU PRESS THE WRONG KEY
---------------------------------------
1. You will be logged out immediately
2. You'll see the Windows lock/login screen
3. Log back in with your password
4. Running programs will be closed
5. Unsaved work may be lost

This is the intended behavior - it's designed to protect against
unauthorized access when you step away.


CUSTOMIZATION
-------------
To change the secret key combination, edit ScreenSleepGuard.ps1:
  1. Open ScreenSleepGuard.ps1 in a text editor
  2. Find the key detection logic
  3. Change the key combination check
  4. Save the file

To disable the logout (just turn off monitor):
  1. Edit ScreenSleepGuard.ps1
  2. Remove or comment out the logout command


ALTERNATIVE: WINDOWS LOCK
-------------------------
If you just want to lock your computer without the logout trap:
  - Press Win+L to lock Windows
  - This is the standard, safer method

ScreenSleepGuard is for when you want an active deterrent against
someone trying to access your computer while you're briefly away.


TIPS
----
- Practice once to remember the key combination
- Use Win+L for normal locking (no risk of logout)
- Good for open office environments
- Consider using Windows lock screen with a strong password instead
- The monitor turning off doesn't put the PC to sleep
