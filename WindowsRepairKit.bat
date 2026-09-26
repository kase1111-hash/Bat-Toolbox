@echo off
setlocal enabledelayedexpansion
title Windows Repair Kit
color 0B

:: ============================================================================
:: Windows Repair Kit
:: ============================================================================
:: Runs SFC, DISM, and CHKDSK in sequence with progress reporting.
:: Parses results to show actual errors found and fixes applied.
:: ============================================================================

echo ============================================================================
echo  Windows Repair Kit
echo ============================================================================
echo/

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

:: Setup colors
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "RESET=%ESC%[0m"

:: Setup log file. Use PowerShell for a locale-independent date (%DATE% slicing
:: assumes US format and yields a "/"-containing, invalid path elsewhere).
for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "TODAY=%%D"
:: Resolve the real Desktop folder. It can be redirected (e.g. OneDrive folder
:: backup moves it to %USERPROFILE%\OneDrive\Desktop), so %USERPROFILE%\Desktop
:: is not always the Desktop the user sees. If that path is missing or cannot
:: be used, fall back to %USERPROFILE%\Desktop, then to the profile folder.
set "DESKTOP_DIR="
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP_DIR=%%D"
if not defined DESKTOP_DIR set "DESKTOP_DIR=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_DIR%\" set "DESKTOP_DIR=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_DIR%\" set "DESKTOP_DIR=%USERPROFILE%"
set "LOGFILE=%DESKTOP_DIR%\RepairKit_%COMPUTERNAME%_%TODAY%.txt"

echo %CYAN%This script will run three system integrity checks:%RESET%
echo/
echo   [1] SFC /scannow        - Scans and repairs Windows system files
echo   [2] DISM /ScanHealth    - Checks the component store, repairs it if needed
echo   [3] CHKDSK              - Checks disk for filesystem errors
echo/
echo Results will be saved to:
echo   !LOGFILE!
echo/
echo %YELLOW%This process can take 15-60 minutes depending on your system.%RESET%
echo/

set "CONFIRM="
set /p "CONFIRM=Run all checks? [Y/N]: "
if /i not "!CONFIRM!"=="Y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo/
echo ============================================================================
echo  Starting Windows Repair Kit - %DATE% %TIME%
echo ============================================================================

:: Initialize log
(
echo ============================================================================
echo  Windows Repair Kit - %COMPUTERNAME%
echo  Date: %DATE% %TIME%
echo  OS:
) > "%LOGFILE%"
for /f "tokens=2 delims=:" %%a in ('systeminfo ^| findstr /c:"OS Name"') do (
    echo   %%a>> "%LOGFILE%"
)
echo ============================================================================>> "%LOGFILE%"
echo/>> "%LOGFILE%"

:: ============================================================================
:: Step 1: System File Checker (SFC)
:: ============================================================================
echo/
echo %CYAN%[1/3] Running System File Checker (SFC /scannow)...%RESET%
echo       This checks Windows system files for corruption.
echo/

echo [1/3] SFC /scannow>> "%LOGFILE%"
echo ---------------------------------------->> "%LOGFILE%"

:: Remember when SFC started, so only this run's CBS.log entries are reported.
:: CBS.log lines start with a local "yyyy-MM-dd HH:mm:ss" timestamp.
set "SFC_START="
for /f "delims=" %%D in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)"') do set "SFC_START=%%D"

sfc /scannow > "%TEMP%\sfc_output.txt" 2>&1
set "SFC_EXIT=%errorlevel%"

:: sfc writes UTF-16LE output with no BOM, so Windows PowerShell reads it as
:: ANSI with a NUL after every character. Strip the NULs and save as ASCII so
:: the findstr phrase checks below can match. Paths come from $env:TEMP so an
:: apostrophe in the profile path cannot break the PowerShell command.
powershell -NoProfile -Command "(Get-Content -LiteralPath (Join-Path $env:TEMP 'sfc_output.txt')) -replace [char]0,'' | Set-Content -LiteralPath (Join-Path $env:TEMP 'sfc_ascii.txt') -Encoding ascii" 2>nul

