@echo off
setlocal enabledelayedexpansion
title Disable NetBIOS over TCP/IP
color 0B
chcp 65001 >nul 2>nul

:: ============================================================================
:: Script Name: DisableNetBIOS.bat
:: Purpose: Disable NetBIOS over TCP/IP on all network adapters to close
::          ports 137 (NBNS), 138 (NBDatagram), and 139 (NBSession).
:: ============================================================================
:: NetBIOS is a legacy protocol used for file sharing and printer discovery
:: on local networks. Modern Windows uses DNS and SMB directly over TCP 445,
:: making NetBIOS unnecessary in most environments. Disabling it reduces
:: attack surface by closing three ports per adapter.
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
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Disable NetBIOS over TCP/IP%RESET%                                             %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%Close ports 137/138/139 on all network adapters%RESET%                      %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
title [1/4] Disable NetBIOS - Scanning adapters...

:: ========================================================================
:: Phase 1: Show current NetBIOS status per adapter
:: ========================================================================

echo   %BOLD%%WHITE%Current NetBIOS Status%RESET%
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/

set "PSSCRIPT=%TEMP%\netbios_status.ps1"

(
echo $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration ^| Where-Object { $_.IPEnabled -eq $true }
echo if (-not $adapters^) {
echo     Write-Host "  No IP-enabled adapters found." -ForegroundColor Yellow
echo     exit
echo }
echo foreach ($a in $adapters^) {
echo     $name = $a.Description
echo     $ips = ($a.IPAddress -join ', '^)
echo     $tcpSetting = $a.TcpipNetbiosOptions
echo     switch ($tcpSetting^) {
echo         0 { $status = 'Default (DHCP-controlled^)'; $color = 'Yellow' }
echo         1 { $status = 'Enabled'; $color = 'Red' }
echo         2 { $status = 'Disabled'; $color = 'Green' }
echo         default { $status = "Unknown ($tcpSetting^)"; $color = 'Yellow' }
echo     }
echo     Write-Host "  Adapter: " -NoNewline
echo     Write-Host "$name" -ForegroundColor Cyan
echo     Write-Host "  IP:      $ips"
echo     Write-Host "  NetBIOS: " -NoNewline
echo     Write-Host "$status" -ForegroundColor $color
echo     Write-Host ""
echo }
) > "%PSSCRIPT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSSCRIPT%"
del "%PSSCRIPT%" >nul 2>nul

echo/
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/
echo   %BOLD%%WHITE%What this script does:%RESET%
echo/
echo     %DIM%1.%RESET% Sets NetBIOS over TCP/IP to %BOLD%Disabled%RESET% on every IP-enabled adapter
echo     %DIM%2.%RESET% Stops and disables the %BOLD%NetBT%RESET% driver service (NetBIOS over TCP/IP)
echo     %DIM%3.%RESET% Stops and disables the %BOLD%lmhosts%RESET% service (TCP/IP NetBIOS Helper)
echo     %DIM%4.%RESET% Adds firewall rules blocking inbound UDP 137-138 and TCP 139
echo/
echo   %YELLOW%NOTE: If you use legacy network shares by hostname (e.g., \\OLDSERVER),
echo   WINS-based printer discovery, or very old applications that rely on
echo   NetBIOS name resolution, do NOT disable NetBIOS.%RESET%
echo/

set /p "confirm=  Disable NetBIOS on all adapters? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo/
    echo   Operation cancelled.
    pause
    exit /b 0
)

echo/

:: ========================================================================
:: Phase 2: Disable NetBIOS per adapter via WMI
:: ========================================================================

title [2/4] Disable NetBIOS - Configuring adapters...

echo   %BOLD%%WHITE%Disabling NetBIOS on adapters...%RESET%
echo/

set "PSSCRIPT=%TEMP%\netbios_disable.ps1"

(
echo $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration ^| Where-Object { $_.IPEnabled -eq $true }
echo $changed = 0
echo $failed = 0
echo foreach ($a in $adapters^) {
echo     $name = $a.Description
echo     Write-Host "  [$name] " -NoNewline
echo     if ($a.TcpipNetbiosOptions -eq 2^) {
echo         Write-Host "Already disabled" -ForegroundColor DarkGray
echo     } else {
echo         $result = $a.SetTcpipNetbios(2^)
echo         if ($result.ReturnValue -eq 0^) {
echo             Write-Host "Disabled" -ForegroundColor Green
echo             $changed++
echo         } else {
echo             Write-Host "Failed (code $($result.ReturnValue^)^)" -ForegroundColor Red
echo             $failed++
echo         }
echo     }
echo }
echo Write-Host ""
echo if ($changed -gt 0^) { Write-Host "  $changed adapter(s^) updated." -ForegroundColor Green }
echo if ($failed -gt 0^) { Write-Host "  $failed adapter(s^) failed." -ForegroundColor Red }
) > "%PSSCRIPT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSSCRIPT%"
del "%PSSCRIPT%" >nul 2>nul
echo/

