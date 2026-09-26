@echo off
setlocal enabledelayedexpansion
title Password Policy Audit
color 0B

:: ============================================================================
:: Password Policy Audit
:: ============================================================================
:: Checks local password policy, audit policy settings, account lockout
:: configuration, guest account status, and user accounts. Reports security
:: posture in a simple summary. Especially useful for shared machines.
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
echo %CYAN% Password Policy Audit%RESET%
echo %CYAN%============================================================================%RESET%
echo/

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR] This script requires Administrator privileges.%RESET%
    echo %RED%Please right-click and select "Run as administrator"%RESET%
    echo/
    pause
    exit /b 1
)

echo This script audits your local security policy and account settings.
echo/
echo %YELLOW%This is a read-only audit. No changes will be made.%RESET%
echo/

set "confirm="
set /p "confirm=Start the audit? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo/
    echo Operation cancelled.
    pause
    exit /b 0
)

:: Set up report file
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "dt=%%I"
set "REPORT=%USERPROFILE%\Desktop\PasswordAudit_%COMPUTERNAME%_%dt:~0,8%.txt"

set "passScore=0"
set "totalChecks=0"
set "issues=0"
set "warnings=0"

:: Write report header
(
echo ============================================================================
echo  Password Policy Audit Report
echo  Computer: %COMPUTERNAME%
echo  Date: %dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%:%dt:~12,2%
echo ============================================================================
) > "%REPORT%"

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 1: Password Policy (local security policy)%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [1/6] Checking password policy...
echo/

(echo/) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  PASSWORD POLICY) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"

:: Export the local security policy once and read its [System Access] values.
:: These key names are the same on every Windows language, unlike the labels
:: and values printed by "net accounts" (e.g. "Jamais"/"Nie" instead of "Never").
:: secedit writes a UTF-16 file, which findstr cannot search directly, so it is
:: converted with "type" first. The values are kept in sp_* variables and reused
:: by Phase 2, Phase 3 and the recommendations.
set "SECPOL_EXPORT=%TEMP%\secpol_export.cfg"
del "%SECPOL_EXPORT%" 2>nul
secedit /export /cfg "%SECPOL_EXPORT%" /areas SECURITYPOLICY >nul 2>&1
for %%k in (MinimumPasswordLength MaximumPasswordAge MinimumPasswordAge PasswordHistorySize LockoutBadCount LockoutDuration ResetLockoutCount PasswordComplexity ClearTextPassword EnableGuestAccount EnableAdminAccount) do set "sp_%%k="
for /f "tokens=1,2 delims== " %%a in ('type "%SECPOL_EXPORT%" 2^>nul ^| findstr /r /i "^MinimumPasswordLength ^MaximumPasswordAge ^MinimumPasswordAge ^PasswordHistorySize ^LockoutBadCount ^LockoutDuration ^ResetLockoutCount ^PasswordComplexity ^ClearTextPassword ^EnableGuestAccount ^EnableAdminAccount"') do set "sp_%%a=%%b"
:: Current name of the built-in Guest account (it may be renamed or localized,
:: e.g. "Gast"). secedit writes it as: NewGuestName = "Guest"
set "guestName="
for /f "tokens=1,* delims==" %%a in ('type "%SECPOL_EXPORT%" 2^>nul ^| findstr /r /i "^NewGuestName"') do set "guestName=%%b"
if defined guestName set "guestName=!guestName:~2,-1!"
if not defined guestName set "guestName=Guest"
del "%SECPOL_EXPORT%" 2>nul

if not defined sp_MinimumPasswordLength (
    echo   %YELLOW%[SKIP] Could not export the local security policy ^(secedit^)%RESET%
    (echo [SKIP] Could not export the local security policy - secedit failed) >> "%REPORT%"
)

