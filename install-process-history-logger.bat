@echo off
setlocal enabledelayedexpansion

:: ===================================================================
:: install-process-history-logger.bat   (idempotent - safe to re-run)
::
:: Installs the SYSTEM-context process-creation logger. Different
:: principal and trigger from the watcher: this one runs as SYSTEM,
:: triggered at boot, so it sees every process across every session.
::
:: Steps:
::   0. Stop any existing logger
::   1. Copy process-history-logger.ps1 to C:\ProgramData\sovereign-shell\
::   2. Create boot-triggered SYSTEM scheduled task
::   3. Run the task now (no need to reboot to verify)
::
:: Run as Administrator. PowerShell 5.1 (built-in) required.
::
:: Uninstall:
::   schtasks /Delete /TN "Sovereign Shell Process History Logger" /F
::   (kill matching powershell processes - see step 0 below)
::   del "C:\ProgramData\sovereign-shell\process-history-logger.ps1"
::   del "C:\ProgramData\sovereign-shell\process-history*.log"
::   del "C:\ProgramData\sovereign-shell\process-history-logger.log"
:: ===================================================================

set "SCRIPT_DIR=%~dp0"
set "PS1_SOURCE=%SCRIPT_DIR%process-history-logger.ps1"
set "INSTALL_DIR=C:\ProgramData\sovereign-shell"
set "PS1_TARGET=%INSTALL_DIR%\process-history-logger.ps1"
set "TASK_NAME=Sovereign Shell Process History Logger"

:: --- Admin check ---
net session >nul 2>&1
if errorlevel 1 (
    echo [FATAL] Run this installer as Administrator.
    pause
    exit /b 1
)

if not exist "%PS1_SOURCE%" (
    echo [FATAL] process-history-logger.ps1 not found next to this bat.
    echo         Expected: %PS1_SOURCE%
    pause
    exit /b 1
)

echo.
echo ==========================================================
echo  Installing Sovereign Shell Process History Logger
echo ==========================================================
echo.

:: --- 0. Stop any existing logger ---
echo [0/3] Stopping any existing logger ...
schtasks /End "%TASK_NAME%" >nul 2>&1
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter 'Name=''powershell.exe''' -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'process-history-logger\.ps1' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
powershell -NoProfile -Command "Start-Sleep -Milliseconds 800"
echo       OK.
echo.

:: --- 1. Copy ps1 ---
echo [1/3] Copying logger to %INSTALL_DIR% ...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" >nul 2>&1
copy /Y "%PS1_SOURCE%" "%PS1_TARGET%" >nul
if errorlevel 1 (
    echo       FAILED.
    pause
    exit /b 1
)
echo       OK.
echo.

:: --- 2. Create boot-triggered SYSTEM scheduled task ---
echo [2/3] Creating boot-triggered SYSTEM scheduled task ...
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%PS1_TARGET%\"';" ^
  "$trigger   = New-ScheduledTaskTrigger -AtStartup;" ^
  "$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest;" ^
  "$set       = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1);" ^
  "Register-ScheduledTask -TaskName '%TASK_NAME%' -Action $action -Trigger $trigger -Principal $principal -Settings $set -Description 'Logs process creation events for sovereign-shell tripwire forensics.' -Force | Out-Null"

if errorlevel 1 (
    echo       FAILED.
    pause
    exit /b 1
)
echo       OK.
echo.

:: --- 3. Run it now ---
echo [3/3] Starting the logger ...
schtasks /Run /TN "%TASK_NAME%" >nul
if errorlevel 1 (
    echo       FAILED to run task ^(it will start at next boot^).
) else (
    echo       OK.
)
echo.

echo ==========================================================
echo  Install complete.
echo ==========================================================
echo.
echo  The logger is running as SYSTEM. Within a few seconds you
echo  should see %INSTALL_DIR%\process-history.log
echo  populated with a snapshot of currently running processes.
echo.
echo  Verify:
echo    type "%INSTALL_DIR%\process-history.log" ^| more
echo.
echo  Diagnostics:
echo    type "%INSTALL_DIR%\process-history-logger.log"
echo.

endlocal
pause
exit /b 0
