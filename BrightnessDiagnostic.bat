@echo off
:: No delayed expansion: it would strip any "!" from the folder path in %%~dp0
:: and every "%%PS_HELPER%%" use. Nothing in this script needs it.
setlocal
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

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "PS_HELPER=%SCRIPT_DIR%BrightnessDiagnostic.ps1"

:: Check if helper script exists
if not exist "%PS_HELPER%" (
    color 0C
    echo [ERROR] BrightnessDiagnostic.ps1 not found!
    echo Please ensure BrightnessDiagnostic.ps1 is in the same folder as this batch file.
    echo/
    pause
    exit /b 1
)

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
echo/
echo   %WHITE%[1]%RESET% Run Full Brightness Diagnostic
echo   %WHITE%[2]%RESET% Quick Fix - Disable All Auto-Dimming
echo   %WHITE%[3]%RESET% Set Brightness to Maximum (100%%)
echo   %WHITE%[4]%RESET% Gamma Boost - Go Beyond Windows Limits
echo   %WHITE%[5]%RESET% Reset Display Settings to Default
echo   %WHITE%[6]%RESET% View Current Brightness Info
echo   %WHITE%[7]%RESET% Advanced Options
echo   %WHITE%[0]%RESET% Exit
echo/
echo %CYAN%============================================================================%RESET%
echo/
set "choice="
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
echo/

echo %YELLOW%[1/8]%RESET% Checking current brightness level...
echo/
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action get-brightness
echo/

echo %YELLOW%[2/8]%RESET% Checking display adapters...
echo/
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action get-adapters
echo/

echo %YELLOW%[3/8]%RESET% Checking for Adaptive Brightness...
echo/
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action get-sensor
echo/

:: Windows keeps the adaptive brightness toggle in the active power plan
:: (ADAPTBRIGHT), not in a registry flag
echo %YELLOW%[4/8]%RESET% Checking Adaptive Brightness Power Setting...
echo/
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action get-adaptive
echo/

echo %YELLOW%[5/8]%RESET% Checking Power Plan Brightness Settings...
echo/
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action get-powerplan
echo/

echo %YELLOW%[6/8]%RESET% Checking for Content Adaptive Brightness Control (CABC)...
echo/
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action get-cabc
echo/

echo %YELLOW%[7/8]%RESET% Checking Intel/AMD/NVIDIA Display Power Saving...
echo/
:: get-dpst prints FeatureTestControl for each Intel adapter
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action get-dpst
echo/

echo %YELLOW%[8/8]%RESET% Checking Night Light Status...
echo/
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action get-nightlight
echo/

echo %CYAN%============================================================================%RESET%
echo %WHITE%                         DIAGNOSTIC SUMMARY%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   Common causes of auto-dimming:
echo   %YELLOW%*%RESET% Adaptive Brightness enabled (light sensor)
echo   %YELLOW%*%RESET% Intel DPST (Display Power Saving Technology)
echo   %YELLOW%*%RESET% AMD Vari-Bright
echo   %YELLOW%*%RESET% Content Adaptive Brightness Control (CABC)
echo   %YELLOW%*%RESET% Power plan dim settings
echo   %YELLOW%*%RESET% Sensor Monitoring Service running
echo/
echo   %GREEN%Recommendation:%RESET% Use option [2] Quick Fix to disable all auto-dimming
echo/
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
echo/

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% This option requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo/
    pause
    goto MAIN_MENU
)

echo   This will change the following settings:
echo   %WHITE%*%RESET% Active power plan: adaptive brightness off, dimmed brightness 100%%,
echo     and "Dim display after" set to never
echo   %WHITE%*%RESET% Sensor Monitoring Service (SensrSvc): stopped and disabled
echo   %WHITE%*%RESET% Intel DPST: bit 0x10 set in FeatureTestControl (Intel adapters only)
echo   %WHITE%*%RESET% CABC: KMD_EnableBrightnessInterface2 = 0 on display adapter 0000
echo/
echo   Power plan and display driver values are backed up first; option [5] restores them.
echo   Option [5] sets SensrSvc to Manual, the Windows default, not its previous start type.
echo/
set "confirm="
set /p "confirm=Apply these changes? (Y/N): "
if /i not "%confirm%"=="Y" goto MAIN_MENU
echo/

echo %YELLOW%[1/6]%RESET% Backing up current settings...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action backup-settings
if %errorlevel% neq 0 (
    echo   %RED%[ERROR]%RESET% Backup failed - no changes were made.
    echo/
    pause
    goto MAIN_MENU
)

