@echo off
setlocal enabledelayedexpansion
title Windows 10 EOS Notification Remover
color 0A

:: ============================================
:: Windows 10 End-of-Support Notification Remover
:: Removes the annoying "Windows 10 is no longer supported" icon
:: ============================================

echo ============================================
echo  Windows 10 EOS Notification Remover
echo ============================================
echo.
echo This script will remove the "Windows 10 is no longer supported"
echo notification icon from your system tray.
echo.

:: Check for admin privileges
net session >nul 2>&1
if errorlevel 1 (
    color 0C
    echo [ERROR] This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    echo.
    pause
    exit /b 1
)

echo [INFO] Administrator privileges confirmed.
echo.

:: Confirm before proceeding
set /p "confirm=Do you want to remove the EOS notification? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo.
    echo Operation cancelled by user.
    pause
    exit /b 0
)

echo.
echo ============================================
echo  Removing EOS Notification Components
echo ============================================
echo.

set "success=0"
set "errors=0"

:: Step 1: Kill any running EOSNotify processes
echo [1/5] Terminating EOSNotify processes...
taskkill /f /im EOSNotify.exe >nul 2>&1
if errorlevel 1 (
    echo       - No running EOSNotify process found ^(OK^)
) else (
    echo       - EOSNotify process terminated successfully
    set /a success+=1
)

:: Step 2: Disable EOS notification via registry (User Policy)
echo [2/5] Disabling EOS notification via registry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableOSUpgrade" /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (
    echo       - Failed to set DisableOSUpgrade policy
    set /a errors+=1
) else (
    echo       - DisableOSUpgrade policy set successfully
    set /a success+=1
)

:: Step 3: Disable End of Support notification specifically
echo [3/5] Disabling End of Support notification registry key...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\OSUpgrade" /v "AllowOSUpgrade" /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
    echo       - Failed to set AllowOSUpgrade key
    set /a errors+=1
) else (
    echo       - AllowOSUpgrade key set successfully
    set /a success+=1
)

:: Step 4: Disable EOS notification scheduled tasks
echo [4/5] Disabling related scheduled tasks...
schtasks /change /tn "\Microsoft\Windows\Setup\EOSNotify" /disable >nul 2>&1
if errorlevel 1 (
    echo       - EOSNotify task not found or already disabled
) else (
    echo       - EOSNotify scheduled task disabled
    set /a success+=1
)

schtasks /change /tn "\Microsoft\Windows\Setup\EOSNotify2" /disable >nul 2>&1
if errorlevel 1 (
    echo       - EOSNotify2 task not found or already disabled
) else (
    echo       - EOSNotify2 scheduled task disabled
    set /a success+=1
)

:: Step 5: Rename EOSNotify.exe to prevent future execution
echo [5/5] Renaming EOSNotify executable to prevent future execution...
set "eosPath=%SystemRoot%\System32\EOSNotify.exe"
if exist "%eosPath%" (
    takeown /f "%eosPath%" >nul 2>&1
    icacls "%eosPath%" /grant administrators:F >nul 2>&1
    ren "%eosPath%" "EOSNotify.exe.bak" >nul 2>&1
    if errorlevel 1 (
        echo       - Failed to rename EOSNotify.exe
        set /a errors+=1
    ) else (
        echo       - EOSNotify.exe renamed to EOSNotify.exe.bak
        set /a success+=1
    )
) else (
    echo       - EOSNotify.exe not found ^(may already be removed^)
)

echo.
echo ============================================
echo  Operation Complete
echo ============================================
echo.
echo Successful operations: %success%
echo Failed operations: %errors%
echo.

if %errors% gtr 0 (
    color 0E
    echo [WARNING] Some operations failed. The notification may still appear.
    echo Try running the script again or manually check the registry settings.
) else (
    color 0A
    echo [SUCCESS] EOS notification has been disabled.
    echo The notification icon should no longer appear.
)

echo.
echo NOTE: You may need to restart your computer or restart
echo       Windows Explorer for changes to take full effect.
echo.
set /p "restart=Would you like to restart Windows Explorer now? (Y/N): "
if /i "%restart%"=="Y" (
    echo.
    echo Restarting Windows Explorer...
    taskkill /f /im explorer.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    start explorer.exe
    echo Explorer restarted successfully.
)

echo.
pause
exit /b 0