:: Minimum password length
if defined sp_MinimumPasswordLength (
    set /a totalChecks+=1
    set "val=!sp_MinimumPasswordLength!"
    if "!val!"=="0" (
        echo   %RED%[FAIL] Minimum password length: !val! ^(no minimum^^!^)%RESET%
        (echo [FAIL] Minimum password length: !val! - no minimum set) >> "%REPORT%"
        set /a issues+=1
    ) else (
        set /a numVal=!val!
        if !numVal! GEQ 12 (
            echo   %GREEN%[PASS] Minimum password length: !val!%RESET%
            (echo [PASS] Minimum password length: !val!) >> "%REPORT%"
            set /a passScore+=1
        ) else if !numVal! GEQ 8 (
            echo   %YELLOW%[WARN] Minimum password length: !val! ^(recommend 12+^)%RESET%
            (echo [WARN] Minimum password length: !val! - recommend 12+) >> "%REPORT%"
            set /a warnings+=1
        ) else (
            echo   %RED%[FAIL] Minimum password length: !val! ^(too short^^!^)%RESET%
            (echo [FAIL] Minimum password length: !val! - too short) >> "%REPORT%"
            set /a issues+=1
        )
    )
)

:: Maximum password age (-1 or 0 = passwords never expire)
if defined sp_MaximumPasswordAge (
    set /a totalChecks+=1
    set "val=!sp_MaximumPasswordAge!"
    set /a numVal=!val!
    if !numVal! LEQ 0 (
        echo   %YELLOW%[WARN] Maximum password age: Unlimited ^(no forced rotation^)%RESET%
        (echo [WARN] Maximum password age: Unlimited) >> "%REPORT%"
        set /a warnings+=1
    ) else (
        echo   %GREEN%[INFO] Maximum password age: !val! days%RESET%
        (echo [INFO] Maximum password age: !val! days) >> "%REPORT%"
        set /a passScore+=1
    )
)

:: Minimum password age
if defined sp_MinimumPasswordAge (
    set /a totalChecks+=1
    set "val=!sp_MinimumPasswordAge!"
    if "!val!"=="0" (
        echo   %YELLOW%[WARN] Minimum password age: 0 days ^(allows immediate reuse cycling^)%RESET%
        (echo [WARN] Minimum password age: 0 - allows reuse cycling) >> "%REPORT%"
        set /a warnings+=1
    ) else (
        echo   %GREEN%[PASS] Minimum password age: !val! days%RESET%
        (echo [PASS] Minimum password age: !val! days) >> "%REPORT%"
        set /a passScore+=1
    )
)

:: Password history (0 = none remembered)
if defined sp_PasswordHistorySize (
    set /a totalChecks+=1
    set "val=!sp_PasswordHistorySize!"
    if "!val!"=="0" (
        echo   %RED%[FAIL] Password history: None ^(passwords can be reused^)%RESET%
        (echo [FAIL] Password history: None - passwords can be reused) >> "%REPORT%"
        set /a issues+=1
    ) else (
        set /a numVal=!val!
        if !numVal! GEQ 5 (
            echo   %GREEN%[PASS] Password history: !val! passwords remembered%RESET%
            (echo [PASS] Password history: !val! passwords remembered) >> "%REPORT%"
            set /a passScore+=1
        ) else (
            echo   %YELLOW%[WARN] Password history: !val! ^(recommend 5+^)%RESET%
            (echo [WARN] Password history: !val! - recommend 5+) >> "%REPORT%"
            set /a warnings+=1
        )
    )
)

:: Lockout threshold (0 = accounts are never locked out)
set "lockoutOff="
if defined sp_LockoutBadCount (
    set /a totalChecks+=1
    set "val=!sp_LockoutBadCount!"
    if "!val!"=="0" (
        echo   %RED%[FAIL] Lockout threshold: Never ^(unlimited login attempts^^!^)%RESET%
        (echo [FAIL] Lockout threshold: Never - unlimited login attempts) >> "%REPORT%"
        set /a issues+=1
        set "lockoutOff=1"
    ) else (
        set /a numVal=!val!
        if !numVal! LEQ 10 (
            echo   %GREEN%[PASS] Lockout threshold: !val! attempts%RESET%
            (echo [PASS] Lockout threshold: !val! attempts) >> "%REPORT%"
            set /a passScore+=1
        ) else (
            echo   %YELLOW%[WARN] Lockout threshold: !val! ^(recommend 10 or fewer^)%RESET%
            (echo [WARN] Lockout threshold: !val! - recommend 10 or fewer) >> "%REPORT%"
            set /a warnings+=1
        )
    )
)

