@echo off
setlocal enabledelayedexpansion
title Harden SMB
color 0B
chcp 65001 >nul 2>nul

:: ============================================================================
:: Script Name: HardenSMB.bat
:: Purpose: Harden SMB 2.0/3.0 by requiring packet signing and encryption,
::          disabling SMB compression (CVE-2020-0796), and restricting
::          guest/null-session access.
:: ============================================================================
:: SMB1 removal is handled by windows-debloat/06-Remove-Features.bat.
:: This script hardens the REMAINING SMB 2.0/3.0 stack by enforcing:
::   - Packet signing (prevents relay and tampering attacks)
::   - Encryption (prevents eavesdropping on file transfers)
::   - No guest fallback (prevents unauthenticated access)
::   - No SMB compression (mitigates SMBGhost CVE-2020-0796)
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
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Harden SMB 2.0 / 3.0%RESET%                                                     %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%Enforce signing, encryption, and disable guest access%RESET%                %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
title [1/4] Harden SMB - Checking current configuration...

:: ========================================================================
:: Phase 1: Show current SMB status
:: ========================================================================

echo   %BOLD%%WHITE%Current SMB Configuration%RESET%
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/

set "PSSCRIPT=%TEMP%\smb_status.ps1"

(
echo # Check SMB server config
echo $server = Get-SmbServerConfiguration -ErrorAction SilentlyContinue
echo if ^($server^) {
echo     function Show-Setting^($name, $value, $desired^) {
echo         $color = if ^($value -eq $desired^) { 'Green' } else { 'Red' }
echo         $mark = if ^($value -eq $desired^) { '[OK]' } else { '[^^!^^!]' }
echo         Write-Host "  $mark $name : " -NoNewline -ForegroundColor $color
echo         Write-Host "$value" -ForegroundColor $color
echo     }
echo     Write-Host "  SMB Server Settings:" -ForegroundColor White
echo     Write-Host ""
echo     Show-Setting "SMB1 Protocol         " $server.EnableSMB1Protocol $false
echo     Show-Setting "SMB2 Protocol         " $server.EnableSMB2Protocol $true
echo     Show-Setting "Require Signing       " $server.RequireSecuritySignature $true
echo     Show-Setting "Enable Signing        " $server.EnableSecuritySignature $true
echo     Show-Setting "Encrypt Data          " $server.EncryptData $true
echo     Show-Setting "Reject Unencrypted    " $server.RejectUnencryptedAccess $true
echo     Show-Setting "Enable Insecure Guest " $server.EnableInsecureGuestLogons $false
echo     Write-Host ""
echo     if ^($server.DisableCompression -ne $null^) {
echo         Show-Setting "Disable Compression   " $server.DisableCompression $true
echo     }
echo } else {
echo     Write-Host "  Could not query SMB server configuration." -ForegroundColor Yellow
echo     Write-Host "  ^(SMB Server service may not be running.^)" -ForegroundColor DarkGray
echo }
echo Write-Host ""
echo # Check SMB client config
echo $client = Get-SmbClientConfiguration -ErrorAction SilentlyContinue
echo if ^($client^) {
echo     Write-Host "  SMB Client Settings:" -ForegroundColor White
echo     Write-Host ""
echo     function Show-ClientSetting^($name, $value, $desired^) {
echo         $color = if ^($value -eq $desired^) { 'Green' } else { 'Red' }
echo         $mark = if ^($value -eq $desired^) { '[OK]' } else { '[^^!^^!]' }
echo         Write-Host "  $mark $name : " -NoNewline -ForegroundColor $color
echo         Write-Host "$value" -ForegroundColor $color
echo     }
echo     Show-ClientSetting "Require Signing       " $client.RequireSecuritySignature $true
echo     Show-ClientSetting "Enable Signing        " $client.EnableSecuritySignature $true
echo     Show-ClientSetting "Enable Insecure Guest " $client.EnableInsecureGuestLogons $false
echo }
) > "%PSSCRIPT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSSCRIPT%"
del "%PSSCRIPT%" >nul 2>nul

