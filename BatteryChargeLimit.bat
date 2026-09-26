@echo off
setlocal enabledelayedexpansion
title Battery Charge Limit
color 0B

:: ============================================================================
:: Battery Charge Limit
:: ============================================================================
:: Sets the maximum battery charge threshold on supported laptops.
:: Supports: Lenovo, ASUS, Microsoft Surface, HP, Dell, Huawei, Samsung,
::           LG, MSI, Razer, Toshiba/Dynabook
:: Requires admin privileges and manufacturer-specific drivers/firmware.
:: ============================================================================

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges.
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: ANSI color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

:: Detect manufacturer
set "manufacturer=Unknown"
for /f "tokens=*" %%m in ('powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).Manufacturer" 2^>nul') do set "manufacturer=%%m"
set "model="
for /f "tokens=*" %%m in ('powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).Model" 2^>nul') do set "model=%%m"

:: Check if running on a laptop (battery present)
set "hasBattery=0"
powershell -NoProfile -Command "if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel%==0 set "hasBattery=1"

:MAIN_MENU
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                      BATTERY CHARGE LIMIT%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   %WHITE%Manufacturer:%RESET% %manufacturer%
echo   %WHITE%Model:%RESET%        %model%
echo/

if "%hasBattery%"=="0" (
    echo   %RED%[WARNING] No battery detected. This tool is for laptops only.%RESET%
    echo/
)

echo   Set the maximum battery charge level to extend battery lifespan.
echo   Keeping the charge between 50-80%% can significantly reduce
echo   long-term battery degradation.
echo/
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo/
echo   %WHITE%[1]%RESET% Set charge limit to %GREEN%50%%%RESET%    (Maximum longevity)
echo   %WHITE%[2]%RESET% Set charge limit to %GREEN%80%%%RESET%    (Recommended balance)
echo   %WHITE%[3]%RESET% Set charge limit to %YELLOW%90%%%RESET%    (Slight protection)
echo   %WHITE%[4]%RESET% Set charge limit to %RED%100%%%RESET%   (No limit - full charge)
echo/
echo   %WHITE%[5]%RESET% View current battery status
echo   %WHITE%[6]%RESET% Detect supported method
echo   %WHITE%[0]%RESET% Exit
echo/
echo %CYAN%============================================================================%RESET%
echo/
set "choice="
set /p "choice=Select an option [0-6]: "

if "%choice%"=="1" (
    set "limit=50"
    goto CONFIRM_LIMIT
)
if "%choice%"=="2" (
    set "limit=80"
    goto CONFIRM_LIMIT
)
if "%choice%"=="3" (
    set "limit=90"
    goto CONFIRM_LIMIT
)
if "%choice%"=="4" (
    set "limit=100"
    goto CONFIRM_LIMIT
)
if "%choice%"=="5" goto BATTERY_STATUS
if "%choice%"=="6" goto DETECT_METHOD
if "%choice%"=="0" goto EXIT
goto MAIN_MENU

:: ============================================================================
:: CONFIRM LIMIT
:: ============================================================================
:CONFIRM_LIMIT
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                    CONFIRM CHARGE LIMIT CHANGE%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   %WHITE%New charge limit:%RESET% %limit%%%
echo   %WHITE%Manufacturer:%RESET%    %manufacturer%
echo/

if "%limit%"=="100" (
    echo   %YELLOW%This removes any charge limit. Your battery will charge to full.%RESET%
) else (
    echo   %GREEN%Limiting charge to %limit%%% helps extend battery lifespan.%RESET%
)

echo/
choice /c YN /m "Apply this charge limit"
if %errorlevel%==2 goto MAIN_MENU
echo/

goto SET_LIMIT

:: ============================================================================
:: SET LIMIT - Route to manufacturer-specific method
:: ============================================================================
:SET_LIMIT

:: Detect and route to the correct manufacturer method
echo %manufacturer% | findstr /i "Lenovo" >nul && goto SET_LENOVO
echo %manufacturer% | findstr /i "ASUSTeK ASUS" >nul && goto SET_ASUS
echo %manufacturer% | findstr /i "Microsoft" >nul && goto SET_SURFACE
echo %manufacturer% | findstr /i "Hewlett HP" >nul && goto SET_HP
echo %manufacturer% | findstr /i "Dell" >nul && goto SET_DELL
echo %manufacturer% | findstr /i "Huawei" >nul && goto SET_HUAWEI
echo %manufacturer% | findstr /i "Samsung" >nul && goto SET_SAMSUNG
echo %manufacturer% | findstr /i "LG" >nul && goto SET_LG
echo %manufacturer% | findstr /i "Micro-Star MSI" >nul && goto SET_MSI
echo %manufacturer% | findstr /i "Razer" >nul && goto SET_RAZER
echo %manufacturer% | findstr /i "Toshiba Dynabook" >nul && goto SET_TOSHIBA