:: Parse SFC results. Use /c: so the whole phrase must match - without it,
:: findstr treats each space-separated word as a separate OR pattern.
set "SFC_STATUS=UNKNOWN"
findstr /i /c:"did not find any integrity violations" "%TEMP%\sfc_ascii.txt" >nul 2>&1
if %errorlevel% equ 0 (
    set "SFC_STATUS=CLEAN"
    echo %GREEN%[OK] SFC: No integrity violations found.%RESET%
    echo Result: No integrity violations found.>> "%LOGFILE%"
)

findstr /i /c:"found corrupt files and successfully repaired" "%TEMP%\sfc_ascii.txt" >nul 2>&1
if %errorlevel% equ 0 (
    set "SFC_STATUS=REPAIRED"
    echo %GREEN%[FIXED] SFC: Found corrupt files and repaired them.%RESET%
    echo Result: Found and repaired corrupt files.>> "%LOGFILE%"
)

findstr /i /c:"found corrupt files but was unable to fix" "%TEMP%\sfc_ascii.txt" >nul 2>&1
if %errorlevel% equ 0 (
    set "SFC_STATUS=FAILED"
    echo %RED%[WARN] SFC: Found corrupt files but could NOT repair them.%RESET%
    echo %YELLOW%       DISM may fix this - continuing to step 2.%RESET%
    echo Result: Found corrupt files but UNABLE to repair.>> "%LOGFILE%"
)

findstr /i /c:"could not perform the requested operation" /c:"system repair pending" "%TEMP%\sfc_ascii.txt" >nul 2>&1
if %errorlevel% equ 0 (
    set "SFC_STATUS=BLOCKED"
    echo %RED%[WARN] SFC: Could not perform scan. Pending repairs may exist.%RESET%
    echo %YELLOW%       A reboot may be required before SFC can run.%RESET%
    echo Result: Could not perform scan.>> "%LOGFILE%"
)

if "!SFC_STATUS!"=="UNKNOWN" (
    echo %YELLOW%[INFO] SFC completed with exit code %SFC_EXIT%.%RESET%
    echo Result: Completed with exit code %SFC_EXIT%.>> "%LOGFILE%"
)

:: Check CBS log for details
echo/>> "%LOGFILE%"
echo CBS Log entries from this SFC run (last 50 relevant lines^):>> "%LOGFILE%"
if exist "%WINDIR%\Logs\CBS\CBS.log" (
    REM CBS.log also holds entries from earlier SFC/DISM runs. Keep only lines
    REM stamped at or after SFC_START - an ordinal compare of the fixed-width
    REM yyyy-MM-dd HH:mm:ss prefix that starts every CBS.log line.
    findstr /i /c:"corrupt" /c:"Cannot repair" /c:"repaired" "%WINDIR%\Logs\CBS\CBS.log" > "%TEMP%\cbs_all.txt" 2>nul
    powershell -NoProfile -Command "Get-Content -LiteralPath (Join-Path $env:TEMP 'cbs_all.txt') | Where-Object { $_.Length -ge 19 -and [string]::CompareOrdinal($_.Substring(0,19), $env:SFC_START) -ge 0 }" > "%TEMP%\cbs_errors.txt" 2>nul
    del "%TEMP%\cbs_all.txt" 2>nul
    REM Get last 50 lines using PowerShell
    powershell -NoProfile -Command "Get-Content -LiteralPath (Join-Path $env:TEMP 'cbs_errors.txt') -Tail 50" >> "%LOGFILE%" 2>nul

    REM Count issues for display
    for /f %%a in ('findstr /i /c:"Cannot repair" "%TEMP%\cbs_errors.txt" 2^>nul ^| find /c /v ""') do set "CBS_FAILURES=%%a"
    for /f %%a in ('findstr /i /c:"repaired" "%TEMP%\cbs_errors.txt" 2^>nul ^| find /c /v ""') do set "CBS_REPAIRS=%%a"

    if defined CBS_REPAIRS if !CBS_REPAIRS! gtr 0 (
        echo       CBS log: !CBS_REPAIRS! repair entries found.
    )
    if defined CBS_FAILURES if !CBS_FAILURES! gtr 0 (
        echo       %RED%CBS log: !CBS_FAILURES! unresolvable entries found.%RESET%
    )
) else (
    echo CBS.log not found.>> "%LOGFILE%"
)
echo/>> "%LOGFILE%"

