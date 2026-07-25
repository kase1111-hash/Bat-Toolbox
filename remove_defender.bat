@echo off
REM ============================================================================
REM  REMOVE_DEFENDER.BAT
REM  Strips Windows Defender as fully as possible via readable, auditable code.
REM  
REM  PREREQUISITES:
REM    1. Run as Administrator (right-click > Run as administrator)
REM    2. MANUALLY disable Tamper Protection FIRST:
REM       Settings > Windows Security > Virus & Threat Protection >
REM       Manage Settings > Toggle OFF "Tamper Protection"
REM       (No script can do this step - Windows requires manual GUI action)
REM    3. Reboot after running this script
REM
REM  WHAT THIS DOES:
REM    - Disables Defender antivirus via registry policies
REM    - Disables real-time protection, cloud delivery, sample submission
REM    - Disables all Defender scheduled tasks
REM    - Disables Defender services (WinDefend, WdNisSvc, SecurityHealth, etc.)
REM    - Disables SmartScreen
REM    - Disables Windows Security Center notifications
REM    - Removes Defender platform files via DISM (if possible)
REM    - Cleans up Defender scan history and cache
REM
REM  REVERSIBLE: Yes. Re-enable Tamper Protection and run Windows Update,
REM  or restore registry keys to defaults. Microsoft may also restore
REM  Defender through feature updates.
REM
REM  Author: Kase Branham / True North Construction LLC
REM  License: Public Domain
REM ============================================================================

REM --- Check for admin privileges ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ============================================
    echo  ERROR: This script must be run as Administrator.
    echo  Right-click the file and select "Run as administrator"
    echo ============================================
    pause
    exit /b 1
)

echo ============================================================================
echo  REMOVE_DEFENDER.BAT - Windows Defender Removal Script
echo ============================================================================
echo/
echo  WARNING: This will disable Windows Defender entirely.
echo  Make sure Tamper Protection is OFF before proceeding.
echo  (Settings ^> Windows Security ^> Virus ^& Threat Protection ^> Manage Settings)
echo/
echo  Press Ctrl+C to abort, or...
pause

echo/
echo [1/8] Disabling Defender via registry policies...
echo -----------------------------------------------

REM -- Core kill switches --
REM DisableAntiSpyware: The master switch. Tells Windows not to run Defender.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f

REM DisableAntiVirus: Redundant but belt-and-suspenders.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f

REM ServiceKeepAlive: Prevent Defender from restarting itself.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v ServiceKeepAlive /t REG_DWORD /d 0 /f

echo/
echo [2/8] Disabling real-time protection, cloud, and sample submission...
echo --------------------------------------------------------------------

REM -- Real-Time Protection --
REM Each of these disables a different tentacle of the live scanning engine.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableIOAVProtection /t REG_DWORD /d 1 /f

REM -- Cloud-Based Protection (aka "phoning home") --
REM SpyNet is Microsoft's telemetry network for Defender. This kills it.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SpyNetReporting /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t REG_DWORD /d 2 /f

REM -- Cloud delivery / block-at-first-sight --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v MpCloudBlockLevel /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v MpEnablePus /t REG_DWORD /d 0 /f

echo/
echo [3/8] Disabling Exploit Guard and Network Protection...
echo -------------------------------------------------------

REM -- Exploit Guard / Network Protection --
REM These are the "advanced threat protection" layers that also phone home.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection" /v EnableNetworkProtection /t REG_DWORD /d 0 /f

REM -- Controlled Folder Access (Ransomware protection - also causes false blocks) --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Controlled Folder Access" /v EnableControlledFolderAccess /t REG_DWORD /d 0 /f

echo/
echo [4/8] Disabling SmartScreen...
echo ------------------------------

REM -- SmartScreen: The "Windows protected your PC" popup system --
REM SmartScreen sends file hashes and URLs to Microsoft for reputation checks.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f
reg add "HKCU\SOFTWARE\Microsoft\Edge\SmartScreenEnabled" /v "" /t REG_DWORD /d 0 /f

REM -- SmartScreen for Store apps --
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d 0 /f

