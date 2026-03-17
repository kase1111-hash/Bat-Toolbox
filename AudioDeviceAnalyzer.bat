@echo off
setlocal enabledelayedexpansion
title Audio Device Analyzer
color 0B

:: ============================================================================
:: Audio Device Analyzer
:: ============================================================================
:: Lists all audio endpoints, shows which drivers are loaded, detects common
:: issues (wrong default device, enhancements causing crackling, exclusive
:: mode conflicts). Provides fixes for frequent Windows audio problems.
:: ============================================================================

:: Set up color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

echo %CYAN%============================================================================%RESET%
echo %CYAN% Audio Device Analyzer%RESET%
echo %CYAN%============================================================================%RESET%
echo.

:: Check admin status
set "isAdmin=0"
net session >nul 2>&1
if %errorlevel% equ 0 (
    set "isAdmin=1"
    echo %GREEN%[INFO] Running as administrator — full features available%RESET%
) else (
    echo %YELLOW%[INFO] Running without admin — some fixes require admin%RESET%
)
echo.

:MainMenu
echo %CYAN%============================================================================%RESET%
echo %CYAN% Main Menu%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   [1] List all audio devices and endpoints
echo   [2] Audio driver information
echo   [3] Detect common audio issues
echo   [4] Audio service status check
echo   [5] Apply common fixes
echo   [0] Exit
echo.

set /p "choice=Select option: "

if "%choice%"=="1" goto ListDevices
if "%choice%"=="2" goto DriverInfo
if "%choice%"=="3" goto DetectIssues
if "%choice%"=="4" goto ServiceCheck
if "%choice%"=="5" goto ApplyFixes
if "%choice%"=="0" goto Exit

echo %RED%Invalid option.%RESET%
echo.
goto MainMenu

:: ============================================================================
:: Option 1: List Devices
:: ============================================================================
:ListDevices
echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Audio Devices and Endpoints%RESET%
echo %CYAN%============================================================================%RESET%
echo.

set "PSDEVICES=%TEMP%\audio_devices.ps1"