echo %YELLOW%[2/6]%RESET% Disabling Adaptive Brightness in active power plan...
:: Get active power plan GUID. The label before the GUID is localized, so parse
:: after the ':' rather than by word position (tokens=4 only works in English).
:: PLAN_GUID is set before the block below is parsed, so %%PLAN_GUID%% is safe in it.
set "PLAN_GUID="
for /f "tokens=2 delims=:" %%a in ('powercfg /getactivescheme 2^>nul') do for /f "tokens=1" %%b in ("%%a") do set "PLAN_GUID=%%b"

if not defined PLAN_GUID (
    echo   %RED%[WARN]%RESET% Could not determine the active power plan GUID - skipping plan tweaks.
) else (
    REM Disable adaptive brightness: subgroup 7516b95f = Display, fbd9aa66 = ADAPTBRIGHT
    powercfg /setacvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0 >nul 2>&1
    powercfg /setdcvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 fbd9aa66-9553-4097-ba44-ed6e9d65eab8 0 >nul 2>&1
    powercfg /setactive %PLAN_GUID% >nul 2>&1
    echo   %GREEN%[OK]%RESET% Power plan adaptive brightness disabled

    echo %YELLOW%[3/6]%RESET% Disabling idle display dimming...
    REM f1fbfde2 = Dimmed display brightness in percent; 17aaa29b = Dim display after in seconds, 0 = never
    powercfg /setacvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 f1fbfde2-a960-4165-9f88-50667911ce96 100 >nul 2>&1
    powercfg /setdcvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 f1fbfde2-a960-4165-9f88-50667911ce96 100 >nul 2>&1
    powercfg /setacvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 17aaa29b-8b43-4b94-aafe-35f64daaf1ee 0 >nul 2>&1
    powercfg /setdcvalueindex %PLAN_GUID% 7516b95f-f776-4464-8c53-06167f40cc99 17aaa29b-8b43-4b94-aafe-35f64daaf1ee 0 >nul 2>&1
    powercfg /setactive %PLAN_GUID% >nul 2>&1
    echo   %GREEN%[OK]%RESET% Dimmed brightness set to 100%% and idle dim timer disabled
)

echo %YELLOW%[4/6]%RESET% Stopping Sensor Monitoring Service...
net stop SensrSvc >nul 2>&1
sc config SensrSvc start= disabled >nul 2>&1
echo   %GREEN%[OK]%RESET% Sensor Monitoring Service stopped and disabled

echo %YELLOW%[5/6]%RESET% Disabling Intel DPST (if present)...
:: Sets only bit 0x10 of FeatureTestControl on Intel adapters that have the value
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action disable-dpst

echo %YELLOW%[6/6]%RESET% Disabling CABC (Content Adaptive Brightness)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v KMD_EnableBrightnessInterface2 /t REG_DWORD /d 0 /f >nul 2>&1
echo   %GREEN%[OK]%RESET% CABC disabled (if applicable)

echo/
echo %GREEN%============================================================================%RESET%
echo %WHITE%                         QUICK FIX COMPLETE%RESET%
echo %GREEN%============================================================================%RESET%
echo/
echo   All auto-dimming features have been disabled.
echo   %YELLOW%NOTE:%RESET% A restart may be required for all changes to take effect.
echo   To undo: option [5] restores the backed-up power plan and driver values
echo   and sets SensrSvc to Manual, the Windows default.
echo/
echo   If brightness still dims, check:
echo   %WHITE%*%RESET% GPU control panel (NVIDIA/AMD/Intel) for power saving
echo   %WHITE%*%RESET% Laptop manufacturer software (Dell, HP, Lenovo utilities)
echo/
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
echo/

echo Setting brightness to 100%%...
echo/
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action set-max

echo/
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
echo/
echo   Gamma adjustment can make your screen appear brighter than 100%% by
echo   boosting the RGB gamma curves. This works on ALL monitors.
echo/
echo   %YELLOW%WARNING:%RESET% Extreme values may cause washed-out colors or eye strain.
echo/
echo   %WHITE%[1]%RESET% Slight Boost   (+10%% perceived brightness)
echo   %WHITE%[2]%RESET% Medium Boost   (+20%% perceived brightness)
echo   %WHITE%[3]%RESET% Strong Boost   (+30%% perceived brightness)
echo   %WHITE%[4]%RESET% Maximum Boost  (+50%% - may wash out colors)
echo   %WHITE%[5]%RESET% Custom Gamma Value
echo   %WHITE%[6]%RESET% Reset to Default Gamma
echo   %WHITE%[0]%RESET% Back to Main Menu
echo/
echo %CYAN%============================================================================%RESET%
echo/
set "gchoice="
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
if "%gchoice%"=="6" goto RESET_GAMMA
if "%gchoice%"=="0" goto MAIN_MENU
goto GAMMA_BOOST_MENU