:: Unknown manufacturer - try common WMI methods as fallback
goto SET_FALLBACK

:: ============================================================================
:: LENOVO
:: ============================================================================
:SET_LENOVO
echo %CYAN%[Lenovo]%RESET% Applying charge limit via Lenovo Energy Management...
echo/

:: Lenovo uses HKLM\SOFTWARE\Lenovo\PWRMGRV\ConfKeys\Data and WMI
:: The Lenovo Vantage/PWRMGR driver exposes a WMI interface

:: Method 1: Lenovo Energy Management WMI
powershell -NoProfile -Command ^
    "$ns = 'root\WMI'; " ^
    "$class = Get-CimClass -Namespace $ns -ClassName Lenovo_SetBatteryChargeThresholdPercentage -ErrorAction SilentlyContinue; " ^
    "if ($class) { " ^
    "  $params = @{ ChargeThreshold = %limit% }; " ^
    "  Invoke-CimMethod -Namespace $ns -ClassName Lenovo_SetBatteryChargeThresholdPercentage -MethodName SetBatteryChargeThresholdPercentage -Arguments $params -ErrorAction Stop; " ^
    "  Write-Host 'WMI method succeeded'; exit 0 " ^
    "} else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %limit%%% via Lenovo WMI%RESET%
    goto SET_SUCCESS
)

:: Method 2: Lenovo registry (Conservation Mode = 1 for ~60%, 0 for 100%)
:: Only if the Lenovo power manager key already exists: reg add would otherwise
:: create the key and "succeed" without anything reading the value.
reg query "HKLM\SOFTWARE\Lenovo\PWRMGRV\ConfKeys\Data" >nul 2>&1
if %errorlevel% neq 0 goto LENOVO_FAIL
if "%limit%"=="100" (
    reg add "HKLM\SOFTWARE\Lenovo\PWRMGRV\ConfKeys\Data" /v "ChargeMode" /t REG_DWORD /d 0 /f >nul 2>&1
) else (
    reg add "HKLM\SOFTWARE\Lenovo\PWRMGRV\ConfKeys\Data" /v "ChargeMode" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Lenovo\PWRMGRV\ConfKeys\Data" /v "ChargeStopPercentage" /t REG_DWORD /d %limit% /f >nul 2>&1
)
if %errorlevel% neq 0 goto LENOVO_FAIL
echo %YELLOW%[UNVERIFIED] Value written for Lenovo software - open Lenovo Vantage to confirm the threshold.%RESET%
echo %YELLOW%[NOTE] You may need to restart for changes to take effect.%RESET%
goto SET_UNVERIFIED

:LENOVO_FAIL
echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure Lenovo Vantage or Lenovo Energy Management is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: ASUS
:: ============================================================================
:SET_ASUS
echo %CYAN%[ASUS]%RESET% Applying charge limit via ASUS Battery Health Charging...
echo/

:: ASUS uses the ATKACPI WMI interface: DEVS(Device_ID, Control_status) with
:: device ID 0x00120057 (RSOC). Control_status is the charge-stop percentage
:: itself, and the method's out value is 1 on success.
:: MyASUS offers 60% as its lowest limit, so 50% is raised to 60%.

:: Method 1: ASUS ACPI WMI
set "asusVal=%limit%"
if "%limit%"=="50" set "asusVal=60"

