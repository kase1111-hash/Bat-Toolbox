@echo off
setlocal enabledelayedexpansion
title NVIDIA Bloatware Remover
color 0A

:: ============================================================================
:: NVIDIA Bloatware Remover
:: ============================================================================
:: Removes NVIDIA bloatware while keeping the essential graphics driver.
:: This includes: GeForce Experience, Telemetry, NodeJS server, etc.
:: The core graphics driver will remain intact.
:: ============================================================================

echo ============================================================================
echo  NVIDIA Bloatware Remover
echo ============================================================================
echo.
echo This script will remove NVIDIA bloatware while keeping the graphics driver:
echo.
echo  - GeForce Experience (game optimizer/updater)
echo  - NVIDIA Telemetry (data collection)
echo  - NVIDIA Container services
echo  - NVIDIA NodeJS Backend
echo  - NVIDIA Web Helper
echo  - Various NVIDIA scheduled tasks
echo.
echo Your graphics driver will NOT be affected.
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

:: Confirm before proceeding
set /p "confirm=Do you want to remove NVIDIA bloatware? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo.
    echo Operation cancelled by user.
    pause
    exit /b 0
)

echo.
echo ============================================================================
echo  Phase 1: Stopping NVIDIA Processes and Services
echo ============================================================================
echo.

set "success=0"
set "errors=0"

:: Kill NVIDIA processes
echo [1/6] Terminating NVIDIA bloatware processes...

for %%P in (
    "NVDisplay.Container.exe"
    "NVIDIA Web Helper.exe"
    "NVIDIA Share.exe"
    "NVIDIA Notification.exe"
    "nvcontainer.exe"
    "nvsphelper64.exe"
    "nvtray.exe"
    "NvBackend.exe"
    "NvNode.exe"
    "NVIDIA GeForce Experience.exe"
    "nvidia-smi.exe"
) do (
    taskkill /f /im %%P >nul 2>&1
    if not errorlevel 1 (
        echo       - Terminated %%P
    )
)
echo       - Process termination complete
set /a success+=1

:: Stop and disable NVIDIA services
echo.
echo [2/6] Stopping and disabling NVIDIA telemetry/container services...

for %%S in (
    "NvTelemetryContainer"
    "NVDisplay.ContainerLocalSystem"
    "NvContainerLocalSystem"
    "NvContainerNetworkService"
) do (
    sc query %%S >nul 2>&1
    if not errorlevel 1060 (
        sc stop %%S >nul 2>&1
        sc config %%S start= disabled >nul 2>&1
        if not errorlevel 1 (
            echo       - Disabled service: %%S
            set /a success+=1
        ) else (
            echo       - Could not disable: %%S
        )
    )
)

echo.
echo ============================================================================
echo  Phase 2: Uninstalling GeForce Experience
echo ============================================================================
echo.

echo [3/6] Uninstalling GeForce Experience...

:: Try standard uninstall first
set "GFE_UNINSTALL="

:: Check common uninstall locations
for %%U in (
    "%ProgramFiles%\NVIDIA Corporation\NVIDIA GeForce Experience\uninstall.exe"
    "%ProgramFiles(x86)%\NVIDIA Corporation\NVIDIA GeForce Experience\uninstall.exe"
) do (
    if exist "%%U" (
        set "GFE_UNINSTALL=%%U"
    )
)

if defined GFE_UNINSTALL (
    echo       - Found GeForce Experience uninstaller
    echo       - Running uninstaller (this may take a moment)...
    start /wait "" "%GFE_UNINSTALL%" /silent /noreboot 2>nul
    if not errorlevel 1 (
        echo       - GeForce Experience uninstalled
        set /a success+=1
    ) else (
        echo       - Uninstaller returned an error (may already be removed)
    )
) else (
    echo       - GeForce Experience uninstaller not found (may not be installed)
)

:: Also try using WMIC
wmic product where "name like '%%GeForce Experience%%'" call uninstall /nointeractive >nul 2>&1

echo.
echo ============================================================================
echo  Phase 3: Removing Scheduled Tasks
echo ============================================================================
echo.