:CUSTOM_GAMMA
echo/
echo   Enter gamma value (0.5 = darker, 1.0 = normal, 2.0 = much brighter)
echo   Recommended range: 1.0 to 1.5
echo/
set "GAMMA_VALUE="
set /p "GAMMA_VALUE=Enter gamma value: "
if not defined GAMMA_VALUE goto GAMMA_BOOST_MENU
goto APPLY_GAMMA

:APPLY_GAMMA
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                      APPLYING GAMMA BOOST%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   Applying gamma value: %GAMMA_VALUE%
echo/

powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action set-gamma -GammaValue %GAMMA_VALUE%

echo/
echo   %YELLOW%NOTE:%RESET% Gamma resets when you restart or log off.
echo   To make permanent, use this tool at startup or use GPU control panel.
echo/
pause
goto GAMMA_BOOST_MENU

:RESET_GAMMA
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                      RESETTING GAMMA%RESET%
echo %CYAN%============================================================================%RESET%
echo/

powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action reset-gamma

echo/
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
echo/
echo   This will:
echo   %WHITE%*%RESET% Reset gamma to default (1.0)
echo   %WHITE%*%RESET% Restore the power plan and display driver values that were backed up
echo     before Quick Fix or an Advanced fix ran (admin). Without a backup, only
echo     adaptive brightness is turned back on.
echo   %WHITE%*%RESET% Set the Sensor Monitoring Service back to Manual (Windows default)
echo   %WHITE%*%RESET% Restart display driver
echo/
set "confirm="
set /p "confirm=Are you sure you want to reset? (Y/N): "
if /i not "%confirm%"=="Y" goto MAIN_MENU

echo/
echo %YELLOW%[1/3]%RESET% Resetting gamma to default...
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action reset-gamma

echo %YELLOW%[2/3]%RESET% Restoring brightness settings...
net session >nul 2>&1
if %errorlevel% equ 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action restore-settings
    REM Windows default for SensrSvc is Manual - trigger start - not Automatic
    sc config SensrSvc start= demand >nul 2>&1
    net start SensrSvc >nul 2>&1
    echo   %GREEN%[OK]%RESET% Sensor Monitoring Service set back to Manual ^(Windows default^)
) else (
    echo   %YELLOW%[SKIP]%RESET% Requires admin to restore brightness settings
)

echo %YELLOW%[3/3]%RESET% Restarting display driver...
powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action restart-driver

echo/
echo %GREEN%[COMPLETE]%RESET% Display settings have been reset.
echo/
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
echo/

powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action view-brightness

echo/
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
echo/
echo   %WHITE%[1]%RESET% Disable Intel DPST (Display Power Saving)
echo   %WHITE%[2]%RESET% Disable AMD Vari-Bright
echo   %WHITE%[3]%RESET% Disable Panel Self-Refresh (PSR)
echo   %WHITE%[4]%RESET% Reset Display Adapter
echo   %WHITE%[5]%RESET% Open Windows Display Settings
echo   %WHITE%[6]%RESET% Open Power Plan Settings
echo   %WHITE%[7]%RESET% Export Diagnostic Report
echo   %WHITE%[0]%RESET% Back to Main Menu
echo/
echo %CYAN%============================================================================%RESET%
echo/
set "achoice="
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
echo/
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Requires Administrator privileges.
    pause
    goto ADVANCED_MENU
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action backup-settings
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Backup failed - no changes were made.
    pause
    goto ADVANCED_MENU
)

:: Sets only bit 0x10 of FeatureTestControl on every Intel adapter that has the
:: value; the rest of the driver's feature bitmask is left as it was
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action disable-dpst

echo/
echo %YELLOW%NOTE:%RESET% Restart required for full effect. Main menu option [5] undoes this.
echo/
pause
goto ADVANCED_MENU

:DISABLE_VARIBRIGHT
cls
echo %CYAN%Disabling AMD Vari-Bright...%RESET%
echo/
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Requires Administrator privileges.
    pause
    goto ADVANCED_MENU
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action backup-settings
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Backup failed - no changes were made.
    pause
    goto ADVANCED_MENU
)

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PP_VariBrightFeatureControl /t REG_DWORD /d 0 /f >nul 2>&1
:: Adapter 0001 only if it exists - reg add would otherwise create an orphan key
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" >nul 2>&1
if %errorlevel% equ 0 reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" /v PP_VariBrightFeatureControl /t REG_DWORD /d 0 /f >nul 2>&1