:: The out parameter is read by value, not by name, so the check does not
:: depend on how the firmware's WMI class names it.
powershell -NoProfile -Command ^
    "$ns = 'root\WMI'; " ^
    "$inst = Get-CimInstance -Namespace $ns -ClassName AsusAtkWmi_WMNB -ErrorAction SilentlyContinue | Select-Object -First 1; " ^
    "if (-not $inst) { exit 1 }; " ^
    "$r = Invoke-CimMethod -InputObject $inst -MethodName DEVS -Arguments @{ Device_ID = [uint32]0x00120057; Control_status = [uint32]%asusVal% } -ErrorAction Stop; " ^
    "$out = @($r.PSObject.Properties | Where-Object { $_.Name -ne 'PSComputerName' } | ForEach-Object { $_.Value }); " ^
    "if ($out -contains 1) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %asusVal%%% via ASUS WMI%RESET%
    if "%limit%"=="50" echo %YELLOW%[NOTE] ASUS supports 60%% as its lowest limit, so 60%% was used instead of 50%%.%RESET%
    echo %YELLOW%[NOTE] ASUS firmware may reset this after a reboot or sleep unless MyASUS keeps it.%RESET%
    set "limit=%asusVal%"
    goto SET_SUCCESS
)

:: Method 2: ASUS registry for Battery Health Charging
:: Only if the key already exists: reg add would otherwise create it and
:: "succeed" without anything reading the value.
reg query "HKLM\SOFTWARE\ASUS\ASUS Battery Health Charging" >nul 2>&1
if %errorlevel% neq 0 goto ASUS_FAIL
reg add "HKLM\SOFTWARE\ASUS\ASUS Battery Health Charging" /v "ChargeLimit" /t REG_DWORD /d %limit% /f >nul 2>&1
if %errorlevel% neq 0 goto ASUS_FAIL
echo %YELLOW%[UNVERIFIED] Value written for ASUS Battery Health Charging - open MyASUS to confirm the limit.%RESET%
echo %YELLOW%[NOTE] Requires ASUS System Control Interface driver.%RESET%
goto SET_UNVERIFIED

:ASUS_FAIL
echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure ASUS System Control Interface or MyASUS is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: MICROSOFT SURFACE
:: ============================================================================
:SET_SURFACE
echo %CYAN%[Surface]%RESET% Surface Battery Limit is a firmware setting.
echo/

:: The Surface firmware does not read any registry value, so this cannot be
:: set from Windows. Remove the non-functional values that earlier versions
:: of this script wrote (they did nothing).
reg delete "HKLM\SOFTWARE\Microsoft\BatteryLimit" /v "EnableBatteryLimit" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\BatteryLimit" /v "BatteryLimitPercent" /f >nul 2>&1

echo %YELLOW%It cannot be changed from Windows. To set it:%RESET%
echo   1. Shut down, then hold Volume Up and press Power to open Surface UEFI
echo   2. Boot configuration ^> Advanced options ^> Enable Battery Limit
echo      ^(On = stop charging at 50%%, Off = charge to 100%%^)
echo   3. Newer models ^(e.g. Surface Pro 11, Surface Laptop 7^): Surface app ^>
echo      Battery ^& charging ^> Charging mode ^(Limit to 80%% / Charge to 100%%^)
goto SET_FAIL

:: ============================================================================
:: HP
:: ============================================================================
:SET_HP
echo %CYAN%[HP]%RESET% Applying charge limit via HP Battery Health Manager...
echo/

:: HP uses a BIOS/WMI interface via HP_BIOSSetting
:: HP Battery Health Manager values: Let HP Manage, Maximize Health, Let User Decide

:: Method 1: HP WMI BIOS interface
powershell -NoProfile -Command ^
    "$ns = 'root\HP\InstrumentedBIOS'; " ^
    "$class = Get-CimClass -Namespace $ns -ClassName HP_BIOSSetting -ErrorAction SilentlyContinue; " ^
    "if ($class) { " ^
    "  $inst = Get-CimInstance -Namespace $ns -ClassName HP_BIOSSettingInterface; " ^
    "  if (%limit% -eq 100) { " ^
    "    $result = Invoke-CimMethod -InputObject $inst -MethodName SetBIOSSetting -Arguments @{ Name='Battery Health Manager'; Value='Let HP Manage My Battery Charging' }; " ^
    "  } else { " ^
    "    $result = Invoke-CimMethod -InputObject $inst -MethodName SetBIOSSetting -Arguments @{ Name='Battery Health Manager'; Value='Maximize My Battery Health' }; " ^
    "  } " ^
    "  if ($result.Return -eq 0) { Write-Host 'WMI method succeeded'; exit 0 } else { exit 1 } " ^
    "} else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    if "%limit%"=="100" (
        echo %GREEN%[OK] HP Battery Health Manager set to normal charging%RESET%
    ) else (
        echo %GREEN%[OK] HP Battery Health Manager set to maximize health%RESET%
        echo %YELLOW%[NOTE] HP manages the exact threshold. Typical limit is ~80%%.%RESET%
    )
    goto SET_SUCCESS
)

