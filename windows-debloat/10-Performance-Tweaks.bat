@echo off
:: ============================================================================
:: Windows 10 Debloat - Performance Optimizations
:: ============================================================================
:: This script applies various performance optimizations:
:: - Disable hibernation (saves disk space)
:: - Clear temp files
:: - Disable Prefetch/Superfetch (for SSD systems)
:: - Disable Windows Search indexing
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Performance Optimizations
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

echo This script will apply the following optimizations:
echo.
echo  1. Disable Hibernation
echo     - Saves disk space (hiberfil.sys can be several GB)
echo     - Not needed if you shut down instead of hibernate
echo.
echo  2. Clear Temporary Files
echo     - Removes files from TEMP and Windows\Temp folders
echo.
echo  3. Disable Prefetch/Superfetch (SysMain)
echo     - Recommended for SSD systems
echo     - May improve performance by reducing disk writes
echo.
echo  4. Disable Windows Search Indexing
echo     - Reduces disk activity
echo     - Consider using "Everything" search as alternative
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo ============================================================================
echo  Disabling Hibernation...
echo ============================================================================

powercfg /hibernate off
echo Hibernation disabled. hiberfil.sys will be removed on reboot.

echo.
echo ============================================================================
echo  Clearing Temporary Files...
echo ============================================================================

echo Clearing user temp folder...
del /q /f /s "%TEMP%\*" 2>nul

echo Clearing Windows temp folder...
del /q /f /s "%SystemRoot%\Temp\*" 2>nul

echo Temp files cleared.

echo.
echo ============================================================================
echo  Disabling Prefetch/Superfetch (SysMain)...
echo ============================================================================

echo Disabling SysMain service...
sc config SysMain start=disabled >nul 2>&1
net stop SysMain >nul 2>&1

echo Disabling Prefetch in registry...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f >nul

echo Prefetch/Superfetch disabled.

echo.
echo ============================================================================
echo  Disabling Windows Search Indexing...
echo ============================================================================

echo Disabling WSearch service...
sc config WSearch start=disabled >nul 2>&1
net stop WSearch >nul 2>&1

echo Windows Search indexing disabled.

echo.
echo ============================================================================
echo  Performance optimizations applied successfully!
echo ============================================================================
echo.
echo NOTES:
echo  - Consider installing "Everything" search (voidtools.com) as a
echo    faster alternative to Windows Search
echo  - If you use a HDD (not SSD), you may want to re-enable Superfetch:
echo      sc config SysMain start=auto
echo      net start SysMain
echo.
echo A reboot is recommended to complete all changes.
echo.

pause
