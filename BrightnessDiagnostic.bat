@echo off
setlocal enabledelayedexpansion
title Brightness Diagnostic Tool
color 0B

:: ============================================================================
:: Brightness Diagnostic Tool
:: ============================================================================
:: Diagnoses and fixes screen brightness issues including:
:: - Auto-dimming problems
:: - Brightness stuck at low levels
:: - Adaptive brightness interference
:: - Power plan dimming settings
:: Also provides gamma boost for brightness beyond Windows limits
:: ============================================================================

:: ANSI color codes for better output
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

:MAIN_MENU
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                    BRIGHTNESS DIAGNOSTIC TOOL%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   %WHITE%[1]%RESET% Run Full Brightness Diagnostic
echo   %WHITE%[2]%RESET% Quick Fix - Disable All Auto-Dimming
echo   %WHITE%[3]%RESET% Set Brightness to Maximum (100%%)
echo   %WHITE%[4]%RESET% Gamma Boost - Go Beyond Windows Limits
echo   %WHITE%[5]%RESET% Reset Display Settings to Default
echo   %WHITE%[6]%RESET% View Current Brightness Info
echo   %WHITE%[7]%RESET% Advanced Options
echo   %WHITE%[0]%RESET% Exit
echo.
echo %CYAN%============================================================================%RESET%
echo.
set /p "choice=Select an option [0-7]: "

if "%choice%"=="1" goto FULL_DIAGNOSTIC
if "%choice%"=="2" goto QUICK_FIX
if "%choice%"=="3" goto SET_MAX_BRIGHTNESS
if "%choice%"=="4" goto GAMMA_BOOST_MENU
if "%choice%"=="5" goto RESET_DISPLAY
if "%choice%"=="6" goto VIEW_BRIGHTNESS
if "%choice%"=="7" goto ADVANCED_MENU
if "%choice%"=="0" goto EXIT
goto MAIN_MENU

:: ============================================================================
:: FULL DIAGNOSTIC
:: ============================================================================
:FULL_DIAGNOSTIC
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                    FULL BRIGHTNESS DIAGNOSTIC%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo %YELLOW%[1/8]%RESET% Checking current brightness level...
echo.
powershell -Command ^
    "$brightness = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue; ^
    if ($brightness) { ^
        Write-Host '  Current Brightness: ' -NoNewline; ^
        Write-Host \"$($brightness.CurrentBrightness)%%\" -ForegroundColor Cyan; ^
        Write-Host '  Brightness Levels Available: ' -NoNewline; ^
        Write-Host ($brightness.Level -join ', ') -ForegroundColor Gray; ^
    } else { ^
        Write-Host '  [WARNING] Cannot read brightness - may be desktop monitor or unsupported display' -ForegroundColor Yellow; ^
    }"
echo.

echo %YELLOW%[2/8]%RESET% Checking display adapters...
echo.
powershell -Command ^
    "$adapters = Get-CimInstance Win32_VideoController; ^
    foreach ($adapter in $adapters) { ^
        Write-Host \"  Display: $($adapter.Name)\" -ForegroundColor White; ^
        Write-Host \"  Driver Version: $($adapter.DriverVersion)\" -ForegroundColor Gray; ^
        Write-Host \"  Status: $($adapter.Status)\" -ForegroundColor $(if($adapter.Status -eq 'OK'){'Green'}else{'Red'}); ^
        Write-Host ''; ^
    }"
echo.

echo %YELLOW%[3/8]%RESET% Checking for Adaptive Brightness...
echo.
powershell -Command ^
    "$service = Get-Service -Name 'SensrSvc' -ErrorAction SilentlyContinue; ^
    if ($service) { ^
        $status = $service.Status; ^
        $color = if($status -eq 'Running'){'Yellow'}else{'Green'}; ^
        Write-Host \"  Sensor Monitoring Service: $status\" -ForegroundColor $color; ^
        if ($status -eq 'Running') { ^
            Write-Host '  [!] This service can cause auto-dimming based on ambient light' -ForegroundColor Yellow; ^
        } ^
    } else { ^
        Write-Host '  Sensor Monitoring Service: Not Found' -ForegroundColor Green; ^
    }"
echo.

