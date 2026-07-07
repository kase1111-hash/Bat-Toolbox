@echo off
setlocal enabledelayedexpansion
title Harden Print Spooler
color 0B
chcp 65001 >nul 2>nul

:: ============================================================================
:: Script Name: HardenPrintSpooler.bat
:: Purpose: Disable or harden the Windows Print Spooler service to mitigate
::          PrintNightmare (CVE-2021-1675 / CVE-2021-34527) and related
::          spooler vulnerabilities.
:: ============================================================================
:: The Print Spooler runs as SYSTEM and has been the target of multiple
:: critical RCE and privilege escalation CVEs. If you don't print from this
:: machine, disabling it entirely is the safest option. If you do print,
:: this script offers a hardened configuration that restricts the most
:: dangerous features while keeping local printing functional.
:: ============================================================================

:: Set up color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "DIM=%ESC%[90m"
set "BOLD=%ESC%[1m"
set "RESET=%ESC%[0m"

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo/
    echo   %RED%[ERROR] This script requires administrator privileges.%RESET%
    echo   %DIM%Right-click the script and select "Run as administrator".%RESET%
    echo/
    pause
    exit /b 1
)

cls
echo/
echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Harden Print Spooler%RESET%                                                     %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%Mitigate PrintNightmare and spooler-based attacks%RESET%                    %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
title [1/3] Harden Print Spooler - Checking status...

:: ========================================================================
:: Phase 1: Show current status
:: ========================================================================

echo   %BOLD%%WHITE%Current Print Spooler Status%RESET%
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/

:: Check spooler service status
for /f "tokens=3" %%a in ('sc query Spooler ^| findstr STATE') do set "SPOOLER_STATE=%%a"
for /f "tokens=3" %%a in ('sc qc Spooler ^| findstr START_TYPE') do set "SPOOLER_START=%%a"

if "!SPOOLER_STATE!"=="1" (
    echo   Service state:  %GREEN%STOPPED%RESET%
) else if "!SPOOLER_STATE!"=="4" (
    echo   Service state:  %RED%RUNNING%RESET%
) else (
    echo   Service state:  %YELLOW%!SPOOLER_STATE!%RESET%
)

if "!SPOOLER_START!"=="DISABLED" (
    echo   Start type:     %GREEN%Disabled%RESET%
) else if "!SPOOLER_START!"=="DEMAND_START" (
    echo   Start type:     %YELLOW%Manual%RESET%
) else (
    echo   Start type:     %RED%!SPOOLER_START!%RESET%
)

:: Check Point and Print restrictions
set "PP_STATUS=Not configured (vulnerable)"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v NoWarningNoElevationOnInstall >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v NoWarningNoElevationOnInstall 2^>nul ^| findstr NoWarningNoElevationOnInstall') do (
        if "%%a"=="0x0" set "PP_STATUS=Restricted (hardened)"
    )
)
echo   Point and Print: !PP_STATUS!

:: Check remote print driver installation
set "RPD_STATUS=Allowed (default)"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v DisableWebPnPDownload >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v DisableWebPnPDownload 2^>nul ^| findstr DisableWebPnPDownload') do (
        if "%%a"=="0x1" set "RPD_STATUS=Blocked"
    )
)
echo   Web PnP download: !RPD_STATUS!

echo/
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/
echo   %BOLD%%WHITE%Choose an option:%RESET%
echo/
echo     %CYAN%[1]%RESET% %BOLD%Disable completely%RESET% %DIM%- Stops and disables Print Spooler entirely%RESET%
echo         %DIM%Best for: machines that never print (servers, VMs, dev boxes)%RESET%
echo/
echo     %CYAN%[2]%RESET% %BOLD%Harden only%RESET% %DIM%- Keep printing but restrict dangerous features%RESET%
echo         %DIM%Best for: workstations that need local or network printing%RESET%
echo/
echo     %CYAN%[3]%RESET% %BOLD%Cancel%RESET%
echo/

set /p "choice=  Select option [1/2/3]: "

if "%choice%"=="3" (
    echo/
    echo   Operation cancelled.
    pause
    exit /b 0
)
if "%choice%"=="1" goto :disable_spooler
if "%choice%"=="2" goto :harden_spooler

