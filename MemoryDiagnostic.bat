@echo off
setlocal enabledelayedexpansion
title Memory Diagnostic
color 0B

:: ============================================================================
:: Memory Diagnostic
:: ============================================================================
:: Shows installed RAM details (speed, slots, channel mode), checks for
:: mismatched sticks, reports current usage by process, and offers to
:: schedule Windows Memory Diagnostic (mdsched.exe) for next reboot.
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
echo %CYAN% Memory Diagnostic%RESET%
echo %CYAN%============================================================================%RESET%
echo/

:: Check admin status
set "isAdmin=0"
net session >nul 2>&1
if %errorlevel% equ 0 (
    set "isAdmin=1"
    echo %GREEN%[INFO] Running as administrator — full features available%RESET%
) else (
    echo %YELLOW%[INFO] Running without admin — some features limited%RESET%
    echo %YELLOW%       Run as admin for memory diagnostics scheduling%RESET%
)
echo/

:MainMenu
echo %CYAN%============================================================================%RESET%
echo %CYAN% Main Menu%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   [1] Hardware info (RAM sticks, speed, slots, channels)
echo   [2] Current memory usage breakdown by process
echo   [3] Memory configuration analysis
echo   [4] Schedule Windows Memory Diagnostic (requires admin)
echo   [0] Exit
echo/

set /p "choice=Select option: "

if "%choice%"=="1" goto HardwareInfo
if "%choice%"=="2" goto UsageBreakdown
if "%choice%"=="3" goto ConfigAnalysis
if "%choice%"=="4" goto ScheduleDiag
if "%choice%"=="0" goto Exit

echo %RED%Invalid option.%RESET%
echo/
goto MainMenu

:: ============================================================================
:: Option 1: Hardware Info
:: ============================================================================
:HardwareInfo
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% RAM Hardware Information%RESET%
echo %CYAN%============================================================================%RESET%
echo/

set "PSHW=%TEMP%\memory_hw.ps1"

