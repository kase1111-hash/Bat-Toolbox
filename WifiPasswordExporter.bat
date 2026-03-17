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
    echo %YELLOW%[NOTE] Running without admin. Some profiles may not show passwords.%RESET%
    echo %YELLOW%       For full access, right-click and "Run as administrator".%RESET%
    echo/
)

:: Output file
set "OUTFILE=%USERPROFILE%\Desktop\WifiPasswords_%COMPUTERNAME%_%DATE:~-4%-%DATE:~4,2%-%DATE:~7,2%.txt"

echo %YELLOW%WARNING: The output file will contain passwords in plain text.%RESET%
echo          Delete it after use or store it securely.
echo/
echo Output will be saved to:
echo   %OUTFILE%
echo/

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

:: Get list of all Wi-Fi profiles
set "PROFILE_COUNT=0"
set "PASSWORD_COUNT=0"
set "OPEN_COUNT=0"

for /f "tokens=2 delims=:" %%a in ('netsh wlan show profiles 2^>nul ^| findstr /c:"All User Profile"') do (
    :: Trim leading space
    set "PROFILE=%%a"
    set "PROFILE=!PROFILE:~1!"

    set /a PROFILE_COUNT+=1

    :: Get password for this profile
    set "PASSWORD="
    set "AUTH="
    set "CIPHER="
    set "CONNECTION_MODE="

    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name^="!PROFILE!" key^=clear 2^>nul ^| findstr /c:"Key Content"') do (
        set "PASSWORD=%%b"
        set "PASSWORD=!PASSWORD:~1!"
    )

    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name^="!PROFILE!" key^=clear 2^>nul ^| findstr /c:"Authentication"') do (
        set "AUTH=%%b"
        set "AUTH=!AUTH:~1!"
    )

    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name^="!PROFILE!" key^=clear 2^>nul ^| findstr /c:"Cipher" ^| findstr /v "unicast broadcast"') do (
        set "CIPHER=%%b"
        set "CIPHER=!CIPHER:~1!"
    )

    for /f "tokens=2 delims=:" %%b in ('netsh wlan show profile name^="!PROFILE!" key^=clear 2^>nul ^| findstr /c:"Connection mode"') do (
        set "CONNECTION_MODE=%%b"
        set "CONNECTION_MODE=!CONNECTION_MODE:~1!"
    )

    :: Display and log
    if defined PASSWORD (
        set /a PASSWORD_COUNT+=1
        echo %GREEN%  [!PROFILE_COUNT!] !PROFILE!%RESET%
        echo       Password: !PASSWORD!
        (
        echo   Network:    !PROFILE!
        echo   Password:   !PASSWORD!
        echo   Security:   !AUTH!
        echo   Cipher:     !CIPHER!
        echo   Auto-connect: !CONNECTION_MODE!
        echo/
        ) >> "%OUTFILE%"
    ) else (
        set /a OPEN_COUNT+=1
        echo %YELLOW%  [!PROFILE_COUNT!] !PROFILE! (open / no password)%RESET%
        (
        echo   Network:    !PROFILE!
        echo   Password:   (none - open network)
        echo   Security:   !AUTH!
        echo/
        ) >> "%OUTFILE%"
    )
)

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

:: Append summary to file
(
echo ============================================================================
echo  SUMMARY
echo ============================================================================
echo/
echo   Total profiles:       !PROFILE_COUNT!
echo   With passwords:       !PASSWORD_COUNT!
echo   Open networks:        !OPEN_COUNT!
echo/
echo ============================================================================
) >> "%OUTFILE%"

echo/
echo %GREEN%Saved to:%RESET% %OUTFILE%
echo/
echo %YELLOW%REMINDER: Delete this file after use - it contains plain text passwords.%RESET%
echo/
echo ============================================================================
echo  Wi-Fi Password Export Complete
echo ============================================================================
echo/
pause