:: Check adaptive brightness registry settings
echo %YELLOW%[4/8]%RESET% Checking Adaptive Brightness Registry Settings...
echo.
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdaptiveBrightness\Status" /v IsEnabled 2^>nul ^| findstr /i "IsEnabled"') do (
    if "%%a"=="0x1" (
        echo   %YELLOW%Adaptive Brightness: ENABLED (can cause dimming)%RESET%
    ) else (
        echo   %GREEN%Adaptive Brightness: DISABLED%RESET%
    )
)
echo.

echo %YELLOW%[5/8]%RESET% Checking Power Plan Brightness Settings...
echo.
powershell -Command ^
    "$plans = powercfg /list 2>$null | Select-String 'GUID'; ^
    $activeGuid = (powercfg /getactivescheme 2>$null) -replace '.*GUID: ([a-f0-9-]+).*','$1'; ^
    Write-Host \"  Active Power Plan GUID: $activeGuid\" -ForegroundColor Gray; ^
    Write-Host ''; ^
    Write-Host '  Checking display brightness settings...' -ForegroundColor White; ^
    $dimSettings = powercfg /query $activeGuid 7516b95f-f776-4464-8c53-06167f40cc99 2>$null; ^
    if ($dimSettings -match 'Current AC Power Setting Index:\s*0x([0-9a-fA-F]+)') { ^
        $acDim = [int]('0x' + $matches[1]); ^
        Write-Host \"  Display Dim Brightness (AC): $acDim%%\" -ForegroundColor $(if($acDim -lt 100){'Yellow'}else{'Green'}); ^
    } ^
    if ($dimSettings -match 'Current DC Power Setting Index:\s*0x([0-9a-fA-F]+)') { ^
        $dcDim = [int]('0x' + $matches[1]); ^
        Write-Host \"  Display Dim Brightness (Battery): $dcDim%%\" -ForegroundColor $(if($dcDim -lt 100){'Yellow'}else{'Green'}); ^
    }"
echo.

echo %YELLOW%[6/8]%RESET% Checking for Content Adaptive Brightness Control (CABC)...
echo.
powershell -Command ^
    "$cabc = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'KMD_EnableBrightnessInterface2' -ErrorAction SilentlyContinue; ^
    if ($cabc) { ^
        if ($cabc.KMD_EnableBrightnessInterface2 -eq 1) { ^
            Write-Host '  CABC (Content Adaptive): ENABLED - may cause dimming based on content' -ForegroundColor Yellow; ^
        } else { ^
            Write-Host '  CABC (Content Adaptive): DISABLED' -ForegroundColor Green; ^
        } ^
    } else { ^
        Write-Host '  CABC: Setting not found (GPU may not support it)' -ForegroundColor Gray; ^
    }"
echo.

echo %YELLOW%[7/8]%RESET% Checking Intel/AMD/NVIDIA Display Power Saving...
echo.
:: Intel Display Power Saving Technology (DPST)
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v FeatureTestControl 2^>nul ^| findstr /i "FeatureTestControl"') do (
    echo   Intel DPST Registry Value: %%a
)
powershell -Command ^
    "$dpst = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'DPST_Enabled' -ErrorAction SilentlyContinue; ^
    if ($dpst) { ^
        if ($dpst.DPST_Enabled -eq 1) { ^
            Write-Host '  Intel DPST: ENABLED - causes auto-dimming!' -ForegroundColor Yellow; ^
        } else { ^
            Write-Host '  Intel DPST: DISABLED' -ForegroundColor Green; ^
        } ^
    }"

:: AMD Vari-Bright
powershell -Command ^
    "$variBright = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'PP_VariBrightFeatureControl' -ErrorAction SilentlyContinue; ^
    if ($variBright) { ^
        Write-Host \"  AMD Vari-Bright: Value = $($variBright.PP_VariBrightFeatureControl)\" -ForegroundColor Yellow; ^
    }"
echo.

echo %YELLOW%[8/8]%RESET% Checking Night Light Status...
echo.
powershell -Command ^
    "$nightLight = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default`$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate' -ErrorAction SilentlyContinue; ^
    if ($nightLight.Data) { ^
        Write-Host '  Night Light: Configuration exists (may affect perceived brightness)' -ForegroundColor Yellow; ^
    } else { ^
        Write-Host '  Night Light: Not configured or disabled' -ForegroundColor Green; ^
    }"
echo.

