@echo off
setlocal enabledelayedexpansion
title ASUS Bloatware Remover
color 0A

:: ============================================================================
:: ASUS Bloatware Remover
:: ============================================================================
:: Removes ASUS pre-installed software and common bundled bloatware.
:: Keeps essential drivers and hardware functionality intact.
:: ============================================================================

echo ============================================================================
echo  ASUS Bloatware Remover
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

echo This script will remove ASUS bloatware while keeping essential drivers.
echo.
echo What will be REMOVED:
echo  - Armoury Crate and ROG software [optional - you choose]
echo  - MyASUS app
echo  - ASUS GIFTBOX
echo  - ASUS AI Suite
echo  - ASUS GameFirst
echo  - ASUS Sonic Studio / Sonic Radar
echo  - ASUS WebStorage
echo  - ASUS Live Update
echo  - ASUS Splendid
echo  - Bundled third-party software [McAfee, WinZip, etc.]
echo.
echo What will be KEPT:
echo  - Hardware drivers [chipset, audio, network, etc.]
echo  - BIOS/firmware components
echo  - Basic system functionality
echo.

:: Confirm before proceeding
set /p "confirm=Do you want to continue? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo.
    echo Operation cancelled.
    pause
    exit /b 0
)

:: Ask about Armoury Crate
echo.
echo ============================================================================
echo  Armoury Crate / ROG Software Decision
echo ============================================================================
echo.
echo Armoury Crate controls:
echo  - RGB lighting [Aura Sync]
echo  - Fan profiles and performance modes
echo  - Gaming features [ROG specific]
echo.
echo If you use RGB lighting or custom fan profiles, you may want to KEEP it.
echo.
set /p "remove_armoury=Remove Armoury Crate and ROG software? [Y/N]: "

echo.
echo ============================================================================
echo  Phase 1: Stopping ASUS Services and Processes
echo ============================================================================
echo.

set "success=0"

:: Kill ASUS processes
echo [1/6] Terminating ASUS processes...

for %%P in (
    "ArmouryCrate.exe"
    "ArmouryCrate.Service.exe"
    "ArmouryCrateControlInterface.exe"
    "ArmourySocketServer.exe"
    "AsusCertService.exe"
    "AsusDownloadAgent.exe"
    "AsusLinkNear.exe"
    "AsusLinkRemote.exe"
    "AsusOptimization.exe"
    "AsusSoftwareManager.exe"
    "AsusSystemAnalysis.exe"
    "AsusSystemDiagnosis.exe"
    "AsusFanControlService.exe"
    "GameFirstUv.exe"
    "GameSDK.exe"
    "LightingService.exe"
    "MyASUS.exe"
    "P508PowerAgent.exe"
    "ROGLiveService.exe"
    "SonicStudio3.exe"
    "SonicRadar3.exe"
    "ASUS WebStorage.exe"
    "AsusWSWinService.exe"
    "GiftBox.exe"
    "AISuite3.exe"
    "AISuiteService.exe"
    "Nahimic3.exe"
    "NahimicService.exe"
) do (
    taskkill /f /im %%P >nul 2>&1
)
echo       - Process termination complete
set /a success+=1

:: Stop ASUS services
echo.
echo [2/6] Stopping and disabling ASUS services...

for %%S in (
    "ArmouryCrateControlInterface"
    "ArmouryCrateService"
    "AsusAppService"
    "AsusCertService"
    "AsusLinkNear"
    "AsusLinkRemote"
    "AsusOptimization"
    "AsusSoftwareManager"
    "AsusSystemAnalysis"
    "AsusSystemDiagnosis"
    "AsusUpdateCheck"
    "GameSDK Service"
    "LightingService"
    "NahimicService"
    "ROGLiveService"
) do (
    sc query %%S >nul 2>&1
    if not errorlevel 1060 (
        sc stop %%S >nul 2>&1
        sc config %%S start= disabled >nul 2>&1
        echo       - Disabled: %%S
        set /a success+=1
    )
)

echo.
echo ============================================================================
echo  Phase 2: Removing ASUS Applications
echo ============================================================================
echo.

echo [3/6] Removing ASUS AppX packages...

:: Create PowerShell script for AppX removal
set "PSSCRIPT=%TEMP%\remove-asus.ps1"