:: Method 2: HP registry policy
:: Only if the policy key already exists: reg add would otherwise create it and
:: "succeed" without anything reading the value.
reg query "HKLM\SOFTWARE\Policies\HP\HP Battery Health Manager" >nul 2>&1
if %errorlevel% neq 0 goto HP_FAIL
if "%limit%"=="100" (
    REM Undo: remove the limiting policy value. reg delete returns 1 when the
    REM value is already absent, so its result is not treated as a failure.
    reg delete "HKLM\SOFTWARE\Policies\HP\HP Battery Health Manager" /v "Setting" /f >nul 2>&1
    echo %GREEN%[OK] HP Battery Health Manager registry policy value removed%RESET%
    echo %YELLOW%[UNVERIFIED] Check Battery Health Manager in BIOS Setup ^(F10^) - it may still limit charging.%RESET%
    goto SET_UNVERIFIED
)
reg add "HKLM\SOFTWARE\Policies\HP\HP Battery Health Manager" /v "Setting" /t REG_DWORD /d 3 /f >nul 2>&1
if %errorlevel% neq 0 goto HP_FAIL
echo %YELLOW%[UNVERIFIED] HP Battery Health Manager policy value written.%RESET%
echo %YELLOW%[NOTE] Requires HP Battery Health Manager driver.%RESET%
goto SET_UNVERIFIED

:HP_FAIL
echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure HP Battery Health Manager is available in BIOS.%RESET%
echo %YELLOW%Some HP models only support this via BIOS Setup (F10 at boot).%RESET%
goto SET_FAIL

:: ============================================================================
:: DELL
:: ============================================================================
:SET_DELL
echo %CYAN%[Dell]%RESET% Applying charge limit via Dell thermal management...
echo/

:: Dell uses SMBIOS/WMI through Dell Command | Power Manager
:: The smbios-thermal-ctl interface or WMI class Dell_SMBIOSBatteryChargeConfiguration

:: Dell's custom charge range: start 50-95%, stop 55-100%, stop - start >= 5.
:: 50% is below Dell's minimum stop value, so it is raised to 55%.
set "dellStop=%limit%"
if "%limit%"=="50" set "dellStop=55"
set /a "dellStart=dellStop-5"

powershell -NoProfile -Command ^
    "$ns = 'root\dcim\sysman\batterychargeconfig'; " ^
    "$class = Get-CimClass -Namespace $ns -ClassName DCIM_BatteryChargeConfiguration -ErrorAction SilentlyContinue; " ^
    "if ($class) { " ^
    "  $inst = Get-CimInstance -Namespace $ns -ClassName DCIM_BatteryChargeConfiguration; " ^
    "  if (%limit% -eq 100) { " ^
    "    $inst.ChargeMode = 'Standard'; " ^
    "  } else { " ^
    "    $inst.ChargeMode = 'Custom'; " ^
    "    $inst.CustomChargeEnd = %dellStop%; " ^
    "    $inst.CustomChargeStart = %dellStart%; " ^
    "  } " ^
    "  Set-CimInstance $inst -ErrorAction Stop; " ^
    "  Write-Host 'WMI method succeeded'; exit 0 " ^
    "} else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %dellStop%%% via Dell WMI%RESET%
    if "%limit%"=="50" echo %YELLOW%[NOTE] Dell's lowest custom limit is 55%%, so 55%% was used instead of 50%%.%RESET%
    set "limit=%dellStop%"
    goto SET_SUCCESS
)

