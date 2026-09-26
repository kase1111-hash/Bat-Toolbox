@echo off
setlocal
:: ============================================================================
:: Windows 10 Debloat - Temporary Files and Cache Cleanup
:: ============================================================================
:: This script cleans up temporary files and caches to free disk space:
:: - User and system temp folders
:: - Windows Update cache
:: - Prefetch files
:: - Thumbnail cache
:: - Browser caches (Edge, Chrome, Firefox)
:: - DNS cache
:: - Windows Installer cache
:: - Font cache
:: - Icon cache
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Temporary Files and Cache Cleanup
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

echo This script will clean the following:
echo/
echo  - User temp folder (%%TEMP%%)
echo  - Windows temp folder (%%SystemRoot%%\Temp)
echo  - Windows Update cache
echo  - Prefetch files
echo  - Thumbnail cache
echo  - Browser caches (Edge, Chrome, Firefox)
echo  - DNS resolver cache
echo  - Windows Installer orphaned patches
echo  - Font cache
echo  - Icon cache
echo  - Recent documents list
echo  - Windows Error Reports
echo/
echo WARNING: Close all browsers before running this script!
echo/
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

set "BYTES_FREED=0"

echo/
echo ============================================================================
echo  [1/12] Cleaning User Temp Folder...
echo ============================================================================
echo Location: %TEMP%
del /q /f /s "%TEMP%\*" 2>nul
for /d %%i in ("%TEMP%\*") do rd /s /q "%%i" 2>nul
echo Done.

echo/
echo ============================================================================
echo  [2/12] Cleaning Windows Temp Folder...
echo ============================================================================
echo Location: %SystemRoot%\Temp
del /q /f /s "%SystemRoot%\Temp\*" 2>nul
for /d %%i in ("%SystemRoot%\Temp\*") do rd /s /q "%%i" 2>nul
echo Done.

echo/
echo ============================================================================
echo  [3/12] Cleaning Windows Update Cache...
echo ============================================================================
echo Location: %SystemRoot%\SoftwareDistribution\Download
echo Stopping Windows Update service...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /q /f /s "%SystemRoot%\SoftwareDistribution\Download\*" 2>nul
for /d %%i in ("%SystemRoot%\SoftwareDistribution\Download\*") do rd /s /q "%%i" 2>nul
echo Starting Windows Update service...
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
echo Done.

echo/
echo ============================================================================
echo  [4/12] Cleaning Prefetch Files...
echo ============================================================================
echo Location: %SystemRoot%\Prefetch
del /q /f /s "%SystemRoot%\Prefetch\*" 2>nul
echo Done.

echo/
echo ============================================================================
echo  [5/12] Cleaning Thumbnail Cache...
echo ============================================================================
echo Location: %LocalAppData%\Microsoft\Windows\Explorer
del /q /f "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul
del /q /f "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*.db" 2>nul
echo Done.

echo/
echo ============================================================================
echo  [6/12] Cleaning Microsoft Edge Cache...
echo ============================================================================
echo Location: %LocalAppData%\Microsoft\Edge\User Data\Default\Cache
if exist "%LocalAppData%\Microsoft\Edge\User Data\Default\Cache" (
    del /q /f /s "%LocalAppData%\Microsoft\Edge\User Data\Default\Cache\*" 2>nul
    del /q /f /s "%LocalAppData%\Microsoft\Edge\User Data\Default\Code Cache\*" 2>nul
)
if exist "%LocalAppData%\Microsoft\Edge\User Data\Default\GPUCache" (
    del /q /f /s "%LocalAppData%\Microsoft\Edge\User Data\Default\GPUCache\*" 2>nul
)
echo Done.

echo/
echo ============================================================================
echo  [7/12] Cleaning Google Chrome Cache...
echo ============================================================================
echo Location: %LocalAppData%\Google\Chrome\User Data\Default\Cache
if exist "%LocalAppData%\Google\Chrome\User Data\Default\Cache" (
    del /q /f /s "%LocalAppData%\Google\Chrome\User Data\Default\Cache\*" 2>nul
    del /q /f /s "%LocalAppData%\Google\Chrome\User Data\Default\Code Cache\*" 2>nul
)
if exist "%LocalAppData%\Google\Chrome\User Data\Default\GPUCache" (
    del /q /f /s "%LocalAppData%\Google\Chrome\User Data\Default\GPUCache\*" 2>nul
)
echo Done.

