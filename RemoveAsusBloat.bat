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
echo/

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR] This script requires Administrator privileges.%RESET%
    echo %RED%Please right-click and select "Run as administrator"%RESET%
    echo/
    pause
    exit /b 1
)

echo This script will remove ASUS bloatware while keeping essential drivers.
echo/
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
echo  - Third-party: McAfee, Norton, WinZip, ExpressVPN, Dropbox, Spotify [optional - you choose]
echo/
echo %GREEN%What will be KEPT:%RESET%
echo  - Hardware drivers [chipset, audio, network, etc.]
echo  - BIOS/firmware components
echo  - ASUS Optimization service and ASUS Keyboard Hotkeys app [Fn hotkeys / OSD]
echo  - Basic system functionality
echo/

:: Confirm before proceeding
set "confirm="
set /p "confirm=Do you want to continue? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo/
    echo Operation cancelled.
    pause
    exit /b 0
)

:: Ask about Armoury Crate
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Armoury Crate / ROG Software Decision%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo Armoury Crate controls:
echo  - RGB lighting [Aura Sync]
echo  - Fan profiles and performance modes
echo  - Gaming features [ROG specific]
echo/
echo %YELLOW%If you use RGB lighting or custom fan profiles, you may want to KEEP it.%RESET%
echo/
set "remove_armoury="
set /p "remove_armoury=Remove Armoury Crate and ROG software? [Y/N]: "

:: Ask about third-party software up front so later phases never pause for input
echo/
echo %YELLOW%Answer N if you installed or paid for any of these yourself.%RESET%
set "remove_thirdparty="
set /p "remove_thirdparty=Also uninstall McAfee, Norton, WinZip, ExpressVPN, Dropbox and Spotify if installed? [Y/N]: "

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 1: Stopping ASUS Services and Processes%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [1/8] Terminating ASUS processes...