echo/
echo   %CYAN%────────────────────────────────────────────────────────────────────────%RESET%
echo/
echo   %BOLD%%WHITE%What this script does:%RESET%
echo/
echo     %DIM%1.%RESET% Requires SMB %BOLD%packet signing%RESET% on both server and client
echo     %DIM%2.%RESET% Enables SMB %BOLD%encryption%RESET% and rejects unencrypted access
echo     %DIM%3.%RESET% Disables %BOLD%insecure guest logons%RESET% (no unauthenticated access)
echo     %DIM%4.%RESET% Disables %BOLD%SMB compression%RESET% (mitigates SMBGhost CVE-2020-0796)
echo     %DIM%5.%RESET% Blocks %BOLD%null session%RESET% enumeration via registry
echo/
echo   %YELLOW%NOTE: Requiring signing and encryption may break access to very old
echo   NAS devices or Linux Samba shares running outdated versions. Modern
echo   NAS firmware and Samba 4.2+ support signing; Samba 4.11+ supports
echo   encryption. Windows-to-Windows file sharing is fully compatible.%RESET%
echo/

set /p "confirm=  Apply SMB hardening? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo/
    echo   Operation cancelled.
    pause
    exit /b 0
)

echo/

:: ========================================================================
:: Phase 2: SMB Server hardening
:: ========================================================================

title [2/4] Harden SMB - Configuring server...

echo   %BOLD%%WHITE%Hardening SMB Server...%RESET%
echo/

set "PSSCRIPT=%TEMP%\smb_harden_server.ps1"

(
echo $ErrorActionPreference = 'Stop'
echo try {
echo     # Require signing on server side
echo     Set-SmbServerConfiguration -RequireSecuritySignature $true -EnableSecuritySignature $true -Confirm:$false
echo     Write-Host "  [OK] SMB server signing required" -ForegroundColor Green
echo } catch {
echo     Write-Host "  [FAIL] Could not configure SMB server signing: $_" -ForegroundColor Red
echo }
echo try {
echo     # Enable encryption and reject unencrypted
echo     Set-SmbServerConfiguration -EncryptData $true -RejectUnencryptedAccess $true -Confirm:$false
echo     Write-Host "  [OK] SMB server encryption enabled, unencrypted rejected" -ForegroundColor Green
echo } catch {
echo     Write-Host "  [FAIL] Could not configure SMB encryption: $_" -ForegroundColor Red
echo }
echo try {
echo     # Disable insecure guest logons
echo     Set-SmbServerConfiguration -EnableInsecureGuestLogons $false -Confirm:$false 2^>$null
echo     Write-Host "  [OK] Insecure guest logons disabled ^(server^)" -ForegroundColor Green
echo } catch {
echo     Write-Host "  [SKIP] EnableInsecureGuestLogons not available on server config" -ForegroundColor DarkGray
echo }
echo # Disable SMB compression ^(SMBGhost mitigation^)
echo try {
echo     Set-SmbServerConfiguration -DisableCompression $true -Confirm:$false 2^>$null
echo     Write-Host "  [OK] SMB compression disabled ^(SMBGhost mitigation^)" -ForegroundColor Green
echo } catch {
echo     Write-Host "  [SKIP] SMB compression setting not available on this version" -ForegroundColor DarkGray
echo }
) > "%PSSCRIPT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSSCRIPT%"
del "%PSSCRIPT%" >nul 2>nul
echo/

:: ========================================================================
:: Phase 3: SMB Client hardening
:: ========================================================================

title [3/4] Harden SMB - Configuring client...

echo   %BOLD%%WHITE%Hardening SMB Client...%RESET%
echo/

set "PSSCRIPT=%TEMP%\smb_harden_client.ps1"

