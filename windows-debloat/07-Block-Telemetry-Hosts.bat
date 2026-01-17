@echo off
setlocal
:: ============================================================================
:: Windows 10 Debloat - Block Telemetry via Hosts File
:: ============================================================================
:: This script adds entries to the Windows hosts file to block
:: Microsoft telemetry and advertising domains at the network level.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Block Telemetry via Hosts File
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

echo This script will add entries to your hosts file to block:
echo  - Microsoft telemetry servers
echo  - Microsoft feedback servers
echo  - Advertising networks (MSN, DoubleClick, etc.)
echo.
echo Location: C:\Windows\System32\drivers\etc\hosts
echo.
echo NOTE: This provides an additional layer of protection beyond
echo disabling services and scheduled tasks.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

set HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts

echo.
echo Creating backup of hosts file...
copy "%HOSTS_FILE%" "%HOSTS_FILE%.backup" >nul 2>&1

echo Adding telemetry blocks to hosts file...
echo.

:: Check if we've already added our blocks
findstr /C:"# Windows 10 Debloat - Telemetry Blocks" "%HOSTS_FILE%" >nul 2>&1
if %errorlevel% equ 0 (
    echo Telemetry blocks already present in hosts file.
    echo Skipping to avoid duplicates.
    goto :done
)

:: Add the telemetry blocks
(
echo.
echo # ============================================================================
echo # Windows 10 Debloat - Telemetry Blocks
echo # Added by windows-debloat scripts
echo # ============================================================================
echo.
echo # Microsoft Telemetry
echo 0.0.0.0 vortex.data.microsoft.com
echo 0.0.0.0 vortex-win.data.microsoft.com
echo 0.0.0.0 telecommand.telemetry.microsoft.com
echo 0.0.0.0 telecommand.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 oca.telemetry.microsoft.com
echo 0.0.0.0 oca.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 sqm.telemetry.microsoft.com
echo 0.0.0.0 sqm.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 watson.telemetry.microsoft.com
echo 0.0.0.0 watson.telemetry.microsoft.com.nsatc.net
echo 0.0.0.0 redir.metaservices.microsoft.com
echo 0.0.0.0 settings-sandbox.data.microsoft.com
echo 0.0.0.0 watson.live.com
echo 0.0.0.0 watson.microsoft.com
echo 0.0.0.0 statsfe2.ws.microsoft.com
echo 0.0.0.0 corpext.msitadfs.glbdns2.microsoft.com
echo 0.0.0.0 compatexchange.cloudapp.net
echo 0.0.0.0 cs1.wpc.v0cdn.net
echo 0.0.0.0 a-0001.a-msedge.net
echo 0.0.0.0 statsfe2.update.microsoft.com.akadns.net
echo 0.0.0.0 diagnostics.support.microsoft.com
echo 0.0.0.0 corp.sts.microsoft.com
echo 0.0.0.0 statsfe1.ws.microsoft.com
echo.
echo # Feedback
echo 0.0.0.0 feedback.windows.com
echo 0.0.0.0 feedback.microsoft-hohm.com
echo 0.0.0.0 feedback.search.microsoft.com
echo.
echo # Advertising
echo 0.0.0.0 rad.msn.com
echo 0.0.0.0 preview.msn.com
echo 0.0.0.0 ad.doubleclick.net
echo 0.0.0.0 ads.msn.com
echo 0.0.0.0 ads1.msads.net
echo 0.0.0.0 ads1.msn.com
echo 0.0.0.0 a.ads1.msn.com
echo 0.0.0.0 a.ads2.msn.com
echo 0.0.0.0 adnexus.net
echo 0.0.0.0 adnxs.com
echo.
echo # ============================================================================
) >> "%HOSTS_FILE%"

:done
echo.
echo ============================================================================
echo  Hosts file updated successfully!
echo ============================================================================
echo.
echo A backup was saved to: %HOSTS_FILE%.backup
echo.
echo To flush DNS cache and apply changes immediately, run:
echo   ipconfig /flushdns
echo.
echo To undo these changes, restore from backup or manually edit the hosts file.
echo.

:: Flush DNS cache
echo Flushing DNS cache...
ipconfig /flushdns >nul 2>&1

echo Done!
echo.

pause