:: Method 2: Dell CCTK (Dell Command | Configure). The installer does not add
:: cctk.exe to PATH, so :FIND_CCTK also checks its default install folders.
call :FIND_CCTK
if defined CCTK (
    if "%limit%"=="100" (
        "!CCTK!" --PrimaryBattChargeCfg=Standard >nul 2>&1
    ) else (
        "!CCTK!" --PrimaryBattChargeCfg=Custom:!dellStart!-!dellStop! >nul 2>&1
    )
    if !errorlevel!==0 (
        echo %GREEN%[OK] Charge limit set to !dellStop!%% via Dell CCTK%RESET%
        if "%limit%"=="50" echo %YELLOW%[NOTE] Dell's lowest custom limit is 55%%, so 55%% was used instead of 50%%.%RESET%
        set "limit=!dellStop!"
        goto SET_SUCCESS
    )
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Options for Dell laptops:%RESET%
echo   1. Install Dell Command ^| Power Manager from Dell support
echo   2. Install Dell Command ^| Configure (CCTK) for command-line control
echo   3. Configure in BIOS: Boot ^> F2 ^> Power Management ^> Battery Charge
goto SET_FAIL

:: ============================================================================
:: HUAWEI
:: ============================================================================
:SET_HUAWEI
echo %CYAN%[Huawei]%RESET% Applying charge limit via Huawei PC Manager...
echo/

:: Only if the Huawei PC Manager key already exists: reg add would otherwise
:: create it and "succeed" without anything reading the value.
reg query "HKLM\SOFTWARE\Huawei\PCManager\BatteryLife" >nul 2>&1
if %errorlevel% neq 0 goto HUAWEI_FAIL
reg add "HKLM\SOFTWARE\Huawei\PCManager\BatteryLife" /v "SmartCharge" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Huawei\PCManager\BatteryLife" /v "MaxChargeCapacity" /t REG_DWORD /d %limit% /f >nul 2>&1
if %errorlevel% neq 0 goto HUAWEI_FAIL
echo %YELLOW%[UNVERIFIED] Value written for Huawei PC Manager - open PC Manager to confirm the limit.%RESET%
goto SET_UNVERIFIED

:HUAWEI_FAIL
echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure Huawei PC Manager is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: SAMSUNG
:: ============================================================================
:SET_SAMSUNG
echo %CYAN%[Samsung]%RESET% Applying charge limit via Samsung Settings...
echo/

:: Samsung uses the SCCI (Samsung Common Communication Interface) WMI
powershell -NoProfile -Command ^
    "$ns = 'root\WMI'; " ^
    "$class = Get-CimClass -Namespace $ns -ClassName SamsungBatteryLifeExtender -ErrorAction SilentlyContinue; " ^
    "if ($class) { " ^
    "  if (%limit% -eq 100) { " ^
    "    Invoke-CimMethod -Namespace $ns -ClassName SamsungBatteryLifeExtender -MethodName SetBatteryLifeExtender -Arguments @{ Enable = $false } -ErrorAction Stop; " ^
    "  } else { " ^
    "    Invoke-CimMethod -Namespace $ns -ClassName SamsungBatteryLifeExtender -MethodName SetBatteryLifeExtender -Arguments @{ Enable = $true } -ErrorAction Stop; " ^
    "  } " ^
    "  Write-Host 'WMI method succeeded'; exit 0 " ^
    "} else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    if "%limit%"=="100" (
        echo %GREEN%[OK] Samsung Battery Life Extender disabled%RESET%
    ) else (
        echo %GREEN%[OK] Samsung Battery Life Extender enabled%RESET%
        echo %YELLOW%[NOTE] Samsung typically limits to 85%% when enabled.%RESET%
    )
    goto SET_SUCCESS
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure Samsung Settings or Samsung System Agent is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: LG
:: ============================================================================
:SET_LG
echo %CYAN%[LG]%RESET% Applying charge limit via LG Control Center...
echo/

:: Only if the LG Control Center key already exists: reg add would otherwise
:: create it and "succeed" without anything reading the value.
reg query "HKLM\SOFTWARE\LG\ControlCenter\BatteryCharge" >nul 2>&1
if %errorlevel% neq 0 goto LG_FAIL
reg add "HKLM\SOFTWARE\LG\ControlCenter\BatteryCharge" /v "ChargeLimit" /t REG_DWORD /d %limit% /f >nul 2>&1
if %errorlevel% neq 0 goto LG_FAIL
echo %YELLOW%[UNVERIFIED] Value written for LG Control Center - open LG Control Center to confirm the limit.%RESET%
goto SET_UNVERIFIED

:LG_FAIL
echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure LG Control Center is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: MSI
:: ============================================================================
:SET_MSI
echo %CYAN%[MSI]%RESET% Applying charge limit via MSI Center...
echo/