echo %CYAN%============================================================================%RESET%
echo %WHITE%                         DIAGNOSTIC SUMMARY%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   Common causes of auto-dimming:
echo   %YELLOW%*%RESET% Adaptive Brightness enabled (light sensor)
echo   %YELLOW%*%RESET% Intel DPST (Display Power Saving Technology)
echo   %YELLOW%*%RESET% AMD Vari-Bright
echo   %YELLOW%*%RESET% Content Adaptive Brightness Control (CABC)
echo   %YELLOW%*%RESET% Power plan dim settings
echo   %YELLOW%*%RESET% Sensor Monitoring Service running
echo.
echo   %GREEN%Recommendation:%RESET% Use option [2] Quick Fix to disable all auto-dimming
echo.
pause
goto MAIN_MENU

:: ============================================================================
:: QUICK FIX - DISABLE ALL AUTO-DIMMING
:: ============================================================================
:QUICK_FIX
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%              QUICK FIX - DISABLE ALL AUTO-DIMMING%RESET%
echo %CYAN%============================================================================%RESET%
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% This option requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    goto MAIN_MENU
)

echo %YELLOW%[1/6]%RESET% Disabling Adaptive Brightness in registry...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdaptiveBrightness\Status" /v IsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel%==0 (
    echo   %GREEN%[OK]%RESET% Adaptive Brightness disabled
) else (
    echo   %YELLOW%[SKIP]%RESET% Could not modify adaptive brightness
)

echo %YELLOW%[2/6]%RESET% Disabling Adaptive Brightness in active power plan...
:: Get active power plan GUID
for /f "tokens=4" %%a in ('powercfg /getactivescheme 2^>nul') do set "PLAN_GUID=%%a"
:: Disable adaptive brightness (GUID: 7516b95f-f776-4464-8c53-06167f40cc99, sub: fbd9aa66-9553-4097-ba44-ed6e9d65eab8)
powercfg /setacvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0 >nul 2>&1
powercfg /setdcvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0 >nul 2>&1
powercfg /setactive %PLAN_GUID% >nul 2>&1
echo   %GREEN%[OK]%RESET% Power plan adaptive brightness disabled

