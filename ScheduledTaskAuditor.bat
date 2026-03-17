@echo off
setlocal enabledelayedexpansion
title Scheduled Task Auditor
color 0B

:: ============================================================================
:: Scheduled Task Auditor
:: ============================================================================
:: Scans Windows scheduled tasks, categorizes them as essential, bloatware,
:: telemetry, or unknown, and lets you disable unwanted ones.
:: ============================================================================

echo ============================================================================
echo  Scheduled Task Auditor
echo ============================================================================
echo/

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

:: Setup colors
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "MAGENTA=%ESC%[95m"
set "RESET=%ESC%[0m"

:: Output file
set "OUTFILE=%USERPROFILE%\Desktop\TaskAudit_%COMPUTERNAME%_%DATE:~-4%-%DATE:~4,2%-%DATE:~7,2%.txt"

echo Scanning scheduled tasks and categorizing them...
echo Results will be saved to your Desktop.
echo/

:: Create PowerShell script for task analysis
set "PSSCRIPT=%TEMP%\task_auditor.ps1"

(
echo # Scheduled Task Auditor
echo # Scans and categorizes all scheduled tasks
echo/
echo $ErrorActionPreference = 'SilentlyContinue'
echo/
echo # Known task categories
echo $telemetryTasks = @(
echo     '*Consolidator*', '*UsbCeip*', '*DmClient*', '*DmClientOnScenario*',
echo     '*FamilySafetyMonitor*', '*FamilySafetyRefresh*', '*KernelCeipTask*',
echo     '*Microsoft Compatibility Appraiser*', '*ProgramDataUpdater*',
echo     '*Proxy*', '*QueueReporting*', '*SmartScreenSpecific*',
echo     '*WinSAT*', '*MapsToastTask*', '*MapsUpdateTask*',
echo     '*Sqm-Tasks*', '*DiagTrack*', '*dmwappushservice*',
echo     '*AitAgent*', '*CEIP*', '*Customer Experience*',
echo     '*OfficeTelemetry*', '*Telemetry*'
echo ^)
echo/
echo $bloatwareTasks = @(
echo     '*Adobe*Update*', '*Adobe*ARM*', '*AdobeGC*',
echo     '*GoogleUpdate*', '*Google*Reporting*', '*Google*Crash*',
echo     '*CCleaner*', '*IObit*', '*Driver Booster*', '*Auslogics*',
echo     '*Avast*', '*AVG*', '*Norton*', '*McAfee*', '*Kaspersky*',
echo     '*Bitdefender*', '*Webroot*',
echo     '*RealPlayer*', '*CyberLink*', '*WildTangent*',
echo     '*Overwolf*', '*Razer*Synapse*Telemetry*',
echo     '*Opera*', '*Brave*Update*', '*Vivaldi*Update*',
echo     '*Java*Update*', '*Apple*Update*', '*iTunes*',
echo     '*DropboxUpdate*', '*OneDrive*Standalone*',
echo     '*Samsung*Magician*Update*', '*Corsair*Update*',
echo     '*HP*Telemetry*', '*Dell*SupportAssist*Telemetry*',
echo     '*LenovoVantage*Telemetry*', '*ASUS*Update*'
echo ^)
echo/
echo $essentialTasks = @(
echo     '*Windows Defender*', '*MpIdleTask*', '*ExploitGuard*',
echo     '*ScanForUpdates*', '*Schedule Scan*',
echo     '*Defrag*', '*SilentCleanup*', '*Sysprep*',
echo     '*ServerManager*', '*Maintenance*',
echo     '*Plug and Play*', '*SystemSoundsService*',
echo     '*Time Synchronization*', '*TimeZone*',
echo     '*CacheTask*', '*StartupAppTask*',
echo     '*CreateObjectTask*', '*BthSQM*',
echo     '*AnalyzeSystem*', '*WdiServiceHost*'
echo ^)
echo/
echo $optionalTasks = @(
echo     '*XblGameSave*', '*Xbox*', '*Xbl*',
echo     '*OneDrive*', '*Edge*Update*', '*MicrosoftEdge*',
echo     '*Office*Background*', '*Office*ClickToRun*',
echo     '*Cortana*', '*CloudExperienceHost*',
echo     '*BackgroundDownload*', '*InstallService*',
echo     '*WindowsUpdate*', '*UpdateOrchestrator*', '*USO_*',
echo     '*Rempl*', '*MozillaMaintenance*',
echo     '*Speech*', '*Clip*', '*NahimicSvc*',
echo     '*SpeechModelDownload*', '*ReconcileFeatures*'
echo ^)
echo/
echo Write-Host ""
echo Write-Host "Scanning scheduled tasks..." -ForegroundColor Cyan
echo Write-Host ""
echo/
echo # Get all scheduled tasks
echo $allTasks = Get-ScheduledTask 2^>$null
echo/
echo if ^(-not $allTasks^) {
echo     Write-Host "[ERROR] Could not retrieve scheduled tasks." -ForegroundColor Red
echo     exit
echo }
echo/
echo $report = @^(^)
echo $telemetryList = @^(^)
echo $bloatwareList = @^(^)
echo $essentialList = @^(^)
echo $optionalList = @^(^)
echo $unknownList = @^(^)
echo/
echo foreach ^($task in $allTasks^) {
echo     $fullName = "$^($task.TaskPath^)$^($task.TaskName^)"
echo     $state = $task.State.ToString^(^)
echo     $category = 'UNKNOWN'
echo/
echo     # Categorize
echo     foreach ^($pattern in $essentialTasks^) {
echo         if ^($fullName -like $pattern -or $task.TaskName -like $pattern^) {
echo             $category = 'ESSENTIAL'
echo             break
echo         }
echo     }
echo/
echo     if ^($category -eq 'UNKNOWN'^) {
echo         foreach ^($pattern in $telemetryTasks^) {
echo             if ^($fullName -like $pattern -or $task.TaskName -like $pattern^) {
echo                 $category = 'TELEMETRY'
echo                 break
echo             }
echo         }
echo     }
echo/
echo     if ^($category -eq 'UNKNOWN'^) {
echo         foreach ^($pattern in $bloatwareTasks^) {
echo             if ^($fullName -like $pattern -or $task.TaskName -like $pattern^) {
echo                 $category = 'BLOATWARE'
echo                 break
echo             }
echo         }
echo     }
echo/
echo     if ^($category -eq 'UNKNOWN'^) {
echo         foreach ^($pattern in $optionalTasks^) {
echo             if ^($fullName -like $pattern -or $task.TaskName -like $pattern^) {
echo                 $category = 'OPTIONAL'
echo                 break
echo             }
echo         }
echo     }
echo/
echo     # Skip Microsoft\Windows system tasks from unknown (they're usually fine)
echo     if ^($category -eq 'UNKNOWN' -and $task.TaskPath -match '\\Microsoft\\Windows\\'^) {
echo         $category = 'WINDOWS'
echo     }
echo/
echo     $info = [PSCustomObject]@{
echo         Name = $task.TaskName
echo         Path = $task.TaskPath
echo         FullName = $fullName
echo         State = $state
echo         Category = $category
echo     }
echo/
echo     switch ^($category^) {
echo         'TELEMETRY' { $telemetryList += $info }
echo         'BLOATWARE' { $bloatwareList += $info }
echo         'ESSENTIAL' { $essentialList += $info }
echo         'OPTIONAL' { $optionalList += $info }
echo         default { $unknownList += $info }
echo     }
echo }
echo/
echo # Display results
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host " SCHEDULED TASK AUDIT RESULTS" -ForegroundColor Cyan
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host ""
echo/
echo $report += "============================================================================"
echo $report += " Scheduled Task Audit - $env:COMPUTERNAME"
echo $report += " Date: $^(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'^)"
echo $report += "============================================================================"
echo $report += ""
echo/
echo # Telemetry
echo $activeTelemetry = @^($telemetryList ^| Where-Object { $_.State -ne 'Disabled' }^)
echo if ^($activeTelemetry.Count -gt 0^) {
echo     Write-Host "[TELEMETRY] - Data collection tasks (can be disabled for privacy):" -ForegroundColor Magenta
echo     $report += "[TELEMETRY] - Data collection tasks:"
echo     foreach ^($t in $activeTelemetry^) {
echo         Write-Host "  [-] $^($t.Name^)  ($^($t.State^))" -ForegroundColor Magenta
echo         Write-Host "      $^($t.FullName^)" -ForegroundColor DarkGray
echo         $report += "  [-] $^($t.Name^)  ($^($t.State^)^)  -  $^($t.FullName^)"
echo     }
echo     Write-Host ""
echo     $report += ""
echo }
echo/
echo # Bloatware
echo $activeBloatware = @^($bloatwareList ^| Where-Object { $_.State -ne 'Disabled' }^)
echo if ^($activeBloatware.Count -gt 0^) {
echo     Write-Host "[BLOATWARE] - Third-party junk tasks (recommended to disable):" -ForegroundColor Red
echo     $report += "[BLOATWARE] - Third-party junk tasks:"
echo     foreach ^($t in $activeBloatware^) {
echo         Write-Host "  [-] $^($t.Name^)  ($^($t.State^))" -ForegroundColor Red
echo         Write-Host "      $^($t.FullName^)" -ForegroundColor DarkGray
echo         $report += "  [-] $^($t.Name^)  ($^($t.State^)^)  -  $^($t.FullName^)"
echo     }
echo     Write-Host ""
echo     $report += ""
echo }
echo/
echo # Optional
echo $activeOptional = @^($optionalList ^| Where-Object { $_.State -ne 'Disabled' }^)
echo if ^($activeOptional.Count -gt 0^) {
echo     Write-Host "[OPTIONAL] - Can be disabled if not using these features:" -ForegroundColor Yellow
echo     $report += "[OPTIONAL] - Can be disabled if not needed:"
echo     foreach ^($t in $activeOptional^) {
echo         Write-Host "  [?] $^($t.Name^)  ($^($t.State^))" -ForegroundColor Yellow
echo         Write-Host "      $^($t.FullName^)" -ForegroundColor DarkGray
echo         $report += "  [?] $^($t.Name^)  ($^($t.State^)^)  -  $^($t.FullName^)"
echo     }
echo     Write-Host ""
echo     $report += ""
echo }
echo/
echo # Essential (brief)
echo $activeEssential = @^($essentialList ^| Where-Object { $_.State -ne 'Disabled' }^)
echo Write-Host "[ESSENTIAL] - $^($activeEssential.Count^) core tasks (will not be touched)" -ForegroundColor Green
echo $report += "[ESSENTIAL] - $^($activeEssential.Count^) core tasks (not touched)"
echo Write-Host ""
echo $report += ""
echo/
echo # Already disabled
echo $disabledCount = @^($allTasks ^| Where-Object { $_.State -eq 'Disabled' }^).Count
echo if ^($disabledCount -gt 0^) {
echo     Write-Host "[DISABLED] - $disabledCount tasks already disabled" -ForegroundColor DarkGray
echo     $report += "[DISABLED] - $disabledCount tasks already disabled"
echo     Write-Host ""
echo     $report += ""
echo }
echo/
echo # Summary
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host " SUMMARY" -ForegroundColor Cyan
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host ""
echo Write-Host "  Total scheduled tasks:  $^($allTasks.Count^)"
echo Write-Host "  Telemetry (active):     $^($activeTelemetry.Count^)" -ForegroundColor Magenta
echo Write-Host "  Bloatware (active):     $^($activeBloatware.Count^)" -ForegroundColor Red
echo Write-Host "  Optional (active):      $^($activeOptional.Count^)" -ForegroundColor Yellow
echo Write-Host "  Essential (active):     $^($activeEssential.Count^)" -ForegroundColor Green
echo Write-Host "  Already disabled:       $disabledCount" -ForegroundColor DarkGray
echo Write-Host ""
echo $report += ""
echo $report += "SUMMARY"
echo $report += "  Total tasks:       $^($allTasks.Count^)"
echo $report += "  Telemetry:         $^($activeTelemetry.Count^) active"
echo $report += "  Bloatware:         $^($activeBloatware.Count^) active"
echo $report += "  Optional:          $^($activeOptional.Count^) active"
echo $report += "  Essential:         $^($activeEssential.Count^) active"
echo $report += "  Already disabled:  $disabledCount"
echo $report += ""
echo/
echo # Offer to disable telemetry tasks
echo if ^($activeTelemetry.Count -gt 0^) {
echo     Write-Host ""
echo     $answer = Read-Host "Disable all TELEMETRY tasks? [Y/N]"
echo     if ^($answer -eq 'Y'^) {
echo         foreach ^($t in $activeTelemetry^) {
echo             try {
echo                 Disable-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction Stop ^| Out-Null
echo                 Write-Host "  [OK] Disabled: $^($t.Name^)" -ForegroundColor Green
echo                 $report += "  [DISABLED] $^($t.Name^)"
echo             } catch {
echo                 Write-Host "  [FAIL] Could not disable: $^($t.Name^) - $^($_.Exception.Message^)" -ForegroundColor Red
echo                 $report += "  [FAILED] $^($t.Name^) - $^($_.Exception.Message^)"
echo             }
echo         }
echo         Write-Host ""
echo     }
echo }
echo/
echo # Offer to disable bloatware tasks
echo if ^($activeBloatware.Count -gt 0^) {
echo     Write-Host ""
echo     $answer = Read-Host "Disable all BLOATWARE tasks? [Y/N]"
echo     if ^($answer -eq 'Y'^) {
echo         foreach ^($t in $activeBloatware^) {
echo             try {
echo                 Disable-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction Stop ^| Out-Null
echo                 Write-Host "  [OK] Disabled: $^($t.Name^)" -ForegroundColor Green
echo                 $report += "  [DISABLED] $^($t.Name^)"
echo             } catch {
echo                 Write-Host "  [FAIL] Could not disable: $^($t.Name^) - $^($_.Exception.Message^)" -ForegroundColor Red
echo                 $report += "  [FAILED] $^($t.Name^) - $^($_.Exception.Message^)"
echo             }
echo         }
echo         Write-Host ""
echo     }
echo }
echo/
echo # Offer to review optional tasks
echo if ^($activeOptional.Count -gt 0^) {
echo     Write-Host ""
echo     $answer = Read-Host "Review OPTIONAL tasks one by one? [Y/N]"
echo     if ^($answer -eq 'Y'^) {
echo         Write-Host ""
echo         foreach ^($t in $activeOptional^) {
echo             $choice = Read-Host "Disable '$^($t.Name^)'? [Y/N/Q to quit]"
echo             if ^($choice -eq 'Q'^) { break }
echo             if ^($choice -eq 'Y'^) {
echo                 try {
echo                     Disable-ScheduledTask -TaskName $t.Name -TaskPath $t.Path -ErrorAction Stop ^| Out-Null
echo                     Write-Host "  [OK] Disabled: $^($t.Name^)" -ForegroundColor Green
echo                     $report += "  [DISABLED] $^($t.Name^)"
echo                 } catch {
echo                     Write-Host "  [FAIL] Could not disable: $^($t.Name^) - $^($_.Exception.Message^)" -ForegroundColor Red
echo                 }
echo             }
echo         }
echo         Write-Host ""
echo     }
echo }
echo/
echo # Save report
echo $report ^| Out-File -FilePath '%OUTFILE%' -Encoding UTF8
echo/
echo Write-Host ""
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host " Scheduled Task Auditor Complete" -ForegroundColor Cyan
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host ""
echo Write-Host "Report saved to: %OUTFILE%" -ForegroundColor Green
echo Write-Host ""
echo Write-Host "To re-enable a disabled task:" -ForegroundColor Yellow
echo Write-Host '  schtasks /Change /TN "\Path\TaskName" /Enable' -ForegroundColor Yellow
echo Write-Host ""
) > "%PSSCRIPT%"

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%"

:: Cleanup
del "%PSSCRIPT%" 2>nul

echo/
pause
