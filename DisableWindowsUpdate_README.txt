================================================================================
 DisableWindowsUpdate.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables Windows Update and silences all update-related notifications, warnings,
and restart prompts. Includes a full restore option to re-enable everything.


HOW TO USE
----------
1. Right-click DisableWindowsUpdate.bat
2. Select "Run as administrator" (REQUIRED)
3. Choose [1] Disable or [2] Restore from the menu
4. Confirm when prompted (Y/N)
5. Restart when prompted (recommended)


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Disable Windows Update"
5. Click Create and wait for completion


WHAT GETS DISABLED
------------------
Services:
  - Windows Update (wuauserv)
  - Windows Update Medic (WaaSMedicSvc) - prevents auto re-enable
  - Update Orchestrator (UsoSvc)
  - Background Intelligent Transfer Service (BITS)
  - Delivery Optimization (DoSvc)

Scheduled Tasks:
  - All WindowsUpdate tasks (Scheduled Start, sih, sihboot)
  - All UpdateOrchestrator tasks (Schedule Scan, Reboot, UpdateAssistant, etc.)
  - WaaSMedic remediation task

Notifications Silenced:
  - Update available toast notifications
  - Restart required warnings
  - "Finish setting up your device" nag
  - Action Center update warnings
  - Settings page update badges
  - System tray update balloons
  - End of Service notifications
  - Active hours notifications

Registry Policies:
  - Automatic updates set to "Never check"
  - Automatic driver delivery disabled
  - Feature and quality updates deferred by 365 days (fallback)
  - OS upgrade prompts disabled
  - Recommended updates disabled


HOW TO RESTORE / UNDO
---------------------
Option 1: Run the Script Again (Recommended)
  1. Right-click DisableWindowsUpdate.bat
  2. Select "Run as administrator"
  3. Choose option [2] Restore Windows Update
  4. Confirm and restart

Option 2: System Restore
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your "Before Disable Windows Update" restore point
  3. Follow the wizard to restore

Option 3: Manual Re-enable via Services
  1. Press Win+R, type "services.msc", press Enter
  2. Find "Windows Update" and double-click
  3. Set Startup type to "Manual"
  4. Click "Start" then "OK"
  5. Repeat for "Update Orchestrator Service" and "Background Intelligent
     Transfer Service"


SECURITY WARNING
----------------
With Windows Update disabled, your system will NOT receive:
  - Security patches for critical vulnerabilities
  - Firmware and driver updates
  - .NET Framework updates
  - Windows Defender definition updates (Defender uses its own update channel,
    but some updates come through Windows Update)

Consider periodically re-enabling updates to install critical security patches,
then disabling again if desired.


WHY DISABLE WINDOWS UPDATE?
----------------------------
Common reasons:
  - Prevent forced restarts during work or gaming
  - Avoid driver updates that break hardware compatibility
  - Stop feature updates that change UI or remove features
  - Maintain a stable known-working system configuration
  - Prevent bandwidth usage on metered connections


NOTES
-----
- Windows may occasionally still show update-related UI in Settings, but it
  will not actually download or install anything
- Windows Update Medic (WaaSMedicSvc) is specifically disabled to prevent
  Windows from re-enabling the update service on its own
- Service Start values are set to 4 (Disabled) via registry to survive
  attempts by the OS to re-enable them
- Some Windows builds may add new update tasks not covered by this script;
  re-download the latest version if updates resume unexpectedly
- Microsoft Store app updates are separate from Windows Update and are
  not affected by this script


TIPS
----
- If you only want to pause updates temporarily, use Settings > Windows Update
  > Pause updates instead of this script
- For metered connection workaround: Settings > Network > Properties >
  Set as metered connection
- Windows Defender definitions can be updated manually:
  Open Windows Security > Virus & threat protection > Check for updates
- Consider running this script after major Windows reinstalls to prevent
  unwanted updates from being installed during initial setup
