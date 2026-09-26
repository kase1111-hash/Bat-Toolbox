@echo off
setlocal enabledelayedexpansion
title Wi-Fi Password Exporter
color 0B

:: ============================================================================
:: Wi-Fi Password Exporter
:: ============================================================================
:: Exports all saved Wi-Fi network names and passwords to a text file.
:: Useful before reinstalling Windows or setting up a new device.
:: ============================================================================

echo ============================================================================
echo  Wi-Fi Password Exporter
echo ============================================================================
echo/
echo Exports saved Wi-Fi network names and passwords.
echo/

:: Setup colors
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "RESET=%ESC%[0m"

:: Admin check - not strictly required but helps with some profiles
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%[NOTE] Running without admin. Passwords of secured networks will be hidden.%RESET%
    echo %YELLOW%       For full access, right-click and "Run as administrator".%RESET%
    echo/
)

:: Output file. Derive the date via PowerShell so it works on every locale -
:: %DATE% slicing assumes the US "Ddd MM/DD/YYYY" format and produces a name
:: containing "/" (an invalid path) elsewhere.
for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%D"
set "DESKTOP_DIR=%USERPROFILE%\Desktop"
:: Ask the shell for the real Desktop - OneDrive folder backup redirects it
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP_DIR=%%P"
if not exist "%DESKTOP_DIR%\" set "DESKTOP_DIR=%USERPROFILE%"
set "OUTFILE=%DESKTOP_DIR%\WifiPasswords_%COMPUTERNAME%_%TODAY%.txt"

echo %YELLOW%WARNING: The output file will contain passwords in plain text.%RESET%
echo          Delete it after use or store it securely.
echo/
echo Output will be saved to:
echo   !OUTFILE!
echo/

set "CONFIRM="
set /p "CONFIRM=Export Wi-Fi passwords? [Y/N]: "
if /i not "!CONFIRM!"=="Y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo/
echo %CYAN%Scanning saved Wi-Fi profiles...%RESET%
echo/

:: Initialize output file
(
echo ============================================================================
echo  Wi-Fi Password Export - %COMPUTERNAME%
echo  Date: %DATE% %TIME%
echo ============================================================================
echo/
echo  WARNING: This file contains passwords in plain text.
echo  Delete after use or store securely.
echo/
echo ============================================================================
echo/
) > "%OUTFILE%"

:: Read the Wi-Fi profiles. netsh's text output is translated on non-English
:: Windows, and parsing it in cmd cut passwords at ":" and mangled "!" and "^".
:: So export every profile as XML (language-independent, key stored verbatim)
:: to a private temp folder and let PowerShell read the XML: it lists each
:: network, appends it to the output file and saves the counts.
:: The temp folder holds plain-text keys, so it is deleted right afterwards.
:: Without admin rights netsh exports keys encrypted - they show as hidden.
set "PROFILE_COUNT=0"
set "PASSWORD_COUNT=0"
set "OPEN_COUNT=0"
set "NOKEY_COUNT=0"
set "WLAN_TMP=%TEMP%\wlan_export_%RANDOM%%RANDOM%"
mkdir "%WLAN_TMP%" 2>nul
netsh wlan export profile key=clear folder="%WLAN_TMP%" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=0; $k=0; $o=0; $n=0; foreach ($f in @(Get-ChildItem -LiteralPath $env:WLAN_TMP -Filter *.xml | Sort-Object Name)) { $x = New-Object xml; try { $x.Load($f.FullName) } catch { continue }; $p = $x.WLANProfile; $s = $p.MSM.security; $a = $s.authEncryption; $t++; $ssid = $p.SSIDConfig.SSID.name; if (-not $ssid) { $ssid = $p.name }; $head = '  [' + $t + '] ' + $ssid; if ($s.sharedKey -and $s.sharedKey.protected -eq 'false') { $k++; $key = $s.sharedKey.keyMaterial; Write-Host $head -ForegroundColor Green; Write-Host ('      Password: ' + $key) } elseif (-not $s.sharedKey -and $a.useOneX -ne 'true') { $o++; $key = '(none - open / Enhanced Open network)'; Write-Host ($head + ' (open / no password)') -ForegroundColor Yellow } elseif ($s.sharedKey) { $n++; $key = '(not available - run as administrator to reveal it)'; Write-Host ($head + ' (secured - key hidden, run as administrator)') -ForegroundColor Yellow } else { $n++; $key = '(not available - 802.1X/Enterprise network, no stored password)'; Write-Host ($head + ' (secured - 802.1X/Enterprise, no stored password)') -ForegroundColor Yellow }; Add-Content -LiteralPath $env:OUTFILE -Encoding UTF8 -Value @(('  Network:    ' + $ssid), ('  Password:   ' + $key), ('  Security:   ' + $a.authentication), ('  Cipher:     ' + $a.encryption), ('  Auto-connect: ' + $p.connectionMode), '') }; Set-Content -LiteralPath (Join-Path $env:WLAN_TMP 'counts.txt') -Value ('{0} {1} {2} {3}' -f $t, $k, $o, $n)"
if exist "%WLAN_TMP%\counts.txt" for /f "usebackq tokens=1-4" %%p in ("%WLAN_TMP%\counts.txt") do (
    set "PROFILE_COUNT=%%p"
    set "PASSWORD_COUNT=%%q"
    set "OPEN_COUNT=%%r"
    set "NOKEY_COUNT=%%s"
)
rd /s /q "%WLAN_TMP%" 2>nul

:: Handle no profiles found
if !PROFILE_COUNT! equ 0 (
    echo %RED%[ERROR] No Wi-Fi profiles found.%RESET%
    echo/
    echo Possible reasons:
    echo   - No Wi-Fi adapter installed
    echo   - Never connected to a Wi-Fi network
    echo   - Profiles were cleared
    echo/
    del "%OUTFILE%" 2>nul
    pause
    exit /b 1
)

:: Summary
echo/
echo ============================================================================
echo %CYAN% SUMMARY%RESET%
echo ============================================================================
echo/
echo   Total profiles found:    !PROFILE_COUNT!
echo   With saved passwords:    %GREEN%!PASSWORD_COUNT!%RESET%
echo   Open networks:           !OPEN_COUNT!
echo   Key not available:       !NOKEY_COUNT!

:: Append summary to file
(
echo ============================================================================
echo  SUMMARY
echo ============================================================================
echo/
echo   Total profiles:       !PROFILE_COUNT!
echo   With passwords:       !PASSWORD_COUNT!
echo   Open networks:        !OPEN_COUNT!
echo   Key not available:    !NOKEY_COUNT!
echo/
echo ============================================================================
) >> "%OUTFILE%"

echo/
echo %GREEN%Saved to:%RESET% !OUTFILE!
echo/
echo %YELLOW%REMINDER: Delete this file after use - it contains plain text passwords.%RESET%
echo/
echo ============================================================================
echo  Wi-Fi Password Export Complete
echo ============================================================================
echo/
pause