echo $packages = @( > "%PSSCRIPT%"
echo     '*ASUS*', >> "%PSSCRIPT%"
echo     '*Armoury*', >> "%PSSCRIPT%"
echo     '*MyASUS*', >> "%PSSCRIPT%"
echo     '*ROGLiveService*', >> "%PSSCRIPT%"
echo     '*AuraCreator*', >> "%PSSCRIPT%"
echo     '*GamingCenter*' >> "%PSSCRIPT%"
echo ) >> "%PSSCRIPT%"
echo. >> "%PSSCRIPT%"
echo foreach ($pattern in $packages) { >> "%PSSCRIPT%"
echo     Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue ^| ForEach-Object { >> "%PSSCRIPT%"
echo         Write-Host "       - Removing: $($_.Name)" >> "%PSSCRIPT%"
echo         Remove-AppxPackage -Package $_.PackageFullName -ErrorAction SilentlyContinue >> "%PSSCRIPT%"
echo     } >> "%PSSCRIPT%"
echo     Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue ^| >> "%PSSCRIPT%"
echo         Where-Object DisplayName -Like $pattern ^| ForEach-Object { >> "%PSSCRIPT%"
echo         Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue ^| Out-Null >> "%PSSCRIPT%"
echo     } >> "%PSSCRIPT%"
echo } >> "%PSSCRIPT%"

powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%" 2>nul
del "%PSSCRIPT%" 2>nul

:: Uninstall using WMIC and standard uninstallers
echo.
echo [4/6] Removing ASUS desktop applications...

:: ASUS software to remove
set "asus_apps=ASUS GIFTBOX;ASUS WebStorage;ASUS Live Update;ASUS Splendid Video Enhancement;ASUS Smart Gesture;ASUS TouchPad Handwriting;ASUS HiPost;ASUS Screen Saver;ASUS USB Charger Plus;ASUS Product Register Program;ASUS Instant Connect;ASUS Console;ASUS Tutor"

:: AI Suite removal
echo       - Checking ASUS AI Suite...
wmic product where "name like '%%AI Suite%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS AI%%'" call uninstall /nointeractive >nul 2>&1

:: GameFirst removal
echo       - Checking ASUS GameFirst...
wmic product where "name like '%%GameFirst%%'" call uninstall /nointeractive >nul 2>&1

:: Sonic Studio / Radar removal
echo       - Checking ASUS Sonic Studio/Radar...
wmic product where "name like '%%Sonic Studio%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%Sonic Radar%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%Nahimic%%'" call uninstall /nointeractive >nul 2>&1

:: Other ASUS software
echo       - Checking other ASUS software...
wmic product where "name like '%%ASUS GIFTBOX%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS WebStorage%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS Live Update%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS Splendid%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS Smart Gesture%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS HiPost%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS InstantOn%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS Instant Connect%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS Product Register%%'" call uninstall /nointeractive >nul 2>&1

:: Armoury Crate removal (if user chose to remove it)
if /i "%remove_armoury%"=="Y" (
    echo.
    echo       - Removing Armoury Crate and ROG software...
    wmic product where "name like '%%Armoury Crate%%'" call uninstall /nointeractive >nul 2>&1
    wmic product where "name like '%%ARMOURY CRATE%%'" call uninstall /nointeractive >nul 2>&1
    wmic product where "name like '%%ROG%%'" call uninstall /nointeractive >nul 2>&1
    wmic product where "name like '%%AURA%%'" call uninstall /nointeractive >nul 2>&1
    wmic product where "name like '%%Aura Sync%%'" call uninstall /nointeractive >nul 2>&1
    wmic product where "name like '%%LightingService%%'" call uninstall /nointeractive >nul 2>&1

    :: Remove Armoury Crate via its uninstaller
    if exist "%ProgramFiles%\ASUS\ARMOURY CRATE Lite Service\Uninstall.exe" (
        start /wait "" "%ProgramFiles%\ASUS\ARMOURY CRATE Lite Service\Uninstall.exe" /silent >nul 2>&1
    )
    if exist "%ProgramFiles%\ASUS\ArmouryCrate\Uninstall.exe" (
        start /wait "" "%ProgramFiles%\ASUS\ArmouryCrate\Uninstall.exe" /silent >nul 2>&1
    )
)

echo.
echo ============================================================================
echo  Phase 3: Removing Bundled Third-Party Bloatware
echo ============================================================================
echo.

echo [5/6] Removing bundled third-party software...

:: McAfee removal
echo       - Checking McAfee...
wmic product where "name like '%%McAfee%%'" call uninstall /nointeractive >nul 2>&1

:: Common McAfee locations
if exist "%ProgramFiles%\McAfee" (
    echo       - Found McAfee installation, attempting removal...
)