:: ========================================================================
:: Phase 3: Disable NetBT driver and lmhosts service
:: ========================================================================

title [3/4] Disable NetBIOS - Stopping services...

echo   %BOLD%%WHITE%Disabling NetBIOS services...%RESET%
echo/

:: Disable the NetBT driver (NetBIOS over TCP/IP transport)
sc config NetBT start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% NetBT driver set to disabled
) else (
    echo   %YELLOW%[SKIP]%RESET% Could not configure NetBT driver
)

:: Stop NetBT if running
sc stop NetBT >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% NetBT driver stopped
) else (
    echo   %DIM%[--]%RESET% NetBT was not running or could not be stopped now
)

:: Disable lmhosts (TCP/IP NetBIOS Helper)
sc config lmhosts start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% lmhosts service set to disabled
) else (
    echo   %YELLOW%[SKIP]%RESET% Could not configure lmhosts service
)

sc stop lmhosts >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% lmhosts service stopped
) else (
    echo   %DIM%[--]%RESET% lmhosts was not running or could not be stopped now
)

echo/

:: ========================================================================
:: Phase 4: Add firewall rules to block NetBIOS ports
:: ========================================================================

title [4/4] Disable NetBIOS - Adding firewall rules...

echo   %BOLD%%WHITE%Adding firewall block rules...%RESET%
echo/

:: Remove existing rules first (idempotent)
netsh advfirewall firewall delete rule name="Block NetBIOS-NS (UDP 137)" >nul 2>&1
netsh advfirewall firewall delete rule name="Block NetBIOS-DGM (UDP 138)" >nul 2>&1
netsh advfirewall firewall delete rule name="Block NetBIOS-SSN (TCP 139)" >nul 2>&1

:: Block inbound UDP 137 (NetBIOS Name Service)
netsh advfirewall firewall add rule name="Block NetBIOS-NS (UDP 137)" dir=in action=block protocol=UDP localport=137 >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Blocked inbound UDP 137 %DIM%(NetBIOS Name Service)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not add rule for UDP 137
)

:: Block inbound UDP 138 (NetBIOS Datagram)
netsh advfirewall firewall add rule name="Block NetBIOS-DGM (UDP 138)" dir=in action=block protocol=UDP localport=138 >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Blocked inbound UDP 138 %DIM%(NetBIOS Datagram)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not add rule for UDP 138
)

:: Block inbound TCP 139 (NetBIOS Session)
netsh advfirewall firewall add rule name="Block NetBIOS-SSN (TCP 139)" dir=in action=block protocol=TCP localport=139 >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Blocked inbound TCP 139 %DIM%(NetBIOS Session)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not add rule for TCP 139
)

echo/

:: ========================================================================
:: Summary
:: ========================================================================

title Disable NetBIOS - Complete

echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Complete%RESET%                                                                 %CYAN%║%RESET%
echo   %CYAN%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo   %CYAN%║%RESET%  NetBIOS has been disabled on all adapters.                            %CYAN%║%RESET%
echo   %CYAN%║%RESET%  Ports 137, 138, and 139 are now blocked by firewall rules.            %CYAN%║%RESET%
echo   %CYAN%║%RESET%                                                                        %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%A reboot is recommended for full effect.%RESET%                              %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
echo   %BOLD%%WHITE%To undo these changes:%RESET%
echo/
echo     %DIM%1.%RESET% Re-enable NetBIOS per adapter:
echo        %DIM%PowerShell (admin):%RESET%
echo        %CYAN%Get-WmiObject Win32_NetworkAdapterConfiguration ^| Where {$_.IPEnabled} ^| ForEach { $_.SetTcpipNetbios(0) }%RESET%
echo/
echo     %DIM%2.%RESET% Re-enable services:
echo        %CYAN%sc config NetBT start= system%RESET%
echo        %CYAN%sc config lmhosts start= auto%RESET%
echo        %CYAN%sc start lmhosts%RESET%
echo/
echo     %DIM%3.%RESET% Remove firewall rules:
echo        %CYAN%netsh advfirewall firewall delete rule name="Block NetBIOS-NS (UDP 137)"%RESET%
echo        %CYAN%netsh advfirewall firewall delete rule name="Block NetBIOS-DGM (UDP 138)"%RESET%
echo        %CYAN%netsh advfirewall firewall delete rule name="Block NetBIOS-SSN (TCP 139)"%RESET%
echo/

pause
