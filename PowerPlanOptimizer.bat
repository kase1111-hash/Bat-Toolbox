@echo off
setlocal enabledelayedexpansion
title Power Plan Optimizer
color 0B

:: ============================================================================
:: Power Plan Optimizer
:: ============================================================================
:: Goes beyond the basic "High Performance" plan. Tweaks hidden power settings
:: like CPU parking, core frequency scaling, PCI Express link state, USB
:: selective suspend, and timer resolution. Creates a custom "Maximum
:: Performance" plan with explanations for each setting.
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
echo %CYAN% Power Plan Optimizer%RESET%
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

:: Detect current power plan. Output looks like:
::   Power Scheme GUID: 381b4222-... (Balanced)
:: token 4 = the GUID; the text inside parentheses = the friendly name.
for /f "tokens=4" %%a in ('powercfg /getactivescheme 2^>nul') do set "currentPlan=%%a"
for /f "tokens=2 delims=()" %%a in ('powercfg /getactivescheme 2^>nul') do set "currentPlanName=%%a"

:: Detect if laptop or desktop via CIM (wmic is removed on Windows 11 24H2+).
:: Chassis types 8=Portable, 9=Laptop, 10=Notebook, 14=Sub-Notebook.
set "isLaptop=0"
for /f %%c in ('powershell -NoProfile -Command "(Get-CimInstance Win32_SystemEnclosure).ChassisTypes" 2^>nul') do (
    if "%%c"=="8" set "isLaptop=1"
    if "%%c"=="9" set "isLaptop=1"
    if "%%c"=="10" set "isLaptop=1"
    if "%%c"=="14" set "isLaptop=1"
)

echo %WHITE%Current plan:%RESET%  !currentPlanName!
if "!isLaptop!"=="1" (
    echo %WHITE%System type:%RESET%  Laptop
) else (
    echo %WHITE%System type:%RESET%  Desktop
)
echo/

:MainMenu
echo %CYAN%============================================================================%RESET%
echo %CYAN% Main Menu%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   [1] Create "Maximum Performance" plan (desktop/gaming)
echo   [2] Create "Balanced Performance" plan (laptop-friendly)
echo   [3] View current power plan details
echo   [4] Unhide all power settings in Control Panel
echo   [5] Restore Windows default power plans
echo   [0] Exit
echo/

set /p "choice=Select option: "

if "%choice%"=="1" goto MaxPerformance
if "%choice%"=="2" goto BalancedPerf
if "%choice%"=="3" goto ViewPlan
if "%choice%"=="4" goto UnhideSettings
if "%choice%"=="5" goto RestoreDefaults
if "%choice%"=="0" goto Exit

echo %RED%Invalid option.%RESET%
echo/
goto MainMenu

:: ============================================================================
:: Option 1: Maximum Performance Plan
:: ============================================================================
:MaxPerformance
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Create Maximum Performance Plan%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo This plan maximizes performance at the cost of power consumption.
echo/
echo %YELLOW%What it does:%RESET%
echo  - Disables CPU core parking (all cores active)
echo  - Sets CPU minimum to 100%% (no frequency scaling)
echo  - Disables PCI Express power management (ASPM)
echo  - Disables USB selective suspend
echo  - Disables hard disk spin-down
echo  - Sets maximum timer resolution
echo  - Disables display/sleep power saving
echo/
echo %RED%WARNING: This will increase power consumption and heat.%RESET%
if "!isLaptop!"=="1" (
    echo %RED%         On laptops, battery life will be significantly reduced.%RESET%
)
echo/

set /p "confirm=Create Maximum Performance plan? [Y/N]: "
if /i not "%confirm%"=="Y" goto MainMenu

echo/

