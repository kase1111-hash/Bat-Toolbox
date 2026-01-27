@echo off
setlocal enabledelayedexpansion
title Startup Program Analyzer
color 0B

:: ============================================================================
:: Startup Program Analyzer
:: ============================================================================
:: Scans startup programs and categorizes them as:
::   - KEEP: Essential programs that should not be disabled
::   - OPTIONAL: Safe to disable, explains what each does
::   - REMOVE: Known bloatware/unnecessary programs
:: ============================================================================

echo ============================================================================
echo  Startup Program Analyzer
echo ============================================================================
echo.
echo Scanning startup programs...
echo.

:: Create temp files for categorization
set "TEMP_ALL=%TEMP%\startup_all.txt"
set "TEMP_KEEP=%TEMP%\startup_keep.txt"
set "TEMP_OPTIONAL=%TEMP%\startup_optional.txt"
set "TEMP_REMOVE=%TEMP%\startup_remove.txt"

:: Clean up any leftover temp files from interrupted runs
del "%TEMP%\categorize_startup.ps1" 2>nul
del "%TEMP_ALL%" 2>nul
del "%TEMP_KEEP%" 2>nul
del "%TEMP_OPTIONAL%" 2>nul
del "%TEMP_REMOVE%" 2>nul

:: Clear temp files
echo. > "%TEMP_ALL%"
echo. > "%TEMP_KEEP%"
echo. > "%TEMP_OPTIONAL%"
echo. > "%TEMP_REMOVE%"

:: ============================================================================
:: Define program categories
:: ============================================================================

:: KEEP - Essential programs (security, drivers, core functionality)
set "KEEP_PATTERNS=SecurityHealth;Windows Defender;Windows Security;Realtek;NVIDIA Display;AMD External;Intel Graphics;Synaptics;ELAN;Bluetooth;SynTPEnh"

:: REMOVE - Known bloatware and unnecessary programs
set "REMOVE_PATTERNS=iTunes Helper;iTunesHelper;QuickTime;Adobe ARM;Acrobat Assistant;AcroTray;Java Update;jusched;CCleaner;Avast;AVG;McAfee;Norton;Spotify;Discord;Steam Client;EpicGames;Origin;Uplay;OneDrive;Dropbox;Google Update;Microsoft Edge Update;Opera;Brave Update;CCleanerBrowser;Yahoo;Bing Bar;Ask;Conduit;Babylon;MyWebSearch;Coupon;Shopping;GameBar;Xbox;Cortana;Teams;Skype;Zoom;Slack;WhatsApp;Telegram;Facebook;Instagram;TikTok;Amazon;eBay;Booking;Candy;Dolby;WinZip;WinRAR Trial;ExpressVPN;NordVPN;CyberGhost;Adobe Creative Cloud;Creative Cloud;AdobeGC;AGC;Updater;Update Service;Update Helper;Browser Assistant;Search Protect;Driver Booster;Driver Easy;IObit;Auslogics;Glary;Wise;Advanced SystemCare;System Mechanic"

:: ============================================================================
:: Scan startup locations
:: ============================================================================

echo [1/4] Scanning HKCU Run registry...
for /f "tokens=1,2,*" %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /i "REG_SZ REG_EXPAND_SZ"') do (
    set "name=%%a"
    set "value=%%c"
    echo HKCU_Run;!name!;!value! >> "%TEMP_ALL%"
)

echo [2/4] Scanning HKLM Run registry...
for /f "tokens=1,2,*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /i "REG_SZ REG_EXPAND_SZ"') do (
    set "name=%%a"
    set "value=%%c"
    echo HKLM_Run;!name!;!value! >> "%TEMP_ALL%"
)

echo [3/4] Scanning HKLM Run (32-bit)...
for /f "tokens=1,2,*" %%a in ('reg query "HKLM\SOFTWARE\WoW6432Node\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /i "REG_SZ REG_EXPAND_SZ"') do (
    set "name=%%a"
    set "value=%%c"
    echo HKLM_Run32;!name!;!value! >> "%TEMP_ALL%"
)

echo [4/4] Scanning Startup folders...
for %%F in ("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*.lnk" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*.exe") do (
    echo Startup_Folder;%%~nxF;%%F >> "%TEMP_ALL%"
)
for %%F in ("%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\*.lnk" "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\*.exe") do (
    echo Startup_Folder_All;%%~nxF;%%F >> "%TEMP_ALL%"
)

