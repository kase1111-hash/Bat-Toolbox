@echo off
setlocal enabledelayedexpansion
title Pagefile Tuner
color 0B

:: ============================================================================
:: Pagefile Tuner
:: ============================================================================
:: Analyzes RAM usage patterns, recommends pagefile size, offers to move it
:: to a faster drive, or lock it to a fixed size to avoid fragmentation.
:: Shows current vs recommended configuration.
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
echo %CYAN% Pagefile Tuner%RESET%
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

echo %GREEN%[INFO] Administrator privileges confirmed.%RESET%
echo/

:MainMenu
echo %CYAN%============================================================================%RESET%
echo %CYAN% Main Menu%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   [1] Analyze current pagefile and RAM usage
echo   [2] Apply recommended pagefile settings
echo   [3] Set custom fixed pagefile size
echo   [4] Move pagefile to a different drive
echo   [5] Disable pagefile (not recommended)
echo   [6] Restore Windows automatic management
echo   [0] Exit
echo/

set "choice="
set /p "choice=Select option: "

if "!choice!"=="1" goto Analyze
if "!choice!"=="2" goto ApplyRecommended
if "!choice!"=="3" goto CustomSize
if "!choice!"=="4" goto MoveDrive
if "!choice!"=="5" goto DisablePagefile
if "!choice!"=="6" goto RestoreAutomatic
if "!choice!"=="0" goto Exit

echo %RED%Invalid option.%RESET%
echo/
goto MainMenu

:: ============================================================================
:: Option 1: Analyze
:: ============================================================================
:Analyze
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% System Memory and Pagefile Analysis%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [1/5] Gathering system information...
echo/

:: Get RAM info
set "PSANALYZE=%TEMP%\pagefile_analyze.ps1"