echo %YELLOW%[3/6]%RESET% Setting display dim brightness to 100%%...
:: Set display dim brightness to 100% (won't dim when idle)
powercfg /setacvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 17aaa29b-8b43-4b94-aafe-35f64daaf1ee 100 >nul 2>&1
powercfg /setdcvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 17aaa29b-8b43-4b94-aafe-35f64daaf1ee 100 >nul 2>&1
powercfg /setactive %PLAN_GUID% >nul 2>&1
echo   %GREEN%[OK]%RESET% Display dim brightness set to 100%%

echo %YELLOW%[4/6]%RESET% Stopping Sensor Monitoring Service...
net stop SensrSvc >nul 2>&1
sc config SensrSvc start= disabled >nul 2>&1
echo   %GREEN%[OK]%RESET% Sensor Monitoring Service stopped and disabled

echo %YELLOW%[5/6]%RESET% Disabling Intel DPST (if present)...
:: Disable Intel Display Power Saving Technology
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v FeatureTestControl /t REG_DWORD /d 0x9240 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v DPST_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
echo   %GREEN%[OK]%RESET% Intel DPST disabled (if applicable)

echo %YELLOW%[6/6]%RESET% Disabling CABC (Content Adaptive Brightness)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v KMD_EnableBrightnessInterface2 /t REG_DWORD /d 0 /f >nul 2>&1
echo   %GREEN%[OK]%RESET% CABC disabled (if applicable)

echo.
echo %GREEN%============================================================================%RESET%
echo %WHITE%                         QUICK FIX COMPLETE%RESET%
echo %GREEN%============================================================================%RESET%
echo.
echo   All auto-dimming features have been disabled.
echo   %YELLOW%NOTE:%RESET% A restart may be required for all changes to take effect.
echo.
echo   If brightness still dims, check:
echo   %WHITE%*%RESET% GPU control panel (NVIDIA/AMD/Intel) for power saving
echo   %WHITE%*%RESET% Laptop manufacturer software (Dell, HP, Lenovo utilities)
echo.
pause
goto MAIN_MENU

:: ============================================================================
:: SET MAXIMUM BRIGHTNESS
:: ============================================================================
:SET_MAX_BRIGHTNESS
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                   SET BRIGHTNESS TO MAXIMUM%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo Setting brightness to 100%%...
echo.

powershell -Command ^
    "$brightness = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods -ErrorAction SilentlyContinue; ^
    if ($brightness) { ^
        $brightness | Invoke-CimMethod -MethodName WmiSetBrightness -Arguments @{Brightness=100; Timeout=0}; ^
        Write-Host '[OK] Brightness set to 100%%' -ForegroundColor Green; ^
    } else { ^
        Write-Host '[WARNING] Cannot set brightness via WMI - trying PowerShell brightness API...' -ForegroundColor Yellow; ^
        try { ^
            (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(0, 100); ^
            Write-Host '[OK] Brightness set to 100%%' -ForegroundColor Green; ^
        } catch { ^
            Write-Host '[ERROR] Could not set brightness. This may be a desktop monitor.' -ForegroundColor Red; ^
            Write-Host 'Desktop monitors typically use physical buttons for brightness.' -ForegroundColor Yellow; ^
        } ^
    }"

echo.
pause
goto MAIN_MENU

:: ============================================================================
:: GAMMA BOOST MENU - GO BEYOND WINDOWS LIMITS
:: ============================================================================
:GAMMA_BOOST_MENU
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%              GAMMA BOOST - BEYOND WINDOWS LIMITS%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   Gamma adjustment can make your screen appear brighter than 100%% by
echo   boosting the RGB gamma curves. This works on ALL monitors.
echo.
echo   %YELLOW%WARNING:%RESET% Extreme values may cause washed-out colors or eye strain.
echo.
echo   %WHITE%[1]%RESET% Slight Boost   (+10%% perceived brightness)
echo   %WHITE%[2]%RESET% Medium Boost   (+20%% perceived brightness)
echo   %WHITE%[3]%RESET% Strong Boost   (+30%% perceived brightness)
echo   %WHITE%[4]%RESET% Maximum Boost  (+50%% - may wash out colors)
echo   %WHITE%[5]%RESET% Custom Gamma Value
echo   %WHITE%[6]%RESET% Reset to Default Gamma
echo   %WHITE%[0]%RESET% Back to Main Menu
echo.
echo %CYAN%============================================================================%RESET%
echo.
set /p "gchoice=Select an option [0-6]: "

if "%gchoice%"=="1" (
    set "GAMMA_VALUE=1.1"
    goto APPLY_GAMMA
)
if "%gchoice%"=="2" (
    set "GAMMA_VALUE=1.2"
    goto APPLY_GAMMA
)
if "%gchoice%"=="3" (
    set "GAMMA_VALUE=1.3"
    goto APPLY_GAMMA
)
if "%gchoice%"=="4" (
    set "GAMMA_VALUE=1.5"
    goto APPLY_GAMMA
)
if "%gchoice%"=="5" goto CUSTOM_GAMMA
if "%gchoice%"=="6" (
    set "GAMMA_VALUE=1.0"
    goto APPLY_GAMMA
)
if "%gchoice%"=="0" goto MAIN_MENU
goto GAMMA_BOOST_MENU

:CUSTOM_GAMMA
echo.
echo   Enter gamma value (0.5 = darker, 1.0 = normal, 2.0 = much brighter)
echo   Recommended range: 1.0 to 1.5
echo.
set /p "GAMMA_VALUE=Enter gamma value: "
goto APPLY_GAMMA

:APPLY_GAMMA
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                      APPLYING GAMMA BOOST%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   Applying gamma value: %GAMMA_VALUE%
echo.

:: Create PowerShell script for gamma adjustment
set "GAMMA_SCRIPT=%TEMP%\set_gamma.ps1"

(
echo Add-Type @"
echo using System;
echo using System.Runtime.InteropServices;
echo public class GammaRamp {
echo     [DllImport("gdi32.dll"^)]
echo     public static extern bool SetDeviceGammaRamp(IntPtr hDC, ref RAMP lpRamp^);
echo     [DllImport("gdi32.dll"^)]
echo     public static extern bool GetDeviceGammaRamp(IntPtr hDC, ref RAMP lpRamp^);
echo     [DllImport("user32.dll"^)]
echo     public static extern IntPtr GetDC(IntPtr hWnd^);
echo     [DllImport("user32.dll"^)]
echo     public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC^);
echo     [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi^)]
echo     public struct RAMP {
echo         [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256^)]
echo         public UInt16[] Red;
echo         [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256^)]
echo         public UInt16[] Green;
echo         [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256^)]
echo         public UInt16[] Blue;
echo     }
echo }
echo "@
echo.
echo $gamma = %GAMMA_VALUE%
echo $hdc = [GammaRamp]::GetDC([IntPtr]::Zero^)
echo $ramp = New-Object GammaRamp+RAMP
echo $ramp.Red = New-Object UInt16[] 256
echo $ramp.Green = New-Object UInt16[] 256
echo $ramp.Blue = New-Object UInt16[] 256
echo.
echo for ($i = 0; $i -lt 256; $i++^) {
echo     $value = [Math]::Pow($i / 255.0, 1.0 / $gamma^) * 65535
echo     $value = [Math]::Min(65535, [Math]::Max(0, $value^)^)
echo     $ramp.Red[$i] = [UInt16]$value
echo     $ramp.Green[$i] = [UInt16]$value
echo     $ramp.Blue[$i] = [UInt16]$value
echo }
echo.
echo $result = [GammaRamp]::SetDeviceGammaRamp($hdc, [ref]$ramp^)
echo [GammaRamp]::ReleaseDC([IntPtr]::Zero, $hdc^) ^| Out-Null
echo.
echo if ($result^) {
echo     Write-Host "[OK] Gamma set to $gamma" -ForegroundColor Green
echo } else {
echo     Write-Host "[ERROR] Failed to set gamma" -ForegroundColor Red
echo }
) > "%GAMMA_SCRIPT%"

