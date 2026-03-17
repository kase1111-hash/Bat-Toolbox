@echo off
setlocal enabledelayedexpansion
title Disable UPnP
color 0B
chcp 65001 >nul 2>nul

:: ============================================================================
:: Script Name: DisableUPnP.bat
:: Purpose: Disable UPnP (Universal Plug and Play) and SSDP Discovery to
::          prevent automatic firewall port-opening and reduce attack surface.
:: ============================================================================
:: UPnP allows applications to automatically open firewall ports without
:: user consent. This means malware, a compromised browser plugin, or any
:: local application can expose services to the internet silently.
::
:: SSDP (Simple Service Discovery Protocol) is the discovery layer that
:: UPnP uses to find devices on the network. It broadcasts on UDP 1900.
::
:: Disabling both prevents automatic port-forwarding and reduces the
:: local network attack surface. Manual port forwarding in your router
:: is the secure alternative when you need to expose a service.
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
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Disable UPnP / SSDP Discovery%RESET%                                           %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%Prevent automatic firewall port-opening%RESET%                              %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
title [1/4] Disable UPnP - Checking current state...

:: ========================================================================
:: Phase 1: Show current status
:: ========================================================================

echo   %BOLD%%WHITE%Current UPnP / SSDP Status%RESET%
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/

:: Check SSDP Discovery service
set "SSDP_STATE=Unknown"
set "SSDP_START=Unknown"
for /f "tokens=3" %%a in ('sc query SSDPSRV 2^>nul ^| findstr STATE') do set "SSDP_STATE=%%a"
for /f "tokens=3" %%a in ('sc qc SSDPSRV 2^>nul ^| findstr START_TYPE') do set "SSDP_START=%%a"

echo   %BOLD%SSDP Discovery (SSDPSRV):%RESET%
if "!SSDP_STATE!"=="4" (
    echo     State:      %GREEN%STOPPED%RESET%
) else if "!SSDP_STATE!"=="1" (
    echo     State:      %GREEN%STOPPED%RESET%
) else (
    echo     State:      %RED%RUNNING%RESET%
)
if "!SSDP_START!"=="DISABLED" (
    echo     Start type: %GREEN%Disabled%RESET%
) else (
    echo     Start type: %RED%!SSDP_START!%RESET%
)
echo/

:: Check UPnP Device Host service
set "UPNP_STATE=Unknown"
set "UPNP_START=Unknown"
for /f "tokens=3" %%a in ('sc query upnphost 2^>nul ^| findstr STATE') do set "UPNP_STATE=%%a"
for /f "tokens=3" %%a in ('sc qc upnphost 2^>nul ^| findstr START_TYPE') do set "UPNP_START=%%a"

echo   %BOLD%UPnP Device Host (upnphost):%RESET%
if "!UPNP_STATE!"=="4" (
    echo     State:      %GREEN%STOPPED%RESET%
) else if "!UPNP_STATE!"=="1" (
    echo     State:      %GREEN%STOPPED%RESET%
) else (
    echo     State:      %RED%RUNNING%RESET%
)
if "!UPNP_START!"=="DISABLED" (
    echo     Start type: %GREEN%Disabled%RESET%
) else (
    echo     Start type: %RED%!UPNP_START!%RESET%
)
echo/

:: Check Function Discovery services
set "FDPHOST_START=Unknown"
set "FDRESPUB_START=Unknown"
for /f "tokens=3" %%a in ('sc qc fdPHost 2^>nul ^| findstr START_TYPE') do set "FDPHOST_START=%%a"
for /f "tokens=3" %%a in ('sc qc FDResPub 2^>nul ^| findstr START_TYPE') do set "FDRESPUB_START=%%a"

echo   %BOLD%Function Discovery Provider Host (fdPHost):%RESET%
if "!FDPHOST_START!"=="DISABLED" (
    echo     Start type: %GREEN%Disabled%RESET%
) else (
    echo     Start type: %YELLOW%!FDPHOST_START!%RESET%
)

echo   %BOLD%Function Discovery Resource Publication (FDResPub):%RESET%
if "!FDRESPUB_START!"=="DISABLED" (
    echo     Start type: %GREEN%Disabled%RESET%
) else (
    echo     Start type: %YELLOW%!FDRESPUB_START!%RESET%
)

echo/
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/
echo   %BOLD%%WHITE%What this script does:%RESET%
echo/
echo     %DIM%1.%RESET% Stops and disables %BOLD%SSDP Discovery%RESET% service (UDP 1900 broadcasts)
echo     %DIM%2.%RESET% Stops and disables %BOLD%UPnP Device Host%RESET% service
echo     %DIM%3.%RESET% Stops and disables %BOLD%Function Discovery%RESET% provider and publication
echo     %DIM%4.%RESET% Adds firewall rules blocking SSDP (UDP 1900) inbound/outbound
echo/
echo   %YELLOW%NOTE: If you rely on automatic device discovery (smart TVs, IoT devices,
echo   game consoles for NAT traversal), disabling UPnP may require manual
echo   port forwarding in your router. Most applications work fine without it.%RESET%
echo/

