@echo off
setlocal
:: ============================================================================
:: Windows 10 Debloat - Registry Performance Tweaks
:: ============================================================================
:: This script applies registry modifications to improve performance:
:: - Disable visual effects and animations
:: - Disable Aero Peek
:: - Disable taskbar animations
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Registry Performance Tweaks
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

echo This script will apply the following performance tweaks:
echo  - Disable window animations
echo  - Disable taskbar animations
echo  - Disable Aero Peek
echo  - Optimize visual effects for performance
echo.
echo NOTE: This will make Windows feel snappier but less "pretty".
echo You can adjust visual effects in System Properties if needed.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo ============================================================================
echo  Disabling Visual Effects...
echo ============================================================================

echo Disabling window minimize/maximize animations...
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f

echo Disabling taskbar animations...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f

echo Disabling Aero Peek...
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f

echo.
echo ============================================================================
echo  Performance registry tweaks applied successfully!
echo ============================================================================
echo.
echo NOTE: To restore visual effects, go to:
echo System Properties ^> Advanced ^> Performance Settings
echo and select "Let Windows choose what's best for my computer"
echo.
echo A reboot or sign-out may be needed for all changes to take effect.
echo.

pause
