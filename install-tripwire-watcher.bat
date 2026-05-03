@echo off
setlocal enabledelayedexpansion

:: ===================================================================
:: install-tripwire-watcher.bat   (idempotent - safe to re-run)
::
:: Installs (or updates) the user-session toast notifier for
:: sovereign-shell tripwire. Each run cleanly stops any existing
:: watcher before deploying the .ps1 next to this bat.
::
:: Steps:
::   0. Stop any running watcher process (v1 or v2)
::   1. Copy tripwire-watcher.ps1 to C:\ProgramData\sovereign-shell\
::   2. Register AppUserModelID for branded toasts
::   3. Create logon-triggered scheduled task
::   4. Start the new watcher (replay-of-3 toasts confirm it's live)
::
:: Run as Administrator. PowerShell 5.1 (built-in) required.
:: ===================================================================

set "SCRIPT_DIR=%~dp0"
set "PS1_SOURCE=%SCRIPT_DIR%tripwire-watcher.ps1"
set "INSTALL_DIR=C:\ProgramData\sovereign-shell"
set "PS1_TARGET=%INSTALL_DIR%\tripwire-watcher.ps1"
set "AUMID=SovereignShell.Tripwire"
set "TASK_NAME=Sovereign Shell Tripwire Watcher"

:: --- Admin check ---
net session >nul 2>&1
if errorlevel 1 (
    echo [FATAL] Run this installer as Administrator.
    pause
    exit /b 1
)

:: --- Source check ---
if not exist "%PS1_SOURCE%" (
    echo [FATAL] tripwire-watcher.ps1 not found next to this bat.
    echo         Expected: %PS1_SOURCE%
    pause
    exit /b 1
)

echo.
echo ==========================================================
echo  Installing Sovereign Shell Tripwire Watcher
echo ==========================================================
echo.

:: --- 0. Stop any existing watcher (task instance + detached process) ---
echo [0/4] Stopping any existing watcher ...
schtasks /End "%TASK_NAME%" >nul 2>&1
:: Pipes are inside the quoted argument, so cmd.exe passes them through
:: to PowerShell verbatim - no ^| escaping needed.
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter 'Name=''powershell.exe''' -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'tripwire-watcher\.ps1' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
:: Give the mutex a moment to release.
powershell -NoProfile -Command "Start-Sleep -Milliseconds 800"
echo       OK.
echo.

:: --- 1. Copy .ps1 into install dir ---
echo [1/4] Copying watcher to %INSTALL_DIR% ...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" >nul 2>&1
copy /Y "%PS1_SOURCE%" "%PS1_TARGET%" >nul
if errorlevel 1 (
    echo       FAILED.
    pause
    exit /b 1
)
echo       OK.
echo.

:: --- 2. Register AUMID for branded toasts ---
echo [2/4] Registering AppUserModelID for branded toasts ...
reg add "HKCU\Software\Classes\AppUserModelId\%AUMID%" ^
    /v "DisplayName" /t REG_SZ /d "Sovereign Shell Tripwire" /f >nul
if errorlevel 1 (
    echo       FAILED ^(toasts will still appear, just unbranded^).
) else (
    echo       OK.
)
echo.

:: --- 3. Create the scheduled task ---
echo [3/4] Creating logon-triggered scheduled task ...
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%PS1_TARGET%\"';" ^
  "$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME;" ^
  "$set     = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1);" ^
  "Register-ScheduledTask -TaskName '%TASK_NAME%' -Action $action -Trigger $trigger -Settings $set -Description 'Tails sovereign-shell tripwire log and toasts on new events.' -Force | Out-Null"

if errorlevel 1 (
    echo       FAILED.
    pause
    exit /b 1
)
echo       OK.
echo.

:: --- 4. Start the watcher right now ---
echo [4/4] Starting the watcher ...
powershell -NoProfile -Command ^
  "Start-Process powershell -ArgumentList '-NoProfile','-WindowStyle','Hidden','-ExecutionPolicy','Bypass','-File','%PS1_TARGET%' -WindowStyle Hidden"
echo       OK.
echo.

echo ==========================================================
echo  Install complete.
echo ==========================================================
echo.
echo  Within a few seconds you should see up to 3 toasts marked
echo  "Tripwire (replay)" - those are your last events from the
echo  log, confirming the pipeline is live. After that, the v2
echo  watcher will be silent for known-fingerprint repeats and
echo  will only toast for NEW, returned, or daily-summary events.
echo.
echo  State files:
echo    Watcher diagnostics:  %%LOCALAPPDATA%%\sovereign-shell\watcher.log
echo    Cursor:               %%LOCALAPPDATA%%\sovereign-shell\tripwire.log.cursor
echo    Fingerprint store:    %%LOCALAPPDATA%%\sovereign-shell\fingerprints.json
echo.
echo  To reset dedup state (force everything to look new again):
echo    del "%%LOCALAPPDATA%%\sovereign-shell\fingerprints.json"
echo    del "%%LOCALAPPDATA%%\sovereign-shell\tripwire.log.cursor"
echo.

endlocal
pause
exit /b 0
