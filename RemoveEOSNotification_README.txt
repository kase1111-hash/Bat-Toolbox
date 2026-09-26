================================================================================
 RemoveEOSNotification.bat - Instructions
================================================================================

DESCRIPTION
-----------
Removes the Windows 10 "End of Support" notification that appears in the
system tray nagging you to upgrade to Windows 11.


HOW TO USE
----------
1. Right-click RemoveEOSNotification.bat
2. Select "Run as administrator" (REQUIRED)
3. Wait for completion
4. The EOS notification should stop appearing


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before EOS Removal"
5. Click Create and wait for completion


WHAT THE SCRIPT DOES
--------------------
1. Terminates any running EOSNotify processes
2. Sets registry keys to disable OS upgrade prompts
3. Disables EOSNotify scheduled tasks
4. Renames EOSNotify.exe to prevent future execution

EOSNotify (the process, the \Microsoft\Windows\Setup\EOSNotify and
EOSNotify2 tasks and System32\EOSNotify.exe) is the older end-of-support
notifier and is often absent on current Windows 10 builds. If none of these
components exist, the script says so with an [INFO] message instead of
reporting success: only the upgrade-offer policies were applied, and the
end-of-support reminder may keep appearing.


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Easiest)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your "Before EOS Removal" restore point
  3. Follow the wizard to restore

Option 2: Manual Reversal
  1. Open Command Prompt as Administrator

  2. Re-enable the registry settings:
     reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableOSUpgrade" /f
     reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade" /v "AllowOSUpgrade" /f

  3. Rename EOSNotify.exe back (if it was renamed):
     Navigate to C:\Windows\System32
     Find EOSNotify.exe.bak and rename it to EOSNotify.exe

  4. Re-enable scheduled tasks:
     Open Task Scheduler
     Navigate to Microsoft\Windows\Setup
     Enable any disabled EOSNotify tasks

Option 3: Windows Update
  Running Windows Update may restore the notification system.
  If you want the notifications back, check for updates.


NOTES
-----
- This only removes the notification, not Windows 10's actual end of support
- Windows 10 support ends October 14, 2025
- After that date, you won't receive security updates
- Consider upgrading to Windows 11 if your hardware supports it
- If you want to stay on Windows 10, consider extended security updates (ESU)


TIPS
----
- The notification may return after major Windows updates
- Run the script again if the notification reappears
- The script sets OS-upgrade blocking values (DisableOSUpgrade=1,
  AllowOSUpgrade=0), which can suppress feature-upgrade offers in Windows
  Update; quality/security updates are unaffected. Undo them (Option 2) if
  you later want the upgrade offer back.
- You can still manually upgrade to Windows 11 anytime
