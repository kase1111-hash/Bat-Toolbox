@echo off
setlocal enabledelayedexpansion
title Context Menu Cleaner
color 0B

:: ============================================================================
:: Context Menu Cleaner
:: ============================================================================
:: Scans the registry for right-click context menu entries, identifies
:: bloatware and junk entries, and lets you selectively disable them.
:: ============================================================================

echo ============================================================================
echo  Context Menu Cleaner
echo ============================================================================
echo(

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo(
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

:: Create PowerShell script for context menu analysis
set "PSSCRIPT=%TEMP%\context_menu_cleaner.ps1"

(
echo # Context Menu Cleaner
echo # Scans registry for right-click context menu entries
echo(
echo $ErrorActionPreference = 'SilentlyContinue'
echo(
echo # Known bloatware/unnecessary context menu entries
echo $bloatwareEntries = @{
echo     '7-Zip' = 'OPTIONAL'
echo     'WinRAR' = 'OPTIONAL'
echo     'WinZip' = 'BLOATWARE'
echo     'CRC SHA' = 'BLOATWARE'
echo     'AMD Radeon' = 'OPTIONAL'
echo     'Cast to Device' = 'OPTIONAL'
echo     'Edit with Paint 3D' = 'BLOATWARE'
echo     'Edit with Photos' = 'OPTIONAL'
echo     'Give access to' = 'OPTIONAL'
echo     'Restore previous versions' = 'OPTIONAL'
echo     'Share' = 'OPTIONAL'
echo     'Include in library' = 'OPTIONAL'
echo     'Pin to Quick access' = 'OPTIONAL'
echo     'Pin to Start' = 'OPTIONAL'
echo     'Send to' = 'KEEP'
echo     'Open with' = 'KEEP'
echo     'Open in Terminal' = 'KEEP'
echo     'Open PowerShell' = 'KEEP'
echo     'Open command window' = 'KEEP'
echo     'Scan with Microsoft Defender' = 'KEEP'
echo     'Dropbox' = 'OPTIONAL'
echo     'Move to Dropbox' = 'OPTIONAL'
echo     'Move to OneDrive' = 'OPTIONAL'
echo     'Google Drive' = 'OPTIONAL'
echo     'iCloud' = 'OPTIONAL'
echo     'Git Bash Here' = 'OPTIONAL'
echo     'Git GUI Here' = 'OPTIONAL'
echo     'TortoiseGit' = 'OPTIONAL'
echo     'TortoiseSVN' = 'OPTIONAL'
echo     'Open with Notepad++' = 'OPTIONAL'
echo     'Edit with Notepad++' = 'OPTIONAL'
echo     'Open with Visual Studio' = 'OPTIONAL'
echo     'Open with Code' = 'OPTIONAL'
echo     'Open with Sublime' = 'OPTIONAL'
echo     'AMD Software' = 'OPTIONAL'
echo     'NVIDIA Control Panel' = 'OPTIONAL'
echo     'Intel Graphics Settings' = 'OPTIONAL'
echo     'McAfee' = 'BLOATWARE'
echo     'Norton' = 'BLOATWARE'
echo     'Avast' = 'BLOATWARE'
echo     'AVG' = 'BLOATWARE'
echo     'Kaspersky' = 'BLOATWARE'
echo     'CCleaner' = 'BLOATWARE'
echo     'IObit' = 'BLOATWARE'
echo     'Bitdefender' = 'BLOATWARE'
echo }
echo(
echo # Registry locations to scan
echo $contextMenuPaths = @(
echo     'HKCR:\*\shell'
echo     'HKCR:\*\shellex\ContextMenuHandlers'
echo     'HKCR:\Directory\shell'
echo     'HKCR:\Directory\shellex\ContextMenuHandlers'
echo     'HKCR:\Directory\Background\shell'
echo     'HKCR:\Directory\Background\shellex\ContextMenuHandlers'
echo     'HKCR:\Folder\shell'
echo     'HKCR:\Folder\shellex\ContextMenuHandlers'
echo     'HKCR:\Drive\shell'
echo     'HKLM:\SOFTWARE\Classes\Directory\background\shell'
echo     'HKLM:\SOFTWARE\Classes\Directory\shell'
echo     'HKCU:\SOFTWARE\Classes\Directory\background\shell'
echo     'HKCU:\SOFTWARE\Classes\Directory\shell'
echo ^)
echo(
echo # Map HKEY_CLASSES_ROOT
echo if (-not ^(Test-Path 'HKCR:'^)^) {
echo     New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT ^| Out-Null
echo }
echo(
echo Write-Host ""
echo Write-Host "Scanning registry for context menu entries..." -ForegroundColor Cyan
echo Write-Host ""
echo(
echo $allEntries = @^(^)
echo $bloatCount = 0
echo $optionalCount = 0
echo $keepCount = 0
echo $unknownCount = 0
echo(
echo foreach ^($path in $contextMenuPaths^) {
echo     if ^(Test-Path $path^) {
echo         $subkeys = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
echo         foreach ^($key in $subkeys^) {
echo             $name = $key.PSChildName
echo             $displayName = $name
echo(
echo             # Try to get a display name
echo             $muiVerb = ^(Get-ItemProperty -Path $key.PSPath -Name 'MUIVerb' -ErrorAction SilentlyContinue^).MUIVerb
echo             if ^($muiVerb -and $muiVerb -notmatch '^@'^) { $displayName = $muiVerb }
echo(
echo             $defaultVal = ^(Get-ItemProperty -Path $key.PSPath -Name '^(Default^)' -ErrorAction SilentlyContinue^).'^(Default^)'
echo             if ^($defaultVal -and -not $muiVerb^) { $displayName = $defaultVal }
echo(
echo             # Check if entry is hidden/disabled
echo             $legacyDisable = ^(Get-ItemProperty -Path $key.PSPath -Name 'LegacyDisable' -ErrorAction SilentlyContinue^)
echo             $extended = ^(Get-ItemProperty -Path $key.PSPath -Name 'Extended' -ErrorAction SilentlyContinue^)
echo             $programmaticOnly = ^(Get-ItemProperty -Path $key.PSPath -Name 'ProgrammaticAccessOnly' -ErrorAction SilentlyContinue^)
echo(
echo             $status = 'Active'
echo             if ^($legacyDisable -or $programmaticOnly^) { $status = 'Disabled' }
echo             if ^($extended^) { $status = 'Shift+Click only' }
echo(
echo             # Categorize
echo             $category = 'UNKNOWN'
echo             foreach ^($pattern in $bloatwareEntries.Keys^) {
echo                 if ^($displayName -match [regex]::Escape^($pattern^) -or $name -match [regex]::Escape^($pattern^)^) {
echo                     $category = $bloatwareEntries[$pattern]
echo                     break
echo                 }
echo             }
echo(
echo             $entry = [PSCustomObject]@{
echo                 Name = $name
echo                 DisplayName = $displayName
echo                 Path = $key.PSPath -replace 'Microsoft\.PowerShell\.Core\\Registry::', ''
echo                 Status = $status
echo                 Category = $category
echo             }
echo             $allEntries += $entry
echo(
echo             switch ^($category^) {
echo                 'BLOATWARE' { $bloatCount++ }
echo                 'OPTIONAL' { $optionalCount++ }
echo                 'KEEP' { $keepCount++ }
echo                 default { $unknownCount++ }
echo             }
echo         }
echo     }
echo }
echo(
echo # Remove duplicates by name
echo $uniqueEntries = $allEntries ^| Sort-Object Name -Unique
echo(
echo # Display results
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host " SCAN RESULTS" -ForegroundColor Cyan
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host ""
echo(
echo # Show bloatware first
echo $bloat = $uniqueEntries ^| Where-Object { $_.Category -eq 'BLOATWARE' -and $_.Status -eq 'Active' }
echo if ^($bloat^) {
echo     Write-Host "[BLOATWARE] - Recommended for removal:" -ForegroundColor Red
echo     foreach ^($e in $bloat^) {
echo         Write-Host "  [-] $^($e.DisplayName^)" -ForegroundColor Red
echo         Write-Host "      $^($e.Path^)" -ForegroundColor DarkGray
echo     }
echo     Write-Host ""
echo }
echo(
echo # Show optional
echo $optional = $uniqueEntries ^| Where-Object { $_.Category -eq 'OPTIONAL' -and $_.Status -eq 'Active' }
echo if ^($optional^) {
echo     Write-Host "[OPTIONAL] - Can be removed if unwanted:" -ForegroundColor Yellow
echo     foreach ^($e in $optional^) {
echo         Write-Host "  [?] $^($e.DisplayName^)" -ForegroundColor Yellow
echo         Write-Host "      $^($e.Path^)" -ForegroundColor DarkGray
echo     }
echo     Write-Host ""
echo }
echo(
echo # Show essential
echo $keep = $uniqueEntries ^| Where-Object { $_.Category -eq 'KEEP' -and $_.Status -eq 'Active' }
echo if ^($keep^) {
echo     Write-Host "[KEEP] - Essential entries (will not be touched):" -ForegroundColor Green
echo     foreach ^($e in $keep^) {
echo         Write-Host "  [+] $^($e.DisplayName^)" -ForegroundColor Green
echo     }
echo     Write-Host ""
echo }
echo(
echo # Show already disabled
echo $disabled = $uniqueEntries ^| Where-Object { $_.Status -eq 'Disabled' }
echo if ^($disabled^) {
echo     Write-Host "[DISABLED] - Already hidden:" -ForegroundColor DarkGray
echo     foreach ^($e in $disabled^) {
echo         Write-Host "  [x] $^($e.DisplayName^)" -ForegroundColor DarkGray
echo     }
echo     Write-Host ""
echo }
echo(
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host " SUMMARY" -ForegroundColor Cyan
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host ""
echo Write-Host "  Total entries found: $^($uniqueEntries.Count^)"
echo $activeBloat = @^($bloat^).Count
echo $activeOptional = @^($optional^).Count
echo if ^($activeBloat -gt 0^) { Write-Host "  Bloatware:  $activeBloat entries" -ForegroundColor Red }
echo if ^($activeOptional -gt 0^) { Write-Host "  Optional:   $activeOptional entries" -ForegroundColor Yellow }
echo Write-Host "  Essential:  $^(@^($keep^).Count^) entries" -ForegroundColor Green
echo Write-Host ""
echo(
echo # Offer to disable bloatware entries
echo if ^($activeBloat -gt 0^) {
echo     Write-Host ""
echo     $answer = Read-Host "Disable all BLOATWARE context menu entries? [Y/N]"
echo     if ^($answer -eq 'Y'^) {
echo         foreach ^($e in $bloat^) {
echo             try {
echo                 $regPath = "Registry::$^($e.Path^)"
echo                 New-ItemProperty -Path $regPath -Name 'LegacyDisable' -Value '' -PropertyType String -Force ^| Out-Null
echo                 Write-Host "  [OK] Disabled: $^($e.DisplayName^)" -ForegroundColor Green
echo             } catch {
echo                 Write-Host "  [FAIL] Could not disable: $^($e.DisplayName^) - $^($_.Exception.Message^)" -ForegroundColor Red
echo             }
echo         }
echo         Write-Host ""
echo     }
echo }
echo(
echo # Offer to disable optional entries one by one
echo if ^($activeOptional -gt 0^) {
echo     Write-Host ""
echo     $answer = Read-Host "Review OPTIONAL entries one by one? [Y/N]"
echo     if ^($answer -eq 'Y'^) {
echo         Write-Host ""
echo         foreach ^($e in $optional^) {
echo             $choice = Read-Host "Disable '$^($e.DisplayName^)'? [Y/N/Q to quit]"
echo             if ^($choice -eq 'Q'^) { break }
echo             if ^($choice -eq 'Y'^) {
echo                 try {
echo                     $regPath = "Registry::$^($e.Path^)"
echo                     New-ItemProperty -Path $regPath -Name 'LegacyDisable' -Value '' -PropertyType String -Force ^| Out-Null
echo                     Write-Host "  [OK] Disabled: $^($e.DisplayName^)" -ForegroundColor Green
echo                 } catch {
echo                     Write-Host "  [FAIL] Could not disable: $^($e.DisplayName^) - $^($_.Exception.Message^)" -ForegroundColor Red
echo                 }
echo             }
echo         }
echo         Write-Host ""
echo     }
echo }
echo(
echo # Common Windows 11 context menu fix
echo $osVersion = [System.Environment]::OSVersion.Version
echo if ^($osVersion.Build -ge 22000^) {
echo     Write-Host ""
echo     Write-Host "============================================================================" -ForegroundColor White
echo     Write-Host " WINDOWS 11 OPTION" -ForegroundColor Cyan
echo     Write-Host "============================================================================" -ForegroundColor White
echo     Write-Host ""
echo     Write-Host "Windows 11 uses a simplified context menu by default." -ForegroundColor Yellow
echo     Write-Host "You must click 'Show more options' to see the full menu." -ForegroundColor Yellow
echo     Write-Host ""
echo     $w11answer = Read-Host "Restore the full classic context menu? [Y/N]"
echo     if ^($w11answer -eq 'Y'^) {
echo         try {
echo             $regPath = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
echo             New-Item -Path $regPath -Force ^| Out-Null
echo             Set-ItemProperty -Path $regPath -Name '^(Default^)' -Value '' -Force
echo             Write-Host ""
echo             Write-Host "  [OK] Classic context menu restored." -ForegroundColor Green
echo             Write-Host "       Restart Explorer or reboot to apply." -ForegroundColor Yellow
echo         } catch {
echo             Write-Host "  [FAIL] Could not restore classic menu: $^($_.Exception.Message^)" -ForegroundColor Red
echo         }
echo     }
echo }
echo(
echo Write-Host ""
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host " Context Menu Cleaner Complete" -ForegroundColor Cyan
echo Write-Host "============================================================================" -ForegroundColor White
echo Write-Host ""
echo Write-Host "Changes take effect immediately for new context menus."
echo Write-Host "Some changes may require restarting Explorer or rebooting."
echo Write-Host ""
) > "%PSSCRIPT%"

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%"

:: Cleanup
del "%PSSCRIPT%" 2>nul

echo(
pause
