================================================================================
 install-tripwire-watcher.bat - Instructions
================================================================================

DESCRIPTION
-----------
Installs (or updates) the user-session "tripwire watcher" - a background
PowerShell process that tails the sovereign-shell tripwire log and raises a
Windows toast notification when a new event appears. It registers a branded
AppUserModelID so the toasts are labeled "Sovereign Shell Tripwire", and it
creates a logon-triggered scheduled task so the watcher starts automatically
each time you sign in.

Companion PowerShell script (required, must sit next to the .bat):
  tripwire-watcher.ps1


HOW TO USE
----------
1. Keep install-tripwire-watcher.bat and tripwire-watcher.ps1 in the same
   folder.
2. Right-click the .bat and choose "Run as administrator" (REQUIRED).
3. The installer:
     [0/4] stops any running watcher (v1 or v2)
     [1/4] copies the .ps1 to C:\ProgramData\sovereign-shell\
     [2/4] registers the AppUserModelID for branded toasts
     [3/4] creates a logon-triggered scheduled task (runs as the current user)
     [4/4] starts the watcher immediately
4. Within a few seconds you should see up to 3 "Tripwire (replay)" toasts -
   these are your most recent log events, confirming the pipeline is live.


WHAT IT DOES
------------
- Task name:  "Sovereign Shell Tripwire Watcher"
- Trigger:    at logon of the current user
- Settings:   starts on battery, no execution time limit, restart x3 on
              failure at 1-minute intervals
- AUMID:      SovereignShell.Tripwire (for branded toast titles)
- Install dir:C:\ProgramData\sovereign-shell\
- Requires PowerShell 5.1 (built into Windows 10/11).

The v2 watcher deduplicates by fingerprint: it stays silent for known,
repeated events and only toasts for NEW, returned, or daily-summary events.


BEFORE YOU RUN
--------------
- This is a per-user notifier. It shows toasts only for the user who is
  signed in. Install it under each account that should receive alerts.
- It only has something to report if a tripwire log is being written. The
  SYSTEM-level process logger (install-process-history-logger.bat) is the
  usual data source; install that first if you want meaningful events.


STATE FILES
-----------
  Watcher diagnostics:  %LOCALAPPDATA%\sovereign-shell\watcher.log
  Cursor (read offset): %LOCALAPPDATA%\sovereign-shell\tripwire.log.cursor
  Fingerprint store:    %LOCALAPPDATA%\sovereign-shell\fingerprints.json

To reset dedup state (force every event to look new again):
  del "%LOCALAPPDATA%\sovereign-shell\fingerprints.json"
  del "%LOCALAPPDATA%\sovereign-shell\tripwire.log.cursor"


UNINSTALL
---------
Run as Administrator:
  schtasks /Delete /TN "Sovereign Shell Tripwire Watcher" /F

Kill any lingering watcher process:
  powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter 'Name=''powershell.exe''' | Where-Object { $_.CommandLine -match 'tripwire-watcher\.ps1' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"

Optionally remove the AUMID and the copied .ps1:
  reg delete "HKCU\Software\Classes\AppUserModelId\SovereignShell.Tripwire" /f
  del "C:\ProgramData\sovereign-shell\tripwire-watcher.ps1"


VERIFICATION
------------
- On install you should see up to 3 "Tripwire (replay)" toasts.
- Confirm the task exists:
  schtasks /Query /TN "Sovereign Shell Tripwire Watcher" /FO LIST


TIPS
----
- Idempotent - safe to re-run to update the .ps1 or repair the task.
- This is the user-session notifier. The SYSTEM/boot process logger is a
  separate component - see install-process-history-logger.bat.