del "%TEMP%\sfc_output.txt" 2>nul
del "%TEMP%\sfc_ascii.txt" 2>nul
del "%TEMP%\cbs_errors.txt" 2>nul

:: ============================================================================
:: Step 2: DISM ScanHealth + RestoreHealth
:: ============================================================================
echo/
echo %CYAN%[2/3] Running DISM /ScanHealth (then /RestoreHealth if needed)...%RESET%
echo       This checks the Windows component store and repairs it using
echo       Windows Update if the scan does not report it as clean.
echo/

echo [2/3] DISM /Online /Cleanup-Image /ScanHealth, then /RestoreHealth if needed>> "%LOGFILE%"
echo ---------------------------------------->> "%LOGFILE%"

:: /RestoreHealth prints "The restore operation completed successfully" whether
:: or not anything was repaired, and never prints "No component store
:: corruption detected" (only /ScanHealth and /CheckHealth do). So scan first
:: and run /RestoreHealth only when the scan does not report a clean store.
:: dism_output.txt then holds the scan output (CLEAN) or the restore output.
DISM /Online /Cleanup-Image /ScanHealth > "%TEMP%\dism_output.txt" 2>&1
set "DISM_EXIT=%errorlevel%"
findstr /i /c:"No component store corruption detected" "%TEMP%\dism_output.txt" >nul 2>&1
if %errorlevel% neq 0 (
    echo       ScanHealth did not report a clean store - running DISM /RestoreHealth...
    echo DISM /ScanHealth output:>> "%LOGFILE%"
    type "%TEMP%\dism_output.txt" >> "%LOGFILE%"
    echo/>> "%LOGFILE%"
    DISM /Online /Cleanup-Image /RestoreHealth > "%TEMP%\dism_output.txt" 2>&1
    set "DISM_EXIT=!errorlevel!"
)

:: Parse DISM results
set "DISM_STATUS=UNKNOWN"

findstr /i /c:"The restore operation completed successfully" "%TEMP%\dism_output.txt" >nul 2>&1
if %errorlevel% equ 0 (
    set "DISM_STATUS=SUCCESS"
    echo %GREEN%[OK] DISM: Restore operation completed successfully.%RESET%
    echo Result: Restore operation completed successfully.>> "%LOGFILE%"
)

findstr /i /c:"No component store corruption detected" "%TEMP%\dism_output.txt" >nul 2>&1
if %errorlevel% equ 0 (
    set "DISM_STATUS=CLEAN"
    echo %GREEN%[OK] DISM: No component store corruption detected.%RESET%
    echo Result: No component store corruption detected.>> "%LOGFILE%"
)

findstr /i "Error" "%TEMP%\dism_output.txt" >nul 2>&1
if %errorlevel% equ 0 if "!DISM_STATUS!"=="UNKNOWN" (
    set "DISM_STATUS=ERROR"
    echo %RED%[ERROR] DISM encountered errors. Check log for details.%RESET%
    echo Result: Errors encountered ^(exit code %DISM_EXIT%^).>> "%LOGFILE%"
)

if "!DISM_STATUS!"=="UNKNOWN" (
    echo %YELLOW%[INFO] DISM completed with exit code %DISM_EXIT%.%RESET%
    echo Result: Completed with exit code %DISM_EXIT%.>> "%LOGFILE%"
)

:: Append full DISM output to log
echo/>> "%LOGFILE%"
echo Full DISM output:>> "%LOGFILE%"
type "%TEMP%\dism_output.txt" >> "%LOGFILE%"
echo/>> "%LOGFILE%"

del "%TEMP%\dism_output.txt" 2>nul

