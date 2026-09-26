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

:: HKCU and %UserProfile% belong to the account this elevated window runs as.
:: If a standard user elevated with another admin's credentials, that is NOT the
:: signed-in user, so warn before changing the wrong account's settings.
set "CONSOLE_USER="
for /f "delims=" %%u in ('powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).UserName" 2^>nul') do set "CONSOLE_USER=%%u"
if not defined CONSOLE_USER goto :user_ok
if /i "%CONSOLE_USER%"=="%USERDOMAIN%\%USERNAME%" goto :user_ok
echo WARNING: This window runs as "%USERDOMAIN%\%USERNAME%", but "%CONSOLE_USER%" is signed in.
echo Per-user settings and files will be changed for "%USERNAME%" only, NOT for "%CONSOLE_USER%".
echo To change them for "%CONSOLE_USER%", that account must be an administrator and run this script itself.
echo/
choice /c YN /m "Continue anyway"
if %errorlevel% neq 1 exit /b 1
echo/
:user_ok

echo This script will apply the following performance tweaks:
echo  - Disable window animations
echo  - Disable taskbar animations
echo  - Disable Aero Peek
echo  - Optimize visual effects for performance
echo/
echo NOTE: This will make Windows feel snappier but less "pretty".
echo You can adjust visual effects in System Properties if needed.
echo/
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo/
echo ============================================================================
echo  Disabling Visual Effects...
echo ============================================================================

echo Disabling window minimize/maximize animations...
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f

echo Disabling taskbar animations...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f

echo Disabling Aero Peek...
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f

echo/
echo ============================================================================
echo  Performance registry tweaks applied successfully!
echo ============================================================================
echo/
echo NOTE: To restore visual effects, go to:
echo System Properties ^> Advanced ^> Performance Settings
echo and select "Let Windows choose what's best for my computer"
echo/
echo A reboot or sign-out may be needed for all changes to take effect.
echo/

pause
