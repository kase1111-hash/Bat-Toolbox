@echo off
setlocal enabledelayedexpansion
title Realtek Audio Bloatware Remover
color 0B

:: ============================================================================
:: Realtek Audio Bloatware Remover
:: ============================================================================
:: Removes Realtek Audio Console, Nahimic, and A-Volute bloatware that ships
:: bundled with Realtek audio drivers. These are notorious for audio conflicts,
:: unnecessary resource usage, and phantom audio processing.
:: The core Realtek HD Audio driver remains intact.
:: ============================================================================

:: Set up color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "RESET=%ESC%[0m"

echo %CYAN%============================================================================%RESET%
echo %CYAN% Realtek Audio Bloatware Remover%RESET%
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

echo This script removes Realtek audio bloatware while keeping the core driver.
echo/
echo %YELLOW%What will be REMOVED:%RESET%
echo  - Realtek Audio Console (UWP app)
echo  - Nahimic / Nahimic Companion (audio effects engine)
echo  - A-Volute / Sonic Studio virtual audio (spatial audio bloat)
echo  - Realtek HD Audio Universal Service (app service, not the driver)
echo  - Waves MaxxAudio / DTS Audio Processing apps and services (if bundled by Dell/HP/Lenovo)
echo  - Related scheduled tasks and startup entries
echo/
echo %GREEN%What will be KEPT:%RESET%
echo  - Realtek HD Audio driver (core audio functionality)
echo  - Windows audio service (AudioSrv / AudioEndpointBuilder)
echo  - All audio devices and endpoints
echo  - Your audio will continue to work normally
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

set "success=0"

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 1: Stopping Processes and Services%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [1/7] Terminating bloatware processes...

for %%P in (
    "RtkAudioUniversalService.exe"
    "RAVCpl64.exe"
    "RtkNGUI64.exe"
    "RTCOM64.exe"
    "RtkAudUService64.exe"
    "Nahimic3.exe"
    "NahimicService.exe"
    "NahimicSvc32.exe"
    "NahimicSvc64.exe"
    "NahimicNotifier.exe"
    "NahimicCompanion.exe"
    "NahimicMSIUILauncher.exe"
    "A-Volute.Nahimic.Svc.exe"
    "A-Volute.SonicStudio.Svc.exe"
    "A-Volute.SpatialSound.Svc.exe"
    "SonicStudio3.exe"
    "SonicRadar3.exe"
    "AVoluteService.exe"
    "DtsApo4Service.exe"
    "MaxxAudioPro.exe"
    "WavesMaxxAudio.exe"
    "WavesSysSvc64.exe"
    "WavesSvc64.exe"
) do (
    taskkill /f /im %%P >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%- Terminated %%~P%RESET%
    )
)
echo       %GREEN%- Process termination complete%RESET%
set /a success+=1

:: Stop and disable bloatware services
echo/
echo [2/7] Stopping and disabling audio bloatware services...