:: ============================================================================
:: Categorize programs using PowerShell for better pattern matching
:: ============================================================================

echo.
echo Categorizing programs...

:: Create PowerShell script for categorization
set "PSSCRIPT=%TEMP%\categorize_startup.ps1"

(
echo $keepPatterns = @(
echo     'SecurityHealth', 'Windows Defender', 'Windows Security', 'MsMpEng',
echo     'Realtek', 'RtkNGUI', 'RtkAudioService', 'RTHDVCpl',
echo     'NVIDIA', 'NvBackend', 'NvTmMon',
echo     'AMD External Events', 'RadeonSettings', 'StartCN',
echo     'Intel', 'igfx', 'hkcmd', 'persistence',
echo     'Synaptics', 'SynTPEnh', 'TouchPad',
echo     'ELAN', 'ETDCtrl',
echo     'Bluetooth', 'BTTray',
echo     'WavesSvc', 'Waves MaxxAudio',
echo     'ctfmon', 'SecurityHealth',
echo     'WindowsDefender', 'Logitech'
echo ^)
echo.
echo $removePatterns = @(
echo     # Bloatware and trials
echo     'iTunesHelper', 'QuickTime', 'Adobe ARM', 'AcroTray', 'Acrobat Assistant',
echo     'Java Update', 'jusched', 'CCleaner', 'Avast', 'AVG',
echo     'McAfee', 'Norton', 'Kaspersky', 'Bitdefender', 'Webroot',
echo     # Social/Communication ^(optional to autostart^)
echo     'Spotify', 'Discord', 'Steam', 'EpicGames', 'Origin', 'Uplay', 'GOG',
echo     'Zoom', 'Teams Installer', 'Slack', 'WhatsApp', 'Telegram', 'Skype',
echo     # Cloud sync ^(often unnecessary at startup^)
echo     'OneDrive', 'Dropbox', 'Google Drive', 'iCloud', 'Box',
echo     # Updaters
echo     'Google Update', 'Chrome Update', 'Edge Update', 'Opera Update', 'Brave Update',
echo     'Adobe Updater', 'AdobeGC', 'Creative Cloud', 'CCLibrary', 'CCXProcess',
echo     'Spotify Web Helper',
echo     # PUPs and bloatware
echo     'Yahoo', 'Bing Bar', 'Ask Toolbar', 'Conduit', 'Babylon', 'MyWebSearch',
echo     'Coupon', 'Shopping', 'Browser Assistant', 'Search Protect', 'Web Companion',
echo     'Driver Booster', 'Driver Easy', 'DriverMax', 'SlimDrivers',
echo     'IObit', 'Auslogics', 'Glary', 'Wise', 'Advanced SystemCare', 'System Mechanic',
echo     'WinZip', 'WinRAR Trial', 'PowerISO',
echo     'ExpressVPN', 'NordVPN', 'CyberGhost', 'HMA', 'Hotspot Shield',
echo     'uTorrent', 'BitTorrent', 'qBittorrent',
echo     'CyberLink', 'Corel', 'Roxio',
echo     'HP ', 'Dell ', 'Lenovo ', 'Acer ', 'ASUS GiftBox', 'MyASUS',
echo     'Energy Manager', 'Power Manager', 'Battery', 'Dolby',
echo     'Candy', 'Game', 'Netflix', 'Amazon', 'eBay', 'Booking',
echo     'Facebook', 'Instagram', 'TikTok', 'Twitter',
echo     'Weather', 'News',
echo     # Known bad actors
echo     'Segurazo', 'ByteFence', 'SpyHunter', 'Reimage', 'PC Accelerate',
echo     'MyPC Backup', 'RegClean', 'WinTonic', 'OneSafe', 'TotalAV'
echo ^)
echo.
echo $optionalPatterns = @(
echo     # These are legitimate but not essential at startup
echo     'Microsoft Office', 'Office Click-to-Run', 'OfficeBackgroundTask',
echo     'Printer', 'Scanner', 'Epson', 'Canon', 'Brother', 'HP Smart',
echo     'Razer', 'Corsair', 'SteelSeries', 'Logitech G', 'ROCCAT', 'HyperX',
echo     'ASUS', 'MSI', 'Gigabyte', 'ASRock',
echo     'VMware', 'VirtualBox', 'Parallels',
echo     'PDF', 'Foxit', 'SumatraPDF', 'Nitro',
echo     'PowerToys', 'AutoHotkey', 'Everything',
echo     'f.lux', 'Flux', 'Night Light',
echo     'ShareX', 'Greenshot', 'LightShot',
echo     'Clipboard', 'Ditto', 'ClipX',
echo     '1Password', 'LastPass', 'Bitwarden', 'KeePass', 'Dashlane',
echo     'NordLocker', 'Cryptomator', 'VeraCrypt',
echo     'AnyDesk', 'TeamViewer', 'Remote Desktop',
echo     'Synergy', 'Mouse without Borders', 'Barrier',
echo     'DisplayFusion', 'UltraMon', 'Actual Multiple Monitors'
echo ^)
echo.
echo $optionalDescriptions = @{
echo     'Office' = 'Microsoft Office background tasks - can slow boot'
echo     'Printer' = 'Printer software - only needed when printing'
echo     'Epson' = 'Epson printer software - only needed when printing'
echo     'Canon' = 'Canon printer software - only needed when printing'
echo     'Brother' = 'Brother printer software - only needed when printing'
echo     'Razer' = 'Razer Synapse - RGB and macro software'
echo     'Corsair' = 'Corsair iCUE - RGB and peripheral software'
echo     'SteelSeries' = 'SteelSeries GG - Gaming peripheral software'
echo     'Logitech G' = 'Logitech G Hub - Gaming peripheral software'
echo     'VMware' = 'VMware Tools - Only needed in VMs'
echo     'VirtualBox' = 'VirtualBox services - Only needed for VMs'
echo     'f.lux' = 'Screen color temperature - Windows has Night Light built-in'
echo     'ShareX' = 'Screenshot tool - can start manually when needed'
echo     'Clipboard' = 'Clipboard manager - Windows 10+ has built-in history ^(Win+V^)'
echo     'Password' = 'Password manager - can be launched manually or via browser'
echo     'TeamViewer' = 'Remote access - security risk if not needed'
echo     'AnyDesk' = 'Remote access - security risk if not needed'
echo     'Adobe' = 'Adobe background services - resource heavy'
echo     'Creative Cloud' = 'Adobe CC - uses significant resources'
echo }
echo.
echo $removeDescriptions = @{
echo     'iTunes' = 'iTunes Helper - slows boot, launches with iTunes anyway'
echo     'QuickTime' = 'QuickTime - outdated, security vulnerabilities'
echo     'Java' = 'Java Updater - can update manually, often exploited'
echo     'Adobe ARM' = 'Adobe Reader updater - can update manually'
echo     'CCleaner' = 'CCleaner monitoring - unnecessary background task'
echo     'Steam' = 'Steam Client - can launch manually when gaming'
echo     'Discord' = 'Discord - can launch manually, uses resources'
echo     'Spotify' = 'Spotify - can launch manually when needed'
echo     'OneDrive' = 'OneDrive sync - can be disabled if not using cloud sync'
echo     'Dropbox' = 'Dropbox sync - can be disabled if not using cloud sync'
echo     'Google Update' = 'Google Updater - browsers update themselves'
echo     'Teams' = 'Microsoft Teams - resource heavy, launch manually'
echo     'Zoom' = 'Zoom - launch manually for meetings'
echo     'Skype' = 'Skype - largely replaced by Teams, launch manually'
echo     'McAfee' = 'McAfee Antivirus - Windows Defender is sufficient'
echo     'Norton' = 'Norton Antivirus - Windows Defender is sufficient'
echo     'Avast' = 'Avast Antivirus - Windows Defender is sufficient'
echo     'AVG' = 'AVG Antivirus - Windows Defender is sufficient'
echo     'Driver Booster' = 'Driver Booster - often installs unwanted software'
echo     'IObit' = 'IObit software - often bundles PUPs'
echo     'Auslogics' = 'Auslogics - unnecessary optimization software'
echo     'ExpressVPN' = 'VPN software - launch manually when needed'
echo     'NordVPN' = 'VPN software - launch manually when needed'
echo     'uTorrent' = 'Torrent client - contains ads, launch manually'
echo     'WinZip' = 'WinZip - use free 7-Zip instead'
echo     'Segurazo' = 'MALWARE - Remove immediately!'
echo     'ByteFence' = 'PUP/Malware - Remove immediately!'
echo     'Reimage' = 'Scareware - Remove immediately!'
echo     'PC Accelerate' = 'Scareware - Remove immediately!'
echo     'RegClean' = 'Scareware - registry cleaners are unnecessary'
echo }
echo.
echo # Read all startup items
echo $items = Get-Content '%TEMP_ALL%' ^| Where-Object { $_ -match ';' }
echo.
echo $keepList = @^(^)
echo $optionalList = @^(^)
echo $removeList = @^(^)
echo $unknownList = @^(^)
echo.
echo foreach ^($item in $items^) {
echo     $parts = $item -split ';', 3
echo     if ^($parts.Count -lt 2^) { continue }
echo     $location = $parts[0]
echo     $name = $parts[1]
echo     $path = if ^($parts.Count -gt 2^) { $parts[2] } else { '' }
echo.
echo     $categorized = $false
echo.
echo     # Check KEEP patterns
echo     foreach ^($pattern in $keepPatterns^) {
echo         if ^($name -match [regex]::Escape^($pattern^) -or $path -match [regex]::Escape^($pattern^)^) {
echo             $keepList += [PSCustomObject]@{Location=$location; Name=$name; Path=$path; Reason='Essential system/driver component'}
echo             $categorized = $true
echo             break
echo         }
echo     }
echo     if ^($categorized^) { continue }
echo.
echo     # Check REMOVE patterns
echo     foreach ^($pattern in $removePatterns^) {
echo         if ^($name -match [regex]::Escape^($pattern^) -or $path -match [regex]::Escape^($pattern^)^) {
echo             $reason = 'Bloatware/Unnecessary'
echo             foreach ^($key in $removeDescriptions.Keys^) {
echo                 if ^($name -match $key -or $path -match $key^) {
echo                     $reason = $removeDescriptions[$key]
echo                     break
echo                 }
echo             }
echo             $removeList += [PSCustomObject]@{Location=$location; Name=$name; Path=$path; Reason=$reason}
echo             $categorized = $true
echo             break
echo         }
echo     }
echo     if ^($categorized^) { continue }
echo.
echo     # Check OPTIONAL patterns
echo     foreach ^($pattern in $optionalPatterns^) {
echo         if ^($name -match [regex]::Escape^($pattern^) -or $path -match [regex]::Escape^($pattern^)^) {
echo             $reason = 'Optional - can be disabled safely'
echo             foreach ^($key in $optionalDescriptions.Keys^) {
echo                 if ^($name -match $key -or $path -match $key^) {
echo                     $reason = $optionalDescriptions[$key]
echo                     break
echo                 }
echo             }
echo             $optionalList += [PSCustomObject]@{Location=$location; Name=$name; Path=$path; Reason=$reason}
echo             $categorized = $true
echo             break
echo         }
echo     }
echo     if ^($categorized^) { continue }
echo.
echo     # Unknown - add to optional with generic message
echo     $unknownList += [PSCustomObject]@{Location=$location; Name=$name; Path=$path; Reason='Unknown - research before disabling'}
echo }
echo.
echo # Output results
echo ''
echo '============================================================================'
echo ' [KEEP] Essential Programs - Do Not Disable'
echo '============================================================================'
echo ''
echo if ^($keepList.Count -eq 0^) {
echo     Write-Host '  No essential startup programs found.' -ForegroundColor Gray
echo } else {
echo     foreach ^($item in $keepList^) {
echo         Write-Host "  [OK] $^($item.Name^)" -ForegroundColor Green
echo         Write-Host "       $^($item.Reason^)" -ForegroundColor DarkGray
echo     }
echo }
echo.
echo ''
echo '============================================================================'
echo ' [OPTIONAL] Safe to Disable - Your Choice'
echo '============================================================================'
echo ''
echo if ^($optionalList.Count -eq 0^) {
echo     Write-Host '  No optional startup programs found.' -ForegroundColor Gray
echo } else {
echo     $i = 1
echo     foreach ^($item in $optionalList^) {
echo         Write-Host "  [$i] $^($item.Name^)" -ForegroundColor Yellow
echo         Write-Host "      $^($item.Reason^)" -ForegroundColor DarkGray
echo         $i++
echo     }
echo }
echo.
echo ''
echo '============================================================================'
echo ' [UNKNOWN] Not Recognized - Research Before Disabling'
echo '============================================================================'
echo ''
echo if ^($unknownList.Count -eq 0^) {
echo     Write-Host '  No unknown startup programs found.' -ForegroundColor Gray
echo } else {
echo     foreach ^($item in $unknownList^) {
echo         Write-Host "  [?] $^($item.Name^)" -ForegroundColor Cyan
echo         Write-Host "      Path: $^($item.Path^)" -ForegroundColor DarkGray
echo     }
echo }
echo.
echo ''
echo '============================================================================'
echo ' [REMOVE] Recommended for Removal - Bloatware/Unnecessary'
echo '============================================================================'
echo ''
echo if ^($removeList.Count -eq 0^) {
echo     Write-Host '  No bloatware found! Your startup is clean.' -ForegroundColor Green
echo } else {
echo     $i = 1
echo     foreach ^($item in $removeList^) {
echo         Write-Host "  [$i] $^($item.Name^)" -ForegroundColor Red
echo         Write-Host "      $^($item.Reason^)" -ForegroundColor DarkYellow
echo         $i++
echo     }
echo }
echo.
echo # Save remove list for batch file
echo $removeList ^| ForEach-Object { "$^($_.Location^);$^($_.Name^);$^($_.Path^)" } ^| Out-File -FilePath '%TEMP_REMOVE%' -Encoding ASCII
echo $optionalList ^| ForEach-Object { "$^($_.Location^);$^($_.Name^);$^($_.Path^)" } ^| Out-File -FilePath '%TEMP_OPTIONAL%' -Encoding ASCII
echo.
echo # Output counts
echo ''
echo '============================================================================'
echo " Summary: $^($keepList.Count^) Keep, $^($optionalList.Count^) Optional, $^($unknownList.Count^) Unknown, $^($removeList.Count^) Remove"
echo '============================================================================'
) > "%PSSCRIPT%"

