@echo off
setlocal enabledelayedexpansion
title Storage Reliability Counter
color 0B

:: ============================================================================
:: Storage Reliability Counter
:: ============================================================================
:: Reports temperature, power-on hours, reallocated sectors, wear level,
:: and reliability counters for SSDs and HDDs. Flags drives approaching
:: failure. Basic info works without admin; full S.M.A.R.T. requires admin.
:: ============================================================================

:: Set up color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

echo %CYAN%============================================================================%RESET%
echo %CYAN% Storage Reliability Counter%RESET%
echo %CYAN%============================================================================%RESET%
echo/

:: Check admin status (non-fatal)
set "isAdmin=0"
net session >nul 2>&1
if %errorlevel% equ 0 (
    set "isAdmin=1"
    echo %GREEN%[INFO] Running as administrator — full S.M.A.R.T. data available%RESET%
) else (
    echo %YELLOW%[INFO] Running without admin — basic info only%RESET%
    echo %YELLOW%       Run as admin for temperature, S.M.A.R.T., and wear data%RESET%
)
echo/

:MainMenu
echo %CYAN%============================================================================%RESET%
echo %CYAN% Main Menu%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   [1] Quick health overview (all drives)
echo   [2] Detailed reliability report
echo   [3] Export report to Desktop
echo   [0] Exit
echo/

set /p "choice=Select option: "

if "%choice%"=="1" goto QuickOverview
if "%choice%"=="2" goto DetailedReport
if "%choice%"=="3" goto ExportReport
if "%choice%"=="0" goto Exit

echo %RED%Invalid option.%RESET%
echo/
goto MainMenu

:: ============================================================================
:: Option 1: Quick Overview
:: ============================================================================
:QuickOverview
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Quick Health Overview%RESET%
echo %CYAN%============================================================================%RESET%
echo/

powershell -ExecutionPolicy Bypass -File "%~dp0StorageReliabilityCounter.ps1" -Mode Quick 2>nul

echo/
pause
goto MainMenu

:: ============================================================================
:: Option 2: Detailed Report
:: ============================================================================
:DetailedReport
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Detailed Reliability Report%RESET%
echo %CYAN%============================================================================%RESET%
echo/

powershell -ExecutionPolicy Bypass -File "%~dp0StorageReliabilityCounter.ps1" -Mode Detail 2>nul

echo/
pause
goto MainMenu

:: ============================================================================
:: Option 3: Export Report
:: ============================================================================
:ExportReport
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Export Report to Desktop%RESET%
echo %CYAN%============================================================================%RESET%
echo/

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value ^| find "="') do set "dt=%%I"
set "REPORT=%USERPROFILE%\Desktop\StorageReliability_%COMPUTERNAME%_%dt:~0,8%.txt"

powershell -ExecutionPolicy Bypass -File "%~dp0StorageReliabilityCounter.ps1" -Mode Export -ReportPath "!REPORT!" 2>nul

echo/
echo %GREEN%Report saved to:%RESET%
echo   %REPORT%
echo/

pause
goto MainMenu

:Exit
echo/
echo Goodbye.
exit /b 0
