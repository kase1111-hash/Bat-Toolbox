@echo off
setlocal enabledelayedexpansion
title Disable Windows Update
color 0B

:: ============================================================================
:: Disable Windows Update
:: ============================================================================
:: Disables Windows Update, its related services, scheduled tasks, and
:: silences all update notifications and warnings.
:: Includes a restore option to re-enable everything.
:: ============================================================================

echo ============================================================================
echo  Disable Windows Update
echo ============================================================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [INFO] Administrator privileges confirmed.
echo.

:: Setup color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "RESET=%ESC%[0m"

:MENU
cls
echo ============================================================================
echo  Disable Windows Update - Main Menu
echo ============================================================================
echo.
echo  %YELLOW%WARNING: Disabling Windows Update stops security patches and feature
echo  updates. Only do this if you understand the security implications.%RESET%
echo.
echo  [1] Disable Windows Update (Full)
echo  [2] Restore Windows Update (Undo All Changes)
echo  [0] Exit
echo.
echo ============================================================================
set /p "choice=Select an option [0-2]: "

if "%choice%"=="1" goto DISABLE
if "%choice%"=="2" goto RESTORE
if "%choice%"=="0" goto EXIT
goto MENU

:: ============================================================================
:: DISABLE WINDOWS UPDATE
:: ============================================================================
:DISABLE
cls
echo ============================================================================
echo  Disable Windows Update
echo ============================================================================
echo.
echo This will:
echo  - Stop and disable Windows Update services
echo  - Disable update-related scheduled tasks
echo  - Block update notifications and restart warnings
echo  - Disable automatic driver delivery via Windows Update
echo  - Prevent the Update Orchestrator from restarting services
echo.
echo %YELLOW%You will no longer receive security updates until you reverse this.%RESET%
echo.
set /p "confirm=Continue? [Y/N]: "
if /i not "%confirm%"=="Y" goto MENU

echo.
echo ============================================================================
echo  Phase 1: Stopping and Disabling Services
echo ============================================================================
echo.

:: --- Windows Update Service (wuauserv) ---
echo   - Stopping Windows Update service...
sc stop wuauserv >nul 2>&1
echo   - Disabling Windows Update service...
sc config wuauserv start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo     %GREEN%[OK] Windows Update service disabled%RESET%
) else (
    echo     %RED%[WARN] Could not disable Windows Update service%RESET%
)

:: --- Windows Update Medic Service (WaaSMedicSvc) ---
:: This service re-enables Windows Update if it detects it was disabled.
:: It's protected, so we use the registry directly.
echo   - Disabling Windows Update Medic service...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo     %GREEN%[OK] Windows Update Medic service disabled%RESET%
) else (
    echo     %RED%[WARN] Could not disable Windows Update Medic service%RESET%
)
sc stop WaaSMedicSvc >nul 2>&1

:: --- Update Orchestrator Service (UsoSvc) ---
echo   - Stopping Update Orchestrator service...
sc stop UsoSvc >nul 2>&1
echo   - Disabling Update Orchestrator service...
sc config UsoSvc start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo     %GREEN%[OK] Update Orchestrator service disabled%RESET%
) else (
    echo     %RED%[WARN] Could not disable Update Orchestrator service%RESET%
)

:: --- Windows Installer (leave enabled but stop for now) ---
:: Not disabled - other software needs it. Just stopping active installs.

:: --- Background Intelligent Transfer Service (BITS) ---
echo   - Stopping BITS service...
sc stop BITS >nul 2>&1
echo   - Disabling BITS service...
sc config BITS start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo     %GREEN%[OK] BITS service disabled%RESET%
) else (
    echo     %RED%[WARN] Could not disable BITS service%RESET%
)

:: --- Delivery Optimization (DoSvc) ---
echo   - Stopping Delivery Optimization service...
sc stop DoSvc >nul 2>&1
echo   - Disabling Delivery Optimization service...
sc config DoSvc start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo     %GREEN%[OK] Delivery Optimization service disabled%RESET%
) else (
    echo     %RED%[WARN] Could not disable Delivery Optimization service%RESET%
)

echo.
echo ============================================================================
echo  Phase 2: Disabling Scheduled Tasks
echo ============================================================================
echo.

