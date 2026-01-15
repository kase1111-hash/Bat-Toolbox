@echo off
title Screen Sleep Guard
color 0A

:: Run the PowerShell script from the same directory as this batch file
powershell -ExecutionPolicy Bypass -File "%~dp0ScreenSleepGuard.ps1"

exit /b
