@echo off
setlocal enabledelayedexpansion
title Disk Health Check
color 0B
chcp 65001 >nul 2>nul

:: ============================================================================
:: Disk Health Check
:: ============================================================================
:: Reads S.M.A.R.T. data, drive temperatures, wear levels, and health
:: status for all connected drives. Flags drives approaching failure.
:: ============================================================================

:: Setup colors early for error messages
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "MAGENTA=%ESC%[95m"
set "WHITE=%ESC%[97m"
set "DIM=%ESC%[90m"
set "BOLD=%ESC%[1m"
set "RESET=%ESC%[0m"

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo/
    pause
    exit /b 1
)

:: Animated header
cls
echo/
echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Disk Health Check%RESET%                                                      %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%S.M.A.R.T. data, temperatures, wear levels, and health status%RESET%      %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
title [1/2] Disk Health Check - Scanning drives...

:: Output file. Use PowerShell for a locale-independent date (%DATE% slicing
:: assumes US format and yields a "/"-containing, invalid path elsewhere).
for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%D"
set "OUTFILE=%USERPROFILE%\Desktop\DiskHealth_%COMPUTERNAME%_%TODAY%.txt"

echo   Results will be saved to your Desktop.
echo/
<nul set /p "=  %CYAN%[%RESET%%WHITE%*%RESET%%CYAN%]%RESET% Analyzing drives"
for /l %%i in (1,1,3) do (
    <nul set /p "=."
    timeout /t 0 /nobreak >nul
)
echo/
echo/

:: Create PowerShell script for detailed analysis
set "PSSCRIPT=%TEMP%\disk_health_check.ps1"