echo/
echo   %RED%Invalid choice.%RESET%
pause
exit /b 1

:: ========================================================================
:: Option 1: Disable completely
:: ========================================================================
:disable_spooler

title [2/3] Harden Print Spooler - Disabling service...

echo/
echo   %BOLD%%WHITE%Disabling Print Spooler completely...%RESET%
echo/

:: Stop the spooler
sc stop Spooler >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Print Spooler stopped
) else (
    echo   %DIM%[--]%RESET% Print Spooler was not running
)

:: Disable it
sc config Spooler start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Print Spooler set to disabled
) else (
    echo   %RED%[FAIL]%RESET% Could not disable Print Spooler
)

:: Also apply the hardening registry keys (defense in depth)
goto :apply_registry_hardening

:: ========================================================================
:: Option 2: Harden only (keep printing)
:: ========================================================================
:harden_spooler

title [2/3] Harden Print Spooler - Applying restrictions...

echo/
echo   %BOLD%%WHITE%Hardening Print Spooler (keeping printing functional)...%RESET%
echo/

:: Set spooler to Manual start (only runs when needed)
sc config Spooler start= demand >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Print Spooler set to Manual start
) else (
    echo   %YELLOW%[SKIP]%RESET% Could not change start type
)

goto :apply_registry_hardening

:: ========================================================================
:: Apply registry hardening (shared by both options)
:: ========================================================================
:apply_registry_hardening

title [3/3] Harden Print Spooler - Applying registry hardening...

echo/
echo   %BOLD%%WHITE%Applying registry hardening...%RESET%
echo/

:: Restrict Point and Print - require elevation for driver install
:: This is the primary PrintNightmare mitigation
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v NoWarningNoElevationOnInstall /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Point and Print: require elevation for driver install
) else (
    echo   %RED%[FAIL]%RESET% Could not set Point and Print restriction
)

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v UpdatePromptSettings /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Point and Print: show warning and elevation on update
) else (
    echo   %RED%[FAIL]%RESET% Could not set Point and Print update setting
)

:: Restrict driver installation to admins only
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v RestrictDriverInstallationToAdministrators /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Print driver installation restricted to admins
) else (
    echo   %RED%[FAIL]%RESET% Could not restrict driver installation
)

:: Disable web-based printing (PnP driver download from internet)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v DisableWebPnPDownload /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Web PnP print driver download disabled
) else (
    echo   %RED%[FAIL]%RESET% Could not disable web PnP download
)

:: Disable internet printing (IPP)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v DisableHTTPPrinting /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Internet printing (IPP/HTTP) disabled
) else (
    echo   %RED%[FAIL]%RESET% Could not disable HTTP printing
)

:: Prevent the spooler from accepting client connections (not a print server)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% RPC authentication level set to Privacy
) else (
    echo   %RED%[FAIL]%RESET% Could not set RPC authentication level
)

echo/

:: ========================================================================
:: Summary
:: ========================================================================

title Harden Print Spooler - Complete

echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Complete%RESET%                                                                 %CYAN%║%RESET%
echo   %CYAN%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
if "%choice%"=="1" (
echo   %CYAN%║%RESET%  Print Spooler has been stopped, disabled, and hardened.               %CYAN%║%RESET%
) else (
echo   %CYAN%║%RESET%  Print Spooler has been set to manual start and hardened.              %CYAN%║%RESET%
)
echo   %CYAN%║%RESET%  PrintNightmare mitigations applied.                                   %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
echo   %BOLD%%WHITE%To undo these changes:%RESET%
echo/
echo     %DIM%1.%RESET% Re-enable Print Spooler:
echo        %CYAN%sc config Spooler start= auto%RESET%
echo        %CYAN%sc start Spooler%RESET%
echo/
echo     %DIM%2.%RESET% Remove Point and Print restrictions:
echo        %CYAN%reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /f%RESET%
echo/
echo     %DIM%3.%RESET% Re-enable web/HTTP printing:
echo        %CYAN%reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v DisableWebPnPDownload /f%RESET%
echo        %CYAN%reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v DisableHTTPPrinting /f%RESET%
echo/
echo     %DIM%4.%RESET% Remove RPC hardening:
echo        %CYAN%reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /f%RESET%
echo/

pause