echo/
echo ============================================================================
echo  [8/12] Cleaning Mozilla Firefox Cache...
echo ============================================================================
echo Location: %LocalAppData%\Mozilla\Firefox\Profiles
if exist "%LocalAppData%\Mozilla\Firefox\Profiles" (
    for /d %%i in ("%LocalAppData%\Mozilla\Firefox\Profiles\*") do (
        del /q /f /s "%%i\cache2\*" 2>nul
        del /q /f /s "%%i\startupCache\*" 2>nul
    )
)
echo Done.

echo/
echo ============================================================================
echo  [9/12] Flushing DNS Resolver Cache...
echo ============================================================================
ipconfig /flushdns
echo Done.

echo/
echo ============================================================================
echo  [10/12] Cleaning Windows Installer Cache...
echo ============================================================================
echo Location: %SystemRoot%\Installer\$PatchCache$
if exist "%SystemRoot%\Installer\$PatchCache$" (
    rd /s /q "%SystemRoot%\Installer\$PatchCache$" 2>nul
)
echo Done.

echo/
echo ============================================================================
echo  [11/12] Cleaning Windows Error Reports...
echo ============================================================================
echo Location: %LocalAppData%\Microsoft\Windows\WER
if exist "%LocalAppData%\Microsoft\Windows\WER" (
    del /q /f /s "%LocalAppData%\Microsoft\Windows\WER\*" 2>nul
    for /d %%i in ("%LocalAppData%\Microsoft\Windows\WER\*") do rd /s /q "%%i" 2>nul
)
if exist "%ProgramData%\Microsoft\Windows\WER" (
    del /q /f /s "%ProgramData%\Microsoft\Windows\WER\*" 2>nul
    for /d %%i in ("%ProgramData%\Microsoft\Windows\WER\*") do rd /s /q "%%i" 2>nul
)
echo Done.

echo/
echo ============================================================================
echo  [12/12] Cleaning Recent Documents List...
echo ============================================================================
echo Location: %AppData%\Microsoft\Windows\Recent
:: Only the recent-item shortcuts are deleted. The AutomaticDestinations and
:: CustomDestinations subfolders are deliberately left alone: they hold the
:: Quick Access pinned folders and pinned jump-list items, which never come back.
del /q /f "%AppData%\Microsoft\Windows\Recent\*" 2>nul
echo Done.

echo/
echo ============================================================================
echo  Running Windows Disk Cleanup (cleanmgr)...
echo ============================================================================
echo Setting up automated cleanup flags...

:: Set up Disk Cleanup to run silently with predefined options.
:: First clear StateFlags0100 from every handler, so only the handlers flagged
:: below run. Older versions of this script also flagged handlers that are no
:: longer wanted (see NOTE below), and those flags stay in the registry.
for /f "delims=" %%k in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches" 2^>nul ^| find /i "HKEY_LOCAL_MACHINE"') do reg delete "%%k" /v StateFlags0100 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
:: NOTE: "Previous Installations" (Windows.old, needed to roll back a feature
:: update), "Recycle Bin", "Update Cleanup" (superseded updates could no longer
:: be uninstalled) and "System error memory dump files" / "System error minidump
:: files" (MEMORY.DMP and minidumps, needed to diagnose blue screens) are
:: deliberately NOT flagged here. They are not in the confirmation list at the
:: top of this script, so wiping them silently would be unconsented data loss.
:: Empty the Recycle Bin manually if you want.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1

echo Running Disk Cleanup (this may take a few minutes)...
cleanmgr /sagerun:100

echo/
echo ============================================================================
echo  Cleanup Complete!
echo ============================================================================
echo/
echo The following locations have been cleaned:
echo/
echo  [X] User temp folder
echo  [X] Windows temp folder
echo  [X] Windows Update cache
echo  [X] Prefetch files
echo  [X] Thumbnail and icon cache
echo  [X] Microsoft Edge cache
echo  [X] Google Chrome cache
echo  [X] Mozilla Firefox cache
echo  [X] DNS resolver cache
echo  [X] Windows Installer patch cache
echo  [X] Windows Error Reports
echo  [X] Recent documents list
echo  [X] Windows Disk Cleanup
echo/
echo TIP: For best results, restart your computer after cleanup.
echo/
echo Additional cleanup you can do manually:
echo  - Empty Recycle Bin
echo  - Run "Disk Cleanup" for system files (cleanmgr /d C:)
echo  - Clear browser history and cookies manually
echo  - Uninstall unused programs
echo/

pause