echo   - Disabling Windows Update scheduled tasks...

for %%T in (
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
    "\Microsoft\Windows\WindowsUpdate\sih"
    "\Microsoft\Windows\WindowsUpdate\sihboot"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Work"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work"
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
    "\Microsoft\Windows\UpdateOrchestrator\Reboot_AC"
    "\Microsoft\Windows\UpdateOrchestrator\Reboot_Battery"
    "\Microsoft\Windows\UpdateOrchestrator\Report policies"
    "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask"
    "\Microsoft\Windows\UpdateOrchestrator\UUS Failover Task"
    "\Microsoft\Windows\WaaSMedic\PerformRemediation"
) do (
    schtasks /change /tn "%%~T" /disable >nul 2>&1
    if not errorlevel 1 (
        echo     %GREEN%[OK] Disabled: %%~nT%RESET%
    ) else (
        echo     %YELLOW%[SKIP] Not found or already disabled: %%~nT%RESET%
    )
)

echo.
echo ============================================================================
echo  Phase 3: Registry - Block Updates and Notifications
echo ============================================================================
echo.

:: --- Disable automatic updates via Group Policy registry keys ---
echo   - Setting Windows Update to "Never check for updates"...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /t REG_DWORD /d 1 /f >nul 2>&1
echo     %GREEN%[OK] Automatic updates disabled via policy%RESET%

:: --- Disable update restart notifications ---
echo   - Disabling update restart notifications...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetAutoRestartNotificationDisable" /t REG_DWORD /d 1 /f >nul 2>&1
echo     %GREEN%[OK] Restart notifications disabled%RESET%

:: --- Disable "Restart required" warnings ---
echo   - Disabling restart-required warnings...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d 1 /f >nul 2>&1
echo     %GREEN%[OK] Auto-restart with logged-on users disabled%RESET%

:: --- Disable Windows Update toast notifications ---
echo   - Disabling Windows Update toast notifications...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetUpdateNotificationLevel" /t REG_DWORD /d 0 /f >nul 2>&1
echo     %GREEN%[OK] Update notification level set to silent%RESET%

:: --- Disable "Get the latest updates" nag in Settings ---
echo   - Disabling update nag in Settings...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdates" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferFeatureUpdatesPeriodInDays" /t REG_DWORD /d 365 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdates" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DeferQualityUpdatesPeriodInDays" /t REG_DWORD /d 365 /f >nul 2>&1
echo     %GREEN%[OK] Updates deferred by maximum period%RESET%

:: --- Disable driver updates via Windows Update ---
echo   - Disabling automatic driver delivery...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f >nul 2>&1
echo     %GREEN%[OK] Driver delivery via Windows Update disabled%RESET%

:: --- Disable "Finish setting up your device" nag ---
echo   - Disabling "Finish setting up your device" nag...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo     %GREEN%[OK] Setup nag disabled%RESET%

:: --- Disable "Recommended" updates ---
echo   - Disabling recommended updates...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "IncludeRecommendedUpdates" /t REG_DWORD /d 0 /f >nul 2>&1
echo     %GREEN%[OK] Recommended updates disabled%RESET%

:: --- Disable Windows Update active hours notification ---
echo   - Disabling active hours notification...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetActiveHours" /t REG_DWORD /d 0 /f >nul 2>&1
echo     %GREEN%[OK] Active hours notification disabled%RESET%

:: --- Silence the "Update available" system tray balloon ---
echo   - Silencing system tray update balloons...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetUpdateNotificationLevel" /t REG_DWORD /d 0 /f >nul 2>&1
echo     %GREEN%[OK] System tray balloons silenced%RESET%

echo.
echo ============================================================================
echo  Phase 4: Block Update Orchestrator from Re-enabling Services
echo ============================================================================
echo.

:: The Update Orchestrator can re-enable wuauserv. Remove its permissions.
echo   - Revoking Update Orchestrator restart permissions...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
echo     %GREEN%[OK] Windows Update service locked to disabled (Start=4)%RESET%

:: Prevent BITS from being restarted by other services
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BITS" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
echo     %GREEN%[OK] BITS service locked to disabled (Start=4)%RESET%

