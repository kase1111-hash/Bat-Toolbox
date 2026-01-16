@echo off
setlocal enabledelayedexpansion
title Running Process Scanner
color 0B

:: ============================================================================
:: Running Process Scanner
:: ============================================================================
:: Scans running processes to identify bloatware, forgotten background
:: programs, and resource hogs. Categorizes processes and offers cleanup.
:: ============================================================================

echo ============================================================================
echo  Running Process Scanner
echo ============================================================================
echo.
echo Scanning running processes...
echo.

:: Create temp file for results
set "PSSCRIPT=%TEMP%\scan_processes.ps1"

:: ============================================================================
:: Create PowerShell script for process analysis
:: ============================================================================

(
echo # Process Scanner - Categorizes running processes
echo.
echo # Define process categories
echo $essentialProcesses = @(
echo     # Windows Core
echo     'System', 'smss', 'csrss', 'wininit', 'services', 'lsass', 'svchost',
echo     'dwm', 'explorer', 'sihost', 'taskhostw', 'RuntimeBroker', 'ShellExperienceHost',
echo     'StartMenuExperienceHost', 'SearchHost', 'SearchIndexer', 'ctfmon',
echo     'conhost', 'dllhost', 'WmiPrvSE', 'msiexec', 'TrustedInstaller',
echo     'spoolsv', 'wuauclt', 'WUDFHost', 'dasHost', 'Memory Compression',
echo     'Registry', 'fontdrvhost', 'lsaiso', 'MsMpEng', 'NisSrv',
echo     'SecurityHealthService', 'SecurityHealthSystray', 'SgrmBroker',
echo     'audiodg', 'WindowsInternal', 'TextInputHost', 'SystemSettings',
echo     'ApplicationFrameHost', 'backgroundTaskHost', 'SettingSyncHost',
echo     'UserOOBEBroker', 'LockApp', 'LogonUI', 'winlogon', 'Idle',
echo     'MoUsoCoreWorker', 'TiWorker', 'WerFault', 'CompPkgSrv',
echo     # Drivers and Hardware
echo     'nvcontainer', 'NVDisplay.Container', 'NVIDIA Share', 'nvsphelper64',
echo     'AMD External Events', 'RadeonSoftware', 'AMDRSServ', 'aaborker',
echo     'igfxEM', 'igfxCUIService', 'IntelCpHDCPSvc', 'IntelCpHeciSvc',
echo     'RtkAudioService', 'RAVBg64', 'RtkNGUI64', 'WavesSvc64',
echo     'SynTPEnh', 'ETDCtrl', 'ETDService',
echo     'BTAGService', 'btwdins', 'btmshellex',
echo     # Security ^(legitimate^)
echo     'MsMpEng', 'NisSrv', 'SecurityHealthService', 'smartscreen'
echo ^)
echo.
echo $bloatwareProcesses = @{
echo     # Antivirus ^(third-party - Windows Defender is sufficient^)
echo     'avast' = 'Avast Antivirus - Windows Defender is sufficient'
echo     'avgui' = 'AVG Antivirus - Windows Defender is sufficient'
echo     'avguard' = 'Avira Antivirus - Windows Defender is sufficient'
echo     'mcshield' = 'McAfee Antivirus - Windows Defender is sufficient'
echo     'mcuicnt' = 'McAfee UI - Windows Defender is sufficient'
echo     'norton' = 'Norton Antivirus - Windows Defender is sufficient'
echo     'ns.exe' = 'Norton Security - Windows Defender is sufficient'
echo     'NortonSecurity' = 'Norton Security - Windows Defender is sufficient'
echo     'bdagent' = 'Bitdefender - Windows Defender is sufficient'
echo     'bdservicehost' = 'Bitdefender - Windows Defender is sufficient'
echo     'kapersky' = 'Kaspersky - Windows Defender is sufficient'
echo     'webroot' = 'Webroot - Windows Defender is sufficient'
echo     # PUPs and Bloatware
echo     'CCleaner' = 'CCleaner monitoring - unnecessary background task'
echo     'ccleaner64' = 'CCleaner - unnecessary background process'
echo     'Driver Booster' = 'Driver Booster - often installs unwanted software'
echo     'daborker' = 'Driver Booster - PUP'
echo     'IObit' = 'IObit software - often bundles PUPs'
echo     'ASC.exe' = 'Advanced SystemCare - unnecessary optimizer'
echo     'Auslogics' = 'Auslogics - unnecessary optimization software'
echo     'GlaryUtilities' = 'Glary Utilities - unnecessary optimizer'
echo     'WiseCare' = 'Wise Care - unnecessary optimizer'
echo     'Segurazo' = 'SEGURAZO MALWARE - Remove immediately!'
echo     'ByteFence' = 'ByteFence PUP - Remove immediately!'
echo     'Reimage' = 'Reimage Scareware - Remove immediately!'
echo     'PCAccelerator' = 'PC Accelerator Scareware - Remove!'
echo     'SpyHunter' = 'SpyHunter - Scareware, remove!'
echo     'RegClean' = 'Registry Cleaner - unnecessary and potentially harmful'
echo     'WinTonic' = 'WinTonic - PUP/Scareware'
echo     'OneSafe' = 'OneSafe PC Cleaner - PUP'
echo     'TotalAV' = 'TotalAV - aggressive upselling'
echo     'Conduit' = 'Conduit - Browser hijacker!'
echo     'Ask Toolbar' = 'Ask Toolbar - Browser hijacker!'
echo     'Babylon' = 'Babylon - Browser hijacker!'
echo     'MyWebSearch' = 'MyWebSearch - Adware!'
echo     'WebCompanion' = 'Web Companion - PUP'
echo     'SearchProtect' = 'Search Protect - Browser hijacker!'
echo     # Updaters ^(unnecessary background processes^)
echo     'jusched' = 'Java Updater - can update manually when needed'
echo     'jucheck' = 'Java Update Checker - unnecessary'
echo     'AdobeARM' = 'Adobe Updater - can update manually'
echo     'armsvc' = 'Adobe ARM Service - unnecessary background service'
echo     'AdobeUpdateService' = 'Adobe Update - unnecessary'
echo     'AGSService' = 'Adobe Genuine Service - unnecessary'
echo     'AdobeGCClient' = 'Adobe Genuine Client - unnecessary'
echo     'CCXProcess' = 'Adobe Creative Cloud - heavy resource usage'
echo     'CCLibrary' = 'Adobe CC Library - runs constantly'
echo     'GoogleUpdate' = 'Google Updater - Chrome updates itself'
echo     'GoogleCrashHandler' = 'Google Crash Handler - unnecessary'
echo     'MicrosoftEdgeUpdate' = 'Edge Updater - Edge updates itself'
echo     'OperaUpdate' = 'Opera Updater - unnecessary'
echo     'BraveUpdate' = 'Brave Updater - unnecessary'
echo     # Apps that dont need to run constantly
echo     'Spotify' = 'Spotify - launch manually when needed'
echo     'SpotifyWebHelper' = 'Spotify Web Helper - unnecessary'
echo     'Discord' = 'Discord - launch manually, uses ~300MB RAM'
echo     'Slack' = 'Slack - launch manually when needed'
echo     'Teams' = 'Microsoft Teams - heavy resource usage, launch manually'
echo     'Zoom' = 'Zoom - launch manually for meetings'
echo     'Skype' = 'Skype - launch manually when needed'
echo     'WhatsApp' = 'WhatsApp - launch manually when needed'
echo     'Telegram' = 'Telegram - launch manually when needed'
echo     'Steam' = 'Steam Client - launch manually for gaming'
echo     'steamwebhelper' = 'Steam Web Helper - uses significant RAM'
echo     'EpicGamesLauncher' = 'Epic Games - launch manually for gaming'
echo     'Origin' = 'EA Origin - launch manually for gaming'
echo     'Uplay' = 'Ubisoft Connect - launch manually for gaming'
echo     'GOGGalaxy' = 'GOG Galaxy - launch manually for gaming'
echo     'Battle.net' = 'Battle.net - launch manually for gaming'
echo     'iTunesHelper' = 'iTunes Helper - slows system, unnecessary'
echo     'iTunes' = 'iTunes running in background - close when not using'
echo     'QuickTime' = 'QuickTime - outdated, security risk'
echo     # Cloud sync ^(optional^)
echo     'OneDrive' = 'OneDrive - disable if not using cloud sync'
echo     'Dropbox' = 'Dropbox - disable if not using cloud sync'
echo     'GoogleDriveFS' = 'Google Drive - disable if not using cloud sync'
echo     'iCloudServices' = 'iCloud - disable if not using Apple ecosystem'
echo     'BoxSync' = 'Box Sync - disable if not using'
echo     # Vendor bloatware
echo     'GiftBox' = 'ASUS GiftBox - bloatware'
echo     'MyASUS' = 'MyASUS - optional, can be removed'
echo     'ASUSOptimization' = 'ASUS Optimization - unnecessary'
echo     'GameFirstUV' = 'ASUS GameFirst - unnecessary'
echo     'NahimicService' = 'Nahimic Audio - optional audio enhancer'
echo     'Nahimic' = 'Nahimic - optional, uses resources'
echo     'DellSupportAssist' = 'Dell Support - can be removed'
echo     'HPSupportSolutions' = 'HP Support - can be removed'
echo     'LenovoVantage' = 'Lenovo Vantage - optional'
echo     'ImController' = 'Lenovo Service - optional'
echo     'AcerQuickAccess' = 'Acer Quick Access - optional'
echo     'CyberLink' = 'CyberLink software - bloatware'
echo     'Corel' = 'Corel software - trial bloatware'
echo     'WinZip' = 'WinZip - use free 7-Zip instead'
echo     'WinRAR' = 'WinRAR trial - use free 7-Zip instead'
echo     'ExpressVPN' = 'ExpressVPN - launch manually when needed'
echo     'NordVPN' = 'NordVPN - launch manually when needed'
echo }
echo.
echo $optionalProcesses = @{
echo     # Legitimate but resource-heavy
echo     'ArmouryCrate' = 'ASUS Armoury Crate - RGB/fan control, uses resources'
echo     'LightingService' = 'ASUS Aura - RGB lighting control'
echo     'iCUE' = 'Corsair iCUE - peripheral software, uses ~200MB RAM'
echo     'RazerCentral' = 'Razer Synapse - peripheral software'
echo     'LGHUB' = 'Logitech G Hub - peripheral software'
echo     'SteelSeriesGG' = 'SteelSeries GG - peripheral software'
echo     'NVIDIAShare' = 'NVIDIA ShadowPlay - screen recording'
echo     'NVIDIA GeForce Experience' = 'GeForce Experience - optional'
echo     'RadeonSoftware' = 'AMD Radeon Software - GPU control panel'
echo     'MSIAfterburner' = 'MSI Afterburner - GPU overclocking'
echo     'RivaTuner' = 'RivaTuner - FPS overlay'
echo     'HWiNFO' = 'HWiNFO - hardware monitoring'
echo     'OpenHardwareMonitor' = 'Hardware Monitor - system monitoring'
echo     'Rainmeter' = 'Rainmeter - desktop customization'
echo     'Wallpaper Engine' = 'Wallpaper Engine - animated wallpapers'
echo     'f.lux' = 'f.lux - screen color, Windows has Night Light'
echo     'ShareX' = 'ShareX - screenshot tool'
echo     'Lightshot' = 'Lightshot - screenshot tool'
echo     'Greenshot' = 'Greenshot - screenshot tool'
echo     'Everything' = 'Everything Search - file search tool'
echo     'PowerToys' = 'PowerToys - Windows utilities'
echo     '1Password' = 'Password manager - can close when not needed'
echo     'LastPass' = 'LastPass - can use browser extension instead'
echo     'Bitwarden' = 'Bitwarden - can use browser extension instead'
echo     'KeePass' = 'KeePass - can close when not needed'
echo }
echo.
echo # Get all running processes with details
echo $processes = Get-Process ^| Select-Object Name, Id, CPU,
echo     @{Name='MemoryMB';Expression={[math]::Round^($_.WorkingSet64/1MB,1^)}},
echo     @{Name='Path';Expression={$_.Path}},
echo     Description ^|
echo     Sort-Object MemoryMB -Descending
echo.
echo $essential = @^(^)
echo $bloatware = @^(^)
echo $optional = @^(^)
echo $unknown = @^(^)
echo $highMemory = @^(^)
echo.
echo foreach ^($proc in $processes^) {
echo     $name = $proc.Name
echo     $found = $false
echo.
echo     # Check essential
echo     foreach ^($pattern in $essentialProcesses^) {
echo         if ^($name -like "*$pattern*"^) {
echo             $essential += $proc
echo             $found = $true
echo             break
echo         }
echo     }
echo     if ^($found^) { continue }
echo.
echo     # Check bloatware
echo     foreach ^($key in $bloatwareProcesses.Keys^) {
echo         if ^($name -like "*$key*"^) {
echo             $proc ^| Add-Member -NotePropertyName 'Reason' -NotePropertyValue $bloatwareProcesses[$key] -Force
echo             $bloatware += $proc
echo             $found = $true
echo             break
echo         }
echo     }
echo     if ^($found^) { continue }
echo.
echo     # Check optional
echo     foreach ^($key in $optionalProcesses.Keys^) {
echo         if ^($name -like "*$key*"^) {
echo             $proc ^| Add-Member -NotePropertyName 'Reason' -NotePropertyValue $optionalProcesses[$key] -Force
echo             $optional += $proc
echo             $found = $true
echo             break
echo         }
echo     }
echo     if ^($found^) { continue }
echo.
echo     # Unknown process
echo     $unknown += $proc
echo }
echo.
echo # High memory processes ^(over 500MB^)
echo $highMemory = $processes ^| Where-Object { $_.MemoryMB -gt 500 }
echo.
echo # Calculate totals
echo $totalMemory = ^($processes ^| Measure-Object -Property MemoryMB -Sum^).Sum
echo $bloatwareMemory = ^($bloatware ^| Measure-Object -Property MemoryMB -Sum^).Sum
echo.
echo # Display results
echo ''
echo '============================================================================'
echo ' SYSTEM OVERVIEW'
echo '============================================================================'
echo ''
echo "Total Processes: $^($processes.Count^)"
echo "Total Memory Usage: $^([math]::Round^($totalMemory,0^)^) MB"
echo "Bloatware Memory: $^([math]::Round^($bloatwareMemory,0^)^) MB"
echo ''
echo.
echo if ^($highMemory.Count -gt 0^) {
echo     Write-Host '============================================================================' -ForegroundColor White
echo     Write-Host ' HIGH MEMORY USAGE ^(Over 500MB^)' -ForegroundColor White
echo     Write-Host '============================================================================' -ForegroundColor White
echo     Write-Host ''
echo     foreach ^($proc in $highMemory^) {
echo         $memColor = if ^($proc.MemoryMB -gt 1000^) { 'Red' } else { 'Yellow' }
echo         Write-Host "  $^($proc.Name^)" -ForegroundColor $memColor -NoNewline
echo         Write-Host " - $^($proc.MemoryMB^) MB" -ForegroundColor Gray
echo     }
echo     Write-Host ''
echo }
echo.
echo if ^($bloatware.Count -gt 0^) {
echo     Write-Host '============================================================================' -ForegroundColor Red
echo     Write-Host ' [BLOATWARE] Recommended to Close/Remove' -ForegroundColor Red
echo     Write-Host '============================================================================' -ForegroundColor Red
echo     Write-Host ''
echo     foreach ^($proc in $bloatware^) {
echo         Write-Host "  [X] $^($proc.Name^) ^(PID: $^($proc.Id^)^)" -ForegroundColor Red -NoNewline
echo         Write-Host " - $^($proc.MemoryMB^) MB" -ForegroundColor Gray
echo         Write-Host "      $^($proc.Reason^)" -ForegroundColor DarkYellow
echo     }
echo     Write-Host ''
echo     # Save bloatware PIDs for potential termination
echo     $bloatware ^| ForEach-Object { "$^($_.Id^);$^($_.Name^)" } ^| Out-File -FilePath "$env:TEMP\bloatware_pids.txt" -Encoding ASCII
echo } else {
echo     Write-Host '============================================================================' -ForegroundColor Green
echo     Write-Host ' [BLOATWARE] None Detected!' -ForegroundColor Green
echo     Write-Host '============================================================================' -ForegroundColor Green
echo     Write-Host ''
echo     Write-Host '  Your system is clean of known bloatware processes.' -ForegroundColor Green
echo     Write-Host ''
echo }
echo.
echo if ^($optional.Count -gt 0^) {
echo     Write-Host '============================================================================' -ForegroundColor Yellow
echo     Write-Host ' [OPTIONAL] Background Programs ^(Your Choice^)' -ForegroundColor Yellow
echo     Write-Host '============================================================================' -ForegroundColor Yellow
echo     Write-Host ''
echo     foreach ^($proc in $optional^) {
echo         Write-Host "  [?] $^($proc.Name^)" -ForegroundColor Yellow -NoNewline
echo         Write-Host " - $^($proc.MemoryMB^) MB" -ForegroundColor Gray
echo         Write-Host "      $^($proc.Reason^)" -ForegroundColor DarkGray
echo     }
echo     Write-Host ''
echo }
echo.
echo Write-Host '============================================================================' -ForegroundColor Cyan
echo Write-Host ' [UNKNOWN] Unrecognized Processes ^(Research if concerned^)' -ForegroundColor Cyan
echo Write-Host '============================================================================' -ForegroundColor Cyan
echo Write-Host ''
echo $unknownHigh = $unknown ^| Where-Object { $_.MemoryMB -gt 50 } ^| Select-Object -First 15
echo foreach ^($proc in $unknownHigh^) {
echo     Write-Host "  [?] $^($proc.Name^)" -ForegroundColor Cyan -NoNewline
echo     Write-Host " - $^($proc.MemoryMB^) MB" -ForegroundColor Gray
echo     if ^($proc.Description^) {
echo         Write-Host "      $^($proc.Description^)" -ForegroundColor DarkGray
echo     }
echo }
echo if ^($unknown.Count -gt 15^) {
echo     Write-Host "  ... and $^($unknown.Count - 15^) more small processes" -ForegroundColor DarkGray
echo }
echo Write-Host ''
echo.
echo Write-Host '============================================================================' -ForegroundColor White
echo Write-Host " Summary: $^($essential.Count^) Essential, $^($bloatware.Count^) Bloatware, $^($optional.Count^) Optional, $^($unknown.Count^) Unknown" -ForegroundColor White
echo Write-Host '============================================================================' -ForegroundColor White
) > "%PSSCRIPT%"

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%"