powershell -ExecutionPolicy Bypass -File "%GAMMA_SCRIPT%"
del "%GAMMA_SCRIPT%" >nul 2>&1

echo.
echo   %YELLOW%NOTE:%RESET% Gamma resets when you restart or log off.
echo   To make permanent, use this tool at startup or use GPU control panel.
echo.
pause
goto GAMMA_BOOST_MENU

:: ============================================================================
:: RESET DISPLAY SETTINGS
:: ============================================================================
:RESET_DISPLAY
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                    RESET DISPLAY SETTINGS%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   This will:
echo   %WHITE%*%RESET% Reset gamma to default (1.0)
echo   %WHITE%*%RESET% Re-enable adaptive brightness
echo   %WHITE%*%RESET% Restart display driver
echo.
set /p "confirm=Are you sure you want to reset? (Y/N): "
if /i not "%confirm%"=="Y" goto MAIN_MENU

echo.
echo %YELLOW%[1/3]%RESET% Resetting gamma to default...
set "GAMMA_VALUE=1.0"

set "GAMMA_SCRIPT=%TEMP%\reset_gamma.ps1"
(
echo Add-Type @"
echo using System;
echo using System.Runtime.InteropServices;
echo public class GammaRamp {
echo     [DllImport("gdi32.dll"^)]
echo     public static extern bool SetDeviceGammaRamp(IntPtr hDC, ref RAMP lpRamp^);
echo     [DllImport("user32.dll"^)]
echo     public static extern IntPtr GetDC(IntPtr hWnd^);
echo     [DllImport("user32.dll"^)]
echo     public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC^);
echo     [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi^)]
echo     public struct RAMP {
echo         [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256^)]
echo         public UInt16[] Red;
echo         [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256^)]
echo         public UInt16[] Green;
echo         [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256^)]
echo         public UInt16[] Blue;
echo     }
echo }
echo "@
echo $hdc = [GammaRamp]::GetDC([IntPtr]::Zero^)
echo $ramp = New-Object GammaRamp+RAMP
echo $ramp.Red = New-Object UInt16[] 256
echo $ramp.Green = New-Object UInt16[] 256
echo $ramp.Blue = New-Object UInt16[] 256
echo for ($i = 0; $i -lt 256; $i++^) {
echo     $value = $i * 256
echo     $ramp.Red[$i] = [UInt16]$value
echo     $ramp.Green[$i] = [UInt16]$value
echo     $ramp.Blue[$i] = [UInt16]$value
echo }
echo [GammaRamp]::SetDeviceGammaRamp($hdc, [ref]$ramp^) ^| Out-Null
echo [GammaRamp]::ReleaseDC([IntPtr]::Zero, $hdc^) ^| Out-Null
echo Write-Host "[OK] Gamma reset to default" -ForegroundColor Green
) > "%GAMMA_SCRIPT%"

powershell -ExecutionPolicy Bypass -File "%GAMMA_SCRIPT%"
del "%GAMMA_SCRIPT%" >nul 2>&1

