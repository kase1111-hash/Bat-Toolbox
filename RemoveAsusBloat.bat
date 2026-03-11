@echo off
setlocal enabledelayedexpansion
title ASUS Bloatware Remover
color 0B

:: ============================================================================
:: ASUS Bloatware Remover
:: ============================================================================
:: Removes ASUS pre-installed software, bundled bloatware, and auto-reinstallers.
:: Keeps essential drivers and hardware functionality intact.
:: ============================================================================

:: Set up color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "RESET=%ESC%[0m"

echo %CYAN%============================================================================%RESET%
echo %CYAN% ASUS Bloatware Remover%RESET%
echo %CYAN%============================================================================%RESET%
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR] This script requires Administrator privileges.%RESET%
    echo %RED%Please right-click and select "Run as administrator"%RESET%
    echo.
    pause
    exit /b 1
)

echo This script will remove ASUS bloatware while keeping essential drivers.
echo.
echo %YELLOW%What will be REMOVED:%RESET%
echo  - Armoury Crate and ROG software [optional - you choose]
echo  - MyASUS app
echo  - ASUS GIFTBOX
echo  - ASUS AI Suite
echo  - ASUS GameFirst
echo  - ASUS Sonic Studio / Sonic Radar / Nahimic
echo  - ASUS WebStorage
echo  - ASUS Live Update
echo  - ASUS Splendid
echo  - ASUS GlideX / ScreenXpert / Link
echo  - ASUS Software Manager and auto-reinstallers
echo  - Bundled third-party software [McAfee, WinZip, Norton, etc.]
echo.
echo %GREEN%What will be KEPT:%RESET%
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
echo %CYAN%============================================================================%RESET%
echo %CYAN% Armoury Crate / ROG Software Decision%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo Armoury Crate controls:
echo  - RGB lighting [Aura Sync]
echo  - Fan profiles and performance modes
echo  - Gaming features [ROG specific]
echo.
echo %YELLOW%If you use RGB lighting or custom fan profiles, you may want to KEEP it.%RESET%
echo.
set /p "remove_armoury=Remove Armoury Crate and ROG software? [Y/N]: "

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 1: Stopping ASUS Services and Processes%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [1/8] Terminating ASUS processes...

for %%P in (
    "ArmouryCrate.exe"
    "ArmouryCrate.Service.exe"
    "ArmouryCrateControlInterface.exe"
    "ArmourySocketServer.exe"
    "ArmourySwAgent.exe"
    "AsusCertService.exe"
    "AsusDownloadAgent.exe"
    "AsusLinkNear.exe"
    "AsusLinkRemote.exe"
    "AsusOptimization.exe"
    "AsusSoftwareManager.exe"
    "AsusSoftwareManagerAgent.exe"
    "AsusSystemAnalysis.exe"
    "AsusSystemDiagnosis.exe"
    "AsusFanControlService.exe"
    "AsusUpdateCheck.exe"
    "AsusLiveUpdate.exe"
    "GameFirstUv.exe"
    "GameSDK.exe"
    "GlideX.exe"
    "LightingService.exe"
    "MyASUS.exe"
    "P508PowerAgent.exe"
    "P513PowerAgent.exe"
    "ROGLiveService.exe"
    "ScreenXpertService.exe"
    "ScreenXpert.exe"
    "SonicStudio3.exe"
    "SonicRadar3.exe"
    "ASUS WebStorage.exe"
    "AsusWSWinService.exe"
    "GiftBox.exe"
    "AISuite3.exe"
    "AISuiteService.exe"
    "Nahimic3.exe"
    "NahimicService.exe"
    "NahimicSvc64.exe"
    "NahimicNotifier.exe"
    "ASUSSmartGesture.exe"
    "DeviceInformation.exe"
    "ASUSSplendid.exe"
) do (
    taskkill /f /im %%P >nul 2>&1
)
echo       %GREEN%- Process termination complete%RESET%

:: Stop and disable ASUS services
echo.
echo [2/8] Stopping and disabling ASUS services...