:: Check for bloatware and offer to kill
if exist "%TEMP%\bloatware_pids.txt" (
    set "bloat_count=0"
    for /f %%a in ('type "%TEMP%\bloatware_pids.txt" 2^>nul ^| find /c ";"') do set "bloat_count=%%a"

    if !bloat_count! gtr 0 (
        echo.
        set /p "killbloat=Would you like to terminate bloatware processes? [Y/N]: "
        if /i "!killbloat!"=="Y" (
            echo.
            echo Terminating bloatware processes...
            for /f "tokens=1,2 delims=;" %%a in ('type "%TEMP%\bloatware_pids.txt"') do (
                taskkill /pid %%a /f >nul 2>&1
                if not errorlevel 1 (
                    echo   [KILLED] %%b ^(PID: %%a^)
                ) else (
                    echo   [FAILED] %%b - may need admin rights or is protected
                )
            )
            echo.
            echo Done! Bloatware processes terminated.
            echo NOTE: They may restart. Use StartupAnalyzer.bat to disable them permanently.
        )
    )
    del "%TEMP%\bloatware_pids.txt" 2>nul
)

:: Cleanup
del "%PSSCRIPT%" 2>nul

echo.
echo ============================================================================
echo  Tips
echo ============================================================================
echo.
echo  - Use Task Manager [Ctrl+Shift+Esc] to monitor processes
echo  - Sort by Memory to find resource hogs
echo  - Right-click a process ^> "Search online" to research unknown ones
echo  - Use StartupAnalyzer.bat to prevent bloatware from auto-starting
echo  - Consider uninstalling programs you don't use
echo.

pause
exit /b 0