:: Prevent UsoSvc from being restarted
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1
echo     %GREEN%[OK] Update Orchestrator locked to disabled (Start=4)%RESET%

echo.
echo ============================================================================
echo  Phase 5: Silence Remaining Notifications
echo ============================================================================
echo.

:: --- Disable "Your device is missing important updates" in Settings ---
echo   - Disabling update status warnings in Settings...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableOSUpgrade" /t REG_DWORD /d 1 /f >nul 2>&1
echo     %GREEN%[OK] OS upgrade prompts disabled%RESET%

:: --- Disable "Reboot to finish installing updates" notifications ---
echo   - Disabling pending reboot notifications...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUShutdownOption" /t REG_DWORD /d 1 /f >nul 2>&1
echo     %GREEN%[OK] Update shutdown option hidden%RESET%

:: --- Disable Update Assistant (Windows 10 feature update nagging) ---
echo   - Disabling Windows Update Assistant...
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\UpdateAssistant" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\UpdateAssistantCalendarRun" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\UpdateOrchestrator\UpdateAssistantWakeupRun" /disable >nul 2>&1
echo     %GREEN%[OK] Update Assistant tasks disabled%RESET%

:: --- Disable "Windows Update" entry from showing warnings in Action Center ---
echo   - Disabling update warnings in Action Center...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.WindowsUpdate.MoNotification" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.WindowsUpdate" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo     %GREEN%[OK] Windows Update Action Center notifications disabled%RESET%

:: --- Disable "You're missing important updates" badge in Settings ---
echo   - Disabling update badges in Settings...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo     %GREEN%[OK] Security and Maintenance notifications disabled%RESET%

:: --- Disable End of Service notifications ---
echo   - Disabling End of Service notifications...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWUfBSafeguards" /t REG_DWORD /d 1 /f >nul 2>&1
echo     %GREEN%[OK] End of Service safeguard notifications disabled%RESET%

echo.
echo ============================================================================
echo  Summary
echo ============================================================================
echo.
echo %GREEN%Windows Update has been disabled.%RESET%
echo.
echo What was changed:
echo  - Windows Update, BITS, Update Orchestrator, and Delivery Optimization
echo    services stopped and disabled
echo  - Windows Update Medic service disabled (prevents auto re-enable)
echo  - All update-related scheduled tasks disabled
echo  - Automatic updates blocked via Group Policy registry keys
echo  - All update notifications and restart warnings silenced
echo  - Driver delivery via Windows Update disabled
echo  - Feature and quality updates deferred by 365 days as fallback
echo.
echo %YELLOW%IMPORTANT: You will no longer receive security updates.%RESET%
echo %YELLOW%To reverse these changes, run this script again and choose "Restore".%RESET%
echo.
echo A reboot is recommended.
echo.
set /p "reboot=Would you like to restart your computer now? [Y/N]: "
if /i "%reboot%"=="Y" (
    echo.
    echo Restarting computer in 10 seconds...
    echo Press Ctrl+C to cancel.
    shutdown /r /t 10 /c "Disable Windows Update - Restart"
)
echo.
pause
goto MENU

:: ============================================================================
:: RESTORE WINDOWS UPDATE
:: ============================================================================
:RESTORE
cls
echo ============================================================================
echo  Restore Windows Update
echo ============================================================================
echo.
echo This will re-enable Windows Update and all its services, scheduled tasks,
echo and notifications.
echo.
set /p "confirm=Continue? [Y/N]: "
if /i not "%confirm%"=="Y" goto MENU

echo.
echo ============================================================================
echo  Restoring Services
echo ============================================================================
echo.

:: --- Re-enable Windows Update service ---
echo   - Re-enabling Windows Update service...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v "Start" /t REG_DWORD /d 3 /f >nul 2>&1
sc config wuauserv start= demand >nul 2>&1
sc start wuauserv >nul 2>&1
echo     %GREEN%[OK] Windows Update service re-enabled%RESET%

:: --- Re-enable Windows Update Medic ---
echo   - Re-enabling Windows Update Medic service...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v "Start" /t REG_DWORD /d 3 /f >nul 2>&1
echo     %GREEN%[OK] Windows Update Medic service re-enabled%RESET%

