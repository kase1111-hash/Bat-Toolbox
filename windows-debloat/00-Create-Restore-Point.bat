@echo off
setlocal
:: ============================================================================
:: Windows 10 Debloat - Create System Restore Point
:: ============================================================================
:: This script creates a system restore point before making any changes.
:: ALWAYS run this first before running any other debloat scripts.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Create System Restore Point
echo ============================================================================
echo/

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo/
    pause
    exit /b 1
)

echo Creating system restore point...
echo This may take a few minutes.
echo/

:: Enable System Restore if disabled
powershell -Command "Enable-ComputerRestore -Drive 'C:\'" 2>nul

:: Remove the 24-hour throttle. By default Windows refuses to create a second
:: restore point within 24 hours (SystemRestorePointCreationFrequency) and
:: Checkpoint-Computer reports that as a *warning* while still exiting 0 - which
:: would make this script claim success with no restore point actually created.
:: Setting the frequency to 0 forces creation every time this safety-net runs.
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 0 /f >nul 2>&1

:: Create the restore point, then verify one was actually added (do not trust
:: the exit code, which is 0 even when creation is skipped).
powershell -NoProfile -Command "$before = @(Get-ComputerRestorePoint).Count; Checkpoint-Computer -Description 'Before Windows 10 Debloat' -RestorePointType 'MODIFY_SETTINGS'; if (@(Get-ComputerRestorePoint).Count -gt $before) { exit 0 } else { exit 1 }"

if %errorlevel% equ 0 (
    echo/
    echo ============================================================================
    echo  SUCCESS: Restore point created successfully!
    echo ============================================================================
    echo/
    echo You can now safely run the other debloat scripts.
    echo If anything goes wrong, you can restore from this point.
    echo/
) else (
    echo/
    echo ============================================================================
    echo  WARNING: Could not create restore point.
    echo ============================================================================
    echo/
    echo This might happen if:
    echo  - System Restore is disabled
    echo  - Not enough disk space
    echo  - A restore point was created recently (Windows limits frequency)
    echo/
    echo Proceed with caution or try again later.
    echo/
)

pause
exit /b 0
