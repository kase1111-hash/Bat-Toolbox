@echo off
setlocal enabledelayedexpansion
title Open Port Scanner
color 0B

:: ============================================================================
:: Open Port Scanner
:: ============================================================================
:: Shows all listening ports, resolves PIDs to process names, flags known-
:: suspicious ports, and highlights unexpected services on 0.0.0.0.
:: A lightweight local audit without installing Nmap.
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
echo %CYAN% Open Port Scanner%RESET%
echo %CYAN%============================================================================%RESET%
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%[WARNING] Running without admin. Some process names may show as "Unknown".%RESET%
    echo %YELLOW%For full results, right-click and select "Run as administrator".%RESET%
    echo.
)

echo This script scans all listening ports on your system and flags
echo suspicious or unexpected services.
echo.
echo %YELLOW%This is a read-only audit. No changes will be made.%RESET%
echo.

set /p "confirm=Start the port scan? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo.
    echo Operation cancelled.
    pause
    exit /b 0
)

:: Set up report file
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value ^| find "="') do set "dt=%%I"
set "REPORT=%USERPROFILE%\Desktop\PortScan_%COMPUTERNAME%_%dt:~0,8%.txt"

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 1: Scanning Listening Ports%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [1/4] Gathering all listening TCP ports...
echo.

:: Header
echo %WHITE%  PROTO  LOCAL ADDRESS                PORT    PID     PROCESS              STATUS%RESET%
echo   -----  ---------------------------  ------  ------  -------------------  --------

:: Write report header
(
echo ============================================================================
echo  Open Port Scanner Report
echo  Computer: %COMPUTERNAME%
echo  Date: %dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%:%dt:~12,2%
echo ============================================================================
echo.
echo PROTO  LOCAL ADDRESS                PORT    PID     PROCESS              STATUS
echo -----  ---------------------------  ------  ------  -------------------  --------
) > "%REPORT%"

set "totalPorts=0"
set "suspiciousPorts=0"
set "wildcardPorts=0"
set "highRiskPorts=0"

:: Create temp PowerShell script for detailed port scanning
set "PSSCRIPT=%TEMP%\portscan.ps1"

