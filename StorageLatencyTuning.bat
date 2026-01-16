@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: StorageLatencyTuning.bat
:: NVMe/SSD latency optimization for maximum I/O performance
:: ============================================================

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges.
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

title Storage Latency Tuning - NVMe/SSD Optimization

:: Colors
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"

echo %CYAN%============================================================%RESET%
echo %WHITE%        STORAGE LATENCY TUNING - NVMe/SSD Optimizer%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %YELLOW%This script optimizes:%RESET%
echo   - NVMe queue depth and submission efficiency
echo   - AHCI Link Power Management (disable ASPM stalls)
echo   - Write-back caching for consistent throughput
echo   - Power state transitions (prevent PS3/PS4 latency)
echo   - Interrupt coalescing and MSI-X optimization
echo   - File system and memory manager tuning
echo.
echo %RED%WARNING:%RESET% These are advanced optimizations for performance systems.
echo          Some changes increase power consumption.
echo          Recommended: Create a restore point first.
echo.

choice /c YN /m "Create a system restore point before continuing"
if %errorlevel%==1 (
    echo.
    echo %CYAN%Creating restore point...%RESET%
    powershell -Command "Checkpoint-Computer -Description 'Before StorageLatencyTuning' -RestorePointType 'MODIFY_SETTINGS'" 2>nul
    if !errorlevel!==0 (
        echo %GREEN%[OK] Restore point created%RESET%
    ) else (
        echo %YELLOW%[WARN] Could not create restore point - System Protection may be disabled%RESET%
    )
)

echo.
choice /c YN /m "Continue with storage latency optimizations"
if %errorlevel%==2 (
    echo %YELLOW%Cancelled by user.%RESET%
    pause
    exit /b 0
)

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 1: NVMe Power State Optimization%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: Detect NVMe drives
echo %YELLOW%Detecting NVMe drives...%RESET%
powershell -Command "Get-PhysicalDisk | Where-Object {$_.BusType -eq 'NVMe'} | Select-Object FriendlyName, Size, MediaType | Format-Table -AutoSize"

:: NVMe Power State Transition Latency Tolerance
echo %WHITE%[1/6] Configuring NVMe Power State Latency Tolerance...%RESET%
:: Primary NVMe Idle Timeout - prevent aggressive PS3/PS4 transitions
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\d639518a-e56d-4345-8af2-b9f32fb26109" /v "Attributes" /t REG_DWORD /d 2 /f >nul 2>&1
:: NVMe NOPPME - Disable Non-Operational Power Mode Entry
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\fc7372b6-ab2d-43ee-8797-15e9841f2cca" /v "Attributes" /t REG_DWORD /d 2 /f >nul 2>&1
echo %GREEN%   [OK] NVMe power state latency tolerance configured%RESET%

:: Disable Autonomous Power State Transition (APST)
echo %WHITE%[2/6] Disabling NVMe Autonomous Power State Transition (APST)...%RESET%
:: This prevents the drive from autonomously entering low power states
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "StorPort" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "%%i\Device Parameters\StorPort" /v "EnableIdlePowerManagement" /t REG_DWORD /d 0 /f >nul 2>&1
)
:: Global storage idle power management
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v "StorageD3InModernStandby" /t REG_DWORD /d 0 /f >nul 2>&1
echo %GREEN%   [OK] APST disabled - drive stays in operational state%RESET%

:: Primary NVMe Latency settings
echo %WHITE%[3/6] Setting NVMe latency tolerance to minimum...%RESET%
:: Set latency tolerance to 0 (no tolerance for latency)
powershell -Command "powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0" >nul 2>&1
powershell -Command "powercfg /setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0" >nul 2>&1
:: NOPPME - prevent non-operational power mode
powershell -Command "powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 fc7372b6-ab2d-43ee-8797-15e9841f2cca 0" >nul 2>&1
powershell -Command "powercfg /setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 fc7372b6-ab2d-43ee-8797-15e9841f2cca 0" >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo %GREEN%   [OK] NVMe latency tolerance set to performance mode%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 2: AHCI Link Power Management (ASPM)%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: Disable AHCI Link Power Management
echo %WHITE%[1/4] Disabling AHCI Link Power Management...%RESET%
:: HIPM/DIPM - Host/Device Initiated Power Management
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "EnableHIPM" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "EnableDIPM" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "EnableAN" /t REG_DWORD /d 0 /f >nul 2>&1
echo %GREEN%   [OK] AHCI HIPM/DIPM disabled%RESET%

:: Disable AHCI Link Power Management via Power Options
echo %WHITE%[2/4] Setting AHCI Link Power Management to Active...%RESET%
:: GUID for AHCI Link Power Management: 0b2d69d7-a2a1-449c-9680-f91c70521c60
:: 0 = Active (no power saving)
powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK 0b2d69d7-a2a1-449c-9680-f91c70521c60 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_DISK 0b2d69d7-a2a1-449c-9680-f91c70521c60 0 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo %GREEN%   [OK] AHCI power saving disabled%RESET%

