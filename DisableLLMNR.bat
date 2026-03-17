@echo off
setlocal enabledelayedexpansion
title Disable LLMNR / mDNS / WPAD
color 0B
chcp 65001 >nul 2>nul

:: ============================================================================
:: Script Name: DisableLLMNR.bat
:: Purpose: Disable LLMNR, mDNS, and WPAD to prevent name-resolution
::          poisoning attacks (Responder, mitm6, WPAD proxy hijack).
:: ============================================================================
:: LLMNR (Link-Local Multicast Name Resolution) and mDNS (Multicast DNS)
:: are fallback name resolution protocols. When DNS fails, Windows broadcasts
:: "who has this name?" to the local network. An attacker on the same subnet
:: can reply with their own IP, capturing credentials (NTLMv2 hashes) or
:: redirecting traffic. Tools like Responder and mitm6 exploit this trivially.
::
:: WPAD (Web Proxy Auto-Discovery) makes Windows query for a proxy config
:: at "wpad.<domain>". An attacker who responds first can intercept all
:: HTTP traffic through a rogue proxy.
::
:: Disabling all three closes the most common internal network poisoning
:: vectors while DNS continues to work normally.
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
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Disable LLMNR / mDNS / WPAD%RESET%                                            %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%Prevent name-resolution poisoning on the local network%RESET%               %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
title [1/5] Disable LLMNR/mDNS/WPAD - Checking current state...

:: ========================================================================
:: Phase 1: Show current status
:: ========================================================================

echo   %BOLD%%WHITE%Current Status%RESET%
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/

:: Check LLMNR
set "LLMNR_STATUS=Enabled (default)"
set "LLMNR_COLOR=%RED%"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast 2^>nul ^| findstr EnableMulticast') do (
        if "%%a"=="0x0" (
            set "LLMNR_STATUS=Disabled"
            set "LLMNR_COLOR=%GREEN%"
        )
    )
)
echo   LLMNR:  !LLMNR_COLOR!!LLMNR_STATUS!%RESET%

:: Check mDNS
set "MDNS_STATUS=Enabled (default)"
set "MDNS_COLOR=%RED%"
reg query "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableMDNS >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableMDNS 2^>nul ^| findstr EnableMDNS') do (
        if "%%a"=="0x0" (
            set "MDNS_STATUS=Disabled"
            set "MDNS_COLOR=%GREEN%"
        )
    )
)
echo   mDNS:   !MDNS_COLOR!!MDNS_STATUS!%RESET%

:: Check WPAD
set "WPAD_STATUS=Enabled (default)"
set "WPAD_COLOR=%RED%"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" /v WpadOverride >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" /v WpadOverride 2^>nul ^| findstr WpadOverride') do (
        if "%%a"=="0x1" (
            set "WPAD_STATUS=Disabled"
            set "WPAD_COLOR=%GREEN%"
        )
    )
)
echo   WPAD:   !WPAD_COLOR!!WPAD_STATUS!%RESET%

:: Check WinHTTP AutoProxy
set "WINHTTP_STATUS=Enabled (default)"
set "WINHTTP_COLOR=%RED%"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v DisableWpad >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v DisableWpad 2^>nul ^| findstr DisableWpad') do (
        if "%%a"=="0x1" (
            set "WINHTTP_STATUS=Disabled"
            set "WINHTTP_COLOR=%GREEN%"
        )
    )
)
echo   WinHTTP AutoProxy: !WINHTTP_COLOR!!WINHTTP_STATUS!%RESET%

echo/
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/
echo   %BOLD%%WHITE%What this script does:%RESET%
echo/
echo     %DIM%1.%RESET% Disables %BOLD%LLMNR%RESET% via Group Policy registry key
echo     %DIM%2.%RESET% Disables %BOLD%mDNS%RESET% via DNS Client registry key
echo     %DIM%3.%RESET% Disables %BOLD%WPAD%RESET% via Internet Settings and WinHTTP registry keys
echo     %DIM%4.%RESET% Disables %BOLD%auto-proxy detection%RESET% in Internet Options
echo     %DIM%5.%RESET% Adds firewall rules blocking mDNS (UDP 5353) and LLMNR (UDP 5355)
echo/
echo   %YELLOW%NOTE: If you use Bonjour (iTunes, AirPlay), Chromecast discovery,
echo   or a corporate proxy via auto-detect, some of these may be needed.
echo   Standard DNS resolution is NOT affected.%RESET%
echo/

set /p "confirm=  Disable LLMNR, mDNS, and WPAD? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo/
    echo   Operation cancelled.
    pause
    exit /b 0
)

echo/

:: ========================================================================
:: Phase 2: Disable LLMNR
:: ========================================================================

title [2/5] Disable LLMNR/mDNS/WPAD - Disabling LLMNR...

echo   %BOLD%%WHITE%Disabling LLMNR...%RESET%
echo/

:: Create the policy key if it doesn't exist
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% LLMNR disabled via Group Policy %DIM%(EnableMulticast = 0)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not set LLMNR registry key
)

echo/

:: ========================================================================
:: Phase 3: Disable mDNS
:: ========================================================================

title [3/5] Disable LLMNR/mDNS/WPAD - Disabling mDNS...

