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
echo  - Desktop applications [from Registry]
echo  - Microsoft Store apps [AppX packages]
echo  - Windows optional features
echo  - Detailed program list with versions
echo  - Winget JSON file [for automated bulk reinstall]
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
echo [1/7] Scanning desktop applications (64-bit registry)...

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
echo [2/7] Scanning desktop applications (32-bit registry)...

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
echo [3/7] Scanning user-installed applications...

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
echo [4/7] Scanning Microsoft Store apps...

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  MICROSOFT STORE APPS >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

set "PSSCRIPT=%TEMP%\get-appx.ps1"

:: Write PowerShell script line by line to avoid parentheses issues
echo $apps = Get-AppxPackage ^| Where-Object { $_.IsFramework -eq $false } ^| Sort-Object Name > "%PSSCRIPT%"
echo foreach ^($app in $apps^) { >> "%PSSCRIPT%"
echo     $name = $app.Name >> "%PSSCRIPT%"
echo     $skip = $false >> "%PSSCRIPT%"
echo     if ^($name -match '^Microsoft\.'  ^) { $skip = $true } >> "%PSSCRIPT%"
echo     if ^($name -match '^Windows'^) { $skip = $true } >> "%PSSCRIPT%"
echo     if ^($name -match '^\d+\.'^) { $skip = $true } >> "%PSSCRIPT%"
echo     if ^($name -match '^InputApp'^) { $skip = $true } >> "%PSSCRIPT%"
echo     if ^(-not $skip^) { Write-Output $name } >> "%PSSCRIPT%"
echo } >> "%PSSCRIPT%"

:: Alternative: just run PowerShell directly
powershell -ExecutionPolicy Bypass -Command "Get-AppxPackage | Where-Object { $_.IsFramework -eq $false -and $_.Name -notmatch '^Microsoft\.' -and $_.Name -notmatch '^Windows' } | Select-Object -ExpandProperty Name | Sort-Object" >> "%EXPORT_FILE%" 2>nul

set "count=0"
for /f "tokens=*" %%a in ('powershell -ExecutionPolicy Bypass -Command "Get-AppxPackage | Where-Object { $_.IsFramework -eq $false -and $_.Name -notmatch '^Microsoft\.' -and $_.Name -notmatch '^Windows' } | Measure-Object | Select-Object -ExpandProperty Count" 2^>nul') do set "count=%%a"
del "%PSSCRIPT%" 2>nul
echo   Found %count% apps

:: ============================================================================
:: Section 5: Windows Optional Features
:: ============================================================================
echo [5/7] Scanning Windows optional features...

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
:: Section 6: Detailed Program List with Versions
:: ============================================================================
echo [6/7] Creating detailed program list with versions...

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  DETAILED PROGRAM LIST [Name, Version, Publisher] >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

echo NAME                                                         ^| VERSION              ^| PUBLISHER >> "%EXPORT_FILE%"
echo ------------------------------------------------------------ ^| -------------------- ^| ------------------------------ >> "%EXPORT_FILE%"

:: Use inline PowerShell to avoid batch parentheses issues
powershell -ExecutionPolicy Bypass -Command "$paths = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'); $programs = $paths | ForEach-Object { Get-ItemProperty $_ -ErrorAction SilentlyContinue } | Where-Object { $_.DisplayName } | Select-Object DisplayName, DisplayVersion, Publisher | Sort-Object DisplayName -Unique; foreach ($p in $programs) { $n = if ($p.DisplayName.Length -gt 55) { $p.DisplayName.Substring(0,55) + '...' } else { $p.DisplayName }; $v = if ($p.DisplayVersion) { $p.DisplayVersion } else { 'N/A' }; $pub = if ($p.Publisher) { $p.Publisher } else { 'Unknown' }; if ($v.Length -gt 18) { $v = $v.Substring(0,18) }; if ($pub.Length -gt 28) { $pub = $pub.Substring(0,28) }; Write-Output ('{0,-60} | {1,-20} | {2}' -f $n, $v, $pub) }" >> "%EXPORT_FILE%" 2>nul

:: ============================================================================
:: Section 7: Winget Export
:: ============================================================================
echo [7/7] Creating Winget export file...

set "WINGET_FILE=%EXPORT_DIR%\WingetPrograms_%COMPUTERNAME%_%TIMESTAMP%.json"

:: Check if winget is available
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo       - Winget found, exporting programs...
    winget export -o "%WINGET_FILE%" --accept-source-agreements >nul 2>&1
    if exist "%WINGET_FILE%" (
        :: Count packages in JSON
        set "winget_count=0"
        for /f %%a in ('powershell -Command "(Get-Content '%WINGET_FILE%' | ConvertFrom-Json).Sources.Packages.Count" 2^>nul') do set "winget_count=%%a"
        echo       - Exported !winget_count! programs to Winget JSON
        echo. >> "%EXPORT_FILE%"
        echo ============================================================================ >> "%EXPORT_FILE%"
        echo  WINGET EXPORT >> "%EXPORT_FILE%"
        echo ============================================================================ >> "%EXPORT_FILE%"
        echo. >> "%EXPORT_FILE%"
        echo Winget JSON file created: %WINGET_FILE% >> "%EXPORT_FILE%"
        echo. >> "%EXPORT_FILE%"
        echo To reinstall after clean install, run: >> "%EXPORT_FILE%"
        echo   winget import -i "%WINGET_FILE%" --accept-source-agreements --accept-package-agreements >> "%EXPORT_FILE%"
        echo. >> "%EXPORT_FILE%"
        echo Programs included in Winget export: >> "%EXPORT_FILE%"
        powershell -Command "(Get-Content '%WINGET_FILE%' | ConvertFrom-Json).Sources.Packages | ForEach-Object { Write-Output ('  - ' + $_.PackageIdentifier) }" >> "%EXPORT_FILE%" 2>nul
    ) else (
        echo       - Winget export failed [no matching packages found]
    )
) else (
    echo       - Winget not found [skipping winget export]
    echo       - Install from: https://github.com/microsoft/winget-cli
)

:: ============================================================================
:: Section 8: Browser Extensions Reminder
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
echo Files saved to:
echo  Text report: %EXPORT_FILE%
if exist "%WINGET_FILE%" (
    echo  Winget JSON: %WINGET_FILE%
)
echo.

:: Count total lines (approximate program count)
set "totallines=0"
for /f %%a in ('type "%EXPORT_FILE%" ^| find /c /v ""') do set "totallines=%%a"
echo Report contains approximately %totallines% lines.
echo.

:: Ask if user wants to open the file
set /p "openfile=Would you like to open the text report now? [Y/N]: "
if /i "%openfile%"=="Y" (
    notepad "%EXPORT_FILE%"
)

echo.
echo ============================================================================
echo  Tips for Clean Install Recovery
echo ============================================================================
echo.
echo 1. Save BOTH files to a USB drive or cloud storage
echo 2. Use Ninite.com for quick reinstallation of common programs
echo 3. The Winget JSON can bulk-install programs automatically
echo 4. Export browser bookmarks and extension lists separately
echo 5. Back up license keys before formatting
echo.
if exist "%WINGET_FILE%" (
    echo Winget reinstall command [run after clean install]:
    echo   winget import -i "WingetPrograms_%COMPUTERNAME%_DATE.json" --accept-package-agreements
    echo.
    echo NOTE: Only programs available in Winget repository are in the JSON.
    echo       Use the text report to manually install the rest.
) else (
    echo Winget was not available. Install it from:
    echo   https://github.com/microsoft/winget-cli
)
echo.

pause
exit /b 0