(
echo # System Memory Info
echo $os = Get-CimInstance Win32_OperatingSystem
echo $cs = Get-CimInstance Win32_ComputerSystem
echo $totalRAM = [math]::Round^($cs.TotalPhysicalMemory / 1GB, 2^)
echo $freeRAM = [math]::Round^($os.FreePhysicalMemory / 1MB, 2^)
echo $usedRAM = [math]::Round^($totalRAM - $freeRAM, 2^)
echo $usedPct = [math]::Round^(^($usedRAM / $totalRAM^) * 100, 1^)
echo/
echo Write-Host "  PHYSICAL MEMORY" -ForegroundColor White
echo Write-Host "  ---------------"
echo Write-Host "  Total RAM:         $totalRAM GB"
echo Write-Host "  Used RAM:          $usedRAM GB ($usedPct%%)"
echo Write-Host "  Free RAM:          $freeRAM GB"
echo Write-Host ""
echo/
echo # Pagefile Info
echo Write-Host "  CURRENT PAGEFILE" -ForegroundColor White
echo Write-Host "  ----------------"
echo/
echo $pagefiles = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue
echo if ^($pagefiles^) {
echo     foreach ^($pf in $pagefiles^) {
echo         $sizeMB = $pf.AllocatedBaseSize
echo         $usedMB = $pf.CurrentUsage
echo         $peakMB = $pf.PeakUsage
echo         $sizeGB = [math]::Round^($sizeMB / 1024, 2^)
echo         $usedGB = [math]::Round^($usedMB / 1024, 2^)
echo         $peakGB = [math]::Round^($peakMB / 1024, 2^)
echo         $usePct = if ^($sizeMB -gt 0^) { [math]::Round^(^($usedMB / $sizeMB^) * 100, 1^) } else { 0 }
echo         Write-Host "  Location:          $($pf.Name)"
echo         Write-Host "  Allocated Size:    $sizeGB GB ($sizeMB MB)"
echo         Write-Host "  Current Usage:     $usedGB GB ($usedMB MB) ($usePct%%)"
echo         Write-Host "  Peak Usage:        $peakGB GB ($peakMB MB)"
echo     }
echo } else {
echo     Write-Host "  No pagefile detected^!" -ForegroundColor Red
echo }
echo Write-Host ""
echo/
echo # Pagefile settings from WMI
echo Write-Host "  PAGEFILE SETTINGS" -ForegroundColor White
echo Write-Host "  -----------------"
echo/
echo $pfSettings = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
echo if ^($pfSettings^) {
echo     foreach ^($pfs in $pfSettings^) {
echo         $initMB = $pfs.InitialSize
echo         $maxMB = $pfs.MaximumSize
echo         if ^($initMB -eq 0 -and $maxMB -eq 0^) {
echo             Write-Host "  $($pfs.Name): System Managed (automatic)" -ForegroundColor Yellow
echo         } else {
echo             Write-Host "  $($pfs.Name): Fixed - Initial: $initMB MB, Maximum: $maxMB MB"
echo         }
echo     }
echo } else {
echo     Write-Host "  System Managed (automatic)" -ForegroundColor Yellow
echo }
echo Write-Host ""
echo/
echo # Check if system managed
echo $autoManaged = ^(Get-CimInstance Win32_ComputerSystem^).AutomaticManagedPagefile
echo if ^($autoManaged^) {
echo     Write-Host "  Management:        Automatic (Windows controlled)" -ForegroundColor Yellow
echo } else {
echo     Write-Host "  Management:        Manual (user configured)"
echo }
echo Write-Host ""
echo/
echo # Drive analysis
echo Write-Host "  AVAILABLE DRIVES" -ForegroundColor White
echo Write-Host "  ----------------"
echo/
echo $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
echo foreach ^($d in $drives^) {
echo     $totalGB = [math]::Round^($d.Size / 1GB, 1^)
echo     $freeGB = [math]::Round^($d.FreeSpace / 1GB, 1^)
echo     $driveLetter = $d.DeviceID
echo/
echo     # Detect if SSD or HDD
echo     $diskNum = ^(Get-Partition -DriveLetter $driveLetter[0] -ErrorAction SilentlyContinue^).DiskNumber
echo     $mediaType = 'Unknown'
echo     if ^($diskNum -ne $null^) {
echo         $physDisk = Get-PhysicalDisk ^| Where-Object { $_.DeviceID -eq $diskNum }
echo         if ^($physDisk^) { $mediaType = if ^($physDisk.BusType -eq 'NVMe'^) { 'NVMe' } else { $physDisk.MediaType } }
echo     }
echo/
echo     $typeStr = switch ^($mediaType^) {
echo         'SSD' { 'SSD' }
echo         'NVMe' { 'NVMe' }
echo         'HDD' { 'HDD' }
echo         'Unspecified' { 'SSD/HDD' }
echo         default { $mediaType }
echo     }
echo/
echo     Write-Host "  $driveLetter  $totalGB GB total, $freeGB GB free [$typeStr]"
echo }
echo Write-Host ""
echo/
echo # Recommendations
echo Write-Host "  RECOMMENDATIONS" -ForegroundColor White
echo Write-Host "  ---------------"
echo Write-Host ""
echo/
echo $totalRAMint = [int]$totalRAM
echo/
echo # Calculate recommended sizes
echo if ^($totalRAMint -ge 64^) {
echo     $recMin = [math]::Max^(1024, [int]^($totalRAMint * 1024 * 0.25^)^)
echo     $recMax = $recMin
echo     Write-Host "  With $totalRAMint GB RAM, pagefile usage is typically minimal."
echo     Write-Host "  You could even disable it if you never exceed RAM capacity."
echo     Write-Host ""
echo     Write-Host "  Recommended: Fixed $([math]::Round($recMin / 1024, 1)) GB" -ForegroundColor Green
echo     Write-Host "  (Keeps crash dump support and prevents edge-case OOM)"
echo } elseif ^($totalRAMint -ge 32^) {
echo     $recMin = [int]^($totalRAMint * 1024 * 0.5^)
echo     $recMax = $recMin
echo     Write-Host "  With $totalRAMint GB RAM, a moderate fixed pagefile is recommended."
echo     Write-Host ""
echo     Write-Host "  Recommended: Fixed $([math]::Round($recMin / 1024, 1)) GB" -ForegroundColor Green
echo } elseif ^($totalRAMint -ge 16^) {
echo     $recMin = [int]^($totalRAMint * 1024 * 1.0^)
echo     $recMax = [int]^($totalRAMint * 1024 * 1.5^)
echo     Write-Host "  With $totalRAMint GB RAM, a standard pagefile is important."
echo     Write-Host ""
echo     Write-Host "  Recommended: Fixed $([math]::Round($recMin / 1024, 1)) GB" -ForegroundColor Green
echo     Write-Host "  (Or $([math]::Round($recMin / 1024, 1)) - $([math]::Round($recMax / 1024, 1)) GB if you multitask heavily)"
echo } else {
echo     $recMin = [int]^($totalRAMint * 1024 * 1.5^)
echo     $recMax = [int]^($totalRAMint * 1024 * 3.0^)
echo     Write-Host "  With $totalRAMint GB RAM, a large pagefile is essential." -ForegroundColor Yellow
echo     Write-Host "  Running out of pagefile can cause crashes."
echo     Write-Host ""
echo     Write-Host "  Recommended: $([math]::Round($recMin / 1024, 1)) - $([math]::Round($recMax / 1024, 1)) GB" -ForegroundColor Green
echo     Write-Host "  Consider upgrading RAM if possible."
echo }
echo/
echo Write-Host ""
echo Write-Host "  General guidelines:" -ForegroundColor Yellow
echo Write-Host "   - Fixed size prevents fragmentation (set min = max)"
echo Write-Host "   - Place pagefile on the fastest drive (NVMe > SSD > HDD)"
echo Write-Host "   - If on HDD, a larger pagefile on SSD is much better"
echo Write-Host "   - Leave at least 10%% free space on the pagefile drive"
echo Write-Host "   - For crash dumps, pagefile must be >= RAM size on C:"
echo Write-Host ""
echo/
echo # Export values for batch script to read
echo "$recMin" ^| Out-File -FilePath "$env:TEMP\pf_recmin.txt" -Encoding ascii
echo "$recMax" ^| Out-File -FilePath "$env:TEMP\pf_recmax.txt" -Encoding ascii
echo "$totalRAMint" ^| Out-File -FilePath "$env:TEMP\pf_totalram.txt" -Encoding ascii
) > "!PSANALYZE!"