:: Lockout duration and observation window have no effect while lockout is
:: disabled (secpol.msc shows them as "Not Applicable"), so they are reported
:: as N/A and not scored in that case.
if defined lockoutOff (
    echo   %YELLOW%[N/A]  Lockout duration: no effect while account lockout is disabled%RESET%
    (echo [N/A]  Lockout duration - no effect, account lockout disabled) >> "%REPORT%"
    echo   %YELLOW%[N/A]  Lockout observation window: no effect while account lockout is disabled%RESET%
    (echo [N/A]  Lockout observation window - no effect, account lockout disabled) >> "%REPORT%"
) else (
    REM Lockout duration: 0 or -1 = locked until an administrator unlocks the account
    if defined sp_LockoutDuration (
        set /a totalChecks+=1
        set "val=!sp_LockoutDuration!"
        set /a numVal=!val!
        if !numVal! LEQ 0 (
            echo   %GREEN%[PASS] Lockout duration: until an administrator unlocks the account%RESET%
            (echo [PASS] Lockout duration: until an administrator unlocks the account) >> "%REPORT%"
            set /a passScore+=1
        ) else if !numVal! GEQ 15 (
            echo   %GREEN%[PASS] Lockout duration: !val! minutes%RESET%
            (echo [PASS] Lockout duration: !val! minutes) >> "%REPORT%"
            set /a passScore+=1
        ) else (
            echo   %YELLOW%[WARN] Lockout duration: !val! minutes ^(recommend 15+^)%RESET%
            (echo [WARN] Lockout duration: !val! minutes - recommend 15+) >> "%REPORT%"
            set /a warnings+=1
        )
    )

    if defined sp_ResetLockoutCount (
        set /a totalChecks+=1
        set "val=!sp_ResetLockoutCount!"
        echo   %GREEN%[INFO] Lockout observation window: !val! minutes%RESET%
        (echo [INFO] Lockout observation window: !val! minutes) >> "%REPORT%"
        set /a passScore+=1
    )
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 2: Password Complexity (secpol)%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [2/6] Checking password complexity requirements...
echo/

(echo/) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  PASSWORD COMPLEXITY) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"

:: Complexity and reversible encryption come from the policy export in Phase 1
if defined sp_PasswordComplexity (
    set /a totalChecks+=1
    if "!sp_PasswordComplexity!"=="1" (
        echo   %GREEN%[PASS] Password complexity: Enabled%RESET%
        echo          Requires: uppercase, lowercase, digit, and/or special character
        (echo [PASS] Password complexity: Enabled) >> "%REPORT%"
        set /a passScore+=1
    ) else (
        echo   %RED%[FAIL] Password complexity: Disabled%RESET%
        echo   %RED%       Simple passwords like "password" or "123456" are allowed%RESET%
        (echo [FAIL] Password complexity: Disabled) >> "%REPORT%"
        set /a issues+=1
    )

    REM Check reversible encryption
    set /a totalChecks+=1
    if "!sp_ClearTextPassword!"=="1" (
        echo   %RED%[FAIL] Reversible encryption: Enabled ^(stores passwords insecurely^^!^)%RESET%
        (echo [FAIL] Reversible encryption: Enabled - stores passwords insecurely) >> "%REPORT%"
        set /a issues+=1
    ) else (
        echo   %GREEN%[PASS] Reversible encryption: Disabled%RESET%
        (echo [PASS] Reversible encryption: Disabled) >> "%REPORT%"
        set /a passScore+=1
    )
) else (
    echo   %YELLOW%[SKIP] Could not export security policy%RESET%
    (echo [SKIP] Could not export security policy) >> "%REPORT%"
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 3: User Account Analysis%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [3/6] Checking user accounts...
echo/

(echo/) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  USER ACCOUNTS) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"

