@echo off
setlocal
:: ============================================================================
:: Windows 10 Debloat - Uninstall OneDrive
:: ============================================================================
:: This script completely removes Microsoft OneDrive from the system,
:: including leftover folders and Explorer integration.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Uninstall OneDrive
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

echo This script will:
echo  - Stop and uninstall OneDrive
echo  - Remove leftover OneDrive program/cache folders
echo    ^(your %UserProfile%\OneDrive files folder is only removed if it is empty^)
echo  - Remove OneDrive from Explorer sidebar
echo/
echo NOTE: Files already uploaded stay in your OneDrive account online.
echo       %UserProfile%\OneDrive is kept unless empty - if Desktop/Documents/Pictures are backed up
echo       to OneDrive they live there; turn off folder backup in OneDrive settings first.
echo/
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo/
echo ============================================================================
echo  Stopping OneDrive...
echo ============================================================================

taskkill /f /im OneDrive.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo/
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

echo/
echo ============================================================================
echo  Removing OneDrive Folders...
echo ============================================================================

:: Never delete the user's OneDrive files folder recursively. With OneDrive
:: folder backup (Known Folder Move) Desktop/Documents/Pictures live inside it,
:: and files that were never uploaded would be lost for good. Plain "rd" (no /s)
:: only removes the folder when it is empty.
echo Checking %UserProfile%\OneDrive...
rd "%UserProfile%\OneDrive" 2>nul
if exist "%UserProfile%\OneDrive\" (
    echo   Kept "%UserProfile%\OneDrive" - it still contains files. Desktop/Documents/Pictures
    echo   may be stored there ^(OneDrive folder backup^). Move what you need out, then delete it manually.
)

echo Removing %LocalAppData%\Microsoft\OneDrive...
rd "%LocalAppData%\Microsoft\OneDrive" /q /s 2>nul

echo Removing %ProgramData%\Microsoft OneDrive...
rd "%ProgramData%\Microsoft OneDrive" /q /s 2>nul

echo Removing C:\OneDriveTemp...
rd "C:\OneDriveTemp" /q /s 2>nul

echo/
echo ============================================================================
echo  Removing OneDrive from Explorer Sidebar...
echo ============================================================================

echo Removing OneDrive shell extension (64-bit)...
reg delete "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f 2>nul

echo Removing OneDrive shell extension (32-bit)...
reg delete "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f 2>nul

echo/
echo ============================================================================
echo  OneDrive removed successfully!
echo ============================================================================
echo/
echo NOTE: You may need to restart Explorer or reboot for the
echo sidebar changes to take effect.
echo/
echo To restart Explorer now, run: taskkill /f /im explorer.exe ^&^& explorer.exe
echo/
echo To reinstall OneDrive later: if you ran 04-Registry-Privacy.bat, first run
echo   reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /f
echo then download OneDrive from Microsoft and sign out and back in.
echo/

pause