echo [4/6] Removing NVIDIA scheduled tasks...

for %%T in (
    "\NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvTmRepOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvProfileUpdaterDaily_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvProfileUpdaterOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvDriverUpdateCheckDaily_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvNodeLauncher_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvBatteryBoostCheckOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NVIDIA GeForce Experience SelfUpdate_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvTmRepCR1_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvTmRepCR2_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
    "\NvTmRepCR3_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
) do (
    schtasks /delete /tn "%%T" /f >nul 2>&1
    if not errorlevel 1 (
        echo       - Removed task: %%~nT
        set /a success+=1
    )
)

echo       - Task cleanup complete

echo.
echo ============================================================================
echo  Phase 4: Cleaning Up Registry
echo ============================================================================
echo.

echo [5/6] Removing NVIDIA telemetry registry entries...

:: Disable telemetry via registry
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NvTelemetryContainer" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1

:: Remove startup entries
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "NvBackend" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ShadowPlay" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "NvBackend" /f >nul 2>&1

:: Remove telemetry registry keys
reg delete "HKLM\SOFTWARE\NVIDIA Corporation\NvTelemetry" /f >nul 2>&1

echo       - Registry cleanup complete
set /a success+=1

echo.
echo ============================================================================
echo  Phase 5: Removing Leftover Files
echo ============================================================================
echo.

echo [6/6] Removing NVIDIA bloatware files and folders...

:: Remove GeForce Experience folders
for %%D in (
    "%ProgramFiles%\NVIDIA Corporation\NVIDIA GeForce Experience"
    "%ProgramFiles(x86)%\NVIDIA Corporation\NVIDIA GeForce Experience"
    "%ProgramFiles%\NVIDIA Corporation\NvContainer"
    "%ProgramFiles%\NVIDIA Corporation\NvTelemetry"
    "%ProgramFiles%\NVIDIA Corporation\NvNode"
    "%ProgramFiles%\NVIDIA Corporation\NvBackend"
    "%ProgramFiles%\NVIDIA Corporation\ShadowPlay"
    "%ProgramFiles%\NVIDIA Corporation\Update Core"
    "%LocalAppData%\NVIDIA\NvBackend"
    "%LocalAppData%\NVIDIA Corporation\NVIDIA GeForce Experience"
    "%ProgramData%\NVIDIA\NvTelemetry"
    "%ProgramData%\NVIDIA Corporation\NvTelemetry"
    "%ProgramData%\NVIDIA Corporation\GeForce Experience"
) do (
    if exist "%%D" (
        rd /s /q "%%D" >nul 2>&1
        if not errorlevel 1 (
            echo       - Removed: %%D
            set /a success+=1
        ) else (
            echo       - Could not remove: %%D (in use or protected)
        )
    )
)

echo       - File cleanup complete

echo.
echo ============================================================================
echo  Summary
echo ============================================================================
echo.
echo Successful operations: %success%
echo.

if %success% gtr 5 (
    color 0A
    echo [SUCCESS] NVIDIA bloatware has been removed.
) else (
    color 0E
    echo [INFO] Some items may already have been removed or were not installed.
)

echo.
echo What was removed:
echo  - GeForce Experience application
echo  - NVIDIA telemetry/data collection
echo  - NVIDIA background services (containers, web helper)
echo  - NVIDIA scheduled tasks
echo  - Startup entries
echo.
echo What remains intact:
echo  - NVIDIA graphics driver
echo  - NVIDIA Control Panel
echo  - Core display functionality
echo.
echo NOTE: After a driver update, some bloatware may be reinstalled.
echo       Consider using NVCleanstall for clean driver installations.
echo.
echo A reboot is recommended to complete the removal process.
echo.

set /p "reboot=Would you like to restart your computer now? (Y/N): "
if /i "%reboot%"=="Y" (
    echo.
    echo Restarting computer in 10 seconds...
    echo Press Ctrl+C to cancel.
    shutdown /r /t 10 /c "NVIDIA Bloatware Removal - Restart"
)

echo.
pause
exit /b 0