(
echo $ErrorActionPreference = 'SilentlyContinue'
echo/
echo # System summary
echo $cs = Get-CimInstance Win32_ComputerSystem
echo $os = Get-CimInstance Win32_OperatingSystem
echo $totalGB = [math]::Round^($cs.TotalPhysicalMemory / 1GB, 2^)
echo $freeGB = [math]::Round^($os.FreePhysicalMemory / 1MB, 2^)
echo $usedGB = [math]::Round^($totalGB - $freeGB, 2^)
echo $usedPct = [math]::Round^(^($usedGB / $totalGB^) * 100, 1^)
echo/
echo Write-Host "  SYSTEM SUMMARY" -ForegroundColor White
echo Write-Host "  ---------------"
echo Write-Host "  Total Physical RAM:   $totalGB GB"
echo Write-Host "  Used:                 $usedGB GB ^($usedPct%%^)"
echo Write-Host "  Free:                 $freeGB GB"
echo Write-Host ""
echo/
echo # Get RAM stick details
echo $sticks = Get-CimInstance Win32_PhysicalMemory
echo $slotsFilled = $sticks.Count
echo/
echo # Get total slot count
echo $totalSlots = ^(Get-CimInstance Win32_PhysicalMemoryArray^).MemoryDevices
echo if ^(-not $totalSlots^) { $totalSlots = $slotsFilled }
echo/
echo Write-Host "  MEMORY SLOTS" -ForegroundColor White
echo Write-Host "  ---------------"
echo Write-Host "  Slots Filled:         $slotsFilled of $totalSlots"
echo Write-Host ""
echo/
echo # Determine channel mode
echo if ^($slotsFilled -ge 4 -and ^($slotsFilled %% 4^) -eq 0^) {
echo     $channelMode = "Quad-Channel ^(possible^)"
echo } elseif ^($slotsFilled -ge 2 -and ^($slotsFilled %% 2^) -eq 0^) {
echo     $channelMode = "Dual-Channel ^(likely^)"
echo } else {
echo     $channelMode = "Single-Channel"
echo }
echo/
echo # Check if all sticks have the same speed
echo $speeds = $sticks ^| Select-Object -ExpandProperty ConfiguredClockSpeed -Unique
echo $capacities = $sticks ^| Select-Object -ExpandProperty Capacity -Unique
echo $manufacturers = $sticks ^| Select-Object -ExpandProperty Manufacturer -Unique
echo $types = $sticks ^| Select-Object -ExpandProperty SMBIOSMemoryType -Unique
echo/
echo $isMatched = ^($speeds.Count -eq 1 -and $capacities.Count -eq 1^)
echo/
echo # Memory type name
echo $typeNames = @{
echo     20 = 'DDR'
echo     21 = 'DDR2'
echo     22 = 'DDR2 FB-DIMM'
echo     24 = 'DDR3'
echo     26 = 'DDR4'
echo     34 = 'DDR5'
echo }
echo/
echo Write-Host "  INSTALLED RAM STICKS" -ForegroundColor White
echo Write-Host "  --------------------"
echo Write-Host ""
echo Write-Host ^("  {0,-6} {1,-12} {2,-10} {3,-10} {4,-15} {5}" -f "Slot", "Capacity", "Speed", "Type", "Manufacturer", "Part Number"^) -ForegroundColor White
echo Write-Host ^("  {0,-6} {1,-12} {2,-10} {3,-10} {4,-15} {5}" -f ^("-"*5^), ^("-"*11^), ^("-"*9^), ^("-"*9^), ^("-"*14^), ^("-"*20^)^)
echo/
echo $stickNum = 0
echo foreach ^($stick in $sticks^) {
echo     $stickNum++
echo     $capGB = [math]::Round^($stick.Capacity / 1GB, 0^)
echo     $speed = $stick.ConfiguredClockSpeed
echo     $maxSpeed = $stick.Speed
echo     $mfr = $stick.Manufacturer
echo     if ^($mfr^) { $mfr = $mfr.Trim^(^) }
echo     if ^(-not $mfr -or $mfr -eq ''   ^) { $mfr = 'Unknown' }
echo     if ^($mfr.Length -gt 14^) { $mfr = $mfr.Substring^(0, 11^) + '...' }
echo     $partNum = $stick.PartNumber
echo     if ^($partNum^) { $partNum = $partNum.Trim^(^) }
echo     $slot = $stick.BankLabel
echo     if ^(-not $slot^) { $slot = "Slot $stickNum" }
echo     if ^($slot.Length -gt 5^) { $slot = $slot.Substring^(0, 5^) }
echo/
echo     $memType = $typeNames[[int]$stick.SMBIOSMemoryType]
echo     if ^(-not $memType^) { $memType = "Type $^($stick.SMBIOSMemoryType^)" }
echo/
echo     $speedStr = "${speed}MHz"
echo     Write-Host ^("  {0,-6} {1,-12} {2,-10} {3,-10} {4,-15} {5}" -f $slot, "$capGB GB", $speedStr, $memType, $mfr, $partNum^)
echo }
echo/
echo Write-Host ""
echo Write-Host "  CONFIGURATION" -ForegroundColor White
echo Write-Host "  ---------------"
echo Write-Host "  Channel Mode:         $channelMode"
echo/
echo if ^($isMatched^) {
echo     Write-Host "  Stick Matching:       All sticks matched ^(same speed and capacity^)" -ForegroundColor Green
echo } else {
echo     Write-Host "  Stick Matching:       MISMATCHED sticks detected^^!" -ForegroundColor Red
echo     if ^($speeds.Count -gt 1^) {
echo         Write-Host "    - Different speeds: $^($speeds -join ', '^) MHz" -ForegroundColor Yellow
echo         Write-Host "      All sticks will run at the slowest speed." -ForegroundColor Yellow
echo     }
echo     if ^($capacities.Count -gt 1^) {
echo         $capList = $capacities ^| ForEach-Object { "$^([math]::Round^($_ / 1GB, 0^)^) GB" }
echo         Write-Host "    - Different capacities: $^($capList -join ', '^)" -ForegroundColor Yellow
echo         Write-Host "      Dual-channel may operate in flex mode ^(partial dual-channel^)." -ForegroundColor Yellow
echo     }
echo }
echo/
echo # XMP/DOCP detection
echo $configSpeed = ^($sticks ^| Select-Object -First 1^).ConfiguredClockSpeed
echo $ratedSpeed = ^($sticks ^| Select-Object -First 1^).Speed
echo if ^($ratedSpeed -and $configSpeed -and $ratedSpeed -gt $configSpeed^) {
echo     Write-Host ""
echo     Write-Host "  XMP/DOCP:             NOT ENABLED" -ForegroundColor Yellow
echo     Write-Host "    - RAM is running at ${configSpeed}MHz but rated for ${ratedSpeed}MHz" -ForegroundColor Yellow
echo     Write-Host "    - Enable XMP/DOCP/EXPO in BIOS to get full speed" -ForegroundColor Yellow
echo } elseif ^($ratedSpeed -and $configSpeed -and $ratedSpeed -eq $configSpeed^) {
echo     Write-Host "  XMP/DOCP:             Running at rated speed ^(${configSpeed}MHz^)" -ForegroundColor Green
echo }
echo/
echo # Single channel warning
echo if ^($channelMode -eq 'Single-Channel'^) {
echo     Write-Host ""
echo     Write-Host "  WARNING: Single-channel mode detected^^!" -ForegroundColor Red
echo     Write-Host "    - Dual-channel doubles memory bandwidth" -ForegroundColor Yellow
echo     Write-Host "    - Add a matching stick for significant performance gain" -ForegroundColor Yellow
echo     Write-Host "    - Especially impacts gaming and integrated graphics" -ForegroundColor Yellow
echo }
echo/
echo Write-Host ""
) > "!PSHW!"