:: MSI uses EC (Embedded Controller) commands through MSI WMI interface
powershell -NoProfile -Command ^
    "$ns = 'root\WMI'; " ^
    "$class = Get-CimClass -Namespace $ns -ClassName MSI_BatteryChargeInfo -ErrorAction SilentlyContinue; " ^
    "if ($class) { " ^
    "  $inst = Get-CimInstance -Namespace $ns -ClassName MSI_BatteryChargeInfo; " ^
    "  Invoke-CimMethod -InputObject $inst -MethodName SetChargeLimit -Arguments @{ Limit = %limit% } -ErrorAction Stop; " ^
    "  Write-Host 'WMI method succeeded'; exit 0 " ^
    "} else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %limit%%% via MSI WMI%RESET%
    goto SET_SUCCESS
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure MSI Center or MSI Dragon Center is installed.%RESET%
echo %YELLOW%Some MSI models only support this through BIOS or MSI Center app.%RESET%
goto SET_FAIL

:: ============================================================================
:: RAZER
:: ============================================================================
:SET_RAZER
echo %CYAN%[Razer]%RESET% Applying charge limit via Razer Synapse...
echo/

:: Only if the Razer Synapse key already exists: reg add would otherwise
:: create it and "succeed" without anything reading the value.
reg query "HKLM\SOFTWARE\Razer\Synapse3\BatteryDesktop" >nul 2>&1
if %errorlevel% neq 0 goto RAZER_FAIL
reg add "HKLM\SOFTWARE\Razer\Synapse3\BatteryDesktop" /v "ChargeLimit" /t REG_DWORD /d %limit% /f >nul 2>&1
if %errorlevel% neq 0 goto RAZER_FAIL
echo %YELLOW%[UNVERIFIED] Value written for Razer Synapse 3 - open Synapse to confirm the limit.%RESET%
goto SET_UNVERIFIED

:RAZER_FAIL
echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure Razer Synapse 3 is installed and running.%RESET%
goto SET_FAIL

:: ============================================================================
:: TOSHIBA / DYNABOOK
:: ============================================================================
:SET_TOSHIBA
echo %CYAN%[Toshiba/Dynabook]%RESET% Applying charge limit...
echo/

:: Toshiba uses eco Charge mode via WMI
powershell -NoProfile -Command ^
    "$ns = 'root\WMI'; " ^
    "$class = Get-CimClass -Namespace $ns -ClassName ToshibaACPI -ErrorAction SilentlyContinue; " ^
    "if ($class) { " ^
    "  if (%limit% -lt 100) { " ^
    "    Invoke-CimMethod -Namespace $ns -ClassName ToshibaACPI -MethodName SetEcoCharge -Arguments @{ Enable = 1 } -ErrorAction Stop; " ^
    "  } else { " ^
    "    Invoke-CimMethod -Namespace $ns -ClassName ToshibaACPI -MethodName SetEcoCharge -Arguments @{ Enable = 0 } -ErrorAction Stop; " ^
    "  } " ^
    "  Write-Host 'WMI method succeeded'; exit 0 " ^
    "} else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    if "%limit%"=="100" (
        echo %GREEN%[OK] Toshiba eco Charge disabled%RESET%
    ) else (
        echo %GREEN%[OK] Toshiba eco Charge enabled%RESET%
        echo %YELLOW%[NOTE] Toshiba eco mode typically limits to ~80%%.%RESET%
    )
    goto SET_SUCCESS
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure Toshiba System Settings or Dynabook Settings is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: FALLBACK - Unknown Manufacturer
:: ============================================================================
:SET_FALLBACK
echo %RED%[ERROR] Manufacturer "%manufacturer%" is not directly supported.%RESET%
echo/
echo %WHITE%The following manufacturers are supported:%RESET%
echo   - Lenovo (Vantage / Energy Management)
echo   - ASUS (MyASUS / Battery Health Charging)
echo   - Microsoft Surface (UEFI Battery Limit)
echo   - HP (Battery Health Manager)
echo   - Dell (Command ^| Power Manager)
echo   - Huawei (PC Manager)
echo   - Samsung (Settings / Battery Life Extender)
echo   - LG (Control Center)
echo   - MSI (Center / Dragon Center)
echo   - Razer (Synapse 3)
echo   - Toshiba / Dynabook (System Settings)
echo/
echo %YELLOW%General tips:%RESET%
echo   1. Check your laptop manufacturer's companion app
echo   2. Look in BIOS/UEFI settings (usually under Power Management)
echo   3. Check if your manufacturer provides a WMI/ACPI battery interface
echo/
pause
goto MAIN_MENU