:: WinZip removal
echo       - Checking WinZip...
wmic product where "name like '%%WinZip%%'" call uninstall /nointeractive >nul 2>&1

:: Norton removal
echo       - Checking Norton...
wmic product where "name like '%%Norton%%'" call uninstall /nointeractive >nul 2>&1

:: ExpressVPN trial removal
echo       - Checking ExpressVPN...
wmic product where "name like '%%ExpressVPN%%'" call uninstall /nointeractive >nul 2>&1

:: Dropbox
echo       - Checking Dropbox...
wmic product where "name like '%%Dropbox%%'" call uninstall /nointeractive >nul 2>&1

echo.
echo ============================================================================
echo  Phase 4: Removing Scheduled Tasks and Startup Items
echo ============================================================================
echo.

echo [6/6] Removing ASUS scheduled tasks and startup items...

:: Remove ASUS scheduled tasks
for /f "tokens=*" %%T in ('schtasks /query /fo list 2^>nul ^| findstr /i "ASUS Armoury ROG Aura"') do (
    for /f "tokens=2 delims=:" %%N in ("%%T") do (
        set "taskname=%%N"
        set "taskname=!taskname:~1!"
        schtasks /delete /tn "!taskname!" /f >nul 2>&1
    )
)

:: Remove startup entries from registry
echo       - Cleaning startup entries...
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUS Smart Gesture" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUSWebStorage" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUS HiPost" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUS Smart Gesture" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUSWebStorage" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUS AI Suite" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ArmouryCrate" /f >nul 2>&1

if /i "%remove_armoury%"=="Y" (
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "LightingService" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ROGLiveService" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AuraSync" /f >nul 2>&1
)

echo       - Startup cleanup complete

:: Clean up leftover folders
echo.
echo       - Cleaning leftover folders...

call :CleanFolder "%ProgramFiles%\ASUS\ASUS WebStorage"
call :CleanFolder "%ProgramFiles%\ASUS\GIFTBOX"
call :CleanFolder "%ProgramFiles%\ASUS\AI Suite"
call :CleanFolder "%ProgramFiles%\ASUS\AI Suite II"
call :CleanFolder "%ProgramFiles%\ASUS\AI Suite III"
call :CleanFolder "%ProgramFiles%\ASUS\GameFirst"
call :CleanFolder "%ProgramFiles%\ASUS\Sonic Studio 3"
call :CleanFolder "%ProgramFiles%\ASUS\Sonic Radar 3"
call :CleanFolder "%ProgramData%\ASUS\GiftBox"
call :CleanFolder "%LocalAppData%\ASUS\WebStorage"

if /i "%remove_armoury%"=="Y" (
    call :CleanFolder "%ProgramFiles%\ASUS\ARMOURY CRATE Lite Service"
    call :CleanFolder "%ProgramFiles%\ASUS\ArmouryCrate"
    call :CleanFolder "%ProgramFiles%\ASUS\ROG Live Service"
    call :CleanFolder "%ProgramFiles%\ASUS\AURA"
    call :CleanFolder "%ProgramFiles%\LightingService"
)

echo.
echo ============================================================================
echo  Summary
echo ============================================================================
echo.
echo Removal process complete!
echo.
echo What was removed:
echo  - ASUS utility software and services
echo  - ASUS scheduled tasks and startup items
echo  - Bundled third-party software [McAfee, WinZip, etc.]
if /i "%remove_armoury%"=="Y" (
    echo  - Armoury Crate, Aura Sync, and ROG software
) else (
    echo  - [KEPT] Armoury Crate, Aura Sync, and ROG software
)
echo.
echo What remains:
echo  - Hardware drivers [chipset, audio, network, Bluetooth]
echo  - BIOS/UEFI components
echo  - Basic Windows functionality
echo.

if /i "%remove_armoury%"=="Y" (
    echo NOTE: RGB lighting will use default settings without Armoury Crate.
    echo       Fan control will use BIOS defaults.
    echo.
)

echo A reboot is recommended to complete the removal process.
echo.

set /p "reboot=Would you like to restart now? [Y/N]: "
if /i "%reboot%"=="Y" (
    echo.
    echo Restarting in 10 seconds...
    shutdown /r /t 10 /c "ASUS Bloatware Removal - Restart"
)

echo.
pause
exit /b 0

:: ============================================================================
:: Subroutine: CleanFolder
:: ============================================================================
:CleanFolder
if exist "%~1" (
    rd /s /q "%~1" >nul 2>&1
    if not errorlevel 1 (
        echo       - Removed: %~1
    )
)
goto :eof