powershell -ExecutionPolicy Bypass -File "!PSANALYZE!" 2>nul
del "!PSANALYZE!" 2>nul

:: Read recommended values
if exist "%TEMP%\pf_recmin.txt" (
    set "recMin="
    set /p recMin=<"%TEMP%\pf_recmin.txt"
    del "%TEMP%\pf_recmin.txt" 2>nul
)
if exist "%TEMP%\pf_recmax.txt" (
    set "recMax="
    set /p recMax=<"%TEMP%\pf_recmax.txt"
    del "%TEMP%\pf_recmax.txt" 2>nul
)
if exist "%TEMP%\pf_totalram.txt" (
    set "totalRAMint="
    set /p totalRAMint=<"%TEMP%\pf_totalram.txt"
    del "%TEMP%\pf_totalram.txt" 2>nul
)

echo/
pause
goto MainMenu

:: ============================================================================
:: Option 2: Apply Recommended
:: ============================================================================
:ApplyRecommended
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Apply Recommended Pagefile Settings%RESET%
echo %CYAN%============================================================================%RESET%
echo/

:: Calculate recommendation
set "PSREC=%TEMP%\pagefile_recommend.ps1"

(
echo $cs = Get-CimInstance Win32_ComputerSystem
echo # Same rounding as option [1], so both options recommend the same size
echo $totalRAM = [int][math]::Round^($cs.TotalPhysicalMemory / 1GB, 2^)
echo/
echo if ^($totalRAM -ge 64^) {
echo     $sizeMB = [math]::Max^(1024, [int]^($totalRAM * 1024 * 0.25^)^)
echo } elseif ^($totalRAM -ge 32^) {
echo     $sizeMB = [int]^($totalRAM * 1024 * 0.5^)
echo } elseif ^($totalRAM -ge 16^) {
echo     $sizeMB = [int]^($totalRAM * 1024 * 1.0^)
echo } else {
echo     $sizeMB = [int]^($totalRAM * 1024 * 1.5^)
echo }
echo/
echo Write-Host "Total RAM: $totalRAM GB"
echo Write-Host "Recommended pagefile: $([math]::Round($sizeMB / 1024, 1)) GB ($sizeMB MB)"
echo Write-Host ""
echo "$sizeMB" ^| Out-File -FilePath "$env:TEMP\pf_size.txt" -Encoding ascii
echo "$totalRAM" ^| Out-File -FilePath "$env:TEMP\pf_ram.txt" -Encoding ascii
) > "!PSREC!"