powershell -ExecutionPolicy Bypass -File "!PSHW!" 2>nul
del "!PSHW!" 2>nul

pause
goto MainMenu

:: ============================================================================
:: Option 2: Usage Breakdown
:: ============================================================================
:UsageBreakdown
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Memory Usage by Process%RESET%
echo %CYAN%============================================================================%RESET%
echo/

set "PSUSAGE=%TEMP%\memory_usage.ps1"

(
echo $ErrorActionPreference = 'SilentlyContinue'
echo/
echo # System overview
echo $os = Get-CimInstance Win32_OperatingSystem
echo $cs = Get-CimInstance Win32_ComputerSystem
echo $totalGB = [math]::Round^($cs.TotalPhysicalMemory / 1GB, 2^)
echo $freeGB = [math]::Round^($os.FreePhysicalMemory / 1MB, 2^)
echo $usedGB = [math]::Round^($totalGB - $freeGB, 2^)
echo $usedPct = [math]::Round^(^($usedGB / $totalGB^) * 100, 1^)
echo/
echo # Performance counter data
echo $committed = [math]::Round^(^(Get-CimInstance Win32_OperatingSystem^).TotalVirtualMemorySize / 1MB, 2^)
echo $committedUsed = [math]::Round^(^(Get-CimInstance Win32_OperatingSystem^).TotalVirtualMemorySize / 1MB - ^(Get-CimInstance Win32_OperatingSystem^).FreeVirtualMemory / 1MB, 2^)
echo/
echo Write-Host "  SYSTEM MEMORY OVERVIEW" -ForegroundColor White
echo Write-Host "  ----------------------"
echo Write-Host ""
echo/
echo # Memory bar
echo $barWidth = 50
echo $filledWidth = [math]::Floor^($usedPct / 100 * $barWidth^)
echo $emptyWidth = $barWidth - $filledWidth
echo $bar = "[" + ^("#" * $filledWidth^) + ^("-" * $emptyWidth^) + "]"
echo $barColor = 'Green'
echo if ^($usedPct -ge 70^) { $barColor = 'Yellow' }
echo if ^($usedPct -ge 90^) { $barColor = 'Red' }
echo Write-Host "  $bar $usedPct%%" -ForegroundColor $barColor
echo Write-Host ""
echo Write-Host "  Physical:   $usedGB / $totalGB GB used"
echo Write-Host "  Committed:  $committedUsed / $committed GB"
echo Write-Host ""
echo/
echo # Top processes by memory
echo Write-Host "  TOP 25 PROCESSES BY MEMORY USAGE" -ForegroundColor White
echo Write-Host "  ---------------------------------"
echo Write-Host ""
echo Write-Host ^("  {0,-5} {1,-35} {2,-12} {3,-8} {4}" -f "Rank", "Process", "Working Set", "%%RAM", "PID"^) -ForegroundColor White
echo Write-Host ^("  {0,-5} {1,-35} {2,-12} {3,-8} {4}" -f ^("-"*4^), ^("-"*34^), ^("-"*11^), ^("-"*7^), ^("-"*8^)^)
echo/
echo $totalBytes = $cs.TotalPhysicalMemory
echo $procs = Get-Process ^| Sort-Object WorkingSet64 -Descending ^| Select-Object -First 25
echo $rank = 0
echo foreach ^($p in $procs^) {
echo     $rank++
echo     $name = $p.ProcessName
echo     if ^($name.Length -gt 34^) { $name = $name.Substring^(0, 31^) + '...' }
echo     $wsMB = [math]::Round^($p.WorkingSet64 / 1MB, 1^)
echo     $pct = [math]::Round^(^($p.WorkingSet64 / $totalBytes^) * 100, 1^)
echo     $procId = $p.Id
echo/
echo     $wsStr = if ^($wsMB -ge 1024^) { "$^([math]::Round^($wsMB / 1024, 1^)^) GB" } else { "$wsMB MB" }
echo/
echo     $color = 'White'
echo     if ^($pct -ge 5^) { $color = 'Yellow' }
echo     if ^($pct -ge 15^) { $color = 'Red' }
echo/
echo     Write-Host ^("  {0,-5} {1,-35} {2,-12} {3,-8} {4}" -f "#$rank", $name, $wsStr, "$pct%%", $procId^) -ForegroundColor $color
echo }
echo/
echo Write-Host ""
echo/
echo # Process category summary
echo Write-Host "  MEMORY BY CATEGORY" -ForegroundColor White
echo Write-Host "  ------------------"
echo Write-Host ""
echo/
echo $allProcs = Get-Process
echo $browsers = $allProcs ^| Where-Object { $_.ProcessName -match 'chrome^|firefox^|msedge^|opera^|brave^|vivaldi' }
echo $browserMB = [math]::Round^(^($browsers ^| Measure-Object WorkingSet64 -Sum^).Sum / 1MB, 0^)
echo/
echo $games = $allProcs ^| Where-Object { $_.ProcessName -match 'steam^|epic^|origin^|uplay^|battle.net' }
echo $gameMB = [math]::Round^(^($games ^| Measure-Object WorkingSet64 -Sum^).Sum / 1MB, 0^)
echo/
echo $system = $allProcs ^| Where-Object { $_.ProcessName -match 'svchost^|System^|csrss^|lsass^|smss^|services^|wininit^|dwm^|explorer' }
echo $systemMB = [math]::Round^(^($system ^| Measure-Object WorkingSet64 -Sum^).Sum / 1MB, 0^)
echo/
echo $security = $allProcs ^| Where-Object { $_.ProcessName -match 'MsMpEng^|SecurityHealth^|avast^|avg^|norton^|kaspersky^|bitdefender^|malwarebytes' }
echo $securityMB = [math]::Round^(^($security ^| Measure-Object WorkingSet64 -Sum^).Sum / 1MB, 0^)
echo/
echo $totalProcMB = [math]::Round^(^($allProcs ^| Measure-Object WorkingSet64 -Sum^).Sum / 1MB, 0^)
echo $otherMB = $totalProcMB - $browserMB - $gameMB - $systemMB - $securityMB
echo/
echo Write-Host ^("  Browsers:       {0,8} MB  ^({1} processes^)" -f $browserMB, $browsers.Count^)
echo Write-Host ^("  System/Shell:   {0,8} MB  ^({1} processes^)" -f $systemMB, $system.Count^)
echo Write-Host ^("  Security:       {0,8} MB  ^({1} processes^)" -f $securityMB, $security.Count^)
echo Write-Host ^("  Game Clients:   {0,8} MB  ^({1} processes^)" -f $gameMB, $games.Count^)
echo Write-Host ^("  Other:          {0,8} MB" -f $otherMB^)
echo Write-Host ^("  -------------------------"^)
echo Write-Host ^("  Total:          {0,8} MB  ^({1} processes^)" -f $totalProcMB, $allProcs.Count^)
echo Write-Host ""
) > "!PSUSAGE!"

