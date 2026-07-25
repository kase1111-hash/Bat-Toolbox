@echo off
:: =============================================================
::  edge-disable.bat
::  Part of the Bat-Toolbox  -  Windows 10
::
::  Disables Microsoft Edge without uninstalling it. Kills running
::  processes, stops and disables the update services, nukes the
::  scheduled tasks, blocks auto-update via policy, kills prelaunch
::  / startup boost / background mode, and (optionally) renames
::  msedge.exe so nothing can accidentally launch it.
::
::  Fully reversible. See "TO REVERSE" notes at the bottom.
:: =============================================================

:: --- Self-elevate to Administrator ---------------------------
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

setlocal enabledelayedexpansion

echo/
echo ============================================================
echo  Edge Disable  -  Bat-Toolbox
echo ============================================================
echo/

:: --- 1. Kill any running Edge processes ----------------------
echo [1/6] Killing running Edge processes...
taskkill /F /IM msedge.exe              >nul 2>&1
taskkill /F /IM MicrosoftEdge.exe       >nul 2>&1
taskkill /F /IM msedgewebview2.exe      >nul 2>&1
taskkill /F /IM MicrosoftEdgeUpdate.exe >nul 2>&1
echo       done.

:: --- 2. Stop and disable Edge update services ----------------
echo [2/6] Stopping and disabling Edge update services...
sc stop   "edgeupdate"  >nul 2>&1
sc stop   "edgeupdatem" >nul 2>&1
sc config "edgeupdate"  start= disabled >nul 2>&1
sc config "edgeupdatem" start= disabled >nul 2>&1
echo       done.

:: --- 3. Disable Edge scheduled tasks -------------------------
echo [3/6] Disabling Edge scheduled tasks...
schtasks /Change /TN "MicrosoftEdgeUpdateTaskMachineCore" /Disable >nul 2>&1
schtasks /Change /TN "MicrosoftEdgeUpdateTaskMachineUA"   /Disable >nul 2>&1
echo       done.

:: --- 4. Block Edge auto-update via policy --------------------
echo [4/6] Setting policy to block Edge auto-updates...
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "UpdateDefault"               /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "InstallDefault"              /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "AutoUpdateCheckPeriodMinutes" /t REG_DWORD /d 0 /f >nul 2>&1
echo       done.

:: --- 5. Kill prelaunch / startup boost / background mode -----
echo [5/6] Killing prelaunch, startup boost, and background mode...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled"   /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "BackgroundModeEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main"         /v "AllowPrelaunch"     /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader" /v "AllowTabPreloading" /t REG_DWORD /d 0 /f >nul 2>&1

:: Strip Edge auto-launch entries from the per-user Run key
for /f "tokens=1" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /i "MicrosoftEdgeAutoLaunch"') do (
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "%%a" /f >nul 2>&1
)
echo       done.

:: --- 6. Optional: rename msedge.exe so nothing can launch it -
echo/
echo [6/6] OPTIONAL: rename msedge.exe to prevent accidental launches?
echo       Most aggressive step. Edge stays on disk, but nothing
echo       can execute it (including system features like Widgets
echo       that try to force-launch via microsoft-edge:// protocol).
echo       Reversible by renaming msedge_disabled.exe back.
echo/
set /p RENAME_CHOICE="       Rename msedge.exe? (y/N): "
if /I "!RENAME_CHOICE!"=="y" (
    set "EDGE_DIR=C:\Program Files (x86)\Microsoft\Edge\Application"
    if exist "!EDGE_DIR!\msedge.exe" (
        :: msedge.exe is locked down - take ownership first
        takeown /F "!EDGE_DIR!\msedge.exe" >nul 2>&1
        icacls "!EDGE_DIR!\msedge.exe" /grant administrators:F >nul 2>&1
        ren "!EDGE_DIR!\msedge.exe" "msedge_disabled.exe" >nul 2>&1
        if exist "!EDGE_DIR!\msedge_disabled.exe" (
            echo       Renamed: msedge.exe  --^>  msedge_disabled.exe
        ) else (
            echo       Rename failed. Edge may still be running, or
            echo       Windows Defender may have re-locked the file.
        )
    ) else (
        echo       msedge.exe not found at expected path - skipping.
    )
) else (
    echo       Skipped rename.
)

echo/
echo ============================================================
echo  Done. Edge is disabled.
echo  Reboot recommended.
echo ============================================================
echo/
echo  TO REVERSE:
echo    sc config edgeupdate   start= demand
echo    sc config edgeupdatem  start= demand
echo    schtasks /Change /TN "MicrosoftEdgeUpdateTaskMachineCore" /Enable
echo    schtasks /Change /TN "MicrosoftEdgeUpdateTaskMachineUA"   /Enable
echo    reg delete "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /f
echo    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge"       /f
echo    (rename msedge_disabled.exe back to msedge.exe if you ran step 6)
echo/

endlocal
pause