for %%S in (
    "ArmouryCrateControlInterface"
    "ArmouryCrateService"
    "ArmourySocketServer"
    "AsusAppService"
    "AsusCertService"
    "AsusFanControlService"
    "AsusLinkNear"
    "AsusLinkRemote"
    "AsusOptimization"
    "AsusSoftwareManager"
    "AsusSoftwareManagerAgent"
    "AsusSystemAnalysis"
    "AsusSystemDiagnosis"
    "AsusUpdateCheck"
    "GameSDK Service"
    "LightingService"
    "NahimicService"
    "ROGLiveService"
    "ScreenXpertService"
    "asus"
    "asusm"
    "ASUSLiveUpdate"
    "ASUSSwitch"
) do (
    sc query %%S >nul 2>&1
    if not errorlevel 1060 (
        sc stop %%S >nul 2>&1
        sc config %%S start= disabled >nul 2>&1
        echo       %GREEN%- Disabled: %%~S%RESET%
    )
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 2: Removing ASUS Applications%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [3/8] Removing ASUS AppX packages...

:: Create PowerShell script for AppX removal
set "PSSCRIPT=%TEMP%\remove-asus.ps1"

(
echo $packages = @(
echo     '*ASUS*',
echo     '*Armoury*',
echo     '*MyASUS*',
echo     '*ROGLiveService*',
echo     '*AuraCreator*',
echo     '*GamingCenter*',
echo     '*GlideX*',
echo     '*ScreenXpert*',
echo     '*DeviceInformation*',
echo     '*ASUSPCAssistant*',
echo     '*ASUSProductRegistration*'
echo ^)
echo.
echo foreach ^($pattern in $packages^) {
echo     Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue ^| ForEach-Object {
echo         Write-Host "       - Removing: $($_.Name)"
echo         Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
echo     }
echo     Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue ^|
echo         Where-Object DisplayName -Like $pattern ^| ForEach-Object {
echo         Write-Host "       - Deprovisioning: $($_.DisplayName)"
echo         Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue ^| Out-Null
echo     }
echo }
) > "%PSSCRIPT%"

powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%" 2>nul
del "%PSSCRIPT%" 2>nul

:: Uninstall using WMIC and standard uninstallers
echo.
echo [4/8] Removing ASUS desktop applications...

:: AI Suite removal
echo       - Checking ASUS AI Suite...
wmic product where "name like '%%AI Suite%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS AI%%'" call uninstall /nointeractive >nul 2>&1

:: GameFirst removal
echo       - Checking ASUS GameFirst...
wmic product where "name like '%%GameFirst%%'" call uninstall /nointeractive >nul 2>&1

:: Sonic Studio / Radar / Nahimic removal
echo       - Checking ASUS Sonic Studio/Radar/Nahimic...
wmic product where "name like '%%Sonic Studio%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%Sonic Radar%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%Nahimic%%'" call uninstall /nointeractive >nul 2>&1

:: GlideX / ScreenXpert removal
echo       - Checking ASUS GlideX/ScreenXpert...
wmic product where "name like '%%GlideX%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ScreenXpert%%'" call uninstall /nointeractive >nul 2>&1

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
wmic product where "name like '%%ASUS Console%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS Tutor%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS Screen Saver%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS USB Charger%%'" call uninstall /nointeractive >nul 2>&1

:: ASUS Software Manager and update agents (re-installers)
echo       - Removing ASUS Software Manager and update agents...
wmic product where "name like '%%ASUS Software Manager%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%AsusSoftwareManager%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS Update%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%AsusDownloadAgent%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%ASUS System Control%%'" call uninstall /nointeractive >nul 2>&1

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
    if exist "%ProgramFiles(x86)%\ASUS\ArmouryCrate\Uninstall.exe" (
        start /wait "" "%ProgramFiles(x86)%\ASUS\ArmouryCrate\Uninstall.exe" /silent >nul 2>&1
    )

    :: Armoury Crate Uninstall Tool (official ASUS removal tool location)
    if exist "%ProgramFiles%\ASUS\Armoury Crate Uninstall Tool\ArmouryCrateUninstallTool.exe" (
        start /wait "" "%ProgramFiles%\ASUS\Armoury Crate Uninstall Tool\ArmouryCrateUninstallTool.exe" /silent >nul 2>&1
    )
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 3: Removing Bundled Third-Party Bloatware%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [5/8] Removing bundled third-party software...

:: McAfee removal
echo       - Checking McAfee...
wmic product where "name like '%%McAfee%%'" call uninstall /nointeractive >nul 2>&1

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

:: Spotify (sometimes bundled)
echo       - Checking Spotify...
wmic product where "name like '%%Spotify%%'" call uninstall /nointeractive >nul 2>&1

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 4: Removing Scheduled Tasks%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [6/8] Removing ASUS scheduled tasks...

:: Remove ASUS scheduled tasks by known names
for %%T in (
    "\ASUS\ArmouryCrate"
    "\ASUS\ArmouryCrateLiteService"
    "\ASUS\ArmourySocketServer"
    "\ASUS\ASUSLiveUpdate"
    "\ASUS\ASUSSoftwareManager"
    "\ASUS\ASUSSoftwareManagerAgent"
    "\ASUS\AsusSystemAnalysis"
    "\ASUS\AsusSystemDiagnosis"
    "\ASUS\AsusCertService"
    "\ASUS\AsusUpdateCheck"
    "\ASUS\GlideX"
    "\ASUS\ScreenXpert"
    "\ASUS\P508PowerAgent"
    "\ASUS\P513PowerAgent"
    "\ASUS\MyASUS"
    "\ASUS\DeviceInformation"
    "\ArmouryCrate"
    "\AsusUpdateCheck"
    "\AsusSoftwareManager"
    "\ASUSGiftBox"
    "\ROG Live Service"
) do (
    schtasks /delete /tn "%%~T" /f >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%- Removed task: %%~T%RESET%
    )
)