echo %GREEN%[OK]%RESET% AMD Vari-Bright disabled. Restart required for full effect.
echo      Main menu option [5] undoes this.
echo/
echo %YELLOW%TIP:%RESET% Also disable Vari-Bright in AMD Radeon Software:
echo      Gaming ^> Display ^> Vari-Bright ^> OFF
echo/
pause
goto ADVANCED_MENU

:DISABLE_PSR
cls
echo %CYAN%Disabling Panel Self-Refresh (PSR)...%RESET%
echo/
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Requires Administrator privileges.
    pause
    goto ADVANCED_MENU
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action backup-settings
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Backup failed - no changes were made.
    pause
    goto ADVANCED_MENU
)

:: Intel PSR
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v Disable_PSR /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v EnablePSR /t REG_DWORD /d 0 /f >nul 2>&1

echo %GREEN%[OK]%RESET% Panel Self-Refresh disabled. Restart required.
echo      Main menu option [5] undoes this.
echo/
pause
goto ADVANCED_MENU

:RESET_ADAPTER
cls
echo %CYAN%Resetting Display Adapter...%RESET%
echo/
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR]%RESET% Requires Administrator privileges.
    pause
    goto ADVANCED_MENU
)
echo This will briefly flash your screen.
set "confirm="
set /p "confirm=Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto ADVANCED_MENU

powershell -ExecutionPolicy Bypass -File "%PS_HELPER%" -Action reset-adapter

echo/
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
echo/

for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set "TODAY=%%D"
:: The visible Desktop may be redirected (e.g. OneDrive Known Folder Move), so ask
:: Windows where it is instead of assuming %%USERPROFILE%%\Desktop.
set "DESKTOP_DIR="
for /f "delims=" %%D in ('powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"') do set "DESKTOP_DIR=%%D"
if not defined DESKTOP_DIR set "DESKTOP_DIR=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_DIR%\" set "DESKTOP_DIR=%USERPROFILE%\Desktop"
set "REPORT_FILE=%DESKTOP_DIR%\BrightnessReport_%TODAY%.txt"
:: Delete an older copy so the existence check below proves this run wrote it
if exist "%REPORT_FILE%" del /f /q "%REPORT_FILE%" >nul 2>&1

(
echo ============================================================================
echo  BRIGHTNESS DIAGNOSTIC REPORT
echo  Generated: %DATE% %TIME%
echo  Computer: %COMPUTERNAME%
echo ============================================================================
echo/
echo == BRIGHTNESS LEVEL ==
powershell -Command "Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue | Format-List *"
echo/
echo == DISPLAY ADAPTERS ==
powershell -Command "Get-CimInstance Win32_VideoController | Format-List Name, DriverVersion, Status, AdapterRAM"
echo/
echo == ADAPTIVE BRIGHTNESS - POWER PLAN SETTING ADAPTBRIGHT ==
powercfg /qh SCHEME_CURRENT SUB_VIDEO ADAPTBRIGHT 2>nul
echo/
echo == POWER PLAN DISPLAY SETTINGS ==
powercfg /query SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99
echo/
echo == SENSOR SERVICE STATUS ==
sc query SensrSvc
echo/
echo == INTEL DPST SETTINGS ==
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v FeatureTestControl 2>nul
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v DPST_Enabled 2>nul
echo/
echo == MONITORS ==
powershell -Command "Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorID -ErrorAction SilentlyContinue | ForEach-Object { $name = ($_.UserFriendlyName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ''; Write-Output \"Monitor: $name\" }"
) > "%REPORT_FILE%"

:: The path is echoed in quotes because a redirected Desktop folder name can
:: contain parentheses or an ampersand, which would break an unquoted echo.
if not exist "%REPORT_FILE%" (
    echo %RED%[ERROR]%RESET% Could not write the report to:
    echo      "%REPORT_FILE%"
    echo/
    pause
    goto ADVANCED_MENU
)
echo %GREEN%[OK]%RESET% Report saved to:
echo      "%REPORT_FILE%"
echo/
pause
goto ADVANCED_MENU

:: ============================================================================
:: EXIT
:: ============================================================================
:EXIT
echo/
echo Goodbye!
endlocal
exit /b 0
