================================================================================
 remove_telemetry.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables Microsoft telemetry, diagnostics, and data-collection behavior as
thoroughly as possible using readable registry, service, scheduled-task, and
hosts-file changes. It sets the telemetry level to the minimum, kills the
DiagTrack pipeline, disables CEIP/AIT/compatibility telemetry, error
reporting, advertising ID, input personalization, location tracking, activity
history, Cortana/web search, feedback prompts, Copilot and Recall, and blocks
60+ known telemetry domains via the hosts file.


HOW TO USE
----------
1. Right-click remove_telemetry.bat and choose "Run as administrator"
   (REQUIRED).
2. It prints a summary and pauses. Press Ctrl+C to abort, or a key to proceed.
3. It runs 12 phases (see below) and finishes by appending a telemetry block
   to your hosts file (with a timestamped backup made first).
4. Reboot afterward.


WHAT IT DOES (the 12 phases)
----------------------------
   [1] Telemetry level -> 0 (minimum) via DataCollection policies
   [2] Disables DiagTrack, dmwappushservice, diagsvc, DPS, WdiServiceHost,
       WdiSystemHost
   [3] Disables Compatibility Telemetry (CompatTelRunner), PCA, Steps Recorder
   [4] Disables CEIP (Windows, IE, Messenger)
   [5] Disables Windows Error Reporting (WerSvc + policies)
   [6] Disables Advertising ID, input personalization, handwriting/typing
       data collection
   [7] Disables location tracking and sensors (lfsvc)
   [8] Disables Activity History / Timeline upload
   [9] Disables Cortana, web search in Start, search highlights, cloud search
  [10] Disables feedback prompts, Wi-Fi Sense, Copilot, and Recall
  [11] Disables ~20 telemetry scheduled tasks (Compatibility Appraiser,
       Device Census, CEIP, DiskDiagnostic, Feedback, Maps, NetTrace, WER)
  [12] Appends 60+ telemetry domains as 0.0.0.0 to the hosts file (idempotent;
       it checks for its own marker and skips if already present, and backs up
       hosts first)


BEFORE YOU RUN
--------------
- A hosts backup is created automatically as:
    %SystemRoot%\System32\drivers\etc\hosts.bak.<YYYYMMDD>
  (the date is derived from your locale's %date% format; if your locale
  formats dates differently the suffix characters may differ, but a backup is
  still written)
- Disabling DPS (Diagnostic Policy Service) can affect some Windows
  troubleshooters and network diagnostics.
- Disabling location (lfsvc) breaks "Find my device" and any app that needs
  your location (maps, weather-by-location).
- Cortana and Start web-search are disabled; local Start search still works.


HOW TO RESTORE / UNDO
---------------------
1. Delete the policy keys the script created, e.g.:
     reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /f
   (and the other HKLM\SOFTWARE\Policies\Microsoft\... keys listed in the
   script's phases)
2. Set the disabled services back to default Start values (most are 2=Auto or
   3=Manual), e.g.:
     reg add "HKLM\SYSTEM\CurrentControlSet\Services\DiagTrack" /v Start /t REG_DWORD /d 2 /f
3. Remove the telemetry block from the hosts file - either edit out the
   section between the "# --- TELEMETRY BLOCK ..." and "# --- END TELEMETRY
   BLOCK ---" markers, or restore the backup:
     copy /Y "%SystemRoot%\System32\drivers\etc\hosts.bak.<date>" "%SystemRoot%\System32\drivers\etc\hosts"
4. Re-enable scheduled tasks via Task Scheduler, then reboot.


VERIFICATION
------------
After reboot:
  sc query DiagTrack                     (STATE: STOPPED, START_TYPE DISABLED)
  Task Manager: no CompatTelRunner.exe running
  netstat -b -n | findstr /i "microsoft" (few/no telemetry connections)


TIPS
----
- Safe to re-run: the hosts block is guarded by a marker so it won't be
  duplicated.
- Telemetry can partially return after a Windows feature update; re-run then.
- Pairs with remove_store.bat and remove_backup.bat for a full debloat/privacy
  pass. This script is the least destructive of the three.