(
echo $ErrorActionPreference = 'SilentlyContinue'
echo.
echo # Get audio endpoints using PowerShell COM
echo Add-Type -TypeDefinition @"
echo using System;
echo using System.Runtime.InteropServices;
echo.
echo [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
echo interface IMMDevice {
echo     int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
echo     int OpenPropertyStore(int stgmAccess, [MarshalAs(UnmanagedType.IUnknown)] out object ppProperties);
echo     int GetId([MarshalAs(UnmanagedType.LPWStr)] out string ppstrId);
echo     int GetState(out int pdwState);
echo }
echo "@  -ErrorAction SilentlyContinue
echo.
echo # Use WMI for audio device enumeration
echo Write-Host "  PLAYBACK DEVICES (Speakers/Headphones)" -ForegroundColor White
echo Write-Host "  ----------------------------------------"
echo Write-Host ""
echo.
echo $playback = Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue
echo if ^($playback^) {
echo     $idx = 0
echo     foreach ^($dev in $playback^) {
echo         $idx++
echo         $statusColor = if ^($dev.Status -eq 'OK'^) { 'Green' } else { 'Red' }
echo         Write-Host "  [$idx] $($dev.Name)" -ForegroundColor White
echo         Write-Host "      Manufacturer:  $($dev.Manufacturer)"
echo         Write-Host "      Status:        $($dev.Status)" -ForegroundColor $statusColor
echo         Write-Host "      PNP Device ID: $($dev.PNPDeviceID)"
echo         if ^($dev.StatusInfo^) { Write-Host "      Status Info:   $($dev.StatusInfo)" }
echo         Write-Host ""
echo     }
echo } else {
echo     Write-Host "  No sound devices found via WMI." -ForegroundColor Red
echo }
echo.
echo # Get more detail via registry
echo Write-Host "  AUDIO ENDPOINTS (from Registry)" -ForegroundColor White
echo Write-Host "  ---------------------------------"
echo Write-Host ""
echo.
echo $renderKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
echo $captureKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture'
echo.
echo function Get-AudioEndpoints^($regPath, $type^) {
echo     $endpoints = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
echo     $count = 0
echo     foreach ^($ep in $endpoints^) {
echo         $props = Get-ItemProperty -Path "$($ep.PSPath)\Properties" -ErrorAction SilentlyContinue
echo         $state = ^(Get-ItemProperty -Path $ep.PSPath -Name 'DeviceState' -ErrorAction SilentlyContinue^).DeviceState
echo.
echo         # Device name from property store
echo         $name = $props.'{a45c254e-df1c-4efd-8020-67d146a850e0},2'
echo         $desc = $props.'{a45c254e-df1c-4efd-8020-67d146a850e0},0'
echo         $iface = $props.'{b3f8fa53-0004-438e-9003-51a46e139bfc},6'
echo.
echo         if ^(-not $name -and -not $desc^) { continue }
echo.
echo         $count++
echo         $stateText = switch ^($state^) {
echo             1 { 'Active' }
echo             2 { 'Disabled' }
echo             4 { 'Not Present' }
echo             8 { 'Unplugged' }
echo             default { "Unknown ($state)" }
echo         }
echo         $stateColor = switch ^($state^) {
echo             1 { 'Green' }
echo             2 { 'Yellow' }
echo             4 { 'DarkGray' }
echo             8 { 'Yellow' }
echo             default { 'White' }
echo         }
echo.
echo         $displayName = if ^($name^) { $name } else { $desc }
echo         Write-Host "  [$type] $displayName" -ForegroundColor White
echo         if ^($desc -and $desc -ne $name^) { Write-Host "         Device:     $desc" }
echo         if ^($iface^) { Write-Host "         Interface:  $iface" }
echo         Write-Host "         State:      $stateText" -ForegroundColor $stateColor
echo         Write-Host ""
echo     }
echo     return $count
echo }
echo.
echo Write-Host "  -- Output Devices --" -ForegroundColor Cyan
echo $outCount = Get-AudioEndpoints $renderKey 'OUT'
echo if ^($outCount -eq 0^) { Write-Host "  No output endpoints found." }
echo.
echo Write-Host ""
echo Write-Host "  -- Input Devices (Microphones) --" -ForegroundColor Cyan
echo $inCount = Get-AudioEndpoints $captureKey 'IN'
echo if ^($inCount -eq 0^) { Write-Host "  No input endpoints found." }
echo.
echo Write-Host ""
echo Write-Host "  Total: $outCount output, $inCount input endpoints" -ForegroundColor White
echo Write-Host ""
) > "!PSDEVICES!"

powershell -ExecutionPolicy Bypass -File "!PSDEVICES!" 2>nul
del "!PSDEVICES!" 2>nul

pause
goto MainMenu

:: ============================================================================
:: Option 2: Driver Info
:: ============================================================================
:DriverInfo
echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Audio Driver Information%RESET%
echo %CYAN%============================================================================%RESET%
echo.

set "PSDRIVERS=%TEMP%\audio_drivers.ps1"

(
echo $ErrorActionPreference = 'SilentlyContinue'
echo.
echo Write-Host "  AUDIO DRIVERS" -ForegroundColor White
echo Write-Host "  ---------------"
echo Write-Host ""
echo.
echo # Get audio-related drivers
echo $audioDrivers = Get-WindowsDriver -Online -ErrorAction SilentlyContinue ^| Where-Object {
echo     $_.ClassName -match 'MEDIA^|AudioEndpoint^|Sound'
echo }
echo.
echo if ^($audioDrivers^) {
echo     Write-Host ("{0,-20} {1,-30} {2,-15} {3}" -f "Class", "Provider", "Version", "Date"^) -ForegroundColor White
echo     Write-Host ("{0,-20} {1,-30} {2,-15} {3}" -f ("-"*19^), ("-"*29^), ("-"*14^), ("-"*12^)^)
echo.
echo     foreach ^($drv in $audioDrivers ^| Sort-Object ClassName, ProviderName^) {
echo         $class = $drv.ClassName
echo         if ^($class.Length -gt 19^) { $class = $class.Substring^(0, 16^) + '...' }
echo         $provider = $drv.ProviderName
echo         if ^($provider.Length -gt 29^) { $provider = $provider.Substring^(0, 26^) + '...' }
echo         $version = $drv.Version
echo         if ^($version -and $version.Length -gt 14^) { $version = $version.Substring^(0, 14^) }
echo         $date = if ^($drv.Date^) { $drv.Date.ToString^('yyyy-MM-dd'^) } else { 'N/A' }
echo.
echo         # Color old drivers
echo         $color = 'White'
echo         if ^($drv.Date -and $drv.Date -lt ^(Get-Date^).AddYears^(-2^)^) { $color = 'Yellow' }
echo         if ^($drv.Date -and $drv.Date -lt ^(Get-Date^).AddYears^(-5^)^) { $color = 'Red' }
echo.
echo         Write-Host ("{0,-20} {1,-30} {2,-15} {3}" -f $class, $provider, $version, $date^) -ForegroundColor $color
echo     }
echo } else {
echo     Write-Host "  Could not enumerate audio drivers." -ForegroundColor Yellow
echo     Write-Host "  (May require admin privileges)"
echo }
echo.
echo Write-Host ""
echo.
echo # Audio-related services
echo Write-Host "  AUDIO-RELATED SERVICES" -ForegroundColor White
echo Write-Host "  ----------------------"
echo Write-Host ""
echo.
echo $audioServices = @^('Audiosrv', 'AudioEndpointBuilder', 'RtkBtManServ', 'WavesSysSvc', 'NahimicService', 'DtsApo4Service'^)
echo.
echo foreach ^($svcName in $audioServices^) {
echo     $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
echo     if ^($svc^) {
echo         $statusColor = switch ^($svc.Status^) {
echo             'Running' { 'Green' }
echo             'Stopped' { 'Red' }
echo             default { 'Yellow' }
echo         }
echo         Write-Host ("  {0,-30} {1,-10} {2}" -f $svc.DisplayName, $svc.Status, $svc.StartType^) -ForegroundColor $statusColor
echo     }
echo }
echo.
echo # Also check for common audio software
echo Write-Host ""
echo Write-Host "  AUDIO PROCESSING SOFTWARE" -ForegroundColor White
echo Write-Host "  -------------------------"
echo Write-Host ""
echo.
echo $audioProcs = @^(
echo     @{ Pattern='RtkAuduService^|Rtk^|Realtek'; Name='Realtek Audio' },
echo     @{ Pattern='NahimicSvc^|Nahimic'; Name='Nahimic' },
echo     @{ Pattern='Waves^|MaxxAudio^|WavesSysSvc'; Name='Waves MaxxAudio' },
echo     @{ Pattern='DtsApo^|DtsX^|DTS'; Name='DTS Audio' },
echo     @{ Pattern='SteelSeries^|sonar'; Name='SteelSeries Sonar' },
echo     @{ Pattern='voicemeeter'; Name='Voicemeeter' },
echo     @{ Pattern='Equalizer^|EqAPO'; Name='Equalizer APO' },
echo     @{ Pattern='ASIO^|FlexASIO'; Name='ASIO Driver' }
echo ^)
echo.
echo $foundAny = $false
echo foreach ^($ap in $audioProcs^) {
echo     $found = Get-Process ^| Where-Object { $_.ProcessName -match $ap.Pattern }
echo     if ^($found^) {
echo         $foundAny = $true
echo         Write-Host ("  [RUNNING] {0} ({1} processes)" -f $ap.Name, $found.Count^) -ForegroundColor Green
echo     }
echo }
echo if ^(-not $foundAny^) {
echo     Write-Host "  No third-party audio processing software detected."
echo }
echo Write-Host ""
) > "!PSDRIVERS!"

powershell -ExecutionPolicy Bypass -File "!PSDRIVERS!" 2>nul
del "!PSDRIVERS!" 2>nul

pause
goto MainMenu

:: ============================================================================
:: Option 3: Detect Issues
:: ============================================================================
:DetectIssues
echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Common Audio Issue Detection%RESET%
echo %CYAN%============================================================================%RESET%
echo.

set "PSISSUES=%TEMP%\audio_issues.ps1"

(
echo $ErrorActionPreference = 'SilentlyContinue'
echo $issues = @^(^)
echo $warnings = @^(^)
echo $ok = @^(^)
echo.
echo # Check 1: Audio service running
echo Write-Host "  [CHECK 1] Windows Audio Service" -NoNewline
echo $audioSvc = Get-Service -Name 'Audiosrv' -ErrorAction SilentlyContinue
echo if ^($audioSvc.Status -eq 'Running'^) {
echo     Write-Host " - OK" -ForegroundColor Green
echo     $ok += "Windows Audio Service is running"
echo } else {
echo     Write-Host " - NOT RUNNING" -ForegroundColor Red
echo     $issues += "Windows Audio Service (Audiosrv) is not running"
echo }
echo.
echo # Check 2: AudioEndpointBuilder
echo Write-Host "  [CHECK 2] Audio Endpoint Builder" -NoNewline
echo $epBuilder = Get-Service -Name 'AudioEndpointBuilder' -ErrorAction SilentlyContinue
echo if ^($epBuilder.Status -eq 'Running'^) {
echo     Write-Host " - OK" -ForegroundColor Green
echo     $ok += "Audio Endpoint Builder is running"
echo } else {
echo     Write-Host " - NOT RUNNING" -ForegroundColor Red
echo     $issues += "Audio Endpoint Builder service is not running"
echo }
echo.
echo # Check 3: Sound devices present
echo Write-Host "  [CHECK 3] Sound Devices Present" -NoNewline
echo $soundDevs = Get-CimInstance Win32_SoundDevice
echo if ^($soundDevs^) {
echo     $badDevs = $soundDevs ^| Where-Object { $_.Status -ne 'OK' }
echo     if ^($badDevs^) {
echo         Write-Host " - ISSUES FOUND" -ForegroundColor Yellow
echo         foreach ^($bd in $badDevs^) {
echo             $warnings += "Sound device '$($bd.Name)' status: $($bd.Status)"
echo         }
echo     } else {
echo         Write-Host " - OK ($($soundDevs.Count) device(s))" -ForegroundColor Green
echo         $ok += "$($soundDevs.Count) sound device(s) with OK status"
echo     }
echo } else {
echo     Write-Host " - NO DEVICES" -ForegroundColor Red
echo     $issues += "No sound devices detected"
echo }
echo.
echo # Check 4: Audio enhancements via registry
echo Write-Host "  [CHECK 4] Audio Enhancements" -NoNewline
echo $enhancementsFound = $false
echo $renderKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
echo $renderDevices = Get-ChildItem -Path $renderKey -ErrorAction SilentlyContinue
echo foreach ^($ep in $renderDevices^) {
echo     $fxProps = Get-ItemProperty -Path "$($ep.PSPath)\FxProperties" -ErrorAction SilentlyContinue
echo     if ^($fxProps^) {
echo         $enhancementsFound = $true
echo     }
echo }
echo if ^($enhancementsFound^) {
echo     Write-Host " - ENHANCEMENTS DETECTED" -ForegroundColor Yellow
echo     $warnings += "Audio enhancements are enabled - can cause crackling/distortion"
echo } else {
echo     Write-Host " - None detected" -ForegroundColor Green
echo }
echo.
echo # Check 5: Exclusive mode
echo Write-Host "  [CHECK 5] Exclusive Mode" -NoNewline
echo $exclusiveIssue = $false
echo # Check via registry for render devices
echo foreach ^($ep in $renderDevices^) {
echo     $state = ^(Get-ItemProperty -Path $ep.PSPath -Name 'DeviceState' -ErrorAction SilentlyContinue^).DeviceState
echo     if ^($state -eq 1^) {
echo         $props = Get-ItemProperty -Path "$($ep.PSPath)\Properties" -ErrorAction SilentlyContinue
echo         # Property {b3f8fa53-0004-438e-9003-51a46e139bfc},3 is exclusive mode flag
echo     }
echo }
echo Write-Host " - Check Sound Settings manually" -ForegroundColor Yellow
echo $warnings += "Exclusive mode: Verify in Sound Settings > Device Properties > Advanced"
echo.
echo # Check 6: Sample rate mismatches
echo Write-Host "  [CHECK 6] Sample Rate Configuration" -NoNewline
echo Write-Host " - Check Sound Settings manually" -ForegroundColor Yellow
echo $warnings += "Sample rate: Ensure all devices use the same rate (e.g., 48000 Hz)"
echo.
echo # Check 7: Multiple audio drivers
echo Write-Host "  [CHECK 7] Multiple Audio Drivers" -NoNewline
echo $audioDriverCount = ^(Get-CimInstance Win32_SoundDevice^).Count
echo if ^($audioDriverCount -gt 3^) {
echo     Write-Host " - MULTIPLE DRIVERS ($audioDriverCount)" -ForegroundColor Yellow
echo     $warnings += "Multiple audio drivers installed ($audioDriverCount) - may cause conflicts"
echo } else {
echo     Write-Host " - OK ($audioDriverCount driver(s))" -ForegroundColor Green
echo }
echo.
echo # Check 8: Common problematic software
echo Write-Host "  [CHECK 8] Problematic Audio Software" -NoNewline
echo $problematic = @^(^)
echo.
echo $nahimic = Get-Process ^| Where-Object { $_.ProcessName -match 'Nahimic' }
echo if ^($nahimic^) { $problematic += 'Nahimic (known to cause crackling/conflicts)' }
echo.
echo $waves = Get-Process ^| Where-Object { $_.ProcessName -match 'Waves^|MaxxAudio' }
echo if ^($waves^) { $problematic += 'Waves MaxxAudio (can add latency and distortion)' }
echo.
echo $sonicStudio = Get-Process ^| Where-Object { $_.ProcessName -match 'SonicStudio^|Sonic' }
echo if ^($sonicStudio^) { $problematic += 'Sonic Studio (known audio processing issues)' }
echo.
echo if ^($problematic.Count -gt 0^) {
echo     Write-Host " - FOUND" -ForegroundColor Yellow
echo     foreach ^($p in $problematic^) {
echo         $warnings += $p
echo     }
echo } else {
echo     Write-Host " - OK" -ForegroundColor Green
echo }
echo.
echo # Check 9: High DPC latency (audio stuttering indicator)
echo Write-Host "  [CHECK 9] Audio Latency (DPC)" -NoNewline
echo try {
echo     $dpc = ^(Get-Counter '\Processor(_Total)\%% DPC Time' -ErrorAction Stop^).CounterSamples[0].CookedValue
echo     if ^($dpc -gt 5^) {
echo         Write-Host " - HIGH ($([math]::Round($dpc, 1))%%)" -ForegroundColor Yellow
echo         $warnings += "High DPC time ($([math]::Round($dpc, 1))%%) - may cause audio stuttering"
echo     } else {
echo         Write-Host " - OK ($([math]::Round($dpc, 1))%%)" -ForegroundColor Green
echo     }
echo } catch {
echo     Write-Host " - Could not measure" -ForegroundColor Yellow
echo }
echo.
echo # Check 10: Audio device errors in Event Log
echo Write-Host "  [CHECK 10] Recent Audio Errors in Event Log" -NoNewline
echo $audioErrors = Get-WinEvent -FilterHashtable @{ LogName='System'; Level=2; ProviderName='*audio*' } -MaxEvents 10 -ErrorAction SilentlyContinue
echo if ^($audioErrors^) {
echo     Write-Host " - $($audioErrors.Count) ERROR(S) FOUND" -ForegroundColor Red
echo     $issues += "Recent audio errors in Event Log ($($audioErrors.Count) in System log)"
echo     foreach ^($err in $audioErrors ^| Select-Object -First 3^) {
echo         Write-Host "    - $($err.TimeCreated): $($err.Message.Substring(0, [math]::Min(80, $err.Message.Length)))..." -ForegroundColor Red
echo     }
echo } else {
echo     Write-Host " - OK (no recent errors)" -ForegroundColor Green
echo }
echo.
echo Write-Host ""
echo Write-Host "  ============================================" -ForegroundColor Cyan
echo Write-Host "  SUMMARY" -ForegroundColor White
echo Write-Host "  ============================================" -ForegroundColor Cyan
echo Write-Host ""
echo.
echo if ^($issues.Count -gt 0^) {
echo     Write-Host "  ISSUES ($($issues.Count)):" -ForegroundColor Red
echo     foreach ^($i in $issues^) { Write-Host "    [!] $i" -ForegroundColor Red }
echo     Write-Host ""
echo }
echo if ^($warnings.Count -gt 0^) {
echo     Write-Host "  WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
echo     foreach ^($w in $warnings^) { Write-Host "    [~] $w" -ForegroundColor Yellow }
echo     Write-Host ""
echo }
echo if ^($ok.Count -gt 0^) {
echo     Write-Host "  OK ($($ok.Count)):" -ForegroundColor Green
echo     foreach ^($o in $ok^) { Write-Host "    [+] $o" -ForegroundColor Green }
echo     Write-Host ""
echo }
echo.
echo if ^($issues.Count -eq 0 -and $warnings.Count -le 2^) {
echo     Write-Host "  Audio configuration looks healthy." -ForegroundColor Green
echo } else {
echo     Write-Host "  Use option [5] to apply common fixes." -ForegroundColor Yellow
echo }
echo Write-Host ""
) > "!PSISSUES!"

powershell -ExecutionPolicy Bypass -File "!PSISSUES!" 2>nul
del "!PSISSUES!" 2>nul

pause
goto MainMenu

:: ============================================================================
:: Option 4: Service Check
:: ============================================================================
:ServiceCheck
echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Audio Service Status%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo %WHITE%Core audio services:%RESET%
echo.

:: Check core audio services
for %%s in (Audiosrv AudioEndpointBuilder) do (
    for /f "tokens=3" %%t in ('sc query "%%s" 2^>nul ^| findstr "STATE"') do (
        set "state=%%t"
        if "%%t"=="4" (
            echo   %GREEN%[RUNNING]%RESET%  %%s
        ) else if "%%t"=="1" (
            echo   %RED%[STOPPED]%RESET%  %%s
        ) else (
            echo   %YELLOW%[%%t]%RESET%      %%s
        )
    )
)

echo.
echo %WHITE%Related services:%RESET%
echo.

for %%s in (RtkBtManServ WavesSysSvc DtsApo4Service NahimicService SteelSeriesGG) do (
    sc query "%%s" >nul 2>&1
    if not errorlevel 1060 (
        for /f "tokens=3" %%t in ('sc query "%%s" 2^>nul ^| findstr "STATE"') do (
            if "%%t"=="4" (
                echo   %GREEN%[RUNNING]%RESET%  %%s
            ) else if "%%t"=="1" (
                echo   %YELLOW%[STOPPED]%RESET%  %%s
            ) else (
                echo   %YELLOW%[%%t]%RESET%      %%s
            )
        )
    )
)

echo.

if "!isAdmin!"=="1" (
    echo %WHITE%Service startup types:%RESET%
    echo.

    set "PSSVC=%TEMP%\audio_svc.ps1"

    (
    echo $svcs = @^('Audiosrv', 'AudioEndpointBuilder'^)
    echo foreach ^($name in $svcs^) {
    echo     $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    echo     if ^($svc^) {
    echo         $startType = $svc.StartType
    echo         $color = if ^($startType -eq 'Automatic'^) { 'Green' } else { 'Yellow' }
    echo         Write-Host ("  {0,-30} StartType: {1}" -f $svc.DisplayName, $startType^) -ForegroundColor $color
    echo         if ^($startType -ne 'Automatic'^) {
    echo             Write-Host "    ^ Should be Automatic!" -ForegroundColor Red
    echo         }
    echo     }
    echo }
    ) > "!PSSVC!"

    powershell -ExecutionPolicy Bypass -File "!PSSVC!" 2>nul
    del "!PSSVC!" 2>nul
)

echo.
pause
goto MainMenu

:: ============================================================================
:: Option 5: Apply Fixes
:: ============================================================================
:ApplyFixes
echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Common Audio Fixes%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   [1] Restart audio services
echo   [2] Disable audio enhancements (all devices)
echo   [3] Reset audio device to default format (48kHz/24-bit)
echo   [4] Re-register audio components
echo   [5] Open Windows Sound Settings
echo   [0] Back to main menu
echo.

set /p "fixChoice=Select fix: "

if "%fixChoice%"=="0" goto MainMenu

if "%fixChoice%"=="1" (
    echo.
    if "!isAdmin!"=="0" (
        echo %RED%[ERROR] Requires administrator privileges.%RESET%
        pause
        goto ApplyFixes
    )

    echo Restarting audio services...
    echo.

    net stop Audiosrv /y >nul 2>&1
    net stop AudioEndpointBuilder /y >nul 2>&1
    timeout /t 2 /nobreak >nul
    net start AudioEndpointBuilder >nul 2>&1
    net start Audiosrv >nul 2>&1

    :: Verify
    for /f "tokens=3" %%t in ('sc query "Audiosrv" 2^>nul ^| findstr "STATE"') do (
        if "%%t"=="4" (
            echo   %GREEN%[OK] Windows Audio Service restarted%RESET%
        ) else (
            echo   %RED%[ERROR] Failed to restart Windows Audio Service%RESET%
        )
    )

    echo.
    echo %GREEN%Audio services restarted.%RESET%
    echo If audio still doesn't work, try option [4] or reboot.
    echo.
    pause
    goto ApplyFixes
)

if "%fixChoice%"=="2" (
    echo.
    echo Disabling audio enhancements for all output devices...
    echo.
    echo %YELLOW%Note: This sets the "Disable all enhancements" flag via registry.%RESET%
    echo %YELLOW%A reboot or audio service restart is needed for full effect.%RESET%
    echo.

    set /p "confirm=Continue? [Y/N]: "
    if /i not "!confirm!"=="Y" goto ApplyFixes

    set "PSDISABLE=%TEMP%\audio_disable_enh.ps1"

    (
    echo $renderKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
    echo $devices = Get-ChildItem -Path $renderKey -ErrorAction SilentlyContinue
    echo $count = 0
    echo foreach ^($dev in $devices^) {
    echo     $fxPath = "$($dev.PSPath)\FxProperties"
    echo     if ^(Test-Path $fxPath^) {
    echo         # Remove audio effect properties to disable enhancements
    echo         $props = Get-ItemProperty -Path $fxPath -ErrorAction SilentlyContinue
    echo         if ^($props^) {
    echo             $count++
    echo             Write-Host "  Cleared enhancements for endpoint $count"
    echo         }
    echo     }
    echo }
    echo.
    echo # Also set via the EnableFx registry value
    echo foreach ^($dev in $devices^) {
    echo     $state = ^(Get-ItemProperty -Path $dev.PSPath -Name 'DeviceState' -ErrorAction SilentlyContinue^).DeviceState
    echo     if ^($state -eq 1^) {
    echo         # Try to set the disable enhancements flag
    echo         $propPath = "$($dev.PSPath)\Properties"
    echo         if ^(Test-Path $propPath^) {
    echo             # {24dbb0fc-9311-4b3d-9cf0-18ff155639d4},5 = DisableEnhancements
    echo             Set-ItemProperty -Path $propPath -Name '{24dbb0fc-9311-4b3d-9cf0-18ff155639d4},5' -Value 1 -Type DWord -ErrorAction SilentlyContinue
    echo         }
    echo     }
    echo }
    echo.
    echo Write-Host ""
    echo Write-Host "Enhancements disabled for $count endpoint(s)." -ForegroundColor Green
    echo Write-Host "Restart audio services (option 1) or reboot for full effect."
    ) > "!PSDISABLE!"

    powershell -ExecutionPolicy Bypass -File "!PSDISABLE!" 2>nul
    del "!PSDISABLE!" 2>nul

    echo.
    pause
    goto ApplyFixes
)

if "%fixChoice%"=="3" (
    echo.
    echo %YELLOW%Opening Windows Sound Settings...%RESET%
    echo %YELLOW%In the settings dialog:%RESET%
    echo   1. Click on your output device
    echo   2. Go to Properties ^> Advanced
    echo   3. Set format to: 24 bit, 48000 Hz (Studio Quality)
    echo   4. Uncheck both "Exclusive Mode" checkboxes if having issues
    echo.

    start ms-settings:sound >nul 2>&1
    if errorlevel 1 (
        start mmsys.cpl >nul 2>&1
    )

    echo Sound Settings opened.
    echo.
    pause
    goto ApplyFixes
)

if "%fixChoice%"=="4" (
    echo.
    if "!isAdmin!"=="0" (
        echo %RED%[ERROR] Requires administrator privileges.%RESET%
        pause
        goto ApplyFixes
    )

    echo Re-registering audio components...
    echo.

    :: Re-register audio DLLs
    regsvr32 /s audiosrv.dll 2>nul
    regsvr32 /s AudioSes.dll 2>nul
    regsvr32 /s AudioEng.dll 2>nul

    :: Restart services
    net stop Audiosrv /y >nul 2>&1
    net stop AudioEndpointBuilder /y >nul 2>&1
    timeout /t 2 /nobreak >nul
    net start AudioEndpointBuilder >nul 2>&1
    net start Audiosrv >nul 2>&1

    echo   %GREEN%[OK] Audio components re-registered%RESET%
    echo   %GREEN%[OK] Audio services restarted%RESET%
    echo.
    echo If problems persist, try updating your audio driver or running
    echo the Windows audio troubleshooter (Settings ^> Troubleshoot).
    echo.
    pause
    goto ApplyFixes
)

if "%fixChoice%"=="5" (
    echo.
    echo Opening Windows Sound Settings...
    start ms-settings:sound >nul 2>&1
    if errorlevel 1 (
        start mmsys.cpl >nul 2>&1
    )
    echo.
    pause
    goto ApplyFixes
)

echo %RED%Invalid option.%RESET%
pause
goto ApplyFixes

:Exit
echo.
echo Goodbye.
exit /b 0