:: AsusOptimization.exe is deliberately not listed: it runs AsusHotkey.exe [Fn keys]
for %%P in (
    "AsusDownloadAgent.exe"
    "AsusLinkNear.exe"
    "AsusLinkRemote.exe"
    "AsusSoftwareManager.exe"
    "AsusSoftwareManagerAgent.exe"
    "AsusSystemAnalysis.exe"
    "AsusSystemDiagnosis.exe"
    "AsusUpdateCheck.exe"
    "AsusLiveUpdate.exe"
    "GameFirstUv.exe"
    "GlideX.exe"
    "MyASUS.exe"
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
:: Armoury Crate / Aura / fan-control / ROG mouse power agent processes only when the user chose to remove them
if /i "%remove_armoury%"=="Y" (
    for %%P in (
        "ArmouryCrate.exe"
        "ArmouryCrate.Service.exe"
        "ArmouryCrateControlInterface.exe"
        "ArmourySocketServer.exe"
        "ArmourySwAgent.exe"
        "AsusCertService.exe"
        "AsusFanControlService.exe"
        "GameSDK.exe"
        "LightingService.exe"
        "P508PowerAgent.exe"
        "P513PowerAgent.exe"
        "ROGLiveService.exe"
    ) do (
        taskkill /f /im %%P >nul 2>&1
    )
)
echo       %GREEN%- Process termination complete%RESET%

:: Stop and disable ASUS services
:: AsusOptimization is deliberately not listed: it runs AsusHotkey.exe [Fn keys]
echo/
echo [2/8] Stopping and disabling ASUS services...

for %%S in (
    "AsusAppService"
    "AsusLinkNear"
    "AsusLinkRemote"
    "AsusSoftwareManager"
    "AsusSoftwareManagerAgent"
    "AsusSystemAnalysis"
    "AsusSystemDiagnosis"
    "AsusUpdateCheck"
    "NahimicService"
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
:: Armoury Crate / Aura / fan-control services only when the user chose to remove them
if /i "%remove_armoury%"=="Y" (
    for %%S in (
        "ArmouryCrateControlInterface"
        "ArmouryCrateService"
        "ArmourySocketServer"
        "AsusCertService"
        "AsusFanControlService"
        "GameSDK Service"
        "LightingService"
        "ROGLiveService"
    ) do (
        sc query %%S >nul 2>&1
        if not errorlevel 1060 (
            sc stop %%S >nul 2>&1
            sc config %%S start= disabled >nul 2>&1
            echo       %GREEN%- Disabled: %%~S%RESET%
        )
    )
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 2: Removing ASUS Applications%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [3/8] Removing ASUS AppX packages...

:: Create PowerShell script for AppX removal
set "PSSCRIPT=%TEMP%\remove-asus.ps1"

:: Armoury Crate / Aura / ROG Store apps are only targeted when the user chose to remove them.
:: $keepPattern also shields them - and the ASUS Keyboard Hotkeys app [Fn keys on some
:: notebooks], which is always kept - from the broad '*ASUS*' pattern.
set "ARMOURY_PATTERNS="
set "PS_KEEP_ARMOURY=$true"
if /i "%remove_armoury%"=="Y" (
    set "ARMOURY_PATTERNS=,'*Armoury*','*ROGLiveService*','*AuraCreator*','*GamingCenter*'"
    set "PS_KEEP_ARMOURY=$false"
)

(
echo $keepArmoury = %PS_KEEP_ARMOURY%
echo $keepPattern = 'KeyboardHotkeys'
echo if ^($keepArmoury^) { $keepPattern += '^|Armoury^|AuraCreator^|ROGLive^|GamingCenter' }
echo $packages = @^(
echo     '*ASUS*',
echo     '*MyASUS*',
echo     '*GlideX*',
echo     '*ScreenXpert*',
echo     '*DeviceInformation*',
echo     '*ASUSPCAssistant*',
echo     '*ASUSProductRegistration*'%ARMOURY_PATTERNS%
echo ^)
echo/
echo foreach ^($pattern in $packages^) {
echo     Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue ^| Where-Object { $_.Name -notmatch $keepPattern } ^| ForEach-Object {
echo         Write-Host "       - Removing: $($_.Name)"
echo         Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
echo     }
echo     Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue ^|
echo         Where-Object { $_.DisplayName -like $pattern -and $_.DisplayName -notmatch $keepPattern } ^| ForEach-Object {
echo         Write-Host "       - Deprovisioning: $($_.DisplayName)"
echo         Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue ^| Out-Null
echo     }
echo }
) > "%PSSCRIPT%"

powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%" 2>nul
del "%PSSCRIPT%" 2>nul

:: Uninstall MSI-installed programs by name (see :UninstallMsiByName) and standard uninstallers
echo/
echo [4/8] Removing ASUS desktop applications...

:: AI Suite removal
echo       - Checking ASUS AI Suite...
call :UninstallMsiByName "AI Suite|ASUS AI"

:: GameFirst removal
echo       - Checking ASUS GameFirst...
call :UninstallMsiByName "GameFirst"

:: Sonic Studio / Radar / Nahimic removal
echo       - Checking ASUS Sonic Studio/Radar/Nahimic...
call :UninstallMsiByName "Sonic Studio|Sonic Radar|Nahimic"

:: GlideX / ScreenXpert removal
echo       - Checking ASUS GlideX/ScreenXpert...
call :UninstallMsiByName "GlideX|ScreenXpert"

:: Other ASUS software
echo       - Checking other ASUS software...
call :UninstallMsiByName "ASUS GIFTBOX|ASUS WebStorage|ASUS Live Update|ASUS Splendid|ASUS Smart Gesture|ASUS HiPost|ASUS InstantOn|ASUS Instant Connect|ASUS Product Register|ASUS Console|ASUS Tutor|ASUS Screen Saver|ASUS USB Charger"

:: ASUS Software Manager and update agents (re-installers)
:: ASUS System Control Interface is deliberately NOT removed: it provides the
:: ASUS Optimization service that runs AsusHotkey.exe [Fn keys]
echo       - Removing ASUS Software Manager and update agents...
call :UninstallMsiByName "ASUS Software Manager|AsusSoftwareManager|ASUS Update|AsusDownloadAgent"

:: Armoury Crate removal (if user chose to remove it)
if /i "%remove_armoury%"=="Y" (
    echo/
    echo       - Removing Armoury Crate and ROG software...
    REM ROG and AURA are matched as whole words so names like "Program..." or "Laura" are not hit
    call :UninstallMsiByName "Armoury Crate|\bROG\b|\bAURA\b|Aura Sync|LightingService"

    REM Remove Armoury Crate via its uninstaller
    if exist "%ProgramFiles%\ASUS\ARMOURY CRATE Lite Service\Uninstall.exe" (
        start /wait "" "%ProgramFiles%\ASUS\ARMOURY CRATE Lite Service\Uninstall.exe" /silent >nul 2>&1
    )
    if exist "%ProgramFiles%\ASUS\ArmouryCrate\Uninstall.exe" (
        start /wait "" "%ProgramFiles%\ASUS\ArmouryCrate\Uninstall.exe" /silent >nul 2>&1
    )
    if exist "%ProgramFiles(x86)%\ASUS\ArmouryCrate\Uninstall.exe" (
        start /wait "" "%ProgramFiles(x86)%\ASUS\ArmouryCrate\Uninstall.exe" /silent >nul 2>&1
    )

    REM Armoury Crate Uninstall Tool (official ASUS removal tool location)
    if exist "%ProgramFiles%\ASUS\Armoury Crate Uninstall Tool\ArmouryCrateUninstallTool.exe" (
        start /wait "" "%ProgramFiles%\ASUS\Armoury Crate Uninstall Tool\ArmouryCrateUninstallTool.exe" /silent >nul 2>&1
    )
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 3: Removing Bundled Third-Party Bloatware%RESET%
echo %CYAN%============================================================================%RESET%
echo/

:: Only when the user explicitly opted in - these may be user-installed or paid
if /i not "%remove_thirdparty%"=="Y" (
    echo [5/8] Skipping third-party software [you chose to keep it]
    goto :SkipThirdParty
)

echo [5/8] Removing third-party software...
echo       - Checking McAfee, WinZip, Norton, ExpressVPN, Dropbox, Spotify...
call :UninstallMsiByName "McAfee|WinZip|Norton|ExpressVPN|Dropbox|Spotify"

:SkipThirdParty

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 4: Removing Scheduled Tasks%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [6/8] Removing ASUS scheduled tasks...

:: Remove ASUS scheduled tasks by known names
for %%T in (
    "\ASUS\ASUSLiveUpdate"
    "\ASUS\ASUSSoftwareManager"
    "\ASUS\ASUSSoftwareManagerAgent"
    "\ASUS\AsusSystemAnalysis"
    "\ASUS\AsusSystemDiagnosis"
    "\ASUS\AsusUpdateCheck"
    "\ASUS\GlideX"
    "\ASUS\ScreenXpert"
    "\ASUS\MyASUS"
    "\ASUS\DeviceInformation"
    "\AsusUpdateCheck"
    "\AsusSoftwareManager"
    "\ASUSGiftBox"
) do (
    schtasks /delete /tn "%%~T" /f >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%- Removed task: %%~T%RESET%
    )
)
:: Armoury Crate / ROG / ROG mouse power agent tasks only when the user chose to remove them
if /i "%remove_armoury%"=="Y" (
    for %%T in (
        "\ASUS\ArmouryCrate"
        "\ASUS\ArmouryCrateLiteService"
        "\ASUS\ArmourySocketServer"
        "\ASUS\AsusCertService"
        "\ASUS\P508PowerAgent"
        "\ASUS\P513PowerAgent"
        "\ArmouryCrate"
        "\ROG Live Service"
    ) do (
        schtasks /delete /tn "%%~T" /f >nul 2>&1
        if not errorlevel 1 (
            echo       %GREEN%- Removed task: %%~T%RESET%
        )
    )
)

:: Catch any remaining ASUS tasks by scanning the task list.
:: $keepPattern always spares the "ASUS Optimization ..." task that starts AsusHotkey.exe
:: [Fn keys], and spares Armoury Crate / Aura / fan / mouse power agent tasks when the user
:: keeps Armoury Crate.
set "PSTASKS=%TEMP%\remove-asus-tasks.ps1"
(
echo $keepArmoury = %PS_KEEP_ARMOURY%
echo $keepPattern = 'Optimization^|Hotkey'
echo if ^($keepArmoury^) { $keepPattern += '^|Armoury^|ROGLive^|Aura^|Lighting^|AsusCert^|FanControl^|GameSDK^|PowerAgent' }
echo Get-ScheduledTask -ErrorAction SilentlyContinue ^| Where-Object {
echo     ^($_.TaskName -match 'ASUS' -or
echo      $_.TaskName -match 'Armoury' -or
echo      $_.TaskName -match 'AsusUpdate' -or
echo      $_.TaskName -match 'AsusSoftwareManager' -or
echo      $_.TaskName -match 'ROGLive' -or
echo      $_.TaskPath -match '\\ASUS\\'^) -and
echo     $_.TaskName -notmatch $keepPattern
echo } ^| ForEach-Object {
echo     Write-Host "       - Removing task: $($_.TaskPath)$($_.TaskName)"
echo     Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
echo }
) > "%PSTASKS%"

powershell -ExecutionPolicy Bypass -File "%PSTASKS%" 2>nul
del "%PSTASKS%" 2>nul

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 5: Blocking Re-installers and Auto-Updates%RESET%
echo %CYAN%============================================================================%RESET%
echo/

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
    echo       %GREEN%- Removed AsusDownloadAgent ^(x86^) directory%RESET%
)

echo       - Removing ASUS Software Manager files...
if exist "%ProgramFiles%\ASUS\AsusSoftwareManager" (
    rd /s /q "%ProgramFiles%\ASUS\AsusSoftwareManager" >nul 2>&1
    echo       %GREEN%- Removed AsusSoftwareManager directory%RESET%
)
if exist "%ProgramFiles(x86)%\ASUS\AsusSoftwareManager" (
    rd /s /q "%ProgramFiles(x86)%\ASUS\AsusSoftwareManager" >nul 2>&1
    echo       %GREEN%- Removed AsusSoftwareManager ^(x86^) directory%RESET%
)

:: Remove ASUS Live Update files
echo       - Removing ASUS Live Update files...
if exist "%ProgramFiles%\ASUS\ASUS Live Update" (
    rd /s /q "%ProgramFiles%\ASUS\ASUS Live Update" >nul 2>&1
    echo       %GREEN%- Removed ASUS Live Update directory%RESET%
)
if exist "%ProgramFiles(x86)%\ASUS\ASUS Live Update" (
    rd /s /q "%ProgramFiles(x86)%\ASUS\ASUS Live Update" >nul 2>&1
    echo       %GREEN%- Removed ASUS Live Update ^(x86^) directory%RESET%
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
echo/
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
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AsusSoftwareManager" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AsusDownloadAgent" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ASUSLiveUpdate" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AsusUpdateCheck" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "GlideX" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ScreenXpert" /f >nul 2>&1

if /i "%remove_armoury%"=="Y" (
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ArmouryCrate" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "LightingService" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "ROGLiveService" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AuraSync" /f >nul 2>&1
)

echo       %GREEN%- Startup cleanup complete%RESET%

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 6: Cleaning Leftover Files%RESET%
echo %CYAN%============================================================================%RESET%
echo/

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

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Summary%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo %GREEN%Removal process complete^^!%RESET%
echo/
echo What was removed:
echo  - ASUS utility software and services
echo  - ASUS scheduled tasks and startup items
echo  - ASUS auto-reinstallers and update agents
if /i "%remove_thirdparty%"=="Y" echo  - Third-party software [McAfee, Norton, WinZip, ExpressVPN, Dropbox, Spotify]
if /i "%remove_armoury%"=="Y" (
    echo  - Armoury Crate, Aura Sync, and ROG software
) else (
    echo  %YELLOW%- [KEPT] Armoury Crate, Aura Sync, and ROG software%RESET%
)
echo/
echo What remains:
echo  - Hardware drivers [chipset, audio, network, Bluetooth]
echo  - BIOS/UEFI components
echo  - ASUS Optimization service and Fn hotkey support
echo  - Basic Windows functionality
echo/

if /i "%remove_armoury%"=="Y" (
    echo %YELLOW%NOTE: RGB lighting will use default settings without Armoury Crate.%RESET%
    echo %YELLOW%      Fan control will use BIOS defaults.%RESET%
    echo/
)

echo A reboot is recommended to complete the removal process.
echo/

set "reboot="
set /p "reboot=Would you like to restart now? [Y/N]: "
if /i "%reboot%"=="Y" (
    echo/
    echo Restarting in 10 seconds...
    shutdown /r /t 10 /c "ASUS Bloatware Removal - Restart"
)

echo/
pause
exit /b 0

:: ============================================================================
:: Subroutine: CleanFolder
:: ============================================================================
:: Deliberately uses no parenthesized blocks: the folder argument is often a
:: Program Files x86 path, and its closing parenthesis would end a block early
:: and abort the whole script with a syntax error.
:CleanFolder
if not exist "%~1" goto :eof
rd /s /q "%~1" >nul 2>&1
if exist "%~1" goto :eof
echo       %GREEN%- Removed: "%~1"%RESET%
goto :eof

:: ============================================================================
:: Subroutine: UninstallMsiByName
:: ============================================================================
:UninstallMsiByName
REM %~1 = .NET regex matched case-insensitively against installed MSI product names.
REM Replaces "wmic product ... call uninstall" (WMIC is not available on Windows 11 24H2+).
set "MSI_NAME_REGEX=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$rx = $env:MSI_NAME_REGEX; $roots = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'; Get-ItemProperty -Path $roots -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and $_.DisplayName -match $rx -and $_.WindowsInstaller -eq 1 -and $_.PSChildName -match '^\{[0-9A-Fa-f-]{36}\}$' } | Sort-Object PSChildName -Unique | ForEach-Object { $proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/x', $_.PSChildName, '/qn', '/norestart') -Wait -PassThru; if (@(0,1641,3010) -contains $proc.ExitCode) { Write-Host ('        Uninstalled: ' + $_.DisplayName) } else { Write-Host ('        Could not uninstall: ' + $_.DisplayName + ' [msiexec exit ' + $proc.ExitCode + ']') -ForegroundColor Yellow } }"
exit /b 0