:: If SFC found unrepairable files and DISM succeeded, suggest re-running SFC
if "!SFC_STATUS!"=="FAILED" if "!DISM_STATUS!"=="SUCCESS" (
    echo/
    echo %YELLOW%[TIP] SFC found unrepairable files but DISM succeeded.%RESET%
    echo %YELLOW%      Re-running SFC may now be able to fix those files.%RESET%
    echo/
    set "RERUN_SFC="
    set /p "RERUN_SFC=Re-run SFC /scannow now? [Y/N]: "
    if /i "!RERUN_SFC!"=="Y" (
        echo/
        echo %CYAN%[BONUS] Re-running SFC /scannow after DISM repair...%RESET%
        echo/
        echo [BONUS] SFC /scannow re-run after DISM>> "%LOGFILE%"
        echo ---------------------------------------->> "%LOGFILE%"
        sfc /scannow > "%TEMP%\sfc2_output.txt" 2>&1
        REM Same UTF-16 NUL stripping as for the first SFC run above
        powershell -NoProfile -Command "(Get-Content -LiteralPath (Join-Path $env:TEMP 'sfc2_output.txt')) -replace [char]0,'' | Set-Content -LiteralPath (Join-Path $env:TEMP 'sfc2_ascii.txt') -Encoding ascii" 2>nul

        findstr /i /c:"did not find any integrity violations" "%TEMP%\sfc2_ascii.txt" >nul 2>&1
        if !errorlevel! equ 0 (
            echo %GREEN%[OK] SFC re-run: All files are now intact.%RESET%
            echo Result: All files intact after DISM repair.>> "%LOGFILE%"
        ) else (
            findstr /i /c:"found corrupt files and successfully repaired" "%TEMP%\sfc2_ascii.txt" >nul 2>&1
            if !errorlevel! equ 0 (
                echo %GREEN%[FIXED] SFC re-run: Additional files repaired.%RESET%
                echo Result: Additional files repaired.>> "%LOGFILE%"
            ) else (
                echo %YELLOW%[INFO] SFC re-run completed. Check log for details.%RESET%
                echo Result: Check log for details.>> "%LOGFILE%"
            )
        )
        del "%TEMP%\sfc2_output.txt" 2>nul
        del "%TEMP%\sfc2_ascii.txt" 2>nul
        echo/>> "%LOGFILE%"
    )
)

:: ============================================================================
:: Step 3: CHKDSK
:: ============================================================================
echo/
echo %CYAN%[3/3] Checking disk filesystem integrity...%RESET%
echo/

echo [3/3] CHKDSK>> "%LOGFILE%"
echo ---------------------------------------->> "%LOGFILE%"

:: Get system drive
set "SYSDRIVE=%SYSTEMDRIVE%"

echo       Running CHKDSK on %SYSDRIVE% (read-only scan)...
echo/

chkdsk %SYSDRIVE% > "%TEMP%\chkdsk_output.txt" 2>&1
set "CHKDSK_EXIT=%errorlevel%"

:: Parse CHKDSK results
findstr /i /c:"found no problems" "%TEMP%\chkdsk_output.txt" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[OK] CHKDSK: No filesystem problems found on %SYSDRIVE%.%RESET%
    echo Result: No filesystem problems found on %SYSDRIVE%.>> "%LOGFILE%"
) else (
    REM Check for problems that need fixing. A read-only scan of a damaged
    REM NTFS volume reports "found problems", "fixed offline" or "spotfix"
    REM on Windows 8 and later, or "errors" on older builds. Exit code 3 also
    REM means errors were found but not fixed because /F was not given.
    findstr /i /c:"found problems" /c:"errors" /c:"fixed offline" /c:"spotfix" "%TEMP%\chkdsk_output.txt" >nul 2>&1
    set "CHK_PROBLEM=!errorlevel!"
    if !CHKDSK_EXIT! geq 3 set "CHK_PROBLEM=0"
    if "!CHK_PROBLEM!"=="0" (
        echo %RED%[WARN] CHKDSK: Filesystem errors detected on %SYSDRIVE%.%RESET%
        echo Result: Filesystem errors detected on %SYSDRIVE%.>> "%LOGFILE%"
        echo/
        echo %YELLOW%       To fix errors, schedule a repair for next reboot:%RESET%
        echo         chkdsk %SYSDRIVE% /F /R
        echo/
        set "SCHEDULE_CHKDSK="
        set /p "SCHEDULE_CHKDSK=Schedule CHKDSK /F /R for next reboot? [Y/N]: "
        if /i "!SCHEDULE_CHKDSK!"=="Y" (
            echo Y | chkdsk %SYSDRIVE% /F /R >nul 2>&1
            echo %GREEN%[OK] CHKDSK repair scheduled for next reboot.%RESET%
            echo CHKDSK /F /R scheduled for next reboot.>> "%LOGFILE%"
        )
    ) else (
        echo %YELLOW%[INFO] CHKDSK completed on %SYSDRIVE% ^(exit code %CHKDSK_EXIT%^).%RESET%
        echo Result: Completed on %SYSDRIVE% ^(exit code %CHKDSK_EXIT%^).>> "%LOGFILE%"
    )
)

