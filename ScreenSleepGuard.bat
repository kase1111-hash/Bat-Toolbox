@echo off
title Screen Sleep Guard
color 0A

:: Check that the companion PowerShell script exists
if not exist "%~dp0ScreenSleepGuard.ps1" (
    color 0C
    echo ERROR: ScreenSleepGuard.ps1 not found in the same directory as this script.
    echo Please ensure both files are in the same folder.
    echo.
    pause
    exit /b 1
)

:: Run the PowerShell script from the same directory as this batch file
powershell -ExecutionPolicy Bypass -File "%~dp0ScreenSleepGuard.ps1"

exit /b
