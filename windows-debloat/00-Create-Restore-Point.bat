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

:: Enable System Restore on the Windows drive if disabled (not always C:)
powershell -NoProfile -Command "Enable-ComputerRestore -Drive '%SystemDrive%\'" 2>nul

:: Remove the 24-hour throttle for this run only. By default Windows refuses to
:: create a second restore point within 24 hours (SystemRestorePointCreationFrequency)
:: and Checkpoint-Computer reports that as a *warning* while still exiting 0 - which
:: would make this script claim success with no restore point actually created.
:: The original value is saved here and put back right after the restore point.
set "SR_KEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
set "OLD_FREQ="
for /f "tokens=3" %%v in ('reg query "%SR_KEY%" /v SystemRestorePointCreationFrequency 2^>nul ^| find "REG_DWORD"') do set "OLD_FREQ=%%v"
reg add "%SR_KEY%" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 0 /f >nul 2>&1

:: Create the restore point, then verify one was actually added (do not trust
:: the exit code, which is 0 even when creation is skipped). Compare the newest
:: SequenceNumber, not the count: when shadow storage is full Windows deletes the
:: oldest point to make room, so the count can stay the same after a success.
powershell -NoProfile -Command "$before = (@(Get-ComputerRestorePoint) | Measure-Object -Property SequenceNumber -Maximum).Maximum; Checkpoint-Computer -Description 'Before Windows 10 Debloat' -RestorePointType 'MODIFY_SETTINGS'; $after = (@(Get-ComputerRestorePoint) | Measure-Object -Property SequenceNumber -Maximum).Maximum; if ($after -and $after -gt $before) { exit 0 } else { exit 1 }"
set "RP_RESULT=%errorlevel%"

:: Put the creation throttle back the way it was
if defined OLD_FREQ (
    reg add "%SR_KEY%" /v SystemRestorePointCreationFrequency /t REG_DWORD /d %OLD_FREQ% /f >nul 2>&1
) else (
    reg delete "%SR_KEY%" /v SystemRestorePointCreationFrequency /f >nul 2>&1
)

if "%RP_RESULT%"=="0" (
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
    echo  - A restore point was created recently ^(Windows limits frequency^)
    echo/
    echo Proceed with caution or try again later.
    echo/
)

pause
exit /b 0