:: Check Guest account. EnableGuestAccount comes from the policy export in
:: Phase 1, so this also works on non-English Windows and after the account
:: has been renamed ("net user Guest" only finds an English, unrenamed account).
if defined sp_EnableGuestAccount (
    set /a totalChecks+=1
    if "!sp_EnableGuestAccount!"=="1" (
        echo   %RED%[FAIL] Guest account: ENABLED%RESET%
        echo   %RED%       Anyone can access this computer without a password%RESET%
        (echo [FAIL] Guest account: ENABLED) >> "%REPORT%"
        set /a issues+=1
    ) else (
        echo   %GREEN%[PASS] Guest account: Disabled%RESET%
        (echo [PASS] Guest account: Disabled) >> "%REPORT%"
        set /a passScore+=1
    )
) else (
    echo   %YELLOW%[SKIP] Guest account: could not read the security policy%RESET%
    (echo [SKIP] Guest account - could not read the security policy) >> "%REPORT%"
)

:: Check Administrator account (built-in), same language-neutral source
if defined sp_EnableAdminAccount (
    set /a totalChecks+=1
    if "!sp_EnableAdminAccount!"=="1" (
        echo   %YELLOW%[WARN] Built-in Administrator account: ENABLED%RESET%
        echo   %YELLOW%       Consider disabling if not needed ^(use a named admin account instead^)%RESET%
        (echo [WARN] Built-in Administrator account: ENABLED) >> "%REPORT%"
        set /a warnings+=1
    ) else (
        echo   %GREEN%[PASS] Built-in Administrator account: Disabled%RESET%
        (echo [PASS] Built-in Administrator account: Disabled) >> "%REPORT%"
        set /a passScore+=1
    )
) else (
    echo   %YELLOW%[SKIP] Built-in Administrator account: could not read the security policy%RESET%
    (echo [SKIP] Built-in Administrator account - could not read the security policy) >> "%REPORT%"
)

:: List all user accounts
echo/
echo   %WHITE%User accounts on this system:%RESET%
(echo/) >> "%REPORT%"
(echo User accounts:) >> "%REPORT%"

:: The generated scripts print to the console with Write-Host and append the
:: report lines themselves. Redirecting their stdout into the report would also
:: capture the Write-Host output, leaving the console blank.
set "PSUSERS=%TEMP%\audit_users.ps1"
(
echo param^($Report^)
echo Get-LocalUser ^| ForEach-Object {
echo     $status = if ^($_.Enabled^) { 'Active' } else { 'Disabled' }
echo     $lastLogon = if ^($_.LastLogon^) { $_.LastLogon.ToString^('yyyy-MM-dd'^) } else { 'Never' }
echo     $pwdSet = if ^($_.PasswordLastSet^) { $_.PasswordLastSet.ToString^('yyyy-MM-dd'^) } else { 'Never' }
echo     $pwdExpires = $_.PasswordExpires
echo     $pwdRequired = $_.PasswordRequired
echo     $name = $_.Name.PadRight^(25^)
echo     $statusStr = $status.PadRight^(10^)
echo     $line = "$name $statusStr Last Logon: $($lastLogon.PadRight(12)) Pwd Set: $($pwdSet.PadRight(12)) Pwd Required: $pwdRequired"
echo     Write-Host "   $line"
echo     Add-Content -LiteralPath $Report -Value $line -Encoding Oem
echo }
) > "%PSUSERS%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSUSERS%" "%REPORT%" 2>nul
del "%PSUSERS%" 2>nul

:: Check for accounts with no password required
echo/
echo   %WHITE%Checking for accounts without password requirement...%RESET%

set "PSNOPWD=%TEMP%\audit_nopwd.ps1"
(
echo param^($Report^)
echo $noPwd = Get-LocalUser ^| Where-Object { $_.Enabled -eq $true -and $_.PasswordRequired -eq $false }
echo if ^($noPwd^) {
echo     foreach ^($u in $noPwd^) {
echo         Write-Host "   [FAIL] $^($u.Name^) - no password required^!" -ForegroundColor Red
echo         Add-Content -LiteralPath $Report -Value "[FAIL] $($u.Name) - no password required" -Encoding Oem
echo     }
echo     exit 1
echo } else {
echo     Write-Host "   [PASS] All active accounts require passwords" -ForegroundColor Green
echo     Add-Content -LiteralPath $Report -Value "[PASS] All active accounts require passwords" -Encoding Oem
echo     exit 0
echo }
) > "%PSNOPWD%"