:: Extract key stats from CHKDSK
echo/>> "%LOGFILE%"
echo CHKDSK details:>> "%LOGFILE%"
findstr /i /c:"KB total disk" /c:"KB available" /c:"bytes in each" /c:"bad sectors" /c:"KB in bad" "%TEMP%\chkdsk_output.txt" >> "%LOGFILE%" 2>nul

:: Show bad sector info if any
for /f "tokens=*" %%a in ('findstr /i "bad sectors" "%TEMP%\chkdsk_output.txt" 2^>nul') do (
    echo       %%a
)

echo/>> "%LOGFILE%"
del "%TEMP%\chkdsk_output.txt" 2>nul

:: ============================================================================
:: Summary
:: ============================================================================
echo/
echo ============================================================================
echo %CYAN% REPAIR KIT SUMMARY%RESET%
echo ============================================================================
echo/

:: SFC summary
if "!SFC_STATUS!"=="CLEAN" (
    echo   SFC:    %GREEN%PASS%RESET% - No integrity violations
) else if "!SFC_STATUS!"=="REPAIRED" (
    echo   SFC:    %GREEN%FIXED%RESET% - Corrupt files were repaired
) else if "!SFC_STATUS!"=="FAILED" (
    echo   SFC:    %RED%ISSUE%RESET% - Some files could not be repaired
) else if "!SFC_STATUS!"=="BLOCKED" (
    echo   SFC:    %YELLOW%BLOCKED%RESET% - Could not run, reboot may be needed
) else (
    echo   SFC:    %YELLOW%CHECK LOG%RESET% - Review log for details
)

:: DISM summary
if "!DISM_STATUS!"=="CLEAN" (
    echo   DISM:   %GREEN%PASS%RESET% - No corruption detected
) else if "!DISM_STATUS!"=="SUCCESS" (
    echo   DISM:   %GREEN%FIXED%RESET% - Component store repaired
) else if "!DISM_STATUS!"=="ERROR" (
    echo   DISM:   %RED%ERROR%RESET% - Check log for details
) else (
    echo   DISM:   %YELLOW%CHECK LOG%RESET% - Review log for details
)

:: CHKDSK summary
if "%CHKDSK_EXIT%"=="0" (
    echo   CHKDSK: %GREEN%PASS%RESET% - No filesystem errors
) else (
    echo   CHKDSK: %YELLOW%CHECK LOG%RESET% - Review log for details
)

echo/
echo Full log saved to:
echo   !LOGFILE!
echo/

:: Completion timestamp
echo ============================================================================>> "%LOGFILE%"
echo Completed: %DATE% %TIME%>> "%LOGFILE%"
echo ============================================================================>> "%LOGFILE%"

:: Recommend reboot if repairs were made
if "!SFC_STATUS!"=="REPAIRED" (
    echo %YELLOW%[TIP] System files were repaired. A reboot is recommended.%RESET%
    echo/
)
if "!DISM_STATUS!"=="SUCCESS" (
    echo %YELLOW%[TIP] Component store was repaired. A reboot is recommended.%RESET%
    echo/
)

echo ============================================================================
echo  Repair Kit Complete
echo ============================================================================
echo/
pause