(
echo # Get all listening TCP connections with process info
echo $listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue ^| Sort-Object LocalPort
echo.
echo # Known suspicious ports
echo $suspiciousPorts = @{
echo     4444 = 'Metasploit/Meterpreter default'
echo     4445 = 'Metasploit alt'
echo     5555 = 'Android ADB / potential backdoor'
echo     6666 = 'IRC backdoor common'
echo     6667 = 'IRC C2 common'
echo     1337 = 'Common backdoor port'
echo     31337 = 'Back Orifice'
echo     12345 = 'NetBus trojan'
echo     27374 = 'SubSeven trojan'
echo     1234 = 'Common backdoor'
echo     9999 = 'Common backdoor'
echo     8888 = 'Common backdoor/proxy'
echo     4443 = 'Common C2 alt-HTTPS'
echo     8443 = 'Alt-HTTPS sometimes suspicious'
echo     2222 = 'Alt-SSH sometimes suspicious'
echo     3127 = 'MyDoom worm'
echo     5900 = 'VNC (check if intentional)'
echo     5901 = 'VNC alt'
echo     3389 = 'RDP (check if intentional)'
echo     23   = 'Telnet (insecure)'
echo     21   = 'FTP (insecure if unintended)'
echo     1433 = 'SQL Server (check exposure)'
echo     3306 = 'MySQL (check exposure)'
echo     5432 = 'PostgreSQL (check exposure)'
echo     27017 = 'MongoDB (check exposure)'
echo     6379 = 'Redis (check exposure)'
echo     11211 = 'Memcached (check exposure)'
echo     9200 = 'Elasticsearch (check exposure)'
echo     2375 = 'Docker unencrypted API'
echo     2376 = 'Docker TLS API'
echo }
echo.
echo # Known safe system ports
echo $safePorts = @{
echo     135 = 'Windows RPC'
echo     139 = 'NetBIOS Session'
echo     445 = 'SMB/CIFS'
echo     902 = 'VMware'
echo     912 = 'VMware'
echo     49664 = 'Windows Dynamic RPC'
echo     49665 = 'Windows Dynamic RPC'
echo     49666 = 'Windows Dynamic RPC'
echo     49667 = 'Windows Dynamic RPC'
echo     49668 = 'Windows Dynamic RPC'
echo     49669 = 'Windows Dynamic RPC'
echo     49670 = 'Windows Dynamic RPC'
echo }
echo.
echo $totalPorts = 0
echo $suspiciousCount = 0
echo $wildcardCount = 0
echo $highRiskCount = 0
echo $results = @(^)
echo.
echo foreach ^($conn in $listeners^) {
echo     $totalPorts++
echo     $port = $conn.LocalPort
echo     $addr = $conn.LocalAddress
echo     $pid = $conn.OwningProcess
echo     $procName = 'Unknown'
echo.
echo     try {
echo         $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
echo         if ^($proc^) { $procName = $proc.ProcessName }
echo     } catch {}
echo.
echo     $status = 'OK'
echo     $color = 'Green'
echo     $isWildcard = ^($addr -eq '0.0.0.0' -or $addr -eq '::'^)
echo.
echo     # Check suspicious ports
echo     if ^($suspiciousPorts.ContainsKey^($port^)^) {
echo         $status = "SUSPICIOUS - $($suspiciousPorts[$port])"
echo         $color = 'Red'
echo         $suspiciousCount++
echo         if ^($port -in @(4444,4445,6666,6667,1337,31337,12345,27374,3127^)^) {
echo             $highRiskCount++
echo             $status = "HIGH RISK - $($suspiciousPorts[$port])"
echo         }
echo     }
echo     # Check wildcard listeners
echo     elseif ^($isWildcard -and -not $safePorts.ContainsKey^($port^) -and $port -lt 49152^) {
echo         $status = 'WILDCARD - exposed on all interfaces'
echo         $color = 'Yellow'
echo         $wildcardCount++
echo     }
echo.
echo     if ^($isWildcard^) {
echo         $addrDisplay = if ^($addr -eq '::''^) { '[::]' } else { $addr }
echo     } else {
echo         $addrDisplay = $addr
echo     }
echo.
echo     $fullAddr = "${addrDisplay}:${port}"
echo.
echo     $obj = [PSCustomObject]@{
echo         Proto = 'TCP'
echo         Address = $fullAddr
echo         Port = $port
echo         PID = $pid
echo         Process = $procName
echo         Status = $status
echo         Color = $color
echo     }
echo     $results += $obj
echo.
echo     # Console output with color
echo     $portStr = $port.ToString^(^).PadRight^(8^)
echo     $pidStr = $pid.ToString^(^).PadRight^(8^)
echo     $procStr = $procName.PadRight^(21^)
echo     $addrStr = $fullAddr.PadRight^(29^)
echo.
echo     switch ^($color^) {
echo         'Red'    { Write-Host "  TCP    $addrStr $portStr $pidStr $procStr " -NoNewline; Write-Host "$status" -ForegroundColor Red }
echo         'Yellow' { Write-Host "  TCP    $addrStr $portStr $pidStr $procStr " -NoNewline; Write-Host "$status" -ForegroundColor Yellow }
echo         'Green'  { Write-Host "  TCP    $addrStr $portStr $pidStr $procStr $status" }
echo     }
echo }
echo.
echo # Also check UDP listeners
echo Write-Host ""
echo Write-Host "  Scanning UDP listeners..." -ForegroundColor Cyan
echo Write-Host ""
echo.
echo $udpListeners = Get-NetUDPEndpoint -ErrorAction SilentlyContinue ^| Sort-Object LocalPort
echo foreach ^($udp in $udpListeners^) {
echo     $port = $udp.LocalPort
echo     $addr = $udp.LocalAddress
echo     $pid = $udp.OwningProcess
echo     $procName = 'Unknown'
echo.
echo     try {
echo         $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
echo         if ^($proc^) { $procName = $proc.ProcessName }
echo     } catch {}
echo.
echo     $isWildcard = ^($addr -eq '0.0.0.0' -or $addr -eq '::'^)
echo     $status = 'OK'
echo     $color = 'Green'
echo.
echo     if ^($suspiciousPorts.ContainsKey^($port^)^) {
echo         $status = "SUSPICIOUS - $($suspiciousPorts[$port])"
echo         $color = 'Red'
echo         $suspiciousCount++
echo     }
echo     elseif ^($isWildcard -and $port -lt 49152 -and $port -notin @(123,137,138,500,3702,4500,5050,5353,5355^)^) {
echo         $status = 'WILDCARD - exposed on all interfaces'
echo         $color = 'Yellow'
echo         $wildcardCount++
echo     }
echo.
echo     $addrDisplay = if ^($addr -eq '::'^) { '[::]' } else { $addr }
echo     $fullAddr = "${addrDisplay}:${port}"
echo     $portStr = $port.ToString^(^).PadRight^(8^)
echo     $pidStr = $pid.ToString^(^).PadRight^(8^)
echo     $procStr = $procName.PadRight^(21^)
echo     $addrStr = $fullAddr.PadRight^(29^)
echo.
echo     $totalPorts++
echo.
echo     switch ^($color^) {
echo         'Red'    { Write-Host "  UDP    $addrStr $portStr $pidStr $procStr " -NoNewline; Write-Host "$status" -ForegroundColor Red }
echo         'Yellow' { Write-Host "  UDP    $addrStr $portStr $pidStr $procStr " -NoNewline; Write-Host "$status" -ForegroundColor Yellow }
echo         'Green'  { Write-Host "  UDP    $addrStr $portStr $pidStr $procStr $status" }
echo     }
echo.
echo     $obj = [PSCustomObject]@{
echo         Proto = 'UDP'
echo         Address = $fullAddr
echo         Port = $port
echo         PID = $pid
echo         Process = $procName
echo         Status = $status
echo         Color = $color
echo     }
echo     $results += $obj
echo }
echo.
echo # Write summary counts to temp file for batch script to read
echo "$totalPorts" ^| Out-File -FilePath "$env:TEMP\portscan_total.txt" -Encoding ascii
echo "$suspiciousCount" ^| Out-File -FilePath "$env:TEMP\portscan_suspicious.txt" -Encoding ascii
echo "$wildcardCount" ^| Out-File -FilePath "$env:TEMP\portscan_wildcard.txt" -Encoding ascii
echo "$highRiskCount" ^| Out-File -FilePath "$env:TEMP\portscan_highrisk.txt" -Encoding ascii
echo.
echo # Write full results to report
echo $results ^| ForEach-Object {
echo     $line = "$($_.Proto.PadRight(7))$($_.Address.PadRight(29))$($_.Port.ToString().PadRight(8))$($_.PID.ToString().PadRight(8))$($_.Process.PadRight(21))$($_.Status)"
echo     $line
echo } ^| Out-File -FilePath "$env:TEMP\portscan_results.txt" -Encoding ascii
) > "%PSSCRIPT%"

powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%" 2>nul

:: Read results back
if exist "%TEMP%\portscan_results.txt" (
    type "%TEMP%\portscan_results.txt" >> "%REPORT%"
    del "%TEMP%\portscan_results.txt" 2>nul
)

:: Read counts
set "totalPorts=0"
set "suspiciousPorts=0"
set "wildcardPorts=0"
set "highRiskPorts=0"

if exist "%TEMP%\portscan_total.txt" (
    set /p totalPorts=<"%TEMP%\portscan_total.txt"
    del "%TEMP%\portscan_total.txt" 2>nul
)
if exist "%TEMP%\portscan_suspicious.txt" (
    set /p suspiciousPorts=<"%TEMP%\portscan_suspicious.txt"
    del "%TEMP%\portscan_suspicious.txt" 2>nul
)
if exist "%TEMP%\portscan_wildcard.txt" (
    set /p wildcardPorts=<"%TEMP%\portscan_wildcard.txt"
    del "%TEMP%\portscan_wildcard.txt" 2>nul
)
if exist "%TEMP%\portscan_highrisk.txt" (
    set /p highRiskPorts=<"%TEMP%\portscan_highrisk.txt"
    del "%TEMP%\portscan_highrisk.txt" 2>nul
)

del "%PSSCRIPT%" 2>nul

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 2: Checking Windows Firewall Status%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [2/4] Checking firewall profile status...
echo.

(echo.) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  FIREWALL STATUS) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"