set /a totalChecks+=1
:: Exit code carries the pass/fail so the score is credited and no stray count
:: number is written into the report.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PSNOPWD%" "%REPORT%" 2>nul
if errorlevel 1 (set /a issues+=1) else (set /a passScore+=1)
del "%PSNOPWD%" 2>nul

:: Check for admin group members. The group name is localized (e.g.
:: "Administratoren"), so resolve it from its well-known SID S-1-5-32-544.
echo/
echo   %WHITE%Local Administrators group members:%RESET%
(echo/) >> "%REPORT%"
(echo Administrators group members:) >> "%REPORT%"

set "adminGroup=Administrators"
for /f "delims=" %%g in ('powershell -NoProfile -Command "(New-Object Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([Security.Principal.NTAccount]).Value.Split('\')[1]" 2^>nul') do set "adminGroup=%%g"
:: net prints a localized "command completed" message as its last line, so
:: stay one line behind and never print the final line.
set "prevMember="
for /f "skip=6 tokens=*" %%a in ('net localgroup "%adminGroup%" 2^>nul') do (
    if defined prevMember (
        echo    !prevMember!
        (echo    !prevMember!) >> "%REPORT%"
    )
    set "prevMember=%%a"
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 4: Audit Policy%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [4/6] Checking audit policy settings...
echo/

(echo/) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  AUDIT POLICY) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"

:: Check key audit categories
echo   %WHITE%Key audit categories:%RESET%
echo/

:: Subcategories are looked up by GUID in an "auditpol /backup" CSV and judged by
:: the numeric setting (0 = none, 1 = success, 2 = failure, 3 = both). Names
:: passed to "auditpol /get /subcategory:" and its text output are localized,
:: so the English names used before found nothing on non-English Windows.
set "PSAUDIT=%TEMP%\audit_policy.ps1"
(
echo param^($Report^)
echo $map = [ordered]@{
echo     '{0CCE9215-69AE-11D9-BED3-505054503030}' = 'Logon'
echo     '{0CCE9216-69AE-11D9-BED3-505054503030}' = 'Logoff'
echo     '{0CCE9217-69AE-11D9-BED3-505054503030}' = 'Account Lockout'
echo     '{0CCE921B-69AE-11D9-BED3-505054503030}' = 'Special Logon'
echo     '{0CCE9235-69AE-11D9-BED3-505054503030}' = 'User Account Management'
echo     '{0CCE9237-69AE-11D9-BED3-505054503030}' = 'Security Group Management'
echo     '{0CCE922F-69AE-11D9-BED3-505054503030}' = 'Audit Policy Change'
echo     '{0CCE9230-69AE-11D9-BED3-505054503030}' = 'Authentication Policy Change'
echo     '{0CCE922B-69AE-11D9-BED3-505054503030}' = 'Process Creation'
echo     '{0CCE9245-69AE-11D9-BED3-505054503030}' = 'Removable Storage'
echo }
echo $f = Join-Path $env:TEMP 'auditpol_backup.csv'
echo Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
echo auditpol /backup /file:"$f" ^| Out-Null
echo if ^(-not ^(Test-Path -LiteralPath $f^)^) {
echo     Write-Host '   [ERROR] Could not read the audit policy - auditpol /backup failed' -ForegroundColor Red
echo     Add-Content -LiteralPath $Report -Value '[ERROR] Could not read the audit policy' -Encoding Oem
echo     exit 1
echo }
echo $rows = @^(Import-Csv -LiteralPath $f -Header M,T,Sub,Guid,Incl,Excl,Val ^| Select-Object -Skip 1^)
echo Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
echo $names = @^('No Auditing','Success','Failure','Success and Failure'^)
echo foreach ^($g in $map.Keys^) {
echo     $r = $rows ^| Where-Object { $_.Guid -eq $g } ^| Select-Object -First 1
echo     $v = 0
echo     if ^($r^) { $v = [int]$r.Val }
echo     $setting = $names[$v -band 3]
echo     $padCat = $map[$g].PadRight^(35^)
echo     if ^($v -eq 0^) {
echo         Write-Host "   [OFF]  $padCat $setting" -ForegroundColor Yellow
echo         Add-Content -LiteralPath $Report -Value "[WARN] $padCat $setting" -Encoding Oem
echo     } else {
echo         Write-Host "   [ON]   $padCat $setting" -ForegroundColor Green
echo         Add-Content -LiteralPath $Report -Value "[PASS] $padCat $setting" -Encoding Oem
echo     }
echo }
) > "%PSAUDIT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSAUDIT%" "%REPORT%" 2>nul
del "%PSAUDIT%" 2>nul

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 5: Additional Security Checks%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [5/6] Running additional security checks...
echo/

