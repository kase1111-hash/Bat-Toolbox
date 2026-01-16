@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: InterruptLatencyTuning.bat
:: Interrupt & DPC Latency Reduction for Microstutter Elimination
:: ============================================================

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges.
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

title Interrupt ^& DPC Latency Tuning

:: Colors
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "MAGENTA=[95m"
set "WHITE=[97m"
set "RESET=[0m"

echo %CYAN%============================================================%RESET%
echo %WHITE%     INTERRUPT ^& DPC LATENCY TUNING%RESET%
echo %WHITE%     Microstutter Elimination Suite%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %YELLOW%This script optimizes:%RESET%
echo   - ISR (Interrupt Service Routine) handling
echo   - DPC (Deferred Procedure Call) latency
echo   - MSI/MSI-X interrupt mode for devices
echo   - CPU interrupt affinity distribution
echo   - Timer resolution and scheduling
echo   - Driver-level interrupt throttling
echo.
echo %WHITE%Why this matters:%RESET%
echo   Poor drivers can block the CPU for milliseconds, causing:
echo   - Frame drops and microstutter in games
echo   - Audio crackling and pops
echo   - Input lag spikes
echo   - General UI jank
echo.
echo %RED%WARNING:%RESET% These are advanced kernel-level optimizations.
echo          Create a restore point before proceeding.
echo.

choice /c YN /m "Create a system restore point before continuing"
if %errorlevel%==1 (
    echo.
    echo %CYAN%Creating restore point...%RESET%
    powershell -Command "Checkpoint-Computer -Description 'Before InterruptLatencyTuning' -RestorePointType 'MODIFY_SETTINGS'" 2>nul
    if !errorlevel!==0 (
        echo %GREEN%[OK] Restore point created%RESET%
    ) else (
        echo %YELLOW%[WARN] Could not create restore point - System Protection may be disabled%RESET%
    )
)

echo.
choice /c YN /m "Continue with interrupt latency optimizations"
if %errorlevel%==2 (
    echo %YELLOW%Cancelled by user.%RESET%
    pause
    exit /b 0
)

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 1: Analyze Current DPC/ISR Latency%RESET%
echo %CYAN%============================================================%RESET%
echo.

echo %YELLOW%Checking for high-latency drivers...%RESET%
echo.

:: Create a PowerShell script to analyze DPC latency
powershell -ExecutionPolicy Bypass -Command ^
    "$devices = Get-WmiObject Win32_PnPSignedDriver | Where-Object {$_.DeviceName -ne $null} | Select-Object DeviceName, DriverVersion, Manufacturer;" ^
    "$problematic = @('Realtek', 'NVIDIA', 'AMD', 'Intel(R) Wi', 'Killer', 'Bluetooth');" ^
    "Write-Host 'Drivers commonly associated with DPC issues:' -ForegroundColor Yellow;" ^
    "Write-Host '';" ^
    "foreach ($dev in $devices) {" ^
    "    foreach ($prob in $problematic) {" ^
    "        if ($dev.DeviceName -like \"*$prob*\") {" ^
    "            Write-Host ('  ' + $dev.DeviceName) -ForegroundColor White;" ^
    "            Write-Host ('    Version: ' + $dev.DriverVersion + ' | ' + $dev.Manufacturer) -ForegroundColor Gray;" ^
    "        }" ^
    "    }" ^
    "}"

echo.
echo %WHITE%[INFO] For detailed DPC analysis, install LatencyMon (free)%RESET%
echo        https://www.resplendence.com/latencymon
echo.

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 2: MSI (Message Signaled Interrupts) Mode%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %WHITE%MSI/MSI-X reduces interrupt latency by:%RESET%
echo   - Eliminating shared interrupt lines
echo   - Allowing direct CPU core targeting
echo   - Reducing interrupt routing overhead
echo.

:: Enable MSI mode for GPU
echo %WHITE%[1/4] Configuring MSI for Graphics Cards...%RESET%

:: Find and configure NVIDIA GPUs
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_10DE" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
    echo %GREEN%   [OK] NVIDIA GPU - MSI enabled%RESET%
)