powershell -ExecutionPolicy Bypass -File "!PSREC!" 2>nul
del "!PSREC!" 2>nul

:: Default of 4096 MB is kept if PowerShell produced no (or an empty) result
set "recSizeMB=4096"
if exist "%TEMP%\pf_size.txt" (
    for /f "usebackq delims=" %%a in ("%TEMP%\pf_size.txt") do set "recSizeMB=%%a"
    del "%TEMP%\pf_size.txt" 2>nul
)
if exist "%TEMP%\pf_ram.txt" (
    del "%TEMP%\pf_ram.txt" 2>nul
)

:: Trim whitespace
for /f "tokens=*" %%a in ("!recSizeMB!") do set "recSizeMB=%%a"

echo This will set a fixed pagefile of !recSizeMB! MB on C:
echo (Fixed size = min and max are the same, prevents fragmentation)
echo/
echo %YELLOW%A reboot is required for pagefile changes to take effect.%RESET%
echo/

set "confirm="
set /p "confirm=Apply recommended settings? [Y/N]: "
if /i not "!confirm!"=="Y" goto MainMenu

echo/
echo Applying settings...

:: Disable automatic management, delete existing pagefiles on all drives,
:: then create the fixed pagefile on C:
call :SetPagefiles "C:\pagefile.sys" !recSizeMB! !recSizeMB!

if not errorlevel 1 (
    echo       %GREEN%- Disabled automatic pagefile management%RESET%
    echo       %GREEN%- Set C:\pagefile.sys to !recSizeMB! MB ^(fixed^)%RESET%
) else (
    echo       %YELLOW%- Applied via registry ^(CIM update failed^)%RESET%
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "C:\pagefile.sys !recSizeMB! !recSizeMB!" /f >nul 2>&1
)

echo/
echo %GREEN%[OK] Pagefile configured.%RESET%
echo %YELLOW%     Reboot required for changes to take effect.%RESET%
echo/

set "reboot="
set /p "reboot=Restart now? [Y/N]: "
if /i "!reboot!"=="Y" (
    shutdown /r /t 10 /c "Pagefile Tuner - Restart"
)

pause
goto MainMenu

:: ============================================================================
:: Option 3: Custom Size
:: ============================================================================
:CustomSize
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Set Custom Fixed Pagefile Size%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo Enter the desired pagefile size in MB.
echo (Set min and max to the same value to prevent fragmentation)
echo/
echo Common sizes:
echo   2048 MB  = 2 GB
echo   4096 MB  = 4 GB
echo   8192 MB  = 8 GB
echo   16384 MB = 16 GB
echo   32768 MB = 32 GB
echo/

set "customInit="
set /p "customInit=Initial (minimum) size in MB: "
set "customMax="
set /p "customMax=Maximum size in MB: "

