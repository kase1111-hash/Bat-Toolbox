@echo off
setlocal EnableDelayedExpansion

::============================================================
:: muzzle-uso.bat
:: Re-disables UsoSvc (Update Orchestrator) at every boot.
:: Part of Bat-Toolbox.
::
:: Usage:
::   muzzle-uso.bat            install the boot task
::   muzzle-uso.bat /u         remove the boot task
::   muzzle-uso.bat /status    show current state
::============================================================

set "TASKNAME=Muzzle-UsoSvc"
set "SVC=UsoSvc"

:: --- elevation check ----------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo [!] Administrator privileges required.
    echo     Right-click this file and choose "Run as administrator".
    pause
    exit /b 1
)

:: --- arg dispatch -------------------------------------------
if /i "%~1"=="/u"        goto :uninstall
if /i "%~1"=="/uninstall" goto :uninstall
if /i "%~1"=="/remove"   goto :uninstall
if /i "%~1"=="/status"   goto :status
goto :install

::============================================================
:install
echo [*] Installing boot task: %TASKNAME%

:: Stop and disable right now so the muzzle takes effect immediately.
sc stop   %SVC% >nul 2>&1
sc config %SVC% start= disabled >nul 2>&1

:: Create the on-boot task.
::   /SC ONSTART  - run at system startup
::   /RU SYSTEM   - run as LocalSystem (no password, full rights)
::   /RL HIGHEST  - elevated
::   /F           - overwrite if exists
:: The /TR command stops the service and re-disables it. The space
:: after "start=" is required by sc.exe; do not remove it.
schtasks /Create /TN "%TASKNAME%" /SC ONSTART /RU "SYSTEM" /RL HIGHEST /F ^
    /TR "cmd.exe /c sc stop %SVC% & sc config %SVC% start= disabled"

if errorlevel 1 (
    echo [!] Failed to create scheduled task.
    exit /b 1
)

echo.
echo [+] Done.
echo     %SVC% is now disabled and will be re-disabled at every boot.
echo     Remove with: %~nx0 /u
echo     Inspect with: %~nx0 /status
echo.
echo     Note: Windows Update cumulative installs occasionally re-enable
echo     UsoSvc and reset its start type. The boot task corrects that on
echo     the next reboot. If Microsoft also re-enables WaaSMedicSvc
echo     (Windows Update Medic Service), it can revert this. WaaSMedic is
echo     deliberately hardened against sc.exe; tampering requires registry
echo     edits and is a separate exercise.
exit /b 0

::============================================================
:uninstall
echo [*] Removing boot task: %TASKNAME%
schtasks /Delete /TN "%TASKNAME%" /F
if errorlevel 1 (
    echo [!] Task not found or removal failed.
    exit /b 1
)
echo [+] Task removed.
echo     %SVC% service state was NOT changed. To re-enable manually:
echo         sc config %SVC% start= demand
echo         sc start  %SVC%
exit /b 0

::============================================================
:status
echo --- Scheduled task ---
schtasks /Query /TN "%TASKNAME%" /FO LIST 2>nul
if errorlevel 1 echo (no task installed)
echo.
echo --- Service state ---
sc qc     %SVC% | findstr /i "START_TYPE"
sc query  %SVC% | findstr /i "STATE"
exit /b 0