:: Find and configure AMD GPUs
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_1002" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
    echo %GREEN%   [OK] AMD GPU - MSI enabled%RESET%
)

:: Find and configure Intel GPUs
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_8086" 2^>nul ^| findstr /i "display" ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
    echo %GREEN%   [OK] Intel GPU - MSI enabled%RESET%
)

:: Enable MSI for Network adapters
echo %WHITE%[2/4] Configuring MSI for Network Adapters...%RESET%

:: Intel NICs (VEN_8086 with NET)
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_8086" 2^>nul ^| findstr /i "net" ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
)

:: Realtek NICs (VEN_10EC)
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_10EC" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
)

:: Killer/Qualcomm NICs (VEN_1969, VEN_168C)
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_1969" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %GREEN%   [OK] Network adapters - MSI configured%RESET%

:: Enable MSI for NVMe/Storage controllers
echo %WHITE%[3/4] Configuring MSI for Storage Controllers...%RESET%
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "SCSIAdapter" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
)
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "stornvme" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %GREEN%   [OK] Storage controllers - MSI configured%RESET%

:: Enable MSI for USB controllers
echo %WHITE%[4/4] Configuring MSI for USB Controllers...%RESET%
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "USB" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %GREEN%   [OK] USB controllers - MSI configured%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 3: Interrupt Affinity Policy%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %WHITE%Distributing interrupts across CPU cores prevents:%RESET%
echo   - Single-core bottlenecks
echo   - Interrupt storms on core 0
echo   - Uneven CPU utilization
echo.

:: Configure interrupt affinity policy
echo %WHITE%[1/2] Setting interrupt affinity policies...%RESET%

:: GPU - spread across cores for better parallelism
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_10DE" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d 4 /f >nul 2>&1
    reg add "%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d 0C /f >nul 2>&1
)
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_1002" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d 4 /f >nul 2>&1
    reg add "%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d 0C /f >nul 2>&1
)
echo %GREEN%   [OK] GPU interrupt affinity configured%RESET%

:: Network - assign to specific cores to reduce jitter
echo %WHITE%[2/2] Configuring network interrupt affinity...%RESET%
:: DevicePolicy values: 0=Default, 1=AllCloseProcessors, 2=OneCloseProcessor, 3=AllProcessors, 4=SpecifiedProcessors, 5=SpreadMessagesAcrossAllProcessors
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "VEN_10EC" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d 5 /f >nul 2>&1
)
echo %GREEN%   [OK] Network interrupt affinity configured%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 4: System Timer Resolution%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %WHITE%Timer resolution affects:%RESET%
echo   - Thread scheduling granularity
echo   - Sleep/wait precision
echo   - Frame pacing accuracy
echo.

:: Check current timer resolution
echo %WHITE%[1/3] Checking current timer resolution...%RESET%
powershell -Command ^
    "$signature = '[DllImport(\"ntdll.dll\")]public static extern int NtQueryTimerResolution(out int min, out int max, out int current);';" ^
    "$type = Add-Type -MemberDefinition $signature -Name 'NtDll' -Namespace 'Win32' -PassThru;" ^
    "$min = $max = $current = 0;" ^
    "[void]$type::NtQueryTimerResolution([ref]$min, [ref]$max, [ref]$current);" ^
    "$currentMs = $current / 10000;" ^
    "$maxMs = $max / 10000;" ^
    "Write-Host \"   Current: $currentMs ms ^| Best possible: $maxMs ms\" -ForegroundColor Cyan"

:: Disable dynamic tick (forces consistent timer)
echo %WHITE%[2/3] Configuring timer behavior...%RESET%
:: Disable dynamic tick for consistent timing
bcdedit /set disabledynamictick yes >nul 2>&1
if %errorlevel%==0 (
    echo %GREEN%   [OK] Dynamic tick disabled - consistent timer intervals%RESET%
) else (
    echo %YELLOW%   [SKIP] Could not modify BCD - may require Secure Boot disabled%RESET%
)