(
echo # Disk Health Check
echo # Reads S.M.A.R.T. data, temperatures, wear levels
echo/
echo $ErrorActionPreference = 'SilentlyContinue'
echo/
echo $outFile = '%OUTFILE%'
echo $report = @^(^)
echo/
echo function Add-Line^($text^) {
echo     $script:report += $text
echo     Write-Host $text
echo }
echo/
echo function Add-ColorLine^($text, $color^) {
echo     $script:report += $text
echo     Write-Host $text -ForegroundColor $color
echo }
echo/
echo Add-Line "============================================================================"
echo Add-Line " Disk Health Report - $env:COMPUTERNAME"
echo Add-Line " Date: $^(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'^)"
echo Add-Line "============================================================================"
echo Add-Line ""
echo/
echo # Get physical disks
echo $disks = Get-PhysicalDisk
echo/
echo if ^(-not $disks^) {
echo     Add-ColorLine "[ERROR] Could not enumerate physical disks." "Red"
echo     $report ^| Out-File -FilePath $outFile -Encoding UTF8
echo     exit
echo }
echo/
echo $warningCount = 0
echo $criticalCount = 0
echo $diskIndex = 0
echo/
echo foreach ^($disk in $disks^) {
echo     $diskIndex++
echo     Add-Line "============================================================================"
echo     Add-ColorLine " DISK $diskIndex: $^($disk.FriendlyName^)" "Cyan"
echo     Add-Line "============================================================================"
echo     Add-Line ""
echo/
echo     # Basic info
echo     $sizeGB = [math]::Round^($disk.Size / 1GB, 1^)
echo     Add-Line "  Model:          $^($disk.FriendlyName^)"
echo     Add-Line "  Serial:         $^($disk.SerialNumber^)"
echo     Add-Line "  Media Type:     $^($disk.MediaType^)"
echo     Add-Line "  Bus Type:       $^($disk.BusType^)"
echo     Add-Line "  Size:           $sizeGB GB"
echo     Add-Line "  Firmware:       $^($disk.FirmwareVersion^)"
echo     Add-Line ""
echo/
echo     # Health Status
echo     $healthStatus = $disk.HealthStatus
echo     $opStatus = $disk.OperationalStatus
echo     switch ^($healthStatus^) {
echo         'Healthy' {
echo             Add-ColorLine "  Health Status:  [OK] Healthy" "Green"
echo         }
echo         'Warning' {
echo             Add-ColorLine "  Health Status:  [WARN] Warning - Monitor closely" "Yellow"
echo             $warningCount++
echo         }
echo         'Unhealthy' {
echo             Add-ColorLine "  Health Status:  [CRITICAL] Unhealthy - Backup immediately^^!" "Red"
echo             $criticalCount++
echo         }
echo         default {
echo             Add-ColorLine "  Health Status:  $healthStatus" "Yellow"
echo         }
echo     }
echo     Add-Line "  Op. Status:     $opStatus"
echo     Add-Line ""
echo/
echo     # Storage Reliability Counters ^(S.M.A.R.T. equivalent^)
echo     $reliability = Get-StorageReliabilityCounter -PhysicalDisk $disk
echo/
echo     if ^($reliability^) {
echo         Add-Line "  --- S.M.A.R.T. / Reliability Data ---"
echo         Add-Line ""
echo/
echo         # Temperature
echo         if ^($reliability.Temperature^) {
echo             $tempC = $reliability.Temperature
echo             $tempColor = "Green"
echo             $tempNote = ""
echo             if ^($tempC -ge 55^) { $tempColor = "Red"; $tempNote = " [HOT^^!]"; $warningCount++ }
echo             elseif ^($tempC -ge 45^) { $tempColor = "Yellow"; $tempNote = " [Warm]" }
echo             Add-ColorLine "  Temperature:    ${tempC}C${tempNote}" $tempColor
echo         }
echo/
echo         # Power-on hours
echo         if ^($reliability.PowerOnHours^) {
echo             $hours = $reliability.PowerOnHours
echo             $days = [math]::Round^($hours / 24, 0^)
echo             $years = [math]::Round^($hours / 8760, 1^)
echo             $hourNote = ""
echo             if ^($hours -ge 35040^) { $hourNote = " ^(${years} years - consider replacement planning^)" }
echo             elseif ^($hours -ge 17520^) { $hourNote = " ^(${years} years^)" }
echo             else { $hourNote = " ^($days days^)" }
echo             Add-Line "  Power-On Hours: $hours$hourNote"
echo         }
echo/
echo         # Wear level ^(SSD specific^)
echo         if ^($reliability.Wear -ne $null^) {
echo             $wear = $reliability.Wear
echo             $wearColor = "Green"
echo             $wearNote = ""
echo             if ^($wear -ge 90^) { $wearColor = "Red"; $wearNote = " [REPLACE SOON^^!]"; $criticalCount++ }
echo             elseif ^($wear -ge 70^) { $wearColor = "Yellow"; $wearNote = " [Monitor]"; $warningCount++ }
echo             elseif ^($wear -ge 50^) { $wearColor = "Yellow"; $wearNote = " [Moderate]" }
echo             Add-ColorLine "  Wear Level:     ${wear}%%${wearNote}" $wearColor
echo         }
echo/
echo         # Read/Write errors
echo         if ^($reliability.ReadErrorsTotal -ne $null^) {
echo             $readErrors = $reliability.ReadErrorsTotal
echo             if ^($readErrors -gt 0^) {
echo                 Add-ColorLine "  Read Errors:    $readErrors [Check drive^^!]" "Red"
echo                 $warningCount++
echo             } else {
echo                 Add-Line "  Read Errors:    0"
echo             }
echo         }
echo         if ^($reliability.WriteErrorsTotal -ne $null^) {
echo             $writeErrors = $reliability.WriteErrorsTotal
echo             if ^($writeErrors -gt 0^) {
echo                 Add-ColorLine "  Write Errors:   $writeErrors [Check drive^^!]" "Red"
echo                 $warningCount++
echo             } else {
echo                 Add-Line "  Write Errors:   0"
echo             }
echo         }
echo/
echo         # Power cycles
echo         if ^($reliability.StartStopCycleCount^) {
echo             Add-Line "  Power Cycles:   $^($reliability.StartStopCycleCount^)"
echo         }
echo/
echo         # Unexpected shutdowns
echo         if ^($reliability.UnrecoverableReadErrorsTotal -ne $null^) {
echo             $unrecoverable = $reliability.UnrecoverableReadErrorsTotal
echo             if ^($unrecoverable -gt 0^) {
echo                 Add-ColorLine "  Unrecoverable:  $unrecoverable read errors [DATA AT RISK]" "Red"
echo                 $criticalCount++
echo             }
echo         }
echo     } else {
echo         Add-Line "  --- S.M.A.R.T. data not available for this drive ---"
echo         Add-Line "  ^(Some USB drives and virtual disks don't report S.M.A.R.T.^)"
echo     }
echo/
echo     Add-Line ""
echo/
echo     # Partition info
echo     Add-Line "  --- Partitions ---"
echo     $partitions = Get-Partition -DiskNumber $disk.DeviceId 2^>$null
echo     if ^($partitions^) {
echo         foreach ^($part in $partitions^) {
echo             $vol = Get-Volume -Partition $part 2^>$null
echo             if ^($vol -and $vol.DriveLetter^) {
echo                 $totalGB = [math]::Round^($vol.Size / 1GB, 1^)
echo                 $freeGB = [math]::Round^($vol.SizeRemaining / 1GB, 1^)
echo                 $usedPct = if ^($vol.Size -gt 0^) { [math]::Round^(^($vol.Size - $vol.SizeRemaining^) / $vol.Size * 100, 0^) } else { 0 }
echo                 $spaceColor = "Green"
echo                 $spaceNote = ""
echo                 if ^($usedPct -ge 95^) { $spaceColor = "Red"; $spaceNote = " [CRITICAL - Nearly full^^!]"; $warningCount++ }
echo                 elseif ^($usedPct -ge 90^) { $spaceColor = "Yellow"; $spaceNote = " [Low space]" }
echo                 Add-ColorLine "  $^($vol.DriveLetter^): $^($vol.FileSystemLabel^) - ${freeGB}GB free / ${totalGB}GB ^(${usedPct}%% used^)${spaceNote}" $spaceColor
echo             }
echo         }
echo     }
echo     Add-Line ""
echo }
echo/
echo # WMIC fallback for additional info
echo Add-Line "============================================================================"
echo Add-Line " Additional Drive Information ^(WMI^)"
echo Add-Line "============================================================================"
echo Add-Line ""
echo/
echo $wmiDisks = Get-WmiObject -Class Win32_DiskDrive
echo foreach ^($d in $wmiDisks^) {
echo     $sizeGB = [math]::Round^($d.Size / 1GB, 1^)
echo     Add-Line "  $^($d.Model^)"
echo     Add-Line "    Interface: $^($d.InterfaceType^)  |  Status: $^($d.Status^)  |  Size: ${sizeGB}GB"
echo     if ^($d.Status -ne 'OK'^) {
echo         Add-ColorLine "    [WARNING] Drive status is '$^($d.Status^)' - not OK^^!" "Red"
echo         $warningCount++
echo     }
echo     Add-Line ""
echo }
echo/
echo # Summary
echo Add-Line "============================================================================"
echo Add-ColorLine " HEALTH SUMMARY" "Cyan"
echo Add-Line "============================================================================"
echo Add-Line ""
echo Add-Line "  Disks scanned:  $diskIndex"
echo/
echo if ^($criticalCount -gt 0^) {
echo     Add-ColorLine "  CRITICAL:       $criticalCount issues found - BACKUP NOW^^!" "Red"
echo     Add-Line ""
echo     Add-ColorLine "  RECOMMENDED ACTIONS:" "Red"
echo     Add-ColorLine "    1. Back up all important data immediately" "Red"
echo     Add-ColorLine "    2. Order a replacement drive" "Red"
echo     Add-ColorLine "    3. Do NOT rely on this drive for important data" "Red"
echo } elseif ^($warningCount -gt 0^) {
echo     Add-ColorLine "  WARNINGS:       $warningCount issues found - monitor closely" "Yellow"
echo     Add-Line ""
echo     Add-ColorLine "  RECOMMENDED ACTIONS:" "Yellow"
echo     Add-ColorLine "    1. Ensure backups are current" "Yellow"
echo     Add-ColorLine "    2. Re-run this check monthly" "Yellow"
echo     Add-ColorLine "    3. Check drive temperatures and ventilation" "Yellow"
echo } else {
echo     Add-ColorLine "  STATUS:         All drives healthy" "Green"
echo     Add-Line ""
echo     Add-Line "  Keep regular backups and re-check every few months."
echo }
echo/
echo Add-Line ""
echo/
echo # Save report
echo $report ^| Out-File -FilePath $outFile -Encoding UTF8
echo/
echo Write-Host ""
echo Write-Host "Report saved to: $outFile" -ForegroundColor Green
echo Write-Host ""
) > "%PSSCRIPT%"

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%"
title [2/2] Disk Health Check - Complete

:: Cleanup
del "%PSSCRIPT%" 2>nul

echo/
echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %GREEN%Disk Health Check Complete%RESET%                                               %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
pause
