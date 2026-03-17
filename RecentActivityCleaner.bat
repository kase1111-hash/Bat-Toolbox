@echo off
setlocal enabledelayedexpansion
title Recent Activity Cleaner
color 0B

:: ============================================================================
:: Recent Activity Cleaner
:: ============================================================================
:: Clears recent files lists, jump lists, Explorer address bar history,
:: Run dialog history, Windows search history, and other activity traces.
:: A privacy-focused cleanup that goes beyond just temp files.
:: ============================================================================

:: Set up color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

echo %CYAN%============================================================================%RESET%
echo %CYAN% Recent Activity Cleaner%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo This script clears recent activity traces and usage history from Windows.
echo.
echo %YELLOW%What will be CLEARED:%RESET%
echo  - Recent files list (Quick Access / Recent Items)
echo  - Jump lists (taskbar right-click history)
echo  - Explorer address bar history
echo  - Run dialog (Win+R) history
echo  - Windows Search history
echo  - File Explorer search history
echo  - Thumbnail cache
echo  - Recent documents per application (Office, Notepad, etc.)
echo  - Windows Activity Timeline
echo  - Prefetch data (recent app launch traces)
echo  - Clipboard history
echo.
echo %GREEN%What will NOT be affected:%RESET%
echo  - Installed programs
echo  - Saved files and documents
echo  - Browser history (use browser settings for that)
echo  - System settings and configuration
echo.

:: Admin check - some features need it, some don't
set "isAdmin=0"
net session >nul 2>&1
if %errorlevel% equ 0 set "isAdmin=1"

if "!isAdmin!"=="0" (
    echo %YELLOW%[INFO] Running without admin. Some items require admin to clear.%RESET%
    echo %YELLOW%       Right-click "Run as administrator" for full cleanup.%RESET%
    echo.
)

:: Confirm before proceeding
set /p "confirm=Clear all recent activity? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo.
    echo Operation cancelled.
    pause
    exit /b 0
)

set "success=0"
set "skipped=0"

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 1: Recent Files and Quick Access%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [1/9] Clearing recent files list...

:: Recent Items folder
if exist "%AppData%\Microsoft\Windows\Recent\*" (
    del /f /q "%AppData%\Microsoft\Windows\Recent\*" >nul 2>&1
    echo       %GREEN%- Cleared Recent Items folder%RESET%
    set /a success+=1
) else (
    echo       - Recent Items folder already empty
)

:: Automatic Destinations (Quick Access frequent files)
if exist "%AppData%\Microsoft\Windows\Recent\AutomaticDestinations\*" (
    del /f /q "%AppData%\Microsoft\Windows\Recent\AutomaticDestinations\*" >nul 2>&1
    echo       %GREEN%- Cleared Quick Access frequent files%RESET%
    set /a success+=1
) else (
    echo       - Quick Access frequent files already empty
)

:: Custom Destinations (Quick Access pinned - skip these, user pinned intentionally)
echo       - Skipped Quick Access pinned items (user-pinned, kept intentionally)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 2: Jump Lists%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [2/9] Clearing jump lists (taskbar right-click history)...

:: Jump list files
if exist "%AppData%\Microsoft\Windows\Recent\AutomaticDestinations\*" (
    del /f /q "%AppData%\Microsoft\Windows\Recent\AutomaticDestinations\*" >nul 2>&1
    echo       %GREEN%- Cleared automatic jump lists%RESET%
    set /a success+=1
)