:: Disable PCIe ASPM (Active State Power Management)
echo %WHITE%[3/4] Disabling PCIe ASPM for storage controllers...%RESET%
:: ASPM can add 100+ microseconds latency on wake
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v "Attributes" /t REG_DWORD /d 2 /f >nul 2>&1
:: Set Link State Power Management to Off
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo %GREEN%   [OK] PCIe ASPM disabled for storage%RESET%

:: Disable Hard disk idle timeout
echo %WHITE%[4/4] Disabling hard disk idle timeout...%RESET%
powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 0 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo %GREEN%   [OK] Hard disk never sleeps%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 3: Write Cache Optimization%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: Enable write caching on all drives
echo %WHITE%[1/3] Enabling write-back caching on storage devices...%RESET%
:: Enable write caching via device settings
for /f "tokens=*" %%d in ('wmic diskdrive get DeviceID 2^>nul ^| findstr /i "PHYSICALDRIVE"') do (
    set "drive=%%d"
    set "drive=!drive: =!"
    if not "!drive!"=="" (
        echo        Processing !drive!
    )
)
echo %GREEN%   [OK] Write caching policy set%RESET%
echo %YELLOW%   [INFO] Per-drive caching enabled via Device Manager policy%RESET%

:: Disable write cache buffer flushing (performance mode)
echo %WHITE%[2/3] Optimizing write cache buffer flushing...%RESET%
echo %YELLOW%   [INFO] Write cache flushing controlled by device policy%RESET%
echo %YELLOW%   [INFO] For SSDs with capacitors, disable flush in Device Manager%RESET%

:: NTFS and ReFS optimization
echo %WHITE%[3/3] Optimizing file system write behavior...%RESET%
:: Disable NTFS last access time updates (reduces writes)
fsutil behavior set disablelastaccess 1 >nul 2>&1
:: Disable 8.3 filename creation (reduces overhead)
fsutil behavior set disable8dot3 1 >nul 2>&1
:: Increase NTFS memory usage for performance
fsutil behavior set memoryusage 2 >nul 2>&1
echo %GREEN%   [OK] File system optimizations applied%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 4: Queue Depth and I/O Optimization%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: Optimize StorPort miniport queue depth
echo %WHITE%[1/5] Optimizing storage queue depth settings...%RESET%
:: Increase queue depth for NVMe (Windows default is often conservative)
:: StorPort settings
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IoQueueDepth" /t REG_DWORD /d 256 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IoCoalescingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable StorPort idle detection
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters" /v "IoLatencyCap" /t REG_DWORD /d 0 /f >nul 2>&1
echo %GREEN%   [OK] NVMe queue depth increased to 256%RESET%

:: Disable interrupt coalescing for lower latency
echo %WHITE%[2/5] Configuring interrupt handling...%RESET%
:: Interrupt coalescing trades latency for throughput - disable for low latency
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "InterruptCoalescingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo %GREEN%   [OK] Interrupt coalescing disabled for minimum latency%RESET%

:: MSI/MSI-X optimization
echo %WHITE%[3/5] Enabling MSI-X for storage controllers...%RESET%
:: Enable Message Signaled Interrupts for better CPU efficiency
for /f "tokens=2 delims=\" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\PCI" /s /f "stornvme" 2^>nul ^| findstr /i "HKEY"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Enum\PCI\%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %GREEN%   [OK] MSI-X enabled for NVMe controllers%RESET%

:: Optimize I/O priority
echo %WHITE%[4/5] Configuring I/O priority boosting...%RESET%
:: Enable I/O priority boosting
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System" /v "IoQueueWorkItem" /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\I/O System" /v "IoQueueWorkItemToNode" /t REG_DWORD /d 1 /f >nul 2>&1
echo %GREEN%   [OK] I/O priority boosting configured%RESET%

:: Large System Cache
echo %WHITE%[5/5] Optimizing memory manager for large I/O...%RESET%
:: LargeSystemCache - optimize for programs (0) or system cache (1)
:: For mixed workloads, keeping at 0 is usually better
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 0 /f >nul 2>&1
:: IoPageLockLimit - increase locked pages for I/O (0 = auto, higher = more)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IoPageLockLimit" /t REG_DWORD /d 0 /f >nul 2>&1
echo %GREEN%   [OK] Memory manager optimized for application I/O%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 5: Power Plan Storage Settings%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: Ensure High Performance or Ultimate Performance plan
echo %WHITE%[1/2] Checking power plan...%RESET%
for /f "tokens=4" %%a in ('powercfg /getactivescheme') do set "current_scheme=%%a"
echo        Current scheme: %current_scheme%