:: --- Re-enable Update Orchestrator ---
echo   - Re-enabling Update Orchestrator service...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc" /v "Start" /t REG_DWORD /d 2 /f >nul 2>&1
sc config UsoSvc start= auto >nul 2>&1
sc start UsoSvc >nul 2>&1
echo     %GREEN%[OK] Update Orchestrator service re-enabled%RESET%

:: --- Re-enable BITS ---
echo   - Re-enabling BITS service...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\BITS" /v "Start" /t REG_DWORD /d 3 /f >nul 2>&1
sc config BITS start= demand >nul 2>&1
echo     %GREEN%[OK] BITS service re-enabled%RESET%

:: --- Re-enable Delivery Optimization ---
echo   - Re-enabling Delivery Optimization service...
sc config DoSvc start= delayed-auto >nul 2>&1
sc start DoSvc >nul 2>&1
echo     %GREEN%[OK] Delivery Optimization service re-enabled%RESET%

echo.
echo ============================================================================
echo  Restoring Scheduled Tasks
echo ============================================================================
echo.

echo   - Re-enabling Windows Update scheduled tasks...

for %%T in (
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
    "\Microsoft\Windows\WindowsUpdate\sih"
    "\Microsoft\Windows\WindowsUpdate\sihboot"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Work"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work"
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
    "\Microsoft\Windows\UpdateOrchestrator\Reboot_AC"
    "\Microsoft\Windows\UpdateOrchestrator\Reboot_Battery"
    "\Microsoft\Windows\UpdateOrchestrator\Report policies"
    "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask"
    "\Microsoft\Windows\UpdateOrchestrator\UUS Failover Task"
    "\Microsoft\Windows\WaaSMedic\PerformRemediation"
    "\Microsoft\Windows\UpdateOrchestrator\UpdateAssistant"
    "\Microsoft\Windows\UpdateOrchestrator\UpdateAssistantCalendarRun"
    "\Microsoft\Windows\UpdateOrchestrator\UpdateAssistantWakeupRun"
) do (
    schtasks /change /tn "%%~T" /enable >nul 2>&1
    if not errorlevel 1 (
        echo     %GREEN%[OK] Enabled: %%~nT%RESET%
    ) else (
        echo     %YELLOW%[SKIP] Not found: %%~nT%RESET%
    )
)

echo.
echo ============================================================================
echo  Restoring Registry Settings
echo ============================================================================
echo.

:: --- Remove Group Policy update blocks ---
echo   - Removing Windows Update policy overrides...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f >nul 2>&1
echo     %GREEN%[OK] Windows Update policies removed%RESET%

:: --- Re-enable driver delivery ---
echo   - Re-enabling automatic driver delivery...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 1 /f >nul 2>&1
echo     %GREEN%[OK] Driver delivery re-enabled%RESET%

:: --- Re-enable setup nag ---
echo   - Re-enabling device setup notifications...
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /f >nul 2>&1
echo     %GREEN%[OK] Device setup notifications re-enabled%RESET%

:: --- Re-enable Action Center notifications ---
echo   - Re-enabling update notifications...
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.WindowsUpdate.MoNotification" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.WindowsUpdate" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /f >nul 2>&1
echo     %GREEN%[OK] Update notifications re-enabled%RESET%

echo.
echo ============================================================================
echo  Restore Complete
echo ============================================================================
echo.
echo %GREEN%Windows Update has been re-enabled.%RESET%
echo.
echo All services, scheduled tasks, and notifications have been restored.
echo Windows will resume checking for and installing updates.
echo.
echo A reboot is recommended.
echo.
set /p "reboot=Would you like to restart your computer now? [Y/N]: "
if /i "%reboot%"=="Y" (
    echo.
    echo Restarting computer in 10 seconds...
    echo Press Ctrl+C to cancel.
    shutdown /r /t 10 /c "Restore Windows Update - Restart"
)
echo.
pause
goto MENU

:: ============================================================================
:: EXIT
:: ============================================================================
:EXIT
echo.
echo Thank you for using Disable Windows Update!
echo.
pause
exit /b 0