echo %YELLOW%[2/3]%RESET% Re-enabling adaptive brightness...
net session >nul 2>&1
if %errorlevel% equ 0 (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdaptiveBrightness\Status" /v IsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
    sc config SensrSvc start= auto >nul 2>&1
    net start SensrSvc >nul 2>&1
    echo   %GREEN%[OK]%RESET% Adaptive brightness re-enabled
) else (
    echo   %YELLOW%[SKIP]%RESET% Requires admin to re-enable adaptive brightness
)

echo %YELLOW%[3/3]%RESET% Restarting display driver...
powershell -Command ^
    "try { ^
        pnputil /restart-device 'DISPLAY\*' 2>$null; ^
        Write-Host '[OK] Display driver restart requested' -ForegroundColor Green; ^
    } catch { ^
        Write-Host '[INFO] Could not restart display driver - may require restart' -ForegroundColor Yellow; ^
    }"

echo.
echo %GREEN%[COMPLETE]%RESET% Display settings have been reset.
echo.
pause
goto MAIN_MENU

:: ============================================================================
:: VIEW CURRENT BRIGHTNESS INFO
:: ============================================================================
:VIEW_BRIGHTNESS
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                    CURRENT BRIGHTNESS INFO%RESET%
echo %CYAN%============================================================================%RESET%
echo.

powershell -Command ^
    "Write-Host 'Monitor Brightness Information' -ForegroundColor Cyan; ^
    Write-Host '==============================' -ForegroundColor Cyan; ^
    Write-Host ''; ^
    $brightness = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue; ^
    if ($brightness) { ^
        Write-Host 'Current Brightness Level: ' -NoNewline; ^
        Write-Host \"$($brightness.CurrentBrightness)%%\" -ForegroundColor Green; ^
        Write-Host ''; ^
        Write-Host 'Available Brightness Levels:' -ForegroundColor White; ^
        $levels = $brightness.Level; ^
        Write-Host ($levels -join '%%  ') -ForegroundColor Gray; ^
        Write-Host ''; ^
    } else { ^
        Write-Host '[INFO] Software brightness control not available' -ForegroundColor Yellow; ^
        Write-Host 'This is normal for desktop monitors - use physical buttons' -ForegroundColor Gray; ^
        Write-Host ''; ^
    } ^
    Write-Host ''; ^
    Write-Host 'Connected Monitors' -ForegroundColor Cyan; ^
    Write-Host '==================' -ForegroundColor Cyan; ^
    $monitors = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorID -ErrorAction SilentlyContinue; ^
    foreach ($mon in $monitors) { ^
        $name = ($mon.UserFriendlyName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ''; ^
        $mfg = ($mon.ManufacturerName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ''; ^
        Write-Host \"  Monitor: $name\" -ForegroundColor White; ^
        Write-Host \"  Manufacturer: $mfg\" -ForegroundColor Gray; ^
        Write-Host ''; ^
    }"

echo.
pause
goto MAIN_MENU

:: ============================================================================
:: ADVANCED MENU
:: ============================================================================
:ADVANCED_MENU
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                        ADVANCED OPTIONS%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   %WHITE%[1]%RESET% Disable Intel DPST (Display Power Saving)
echo   %WHITE%[2]%RESET% Disable AMD Vari-Bright
echo   %WHITE%[3]%RESET% Disable Panel Self-Refresh (PSR)
echo   %WHITE%[4]%RESET% Reset Display Adapter
echo   %WHITE%[5]%RESET% Open Windows Display Settings
echo   %WHITE%[6]%RESET% Open Power Plan Settings
echo   %WHITE%[7]%RESET% Export Diagnostic Report
echo   %WHITE%[0]%RESET% Back to Main Menu
echo.
echo %CYAN%============================================================================%RESET%
echo.
set /p "achoice=Select an option [0-7]: "

if "%achoice%"=="1" goto DISABLE_DPST
if "%achoice%"=="2" goto DISABLE_VARIBRIGHT
if "%achoice%"=="3" goto DISABLE_PSR
if "%achoice%"=="4" goto RESET_ADAPTER
if "%achoice%"=="5" goto OPEN_DISPLAY_SETTINGS
if "%achoice%"=="6" goto OPEN_POWER_SETTINGS
if "%achoice%"=="7" goto EXPORT_REPORT
if "%achoice%"=="0" goto MAIN_MENU
goto ADVANCED_MENU

:DISABLE_DPST
cls
echo %CYAN%Disabling Intel Display Power Saving Technology (DPST)...%RESET%
echo.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Requires Administrator privileges.
    pause
    goto ADVANCED_MENU
)

:: Multiple registry locations for different Intel driver versions
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v FeatureTestControl /t REG_DWORD /d 0x9240 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v DPST_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" /v FeatureTestControl /t REG_DWORD /d 0x9240 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" /v DPST_Enabled /t REG_DWORD /d 0 /f >nul 2>&1

echo %GREEN%[OK]%RESET% Intel DPST disabled. Restart required for full effect.
echo.
pause
goto ADVANCED_MENU

:DISABLE_VARIBRIGHT
cls
echo %CYAN%Disabling AMD Vari-Bright...%RESET%
echo.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Requires Administrator privileges.
    pause
    goto ADVANCED_MENU
)

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PP_VariBrightFeatureControl /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" /v PP_VariBrightFeatureControl /t REG_DWORD /d 0 /f >nul 2>&1