if "!customInit!"=="" goto MainMenu
if "!customMax!"=="" set "customMax=!customInit!"

:: Sizes must be whole numbers: strip every digit and see if anything besides
:: the "x" sentinel is left (the sentinel keeps the variable defined)
set "sizeCheck=x!customInit!!customMax!"
for %%d in (0 1 2 3 4 5 6 7 8 9) do set "sizeCheck=!sizeCheck:%%d=!"
if not "!sizeCheck!"=="x" (
    echo %RED%[ERROR] Sizes must be whole numbers in MB. Nothing was changed.%RESET%
    pause
    goto MainMenu
)

echo/
echo Settings: C:\pagefile.sys
echo   Initial: !customInit! MB
echo   Maximum: !customMax! MB
echo/

set "confirm="
set /p "confirm=Apply? [Y/N]: "
if /i not "!confirm!"=="Y" goto MainMenu

call :SetPagefiles "C:\pagefile.sys" !customInit! !customMax!

if not errorlevel 1 (
    echo       %GREEN%[OK] Pagefile set to !customInit! / !customMax! MB%RESET%
) else (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "C:\pagefile.sys !customInit! !customMax!" /f >nul 2>&1
    echo       %GREEN%[OK] Applied via registry%RESET%
)

echo %YELLOW%     Reboot required.%RESET%
echo/

set "reboot="
set /p "reboot=Restart now? [Y/N]: "
if /i "!reboot!"=="Y" (
    shutdown /r /t 10 /c "Pagefile Tuner - Restart"
)

pause
goto MainMenu

:: ============================================================================
:: Option 4: Move to Different Drive
:: ============================================================================
:MoveDrive
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Move Pagefile to a Different Drive%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo %WHITE%Available drives:%RESET%
echo/

:: List available drives with type
set "PSDRIVES=%TEMP%\pagefile_drives.ps1"

(
echo $drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
echo foreach ^($d in $drives^) {
echo     $totalGB = [math]::Round^($d.Size / 1GB, 1^)
echo     $freeGB = [math]::Round^($d.FreeSpace / 1GB, 1^)
echo     $letter = $d.DeviceID
echo/
echo     $diskNum = ^(Get-Partition -DriveLetter $letter[0] -ErrorAction SilentlyContinue^).DiskNumber
echo     $mediaType = 'Unknown'
echo     if ^($diskNum -ne $null^) {
echo         $physDisk = Get-PhysicalDisk ^| Where-Object { $_.DeviceID -eq $diskNum }
echo         if ^($physDisk^) { $mediaType = if ^($physDisk.BusType -eq 'NVMe'^) { 'NVMe' } else { $physDisk.MediaType } }
echo     }
echo/
echo     Write-Host "  $letter  $totalGB GB total, $freeGB GB free [$mediaType]"
echo }
) > "!PSDRIVES!"

powershell -ExecutionPolicy Bypass -File "!PSDRIVES!" 2>nul
del "!PSDRIVES!" 2>nul

echo/
echo %YELLOW%Best practice: Place pagefile on your fastest drive (NVMe ^> SSD ^> HDD).%RESET%
echo %YELLOW%For crash dumps, a small pagefile must remain on C:.%RESET%
echo/

set "targetDrive="
set /p "targetDrive=Target drive letter (e.g., D): "
if "!targetDrive!"=="" goto MainMenu
set "targetDrive=!targetDrive:~0,1!"

if not exist "!targetDrive!:\" (
    echo %RED%[ERROR] Drive !targetDrive!: not found.%RESET%
    pause
    goto MainMenu
)

echo/
set "moveSizeMB="
set /p "moveSizeMB=Pagefile size in MB (e.g., 8192): "
if "!moveSizeMB!"=="" goto MainMenu