powershell -ExecutionPolicy Bypass -File "!PSUSAGE!" 2>nul
del "!PSUSAGE!" 2>nul

pause
goto MainMenu

:: ============================================================================
:: Option 3: Configuration Analysis
:: ============================================================================
:ConfigAnalysis
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Memory Configuration Analysis%RESET%
echo %CYAN%============================================================================%RESET%
echo/

set "PSCONFIG=%TEMP%\memory_config.ps1"

(
echo $ErrorActionPreference = 'SilentlyContinue'
echo/
echo $cs = Get-CimInstance Win32_ComputerSystem
echo $os = Get-CimInstance Win32_OperatingSystem
echo $sticks = Get-CimInstance Win32_PhysicalMemory
echo $totalGB = [math]::Round^($cs.TotalPhysicalMemory / 1GB, 2^)
echo $totalSlots = ^(Get-CimInstance Win32_PhysicalMemoryArray^).MemoryDevices
echo $slotsFilled = $sticks.Count
echo/
echo $issues = @^(^)
echo $recommendations = @^(^)
echo $score = 100
echo/
echo Write-Host "  CONFIGURATION ANALYSIS" -ForegroundColor White
echo Write-Host "  ----------------------"
echo Write-Host ""
echo/
echo # Check 1: Total RAM
echo Write-Host "  [CHECK] Total RAM: $totalGB GB" -NoNewline
echo if ^($totalGB -lt 8^) {
echo     Write-Host " - INSUFFICIENT" -ForegroundColor Red
echo     $issues += "Less than 8 GB RAM - minimum for modern Windows"
echo     $recommendations += "Upgrade to at least 16 GB RAM"
echo     $score -= 30
echo } elseif ^($totalGB -lt 16^) {
echo     Write-Host " - ADEQUATE" -ForegroundColor Yellow
echo     $recommendations += "Consider upgrading to 16 GB for better multitasking"
echo     $score -= 10
echo } elseif ^($totalGB -ge 32^) {
echo     Write-Host " - EXCELLENT" -ForegroundColor Green
echo } else {
echo     Write-Host " - GOOD" -ForegroundColor Green
echo }
echo/
echo # Check 2: Channel mode
echo $channelMode = "Single"
echo if ^($slotsFilled -ge 2 -and ^($slotsFilled %% 2^) -eq 0^) { $channelMode = "Dual" }
echo if ^($slotsFilled -ge 4 -and ^($slotsFilled %% 4^) -eq 0^) { $channelMode = "Quad" }
echo/
echo Write-Host "  [CHECK] Channel Mode: $channelMode-channel" -NoNewline
echo if ^($channelMode -eq "Single"^) {
echo     Write-Host " - SUBOPTIMAL" -ForegroundColor Red
echo     $issues += "Single-channel mode halves memory bandwidth"
echo     $recommendations += "Add a matching RAM stick for dual-channel"
echo     $score -= 25
echo } else {
echo     Write-Host " - OK" -ForegroundColor Green
echo }
echo/
echo # Check 3: Matched sticks
echo $speeds = $sticks ^| Select-Object -ExpandProperty ConfiguredClockSpeed -Unique
echo $capacities = $sticks ^| Select-Object -ExpandProperty Capacity -Unique
echo $isMatched = ^($speeds.Count -eq 1 -and $capacities.Count -eq 1^)
echo/
echo Write-Host "  [CHECK] Stick Matching:" -NoNewline
echo if ^($isMatched^) {
echo     Write-Host " MATCHED" -ForegroundColor Green
echo } else {
echo     Write-Host " MISMATCHED" -ForegroundColor Yellow
echo     if ^($speeds.Count -gt 1^) {
echo         $issues += "Mixed RAM speeds: $^($speeds -join ', '^) MHz"
echo         $recommendations += "Use identical RAM sticks for optimal performance"
echo         $score -= 10
echo     }
echo     if ^($capacities.Count -gt 1^) {
echo         $capList = $capacities ^| ForEach-Object { "$^([math]::Round^($_ / 1GB, 0^)^) GB" }
echo         $issues += "Mixed RAM capacities: $^($capList -join ', '^)"
echo         $score -= 5
echo     }
echo }
echo/
echo # Check 4: XMP/DOCP
echo $configSpeed = ^($sticks ^| Select-Object -First 1^).ConfiguredClockSpeed
echo $ratedSpeed = ^($sticks ^| Select-Object -First 1^).Speed
echo/
echo Write-Host "  [CHECK] XMP/DOCP:" -NoNewline
echo if ^($ratedSpeed -and $configSpeed -and $ratedSpeed -gt $configSpeed^) {
echo     Write-Host " NOT ENABLED ^(${configSpeed}MHz of ${ratedSpeed}MHz^)" -ForegroundColor Yellow
echo     $issues += "RAM running below rated speed ^(${configSpeed} vs ${ratedSpeed} MHz^)"
echo     $recommendations += "Enable XMP/DOCP/EXPO in BIOS for full RAM speed"
echo     $score -= 15
echo } elseif ^($ratedSpeed -and $configSpeed^) {
echo     Write-Host " OK ^(${configSpeed}MHz^)" -ForegroundColor Green
echo } else {
echo     Write-Host " UNKNOWN" -ForegroundColor Yellow
echo }
echo/
echo # Check 5: Available slots
echo $emptySlots = $totalSlots - $slotsFilled
echo Write-Host "  [CHECK] Expansion:" -NoNewline
echo if ^($emptySlots -gt 0^) {
echo     Write-Host " $emptySlots empty slot^(s^) available" -ForegroundColor Green
echo } else {
echo     Write-Host " All slots filled ^(no expansion possible^)" -ForegroundColor Yellow
echo     if ^($totalGB -lt 32^) {
echo         $recommendations += "All slots full - would need higher capacity sticks to upgrade"
echo     }
echo }
echo/
echo # Check 6: Current usage
echo $freeGB = [math]::Round^($os.FreePhysicalMemory / 1MB, 2^)
echo $usedPct = [math]::Round^(^(1 - $freeGB / $totalGB^) * 100, 1^)
echo/
echo Write-Host "  [CHECK] Current Usage: $usedPct%%" -NoNewline
echo if ^($usedPct -ge 90^) {
echo     Write-Host " - CRITICAL" -ForegroundColor Red
echo     $issues += "Memory usage above 90%% - system may be swapping"
echo     $recommendations += "Close unnecessary programs or add more RAM"
echo     $score -= 15
echo } elseif ^($usedPct -ge 75^) {
echo     Write-Host " - HIGH" -ForegroundColor Yellow
echo     $score -= 5
echo } else {
echo     Write-Host " - OK" -ForegroundColor Green
echo }
echo/
echo # Check 7: Pagefile
echo $pf = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue
echo Write-Host "  [CHECK] Pagefile:" -NoNewline
echo if ^($pf^) {
echo     $pfUsePct = if ^($pf.AllocatedBaseSize -gt 0^) { [math]::Round^($pf.CurrentUsage / $pf.AllocatedBaseSize * 100, 1^) } else { 0 }
echo     if ^($pfUsePct -ge 50^) {
echo         Write-Host " $pfUsePct%% used ^($^($pf.CurrentUsage^) MB of $^($pf.AllocatedBaseSize^) MB^)" -ForegroundColor Yellow
echo         $recommendations += "High pagefile usage - consider adding more RAM"
echo     } else {
echo         Write-Host " $pfUsePct%% used ^($^($pf.CurrentUsage^) MB of $^($pf.AllocatedBaseSize^) MB^)" -ForegroundColor Green
echo     }
echo } else {
echo     Write-Host " NOT CONFIGURED" -ForegroundColor Red
echo     $issues += "No pagefile detected"
echo     $score -= 10
echo }
echo/
echo Write-Host ""
echo/
echo # Score
echo $grade = switch ^([math]::Floor^($score / 10^)^) {
echo     { $_ -ge 9 } { 'A' }
echo     { $_ -ge 8 } { 'B' }
echo     { $_ -ge 7 } { 'C' }
echo     { $_ -ge 6 } { 'D' }
echo     default { 'F' }
echo }
echo $gradeColor = switch ^($grade^) {
echo     'A' { 'Green' }
echo     'B' { 'Green' }
echo     'C' { 'Yellow' }
echo     'D' { 'Yellow' }
echo     'F' { 'Red' }
echo }
echo/
echo Write-Host "  OVERALL GRADE: $grade ^($score/100^)" -ForegroundColor $gradeColor
echo Write-Host ""
echo/
echo if ^($issues.Count -gt 0^) {
echo     Write-Host "  ISSUES FOUND:" -ForegroundColor Red
echo     foreach ^($i in $issues^) {
echo         Write-Host "    - $i" -ForegroundColor Red
echo     }
echo     Write-Host ""
echo }
echo/
echo if ^($recommendations.Count -gt 0^) {
echo     Write-Host "  RECOMMENDATIONS:" -ForegroundColor Yellow
echo     foreach ^($r in $recommendations^) {
echo         Write-Host "    - $r" -ForegroundColor Yellow
echo     }
echo     Write-Host ""
echo }
) > "!PSCONFIG!"

