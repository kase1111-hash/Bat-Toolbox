@echo off
:: ============================================================================
:: Windows 10 Debloat - Create System Restore Point
:: ============================================================================
:: This script creates a system restore point before making any changes.
:: ALWAYS run this first before running any other debloat scripts.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Create System Restore Point
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

echo Creating system restore point...
echo This may take a few minutes.
echo.

:: Enable System Restore if disabled
powershell -Command "Enable-ComputerRestore -Drive 'C:\'" 2>nul

:: Create the restore point
powershell -Command "Checkpoint-Computer -Description 'Before Windows 10 Debloat' -RestorePointType 'MODIFY_SETTINGS'"

if %errorlevel% equ 0 (
    echo.
    echo ============================================================================
    echo  SUCCESS: Restore point created successfully!
    echo ============================================================================
    echo.
    echo You can now safely run the other debloat scripts.
    echo If anything goes wrong, you can restore from this point.
    echo.
) else (
    echo.
    echo ============================================================================
    echo  WARNING: Could not create restore point.
    echo ============================================================================
    echo.
    echo This might happen if:
    echo  - System Restore is disabled
    echo  - Not enough disk space
    echo  - A restore point was created recently (Windows limits frequency)
    echo.
    echo Proceed with caution or try again later.
    echo.
)

pause