(
echo $ErrorActionPreference = 'Stop'
echo try {
echo     # Require signing on client side
echo     Set-SmbClientConfiguration -RequireSecuritySignature $true -EnableSecuritySignature $true -Confirm:$false
echo     Write-Host "  [OK] SMB client signing required" -ForegroundColor Green
echo } catch {
echo     Write-Host "  [FAIL] Could not configure SMB client signing: $_" -ForegroundColor Red
echo }
echo try {
echo     # Disable insecure guest logons on client
echo     Set-SmbClientConfiguration -EnableInsecureGuestLogons $false -Confirm:$false
echo     Write-Host "  [OK] Insecure guest logons disabled ^(client^)" -ForegroundColor Green
echo } catch {
echo     Write-Host "  [FAIL] Could not disable insecure guest logons: $_" -ForegroundColor Red
echo }
) > "%PSSCRIPT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSSCRIPT%"
del "%PSSCRIPT%" >nul 2>nul
echo/

:: ========================================================================
:: Phase 4: Registry hardening (null sessions, anonymous access)
:: ========================================================================

title [4/4] Harden SMB - Registry hardening...

echo   %BOLD%%WHITE%Applying registry hardening...%RESET%
echo/

:: Restrict anonymous enumeration of SAM accounts
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymousSAM /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Anonymous SAM enumeration restricted
) else (
    echo   %RED%[FAIL]%RESET% Could not restrict anonymous SAM enumeration
)

:: Restrict anonymous enumeration of shares
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymous /t REG_DWORD /d 1 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Anonymous share enumeration restricted
) else (
    echo   %RED%[FAIL]%RESET% Could not restrict anonymous share enumeration
)

:: Disable null session pipes
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" /v NullSessionPipes /t REG_MULTI_SZ /d "" /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Null session pipes cleared
) else (
    echo   %RED%[FAIL]%RESET% Could not clear null session pipes
)

:: Disable null session shares
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" /v NullSessionShares /t REG_MULTI_SZ /d "" /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% Null session shares cleared
) else (
    echo   %RED%[FAIL]%RESET% Could not clear null session shares
)

:: Require NTLMv2 (disable LM and NTLMv1)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 5 /f >nul 2>&1
if %errorlevel% equ 0 (
    echo   %GREEN%[OK]%RESET% LAN Manager auth set to NTLMv2 only %DIM%(LmCompatibilityLevel = 5)%RESET%
) else (
    echo   %RED%[FAIL]%RESET% Could not set LAN Manager auth level
)

echo/

:: ========================================================================
:: Summary
:: ========================================================================

title Harden SMB - Complete

echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Complete%RESET%                                                                 %CYAN%║%RESET%
echo   %CYAN%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo   %CYAN%║%RESET%  SMB signing and encryption enforced on server and client.             %CYAN%║%RESET%
echo   %CYAN%║%RESET%  Guest logons, null sessions, and LM/NTLMv1 auth disabled.            %CYAN%║%RESET%
echo   %CYAN%║%RESET%  SMB compression disabled (SMBGhost mitigation).                      %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
echo   %BOLD%%WHITE%To undo these changes:%RESET%
echo/
echo     %DIM%1.%RESET% Revert SMB server settings (PowerShell admin):
echo        %CYAN%Set-SmbServerConfiguration -RequireSecuritySignature $false -EncryptData $false -RejectUnencryptedAccess $false -Confirm:$false%RESET%
echo/
echo     %DIM%2.%RESET% Revert SMB client settings (PowerShell admin):
echo        %CYAN%Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableInsecureGuestLogons $true -Confirm:$false%RESET%
echo/
echo     %DIM%3.%RESET% Revert registry keys:
echo        %CYAN%reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymousSAM /t REG_DWORD /d 0 /f%RESET%
echo        %CYAN%reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymous /t REG_DWORD /d 0 /f%RESET%
echo        %CYAN%reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 3 /f%RESET%
echo/

pause