:: Catch any remaining ASUS tasks by scanning the task list
set "PSTASKS=%TEMP%\remove-asus-tasks.ps1"
(
echo Get-ScheduledTask -ErrorAction SilentlyContinue ^| Where-Object {
echo     $_.TaskName -match 'ASUS' -or
echo     $_.TaskName -match 'Armoury' -or
echo     $_.TaskName -match 'AsusUpdate' -or
echo     $_.TaskName -match 'AsusSoftwareManager' -or
echo     $_.TaskName -match 'ROGLive' -or
echo     $_.TaskPath -match '\\ASUS\\'
echo } ^| ForEach-Object {
echo     Write-Host "       - Removing task: $($_.TaskPath)$($_.TaskName)"
echo     Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
echo }
) > "%PSTASKS%"

powershell -ExecutionPolicy Bypass -File "%PSTASKS%" 2>nul
del "%PSTASKS%" 2>nul

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 5: Blocking Re-installers and Auto-Updates%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [7/8] Blocking ASUS auto-reinstallation mechanisms...

:: Disable ASUS update check registry keys
echo       - Disabling ASUS update and reinstall registry entries...
reg add "HKLM\SOFTWARE\ASUS\ASUS Live Update" /v "PollInterval" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\ASUS\ASUS Live Update" /v "AutoUpdate" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\ASUS\AsusSoftwareManager" /v "AutoUpdate" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\ASUS\AsusSoftwareManager" /v "AutoInstall" /t REG_DWORD /d 0 /f >nul 2>&1

:: Remove the ASUS download agent and software manager entirely
echo       - Removing ASUS download agent...
if exist "%ProgramFiles%\ASUS\AsusDownloadAgent" (
    rd /s /q "%ProgramFiles%\ASUS\AsusDownloadAgent" >nul 2>&1
    echo       %GREEN%- Removed AsusDownloadAgent directory%RESET%
)
if exist "%ProgramFiles(x86)%\ASUS\AsusDownloadAgent" (
    rd /s /q "%ProgramFiles(x86)%\ASUS\AsusDownloadAgent" >nul 2>&1
    echo       %GREEN%- Removed AsusDownloadAgent (x86) directory%RESET%
)