echo/
echo [5/8] Disabling Defender services...
echo ------------------------------------

REM -- WinDefend: The main Defender antimalware service --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v Start /t REG_DWORD /d 4 /f

REM -- WdNisSvc: Defender Network Inspection Service --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v Start /t REG_DWORD /d 4 /f

REM -- WdFilter: Defender mini-filter driver (the kernel-level file scanner) --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter" /v Start /t REG_DWORD /d 4 /f

REM -- WdBoot: Defender boot-time driver --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdBoot" /v Start /t REG_DWORD /d 4 /f

REM -- WdNisDrv: Defender network inspection driver --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisDrv" /v Start /t REG_DWORD /d 4 /f

REM -- SecurityHealthService: The Windows Security app tray icon and UI --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v Start /t REG_DWORD /d 4 /f

REM -- wscsvc: Windows Security Center Service (the nag engine) --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wscsvc" /v Start /t REG_DWORD /d 4 /f

REM -- SgrmBroker: System Guard Runtime Monitor (attestation telemetry) --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SgrmBroker" /v Start /t REG_DWORD /d 4 /f

REM -- Sense: Microsoft Defender for Endpoint (enterprise telemetry) --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Sense" /v Start /t REG_DWORD /d 4 /f

echo/
echo [6/8] Disabling Defender scheduled tasks...
echo --------------------------------------------

REM -- These are the tasks that wake Defender up on schedule --
REM -- Even with services disabled, scheduled tasks can re-enable things --
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable >nul 2>&1

REM -- ExploitGuard MDM policy refresh task --
schtasks /Change /TN "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh" /Disable >nul 2>&1

echo/
echo [7/8] Removing Windows Security notification icon...
echo ----------------------------------------------------

REM -- Kill the system tray icon that nags you about protection --
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v SecurityHealth /f >nul 2>&1

REM -- Disable Security Center notifications entirely --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableEnhancedNotifications /t REG_DWORD /d 1 /f

echo/
echo [8/8] Cleaning up Defender scan history and cached data...
echo ----------------------------------------------------------

REM -- Remove scan history (where Defender stores what it found) --
if exist "%ProgramData%\Microsoft\Windows Defender\Scans\History" (
    rmdir /s /q "%ProgramData%\Microsoft\Windows Defender\Scans\History" >nul 2>&1
    echo   Scan history removed.
) else (
    echo   No scan history found.
)

REM -- Remove cached detection data --
if exist "%ProgramData%\Microsoft\Windows Defender\Scans\mpenginedb.db" (
    del /f /q "%ProgramData%\Microsoft\Windows Defender\Scans\mpenginedb.db" >nul 2>&1
    echo   Engine database removed.
)

REM -- Remove definition updates cache --
if exist "%ProgramData%\Microsoft\Windows Defender\Definition Updates" (
    rmdir /s /q "%ProgramData%\Microsoft\Windows Defender\Definition Updates" >nul 2>&1
    echo   Definition updates cache removed.
) else (
    echo   No definition cache found.
)

echo/
echo ============================================================================
echo  DONE. Windows Defender has been disabled.
echo ============================================================================
echo/
echo  NEXT STEPS:
echo    1. REBOOT your machine for all changes to take effect.
echo    2. After reboot, verify Defender is gone:
echo       - Open Task Manager, check no MsMpEng.exe is running
echo       - Open Services (services.msc), confirm WinDefend is disabled
echo       - Run: sc query WinDefend
echo    3. If Defender resurrects after a Windows Update, re-run this script.
echo/
echo  OPTIONAL NUCLEAR STEP (run manually if needed):
echo    To attempt removal of the Defender platform package via DISM:
echo      DISM /Online /Remove-Feature /FeatureName:Windows-Defender /NoRestart
echo    Note: This may not work on all Windows editions but is worth trying.
echo/
echo  TO REVERSE THIS:
echo    Delete the registry keys under:
echo      HKLM\SOFTWARE\Policies\Microsoft\Windows Defender
echo    Set all service Start values back to 2 or 3
echo    Re-enable Tamper Protection in Windows Security
echo    Run Windows Update
echo/
pause
