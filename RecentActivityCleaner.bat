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
echo/

echo This script clears recent activity traces and usage history from Windows.
echo/
echo %YELLOW%What will be CLEARED:%RESET%
echo  - Recent files list (Quick Access / Recent Items)
echo  - Jump lists (taskbar right-click history, INCLUDING items pinned in them)
echo  - Explorer address bar history
echo  - Run dialog (Win+R) history
echo  - Windows Search history
echo  - File Explorer search history
echo  - Thumbnail cache
echo  - Recent documents per application (Office, Notepad, etc.)
echo  - Windows Activity Timeline
echo  - Prefetch data (recent app launch traces)
echo  - Clipboard history
echo/
echo %GREEN%What will NOT be affected:%RESET%
echo  - Installed programs
echo  - Saved files and documents
echo  - Browser history (use browser settings for that)
echo  - Quick Access pinned and frequent folders
echo  - File Explorer Favorites (pinned files, Windows 11)
echo  - Other system settings. Only these are turned off: device search history,
echo    cloud content search, clipboard history and, with admin, the Activity
echo    history policy. The README explains how to turn them back on.
echo/

:: Admin check - some features need it, some don't
set "isAdmin=0"
net session >nul 2>&1
if %errorlevel% equ 0 set "isAdmin=1"

:: When a standard user elevates with another account's credentials, %AppData%,
:: %LocalAppData%, %TEMP% and HKCU all belong to that admin account, so the
:: cleanup would hit the wrong profile. Compare against the owner of this
:: session's Explorer and stop if they differ.
if "!isAdmin!"=="1" (
    set "shellUser="
    for /f "usebackq delims=" %%u in (`powershell -NoProfile -Command "$s=(Get-Process -Id $PID).SessionId; $me=[Security.Principal.WindowsIdentity]::GetCurrent().Name; $owner=(Get-Process explorer -IncludeUserName -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $s } | Select-Object -First 1).UserName; if ($owner -and $owner -ne $me) { $owner }"`) do set "shellUser=%%u"
    if defined shellUser (
        echo %RED%[ERROR] Elevated as !USERDOMAIN!\!USERNAME!, but this desktop belongs to !shellUser!.%RESET%
        echo %RED%        Run the script WITHOUT "Run as administrator" to clean that user's history.%RESET%
        pause
        exit /b 1
    )
)

if "!isAdmin!"=="0" (
    echo %YELLOW%[INFO] Running without admin. Some items require admin to clear.%RESET%
    echo %YELLOW%       Right-click "Run as administrator" for full cleanup.%RESET%
    echo/
)

:: Confirm before proceeding
set "confirm="
set /p "confirm=Clear all recent activity? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo/
    echo Operation cancelled.
    pause
    exit /b 0
)

set "success=0"
set "skipped=0"