powershell -ExecutionPolicy Bypass -File "!PSCONFIG!" 2>nul
del "!PSCONFIG!" 2>nul

pause
goto MainMenu

:: ============================================================================
:: Option 4: Schedule Windows Memory Diagnostic
:: ============================================================================
:ScheduleDiag
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Windows Memory Diagnostic (mdsched.exe)%RESET%
echo %CYAN%============================================================================%RESET%
echo/

if "!isAdmin!"=="0" (
    echo %RED%[ERROR] This option requires administrator privileges.%RESET%
    echo %RED%        Right-click and select "Run as administrator"%RESET%
    echo/
    pause
    goto MainMenu
)

echo Windows Memory Diagnostic tests your RAM for hardware errors.
echo/
echo %YELLOW%What it does:%RESET%
echo  - Writes test patterns to all RAM addresses
echo  - Reads back and checks for errors
echo  - Takes 10-30 minutes depending on RAM amount
echo  - Requires a reboot (runs before Windows loads)
echo/
echo %WHITE%When to use:%RESET%
echo  - Blue screens (BSOD) with memory-related stop codes
echo  - Random application crashes
echo  - File corruption without disk issues
echo  - System instability after adding new RAM
echo/

echo %YELLOW%Options:%RESET%
echo   [1] Schedule and restart now
echo   [2] Schedule for next restart
echo   [3] View results from last diagnostic
echo   [0] Cancel
echo/