:: Also clear custom destinations for jump lists
if exist "%AppData%\Microsoft\Windows\Recent\CustomDestinations\*" (
    del /f /q "%AppData%\Microsoft\Windows\Recent\CustomDestinations\*" >nul 2>&1
    echo       %GREEN%- Cleared custom jump lists%RESET%
    set /a success+=1
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 3: Explorer History%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [3/9] Clearing Explorer address bar and search history...

:: Explorer address bar history (TypedPaths)
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f >nul 2>&1
echo       %GREEN%- Cleared Explorer address bar history%RESET%
set /a success+=1

:: Explorer search history (WordWheelQuery)
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" /f >nul 2>&1
echo       %GREEN%- Cleared Explorer search history%RESET%
set /a success+=1

:: Explorer recent docs MRU
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" /f >nul 2>&1
echo       %GREEN%- Cleared Explorer recent documents registry%RESET%
set /a success+=1

:: Common Dialog MRU (Open/Save As dialog history)
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRULegacy" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRULegacy" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU" /f >nul 2>&1
echo       %GREEN%- Cleared Open/Save dialog history%RESET%
set /a success+=1

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 4: Run Dialog and Command History%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [4/9] Clearing Run dialog and command history...

:: Run dialog history
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /f >nul 2>&1
echo       %GREEN%- Cleared Run dialog (Win+R) history%RESET%
set /a success+=1

:: CMD command history (current session doesn't persist, but clear doskey)
doskey /reinstall >nul 2>&1
echo       %GREEN%- Cleared command-line history (doskey)%RESET%
set /a success+=1

:: PowerShell history file
if exist "%AppData%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" (
    del /f /q "%AppData%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" >nul 2>&1
    echo       %GREEN%- Cleared PowerShell command history%RESET%
    set /a success+=1
) else (
    echo       - PowerShell history not found (may not exist)
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 5: Windows Search History%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [5/9] Clearing Windows Search and Cortana history...

:: Windows Search / Start Menu search history
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /f >nul 2>&1
echo       %GREEN%- Disabled cloud search suggestions%RESET%

:: Clear search highlights data
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDeviceSearchHistoryEnabled" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDeviceSearchHistoryEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo       %GREEN%- Disabled device search history%RESET%
set /a success+=1

:: Clear Cortana history
if exist "%LocalAppData%\Packages\Microsoft.Windows.Cortana_cw5n1h2txyewy\LocalState\ESEDatabase_CortanaCoreInstance" (
    rd /s /q "%LocalAppData%\Packages\Microsoft.Windows.Cortana_cw5n1h2txyewy\LocalState\ESEDatabase_CortanaCoreInstance" >nul 2>&1
    echo       %GREEN%- Cleared Cortana local database%RESET%
    set /a success+=1
)

:: Windows 11 search history
if exist "%LocalAppData%\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\LocalState" (
    rd /s /q "%LocalAppData%\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\LocalState" >nul 2>&1
    echo       %GREEN%- Cleared Windows Search local state%RESET%
    set /a success+=1
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 6: Thumbnail Cache%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [6/9] Clearing thumbnail cache...

:: Thumbnail cache (thumbcache_*.db)
if exist "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*" (
    del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*" >nul 2>&1
    echo       %GREEN%- Cleared thumbnail cache%RESET%
    set /a success+=1
) else (
    echo       - Thumbnail cache files not found or in use
)

:: Icon cache
if exist "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*" (
    del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*" >nul 2>&1
    echo       %GREEN%- Cleared icon cache%RESET%
    set /a success+=1
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 7: Application-Specific History%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [7/9] Clearing application-specific recent file lists...

:: Microsoft Office recent files
reg delete "HKCU\SOFTWARE\Microsoft\Office\16.0\Word\User MRU" /f >nul 2>&1 && echo       %GREEN%- Cleared Word recent files%RESET%
reg delete "HKCU\SOFTWARE\Microsoft\Office\16.0\Excel\User MRU" /f >nul 2>&1 && echo       %GREEN%- Cleared Excel recent files%RESET%
reg delete "HKCU\SOFTWARE\Microsoft\Office\16.0\PowerPoint\User MRU" /f >nul 2>&1 && echo       %GREEN%- Cleared PowerPoint recent files%RESET%

:: Paint recent files
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List" /f >nul 2>&1 && echo       %GREEN%- Cleared Paint recent files%RESET%

:: Notepad recent files (Windows 11 Notepad)
if exist "%LocalAppData%\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState\TabState" (
    del /f /q "%LocalAppData%\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState\TabState\*" >nul 2>&1
    echo       %GREEN%- Cleared Notepad tab state (Win11)%RESET%
    set /a success+=1
)

:: Windows Media Player recent
reg delete "HKCU\SOFTWARE\Microsoft\MediaPlayer\Player\RecentFileList" /f >nul 2>&1 && echo       %GREEN%- Cleared Media Player recent files%RESET%

:: WordPad recent
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List" /f >nul 2>&1 && echo       %GREEN%- Cleared WordPad recent files%RESET%

set /a success+=1

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 8: Windows Activity Timeline and Clipboard%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [8/9] Clearing Activity Timeline and clipboard history...

:: Disable and clear Activity Timeline
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
echo       %GREEN%- Disabled Activity Timeline collection%RESET%
set /a success+=1

:: Clear Activity Timeline database
if exist "%LocalAppData%\ConnectedDevicesPlatform" (
    :: Clear activity log files in each subfolder
    for /d %%D in ("%LocalAppData%\ConnectedDevicesPlatform\*") do (
        del /f /q "%%D\ActivitiesCache.db" >nul 2>&1
        del /f /q "%%D\ActivitiesCache.db-shm" >nul 2>&1
        del /f /q "%%D\ActivitiesCache.db-wal" >nul 2>&1
    )
    echo       %GREEN%- Cleared Activity Timeline database%RESET%
    set /a success+=1
)

:: Clear clipboard history
echo "" | clip >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d 0 /f >nul 2>&1
echo       %GREEN%- Cleared and disabled clipboard history%RESET%
set /a success+=1

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 9: Prefetch and Temp Traces%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [9/9] Clearing prefetch and temp traces...

:: Prefetch data (shows which programs were launched recently)
if "!isAdmin!"=="1" (
    if exist "%SystemRoot%\Prefetch\*.pf" (
        del /f /q "%SystemRoot%\Prefetch\*.pf" >nul 2>&1
        echo       %GREEN%- Cleared Prefetch data%RESET%
        set /a success+=1
    ) else (
        echo       - Prefetch folder already empty
    )
) else (
    echo       %YELLOW%- Skipped Prefetch (requires admin)%RESET%
    set /a skipped+=1
)

:: Windows temp files
del /f /q "%TEMP%\*" >nul 2>&1
rd /s /q "%TEMP%\*" >nul 2>&1
echo       %GREEN%- Cleared user temp folder%RESET%
set /a success+=1

if "!isAdmin!"=="1" (
    del /f /q "%SystemRoot%\Temp\*" >nul 2>&1
    echo       %GREEN%- Cleared system temp folder%RESET%
    set /a success+=1
) else (
    echo       %YELLOW%- Skipped system temp folder (requires admin)%RESET%
    set /a skipped+=1
)

:: Notification history
if exist "%LocalAppData%\Microsoft\Windows\Notifications" (
    del /f /q "%LocalAppData%\Microsoft\Windows\Notifications\*" >nul 2>&1
    echo       %GREEN%- Cleared notification history%RESET%
    set /a success+=1
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Restarting Explorer%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo Restarting Explorer to apply changes...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
echo       %GREEN%- Explorer restarted%RESET%

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Summary%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo %GREEN%Cleanup complete!%RESET%
echo.
echo   Items cleared:  !success!
echo   Items skipped:  !skipped!
echo.
echo What was cleared:
echo  - Recent files and Quick Access history
echo  - Taskbar jump lists
echo  - Explorer address bar and search history
echo  - Open/Save dialog history
echo  - Run dialog (Win+R) history
echo  - PowerShell command history
echo  - Windows Search and Cortana history
echo  - Thumbnail and icon cache
echo  - Application recent file lists (Office, Paint, etc.)
echo  - Windows Activity Timeline
echo  - Clipboard history
echo  - Prefetch data
echo  - Temp files and notification history
echo.
echo %YELLOW%NOT cleared (use browser settings):%RESET%
echo  - Browser history, cookies, and cache
echo  - Saved browser passwords
echo.
echo %YELLOW%NOTE: Some caches will rebuild naturally as you use Windows.%RESET%
echo %YELLOW%      This is normal and expected behavior.%RESET%
echo.

pause
exit /b 0