echo       - Removing ASUS Software Manager files...
if exist "%ProgramFiles%\ASUS\AsusSoftwareManager" (
    rd /s /q "%ProgramFiles%\ASUS\AsusSoftwareManager" >nul 2>&1
    echo       %GREEN%- Removed AsusSoftwareManager directory%RESET%
)
if exist "%ProgramFiles(x86)%\ASUS\AsusSoftwareManager" (
    rd /s /q "%ProgramFiles(x86)%\ASUS\AsusSoftwareManager" >nul 2>&1
    echo       %GREEN%- Removed AsusSoftwareManager (x86) directory%RESET%
)

:: Remove ASUS Live Update files
echo       - Removing ASUS Live Update files...
if exist "%ProgramFiles%\ASUS\ASUS Live Update" (
    rd /s /q "%ProgramFiles%\ASUS\ASUS Live Update" >nul 2>&1
    echo       %GREEN%- Removed ASUS Live Update directory%RESET%
)
if exist "%ProgramFiles(x86)%\ASUS\ASUS Live Update" (
    rd /s /q "%ProgramFiles(x86)%\ASUS\ASUS Live Update" >nul 2>&1
    echo       %GREEN%- Removed ASUS Live Update (x86) directory%RESET%
)

:: Remove ASUS installer staging/cache directories
echo       - Cleaning ASUS installer cache...
if exist "%ProgramData%\ASUS\Promotion" (
    rd /s /q "%ProgramData%\ASUS\Promotion" >nul 2>&1
    echo       %GREEN%- Removed ASUS Promotion cache%RESET%
)
if exist "%ProgramData%\ASUS\SoftwareManager" (
    rd /s /q "%ProgramData%\ASUS\SoftwareManager" >nul 2>&1
    echo       %GREEN%- Removed ASUS SoftwareManager cache%RESET%
)
if exist "%ProgramData%\ASUS\InstallerCache" (
    rd /s /q "%ProgramData%\ASUS\InstallerCache" >nul 2>&1
    echo       %GREEN%- Removed ASUS InstallerCache%RESET%
)

:: Remove startup entries from registry
echo.
echo       - Cleaning startup entries...
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUS Smart Gesture" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUSWebStorage" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUS HiPost" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AsusSoftwareManager" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AsusDownloadAgent" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "GlideX" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ScreenXpert" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUS Smart Gesture" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUSWebStorage" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUS AI Suite" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ArmouryCrate" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AsusSoftwareManager" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AsusDownloadAgent" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUSLiveUpdate" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AsusUpdateCheck" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "GlideX" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ScreenXpert" /f >nul 2>&1

if /i "%remove_armoury%"=="Y" (
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "LightingService" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ROGLiveService" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AuraSync" /f >nul 2>&1
)

echo       %GREEN%- Startup cleanup complete%RESET%

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 6: Cleaning Leftover Files%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [8/8] Cleaning leftover folders...

:: ASUS software directories
call :CleanFolder "%ProgramFiles%\ASUS\ASUS WebStorage"
call :CleanFolder "%ProgramFiles%\ASUS\GIFTBOX"
call :CleanFolder "%ProgramFiles%\ASUS\AI Suite"
call :CleanFolder "%ProgramFiles%\ASUS\AI Suite II"
call :CleanFolder "%ProgramFiles%\ASUS\AI Suite III"
call :CleanFolder "%ProgramFiles%\ASUS\GameFirst"
call :CleanFolder "%ProgramFiles%\ASUS\GameFirst VI"
call :CleanFolder "%ProgramFiles%\ASUS\Sonic Studio 3"
call :CleanFolder "%ProgramFiles%\ASUS\Sonic Radar 3"
call :CleanFolder "%ProgramFiles%\ASUS\GlideX"
call :CleanFolder "%ProgramFiles%\ASUS\ScreenXpert"
call :CleanFolder "%ProgramFiles%\ASUS\ASUS Splendid"
call :CleanFolder "%ProgramFiles%\ASUS\ASUS Smart Gesture"
call :CleanFolder "%ProgramFiles%\ASUS\ASUS Console"
call :CleanFolder "%ProgramFiles%\ASUS\ASUS Tutor"
call :CleanFolder "%ProgramFiles%\ASUS\ASUS HiPost"
call :CleanFolder "%ProgramFiles%\ASUS\DeviceInformation"

