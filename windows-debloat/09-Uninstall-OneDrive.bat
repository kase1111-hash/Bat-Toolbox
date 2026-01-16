@echo off
:: ============================================================================
:: Windows 10 Debloat - Uninstall OneDrive
:: ============================================================================
:: This script completely removes Microsoft OneDrive from the system,
:: including leftover folders and Explorer integration.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Uninstall OneDrive
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

echo This script will:
echo  - Stop and uninstall OneDrive
echo  - Remove OneDrive folders
echo  - Remove OneDrive from Explorer sidebar
echo.
echo WARNING: Any files stored only in OneDrive will be lost!
echo Make sure to sync/download important files first.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo ============================================================================
echo  Stopping OneDrive...
echo ============================================================================

taskkill /f /im OneDrive.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo.
echo ============================================================================
echo  Uninstalling OneDrive...
echo ============================================================================

:: Uninstall based on architecture
if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
    echo Running 64-bit uninstaller...
    "%SystemRoot%\System32\OneDriveSetup.exe" /uninstall
)

if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
    echo Running 32-bit uninstaller...
    "%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall
)

timeout /t 3 /nobreak >nul

echo.
echo ============================================================================
echo  Removing OneDrive Folders...
echo ============================================================================

echo Removing %UserProfile%\OneDrive...
rd "%UserProfile%\OneDrive" /q /s 2>nul

echo Removing %LocalAppData%\Microsoft\OneDrive...
rd "%LocalAppData%\Microsoft\OneDrive" /q /s 2>nul

echo Removing %ProgramData%\Microsoft OneDrive...
rd "%ProgramData%\Microsoft OneDrive" /q /s 2>nul

echo Removing C:\OneDriveTemp...
rd "C:\OneDriveTemp" /q /s 2>nul

echo.
echo ============================================================================
echo  Removing OneDrive from Explorer Sidebar...
echo ============================================================================

echo Removing OneDrive shell extension (64-bit)...
reg delete "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f 2>nul

echo Removing OneDrive shell extension (32-bit)...
reg delete "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f 2>nul

echo.
echo ============================================================================
echo  OneDrive removed successfully!
echo ============================================================================
echo.
echo NOTE: You may need to restart Explorer or reboot for the
echo sidebar changes to take effect.
echo.
echo To restart Explorer now, run: taskkill /f /im explorer.exe ^&^& explorer.exe
echo.

pause
