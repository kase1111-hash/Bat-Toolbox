@echo off
title Network Reset Utility
color 0A

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo ============================================
    echo   ADMINISTRATOR PRIVILEGES REQUIRED
    echo ============================================
    echo.
    echo Right-click this script and select
    echo "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo ============================================
echo   NETWORK RESET UTILITY
echo ============================================
echo.

:: Get the active adapter name
:: tokens=4* puts first word in %%a, remaining words in %%b
:: We need both parts to handle multi-word adapter names
for /f "tokens=4*" %%a in ('netsh interface show interface ^| findstr /i "Connected"') do (
    set "adapter=%%a"
    if not "%%b"=="" set "adapter=%%a %%b"
)

echo Active adapter detected: %adapter%
echo.

echo [1/8] Releasing IP address...
ipconfig /release >nul 2>&1

echo [2/8] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1

echo [3/8] Flushing ARP cache...
netsh interface ip delete arpcache >nul 2>&1

echo [4/8] Resetting Winsock catalog...
netsh winsock reset >nul 2>&1

echo [5/8] Resetting TCP/IP stack...
netsh int ip reset >nul 2>&1

echo [6/8] Disabling network adapter...
netsh interface set interface "%adapter%" disable >nul 2>&1

echo       Waiting 5 seconds...
timeout /t 5 /nobreak >nul

echo [7/8] Re-enabling network adapter...
netsh interface set interface "%adapter%" enable >nul 2>&1

echo       Waiting for connection...
timeout /t 5 /nobreak >nul

echo [8/8] Renewing IP address...
ipconfig /renew >nul 2>&1

echo.
echo ============================================
echo   RESET COMPLETE
echo ============================================
echo.
echo New IP configuration:
echo.
ipconfig | findstr /i "IPv4 Subnet Default"
echo.
echo ============================================
echo.
echo NOTE: Winsock and TCP/IP resets may require
echo a restart to fully take effect.
echo.
echo ============================================

:reboot_prompt
echo.
set /p "reboot=Restart computer now? (Y/N): "

if /i "%reboot%"=="Y" (
    echo.
    echo Restarting in 10 seconds...
    echo Press Ctrl+C to cancel.
    shutdown /r /t 10 /c "Network Reset Utility - Restarting to complete network stack reset"
    exit /b 0
)

if /i "%reboot%"=="N" (
    echo.
    echo Remember to restart later if you experience
    echo continued network issues.
    echo.
    pause
    exit /b 0
)

:: Invalid input - ask again
echo Please enter Y or N.
goto reboot_prompt
