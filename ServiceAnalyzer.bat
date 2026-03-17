@echo off
setlocal enabledelayedexpansion
title Windows Service Analyzer
color 0B
chcp 65001 >nul 2>nul

:: ============================================================================
:: Windows Service Analyzer
:: ============================================================================
:: Analyzes Windows services to find unnecessary automatic services.
:: Identifies bloatware services, telemetry, and services that can be
:: safely set to manual or disabled.
:: ============================================================================

:: Setup colors
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "GREEN=%ESC%[92m"
set "DIM=%ESC%[90m"
set "BOLD=%ESC%[1m"
set "RESET=%ESC%[0m"

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo/
    pause
    exit /b 1
)

cls
echo/
echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Windows Service Analyzer%RESET%                                                %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%Find unnecessary services, telemetry, and bloatware%RESET%                 %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
title [1/2] Service Analyzer - Scanning...
<nul set /p "=  %CYAN%[%RESET%%WHITE%*%RESET%%CYAN%]%RESET% Analyzing Windows services"
for /l %%i in (1,1,3) do (
    <nul set /p "=."
    timeout /t 0 /nobreak >nul
)
echo/
echo/

:: Run the PowerShell service analysis script
powershell -ExecutionPolicy Bypass -File "%~dp0ServiceAnalyzer.ps1"

echo/

:: Ask about disabling bloatware services
if exist "%TEMP%\bloatware_services.txt" (
    set "bloat_count=0"
    for /f %%a in ('type "%TEMP%\bloatware_services.txt" 2^>nul ^| find /c /v ""') do set "bloat_count=%%a"

    if !bloat_count! gtr 0 (
        echo/
        set /p "disablebloat=Disable BLOATWARE services? [Y/N]: "
        if /i "!disablebloat!"=="Y" (
            echo/
            echo Disabling bloatware services...
            for /f "tokens=*" %%s in ('type "%TEMP%\bloatware_services.txt"') do (
                sc stop "%%s" >nul 2>&1
                sc config "%%s" start= disabled >nul 2>&1
                if not errorlevel 1 (
                    echo   [DISABLED] %%s
                ) else (
                    echo   [FAILED] %%s - may be protected
                )
            )
        )
    )
    del "%TEMP%\bloatware_services.txt" 2>nul
)

:: Ask about disabling telemetry services
if exist "%TEMP%\telemetry_services.txt" (
    set "tele_count=0"
    for /f %%a in ('type "%TEMP%\telemetry_services.txt" 2^>nul ^| find /c /v ""') do set "tele_count=%%a"

    if !tele_count! gtr 0 (
        echo/
        set /p "disabletele=Disable TELEMETRY services? [Y/N]: "
        if /i "!disabletele!"=="Y" (
            echo/
            echo Disabling telemetry services...
            for /f "tokens=*" %%s in ('type "%TEMP%\telemetry_services.txt"') do (
                sc stop "%%s" >nul 2>&1
                sc config "%%s" start= disabled >nul 2>&1
                if not errorlevel 1 (
                    echo   [DISABLED] %%s
                ) else (
                    echo   [FAILED] %%s - may be protected
                )
            )
        )
    )
    del "%TEMP%\telemetry_services.txt" 2>nul
)

:: Ask about Xbox services
if exist "%TEMP%\xbox_services.txt" (
    set "xbox_count=0"
    for /f %%a in ('type "%TEMP%\xbox_services.txt" 2^>nul ^| find /c /v ""') do set "xbox_count=%%a"

    if !xbox_count! gtr 0 (
        echo/
        set /p "disablexbox=Disable XBOX services? [Y/N]: "
        if /i "!disablexbox!"=="Y" (
            echo/
            echo Disabling Xbox services...
            for /f "tokens=*" %%s in ('type "%TEMP%\xbox_services.txt"') do (
                sc stop "%%s" >nul 2>&1
                sc config "%%s" start= disabled >nul 2>&1
                if not errorlevel 1 (
                    echo   [DISABLED] %%s
                ) else (
                    echo   [FAILED] %%s - may be protected
                )
            )
        )
    )
    del "%TEMP%\xbox_services.txt" 2>nul
)

:: Cleanup
del "%TEMP%\manual_services.txt" 2>nul

title [2/2] Service Analyzer - Complete
echo/
echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %GREEN%Complete^!%RESET%                                                               %CYAN%║%RESET%
echo   %CYAN%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo   %CYAN%║%RESET%  %DIM%-%RESET% Use %WHITE%services.msc%RESET% for manual service management                     %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%-%RESET% Disabled services can be re-enabled anytime                        %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%-%RESET% Some changes require a restart to take effect                      %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%-%RESET% If something breaks, re-enable or use System Restore               %CYAN%║%RESET%
echo   %CYAN%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo   %CYAN%║%RESET%  To re-enable a service:                                                %CYAN%║%RESET%
echo   %CYAN%║%RESET%    %DIM%sc config "ServiceName" start= auto%RESET%                                %CYAN%║%RESET%
echo   %CYAN%║%RESET%    %DIM%sc start "ServiceName"%RESET%                                              %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/

pause
exit /b 0