:: Run PowerShell categorization
powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%"

:: Check if there are items to remove
set "remove_count=0"
for /f %%a in ('type "%TEMP_REMOVE%" 2^>nul ^| find /c ";"') do set "remove_count=%%a"

echo.

if %remove_count% gtr 0 (
    echo.
    set /p "doremove=Would you like to disable the [REMOVE] items? [Y/N]: "
    if /i "!doremove!"=="Y" (
        echo.
        echo Disabling bloatware startup entries...
        echo.

        for /f "tokens=1,2,3 delims=;" %%a in ('type "%TEMP_REMOVE%" 2^>nul') do (
            set "loc=%%a"
            set "itemname=%%b"

            if "!loc!"=="HKCU_Run" (
                reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "!itemname!" /f >nul 2>&1
                if not errorlevel 1 (
                    echo   [REMOVED] !itemname!
                ) else (
                    echo   [FAILED] !itemname!
                )
            )
            if "!loc!"=="HKLM_Run" (
                reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "!itemname!" /f >nul 2>&1
                if not errorlevel 1 (
                    echo   [REMOVED] !itemname!
                ) else (
                    echo   [FAILED] !itemname! - may need admin rights
                )
            )
            if "!loc!"=="HKLM_Run32" (
                reg delete "HKLM\SOFTWARE\WoW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "!itemname!" /f >nul 2>&1
                if not errorlevel 1 (
                    echo   [REMOVED] !itemname!
                ) else (
                    echo   [FAILED] !itemname! - may need admin rights
                )
            )
            if "!loc!"=="Startup_Folder" (
                del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\!itemname!" >nul 2>&1
                echo   [REMOVED] !itemname!
            )
            if "!loc!"=="Startup_Folder_All" (
                del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\!itemname!" >nul 2>&1
                echo   [REMOVED] !itemname!
            )
        )
        echo.
        echo Bloatware startup entries have been disabled.
    )
)

:: Ask about optional items
set "optional_count=0"
for /f %%a in ('type "%TEMP_OPTIONAL%" 2^>nul ^| find /c ";"') do set "optional_count=%%a"

if %optional_count% gtr 0 (
    echo.
    set /p "dooptional=Would you like to review [OPTIONAL] items for removal? [Y/N]: "
    if /i "!dooptional!"=="Y" (
        echo.
        echo Opening Task Manager for manual review...
        echo Use the Startup tab to disable optional items.
        echo.
        start taskmgr /0 /startup
    )
)

:: Cleanup
del "%PSSCRIPT%" 2>nul
del "%TEMP_ALL%" 2>nul
del "%TEMP_KEEP%" 2>nul
del "%TEMP_OPTIONAL%" 2>nul
del "%TEMP_REMOVE%" 2>nul

echo.
echo ============================================================================
echo  Complete!
echo ============================================================================
echo.
echo Tips:
echo  - Use Task Manager [Ctrl+Shift+Esc] ^> Startup tab for manual control
echo  - Disabled programs can be re-enabled in Task Manager
echo  - Some changes may require a restart to take effect
echo.

pause
exit /b 0
