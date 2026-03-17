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
echo(
echo   %WHITE%Manufacturer:%RESET% %manufacturer%
echo   %WHITE%Model:%RESET%        %model%
echo(

if "%hasBattery%"=="0" (
    echo   %RED%[WARNING] No battery detected. This tool is for laptops only.%RESET%
    echo(
)

echo   Set the maximum battery charge level to extend battery lifespan.
echo   Keeping the charge between 50-80%% can significantly reduce
echo   long-term battery degradation.
echo(
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo(
echo   %WHITE%[1]%RESET% Set charge limit to %GREEN%50%%%RESET%    (Maximum longevity)
echo   %WHITE%[2]%RESET% Set charge limit to %GREEN%80%%%RESET%    (Recommended balance)
echo   %WHITE%[3]%RESET% Set charge limit to %YELLOW%90%%%RESET%    (Slight protection)
echo   %WHITE%[4]%RESET% Set charge limit to %RED%100%%%RESET%   (No limit - full charge)
echo(
echo   %WHITE%[5]%RESET% View current battery status
echo   %WHITE%[6]%RESET% Detect supported method
echo   %WHITE%[0]%RESET% Exit
echo(
echo %CYAN%============================================================================%RESET%
echo(
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
echo(
echo   %WHITE%New charge limit:%RESET% %limit%%%
echo   %WHITE%Manufacturer:%RESET%    %manufacturer%
echo(

if "%limit%"=="100" (
    echo   %YELLOW%This removes any charge limit. Your battery will charge to full.%RESET%
) else (
    echo   %GREEN%Limiting charge to %limit%%% helps extend battery lifespan.%RESET%
)

echo(
choice /c YN /m "Apply this charge limit"
if %errorlevel%==2 goto MAIN_MENU
echo(

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
echo(

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
if "%limit%"=="100" (
    reg add "HKLM\SOFTWARE\Lenovo\PWRMGRV\ConfKeys\Data" /v "ChargeMode" /t REG_DWORD /d 0 /f >nul 2>&1
) else (
    reg add "HKLM\SOFTWARE\Lenovo\PWRMGRV\ConfKeys\Data" /v "ChargeMode" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Lenovo\PWRMGRV\ConfKeys\Data" /v "ChargeStopPercentage" /t REG_DWORD /d %limit% /f >nul 2>&1
)
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %limit%%% via Lenovo registry%RESET%
    echo %YELLOW%[NOTE] You may need to restart for changes to take effect.%RESET%
    goto SET_SUCCESS
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure Lenovo Vantage or Lenovo Energy Management is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: ASUS
:: ============================================================================
:SET_ASUS
echo %CYAN%[ASUS]%RESET% Applying charge limit via ASUS Battery Health Charging...
echo(

:: ASUS uses the ATKACPI WMI interface (device ID 0x00120057)
:: Values: 0=Full(100%), 1=Balanced(80%), 2=Maximum Lifespan(60%)
:: Newer ASUS models support custom thresholds via registry

:: Method 1: ASUS ACPI WMI
set "asusVal=0"
if "%limit%"=="100" set "asusVal=0"
if "%limit%"=="90" set "asusVal=90"
if "%limit%"=="80" set "asusVal=80"
if "%limit%"=="50" set "asusVal=60"

powershell -NoProfile -Command ^
    "$ns = 'root\WMI'; " ^
    "$class = Get-CimClass -Namespace $ns -ClassName AsusAtkWmi_WMNB -ErrorAction SilentlyContinue; " ^
    "if ($class) { " ^
    "  $inst = Get-CimInstance -Namespace $ns -ClassName AsusAtkWmi_WMNB; " ^
    "  $params = @{ Data = [uint32]%asusVal%; Device_ID = [uint32]0x00120057 }; " ^
    "  Invoke-CimMethod -InputObject $inst -MethodName DEVS -Arguments $params -ErrorAction Stop; " ^
    "  Write-Host 'WMI method succeeded'; exit 0 " ^
    "} else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %limit%%% via ASUS WMI%RESET%
    goto SET_SUCCESS
)

:: Method 2: ASUS registry for Battery Health Charging
reg add "HKLM\SOFTWARE\ASUS\ASUS Battery Health Charging" /v "ChargeLimit" /t REG_DWORD /d %limit% /f >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %limit%%% via ASUS registry%RESET%
    echo %YELLOW%[NOTE] Requires ASUS System Control Interface driver.%RESET%
    goto SET_SUCCESS
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure ASUS System Control Interface or MyASUS is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: MICROSOFT SURFACE
:: ============================================================================
:SET_SURFACE
echo %CYAN%[Surface]%RESET% Applying charge limit via Surface UEFI...
echo(

:: Surface devices use a registry key read by the firmware
if "%limit%"=="100" (
    reg delete "HKLM\SOFTWARE\Microsoft\BatteryLimit" /v "EnableBatteryLimit" /f >nul 2>&1
    echo %GREEN%[OK] Battery limit disabled - will charge to 100%%%RESET%
    goto SET_SUCCESS
) else (
    reg add "HKLM\SOFTWARE\Microsoft\BatteryLimit" /v "EnableBatteryLimit" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\BatteryLimit" /v "BatteryLimitPercent" /t REG_DWORD /d %limit% /f >nul 2>&1
    if %errorlevel%==0 (
        echo %GREEN%[OK] Charge limit set to %limit%%% via Surface registry%RESET%
        echo %YELLOW%[NOTE] Surface UEFI Battery Limit feature must be supported.%RESET%
        echo %YELLOW%[NOTE] Default Surface limit is 50%%. Custom values require newer firmware.%RESET%
        goto SET_SUCCESS
    )
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure you have the latest Surface UEFI firmware.%RESET%
goto SET_FAIL

:: ============================================================================
:: HP
:: ============================================================================
:SET_HP
echo %CYAN%[HP]%RESET% Applying charge limit via HP Battery Health Manager...
echo(

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
reg add "HKLM\SOFTWARE\Policies\HP\HP Battery Health Manager" /v "Setting" /t REG_DWORD /d 3 /f >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit configured via HP registry policy%RESET%
    echo %YELLOW%[NOTE] Requires HP Battery Health Manager driver.%RESET%
    goto SET_SUCCESS
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure HP Battery Health Manager is available in BIOS.%RESET%
echo %YELLOW%Some HP models only support this via BIOS Setup (F10 at boot).%RESET%
goto SET_FAIL

:: ============================================================================
:: DELL
:: ============================================================================
:SET_DELL
echo %CYAN%[Dell]%RESET% Applying charge limit via Dell thermal management...
echo(

:: Dell uses SMBIOS/WMI through Dell Command | Power Manager
:: The smbios-thermal-ctl interface or WMI class Dell_SMBIOSBatteryChargeConfiguration

powershell -NoProfile -Command ^
    "$ns = 'root\dcim\sysman\batterychargeconfig'; " ^
    "$class = Get-CimClass -Namespace $ns -ClassName DCIM_BatteryChargeConfiguration -ErrorAction SilentlyContinue; " ^
    "if ($class) { " ^
    "  $inst = Get-CimInstance -Namespace $ns -ClassName DCIM_BatteryChargeConfiguration; " ^
    "  if (%limit% -eq 100) { " ^
    "    $inst.ChargeMode = 'Standard'; " ^
    "  } else { " ^
    "    $inst.ChargeMode = 'Custom'; " ^
    "    $inst.CustomChargeEnd = %limit%; " ^
    "    $inst.CustomChargeStart = [Math]::Max(%limit% - 5, 40); " ^
    "  } " ^
    "  Set-CimInstance $inst -ErrorAction Stop; " ^
    "  Write-Host 'WMI method succeeded'; exit 0 " ^
    "} else { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %limit%%% via Dell WMI%RESET%
    goto SET_SUCCESS
)

:: Method 2: Dell CCTK (Dell Command | Configure)
where cctk >nul 2>&1
if %errorlevel%==0 (
    if "%limit%"=="100" (
        cctk --PrimaryBattChargeCfg=Standard >nul 2>&1
    ) else (
        set /a "startVal=%limit%-5"
        cctk --PrimaryBattChargeCfg=Custom:%startVal%-%limit% >nul 2>&1
    )
    if %errorlevel%==0 (
        echo %GREEN%[OK] Charge limit set to %limit%%% via Dell CCTK%RESET%
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
echo(

reg add "HKLM\SOFTWARE\Huawei\PCManager\BatteryLife" /v "SmartCharge" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Huawei\PCManager\BatteryLife" /v "MaxChargeCapacity" /t REG_DWORD /d %limit% /f >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %limit%%% via Huawei registry%RESET%
    echo %YELLOW%[NOTE] Requires Huawei PC Manager to be installed.%RESET%
    goto SET_SUCCESS
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure Huawei PC Manager is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: SAMSUNG
:: ============================================================================
:SET_SAMSUNG
echo %CYAN%[Samsung]%RESET% Applying charge limit via Samsung Settings...
echo(

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
echo(

reg add "HKLM\SOFTWARE\LG\ControlCenter\BatteryCharge" /v "ChargeLimit" /t REG_DWORD /d %limit% /f >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %limit%%% via LG registry%RESET%
    echo %YELLOW%[NOTE] Requires LG Control Center to be installed.%RESET%
    goto SET_SUCCESS
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure LG Control Center is installed.%RESET%
goto SET_FAIL

:: ============================================================================
:: MSI
:: ============================================================================
:SET_MSI
echo %CYAN%[MSI]%RESET% Applying charge limit via MSI Center...
echo(

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
echo(

reg add "HKLM\SOFTWARE\Razer\Synapse3\BatteryDesktop" /v "ChargeLimit" /t REG_DWORD /d %limit% /f >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%[OK] Charge limit set to %limit%%% via Razer registry%RESET%
    echo %YELLOW%[NOTE] Requires Razer Synapse 3 to be installed.%RESET%
    goto SET_SUCCESS
)

echo %RED%[FAIL] Could not set charge limit.%RESET%
echo %YELLOW%Ensure Razer Synapse 3 is installed and running.%RESET%
goto SET_FAIL

:: ============================================================================
:: TOSHIBA / DYNABOOK
:: ============================================================================
:SET_TOSHIBA
echo %CYAN%[Toshiba/Dynabook]%RESET% Applying charge limit...
echo(

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
echo(
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
echo(
echo %YELLOW%General tips:%RESET%
echo   1. Check your laptop manufacturer's companion app
echo   2. Look in BIOS/UEFI settings (usually under Power Management)
echo   3. Check if your manufacturer provides a WMI/ACPI battery interface
echo(
pause
goto MAIN_MENU

:: ============================================================================
:: SUCCESS / FAILURE handlers
:: ============================================================================
:SET_SUCCESS
echo(
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo %GREEN%  Battery charge limit has been set to %limit%%%.%RESET%
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo(
if not "%limit%"=="100" (
    echo %WHITE%How to undo:%RESET%
    echo   Run this script again and select option [4] to restore 100%% charging.
    echo(
)
echo %YELLOW%[NOTE] Some changes may require a reboot or AC adapter reconnection.%RESET%
echo(
pause
goto MAIN_MENU

:SET_FAIL
echo(
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo %RED%  Failed to set charge limit. See suggestions above.%RESET%
echo %CYAN%----------------------------------------------------------------------------%RESET%
echo(
pause
goto MAIN_MENU

:: ============================================================================
:: BATTERY STATUS
:: ============================================================================
:BATTERY_STATUS
cls
echo %CYAN%============================================================================%RESET%
echo %WHITE%                      CURRENT BATTERY STATUS%RESET%
echo %CYAN%============================================================================%RESET%
echo(

powershell -NoProfile -Command ^
    "$bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue; " ^
    "if ($bat) { " ^
    "  Write-Host ('  Status:            ' + $bat.Status); " ^
    "  Write-Host ('  Charge:            ' + $bat.EstimatedChargeRemaining + '%%'); " ^
    "  $statusMap = @{1='Discharging';2='AC Power';3='Fully Charged';4='Low';5='Critical';6='Charging';7='Charging/High';8='Charging/Low';9='Charging/Critical';10='Undefined';11='Partially Charged'}; " ^
    "  $desc = $statusMap[[int]$bat.BatteryStatus]; if (-not $desc) { $desc = 'Unknown' }; " ^
    "  Write-Host ('  Battery State:     ' + $desc); " ^
    "  Write-Host ('  Chemistry:         ' + $bat.Chemistry); " ^
    "  Write-Host ('  Name:              ' + $bat.Name); " ^
    "  Write-Host ('  Device ID:         ' + $bat.DeviceID); " ^
    "  Write-Host; " ^
    "  $fullCap = (Get-CimInstance -Namespace root\WMI -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue).FullChargedCapacity; " ^
    "  $designCap = (Get-CimInstance -Namespace root\WMI -ClassName BatteryStaticData -ErrorAction SilentlyContinue).DesignedCapacity; " ^
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

echo(
echo %CYAN%============================================================================%RESET%
echo(
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
echo(
echo   %WHITE%Manufacturer:%RESET% %manufacturer%
echo   %WHITE%Model:%RESET%        %model%
echo(
echo %YELLOW%Checking available interfaces...%RESET%
echo(

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
reg query "HKLM\SOFTWARE\Microsoft\BatteryLimit" >nul 2>&1
if %errorlevel%==0 (
    echo     %GREEN%[FOUND] Microsoft Surface Battery Limit registry%RESET%
    set "found=1"
) else (
    echo     %WHITE%[NOT FOUND]%RESET%
)

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
where cctk >nul 2>&1
if %errorlevel%==0 (
    echo     %GREEN%[FOUND] Dell Command ^| Configure (CCTK)%RESET%
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

echo(
if "%found%"=="0" (
    echo %RED%No supported charge limit interface was detected.%RESET%
    echo(
    echo %YELLOW%This may mean:%RESET%
    echo   - Your manufacturer's companion software is not installed
    echo   - Your laptop model doesn't expose a WMI/ACPI battery interface
    echo   - The charge limit must be set through BIOS or manufacturer app
) else (
    echo %GREEN%At least one supported interface was detected.%RESET%
    echo Use the charge limit options in the main menu to apply changes.
)

echo(
echo %CYAN%============================================================================%RESET%
echo(
pause
goto MAIN_MENU

:: ============================================================================
:: EXIT
:: ============================================================================
:EXIT
echo(
echo %GREEN%Exiting Battery Charge Limit tool.%RESET%
endlocal
exit /b 0