:: The size must be a whole number: strip every digit and see if anything besides
:: the "x" sentinel is left (the sentinel keeps the variable defined)
set "sizeCheck=x!moveSizeMB!"
for %%d in (0 1 2 3 4 5 6 7 8 9) do set "sizeCheck=!sizeCheck:%%d=!"
if not "!sizeCheck!"=="x" (
    echo %RED%[ERROR] The size must be a whole number in MB. Nothing was changed.%RESET%
    pause
    goto MainMenu
)

echo/
echo Will create:
echo   !targetDrive!:\pagefile.sys  (!moveSizeMB! MB fixed)
echo/

:: Only offer the extra small C: pagefile when the target is another drive. When the
:: target is C: itself, it would replace the size chosen above with 800 MB.
set "keepOnC=N"
if /i not "!targetDrive!"=="C" set /p "keepOnC=Also keep a small pagefile on C: for crash dumps? [Y/N]: "

set "confirm="
set /p "confirm=Apply? [Y/N]: "
if /i not "!confirm!"=="Y" goto MainMenu

echo/
:: Disable automatic management, delete existing pagefiles on all drives, then create
:: the pagefile on the target drive (plus a small one on C: if requested).
:: 800 MB on C: is enough for a minidump.
set "cPagefile="
set "pagingFilesValue=!targetDrive!:\pagefile.sys !moveSizeMB! !moveSizeMB!"
if /i "!keepOnC!"=="Y" (
    set "cPagefile=C:\pagefile.sys 800 800"
    set "pagingFilesValue=!pagingFilesValue!\0C:\pagefile.sys 800 800"
)
call :SetPagefiles "!targetDrive!:\pagefile.sys" !moveSizeMB! !moveSizeMB! !cPagefile!

if not errorlevel 1 (
    echo       %GREEN%- Created !targetDrive!:\pagefile.sys ^(!moveSizeMB! MB^)%RESET%
    if defined cPagefile echo       %GREEN%- Created C:\pagefile.sys ^(800 MB, crash dump support^)%RESET%
) else (
    REM reg.exe splits REG_MULTI_SZ data at \0, giving one line per pagefile
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "!pagingFilesValue!" /f >nul 2>&1
    echo       %YELLOW%- Applied via registry ^(CIM update failed^)%RESET%
)

echo/
echo %GREEN%[OK] Pagefile moved.%RESET%
echo %YELLOW%     Reboot required.%RESET%
echo/

set "reboot="
set /p "reboot=Restart now? [Y/N]: "
if /i "!reboot!"=="Y" (
    shutdown /r /t 10 /c "Pagefile Tuner - Restart"
)

pause
goto MainMenu

:: ============================================================================
:: Option 5: Disable Pagefile
:: ============================================================================
:DisablePagefile
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Disable Pagefile%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo %RED%WARNING: Disabling the pagefile is NOT recommended for most users^^!%RESET%
echo/
echo Consequences:
echo  - Programs may crash with out-of-memory errors
echo  - Windows cannot create crash dumps for debugging
echo  - Some programs require a pagefile to function
echo  - Memory-mapped files may fail
echo/
echo %YELLOW%Only disable if you have 64+ GB RAM and never exceed RAM capacity.%RESET%
echo/

set "confirm="
set /p "confirm=Are you sure you want to disable the pagefile? [Y/N]: "
if /i not "!confirm!"=="Y" goto MainMenu

:: Double confirm
set "confirm2="
set /p "confirm2=Type DISABLE to confirm: "
if not "!confirm2!"=="DISABLE" (
    echo Cancelled.
    pause
    goto MainMenu
)

echo/
:: Disable automatic management and delete all pagefile settings
call :SetPagefiles none

:: Set empty pagefile in registry (also covers the case where the CIM update failed)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "" /f >nul 2>&1

echo       %GREEN%[OK] Pagefile disabled.%RESET%
echo %YELLOW%     Reboot required. The pagefile.sys file will be deleted on reboot.%RESET%
echo/
echo %YELLOW%     To re-enable: run this script ^> option [6]%RESET%
echo/