:: Check if our custom plan already exists
set "PLAN_GUID=77777777-7777-7777-7777-777777777777"
set "planExists=0"
powercfg /list 2>nul | find "!PLAN_GUID!" >nul 2>&1
if not errorlevel 1 (
    echo %YELLOW%[INFO] Maximum Performance plan already exists. Updating settings...%RESET%
    set "planExists=1"
) else (
    :: Duplicate the High Performance plan as our base
    echo [1/10] Creating plan based on High Performance...

    :: First try to get the High Performance GUID
    set "HP_GUID="
    for /f "tokens=4" %%g in ('powercfg /list 2^>nul ^| findstr /i /c:"High Performance"') do set "HP_GUID=%%g"

    if not defined HP_GUID (
        :: High Performance might not be visible, use its known GUID
        set "HP_GUID=8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    )

    powercfg /duplicatescheme !HP_GUID! !PLAN_GUID! >nul 2>&1
    if errorlevel 1 (
        :: Fallback: duplicate the active plan
        powercfg /duplicatescheme SCHEME_CURRENT !PLAN_GUID! >nul 2>&1
    )

    powercfg /changename !PLAN_GUID! "Maximum Performance" "Custom high-performance plan with all power saving disabled. Created by Bat-Toolbox." >nul 2>&1
    echo       %GREEN%[OK] Plan created%RESET%
)

:: Set as active
echo [2/10] Setting as active power plan...
powercfg /setactive !PLAN_GUID!
echo       %GREEN%[OK] Maximum Performance is now active%RESET%

:: ---- CPU Settings ----
echo/
echo [3/10] Configuring CPU settings...
echo       - CPU minimum processor state: 100%%
echo         %CYAN%(Prevents frequency scaling - CPU stays at max clock)%RESET%
powercfg /setacvalueindex !PLAN_GUID! SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg /setdcvalueindex !PLAN_GUID! SUB_PROCESSOR PROCTHROTTLEMIN 100

echo       - CPU maximum processor state: 100%%
powercfg /setacvalueindex !PLAN_GUID! SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setdcvalueindex !PLAN_GUID! SUB_PROCESSOR PROCTHROTTLEMAX 100

echo       - CPU cooling policy: Active
echo         %CYAN%(Fan ramps up before CPU throttles)%RESET%
powercfg /setacvalueindex !PLAN_GUID! SUB_PROCESSOR SYSCOOLPOL 1
powercfg /setdcvalueindex !PLAN_GUID! SUB_PROCESSOR SYSCOOLPOL 1

echo       %GREEN%[OK] CPU configured for maximum performance%RESET%

:: ---- CPU Core Parking ----
echo/
echo [4/10] Disabling CPU core parking...
echo       %CYAN%(Keeps all cores active - prevents wake-up latency)%RESET%

:: Core parking - minimum percentage of cores unparked
powercfg /setacvalueindex !PLAN_GUID! SUB_PROCESSOR CPMINCORES 100 >nul 2>&1
powercfg /setdcvalueindex !PLAN_GUID! SUB_PROCESSOR CPMINCORES 100 >nul 2>&1

:: Core parking - maximum percentage of cores unparked
powercfg /setacvalueindex !PLAN_GUID! SUB_PROCESSOR CPMAXCORES 100 >nul 2>&1
powercfg /setdcvalueindex !PLAN_GUID! SUB_PROCESSOR CPMAXCORES 100 >nul 2>&1

:: Heterogeneous policy (for Intel big.LITTLE / AMD preferred cores)
powercfg /setacvalueindex !PLAN_GUID! SUB_PROCESSOR SCHEDPOLICY 5 >nul 2>&1
powercfg /setdcvalueindex !PLAN_GUID! SUB_PROCESSOR SCHEDPOLICY 5 >nul 2>&1

:: Processor performance boost policy: aggressive
powercfg /setacvalueindex !PLAN_GUID! SUB_PROCESSOR PERFBOOSTPOL 100 >nul 2>&1
powercfg /setdcvalueindex !PLAN_GUID! SUB_PROCESSOR PERFBOOSTPOL 100 >nul 2>&1

:: Processor performance boost mode: aggressive
powercfg /setacvalueindex !PLAN_GUID! SUB_PROCESSOR PERFBOOSTMODE 2 >nul 2>&1
powercfg /setdcvalueindex !PLAN_GUID! SUB_PROCESSOR PERFBOOSTMODE 2 >nul 2>&1

echo       %GREEN%[OK] Core parking disabled%RESET%

:: ---- PCI Express ----
echo/
echo [5/10] Disabling PCI Express Link State Power Management...
echo       %CYAN%(Prevents GPU/NVMe latency spikes from ASPM transitions)%RESET%

:: ASPM: 0 = Off, 1 = Moderate, 2 = Maximum
powercfg /setacvalueindex !PLAN_GUID! SUB_PCIEXPRESS ASPM 0
powercfg /setdcvalueindex !PLAN_GUID! SUB_PCIEXPRESS ASPM 0

echo       %GREEN%[OK] PCI Express ASPM disabled%RESET%

:: ---- USB Settings ----
echo/
echo [6/10] Disabling USB selective suspend...
echo       %CYAN%(Prevents USB devices from disconnecting/reconnecting)%RESET%

:: USB selective suspend: 0 = Disabled
powercfg /setacvalueindex !PLAN_GUID! 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setdcvalueindex !PLAN_GUID! 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

:: USB 3 Link Power Management: 0 = Off
powercfg /setacvalueindex !PLAN_GUID! 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1
powercfg /setdcvalueindex !PLAN_GUID! 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1

echo       %GREEN%[OK] USB suspend disabled%RESET%

:: ---- Hard Disk ----
echo/
echo [7/10] Disabling hard disk spin-down...
echo       %CYAN%(Keeps drives always ready - eliminates spin-up delay)%RESET%

:: 0 = never spin down
powercfg /setacvalueindex !PLAN_GUID! SUB_DISK DISKIDLE 0
powercfg /setdcvalueindex !PLAN_GUID! SUB_DISK DISKIDLE 0

:: NVMe power state transition latency tolerance
powercfg /setacvalueindex !PLAN_GUID! SUB_DISK dab60367-53fe-4fbc-825e-521d069d2456 0 >nul 2>&1
powercfg /setdcvalueindex !PLAN_GUID! SUB_DISK dab60367-53fe-4fbc-825e-521d069d2456 0 >nul 2>&1

echo       %GREEN%[OK] Disk always-on configured%RESET%

:: ---- Display and Sleep ----
echo/
echo [8/10] Configuring display and sleep settings...
echo       %CYAN%(Disable screen timeout and sleep for uninterrupted operation)%RESET%

:: Display off after: 0 = never (AC), 15 min (DC/battery)
powercfg /setacvalueindex !PLAN_GUID! SUB_VIDEO VIDEOIDLE 0
if "!isLaptop!"=="1" (
    powercfg /setdcvalueindex !PLAN_GUID! SUB_VIDEO VIDEOIDLE 15
) else (
    powercfg /setdcvalueindex !PLAN_GUID! SUB_VIDEO VIDEOIDLE 0
)

:: Sleep after: 0 = never
powercfg /setacvalueindex !PLAN_GUID! SUB_SLEEP STANDBYIDLE 0
powercfg /setdcvalueindex !PLAN_GUID! SUB_SLEEP STANDBYIDLE 0

:: Hibernate after: 0 = never
powercfg /setacvalueindex !PLAN_GUID! SUB_SLEEP HIBERNATEIDLE 0
powercfg /setdcvalueindex !PLAN_GUID! SUB_SLEEP HIBERNATEIDLE 0

:: Allow away mode: enabled
powercfg /setacvalueindex !PLAN_GUID! SUB_SLEEP AWAYMODE 1 >nul 2>&1
powercfg /setdcvalueindex !PLAN_GUID! SUB_SLEEP AWAYMODE 1 >nul 2>&1

echo       %GREEN%[OK] Display/sleep configured%RESET%

:: ---- Timer Resolution ----
echo/
echo [9/10] Configuring system timer resolution...
echo       %CYAN%(Higher resolution = more precise scheduling, lower latency)%RESET%

:: Timer resolution is a BOOT setting, not a power-plan value. The old code set
:: SUB_SLEEP RTCWAKE (which is "allow wake timers", unrelated - and it actually
:: enabled them). Disabling the dynamic tick keeps the platform timer at a fixed
:: high rate for lower scheduling latency. Takes effect after a reboot.
bcdedit /set disabledynamictick yes >nul 2>&1

:: Disable power throttling
powercfg /setacvalueindex !PLAN_GUID! SUB_PROCESSOR THROTTLING 0 >nul 2>&1
powercfg /setdcvalueindex !PLAN_GUID! SUB_PROCESSOR THROTTLING 0 >nul 2>&1

echo       %GREEN%[OK] Timer resolution optimized%RESET%

:: ---- Network Adapter ----
echo/
echo [10/10] Configuring network adapter power settings...
echo       %CYAN%(Prevents Wi-Fi/Ethernet from sleeping mid-game)%RESET%

:: Wireless adapter power saving mode: 1 = Maximum Performance
powercfg /setacvalueindex !PLAN_GUID! 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 1
powercfg /setdcvalueindex !PLAN_GUID! 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 1

echo       %GREEN%[OK] Network adapter configured%RESET%

:: Apply changes
powercfg /setactive !PLAN_GUID!

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Maximum Performance Plan Applied%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo %GREEN%All settings applied successfully!%RESET%
echo/
echo Settings summary:
echo   CPU min/max state:          100%% / 100%%
echo   CPU cooling policy:         Active (fan before throttle)
echo   Core parking:               Disabled (all cores active)
echo   Boost policy:               Aggressive
echo   PCI Express ASPM:           Off
echo   USB selective suspend:      Disabled
echo   Hard disk spin-down:        Never
echo   Display timeout (AC):       Never
echo   Sleep/hibernate:            Never
echo   Timer resolution:           Fixed tick (after reboot)
echo   Network adapter power:      Maximum Performance
echo/

if "!isLaptop!"=="1" (
    echo %YELLOW%LAPTOP NOTE: Battery life will be significantly reduced.%RESET%
    echo %YELLOW%Switch to "Balanced Performance" (option 2) when on battery.%RESET%
    echo/
)

echo %YELLOW%To switch back: Control Panel ^> Power Options ^> select another plan%RESET%
echo %YELLOW%Or run this script ^> option [5] to restore defaults.%RESET%
echo/

pause
goto MainMenu

:: ============================================================================
:: Option 2: Balanced Performance Plan
:: ============================================================================
:BalancedPerf
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Create Balanced Performance Plan%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo This plan optimizes performance while respecting power/thermal limits.
echo Good for laptops or quiet desktops.
echo/

set /p "confirm=Create Balanced Performance plan? [Y/N]: "
if /i not "%confirm%"=="Y" goto MainMenu

echo/

set "BAL_GUID=88888888-8888-8888-8888-888888888888"

:: Check if it already exists
powercfg /list 2>nul | find "!BAL_GUID!" >nul 2>&1
if not errorlevel 1 (
    echo %YELLOW%[INFO] Balanced Performance plan already exists. Updating...%RESET%
) else (
    :: Duplicate Balanced plan
    powercfg /duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e !BAL_GUID! >nul 2>&1
    if errorlevel 1 (
        powercfg /duplicatescheme SCHEME_CURRENT !BAL_GUID! >nul 2>&1
    )

    powercfg /changename !BAL_GUID! "Balanced Performance" "Performance-optimized plan that respects thermal/power limits. Created by Bat-Toolbox." >nul 2>&1
)

echo [1/6] Configuring CPU...
:: CPU: allow scaling but set a high floor
powercfg /setacvalueindex !BAL_GUID! SUB_PROCESSOR PROCTHROTTLEMIN 10
powercfg /setdcvalueindex !BAL_GUID! SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg /setacvalueindex !BAL_GUID! SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setdcvalueindex !BAL_GUID! SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setacvalueindex !BAL_GUID! SUB_PROCESSOR SYSCOOLPOL 1
powercfg /setdcvalueindex !BAL_GUID! SUB_PROCESSOR SYSCOOLPOL 1

:: Moderate core parking
powercfg /setacvalueindex !BAL_GUID! SUB_PROCESSOR CPMINCORES 50 >nul 2>&1
powercfg /setdcvalueindex !BAL_GUID! SUB_PROCESSOR CPMINCORES 25 >nul 2>&1

:: Boost: enabled but not forced
powercfg /setacvalueindex !BAL_GUID! SUB_PROCESSOR PERFBOOSTPOL 60 >nul 2>&1
powercfg /setdcvalueindex !BAL_GUID! SUB_PROCESSOR PERFBOOSTPOL 40 >nul 2>&1
echo       %GREEN%[OK] CPU configured%RESET%

echo [2/6] Configuring PCI Express...
:: ASPM: moderate saving on battery, off on AC
powercfg /setacvalueindex !BAL_GUID! SUB_PCIEXPRESS ASPM 0
powercfg /setdcvalueindex !BAL_GUID! SUB_PCIEXPRESS ASPM 1
echo       %GREEN%[OK] PCI Express configured%RESET%

echo [3/6] Configuring USB...
powercfg /setacvalueindex !BAL_GUID! 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setdcvalueindex !BAL_GUID! 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
echo       %GREEN%[OK] USB configured%RESET%

echo [4/6] Configuring storage...
powercfg /setacvalueindex !BAL_GUID! SUB_DISK DISKIDLE 0
powercfg /setdcvalueindex !BAL_GUID! SUB_DISK DISKIDLE 20
echo       %GREEN%[OK] Storage configured%RESET%

echo [5/6] Configuring display/sleep...
powercfg /setacvalueindex !BAL_GUID! SUB_VIDEO VIDEOIDLE 15
powercfg /setdcvalueindex !BAL_GUID! SUB_VIDEO VIDEOIDLE 5
powercfg /setacvalueindex !BAL_GUID! SUB_SLEEP STANDBYIDLE 0
powercfg /setdcvalueindex !BAL_GUID! SUB_SLEEP STANDBYIDLE 30
echo       %GREEN%[OK] Display/sleep configured%RESET%

echo [6/6] Configuring network...
powercfg /setacvalueindex !BAL_GUID! 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 1
powercfg /setdcvalueindex !BAL_GUID! 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 3
echo       %GREEN%[OK] Network configured%RESET%

powercfg /setactive !BAL_GUID!

echo/
echo %GREEN%Balanced Performance plan created and activated!%RESET%
echo/
echo AC (Plugged In):
echo   CPU scaling:        10-100%%, boost enabled
echo   Core parking:       50%% cores minimum
echo   PCI Express:        ASPM off
echo   USB suspend:        Disabled
echo   Disk spin-down:     Never
echo   Display off:        15 minutes
echo   Sleep:              Never
echo/
echo DC (Battery):
echo   CPU scaling:        5-100%%, moderate boost
echo   Core parking:       25%% cores minimum
echo   PCI Express:        Moderate saving
echo   USB suspend:        Enabled
echo   Disk spin-down:     20 minutes
echo   Display off:        5 minutes
echo   Sleep:              30 minutes
echo/

pause
goto MainMenu

:: ============================================================================
:: Option 3: View Current Plan
:: ============================================================================
:ViewPlan
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Current Power Plan Details%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo %WHITE%Available power plans:%RESET%
powercfg /list 2>nul
echo/

echo %WHITE%Active plan settings:%RESET%
echo/

set "PSPLAN=%TEMP%\powerplan_view.ps1"

(
echo $plan = powercfg /getactivescheme
echo Write-Host $plan -ForegroundColor Cyan
echo Write-Host ""
echo/
echo $settings = @^(
echo     @{ Name='CPU Min State'; Sub='SUB_PROCESSOR'; Setting='PROCTHROTTLEMIN' },
echo     @{ Name='CPU Max State'; Sub='SUB_PROCESSOR'; Setting='PROCTHROTTLEMAX' },
echo     @{ Name='CPU Cooling Policy'; Sub='SUB_PROCESSOR'; Setting='SYSCOOLPOL' },
echo     @{ Name='PCI Express ASPM'; Sub='SUB_PCIEXPRESS'; Setting='ASPM' },
echo     @{ Name='Hard Disk Timeout'; Sub='SUB_DISK'; Setting='DISKIDLE' },
echo     @{ Name='Display Timeout'; Sub='SUB_VIDEO'; Setting='VIDEOIDLE' },
echo     @{ Name='Sleep Timeout'; Sub='SUB_SLEEP'; Setting='STANDBYIDLE' },
echo     @{ Name='Hibernate Timeout'; Sub='SUB_SLEEP'; Setting='HIBERNATEIDLE' }
echo ^)
echo/
echo foreach ^($s in $settings^) {
echo     $output = powercfg /query SCHEME_CURRENT $s.Sub $s.Setting 2^>$null
echo     $acLine = $output ^| Select-String 'Current AC Power Setting Index'
echo     $dcLine = $output ^| Select-String 'Current DC Power Setting Index'
echo     $acVal = if ^($acLine^) { ^($acLine -split ': '^)[1].Trim^(^) } else { 'N/A' }
echo     $dcVal = if ^($dcLine^) { ^($dcLine -split ': '^)[1].Trim^(^) } else { 'N/A' }
echo     $name = $s.Name.PadRight^(25^)
echo     Write-Host "  $name AC: $acVal    DC: $dcVal"
echo }
echo/
echo # Check core parking
echo Write-Host ""
echo Write-Host "Core Parking:" -ForegroundColor White
echo $cpOutput = powercfg /query SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 2^>$null
echo $cpAC = $cpOutput ^| Select-String 'Current AC Power Setting Index'
echo if ^($cpAC^) {
echo     $val = ^($cpAC -split ': '^)[1].Trim^(^)
echo     Write-Host "  Min cores unparked:     $val"
echo } else {
echo     Write-Host "  Core parking data not available ^(may be hidden^)"
echo }
echo/
echo # USB selective suspend
echo Write-Host "USB Settings:" -ForegroundColor White
echo $usbOut = powercfg /query SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 2^>$null
echo $usbAC = $usbOut ^| Select-String 'Current AC Power Setting Index'
echo if ^($usbAC^) {
echo     $val = ^($usbAC -split ': '^)[1].Trim^(^)
echo     $status = if ^($val -eq '0x00000000'^) { 'Disabled' } else { 'Enabled' }
echo     Write-Host "  USB Selective Suspend:   $status ^($val^)"
echo }
) > "!PSPLAN!"

powershell -ExecutionPolicy Bypass -File "!PSPLAN!" 2>nul
del "!PSPLAN!" 2>nul

echo/
pause
goto MainMenu

:: ============================================================================
:: Option 4: Unhide All Settings
:: ============================================================================
:UnhideSettings
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Unhide Hidden Power Settings%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo Windows hides many power settings by default. This makes them all visible
echo in the Power Options advanced settings dialog.
echo/

set /p "confirm=Unhide all power settings? [Y/N]: "
if /i not "%confirm%"=="Y" goto MainMenu

echo/
echo Unhiding power settings in registry...

:: Unhide all power settings by setting Attributes to 2
set "PSUNHIDE=%TEMP%\unhide_power.ps1"

(
echo $count = 0
echo $powerKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings'
echo Get-ChildItem -Path $powerKey -Recurse -ErrorAction SilentlyContinue ^| ForEach-Object {
echo     $attrs = Get-ItemProperty -Path $_.PSPath -Name 'Attributes' -ErrorAction SilentlyContinue
echo     if ^($attrs -and $attrs.Attributes -ne 2^) {
echo         Set-ItemProperty -Path $_.PSPath -Name 'Attributes' -Value 2 -ErrorAction SilentlyContinue
echo         $count++
echo     }
echo }
echo Write-Host "Unhidden $count power settings." -ForegroundColor Green
) > "!PSUNHIDE!"

powershell -ExecutionPolicy Bypass -File "!PSUNHIDE!" 2>nul
del "!PSUNHIDE!" 2>nul

echo/
echo %GREEN%[OK] Hidden power settings are now visible.%RESET%
echo/
echo To access: Control Panel ^> Power Options ^> Change plan settings ^>
echo            Change advanced power settings
echo/
echo You will now see additional options like:
echo  - Processor performance core parking min/max cores
echo  - Processor performance boost policy/mode
echo  - NVMe latency tolerance settings
echo  - GPU preference policies
echo  - Network adapter power settings
echo/

pause
goto MainMenu

:: ============================================================================
:: Option 5: Restore Defaults
:: ============================================================================
:RestoreDefaults
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Restore Default Power Plans%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo This will restore Windows default power plans and remove custom plans.
echo/

set /p "confirm=Restore defaults? [Y/N]: "
if /i not "%confirm%"=="Y" goto MainMenu

echo/

:: Switch to Balanced first
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
echo       - Switched to Balanced plan

:: Delete custom plans
powercfg /delete 77777777-7777-7777-7777-777777777777 >nul 2>&1
echo       - Removed Maximum Performance plan (if it existed)
powercfg /delete 88888888-8888-8888-8888-888888888888 >nul 2>&1
echo       - Removed Balanced Performance plan (if it existed)

:: Restore default plans
powercfg /restoredefaultschemes >nul 2>&1
echo       - Restored all default power schemes

echo/
echo %GREEN%[OK] Default power plans restored.%RESET%
echo     Active plan: Balanced
echo/

pause
goto MainMenu

:Exit
echo/
echo Goodbye.
exit /b 0