:: ============================================================================
:: SUCCESS / FAILURE handlers
:: ============================================================================
:SET_SUCCESS
echo/
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo %GREEN%  Battery charge limit has been set to %limit%%%.%RESET%
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo/
if not "%limit%"=="100" (
    echo %WHITE%How to undo:%RESET%
    echo   Run this script again and select option [4] to restore 100%% charging.
    echo/
)
echo %YELLOW%[NOTE] Some changes may require a reboot or AC adapter reconnection.%RESET%
echo/
pause
goto MAIN_MENU

:SET_FAIL
echo/
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo %RED%  Failed to set charge limit. See suggestions above.%RESET%
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo/
pause
goto MAIN_MENU

:: A registry value was written for manufacturer software, but nothing confirms
:: that the software or firmware reads it, so do not claim the limit is active.
:SET_UNVERIFIED
echo/
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo %YELLOW%  A setting was written, but the charge limit could not be verified.%RESET%
echo %YELLOW%  Check your manufacturer app or BIOS to confirm it is active.%RESET%
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo/
if not "%limit%"=="100" (
    echo %WHITE%How to undo:%RESET%
    echo   Run this script again and select option [4] to restore 100%% charging,
    echo   or change the setting in your manufacturer app.
    echo/
)
pause
goto MAIN_MENU

:: ============================================================================
:: FIND_CCTK - locate Dell Command | Configure's cctk.exe
:: Sets CCTK to its full path, or leaves CCTK undefined if it is not installed.
:: ============================================================================
:FIND_CCTK
set "CCTK="
if exist "%ProgramFiles(x86)%\Dell\Command Configure\X86_64\cctk.exe" set "CCTK=%ProgramFiles(x86)%\Dell\Command Configure\X86_64\cctk.exe"
if not defined CCTK if exist "%ProgramFiles%\Dell\Command Configure\X86_64\cctk.exe" set "CCTK=%ProgramFiles%\Dell\Command Configure\X86_64\cctk.exe"
if not defined CCTK for /f "delims=" %%p in ('where cctk 2^>nul') do set "CCTK=%%p"
exit /b 0

:: ============================================================================
:: BATTERY STATUS
:: ============================================================================
:BATTERY_STATUS
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                      CURRENT BATTERY STATUS%RESET%
echo %CYAN%============================================================================%RESET%
echo/

powershell -NoProfile -Command ^
    "$bats = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue); $bat = $bats | Select-Object -First 1; " ^
    "if ($bat) { " ^
    "  if ($bats.Count -gt 1) { Write-Host ('  Batteries:         ' + $bats.Count + ' (details below are for the first; capacity is combined)') }; " ^
    "  Write-Host ('  Status:            ' + $bat.Status); " ^
    "  Write-Host ('  Charge:            ' + $bat.EstimatedChargeRemaining + '%%'); " ^
    "  $statusMap = @{1='Discharging';2='AC Power';3='Fully Charged';4='Low';5='Critical';6='Charging';7='Charging/High';8='Charging/Low';9='Charging/Critical';10='Undefined';11='Partially Charged'}; " ^
    "  $desc = $statusMap[[int]$bat.BatteryStatus]; if (-not $desc) { $desc = 'Unknown' }; " ^
    "  Write-Host ('  Battery State:     ' + $desc); " ^
    "  Write-Host ('  Chemistry:         ' + $bat.Chemistry); " ^
    "  Write-Host ('  Name:              ' + $bat.Name); " ^
    "  Write-Host ('  Device ID:         ' + $bat.DeviceID); " ^
    "  Write-Host; " ^
    "  $fullCap = (Get-CimInstance -Namespace root\WMI -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue | Measure-Object -Property FullChargedCapacity -Sum -ErrorAction SilentlyContinue).Sum; " ^
    "  $designCap = (Get-CimInstance -Namespace root\WMI -ClassName BatteryStaticData -ErrorAction SilentlyContinue | Measure-Object -Property DesignedCapacity -Sum -ErrorAction SilentlyContinue).Sum; " ^
    "  if ($fullCap -and $designCap -and $designCap -gt 0) { " ^
    "    $health = [math]::Round(($fullCap / $designCap) * 100, 1); " ^
    "    Write-Host ('  Design Capacity:   ' + $designCap + ' mWh'); " ^
    "    Write-Host ('  Full Charge Cap:   ' + $fullCap + ' mWh'); " ^
    "    Write-Host ('  Battery Health:    ' + $health + '%%'); " ^
    "    if ($health -lt 50) { Write-Host '  [WARNING] Battery health is poor - consider replacement' -ForegroundColor Red } " ^
    "    elseif ($health -lt 80) { Write-Host '  [NOTE] Battery has moderate wear' -ForegroundColor Yellow } " ^
    "    else { Write-Host '  [OK] Battery health is good' -ForegroundColor Green } " ^
    "  } " ^
    "} else { " ^
    "  Write-Host '  No battery detected.' -ForegroundColor Red " ^
    "}"

