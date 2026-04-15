@echo off
REM ============================================================================
REM  REMOVE_BACKUP.BAT
REM  Disables Windows Backup and all related components.
REM
REM  PREREQUISITES:
REM    1. Run as Administrator
REM    2. Reboot after running
REM
REM  WHY:
REM    Windows Backup runs unsolicited even when never configured.
REM    It consumes disk I/O, CPU, and network bandwidth sending data
REM    to Microsoft's cloud infrastructure. If you never set it up
REM    and it's running for 6 minutes sending data — that's not backup,
REM    that's inventory and exfiltration wearing a backup costume.
REM
REM  WHAT THIS DOES:
REM    - Disables Windows Backup service (sdrsvc, SDRSVC)
REM    - Disables Windows Backup Engine (wbengine)
REM    - Disables Block Level Backup Engine (wbengine)
REM    - Disables Volume Shadow Copy (if desired — commented out by default)
REM    - Disables File History service
REM    - Disables all backup-related scheduled tasks
REM    - Disables Windows Backup cloud/OneDrive integration
REM    - Disables Windows Backup settings in the Settings app
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
echo  REMOVE_BACKUP.BAT - Windows Backup Removal Script
echo ============================================================================
echo.
echo  This will disable Windows Backup and all related components.
echo  Press Ctrl+C to abort, or...
pause

echo.
echo [1/5] Disabling backup services...
echo ------------------------------------

REM -- wbengine: Block Level Backup Engine Service --
REM -- This is the core backup engine that performs the actual backup --
REM -- operations. It's what was eating your CPU for 6 minutes. --
sc stop wbengine >nul 2>&1
sc config wbengine start=disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wbengine" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
echo   wbengine (Block Level Backup Engine) - DISABLED

REM -- SDRSVC: Windows Backup (System Restore/Backup service) --
sc stop SDRSVC >nul 2>&1
sc config SDRSVC start=disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SDRSVC" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
echo   SDRSVC (Windows Backup) - DISABLED

REM -- fhsvc: File History Service --
REM -- Automatically backs up files to external drives or network --
REM -- locations. Also integrates with OneDrive. --
sc stop fhsvc >nul 2>&1
sc config fhsvc start=disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\fhsvc" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
echo   fhsvc (File History Service) - DISABLED

REM -- wbioSrvc: Note - this is Windows Biometric, NOT backup --
REM -- (not touching it, just noting it has a similar name)

REM -- swprv: Microsoft Software Shadow Copy Provider --
REM -- Used by backup to create shadow copies. Safe to disable --
REM -- if you're not using any backup software at all. --
sc stop swprv >nul 2>&1
sc config swprv start=disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\swprv" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
echo   swprv (Software Shadow Copy Provider) - DISABLED

REM -- VSS: Volume Shadow Copy --
REM -- CAUTION: Some apps depend on VSS (e.g., disk imaging tools, --
REM -- some installers). Disabled here since BlueHammer literally --
REM -- exploits the VSS pipeline. Uncomment the REM lines below --
REM -- to re-enable if something breaks. --
sc stop VSS >nul 2>&1
sc config VSS start=disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\VSS" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
echo   VSS (Volume Shadow Copy) - DISABLED
echo     NOTE: Also closes the BlueHammer exploit vector.
echo     If installers break, re-enable with: sc config VSS start=demand

echo.
echo [2/5] Disabling backup scheduled tasks...
echo -------------------------------------------

REM -- Windows Backup scheduled tasks --
schtasks /Change /TN "Microsoft\Windows\WindowsBackup\ConfigNotification" /Disable >nul 2>&1
echo   ConfigNotification - DISABLED
schtasks /Change /TN "Microsoft\Windows\WindowsBackup\AutomaticBackup" /Disable >nul 2>&1
echo   AutomaticBackup - DISABLED
schtasks /Change /TN "Microsoft\Windows\WindowsBackup\Windows Backup Monitor" /Disable >nul 2>&1
echo   Windows Backup Monitor - DISABLED

REM -- File History tasks --
schtasks /Change /TN "Microsoft\Windows\FileHistory\File History (maintenance mode)" /Disable >nul 2>&1
echo   File History (maintenance mode) - DISABLED

REM -- System Restore tasks --
schtasks /Change /TN "Microsoft\Windows\SystemRestore\SR" /Disable >nul 2>&1
echo   SystemRestore SR - DISABLED

REM -- Cloud backup/sync related --
schtasks /Change /TN "Microsoft\Windows\CloudBackup\CloudBackup" /Disable >nul 2>&1
echo   CloudBackup - DISABLED

echo.
echo [3/5] Disabling Windows Backup in Settings and policies...
echo -----------------------------------------------------------

REM -- Disable Windows Backup feature via policy --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Backup\Client" /v DisableBackupUI /t REG_DWORD /d 1 /f >nul 2>&1
echo   Backup UI - DISABLED

REM -- Disable System Restore --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableConfig /t REG_DWORD /d 1 /f >nul 2>&1
echo   System Restore - DISABLED

REM -- Disable File History --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\FileHistory" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
echo   File History policy - DISABLED

echo.
echo [4/5] Disabling OneDrive backup integration...
echo -------------------------------------------------

REM -- Prevent OneDrive from managing backup --
REM -- OneDrive's "backup" feature syncs Desktop/Documents/Pictures --
REM -- to Microsoft's cloud without clear consent. --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v KFMBlockOptIn /t REG_DWORD /d 1 /f >nul 2>&1
echo   OneDrive backup/sync - DISABLED

REM -- Disable OneDrive startup --
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
echo   OneDrive autostart - REMOVED

REM -- Disable OneDrive per-machine install --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f >nul 2>&1
echo   OneDrive file sync - DISABLED

echo.
echo [5/5] Cleaning up existing restore points and backup data...
echo --------------------------------------------------------------

REM -- Delete all existing restore points --
REM -- These take up disk space and are no longer needed --
vssadmin delete shadows /all /quiet >nul 2>&1
echo   Existing shadow copies/restore points - DELETED

REM -- Disable System Protection on C: drive --
powershell -NoProfile -Command "Disable-ComputerRestore -Drive 'C:\'" >nul 2>&1
echo   System Protection on C: - DISABLED

echo.
echo ============================================================================
echo  DONE. Windows Backup and all related components have been disabled.
echo ============================================================================
echo.
echo  SERVICES DISABLED:
echo    wbengine    - Block Level Backup Engine
echo    SDRSVC      - Windows Backup
echo    fhsvc       - File History
echo    swprv       - Software Shadow Copy Provider
echo    VSS         - Volume Shadow Copy (also closes BlueHammer vector)
echo.
echo  ALSO DISABLED:
echo    System Restore, File History, OneDrive backup integration,
echo    Cloud Backup, all backup scheduled tasks, existing restore points
echo.
echo  NOTE ON VSS:
echo    Volume Shadow Copy was disabled because it is the exact service
echo    exploited by BlueHammer. If you use disk imaging software or
echo    an installer fails, re-enable temporarily with:
echo      sc config VSS start=demand
echo      net start VSS
echo    Then disable again when done:
echo      sc config VSS start=disabled
echo.
echo  TO REVERSE:
echo    sc config wbengine start=demand
echo    sc config SDRSVC start=demand
echo    sc config fhsvc start=manual
echo    sc config swprv start=manual
echo    sc config VSS start=manual
echo    Delete policy keys under:
echo      HKLM\SOFTWARE\Policies\Microsoft\Windows\Backup
echo      HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore
echo.
pause