set "reboot="
set /p "reboot=Restart now? [Y/N]: "
if /i "!reboot!"=="Y" (
    shutdown /r /t 10 /c "Pagefile Tuner - Restart"
)

pause
goto MainMenu

:: ============================================================================
:: Option 6: Restore Automatic
:: ============================================================================
:RestoreAutomatic
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Restore Windows Automatic Pagefile Management%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo This will let Windows manage the pagefile automatically.
echo (Windows default behavior)
echo/

set "confirm="
set /p "confirm=Restore automatic management? [Y/N]: "
if /i not "!confirm!"=="Y" goto MainMenu

:: Delete all custom pagefile settings and turn automatic management back on
call :SetPagefiles auto
if errorlevel 1 (
    REM "?:\pagefile.sys" is the PagingFiles value Windows uses for automatic management
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "PagingFiles" /t REG_MULTI_SZ /d "?:\pagefile.sys" /f >nul 2>&1
    echo       %YELLOW%- Applied via registry ^(CIM update failed^)%RESET%
)

echo/
echo       %GREEN%[OK] Automatic pagefile management restored.%RESET%
echo %YELLOW%     Reboot required.%RESET%
echo/

set "reboot="
set /p "reboot=Restart now? [Y/N]: "
if /i "!reboot!"=="Y" (
    shutdown /r /t 10 /c "Pagefile Tuner - Restart"
)

pause
goto MainMenu

:Exit
echo/
echo Goodbye.
exit /b 0

:: ============================================================================
:: Subroutine: SetPagefiles
:: ============================================================================
:SetPagefiles
REM Replaces the former "wmic computersystem set AutomaticManagedPagefile=..." and
REM "wmic pagefileset delete / create / set" calls, because WMIC is not available on
REM Windows 11 24H2 and later. Uses PowerShell CIM instead.
REM   call :SetPagefiles auto
REM       delete every pagefile setting and turn automatic management back on
REM   call :SetPagefiles none
REM       turn automatic management off and delete every pagefile setting
REM   call :SetPagefiles "X:\pagefile.sys" initialMB maxMB [Y:\pagefile.sys initialMB maxMB]
REM       turn automatic management off, delete every pagefile setting, then create
REM       the listed pagefile[s] with the given sizes
REM Sizes are converted before anything is changed, so a bad size changes nothing.
REM Returns errorlevel 0 on success, 1 if any step failed [callers fall back to the registry].
set "PF_MODE=%~1"
set "PF1_NAME=%~1"
set "PF1_INIT=%~2"
set "PF1_MAX=%~3"
set "PF2_NAME=%~4"
set "PF2_INIT=%~5"
set "PF2_MAX=%~6"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; try { $new = @(); if ($env:PF_MODE -ne 'auto' -and $env:PF_MODE -ne 'none') { $new += @{Name=$env:PF1_NAME; Init=[uint32]$env:PF1_INIT; Max=[uint32]$env:PF1_MAX}; if ($env:PF2_NAME) { $new += @{Name=$env:PF2_NAME; Init=[uint32]$env:PF2_INIT; Max=[uint32]$env:PF2_MAX} } }; $cs = Get-CimInstance Win32_ComputerSystem; if ($env:PF_MODE -eq 'auto') { Get-CimInstance Win32_PageFileSetting | Remove-CimInstance; Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$true} } else { Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$false}; Get-CimInstance Win32_PageFileSetting | Remove-CimInstance; foreach ($p in $new) { New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name=$p.Name} | Out-Null; $setting = @(Get-CimInstance Win32_PageFileSetting | Where-Object { $_.Name -eq $p.Name }); if ($setting.Count -eq 0) { throw 'Pagefile setting was not created' }; $setting | Set-CimInstance -Property @{InitialSize=$p.Init; MaximumSize=$p.Max} } }; exit 0 } catch { exit 1 }"
if %errorlevel% neq 0 exit /b 1
exit /b 0