for %%P in (Domain Standard Public) do (
    netsh advfirewall show %%Pprofile state 2>nul | find /i "ON" >nul 2>&1
    if not errorlevel 1 (
        echo   %GREEN%[ON]  %%P Profile firewall is enabled%RESET%
        (echo [ON]  %%P Profile firewall is enabled) >> "%REPORT%"
    ) else (
        echo   %RED%[OFF] %%P Profile firewall is DISABLED%RESET%
        (echo [OFF] %%P Profile firewall is DISABLED) >> "%REPORT%"
    )
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 3: Checking Remote Access Services%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [3/4] Checking remote access configuration...
echo.

(echo.) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  REMOTE ACCESS STATUS) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"

:: Check RDP
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections 2>nul | find "0x0" >nul 2>&1
if not errorlevel 1 (
    echo   %YELLOW%[WARNING] Remote Desktop (RDP) is ENABLED%RESET%
    echo   %YELLOW%          Listening on port 3389. Ensure this is intentional.%RESET%
    (echo [WARNING] Remote Desktop (RDP) is ENABLED) >> "%REPORT%"
) else (
    echo   %GREEN%[OK] Remote Desktop (RDP) is disabled%RESET%
    (echo [OK] Remote Desktop (RDP) is disabled) >> "%REPORT%"
)