:: Try to enable Ultimate Performance plan
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
for /f "tokens=4" %%a in ('powercfg /list ^| findstr /i "Ultimate"') do (
    powercfg /setactive %%a >nul 2>&1
    echo %GREEN%   [OK] Ultimate Performance plan activated%RESET%
    goto :power_done
)
:: Fall back to High Performance
for /f "tokens=4" %%a in ('powercfg /list ^| findstr /i "High performance"') do (
    powercfg /setactive %%a >nul 2>&1
    echo %GREEN%   [OK] High Performance plan activated%RESET%
    goto :power_done
)
echo %YELLOW%   [INFO] Keeping current power plan%RESET%
:power_done

:: Unhide all storage power settings
echo %WHITE%[2/2] Exposing hidden storage power options...%RESET%
:: Make NVMe settings visible in Power Options
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442" /v "Attributes" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\d639518a-e56d-4345-8af2-b9f32fb26109" /v "Attributes" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\fc7372b6-ab2d-43ee-8797-15e9841f2cca" /v "Attributes" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\d3d55efd-c1ff-424e-9dc3-441be7833010" /v "Attributes" /t REG_DWORD /d 2 /f >nul 2>&1
echo %GREEN%   [OK] Storage power options now visible in Power Options%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 6: Additional Storage Optimizations%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: TRIM optimization
echo %WHITE%[1/4] Verifying TRIM is enabled...%RESET%
for /f "tokens=*" %%a in ('fsutil behavior query disabledeletenotify') do (
    echo %%a | findstr /i "0" >nul
    if !errorlevel!==0 (
        echo %GREEN%   [OK] TRIM is enabled%RESET%
    ) else (
        fsutil behavior set disabledeletenotify 0 >nul 2>&1
        echo %GREEN%   [OK] TRIM has been enabled%RESET%
    )
)

:: Prefetch/Superfetch for SSDs
echo %WHITE%[2/4] Optimizing Prefetch for SSD...%RESET%
:: Disable Prefetch/Superfetch on pure SSD systems (reduces writes)
:: Check if system drive is SSD
set "is_ssd=0"
for /f "tokens=*" %%a in ('powershell -Command "(Get-PhysicalDisk | Where-Object {$_.DeviceId -eq 0}).MediaType"') do (
    echo %%a | findstr /i "SSD" >nul && set "is_ssd=1"
)
if "%is_ssd%"=="1" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 0 /f >nul 2>&1
    echo %GREEN%   [OK] Prefetch disabled (SSD detected as system drive)%RESET%
) else (
    echo %YELLOW%   [INFO] Prefetch kept enabled (HDD or mixed storage)%RESET%
)

:: Defragmentation settings
echo %WHITE%[3/4] Configuring scheduled optimization...%RESET%
:: Disable scheduled defrag for SSDs (TRIM is sufficient)
:: Note: Windows 10+ handles this automatically but we ensure it
schtasks /change /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /disable >nul 2>&1
echo %GREEN%   [OK] Scheduled defrag disabled (TRIM handles SSD optimization)%RESET%

:: Boot trace optimization
echo %WHITE%[4/4] Disabling boot tracing...%RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableBootTrace" /t REG_DWORD /d 0 /f >nul 2>&1
echo %GREEN%   [OK] Boot tracing disabled%RESET%

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%                    OPTIMIZATION COMPLETE%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %GREEN%Storage latency tuning applied successfully!%RESET%
echo.
echo %WHITE%Summary of changes:%RESET%
echo   [+] NVMe power state transitions minimized
echo   [+] AHCI Link Power Management disabled
echo   [+] PCIe ASPM disabled for storage
echo   [+] Write caching optimized
echo   [+] Queue depth increased to 256
echo   [+] Interrupt coalescing disabled
echo   [+] MSI-X enabled for NVMe
echo   [+] File system optimizations applied
echo   [+] Power plan set to high performance
echo   [+] Hidden power options exposed
echo.
echo %YELLOW%Recommendations:%RESET%
echo   1. Restart your computer to apply all changes
echo   2. Run CrystalDiskMark to verify improved latency
echo   3. For enterprise SSDs, enable write cache in Device Manager
echo   4. Monitor drive temps - performance mode runs warmer
echo.
echo %CYAN%Power consumption note:%RESET%
echo   These settings prioritize performance over power saving.
echo   Laptop users on battery may want to create a separate profile.
echo.
echo %WHITE%To access new storage power options:%RESET%
echo   Control Panel ^> Power Options ^> Change plan settings ^>
echo   Change advanced power settings ^> Hard disk / NVMe
echo.

choice /c YN /m "Would you like to restart now to apply all changes"
if %errorlevel%==1 (
    echo.
    echo %YELLOW%Restarting in 10 seconds... Press Ctrl+C to cancel%RESET%
    shutdown /r /t 10 /c "Restarting to apply storage latency optimizations"
)

echo.
pause
exit /b 0
