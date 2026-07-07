================================================================================
 install-process-history-logger.bat - Instructions
================================================================================

DESCRIPTION
-----------
Installs a SYSTEM-context process-creation logger as a boot-triggered
scheduled task. Because it runs as SYSTEM starting at boot, it observes every
process launched across every user session and records them to a log. This is
the data source that the "sovereign-shell" tripwire/inventory scripts read
from (e.g. disable-bloat-services.bat and inventory-asus-staging.bat show
recent-process context pulled from this log).

Companion PowerShell script (required, must sit next to the .bat):
  process-history-logger.ps1


HOW TO USE
----------
1. Keep install-process-history-logger.bat and process-history-logger.ps1 in
   the same folder.
2. Right-click the .bat and choose "Run as administrator" (REQUIRED).
3. The installer:
     [0/3] stops any existing logger instance
     [1/3] copies the .ps1 to C:\ProgramData\sovereign-shell\
     [2/3] registers a boot-triggered SYSTEM scheduled task
     [3/3] runs the task now so you don't have to reboot to verify
4. Within a few seconds, C:\ProgramData\sovereign-shell\process-history.log
   should start populating.


WHAT IT DOES
------------
- Task name:   "Sovereign Shell Process History Logger"
- Principal:   SYSTEM, RunLevel Highest
- Trigger:     at startup
- Settings:    starts on battery, no execution time limit, restart x3 on
               failure at 1-minute intervals
- Install dir: C:\ProgramData\sovereign-shell\
- Requires PowerShell 5.1 (built into Windows 10/11).


BEFORE YOU RUN
--------------
- This is a monitoring/forensics tool. It writes a continuous log of process
  launches to disk. Understand that the log will grow over time (the .ps1
  handles rotation to process-history.old.log).
- SYSTEM-level scheduled tasks are powerful; only install this on a machine
  you administer.


UNINSTALL
---------
Run as Administrator:

  schtasks /Delete /TN "Sovereign Shell Process History Logger" /F

  Kill any lingering logger process:
  powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter 'Name=''powershell.exe''' | Where-Object { $_.CommandLine -match 'process-history-logger\.ps1' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"

  Remove files:
  del "C:\ProgramData\sovereign-shell\process-history-logger.ps1"
  del "C:\ProgramData\sovereign-shell\process-history*.log"
  del "C:\ProgramData\sovereign-shell\process-history-logger.log"


VERIFICATION
------------
  type "C:\ProgramData\sovereign-shell\process-history.log" | more
  (should show a snapshot of currently running processes, then live entries)

  Diagnostics / errors:
  type "C:\ProgramData\sovereign-shell\process-history-logger.log"


TIPS
----
- Idempotent - safe to re-run to update the .ps1 or repair the task.
- This is the SYSTEM/boot logger. The user-session toast notifier is a
  separate component - see install-tripwire-watcher.bat.
- Several other scripts in this toolbox display "recent processes" context by
  reading this log; if that context is empty, this logger is probably not
  installed yet.