echo/
echo %CYAN%============================================================================%RESET%
echo/
pause
goto MAIN_MENU

:: ============================================================================
:: DETECT METHOD
:: ============================================================================
:DETECT_METHOD
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                 DETECTING SUPPORTED CHARGE LIMIT METHOD%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   %WHITE%Manufacturer:%RESET% %manufacturer%
echo   %WHITE%Model:%RESET%        %model%
echo/
echo %YELLOW%Checking available interfaces...%RESET%
echo/

:: Check each known WMI namespace / registry key
set "found=0"

echo   Lenovo WMI...
powershell -NoProfile -Command "Get-CimClass -Namespace root\WMI -ClassName Lenovo_SetBatteryChargeThresholdPercentage -ErrorAction Stop" >nul 2>&1
if %errorlevel%==0 (
    echo     %GREEN%[FOUND] Lenovo Battery Charge Threshold WMI%RESET%
    set "found=1"
) else (
    echo     %WHITE%[NOT FOUND]%RESET%
)

echo   ASUS ACPI WMI...
powershell -NoProfile -Command "Get-CimClass -Namespace root\WMI -ClassName AsusAtkWmi_WMNB -ErrorAction Stop" >nul 2>&1
if %errorlevel%==0 (
    echo     %GREEN%[FOUND] ASUS ATK ACPI WMI%RESET%
    set "found=1"
) else (
    echo     %WHITE%[NOT FOUND]%RESET%
)

echo   Surface Battery Limit...
echo     %WHITE%[INFO] UEFI / Surface app setting - cannot be detected from Windows%RESET%

echo   HP BIOS WMI...
powershell -NoProfile -Command "Get-CimClass -Namespace root\HP\InstrumentedBIOS -ClassName HP_BIOSSetting -ErrorAction Stop" >nul 2>&1
if %errorlevel%==0 (
    echo     %GREEN%[FOUND] HP Instrumented BIOS WMI%RESET%
    set "found=1"
) else (
    echo     %WHITE%[NOT FOUND]%RESET%
)

echo   Dell Battery Configuration WMI...
powershell -NoProfile -Command "Get-CimClass -Namespace root\dcim\sysman\batterychargeconfig -ClassName DCIM_BatteryChargeConfiguration -ErrorAction Stop" >nul 2>&1
if %errorlevel%==0 (
    echo     %GREEN%[FOUND] Dell DCIM Battery Charge Configuration%RESET%
    set "found=1"
) else (
    echo     %WHITE%[NOT FOUND]%RESET%
)

echo   Dell CCTK...
call :FIND_CCTK
if defined CCTK (
    echo     %GREEN%[FOUND] Dell Command ^| Configure ^(CCTK^)%RESET%
    set "found=1"
) else (
    echo     %WHITE%[NOT FOUND]%RESET%
)

echo   Samsung Battery Life Extender...
powershell -NoProfile -Command "Get-CimClass -Namespace root\WMI -ClassName SamsungBatteryLifeExtender -ErrorAction Stop" >nul 2>&1
if %errorlevel%==0 (
    echo     %GREEN%[FOUND] Samsung Battery Life Extender WMI%RESET%
    set "found=1"
) else (
    echo     %WHITE%[NOT FOUND]%RESET%
)

echo/
if "%found%"=="0" (
    echo %RED%No supported charge limit interface was detected.%RESET%
    echo/
    echo %YELLOW%This may mean:%RESET%
    echo   - Your manufacturer's companion software is not installed
    echo   - Your laptop model doesn't expose a WMI/ACPI battery interface
    echo   - The charge limit must be set through BIOS or manufacturer app
) else (
    echo %GREEN%At least one supported interface was detected.%RESET%
    echo Use the charge limit options in the main menu to apply changes.
)

echo/
echo %CYAN%============================================================================%RESET%
echo/
pause
goto MAIN_MENU

:: ============================================================================
:: EXIT
:: ============================================================================
:EXIT
echo/
echo %GREEN%Exiting Battery Charge Limit tool.%RESET%
endlocal
exit /b 0