(echo/) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  ADDITIONAL SECURITY CHECKS) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"

:: Check UAC status
set /a totalChecks+=1
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA 2>nul | find "0x1" >nul 2>&1
if not errorlevel 1 (
    echo   %GREEN%[PASS] UAC ^(User Account Control^): Enabled%RESET%
    (echo [PASS] UAC: Enabled) >> "%REPORT%"
    set /a passScore+=1
) else (
    echo   %RED%[FAIL] UAC ^(User Account Control^): Disabled^^!%RESET%
    (echo [FAIL] UAC: Disabled) >> "%REPORT%"
    set /a issues+=1
)

:: Check UAC consent prompt level
set /a totalChecks+=1
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin 2^>nul ^| find "REG_DWORD"') do (
    set "uacLevel=%%a"
)
if defined uacLevel (
    if "!uacLevel!"=="0x0" (
        echo   %RED%[FAIL] UAC prompt level: Never notify ^(no protection^)%RESET%
        (echo [FAIL] UAC prompt level: Never notify) >> "%REPORT%"
        set /a issues+=1
    ) else if "!uacLevel!"=="0x5" (
        echo   %GREEN%[PASS] UAC prompt level: Default ^(prompt for non-Windows binaries^)%RESET%
        (echo [PASS] UAC prompt level: Default) >> "%REPORT%"
        set /a passScore+=1
    ) else if "!uacLevel!"=="0x2" (
        echo   %GREEN%[PASS] UAC prompt level: Always notify ^(maximum protection^)%RESET%
        (echo [PASS] UAC prompt level: Always notify) >> "%REPORT%"
        set /a passScore+=1
    ) else (
        echo   %YELLOW%[WARN] UAC prompt level: Custom ^(!uacLevel!^)%RESET%
        (echo [WARN] UAC prompt level: Custom) >> "%REPORT%"
        set /a warnings+=1
    )
)

:: Check auto-logon
set /a totalChecks+=1
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon 2>nul | find "1" >nul 2>&1
if not errorlevel 1 (
    echo   %RED%[FAIL] Auto-logon: Enabled ^(bypasses login screen^^!^)%RESET%
    (echo [FAIL] Auto-logon: Enabled) >> "%REPORT%"
    set /a issues+=1

    REM Check if password is stored in plaintext
    reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword >nul 2>&1
    if not errorlevel 1 (
        echo   %RED%[FAIL] Auto-logon password is stored in plaintext in registry^^!%RESET%
        (echo [FAIL] Auto-logon password stored in plaintext registry) >> "%REPORT%"
        set /a issues+=1
    )
) else (
    echo   %GREEN%[PASS] Auto-logon: Disabled%RESET%
    (echo [PASS] Auto-logon: Disabled) >> "%REPORT%"
    set /a passScore+=1
)