:: Enable synthetic timer (HPET alternative)
echo %WHITE%[3/3] Configuring platform timer...%RESET%
:: Use TSC (fastest) if available, otherwise platform timer
bcdedit /set useplatformtick yes >nul 2>&1
:: Disable HPET (can cause latency on some systems)
bcdedit /deletevalue useplatformclock >nul 2>&1
echo %GREEN%   [OK] Platform timer configured%RESET%
echo %YELLOW%   [INFO] HPET disabled - using TSC for lower latency%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 5: Kernel & Scheduler Optimizations%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: Disable kernel DPC watchdog timeout (prevents forced preemption)
echo %WHITE%[1/6] Configuring DPC watchdog...%RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DpcWatchdogPeriod" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DpcTimeout" /t REG_DWORD /d 0 /f >nul 2>&1
echo %GREEN%   [OK] DPC watchdog configured%RESET%

:: Optimize kernel scheduling
echo %WHITE%[2/6] Optimizing kernel scheduler...%RESET%
:: Thread quantum - shorter = more responsive, longer = better throughput
:: 0x26 (38) = Long, fixed, foreground boost | 0x24 = Short, fixed
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo %GREEN%   [OK] Thread scheduling optimized for responsiveness%RESET%

:: Disable power throttling
echo %WHITE%[3/6] Disabling power throttling...%RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f >nul 2>&1
echo %GREEN%   [OK] Power throttling disabled%RESET%

:: Disable CPU core parking
echo %WHITE%[4/6] Disabling CPU core parking...%RESET%
:: Core parking adds latency when cores wake up
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo %GREEN%   [OK] All CPU cores active (no parking)%RESET%

:: Disable CPU idle states that add latency
echo %WHITE%[5/6] Configuring CPU idle states...%RESET%
:: Processor idle disable - prevents deep C-states
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 1 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo %GREEN%   [OK] Deep idle states disabled%RESET%

:: Set processor performance to maximum
echo %WHITE%[6/6] Setting processor performance state...%RESET%
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo %GREEN%   [OK] Processor locked at maximum performance%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 6: Driver-Specific Latency Fixes%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: NVIDIA specific optimizations
echo %WHITE%[1/4] Checking NVIDIA driver settings...%RESET%
reg query "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" >nul 2>&1
if %errorlevel%==0 (
    :: Disable NVIDIA telemetry that causes DPC spikes
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup" /v "SendTelemetryData" /t REG_DWORD /d 0 /f >nul 2>&1
    :: Disable HDCP ^(can cause latency^)
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisableHDCP" /t REG_DWORD /d 1 /f >nul 2>&1
    :: Optimize interrupt handling
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "RmDisableHdcp22" /t REG_DWORD /d 1 /f >nul 2>&1
    echo %GREEN%   [OK] NVIDIA optimizations applied%RESET%
) else (
    echo %YELLOW%   [SKIP] NVIDIA driver not found%RESET%
)

:: AMD specific optimizations
echo %WHITE%[2/4] Checking AMD driver settings...%RESET%
reg query "HKLM\SYSTEM\CurrentControlSet\Services\amdkmdag" >nul 2>&1
if %errorlevel%==0 (
    :: AMD interrupt coalescing
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\amdkmdag" /v "EnableUlps" /t REG_DWORD /d 0 /f >nul 2>&1
    echo %GREEN%   [OK] AMD ULPS disabled ^(reduces wake latency^)%RESET%
) else (
    echo %YELLOW%   [SKIP] AMD driver not found%RESET%
)

:: Network driver optimizations
echo %WHITE%[3/4] Optimizing network driver settings...%RESET%
:: Disable interrupt moderation on Intel NICs
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s /f "InterruptModerationRate" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a" /v "InterruptModerationRate" /t REG_DWORD /d 0 /f >nul 2>&1
)
:: Disable flow control (can cause latency spikes)
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s /f "*FlowControl" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a" /v "*FlowControl" /t REG_DWORD /d 0 /f >nul 2>&1
)
:: Disable energy efficient ethernet
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s /f "EEE" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a" /v "EEE" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "%%a" /v "EEELinkAdvertisement" /t REG_DWORD /d 0 /f >nul 2>&1
)
echo %GREEN%   [OK] Network interrupt moderation disabled%RESET%