:: Also check x86 program files
call :CleanFolder "%ProgramFiles(x86)%\ASUS\ASUS WebStorage"
call :CleanFolder "%ProgramFiles(x86)%\ASUS\GIFTBOX"
call :CleanFolder "%ProgramFiles(x86)%\ASUS\AI Suite"
call :CleanFolder "%ProgramFiles(x86)%\ASUS\AI Suite II"
call :CleanFolder "%ProgramFiles(x86)%\ASUS\AI Suite III"
call :CleanFolder "%ProgramFiles(x86)%\ASUS\Sonic Studio 3"
call :CleanFolder "%ProgramFiles(x86)%\ASUS\Sonic Radar 3"
call :CleanFolder "%ProgramFiles(x86)%\ASUS\ASUS Splendid"

:: ProgramData and AppData locations
call :CleanFolder "%ProgramData%\ASUS\GiftBox"
call :CleanFolder "%ProgramData%\ASUS\WebStorage"
call :CleanFolder "%ProgramData%\ASUS\Nahimic"
call :CleanFolder "%LocalAppData%\ASUS\WebStorage"
call :CleanFolder "%LocalAppData%\ASUS\GlideX"
call :CleanFolder "%LocalAppData%\ASUS\ScreenXpert"

:: Nahimic (installed outside ASUS folder sometimes)
call :CleanFolder "%ProgramFiles%\Nahimic"
call :CleanFolder "%ProgramFiles(x86)%\Nahimic"

if /i "%remove_armoury%"=="Y" (
    call :CleanFolder "%ProgramFiles%\ASUS\ARMOURY CRATE Lite Service"
    call :CleanFolder "%ProgramFiles%\ASUS\ArmouryCrate"
    call :CleanFolder "%ProgramFiles%\ASUS\ROG Live Service"
    call :CleanFolder "%ProgramFiles%\ASUS\AURA"
    call :CleanFolder "%ProgramFiles%\ASUS\Armoury Crate Uninstall Tool"
    call :CleanFolder "%ProgramFiles%\LightingService"
    call :CleanFolder "%ProgramFiles(x86)%\LightingService"
    call :CleanFolder "%ProgramData%\ASUS\ArmouryCrate"
    call :CleanFolder "%ProgramData%\ASUS\ROGLiveService"
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Summary%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo %GREEN%Removal process complete!%RESET%
echo.
echo What was removed:
echo  - ASUS utility software and services
echo  - ASUS scheduled tasks and startup items
echo  - ASUS auto-reinstallers and update agents
echo  - Bundled third-party software [McAfee, WinZip, etc.]
if /i "%remove_armoury%"=="Y" (
    echo  - Armoury Crate, Aura Sync, and ROG software
) else (
    echo  %YELLOW%- [KEPT] Armoury Crate, Aura Sync, and ROG software%RESET%
)
echo.
echo What remains:
echo  - Hardware drivers [chipset, audio, network, Bluetooth]
echo  - BIOS/UEFI components
echo  - Basic Windows functionality
echo.

if /i "%remove_armoury%"=="Y" (
    echo %YELLOW%NOTE: RGB lighting will use default settings without Armoury Crate.%RESET%
    echo %YELLOW%      Fan control will use BIOS defaults.%RESET%
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
        echo       %GREEN%- Removed: %~1%RESET%
    )
)
goto :eof
