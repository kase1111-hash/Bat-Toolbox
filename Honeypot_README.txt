================================================================================
 Honeypot.bat - Instructions
================================================================================

DESCRIPTION
-----------
A decoy/trap file that logs information about anyone who opens it, displays
warning messages, and then shuts down the computer. Designed to catch
unauthorized access to sensitive folders.

WARNING: This script WILL shut down the computer when run!


HOW TO USE
----------
1. Rename the file to something enticing (e.g., "Passwords.bat",
   "Bank_Account.bat", "Private_Photos.bat")
2. Place it in a folder you want to protect
3. When someone opens it:
   - Their information is logged to IntruderLog.txt
   - Warning messages and sounds play
   - After the on-screen countdown, a Windows shutdown is scheduled with
     a 30-second timer, and the computer then shuts down

The log file (IntruderLog.txt) records:
  - Date and time of access
  - Username and computer name
  - Domain information
  - Network/IP details
  - Running processes


BEFORE YOU RUN
--------------
- Understand that running this WILL shut down your computer
- Save all work before testing (the shutdown forces apps to close, so
  unsaved work is lost)
- The shutdown can be cancelled - see below


HOW TO CANCEL THE SHUTDOWN
--------------------------
If you accidentally trigger the honeypot, there are two cancel windows:

During the on-screen warnings and countdown (roughly 20-30 seconds, until
the voice says "Goodbye."):
  - Nothing has been scheduled yet, so "shutdown /a" does nothing here.
  - Close the console window, or press Ctrl+C and answer Y.

After "Goodbye." (the script ends and Windows shows a shutdown notice):
  1. Press Win+R quickly
  2. Type: shutdown /a
  3. Press Enter

Or open Command Prompt and run: shutdown /a

The script runs "shutdown /s /t 30 /f", so you have about 30 seconds
after "Goodbye." to cancel before the computer shuts down.


HOW TO RESTORE / UNDO
---------------------
This script does not make permanent changes to your system.

After shutdown:
  1. Turn your computer back on normally
  2. Check IntruderLog.txt to see what was recorded
  3. Delete IntruderLog.txt if desired

To remove the honeypot:
  1. Delete the renamed .bat file
  2. Delete IntruderLog.txt


CUSTOMIZATION
-------------
You can edit the script to:
  - Change the countdown time (the on-screen countdown loop, and the
    "/t 30" shutdown timer on the last line; keep /t above 0 or
    "shutdown /a" can no longer cancel it)
  - Modify warning messages
  - Change or disable the shutdown
  - Add email notifications (requires additional setup)


TIPS
----
- Test it once so you know how it works
- Place in folders like "Financial" or "Personal"
- The dramatic warnings are intentional to scare intruders
- Check IntruderLog.txt periodically to see if anyone triggered it
- Consider using Windows file auditing for more serious security