:: Check SSH server
sc query sshd 2>nul | find "RUNNING" >nul 2>&1
if not errorlevel 1 (
    echo   %YELLOW%[WARNING] OpenSSH Server is RUNNING%RESET%
    echo   %YELLOW%          Listening on port 22. Ensure this is intentional.%RESET%
    (echo [WARNING] OpenSSH Server is RUNNING) >> "%REPORT%"
) else (
    echo   %GREEN%[OK] OpenSSH Server is not running%RESET%
    (echo [OK] OpenSSH Server is not running) >> "%REPORT%"
)

:: Check WinRM
sc query WinRM 2>nul | find "RUNNING" >nul 2>&1
if not errorlevel 1 (
    echo   %YELLOW%[WARNING] WinRM (Remote Management) is RUNNING%RESET%
    echo   %YELLOW%          Allows remote PowerShell. Ensure this is intentional.%RESET%
    (echo [WARNING] WinRM (Remote Management) is RUNNING) >> "%REPORT%"
) else (
    echo   %GREEN%[OK] WinRM is not running%RESET%
    (echo [OK] WinRM is not running) >> "%REPORT%"
)

:: Check Telnet
sc query TlntSvr 2>nul | find "RUNNING" >nul 2>&1
if not errorlevel 1 (
    echo   %RED%[ALERT] Telnet Server is RUNNING (insecure!)%RESET%
    echo   %RED%         Telnet transmits in plaintext. Disable immediately.%RESET%
    (echo [ALERT] Telnet Server is RUNNING - insecure!) >> "%REPORT%"
) else (
    echo   %GREEN%[OK] Telnet Server is not running%RESET%
    (echo [OK] Telnet Server is not running) >> "%REPORT%"
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 4: Established Connections Summary%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [4/4] Checking established outbound connections...
echo.

(echo.) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  ESTABLISHED CONNECTIONS) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"

echo %WHITE%  LOCAL ADDRESS              REMOTE ADDRESS             PID     PROCESS%RESET%
echo   -------------------------  -------------------------  ------  -------------------

set "PSESTABLISHED=%TEMP%\portscan_established.ps1"

(
echo $conns = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue ^| Sort-Object RemotePort
echo foreach ^($conn in $conns^) {
echo     $procName = 'Unknown'
echo     try {
echo         $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
echo         if ^($proc^) { $procName = $proc.ProcessName }
echo     } catch {}
echo     $local = "$($conn.LocalAddress):$($conn.LocalPort)"
echo     $remote = "$($conn.RemoteAddress):$($conn.RemotePort)"
echo     $pidStr = $conn.OwningProcess.ToString^(^)
echo     Write-Host "  $($local.PadRight(27)) $($remote.PadRight(27)) $($pidStr.PadRight(8)) $procName"
echo     "$($local.PadRight(27)) $($remote.PadRight(27)) $($pidStr.PadRight(8)) $procName"
echo }
) > "%PSESTABLISHED%"

