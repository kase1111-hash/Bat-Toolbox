@echo off
setlocal enabledelayedexpansion
title Installed Programs Exporter
color 0B

:: ============================================================================
:: Installed Programs Exporter
:: ============================================================================
:: Scans and exports a list of all installed programs to help with recovery
:: after a clean Windows install. Uses multiple detection methods.
:: ============================================================================

echo ============================================================================
echo  Installed Programs Exporter
echo ============================================================================
echo.
echo This script will scan your system and create a list of installed programs.
echo Useful for documenting what to reinstall after a clean Windows install.
echo.
echo The following will be exported:
echo  - Desktop applications (from Registry)
echo  - Microsoft Store apps (AppX packages)
echo  - Windows optional features
echo  - Installed drivers (optional)
echo.

:: Set output directory and filename
set "EXPORT_DIR=%USERPROFILE%\Desktop"
set "TIMESTAMP=%DATE:~-4%-%DATE:~4,2%-%DATE:~7,2%_%TIME:~0,2%-%TIME:~3,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"
set "EXPORT_FILE=%EXPORT_DIR%\InstalledPrograms_%COMPUTERNAME%_%TIMESTAMP%.txt"

echo Output will be saved to:
echo  %EXPORT_FILE%
echo.
echo Press any key to start scanning...
pause >nul

echo.
echo ============================================================================
echo  Scanning System...
echo ============================================================================
echo.

:: Create/clear output file
echo ============================================================================ > "%EXPORT_FILE%"
echo  INSTALLED PROGRAMS REPORT >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"
echo Computer Name: %COMPUTERNAME% >> "%EXPORT_FILE%"
echo Username: %USERNAME% >> "%EXPORT_FILE%"
echo Export Date: %DATE% %TIME% >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

:: Get Windows version
for /f "tokens=4-5 delims=[.] " %%i in ('ver') do set "WINVER=%%i.%%j"
echo Windows Version: %WINVER% >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

:: ============================================================================
:: Section 1: Desktop Applications (Registry - 64-bit)
:: ============================================================================
echo [1/6] Scanning desktop applications (64-bit registry)...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  DESKTOP APPLICATIONS (64-bit) >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

set "count=0"
for /f "tokens=*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2^>nul ^| findstr /i "DisplayName"') do (
    set "line=%%a"
    set "line=!line:*DisplayName    REG_SZ    =!"
    if not "!line!"=="" (
        echo !line! >> "%EXPORT_FILE%"
        set /a count+=1
    )
)
echo   Found %count% programs

:: ============================================================================
:: Section 2: Desktop Applications (Registry - 32-bit on 64-bit Windows)
:: ============================================================================
echo [2/6] Scanning desktop applications (32-bit registry)...

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  DESKTOP APPLICATIONS (32-bit / WoW64) >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

set "count=0"
for /f "tokens=*" %%a in ('reg query "HKLM\SOFTWARE\WoW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2^>nul ^| findstr /i "DisplayName"') do (
    set "line=%%a"
    set "line=!line:*DisplayName    REG_SZ    =!"
    if not "!line!"=="" (
        echo !line! >> "%EXPORT_FILE%"
        set /a count+=1
    )
)
echo   Found %count% programs

:: ============================================================================
:: Section 3: User-Installed Applications
:: ============================================================================
echo [3/6] Scanning user-installed applications...

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  USER-INSTALLED APPLICATIONS >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

set "count=0"
for /f "tokens=*" %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2^>nul ^| findstr /i "DisplayName"') do (
    set "line=%%a"
    set "line=!line:*DisplayName    REG_SZ    =!"
    if not "!line!"=="" (
        echo !line! >> "%EXPORT_FILE%"
        set /a count+=1
    )
)
echo   Found %count% programs

:: ============================================================================
:: Section 4: Microsoft Store Apps (PowerShell)
:: ============================================================================
echo [4/6] Scanning Microsoft Store apps...

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  MICROSOFT STORE APPS >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

set "PSSCRIPT=%TEMP%\get-appx.ps1"
(
echo $apps = Get-AppxPackage ^| Where-Object { $_.IsFramework -eq $false } ^| Sort-Object Name
echo foreach ^($app in $apps^) {
echo     $name = $app.Name
echo     if ^($name -notmatch '^Microsoft\.(NET|VCLibs|UI|Services|Windows)'  -and $name -notmatch '^\d+\.'  -and $name -notmatch '^Windows'  -and $name -notmatch '^InputApp' ^) {
echo         Write-Output "$name"
echo     }
echo }
) > "%PSSCRIPT%"

set "count=0"
for /f "tokens=*" %%a in ('powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%" 2^>nul') do (
    echo %%a >> "%EXPORT_FILE%"
    set /a count+=1
)
del "%PSSCRIPT%" 2>nul
echo   Found %count% apps

:: ============================================================================
:: Section 5: Windows Optional Features
:: ============================================================================
echo [5/6] Scanning Windows optional features...

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  WINDOWS OPTIONAL FEATURES (Enabled) >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