:: Windows 11 Notepad keeps the ONLY copy of unsaved tabs in TabState, so ask
:: now (before Explorer is stopped in Phase 6) instead of deleting silently.
set "tabState=%LocalAppData%\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState\TabState"
set "clearNotepadTabs=0"
if exist "%tabState%\*.bin" (
    echo/
    echo %YELLOW%Windows 11 Notepad keeps the text of UNSAVED Notepad tabs in its tab state.%RESET%
    echo %YELLOW%Deleting it permanently discards that text. Close Notepad first if you answer Y.%RESET%
    choice /c YN /m "Also delete unsaved Notepad tabs"
    if !errorlevel! equ 1 set "clearNotepadTabs=1"
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 1: Recent Files and Quick Access%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [1/9] Clearing recent files list...

:: Recent Items folder
if exist "%AppData%\Microsoft\Windows\Recent\*" (
    del /f /q "%AppData%\Microsoft\Windows\Recent\*" >nul 2>&1
    echo       %GREEN%- Cleared Recent Items folder%RESET%
    set /a success+=1
) else (
    echo       - Recent Items folder already empty
)

:: Quick Access pinned AND frequent folders are stored together in Explorer's own
:: jump list (AutomaticDestinations\f01b4d95cf55d32a.automaticDestinations-ms).
:: Deleting that file would unpin every folder, so Phase 2 keeps it.
:: File Explorer Favorites (pinned files, Windows 11) live in Explorer's other
:: list (5f7b5f1e01b83767), which also holds Explorer's own recent/pinned file
:: entries. Deleting it would remove every Favorite, so Phase 2 keeps it too.
echo       %YELLOW%- Kept Quick Access pinned and frequent folders ^(stored together in one file^)%RESET%
echo       %YELLOW%- Kept File Explorer Favorites ^(pinned files, Windows 11^)%RESET%

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 2: Jump Lists%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [2/9] Clearing jump lists (taskbar right-click history)...

:: AutomaticDestinations = every app's jump list (including pinned jump-list items).
:: f01b4d95cf55d32a is Explorer's Quick Access list (pinned AND frequent folders) - keep it.
:: 5f7b5f1e01b83767 holds File Explorer Favorites (pinned files, Windows 11) - keep it.
set "qaFile=f01b4d95cf55d32a.automaticDestinations-ms"
set "favFile=5f7b5f1e01b83767.automaticDestinations-ms"
if exist "%AppData%\Microsoft\Windows\Recent\AutomaticDestinations\*" (
    for %%F in ("%AppData%\Microsoft\Windows\Recent\AutomaticDestinations\*") do (
        if /i not "%%~nxF"=="!qaFile!" if /i not "%%~nxF"=="!favFile!" del /f /q "%%F" >nul 2>&1
    )
    echo       %GREEN%- Cleared automatic jump lists ^(pinned jump-list items included^)%RESET%
    set /a success+=1
)

:: Custom jump lists (some apps keep their pinned jump-list items here too)
if exist "%AppData%\Microsoft\Windows\Recent\CustomDestinations\*" (
    del /f /q "%AppData%\Microsoft\Windows\Recent\CustomDestinations\*" >nul 2>&1
    echo       %GREEN%- Cleared custom jump lists%RESET%
    set /a success+=1
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 3: Explorer History%RESET%
echo %CYAN%============================================================================%RESET%
echo/

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

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 4: Run Dialog and Command History%RESET%
echo %CYAN%============================================================================%RESET%
echo/

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
    echo       - PowerShell history not found ^(may not exist^)
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 5: Windows Search History%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [5/9] Clearing Windows Search and Cortana history...

:: Cloud content search toggles (Win11: Settings, Privacy and security, Search
:: permissions; Win10: Settings, Search, Permissions and History).
:: 0 = off; a missing value means the Windows default, which is ON.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo       %GREEN%- Disabled cloud content search%RESET%

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

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 6: Thumbnail Cache%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [6/9] Clearing thumbnail cache...

:: Explorer holds thumbcache/iconcache open; stop it now (restarted at the end of the script)
echo       %YELLOW%- Stopping Explorer until the end of the script ^(taskbar and desktop disappear^)%RESET%
echo       %YELLOW%  If this window is closed early: Ctrl+Shift+Esc, Run new task, explorer%RESET%
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: Thumbnail cache (thumbcache_*.db). Other processes (thumbnail surrogate,
:: file dialogs) can still hold a file, so check what is left after the delete.
if exist "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" (
    del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
    if exist "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" (
        echo       %YELLOW%- Some thumbnail cache files are in use and were not deleted%RESET%
        set /a skipped+=1
    ) else (
        echo       %GREEN%- Cleared thumbnail cache%RESET%
        set /a success+=1
    )
) else (
    echo       - Thumbnail cache files not found
)

:: Icon cache (iconcache_*.db)
if exist "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*.db" (
    del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1
    if exist "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*.db" (
        echo       %YELLOW%- Some icon cache files are in use and were not deleted%RESET%
        set /a skipped+=1
    ) else (
        echo       %GREEN%- Cleared icon cache%RESET%
        set /a success+=1
    )
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 7: Application-Specific History%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [7/9] Clearing application-specific recent file lists...

:: Microsoft Office recent files
reg delete "HKCU\SOFTWARE\Microsoft\Office\16.0\Word\User MRU" /f >nul 2>&1 && echo       %GREEN%- Cleared Word recent files%RESET%
reg delete "HKCU\SOFTWARE\Microsoft\Office\16.0\Excel\User MRU" /f >nul 2>&1 && echo       %GREEN%- Cleared Excel recent files%RESET%
reg delete "HKCU\SOFTWARE\Microsoft\Office\16.0\PowerPoint\User MRU" /f >nul 2>&1 && echo       %GREEN%- Cleared PowerPoint recent files%RESET%

:: Paint recent files
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List" /f >nul 2>&1 && echo       %GREEN%- Cleared Paint recent files%RESET%

:: Notepad tab state (Windows 11). TabState is the ONLY copy of unsaved Notepad
:: tabs, so it is deleted only if the user said Y at the start and Notepad is closed.
if exist "%tabState%\*.bin" (
    if "!clearNotepadTabs!"=="1" (
        tasklist /fi "imagename eq Notepad.exe" 2>nul | find /i "Notepad.exe" >nul
        if !errorlevel! equ 0 (
            echo       %YELLOW%- Skipped Notepad tab state: Notepad is running%RESET%
            set /a skipped+=1
        ) else (
            del /f /q "%tabState%\*" >nul 2>&1
            echo       %GREEN%- Cleared Notepad tab state ^(Win11^)%RESET%
            set /a success+=1
        )
    ) else (
        echo       - Kept Notepad tab state ^(unsaved Notepad tabs^)
        set /a skipped+=1
    )
)

:: Windows Media Player recent
reg delete "HKCU\SOFTWARE\Microsoft\MediaPlayer\Player\RecentFileList" /f >nul 2>&1 && echo       %GREEN%- Cleared Media Player recent files%RESET%

:: WordPad recent
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List" /f >nul 2>&1 && echo       %GREEN%- Cleared WordPad recent files%RESET%

set /a success+=1

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 8: Windows Activity Timeline and Clipboard%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [8/9] Clearing Activity Timeline and clipboard history...

:: Disable Activity Timeline (machine-wide policy for every account - admin only;
:: the README explains how to remove it again)
if "!isAdmin!"=="1" (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
    echo       %GREEN%- Disabled Activity Timeline collection ^(machine policy^)%RESET%
    set /a success+=1
) else (
    echo       %YELLOW%- Skipped Activity Timeline policy ^(requires admin^)%RESET%
    set /a skipped+=1
)

:: Clear Activity Timeline database. The per-user CDPUserSvc_* service keeps
:: ActivitiesCache.db open; with admin it is stopped briefly and started again.
if exist "%LocalAppData%\ConnectedDevicesPlatform" (
    if "!isAdmin!"=="1" powershell -NoProfile -Command "Get-Service CDPUserSvc_* -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue" >nul 2>&1
    set "timelineLeft=0"
    REM Clear activity log files in each subfolder
    for /d %%D in ("%LocalAppData%\ConnectedDevicesPlatform\*") do (
        del /f /q "%%D\ActivitiesCache.db" >nul 2>&1
        del /f /q "%%D\ActivitiesCache.db-shm" >nul 2>&1
        del /f /q "%%D\ActivitiesCache.db-wal" >nul 2>&1
        if exist "%%D\ActivitiesCache.db" set "timelineLeft=1"
    )
    if "!isAdmin!"=="1" powershell -NoProfile -Command "Get-Service CDPUserSvc_* -ErrorAction SilentlyContinue | Start-Service -ErrorAction SilentlyContinue" >nul 2>&1
    if "!timelineLeft!"=="1" (
        echo       %YELLOW%- Activity Timeline database is in use - not cleared%RESET%
        set /a skipped+=1
    ) else (
        echo       %GREEN%- Cleared Activity Timeline database%RESET%
        set /a success+=1
    )
)

:: Clear clipboard history
echo "" | clip >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d 0 /f >nul 2>&1
echo       %GREEN%- Cleared and disabled clipboard history%RESET%
set /a success+=1

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 9: Prefetch and Temp Traces%RESET%
echo %CYAN%============================================================================%RESET%
echo/

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
    echo       %YELLOW%- Skipped Prefetch ^(requires admin^)%RESET%
    set /a skipped+=1
)

:: Windows temp files. "rd" does not accept wildcards, so removing subfolders
:: needs a loop over each directory under %TEMP%.
:: Skip it when this script itself runs from inside %TEMP% (e.g. double-clicked
:: inside a ZIP): deleting the running .bat aborts the script. Compare the short
:: 8.3 forms of both paths, because %TEMP% is often stored in short form.
:: cmd string substitution is case-insensitive.
set "selfShort=%~sdp0"
for %%T in ("%TEMP%") do set "tempShort=%%~sT\"
if /i "!selfShort:%tempShort%=!"=="!selfShort!" (
    del /f /q "%TEMP%\*" >nul 2>&1
    for /d %%d in ("%TEMP%\*") do rd /s /q "%%d" >nul 2>&1
    echo       %GREEN%- Cleared user temp folder%RESET%
    set /a success+=1
) else (
    echo       %YELLOW%- Skipped user temp folder: this script is running from inside it%RESET%
    echo       %YELLOW%  ^(extract the ZIP to a normal folder and run it from there^)%RESET%
    set /a skipped+=1
)

if "!isAdmin!"=="1" (
    del /f /q "%SystemRoot%\Temp\*" >nul 2>&1
    echo       %GREEN%- Cleared system temp folder%RESET%
    set /a success+=1
) else (
    echo       %YELLOW%- Skipped system temp folder ^(requires admin^)%RESET%
    set /a skipped+=1
)

:: Notification history. The per-user WpnUserService_* service keeps
:: wpndatabase.db open; with admin it is stopped briefly and started again.
if exist "%LocalAppData%\Microsoft\Windows\Notifications" (
    if "!isAdmin!"=="1" powershell -NoProfile -Command "Get-Service WpnUserService_* -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue" >nul 2>&1
    del /f /q "%LocalAppData%\Microsoft\Windows\Notifications\*" >nul 2>&1
    REM Check before the service is started again, because it recreates the file
    set "notifyLeft=0"
    if exist "%LocalAppData%\Microsoft\Windows\Notifications\wpndatabase.db" set "notifyLeft=1"
    if "!isAdmin!"=="1" powershell -NoProfile -Command "Get-Service WpnUserService_* -ErrorAction SilentlyContinue | Start-Service -ErrorAction SilentlyContinue" >nul 2>&1
    if "!notifyLeft!"=="1" (
        echo       %YELLOW%- Notification history is in use - not cleared%RESET%
        set /a skipped+=1
    ) else (
        echo       %GREEN%- Cleared notification history%RESET%
        set /a success+=1
    )
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Restarting Explorer%RESET%
echo %CYAN%============================================================================%RESET%
echo/

:: Explorer was stopped at the start of Phase 6 so the caches could be deleted
echo Starting Explorer again to apply changes...
start explorer.exe
echo       %GREEN%- Explorer restarted%RESET%

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Summary%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo %GREEN%Cleanup complete^^!%RESET%
echo/
echo   Items cleared:  !success!
echo   Items skipped:  !skipped!
echo/
echo What this script clears (anything skipped or in use is listed above):
echo  - Recent files list (Quick Access pinned and frequent folders are kept, and
echo    File Explorer Favorites - pinned files, Windows 11 - are kept)
echo  - Taskbar jump lists, including items pinned in them
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
echo/
echo %YELLOW%NOT cleared (use browser settings):%RESET%
echo  - Browser history, cookies, and cache
echo  - Saved browser passwords
echo/
echo %YELLOW%NOTE: Some caches will rebuild naturally as you use Windows.%RESET%
echo %YELLOW%      This is normal and expected behavior.%RESET%
echo/

pause
exit /b 0