powershell -ExecutionPolicy Bypass -File "%PSESTABLISHED%" 2>nul >> "%REPORT%"
del "%PSESTABLISHED%" 2>nul

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Summary%RESET%
echo %CYAN%============================================================================%RESET%
echo.

:: Trim whitespace from counts
for /f "tokens=* delims= " %%a in ("!totalPorts!") do set "totalPorts=%%a"
for /f "tokens=* delims= " %%a in ("!suspiciousPorts!") do set "suspiciousPorts=%%a"
for /f "tokens=* delims= " %%a in ("!wildcardPorts!") do set "wildcardPorts=%%a"
for /f "tokens=* delims= " %%a in ("!highRiskPorts!") do set "highRiskPorts=%%a"

echo   Total listening ports:    %totalPorts%
echo   Suspicious ports:         %suspiciousPorts%
echo   Wildcard listeners:       %wildcardPorts%
echo   High-risk ports:          %highRiskPorts%
echo.

(echo.) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  SUMMARY) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo Total listening ports:    %totalPorts%) >> "%REPORT%"
(echo Suspicious ports:         %suspiciousPorts%) >> "%REPORT%"
(echo Wildcard listeners:       %wildcardPorts%) >> "%REPORT%"
(echo High-risk ports:          %highRiskPorts%) >> "%REPORT%"

:: Overall assessment
set "assessment=CLEAN"

if not "!highRiskPorts!"=="0" (
    echo %RED%[CRITICAL] High-risk ports detected! These are commonly used by malware.%RESET%
    echo %RED%           Investigate the processes immediately.%RESET%
    set "assessment=CRITICAL"
    (echo.) >> "%REPORT%"
    (echo ASSESSMENT: CRITICAL - High-risk ports detected) >> "%REPORT%"
) else if not "!suspiciousPorts!"=="0" (
    echo %YELLOW%[WARNING] Suspicious ports detected. Verify these are intentional.%RESET%
    set "assessment=WARNING"
    (echo.) >> "%REPORT%"
    (echo ASSESSMENT: WARNING - Suspicious ports found, verify intentional) >> "%REPORT%"
) else if not "!wildcardPorts!"=="0" (
    echo %YELLOW%[INFO] Some services are listening on all interfaces (0.0.0.0).%RESET%
    echo %YELLOW%       This is normal for some services but verify they are expected.%RESET%
    set "assessment=INFO"
    (echo.) >> "%REPORT%"
    (echo ASSESSMENT: INFO - Wildcard listeners found, verify expected) >> "%REPORT%"
) else (
    echo %GREEN%[OK] No suspicious ports detected. System looks clean.%RESET%
    (echo.) >> "%REPORT%"
    (echo ASSESSMENT: CLEAN - No suspicious ports detected) >> "%REPORT%"
)

echo.
echo %YELLOW%RECOMMENDATIONS:%RESET%
echo  - Investigate any SUSPICIOUS or HIGH RISK entries
echo  - Ensure wildcard listeners (0.0.0.0) are intentional
echo  - Disable RDP/SSH/WinRM if not actively used
echo  - Keep Windows Firewall enabled on all profiles
echo  - Run this scan periodically or after installing new software
echo.
echo Report saved to: %REPORT%
echo.

(echo.) >> "%REPORT%"
(echo RECOMMENDATIONS:) >> "%REPORT%"
(echo  - Investigate any SUSPICIOUS or HIGH RISK entries) >> "%REPORT%"
(echo  - Ensure wildcard listeners are intentional) >> "%REPORT%"
(echo  - Disable RDP/SSH/WinRM if not actively used) >> "%REPORT%"
(echo  - Keep Windows Firewall enabled on all profiles) >> "%REPORT%"

pause
exit /b 0