echo   %BOLD%%WHITE%Disabling mDNS...%RESET%
echo/

reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableMDNS /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% mDNS disabled %DIM%(EnableMDNS = 0)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not set mDNS registry key
)

echo/

:: ========================================================================
:: Phase 4: Disable WPAD
:: ========================================================================

title [4/5] Disable LLMNR/mDNS/WPAD - Disabling WPAD...

echo   %BOLD%%WHITE%Disabling WPAD...%RESET%
echo/

:: Disable WPAD override for current user
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" /v WpadOverride /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% WPAD override set %DIM%(WpadOverride = 1)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not set WPAD override key
)

:: Disable WinHTTP auto-proxy
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v DisableWpad /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% WinHTTP WPAD disabled %DIM%(DisableWpad = 1)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not set WinHTTP WPAD key
)

:: Disable "Automatically detect settings" in Internet Options
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Auto-detect proxy disabled %DIM%(AutoDetect = 0)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not set AutoDetect key
)

:: Disable WinHTTP autoproxy service
sc config WinHttpAutoProxySvc start= disabled >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% WinHTTP Auto-Proxy service set to disabled
) else (
    echo   %YELLOW%[SKIP]%RESET% Could not configure WinHTTP Auto-Proxy service
)

sc stop WinHttpAutoProxySvc >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% WinHTTP Auto-Proxy service stopped
) else (
    echo   %DIM%[--]%RESET% Service was not running or could not be stopped now
)

echo/

:: ========================================================================
:: Phase 5: Firewall rules
:: ========================================================================

title [5/5] Disable LLMNR/mDNS/WPAD - Adding firewall rules...

echo   %BOLD%%WHITE%Adding firewall block rules...%RESET%
echo/

:: Remove existing rules first (idempotent)
netsh advfirewall firewall delete rule name="Block LLMNR (UDP 5355)" >nul 2>&1
netsh advfirewall firewall delete rule name="Block mDNS (UDP 5353)" >nul 2>&1

:: Block LLMNR (UDP 5355)
netsh advfirewall firewall add rule name="Block LLMNR (UDP 5355)" dir=in action=block protocol=UDP localport=5355 >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Blocked inbound UDP 5355 %DIM%(LLMNR)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not add rule for UDP 5355
)

:: Block outbound LLMNR too (prevents this machine from querying)
netsh advfirewall firewall delete rule name="Block LLMNR outbound (UDP 5355)" >nul 2>&1
netsh advfirewall firewall add rule name="Block LLMNR outbound (UDP 5355)" dir=out action=block protocol=UDP remoteport=5355 >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Blocked outbound UDP 5355 %DIM%(LLMNR queries)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not add outbound rule for UDP 5355
)

:: Block mDNS (UDP 5353)
netsh advfirewall firewall add rule name="Block mDNS (UDP 5353)" dir=in action=block protocol=UDP localport=5353 >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Blocked inbound UDP 5353 %DIM%(mDNS)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not add rule for UDP 5353
)

netsh advfirewall firewall delete rule name="Block mDNS outbound (UDP 5353)" >nul 2>&1
netsh advfirewall firewall add rule name="Block mDNS outbound (UDP 5353)" dir=out action=block protocol=UDP remoteport=5353 >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Blocked outbound UDP 5353 %DIM%(mDNS queries)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not add outbound rule for UDP 5353
)

echo/

:: ========================================================================
:: Summary
:: ========================================================================

title Disable LLMNR/mDNS/WPAD - Complete

echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Complete%RESET%                                                                 %CYAN%║%RESET%
echo   %CYAN%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo   %CYAN%║%RESET%  LLMNR, mDNS, and WPAD have been disabled.                             %CYAN%║%RESET%
echo   %CYAN%║%RESET%  Firewall rules block both inbound and outbound on 5353/5355.          %CYAN%║%RESET%
echo   %CYAN%║%RESET%                                                                        %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%A reboot is recommended for full effect.%RESET%                              %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
echo   %BOLD%%WHITE%To undo these changes:%RESET%
echo/
echo     %DIM%1.%RESET% Re-enable LLMNR:
echo        %CYAN%reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /f%RESET%
echo/
echo     %DIM%2.%RESET% Re-enable mDNS:
echo        %CYAN%reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableMDNS /f%RESET%
echo/
echo     %DIM%3.%RESET% Re-enable WPAD:
echo        %CYAN%reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" /v WpadOverride /f%RESET%
echo        %CYAN%reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v DisableWpad /f%RESET%
echo        %CYAN%reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 1 /f%RESET%
echo        %CYAN%sc config WinHttpAutoProxySvc start= demand%RESET%
echo/
echo     %DIM%4.%RESET% Remove firewall rules:
echo        %CYAN%netsh advfirewall firewall delete rule name="Block LLMNR (UDP 5355)"%RESET%
echo        %CYAN%netsh advfirewall firewall delete rule name="Block LLMNR outbound (UDP 5355)"%RESET%
echo        %CYAN%netsh advfirewall firewall delete rule name="Block mDNS (UDP 5353)"%RESET%
echo        %CYAN%netsh advfirewall firewall delete rule name="Block mDNS outbound (UDP 5353)"%RESET%
echo/

pause
