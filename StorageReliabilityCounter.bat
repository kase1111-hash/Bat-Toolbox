@echo off
setlocal enabledelayedexpansion
title Storage Reliability Counter
color 0B

:: ============================================================================
:: Storage Reliability Counter
:: ============================================================================
:: Reports temperature, power-on hours, reallocated sectors, wear level,
:: and reliability counters for SSDs and HDDs. Flags drives approaching
:: failure. Basic info works without admin; full S.M.A.R.T. requires admin.
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
echo %CYAN% Storage Reliability Counter%RESET%
echo %CYAN%============================================================================%RESET%
echo.

:: Check admin status (non-fatal)
set "isAdmin=0"
net session >nul 2>&1
if %errorlevel% equ 0 (
    set "isAdmin=1"
    echo %GREEN%[INFO] Running as administrator — full S.M.A.R.T. data available%RESET%
) else (
    echo %YELLOW%[INFO] Running without admin — basic info only%RESET%
    echo %YELLOW%       Run as admin for temperature, S.M.A.R.T., and wear data%RESET%
)
echo.

:MainMenu
echo %CYAN%============================================================================%RESET%
echo %CYAN% Main Menu%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo   [1] Quick health overview (all drives)
echo   [2] Detailed reliability report
echo   [3] Export report to Desktop
echo   [0] Exit
echo.

set /p "choice=Select option: "

if "%choice%"=="1" goto QuickOverview
if "%choice%"=="2" goto DetailedReport
if "%choice%"=="3" goto ExportReport
if "%choice%"=="0" goto Exit

echo %RED%Invalid option.%RESET%
echo.
goto MainMenu

:: ============================================================================
:: Option 1: Quick Overview
:: ============================================================================
:QuickOverview
echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Quick Health Overview%RESET%
echo %CYAN%============================================================================%RESET%
echo.

set "PSQUICK=%TEMP%\storage_quick.ps1"