echo %GREEN%[OK]%RESET% AMD Vari-Bright disabled. Restart required for full effect.
echo.
echo %YELLOW%TIP:%RESET% Also disable Vari-Bright in AMD Radeon Software:
echo      Gaming ^> Display ^> Vari-Bright ^> OFF
echo.
pause
goto ADVANCED_MENU

:DISABLE_PSR
cls
echo %CYAN%Disabling Panel Self-Refresh (PSR)...%RESET%
echo.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Requires Administrator privileges.
    pause
    goto ADVANCED_MENU
)

:: Intel PSR
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v Disable_PSR /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v EnablePSR /t REG_DWORD /d 0 /f >nul 2>&1

echo %GREEN%[OK]%RESET% Panel Self-Refresh disabled. Restart required.
echo.
pause
goto ADVANCED_MENU

:RESET_ADAPTER
cls
echo %CYAN%Resetting Display Adapter...%RESET%
echo.
echo This will briefly flash your screen.
set /p "confirm=Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto ADVANCED_MENU

powershell -Command ^
    "$adapters = Get-PnpDevice -Class Display -Status OK; ^
    foreach ($adapter in $adapters) { ^
        Write-Host \"Restarting: $($adapter.FriendlyName)\" -ForegroundColor Yellow; ^
        Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction SilentlyContinue; ^
        Start-Sleep -Seconds 2; ^
        Enable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction SilentlyContinue; ^
        Write-Host '[OK] Adapter restarted' -ForegroundColor Green; ^
    }"

echo.
pause
goto ADVANCED_MENU

:OPEN_DISPLAY_SETTINGS
start ms-settings:display
goto ADVANCED_MENU

:OPEN_POWER_SETTINGS
start powercfg.cpl
goto ADVANCED_MENU

:EXPORT_REPORT
cls
echo %CYAN%Exporting Diagnostic Report...%RESET%
echo.

set "REPORT_FILE=%USERPROFILE%\Desktop\BrightnessReport_%DATE:~-4%%DATE:~4,2%%DATE:~7,2%.txt"

(
echo ============================================================================
echo  BRIGHTNESS DIAGNOSTIC REPORT
echo  Generated: %DATE% %TIME%
echo  Computer: %COMPUTERNAME%
echo ============================================================================
echo.
echo == BRIGHTNESS LEVEL ==
powershell -Command "Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue | Format-List *"
echo.
echo == DISPLAY ADAPTERS ==
powershell -Command "Get-CimInstance Win32_VideoController | Format-List Name, DriverVersion, Status, AdapterRAM"
echo.
echo == ADAPTIVE BRIGHTNESS REGISTRY ==
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdaptiveBrightness\Status" 2>nul
echo.
echo == POWER PLAN DISPLAY SETTINGS ==
powercfg /query SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99
echo.
echo == SENSOR SERVICE STATUS ==
sc query SensrSvc
echo.
echo == INTEL DPST SETTINGS ==
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v FeatureTestControl 2>nul
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v DPST_Enabled 2>nul
echo.
echo == MONITORS ==
powershell -Command "Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorID -ErrorAction SilentlyContinue | ForEach-Object { $name = ($_.UserFriendlyName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ''; Write-Output \"Monitor: $name\" }"
) > "%REPORT_FILE%"

echo %GREEN%[OK]%RESET% Report saved to:
echo      %REPORT_FILE%
echo.
pause
goto ADVANCED_MENU

:: ============================================================================
:: EXIT
:: ============================================================================
:EXIT
echo.
echo Goodbye!
endlocal
exit /b 0