set /p "diagChoice=Select option: "

if "%diagChoice%"=="0" goto MainMenu

if "%diagChoice%"=="3" (
    echo/
    echo %WHITE%Last Memory Diagnostic results:%RESET%
    echo/

    set "PSRESULT=%TEMP%\memdiag_results.ps1"

    (
    echo $results = Get-WinEvent -FilterHashtable @{ LogName='System'; ProviderName='Microsoft-Windows-MemoryDiagnostics-Results' } -MaxEvents 5 -ErrorAction SilentlyContinue
    echo if ^($results^) {
    echo     foreach ^($r in $results^) {
    echo         Write-Host "  Date:    $^($r.TimeCreated^)" -ForegroundColor White
    echo         Write-Host "  Result:  $^($r.Message^)"
    echo         Write-Host ""
    echo     }
    echo } else {
    echo     Write-Host "  No memory diagnostic results found." -ForegroundColor Yellow
    echo     Write-Host "  Run a diagnostic first ^(options 1 or 2^)."
    echo }
    ) > "!PSRESULT!"

    powershell -ExecutionPolicy Bypass -File "!PSRESULT!" 2>nul
    del "!PSRESULT!" 2>nul

    echo/
    pause
    goto MainMenu
)

if "%diagChoice%"=="1" (
    echo/
    echo %YELLOW%The computer will restart now to run Memory Diagnostic.%RESET%
    echo %YELLOW%Save all work before continuing.%RESET%
    echo/
    set /p "confirm=Restart now? [Y/N]: "
    if /i not "!confirm!"=="Y" goto MainMenu

    :: Schedule immediate diagnostic
    bcdedit /set {memdiag} locale en-US >nul 2>&1
    mdsched.exe /f >nul 2>&1
    if errorlevel 1 (
        :: Fallback
        echo %YELLOW%Starting Windows Memory Diagnostic...%RESET%
        start "" mdsched.exe
    )
    goto MainMenu
)

if "%diagChoice%"=="2" (
    echo/
    echo %GREEN%Memory Diagnostic will run on next restart.%RESET%
    echo/
    mdsched.exe >nul 2>&1
    if errorlevel 1 (
        start "" mdsched.exe
    )
    echo %YELLOW%When prompted by the system dialog, select%RESET%
    echo %YELLOW%"Check for problems the next time I start my computer"%RESET%
    echo/
    pause
    goto MainMenu
)

echo %RED%Invalid option.%RESET%
pause
goto MainMenu

:Exit
echo/
echo Goodbye.
exit /b 0