set /p "confirm=  Disable UPnP and SSDP? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo/
    echo   Operation cancelled.
    pause
    exit /b 0
)

echo/

:: ========================================================================
:: Phase 2: Disable services
:: ========================================================================

title [2/4] Disable UPnP - Stopping services...

echo   %BOLD%%WHITE%Disabling UPnP services...%RESET%
echo/

:: SSDP Discovery
sc stop SSDPSRV >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% SSDP Discovery stopped
) else (
    echo   %DIM%[--]%RESET% SSDP Discovery was not running
)
sc config SSDPSRV start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% SSDP Discovery set to disabled
) else (
    echo   %RED%[FAIL]%RESET% Could not disable SSDP Discovery
)

echo/

:: UPnP Device Host
sc stop upnphost >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% UPnP Device Host stopped
) else (
    echo   %DIM%[--]%RESET% UPnP Device Host was not running
)
sc config upnphost start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% UPnP Device Host set to disabled
) else (
    echo   %RED%[FAIL]%RESET% Could not disable UPnP Device Host
)

echo/

:: ========================================================================
:: Phase 3: Disable Function Discovery services
:: ========================================================================

title [3/4] Disable UPnP - Disabling discovery services...

echo   %BOLD%%WHITE%Disabling Function Discovery services...%RESET%
echo/

:: Function Discovery Provider Host
sc stop fdPHost >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Function Discovery Provider Host stopped
) else (
    echo   %DIM%[--]%RESET% Function Discovery Provider Host was not running
)
sc config fdPHost start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Function Discovery Provider Host set to disabled
) else (
    echo   %YELLOW%[SKIP]%RESET% Could not disable Function Discovery Provider Host
)

:: Function Discovery Resource Publication
sc stop FDResPub >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Function Discovery Resource Publication stopped
) else (
    echo   %DIM%[--]%RESET% Function Discovery Resource Publication was not running
)
sc config FDResPub start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Function Discovery Resource Publication set to disabled
) else (
    echo   %YELLOW%[SKIP]%RESET% Could not disable Function Discovery Resource Publication
)

echo/

:: ========================================================================
:: Phase 4: Firewall rules
:: ========================================================================

title [4/4] Disable UPnP - Adding firewall rules...

echo   %BOLD%%WHITE%Adding firewall block rules...%RESET%
echo/

:: Remove existing rules first (idempotent)
netsh advfirewall firewall delete rule name="Block SSDP (UDP 1900)" >nul 2>&1
netsh advfirewall firewall delete rule name="Block SSDP outbound (UDP 1900)" >nul 2>&1

:: Block inbound SSDP
netsh advfirewall firewall add rule name="Block SSDP (UDP 1900)" dir=in action=block protocol=UDP localport=1900 >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Blocked inbound UDP 1900 %DIM%(SSDP)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not add inbound rule for UDP 1900
)

:: Block outbound SSDP (prevents this machine from discovering)
netsh advfirewall firewall add rule name="Block SSDP outbound (UDP 1900)" dir=out action=block protocol=UDP remoteport=1900 >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Blocked outbound UDP 1900 %DIM%(SSDP discovery)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not add outbound rule for UDP 1900
)

echo/

:: ========================================================================
:: Summary
:: ========================================================================

title Disable UPnP - Complete

echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Complete%RESET%                                                                 %CYAN%║%RESET%
echo   %CYAN%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo   %CYAN%║%RESET%  UPnP and SSDP Discovery have been disabled.                          %CYAN%║%RESET%
echo   %CYAN%║%RESET%  Applications can no longer auto-open firewall ports.                  %CYAN%║%RESET%
echo   %CYAN%║%RESET%  Function Discovery services have been disabled.                       %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
echo   %BOLD%%WHITE%To undo these changes:%RESET%
echo/
echo     %DIM%1.%RESET% Re-enable services:
echo        %CYAN%sc config SSDPSRV start= demand%RESET%
echo        %CYAN%sc config upnphost start= demand%RESET%
echo        %CYAN%sc config fdPHost start= demand%RESET%
echo        %CYAN%sc config FDResPub start= demand%RESET%
echo        %CYAN%sc start SSDPSRV%RESET%
echo        %CYAN%sc start upnphost%RESET%
echo/
echo     %DIM%2.%RESET% Remove firewall rules:
echo        %CYAN%netsh advfirewall firewall delete rule name="Block SSDP (UDP 1900)"%RESET%
echo        %CYAN%netsh advfirewall firewall delete rule name="Block SSDP outbound (UDP 1900)"%RESET%
echo/

pause