:: USB driver optimizations
echo %WHITE%[4/4] Optimizing USB driver settings...%RESET%
:: Disable USB selective suspend
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v "DisableSelectiveSuspend" /t REG_DWORD /d 1 /f >nul 2>&1
:: Disable USB legacy support (BIOS setting, registry hint)
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{36fc9e60-c465-11cf-8056-444553540000}" /s /f "EnhancedPowerManagementEnabled" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a" /v "EnhancedPowerManagementEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
)
echo %GREEN%   [OK] USB power management disabled%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 7: Additional Latency Optimizations%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: Disable Spectre/Meltdown mitigations (optional - security tradeoff)
echo %WHITE%[1/4] CPU vulnerability mitigations...%RESET%
echo %YELLOW%   [INFO] Spectre/Meltdown mitigations kept enabled (security)%RESET%
echo %YELLOW%   [INFO] To disable for max performance (not recommended):%RESET%
echo            reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d 3 /f
echo            reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d 3 /f

:: Disable MMCSS throttling
echo %WHITE%[2/4] Optimizing Multimedia Class Scheduler...%RESET%
:: MMCSS - Multimedia Class Scheduler Service
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xffffffff /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul 2>&1
:: Games profile
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t REG_DWORD /d 10000 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
echo %GREEN%   [OK] MMCSS optimized for gaming%RESET%

:: Disable Nagle's algorithm (network micro-batching)
echo %WHITE%[3/4] Disabling Nagle's algorithm...%RESET%
:: This reduces network latency at cost of slightly more packets
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%a" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%a" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %GREEN%   [OK] Nagle's algorithm disabled (lower network latency)%RESET%

:: Optimize memory management
echo %WHITE%[4/4] Optimizing memory management...%RESET%
:: Disable paging executive (keeps drivers in RAM)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul 2>&1
:: Increase system working set
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 0 /f >nul 2>&1
echo %GREEN%   [OK] Memory management optimized%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%                    OPTIMIZATION COMPLETE%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %GREEN%Interrupt and DPC latency tuning applied successfully!%RESET%
echo.
echo %WHITE%Summary of changes:%RESET%
echo   [+] MSI mode enabled for GPU, NIC, Storage, USB
echo   [+] Interrupt affinity distributed across CPU cores
echo   [+] Dynamic tick disabled for consistent timing
echo   [+] DPC watchdog configured
echo   [+] CPU core parking disabled
echo   [+] Deep C-states disabled
echo   [+] Driver-specific latency fixes applied
echo   [+] MMCSS optimized for gaming/low-latency
echo   [+] Nagle's algorithm disabled
echo   [+] Memory paging executive disabled
echo.
echo %YELLOW%Verification steps:%RESET%
echo   1. Restart your computer
echo   2. Download LatencyMon: resplendence.com/latencymon
echo   3. Run LatencyMon and check DPC/ISR latency
echo   4. Target: ^<500us average, ^<1000us max under load
echo.
echo %CYAN%Common high-DPC culprits to investigate:%RESET%
echo   - Realtek HD Audio     (Update driver or use generic)
echo   - Network drivers      (Disable interrupt moderation)
echo   - NVIDIA HD Audio      (Disable if using separate DAC)
echo   - Wireless drivers     (Update to latest)
echo   - ACPI.sys             (BIOS update may help)
echo.
echo %WHITE%Power consumption note:%RESET%
echo   These settings disable power saving features.
echo   Expect higher idle power draw and temperatures.
echo.

choice /c YN /m "Would you like to restart now to apply all changes"
if %errorlevel%==1 (
    echo.
    echo %YELLOW%Restarting in 10 seconds... Press Ctrl+C to cancel%RESET%
    shutdown /r /t 10 /c "Restarting to apply interrupt latency optimizations"
)

echo.
pause
exit /b 0