for %%S in (
    "RtkAudioUniversalService"
    "RtkAudUService64"
    "NahimicService"
    "A-VolUteSvc"
    "A-Volute.Nahimic.Svc"
    "A-Volute.SonicStudio.Svc"
    "A-Volute.SpatialSound.Svc"
    "WavesSysSvc"
    "WavesSysSvc64"
    "MaxxAudioPro"
    "DtsApo4Service"
    "NahimicSvc32"
    "NahimicSvc64"
) do (
    sc query %%S >nul 2>&1
    if not errorlevel 1060 (
        sc stop %%S >nul 2>&1
        sc config %%S start= disabled >nul 2>&1
        echo       %GREEN%- Disabled service: %%~S%RESET%
        set /a success+=1
    )
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 2: Removing Nahimic / A-Volute Software%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [3/7] Removing Nahimic and A-Volute AppX packages...

:: Create PowerShell script for AppX removal
set "PSSCRIPT=%TEMP%\remove-realtek-bloat.ps1"

(
echo $packages = @^(
echo     '*Nahimic*',
echo     '*A-Volute*',
echo     '*RealtekAudioConsole*',
echo     '*RealtekAudioControl*',
echo     '*Realtek.USB.Audio*',
echo     '*SonicStudio*',
echo     '*SonicRadar*'
echo ^)
echo/
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
set /a success+=1

echo/
echo [4/7] Removing desktop (MSI) applications...

:: Nahimic removal
echo       - Checking Nahimic...
call :UninstallMsiByName "Nahimic|A-Volute"

:: Realtek Audio Console removal (desktop version)
echo       - Checking Realtek Audio Console...
call :UninstallMsiByName "Realtek Audio Console|Realtek Audio Control|Realtek Audio Universal Service"

:: Sonic Studio / Radar
echo       - Checking Sonic Studio/Radar...
call :UninstallMsiByName "Sonic Studio|Sonic Radar"

:: Waves MaxxAudio (bundled with some Realtek configs on Dell/HP)
echo       - Checking Waves MaxxAudio...
call :UninstallMsiByName "Waves MaxxAudio|MaxxAudio Pro|WavesNx"

:: DTS Audio
echo       - Checking DTS Audio Processing...
call :UninstallMsiByName "\bDTS Audio|\bDTS Sound"

echo       %GREEN%- Application removal complete%RESET%
set /a success+=1

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 3: Removing Scheduled Tasks%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [5/7] Removing audio bloatware scheduled tasks...

for %%T in (
    "\NahimicTask"
    "\NahimicSvc32"
    "\NahimicSvc64"
    "\A-Volute\Nahimic"
    "\A-Volute\SonicStudio"
    "\Realtek\RtkAudUService"
    "\Realtek\RtkAudioUniversal"
    "\RtkAudUService"
    "\WavesMaxxAudio"
    "\MaxxAudioPro"
) do (
    schtasks /delete /tn "%%~T" /f >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%- Removed task: %%~T%RESET%
        set /a success+=1
    )
)

:: Catch remaining Nahimic/A-Volute tasks via PowerShell
set "PSTASKS=%TEMP%\remove-realtek-tasks.ps1"
(
echo Get-ScheduledTask -ErrorAction SilentlyContinue ^| Where-Object {
echo     $_.TaskName -match 'Nahimic' -or
echo     $_.TaskName -match 'A-Volute' -or
echo     $_.TaskName -match 'SonicStudio' -or
echo     $_.TaskName -match 'MaxxAudio' -or
echo     $_.TaskPath -match '\\A-Volute\\' -or
echo     $_.TaskPath -match '\\Realtek\\'
echo } ^| ForEach-Object {
echo     Write-Host "       - Removing task: $($_.TaskPath)$($_.TaskName)"
echo     Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
echo }
) > "%PSTASKS%"

powershell -ExecutionPolicy Bypass -File "%PSTASKS%" 2>nul
del "%PSTASKS%" 2>nul

echo       %GREEN%- Task cleanup complete%RESET%

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 4: Cleaning Registry%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [6/7] Removing registry entries for audio bloatware...

:: Remove startup entries
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "RtkAudUService" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "RtkNGUI64" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "RTCOM" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "NahimicService" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "NahimicSvc64" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WavesSvc" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "MaxxAudioPro" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "NahimicCompanion" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "NahimicNotifier" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WavesSvc" /f >nul 2>&1

:: Disable Nahimic APO (Audio Processing Object) in the driver chain.
:: FxProperties values hold APO CLSIDs, not vendor names, so each CLSID is
:: resolved to its COM registration (name + DLL path) to find Nahimic's APOs.
:: A value is removed only when it lists nothing but Nahimic APOs (removing a
:: shared effect chain would also drop Realtek's own effects), and success is
:: reported only when Windows actually allowed the delete: the endpoint keys
:: are normally protected (TrustedInstaller), so the APO is often left in place.
echo       - Disabling Nahimic audio processing objects...
set "PSAPO=%TEMP%\disable-nahimic-apo.ps1"
(
echo # Find and disable Nahimic/A-Volute APO entries in the audio endpoint registry
echo $apoPattern = 'Nahimic^|A-Volute^|AVolute^|SonicStudio'
echo $fxPaths = @^(
echo     'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render',
echo     'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture'
echo ^)
echo $found = 0
echo $cleared = 0
echo foreach ^($basePath in $fxPaths^) {
echo     if ^(Test-Path $basePath^) {
echo         Get-ChildItem -Path $basePath -Recurse -ErrorAction SilentlyContinue ^|
echo             Where-Object { $_.Name -match 'FxProperties' } ^| ForEach-Object {
echo                 $key = $_
echo                 foreach ^($prop in $key.GetValueNames^(^)^) {
echo                     $guids = @^(@^($key.GetValue^($prop^)^) ^| Where-Object { $_ -is [string] -and $_ -match '^^\{[0-9A-Fa-f-]{36}\}$' }^)
echo                     if ^($guids.Count -eq 0^) { continue }
echo                     $apoDlls = @^(^)
echo                     $others = 0
echo                     foreach ^($g in $guids^) {
echo                         $name = [string]^(Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Classes\CLSID\$g" -ErrorAction SilentlyContinue^).'^(default^)'
echo                         $dll = [string]^(Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Classes\CLSID\$g\InprocServer32" -ErrorAction SilentlyContinue^).'^(default^)'
echo                         if ^("$name $dll" -match $apoPattern^) { $apoDlls += [System.IO.Path]::GetFileName^($dll^) } else { $others++ }
echo                     }
echo                     if ^($apoDlls.Count -eq 0^) { continue }
echo                     $found++
echo                     if ^($others -gt 0^) {
echo                         Write-Host "       - Nahimic APO shares $prop with other audio effects; left in place" -ForegroundColor Yellow
echo                         continue
echo                     }
echo                     try {
echo                         Remove-ItemProperty -LiteralPath $key.PSPath -Name $prop -ErrorAction Stop
echo                         $cleared++
echo                         Write-Host "       - Cleared APO entry: $prop ($($apoDlls -join ', '))"
echo                     } catch {
echo                         Write-Host "       - Nahimic APO found in $prop but the key is protected (TrustedInstaller); not removed" -ForegroundColor Yellow
echo                     }
echo                 }
echo             }
echo     }
echo }
echo if ^($found -eq 0^) {
echo     Write-Host '       - No Nahimic/A-Volute APO found on any audio endpoint'
echo } elseif ^($cleared -lt $found^) {
echo     Write-Host "       - Nahimic APO is still active - see RemoveRealtekBloat_README.txt to remove its driver" -ForegroundColor Yellow
echo }
) > "%PSAPO%"

powershell -ExecutionPolicy Bypass -File "%PSAPO%" 2>nul
del "%PSAPO%" 2>nul

echo       %GREEN%- Registry cleanup complete%RESET%
set /a success+=1

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 5: Cleaning Leftover Files%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [7/7] Removing leftover folders...

:: Nahimic / A-Volute directories
call :CleanFolder "%ProgramFiles%\Nahimic"
call :CleanFolder "%ProgramFiles(x86)%\Nahimic"
call :CleanFolder "%ProgramFiles%\A-Volute"
call :CleanFolder "%ProgramFiles(x86)%\A-Volute"
call :CleanFolder "%ProgramFiles%\Sonic Studio 3"
call :CleanFolder "%ProgramFiles(x86)%\Sonic Studio 3"
call :CleanFolder "%ProgramFiles%\Sonic Radar 3"
call :CleanFolder "%ProgramFiles(x86)%\Sonic Radar 3"

:: Realtek Audio Console / bloatware app data (NOT the driver)
call :CleanFolder "%ProgramData%\Nahimic"
call :CleanFolder "%ProgramData%\A-Volute"
call :CleanFolder "%LocalAppData%\Nahimic"
call :CleanFolder "%LocalAppData%\A-Volute"
call :CleanFolder "%LocalAppData%\Packages\RealtekSemiconductorCorp.RealtekAudioControl_dt26b99r8h8gj"
call :CleanFolder "%LocalAppData%\Packages\AppUp.RealtekAudioConsole_dt26b99r8h8gj"

:: Waves MaxxAudio leftovers
call :CleanFolder "%ProgramFiles%\Waves\MaxxAudio"
call :CleanFolder "%ProgramFiles(x86)%\Waves\MaxxAudio"
call :CleanFolder "%ProgramData%\Waves"

echo       %GREEN%- File cleanup complete%RESET%

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Summary%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo %GREEN%Removal process complete^^!%RESET%
echo Successful operations: %success%
echo/
echo What was removed:
echo  - Realtek Audio Console (UWP app layer)
echo  - Nahimic / A-Volute audio effects engine
echo  - Sonic Studio / Sonic Radar
echo  - Waves MaxxAudio / DTS Audio Processing (if present)
echo  - Audio bloatware services and scheduled tasks
echo  - Startup entries, plus Nahimic APO entries Windows allowed to be removed (see Phase 4)
echo/
echo What remains intact:
echo  - Realtek HD Audio driver (core audio)
echo  - Windows Audio Service
echo  - All audio devices and endpoints
echo  - System sounds and volume controls
echo/
echo %YELLOW%NOTE: If audio sounds "flat" after removal, that is the clean unprocessed%RESET%
echo %YELLOW%      output. Windows built-in spatial sound or equalizer can be used instead.%RESET%
echo %YELLOW%      Right-click the speaker icon ^> Sound settings ^> Audio enhancements.%RESET%
echo/
echo %YELLOW%NOTE: After Realtek driver updates, bloatware may be reinstalled.%RESET%
echo %YELLOW%      Run this script again if Nahimic or Audio Console reappears.%RESET%
echo/
echo A reboot is recommended to complete the removal process.
echo/

set "reboot="
set /p "reboot=Would you like to restart now? [Y/N]: "
if /i "%reboot%"=="Y" (
    echo/
    echo Restarting in 10 seconds...
    shutdown /r /t 10 /c "Realtek Audio Bloatware Removal - Restart"
)

echo/
pause
exit /b 0

:: ============================================================================
:: Subroutine: CleanFolder
:: ============================================================================
:CleanFolder
:: No ( ) block here: the folder argument is often "C:\Program Files (x86)\..."
:: and its ")" would close a block early and abort the whole script. RD does
:: not reset ERRORLEVEL on success, so check whether the folder is really gone.
if not exist "%~1\" goto :eof
rd /s /q "%~1" >nul 2>&1
if exist "%~1\" goto :eof
echo       %GREEN%- Removed: %~1%RESET%
set /a success+=1
goto :eof

:: ============================================================================
:: Subroutine: UninstallMsiByName
:: ============================================================================
:UninstallMsiByName
REM %~1 = .NET regex matched case-insensitively against installed MSI product names.
REM Replaces "wmic product ... call uninstall" (WMIC is not available on Windows 11 24H2+).
set "MSI_NAME_REGEX=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$rx = $env:MSI_NAME_REGEX; $roots = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'; Get-ItemProperty -Path $roots -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and $_.DisplayName -match $rx -and $_.PSChildName -match '^\{[0-9A-Fa-f-]{36}\}$' } | Sort-Object PSChildName -Unique | ForEach-Object { $proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/x', $_.PSChildName, '/qn', '/norestart') -Wait -PassThru; Write-Host ('        Uninstalled: ' + $_.DisplayName + ' [exit ' + $proc.ExitCode + ']') }"
exit /b 0