:: Check screen lock timeout. The timeout and password only lock anything when a
:: screen saver is selected: choosing "(None)" removes SCRNSAVE.EXE but leaves
:: ScreenSaveTimeOut and ScreenSaverIsSecure behind. Group Policy values
:: (read second) override the user's own settings.
set /a totalChecks+=1
set "ssExe="
set "lockTimeout="
set "ssSecure="
set "ssPolicyKey=HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
for /f "tokens=2*" %%a in ('reg query "HKCU\Control Panel\Desktop" /v SCRNSAVE.EXE 2^>nul ^| find /i "SCRNSAVE.EXE"') do set "ssExe=%%b"
for /f "tokens=2*" %%a in ('reg query "%ssPolicyKey%" /v SCRNSAVE.EXE 2^>nul ^| find /i "SCRNSAVE.EXE"') do set "ssExe=%%b"
for /f "tokens=3" %%a in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut 2^>nul ^| find "REG_SZ"') do set "lockTimeout=%%a"
for /f "tokens=3" %%a in ('reg query "%ssPolicyKey%" /v ScreenSaveTimeOut 2^>nul ^| find "REG_SZ"') do set "lockTimeout=%%a"
for /f "tokens=3" %%a in ('reg query "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure 2^>nul ^| find "REG_SZ"') do set "ssSecure=%%a"
for /f "tokens=3" %%a in ('reg query "%ssPolicyKey%" /v ScreenSaverIsSecure 2^>nul ^| find "REG_SZ"') do set "ssSecure=%%a"
:: Policy "Enable screen saver" = Disabled: no screen saver ever runs
for /f "tokens=3" %%a in ('reg query "%ssPolicyKey%" /v ScreenSaveActive 2^>nul ^| find "REG_SZ"') do if "%%a"=="0" set "ssExe="

if not defined ssExe (
    echo   %YELLOW%[WARN] Screen saver: None selected ^(no screen saver lock^)%RESET%
    (echo [WARN] Screen saver: None selected - no screen saver lock) >> "%REPORT%"
    set /a warnings+=1
) else if not defined lockTimeout (
    echo   %YELLOW%[WARN] Screen saver timeout: Not configured%RESET%
    (echo [WARN] Screen saver timeout: Not configured) >> "%REPORT%"
    set /a warnings+=1
) else if "!lockTimeout!"=="0" (
    echo   %YELLOW%[WARN] Screen saver timeout: Disabled ^(no automatic lock^)%RESET%
    (echo [WARN] Screen saver timeout: Disabled) >> "%REPORT%"
    set /a warnings+=1
) else (
    set /a lockMin=!lockTimeout!/60
    echo   %GREEN%[INFO] Screen saver timeout: !lockMin! minutes%RESET%
    (echo [INFO] Screen saver timeout: !lockMin! minutes) >> "%REPORT%"
    set /a passScore+=1
)

:: Check if screen saver requires password
set /a totalChecks+=1
if not defined ssExe (
    echo   %YELLOW%[WARN] Screen saver password: Not applied - no screen saver selected%RESET%
    (echo [WARN] Screen saver password: not applied - no screen saver selected) >> "%REPORT%"
    set /a warnings+=1
) else if "!ssSecure!"=="1" (
    echo   %GREEN%[PASS] Screen saver password: Required on resume%RESET%
    (echo [PASS] Screen saver password required) >> "%REPORT%"
    set /a passScore+=1
) else (
    echo   %YELLOW%[WARN] Screen saver password: Not required on resume%RESET%
    (echo [WARN] Screen saver password not required on resume) >> "%REPORT%"
    set /a warnings+=1
)