set "count=0"
for /f "tokens=*" %%a in ('dism /online /get-features /format:table 2^>nul ^| findstr /i "Enabled"') do (
    set "line=%%a"
    set "line=!line: | Enabled=!"
    echo !line! >> "%EXPORT_FILE%"
    set /a count+=1
)
echo   Found %count% features

:: ============================================================================
:: Section 6: Detailed Program List with Versions (WMIC)
:: ============================================================================
echo [6/6] Creating detailed program list with versions...

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  DETAILED PROGRAM LIST (Name, Version, Publisher) >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"
echo %-60s %-20s %-30s >> "%EXPORT_FILE%"

:: Use PowerShell for better formatting
set "PSSCRIPT2=%TEMP%\get-programs.ps1"
(
echo $programs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
echo                              HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
echo                              HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* 2^>$null ^|
echo     Where-Object { $_.DisplayName -ne $null } ^|
echo     Select-Object DisplayName, DisplayVersion, Publisher ^|
echo     Sort-Object DisplayName -Unique
echo.
echo foreach ^($prog in $programs^) {
echo     $name = if ^($prog.DisplayName.Length -gt 55^) { $prog.DisplayName.Substring^(0,55^) + "..." } else { $prog.DisplayName }
echo     $version = if ^($prog.DisplayVersion^) { $prog.DisplayVersion } else { "N/A" }
echo     $publisher = if ^($prog.Publisher^) { $prog.Publisher } else { "Unknown" }
echo     if ^($version.Length -gt 18^) { $version = $version.Substring^(0,18^) }
echo     if ^($publisher.Length -gt 28^) { $publisher = $publisher.Substring^(0,28^) }
echo     Write-Output ^("$name | $version | $publisher"^)
echo }
) > "%PSSCRIPT2%"

echo NAME                                                         ^| VERSION              ^| PUBLISHER >> "%EXPORT_FILE%"
echo ------------------------------------------------------------ ^| -------------------- ^| ------------------------------ >> "%EXPORT_FILE%"

for /f "tokens=*" %%a in ('powershell -ExecutionPolicy Bypass -File "%PSSCRIPT2%" 2^>nul') do (
    echo %%a >> "%EXPORT_FILE%"
)
del "%PSSCRIPT2%" 2>nul

:: ============================================================================
:: Section 7: Browser Extensions Reminder
:: ============================================================================

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  MANUAL CHECKLIST - Don't Forget! >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"
echo [ ] Browser extensions ^(Chrome: chrome://extensions, Firefox: about:addons^) >> "%EXPORT_FILE%"
echo [ ] Browser bookmarks ^(export to HTML^) >> "%EXPORT_FILE%"
echo [ ] Saved passwords ^(use a password manager^) >> "%EXPORT_FILE%"
echo [ ] License keys ^(check emails, use tools like ProduKey^) >> "%EXPORT_FILE%"
echo [ ] Game saves ^(Documents, AppData, or cloud saves^) >> "%EXPORT_FILE%"
echo [ ] Application settings ^(AppData\Local, AppData\Roaming^) >> "%EXPORT_FILE%"
echo [ ] Fonts ^(C:\Windows\Fonts - custom installed fonts^) >> "%EXPORT_FILE%"
echo [ ] Drivers ^(especially GPU, audio, network^) >> "%EXPORT_FILE%"
echo [ ] VPN configurations >> "%EXPORT_FILE%"
echo [ ] SSH keys ^(%USERPROFILE%\.ssh^) >> "%EXPORT_FILE%"
echo [ ] Development environments ^(Python packages, npm global, etc.^) >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

:: ============================================================================
:: Summary
:: ============================================================================

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  END OF REPORT >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"

echo.
echo ============================================================================
echo  Export Complete!
echo ============================================================================
echo.
echo File saved to:
echo  %EXPORT_FILE%
echo.

:: Count total lines (approximate program count)
set "totallines=0"
for /f %%a in ('type "%EXPORT_FILE%" ^| find /c /v ""') do set "totallines=%%a"
echo Report contains approximately %totallines% lines.
echo.

:: Ask if user wants to open the file
set /p "openfile=Would you like to open the file now? (Y/N): "
if /i "%openfile%"=="Y" (
    notepad "%EXPORT_FILE%"
)

echo.
echo ============================================================================
echo  Tips for Clean Install Recovery
echo ============================================================================
echo.
echo 1. Save this file to a USB drive or cloud storage
echo 2. Use Ninite.com for quick reinstallation of common programs
echo 3. Consider using Chocolatey or Winget for automated installs
echo 4. Export browser bookmarks and extension lists separately
echo 5. Back up license keys before formatting
echo.
echo Winget bulk install tip: After clean install, you can use:
echo   winget import -i programs.json
echo.
echo To create a Winget export, run:
echo   winget export -o "%USERPROFILE%\Desktop\winget-programs.json"
echo.

pause
exit /b 0