(
echo $ErrorActionPreference = 'SilentlyContinue'
echo.
echo # Get physical disks
echo $disks = Get-PhysicalDisk
echo if (-not $disks^) {
echo     Write-Host "[ERROR] Could not enumerate physical disks." -ForegroundColor Red
echo     exit 1
echo }
echo.
echo Write-Host ("{0,-8} {1,-25} {2,-10} {3,-12} {4,-15} {5}" -f "Disk", "Model", "Size", "Type", "Health", "Status"^) -ForegroundColor White
echo Write-Host ("{0,-8} {1,-25} {2,-10} {3,-12} {4,-15} {5}" -f ("-"*7^), ("-"*24^), ("-"*9^), ("-"*11^), ("-"*14^), ("-"*10^)^)
echo.
echo foreach ^($disk in $disks^) {
echo     $id = $disk.DeviceID
echo     $model = $disk.FriendlyName
echo     if ^($model.Length -gt 24^) { $model = $model.Substring^(0, 21^) + '...' }
echo     $sizeGB = [math]::Round^($disk.Size / 1GB, 0^)
echo     $size = "$sizeGB GB"
echo     $type = $disk.MediaType
echo     if ^(-not $type -or $type -eq 'Unspecified'^) { $type = 'Unknown' }
echo     $health = $disk.HealthStatus
echo     $status = $disk.OperationalStatus
echo.
echo     # Color code health
echo     $color = 'Green'
echo     if ^($health -ne 'Healthy'^) { $color = 'Red' }
echo     if ^($status -ne 'OK'^) { $color = 'Red' }
echo.
echo     $line = "{0,-8} {1,-25} {2,-10} {3,-12} {4,-15} {5}" -f "Disk $id", $model, $size, $type, $health, $status
echo     Write-Host $line -ForegroundColor $color
echo }
echo.
echo Write-Host ""
echo.
echo # Reliability counters from StorageReliabilityCounter
echo $isAdmin = ^([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent^(^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)
echo.
echo if ^($isAdmin^) {
echo     Write-Host "RELIABILITY COUNTERS" -ForegroundColor White
echo     Write-Host "====================" -ForegroundColor White
echo     Write-Host ""
echo.
echo     foreach ^($disk in $disks^) {
echo         $id = $disk.DeviceID
echo         $model = $disk.FriendlyName
echo         Write-Host "Disk $id - $model" -ForegroundColor Cyan
echo         Write-Host ("-" * 60^)
echo.
echo         # Get reliability counters
echo         $rel = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
echo.
echo         if ^($rel^) {
echo             # Temperature
echo             $temp = $rel.Temperature
echo             if ^($temp -and $temp -gt 0^) {
echo                 $tempColor = 'Green'
echo                 $tempStatus = 'OK'
echo                 if ^($temp -ge 50^) { $tempColor = 'Yellow'; $tempStatus = 'WARM' }
echo                 if ^($temp -ge 60^) { $tempColor = 'Red'; $tempStatus = 'HOT' }
echo                 if ^($temp -ge 70^) { $tempColor = 'Red'; $tempStatus = 'CRITICAL' }
echo                 Write-Host ("  Temperature:          {0}C [{1}]" -f $temp, $tempStatus^) -ForegroundColor $tempColor
echo             } else {
echo                 Write-Host "  Temperature:          N/A"
echo             }
echo.
echo             # Power-on hours
echo             $poh = $rel.PowerOnHours
echo             if ^($poh -and $poh -gt 0^) {
echo                 $days = [math]::Round^($poh / 24, 0^)
echo                 $years = [math]::Round^($poh / 8760, 1^)
echo                 $pohColor = 'Green'
echo                 $pohStatus = 'OK'
echo                 if ^($poh -ge 35000^) { $pohColor = 'Yellow'; $pohStatus = 'HIGH' }
echo                 if ^($poh -ge 50000^) { $pohColor = 'Red'; $pohStatus = 'VERY HIGH' }
echo                 Write-Host ("  Power-On Hours:       {0} hrs ({1} days / {2} years) [{3}]" -f $poh, $days, $years, $pohStatus^) -ForegroundColor $pohColor
echo             } else {
echo                 Write-Host "  Power-On Hours:       N/A"
echo             }
echo.
echo             # Wear level (SSD specific)
echo             $wear = $rel.Wear
echo             if ^($wear -ne $null -and $wear -ge 0^) {
echo                 $remainPct = 100 - $wear
echo                 $wearColor = 'Green'
echo                 $wearStatus = 'OK'
echo                 if ^($remainPct -le 30^) { $wearColor = 'Yellow'; $wearStatus = 'WORN' }
echo                 if ^($remainPct -le 10^) { $wearColor = 'Red'; $wearStatus = 'REPLACE SOON' }
echo                 Write-Host ("  Wear Level:           {0}%% used, {1}%% remaining [{2}]" -f $wear, $remainPct, $wearStatus^) -ForegroundColor $wearColor
echo             }
echo.
echo             # Read/Write errors
echo             $readErr = $rel.ReadErrorsTotal
echo             $writeErr = $rel.WriteErrorsTotal
echo             if ^($readErr -ne $null^) {
echo                 $errColor = if ^($readErr -gt 0^) { 'Yellow' } else { 'Green' }
echo                 Write-Host ("  Read Errors Total:    {0}" -f $readErr^) -ForegroundColor $errColor
echo             }
echo             if ^($writeErr -ne $null^) {
echo                 $errColor = if ^($writeErr -gt 0^) { 'Yellow' } else { 'Green' }
echo                 Write-Host ("  Write Errors Total:   {0}" -f $writeErr^) -ForegroundColor $errColor
echo             }
echo.
echo             # Reallocated sectors (bad sectors remapped)
echo             $readErrCorr = $rel.ReadErrorsCorrected
echo             $readErrUncorr = $rel.ReadErrorsUncorrected
echo             $writeErrCorr = $rel.WriteErrorsCorrected
echo             $writeErrUncorr = $rel.WriteErrorsUncorrected
echo.
echo             if ^($readErrUncorr -ne $null -and $readErrUncorr -gt 0^) {
echo                 Write-Host ("  Read Errors Uncorrected:  {0}" -f $readErrUncorr^) -ForegroundColor Red
echo             }
echo             if ^($writeErrUncorr -ne $null -and $writeErrUncorr -gt 0^) {
echo                 Write-Host ("  Write Errors Uncorrected: {0}" -f $writeErrUncorr^) -ForegroundColor Red
echo             }
echo.
echo             # Start/stop count
echo             $startStop = $rel.StartStopCycleCount
echo             if ^($startStop -and $startStop -gt 0^) {
echo                 Write-Host ("  Start/Stop Cycles:    {0}" -f $startStop^)
echo             }
echo.
echo             # Flash writes (SSD)
echo             $flashWrites = $rel.FlashWrites
echo             if ^($flashWrites -ne $null -and $flashWrites -gt 0^) {
echo                 Write-Host ("  Flash Writes:         {0}" -f $flashWrites^)
echo             }
echo         } else {
echo             Write-Host "  Reliability data not available for this drive."
echo             Write-Host "  (Drive may not support StorageReliabilityCounter)"
echo         }
echo.
echo         Write-Host ""
echo     }
echo } else {
echo     Write-Host "Run as administrator for reliability counters (temperature, wear, errors)." -ForegroundColor Yellow
echo     Write-Host ""
echo }
echo.
echo # Volume info (works without admin)
echo Write-Host "VOLUME INFORMATION" -ForegroundColor White
echo Write-Host "==================" -ForegroundColor White
echo Write-Host ""
echo Write-Host ("{0,-6} {1,-12} {2,-12} {3,-10} {4,-10} {5}" -f "Drive", "Total", "Free", "Free %%", "Format", "Label"^) -ForegroundColor White
echo Write-Host ("{0,-6} {1,-12} {2,-12} {3,-10} {4,-10} {5}" -f ("-"*5^), ("-"*11^), ("-"*11^), ("-"*9^), ("-"*9^), ("-"*15^)^)
echo.
echo $vols = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
echo foreach ^($v in $vols^) {
echo     $totalGB = [math]::Round^($v.Size / 1GB, 1^)
echo     $freeGB = [math]::Round^($v.FreeSpace / 1GB, 1^)
echo     $freePct = if ^($v.Size -gt 0^) { [math]::Round^(^($v.FreeSpace / $v.Size^) * 100, 1^) } else { 0 }
echo     $freeColor = 'Green'
echo     if ^($freePct -lt 15^) { $freeColor = 'Yellow' }
echo     if ^($freePct -lt 5^) { $freeColor = 'Red' }
echo     $line = "{0,-6} {1,-12} {2,-12} {3,-10} {4,-10} {5}" -f $v.DeviceID, "$totalGB GB", "$freeGB GB", "$freePct%%", $v.FileSystem, $v.VolumeName
echo     Write-Host $line -ForegroundColor $freeColor
echo }
echo Write-Host ""
) > "!PSQUICK!"

powershell -ExecutionPolicy Bypass -File "!PSQUICK!" 2>nul
del "!PSQUICK!" 2>nul

echo.
pause
goto MainMenu

:: ============================================================================
:: Option 2: Detailed Report
:: ============================================================================
:DetailedReport
echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Detailed Reliability Report%RESET%
echo %CYAN%============================================================================%RESET%
echo.

set "PSDETAIL=%TEMP%\storage_detail.ps1"

(
echo $ErrorActionPreference = 'SilentlyContinue'
echo $isAdmin = ^([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent^(^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)
echo.
echo $disks = Get-PhysicalDisk
echo if (-not $disks^) {
echo     Write-Host "[ERROR] Could not enumerate physical disks." -ForegroundColor Red
echo     exit 1
echo }
echo.
echo foreach ^($disk in $disks^) {
echo     $id = $disk.DeviceID
echo     $model = $disk.FriendlyName
echo     $serial = $disk.SerialNumber
echo     $fw = $disk.FirmwareVersion
echo     $sizeGB = [math]::Round^($disk.Size / 1GB, 1^)
echo     $type = $disk.MediaType
echo     $bus = $disk.BusType
echo     $health = $disk.HealthStatus
echo     $status = $disk.OperationalStatus
echo.
echo     Write-Host "============================================================================" -ForegroundColor Cyan
echo     Write-Host " Disk $id - $model" -ForegroundColor White
echo     Write-Host "============================================================================" -ForegroundColor Cyan
echo     Write-Host ""
echo.
echo     Write-Host "  IDENTIFICATION" -ForegroundColor White
echo     Write-Host "  Model:                $model"
echo     if ^($serial^) { Write-Host "  Serial Number:        $($serial.Trim())" }
echo     if ^($fw^) { Write-Host "  Firmware Version:     $fw" }
echo     Write-Host "  Capacity:             $sizeGB GB"
echo     Write-Host "  Media Type:           $type"
echo     Write-Host "  Bus Type:             $bus"
echo     Write-Host ""
echo.
echo     # Health assessment
echo     Write-Host "  HEALTH STATUS" -ForegroundColor White
echo     $hColor = if ^($health -eq 'Healthy'^) { 'Green' } else { 'Red' }
echo     Write-Host "  Health:               $health" -ForegroundColor $hColor
echo     $sColor = if ^($status -eq 'OK'^) { 'Green' } else { 'Red' }
echo     Write-Host "  Operational Status:   $status" -ForegroundColor $sColor
echo     Write-Host ""
echo.
echo     if ^($isAdmin^) {
echo         # Reliability counters
echo         $rel = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
echo.
echo         if ^($rel^) {
echo             Write-Host "  RELIABILITY COUNTERS" -ForegroundColor White
echo.
echo             # Temperature
echo             $temp = $rel.Temperature
echo             if ^($temp -and $temp -gt 0^) {
echo                 $tempC = $temp
echo                 $tempF = [math]::Round^($temp * 9/5 + 32, 0^)
echo                 $tempColor = 'Green'
echo                 $tempNote = 'Normal'
echo                 if ^($temp -ge 45^) { $tempColor = 'Green'; $tempNote = 'Normal (warm)' }
echo                 if ^($temp -ge 50^) { $tempColor = 'Yellow'; $tempNote = 'Warm - check airflow' }
echo                 if ^($temp -ge 60^) { $tempColor = 'Red'; $tempNote = 'Hot - improve cooling' }
echo                 if ^($temp -ge 70^) { $tempColor = 'Red'; $tempNote = 'CRITICAL - drive may throttle or fail' }
echo                 Write-Host ("  Temperature:          {0}C / {1}F  [{2}]" -f $tempC, $tempF, $tempNote^) -ForegroundColor $tempColor
echo             }
echo.
echo             # Power-on hours
echo             $poh = $rel.PowerOnHours
echo             if ^($poh -and $poh -gt 0^) {
echo                 $days = [math]::Round^($poh / 24, 0^)
echo                 $years = [math]::Round^($poh / 8760, 1^)
echo                 $pohColor = 'Green'
echo                 $pohNote = 'Low usage'
echo                 if ^($poh -ge 10000^) { $pohNote = 'Moderate usage' }
echo                 if ^($poh -ge 25000^) { $pohNote = 'Well used'; $pohColor = 'Green' }
echo                 if ^($poh -ge 35000^) { $pohNote = 'High usage - monitor closely'; $pohColor = 'Yellow' }
echo                 if ^($poh -ge 50000^) { $pohNote = 'Very high - consider replacement'; $pohColor = 'Red' }
echo                 Write-Host ("  Power-On Hours:       {0:N0} hrs ({1} days / {2} years)  [{3}]" -f $poh, $days, $years, $pohNote^) -ForegroundColor $pohColor
echo.
echo                 # Estimate daily usage
echo                 if ^($poh -gt 168^) {
echo                     # Only show if at least 1 week of data
echo                     $daysOwned = $poh / 24
echo                     $dailyHours = 24  # assume always on if poh tracks real time
echo                     Write-Host ("  Average Daily Use:    ~{0:N0} hrs/day (estimated)" -f [math]::Min^(24, [math]::Round^(24 * ($poh / [math]::Max^(1, $days * 24^)^), 1^)^)^)
echo                 }
echo             }
echo.
echo             # Wear level
echo             $wear = $rel.Wear
echo             if ^($wear -ne $null -and $wear -ge 0^) {
echo                 $remain = 100 - $wear
echo                 $wearColor = 'Green'
echo                 $wearNote = 'Excellent'
echo                 if ^($remain -le 80^) { $wearNote = 'Good' }
echo                 if ^($remain -le 50^) { $wearNote = 'Fair'; $wearColor = 'Yellow' }
echo                 if ^($remain -le 30^) { $wearNote = 'Worn - plan replacement'; $wearColor = 'Yellow' }
echo                 if ^($remain -le 10^) { $wearNote = 'CRITICAL - replace immediately'; $wearColor = 'Red' }
echo                 Write-Host ("  Wear Level:           {0}%% used / {1}%% remaining  [{2}]" -f $wear, $remain, $wearNote^) -ForegroundColor $wearColor
echo.
echo                 # Estimate remaining life based on wear and POH
echo                 if ^($poh -gt 0 -and $wear -gt 0^) {
echo                     $remainHours = [math]::Round^(^($poh / $wear^) * $remain^)
echo                     $remainYears = [math]::Round^($remainHours / 8760, 1^)
echo                     if ^($remainYears -gt 0 -and $remainYears -lt 50^) {
echo                         Write-Host ("  Est. Remaining Life:  ~{0:N0} hours ({1} years at current rate)" -f $remainHours, $remainYears^)
echo                     }
echo                 }
echo             }
echo.
echo             # Error counters
echo             Write-Host ""
echo             Write-Host "  ERROR COUNTERS" -ForegroundColor White
echo.
echo             $readErr = $rel.ReadErrorsTotal
echo             $writeErr = $rel.WriteErrorsTotal
echo             $readCorr = $rel.ReadErrorsCorrected
echo             $readUncorr = $rel.ReadErrorsUncorrected
echo             $writeCorr = $rel.WriteErrorsCorrected
echo             $writeUncorr = $rel.WriteErrorsUncorrected
echo.
echo             if ^($readErr -ne $null^) {
echo                 $c = if ^($readErr -gt 0^) { 'Yellow' } else { 'Green' }
echo                 Write-Host ("  Read Errors Total:        {0}" -f $readErr^) -ForegroundColor $c
echo             }
echo             if ^($readCorr -ne $null -and $readCorr -gt 0^) {
echo                 Write-Host ("  Read Errors Corrected:    {0}" -f $readCorr^) -ForegroundColor Yellow
echo             }
echo             if ^($readUncorr -ne $null -and $readUncorr -gt 0^) {
echo                 Write-Host ("  Read Errors UNCORRECTED:  {0}" -f $readUncorr^) -ForegroundColor Red
echo             }
echo             if ^($writeErr -ne $null^) {
echo                 $c = if ^($writeErr -gt 0^) { 'Yellow' } else { 'Green' }
echo                 Write-Host ("  Write Errors Total:       {0}" -f $writeErr^) -ForegroundColor $c
echo             }
echo             if ^($writeCorr -ne $null -and $writeCorr -gt 0^) {
echo                 Write-Host ("  Write Errors Corrected:   {0}" -f $writeCorr^) -ForegroundColor Yellow
echo             }
echo             if ^($writeUncorr -ne $null -and $writeUncorr -gt 0^) {
echo                 Write-Host ("  Write Errors UNCORRECTED: {0}" -f $writeUncorr^) -ForegroundColor Red
echo             }
echo.
echo             if ^(^($readErr -eq $null -or $readErr -eq 0^) -and ^($writeErr -eq $null -or $writeErr -eq 0^)^) {
echo                 Write-Host "  No errors detected." -ForegroundColor Green
echo             }
echo.
echo             # Additional counters
echo             $startStop = $rel.StartStopCycleCount
echo             $loadUnload = $rel.LoadUnloadCycleCount
echo             $flashWrites = $rel.FlashWrites
echo.
echo             if ^($startStop -or $loadUnload -or $flashWrites^) {
echo                 Write-Host ""
echo                 Write-Host "  USAGE COUNTERS" -ForegroundColor White
echo                 if ^($startStop -and $startStop -gt 0^) {
echo                     Write-Host ("  Start/Stop Cycles:    {0:N0}" -f $startStop^)
echo                 }
echo                 if ^($loadUnload -and $loadUnload -gt 0^) {
echo                     Write-Host ("  Load/Unload Cycles:   {0:N0}" -f $loadUnload^)
echo                 }
echo                 if ^($flashWrites -and $flashWrites -gt 0^) {
echo                     Write-Host ("  Flash Writes:         {0:N0}" -f $flashWrites^)
echo                 }
echo             }
echo         } else {
echo             Write-Host "  Reliability counters not available for this drive." -ForegroundColor Yellow
echo             Write-Host "  (Drive may not expose StorageReliabilityCounter data)"
echo         }
echo.
echo         # Get partition info
echo         Write-Host ""
echo         Write-Host "  PARTITIONS" -ForegroundColor White
echo         $parts = Get-Partition -DiskNumber $id -ErrorAction SilentlyContinue
echo         if ^($parts^) {
echo             foreach ^($p in $parts^) {
echo                 $pSizeGB = [math]::Round^($p.Size / 1GB, 1^)
echo                 $letter = if ^($p.DriveLetter^) { "$($p.DriveLetter):" } else { "(no letter)" }
echo                 $pType = $p.Type
echo                 if ^(-not $pType^) { $pType = $p.GptType }
echo                 Write-Host ("    {0,-10} {1,-10} {2}" -f $letter, "$pSizeGB GB", $pType^)
echo             }
echo         }
echo     } else {
echo         Write-Host "  (Run as administrator for reliability counters)" -ForegroundColor Yellow
echo     }
echo.
echo     # Overall assessment
echo     Write-Host ""
echo     Write-Host "  ASSESSMENT" -ForegroundColor White
echo     $issues = @^(^)
echo.
echo     if ^($health -ne 'Healthy'^) { $issues += "Health status is $health" }
echo     if ^($status -ne 'OK'^) { $issues += "Operational status is $status" }
echo.
echo     if ^($isAdmin -and $rel^) {
echo         if ^($rel.Temperature -ge 60^) { $issues += "Temperature is too high ($($rel.Temperature)C)" }
echo         if ^($rel.Wear -ne $null -and ^(100 - $rel.Wear^) -le 10^) { $issues += "SSD wear level critical ($($rel.Wear)%% used)" }
echo         if ^($rel.ReadErrorsUncorrected -and $rel.ReadErrorsUncorrected -gt 0^) { $issues += "Uncorrected read errors detected" }
echo         if ^($rel.WriteErrorsUncorrected -and $rel.WriteErrorsUncorrected -gt 0^) { $issues += "Uncorrected write errors detected" }
echo         if ^($rel.PowerOnHours -ge 50000^) { $issues += "Very high power-on hours ($($rel.PowerOnHours))" }
echo     }
echo.
echo     if ^($issues.Count -eq 0^) {
echo         Write-Host "  PASS - No issues detected" -ForegroundColor Green
echo     } else {
echo         foreach ^($issue in $issues^) {
echo             Write-Host "  WARNING: $issue" -ForegroundColor Red
echo         }
echo     }
echo.
echo     Write-Host ""
echo }
echo.
echo # WMI disk status fallback for additional info
echo Write-Host "============================================================================" -ForegroundColor Cyan
echo Write-Host " WMI Disk Status (additional data)" -ForegroundColor White
echo Write-Host "============================================================================" -ForegroundColor Cyan
echo Write-Host ""
echo.
echo $wmiDisks = Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue
echo foreach ^($wd in $wmiDisks^) {
echo     $wmiStatus = $wd.Status
echo     $sColor = if ^($wmiStatus -eq 'OK'^) { 'Green' } else { 'Red' }
echo     Write-Host ("  {0,-35} Status: {1}  Interface: {2}" -f $wd.Model, $wmiStatus, $wd.InterfaceType^) -ForegroundColor $sColor
echo }
echo Write-Host ""
echo.
echo # SMART status via WMI (requires admin)
echo if ^($isAdmin^) {
echo     $smartData = Get-CimInstance -Namespace 'root\WMI' -ClassName 'MSStorageDriver_FailurePredictStatus' -ErrorAction SilentlyContinue
echo     if ^($smartData^) {
echo         Write-Host "S.M.A.R.T. FAILURE PREDICTION" -ForegroundColor White
echo         Write-Host "=============================" -ForegroundColor White
echo         Write-Host ""
echo         foreach ^($s in $smartData^) {
echo             $instanceName = $s.InstanceName
echo             $predicted = $s.PredictFailure
echo             $reason = $s.Reason
echo             $pColor = if ^($predicted^) { 'Red' } else { 'Green' }
echo             $pText = if ^($predicted^) { 'YES - FAILURE PREDICTED' } else { 'No - OK' }
echo             Write-Host "  Predict Failure: $pText" -ForegroundColor $pColor
echo             if ^($predicted -and $reason^) {
echo                 Write-Host "  Reason Code:     $reason" -ForegroundColor Red
echo             }
echo         }
echo         Write-Host ""
echo     }
echo }
) > "!PSDETAIL!"

powershell -ExecutionPolicy Bypass -File "!PSDETAIL!" 2>nul
del "!PSDETAIL!" 2>nul

echo.
pause
goto MainMenu

:: ============================================================================
:: Option 3: Export Report
:: ============================================================================
:ExportReport
echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Export Report to Desktop%RESET%
echo %CYAN%============================================================================%RESET%
echo.

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value ^| find "="') do set "dt=%%I"
set "REPORT=%USERPROFILE%\Desktop\StorageReliability_%COMPUTERNAME%_%dt:~0,8%.txt"

set "PSEXPORT=%TEMP%\storage_export.ps1"

(
echo $ErrorActionPreference = 'SilentlyContinue'
echo $isAdmin = ^([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent^(^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]::Administrator^)
echo $report = @^(^)
echo.
echo function Add-Line^($text^) { $script:report += $text; Write-Host $text }
echo.
echo Add-Line "============================================================================"
echo Add-Line " Storage Reliability Report"
echo Add-Line " Computer: $env:COMPUTERNAME"
echo Add-Line " Date:     $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
echo Add-Line " Admin:    $isAdmin"
echo Add-Line "============================================================================"
echo Add-Line ""
echo.
echo $disks = Get-PhysicalDisk
echo foreach ^($disk in $disks^) {
echo     $id = $disk.DeviceID
echo     Add-Line "--- Disk $id - $($disk.FriendlyName) ---"
echo     Add-Line "  Size:       $([math]::Round($disk.Size / 1GB, 1)) GB"
echo     Add-Line "  Type:       $($disk.MediaType)"
echo     Add-Line "  Bus:        $($disk.BusType)"
echo     Add-Line "  Health:     $($disk.HealthStatus)"
echo     Add-Line "  Status:     $($disk.OperationalStatus)"
echo     if ^($disk.SerialNumber^) { Add-Line "  Serial:     $($disk.SerialNumber.Trim())" }
echo     if ^($disk.FirmwareVersion^) { Add-Line "  Firmware:   $($disk.FirmwareVersion)" }
echo.
echo     if ^($isAdmin^) {
echo         $rel = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
echo         if ^($rel^) {
echo             if ^($rel.Temperature -and $rel.Temperature -gt 0^) { Add-Line "  Temperature:    $($rel.Temperature)C" }
echo             if ^($rel.PowerOnHours -and $rel.PowerOnHours -gt 0^) {
echo                 $years = [math]::Round^($rel.PowerOnHours / 8760, 1^)
echo                 Add-Line "  Power-On Hours: $($rel.PowerOnHours) ($years years)"
echo             }
echo             if ^($rel.Wear -ne $null -and $rel.Wear -ge 0^) { Add-Line "  Wear:           $($rel.Wear)%% used, $(100 - $rel.Wear)%% remaining" }
echo             if ^($rel.ReadErrorsTotal -ne $null^) { Add-Line "  Read Errors:    $($rel.ReadErrorsTotal)" }
echo             if ^($rel.WriteErrorsTotal -ne $null^) { Add-Line "  Write Errors:   $($rel.WriteErrorsTotal)" }
echo             if ^($rel.StartStopCycleCount -and $rel.StartStopCycleCount -gt 0^) { Add-Line "  Start/Stop:     $($rel.StartStopCycleCount)" }
echo         }
echo     }
echo     Add-Line ""
echo }
echo.
echo # Volume info
echo Add-Line "--- Volume Information ---"
echo $vols = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
echo foreach ^($v in $vols^) {
echo     $totalGB = [math]::Round^($v.Size / 1GB, 1^)
echo     $freeGB = [math]::Round^($v.FreeSpace / 1GB, 1^)
echo     $freePct = if ^($v.Size -gt 0^) { [math]::Round^(^($v.FreeSpace / $v.Size^) * 100, 1^) } else { 0 }
echo     Add-Line ("  {0}  {1} GB total, {2} GB free ({3}%%)" -f $v.DeviceID, $totalGB, $freeGB, $freePct^)
echo }
echo Add-Line ""
echo.
echo $report ^| Out-File -FilePath '%REPORT%' -Encoding UTF8
echo Write-Host ""
echo Write-Host "Report saved to: %REPORT%" -ForegroundColor Green
) > "!PSEXPORT!"

powershell -ExecutionPolicy Bypass -File "!PSEXPORT!" 2>nul
del "!PSEXPORT!" 2>nul

echo.
echo %GREEN%Report saved to:%RESET%
echo   %REPORT%
echo.

pause
goto MainMenu

:Exit
echo.
echo Goodbye.
exit /b 0