:: Check Windows Defender status
set /a totalChecks+=1
sc query WinDefend 2>nul | find "RUNNING" >nul 2>&1
if not errorlevel 1 (
    echo   %GREEN%[PASS] Windows Defender: Running%RESET%
    (echo [PASS] Windows Defender: Running) >> "%REPORT%"
    set /a passScore+=1
) else (
    echo   %YELLOW%[WARN] Windows Defender: Not running ^(check if another AV is active^)%RESET%
    (echo [WARN] Windows Defender: Not running) >> "%REPORT%"
    set /a warnings+=1
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 6: Security Score%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [6/6] Calculating security score...
echo/

(echo/) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"
(echo  SECURITY SCORE) >> "%REPORT%"
(echo ============================================================================) >> "%REPORT%"

:: Calculate percentage
if !totalChecks! GTR 0 (
    set /a scorePercent=passScore*100/totalChecks
) else (
    set "scorePercent=0"
)

echo   Checks passed:  !passScore! / !totalChecks!
echo   Issues found:   !issues!
echo   Warnings:       !warnings!
echo   Score:          !scorePercent!%%
echo/

(echo Checks passed:  !passScore! / !totalChecks!) >> "%REPORT%"
(echo Issues found:   !issues!) >> "%REPORT%"
(echo Warnings:       !warnings!) >> "%REPORT%"
(echo Score:          !scorePercent!%%) >> "%REPORT%"
(echo/) >> "%REPORT%"

:: Grade
if !scorePercent! GEQ 90 (
    echo   %GREEN%Grade: A - Excellent security posture%RESET%
    (echo Grade: A - Excellent security posture) >> "%REPORT%"
) else if !scorePercent! GEQ 75 (
    echo   %GREEN%Grade: B - Good security posture%RESET%
    (echo Grade: B - Good security posture) >> "%REPORT%"
) else if !scorePercent! GEQ 60 (
    echo   %YELLOW%Grade: C - Acceptable, but improvements recommended%RESET%
    (echo Grade: C - Acceptable, improvements recommended) >> "%REPORT%"
) else if !scorePercent! GEQ 40 (
    echo   %YELLOW%Grade: D - Weak security posture, action needed%RESET%
    (echo Grade: D - Weak security posture, action needed) >> "%REPORT%"
) else (
    echo   %RED%Grade: F - Critical security issues found^^!%RESET%
    (echo Grade: F - Critical security issues) >> "%REPORT%"
)

:: Recommendations
echo/
echo %YELLOW%RECOMMENDATIONS:%RESET%
(echo/) >> "%REPORT%"
(echo RECOMMENDATIONS:) >> "%REPORT%"

if !issues! GTR 0 (
    echo/
    echo   %WHITE%Critical fixes:%RESET%
    (echo/) >> "%REPORT%"
    (echo Critical fixes:) >> "%REPORT%"

    REM Uses the language-neutral policy values read in Phase 1
    if "!sp_EnableGuestAccount!"=="1" (
        echo    - Disable Guest account:  net user "!guestName!" /active:no
        (echo  - Disable Guest account: net user "!guestName!" /active:no) >> "%REPORT%"
    )

    if "!sp_MinimumPasswordLength!"=="0" (
        echo    - Set minimum password length:  net accounts /minpwlen:12
        (echo  - Set minimum password length: net accounts /minpwlen:12) >> "%REPORT%"
    )

    if "!sp_LockoutBadCount!"=="0" (
        echo    - Set lockout threshold:  net accounts /lockoutthreshold:5
        (echo  - Set lockout threshold: net accounts /lockoutthreshold:5) >> "%REPORT%"
    )
)

echo/
echo   %WHITE%General recommendations:%RESET%
echo    - Use passwords of 12+ characters with complexity
echo    - Enable account lockout after 5-10 failed attempts
echo    - Disable the Guest and built-in Administrator accounts
echo    - Enable audit logging for logon events
echo    - Set screen lock timeout to 5-15 minutes
echo    - Keep UAC enabled at default or higher
echo/

(echo/) >> "%REPORT%"
(echo General recommendations:) >> "%REPORT%"
(echo  - Use passwords of 12+ characters with complexity) >> "%REPORT%"
(echo  - Enable account lockout after 5-10 failed attempts) >> "%REPORT%"
(echo  - Disable Guest and built-in Administrator accounts) >> "%REPORT%"
(echo  - Enable audit logging for logon events) >> "%REPORT%"
(echo  - Set screen lock timeout to 5-15 minutes) >> "%REPORT%"
(echo  - Keep UAC enabled at default or higher) >> "%REPORT%"

echo Report saved to: %REPORT%
echo/

pause
exit /b 0
