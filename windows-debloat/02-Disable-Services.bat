@echo off
:: ============================================================================
:: Windows 10 Debloat - Disable Unnecessary Services
:: ============================================================================
:: This script disables telemetry, Xbox, and other unnecessary services.
:: Review carefully before running - some services may be needed for your use case.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Disable Unnecessary Services
echo ============================================================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo This script will disable the following services:
echo.
echo  TELEMETRY ^& DATA COLLECTION:
echo   - DiagTrack (Connected User Experiences and Telemetry)
echo   - dmwappushservice (Device Management WAP Push)
echo   - diagnosticshub.standardcollector.service
echo   - WMPNetworkSvc (Windows Media Player Network Sharing)
echo.
echo  XBOX SERVICES (skip if you game on PC):
echo   - XblAuthManager, XblGameSave, XboxGipSvc, XboxNetApiSvc
echo.
echo  CONSUMER FEATURES:
echo   - MapsBroker (Downloaded Maps Manager)
echo   - lfsvc (Geolocation Service)
echo   - RetailDemo (Retail Demo Service)
echo.
echo  RARELY USED:
echo   - Fax, WpcMonSvc (Parental Controls), wisvc (Windows Insider)
echo   - PhoneSvc, WerSvc (Error Reporting)
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo ============================================================================
echo  Disabling Telemetry Services...
echo ============================================================================

for %%s in (DiagTrack dmwappushservice WMPNetworkSvc) do (
    echo Disabling %%s...
    sc config "%%s" start=disabled >nul 2>&1
    net stop "%%s" >nul 2>&1
)

:: This one has a longer name
sc config "diagnosticshub.standardcollector.service" start=disabled >nul 2>&1
net stop "diagnosticshub.standardcollector.service" >nul 2>&1

echo.
echo ============================================================================
echo  Disabling Xbox Services...
echo ============================================================================

for %%s in (XblAuthManager XblGameSave XboxGipSvc XboxNetApiSvc) do (
    echo Disabling %%s...
    sc config "%%s" start=disabled >nul 2>&1
    net stop "%%s" >nul 2>&1
)

echo.
echo ============================================================================
echo  Disabling Consumer Feature Services...
echo ============================================================================

for %%s in (MapsBroker lfsvc RetailDemo) do (
    echo Disabling %%s...
    sc config "%%s" start=disabled >nul 2>&1
    net stop "%%s" >nul 2>&1
)

echo.
echo ============================================================================
echo  Disabling Rarely Used Services...
echo ============================================================================

for %%s in (Fax WpcMonSvc wisvc PhoneSvc WerSvc) do (
    echo Disabling %%s...
    sc config "%%s" start=disabled >nul 2>&1
    net stop "%%s" >nul 2>&1
)

echo.
echo ============================================================================
echo  Services disabled successfully!
echo ============================================================================
echo.
echo NOTE: If you need any of these services later, you can re-enable them
echo using: sc config "ServiceName" start=auto
echo.
echo A reboot is recommended to apply all changes.
echo.

pause
