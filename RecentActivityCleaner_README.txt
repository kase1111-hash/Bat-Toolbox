================================================================================
 RecentActivityCleaner.bat - Instructions
================================================================================

DESCRIPTION
-----------
Clears recent files lists, jump lists, Explorer address bar history, Run dialog
history, Windows Search history, and other activity traces. A privacy-focused
cleanup that goes beyond just temp files. Useful for shared computers, public
workstations, or anyone who values privacy.


HOW TO USE
----------
1. Right-click RecentActivityCleaner.bat
2. Select "Run as administrator" (RECOMMENDED for full cleanup)
3. Confirm when prompted (Y/N)
4. If Windows 11 Notepad has saved tab state, answer whether unsaved Notepad
   tabs may be deleted too (Y/N)
5. On Windows 11, answer whether the File Explorer Recent files list may be
   cleared too (Y/N). Windows 11 stores that list and your File Explorer
   Favorites (pinned files) in ONE file: Y clears the Recent files list AND
   removes every Favorite; N keeps both, so the whole File Explorer Recent
   files list stays. Windows 10 does not ask and always clears it
6. Wait for all phases to complete. Explorer (taskbar and desktop) is stopped
   at the start of Phase 6 and started again at the end
7. If the window is closed before the end, start Explorer again with
   Ctrl+Shift+Esc > Run new task > explorer

IMPORTANT - standard (non-admin) accounts:
  If you are signed in as a standard user and "Run as administrator" asks for
  another account's password, the script would run as THAT account and clean
  its history, not yours. The script detects this and stops. Run it WITHOUT
  "Run as administrator" to clean your own history (see ADMIN VS NON-ADMIN).


BEFORE YOU RUN
--------------
This script clears usage history. If you need any of the following, save
them first:
  - Recent files you need to find again
  - Run dialog commands you want to remember
  - PowerShell command history you may need
  - Clipboard contents you haven't pasted yet
  - Pinned items in taskbar jump lists (right-click menu pins are removed)
  - Unsaved Notepad tabs (Windows 11) - you will be asked before they are
    deleted, and they are skipped while Notepad is running
  - File Explorer Favorites (pinned files, Windows 11) - removed only if you
    answer Y to clearing the File Explorer Recent files list


WHAT GETS CLEARED
-----------------
Phase 1: Recent Files and Quick Access
  - Recent Items folder (%AppData%\Microsoft\Windows\Recent)
  - Note: Quick Access pinned and frequent folders are kept. Windows stores
    both in one file (AutomaticDestinations\f01b4d95cf55d32a...), so the
    frequent folders cannot be cleared without losing the pins
  - File Explorer Recent files list (AutomaticDestinations\5f7b5f1e01b83767...,
    deleted in Phase 2):
      Windows 10: this is the Quick Access Recent files list. It is always
        cleared (Quick Access pins only folders there, and those are kept)
      Windows 11: the File Explorer Home "Recent" list and your File Explorer
        Favorites (pinned files) are this one file. It is kept unless you
        answer Y at the start. If you answer N, the whole File Explorer Recent
        files list stays; if you answer Y, every Favorite is removed too.
        Files from Office.com (Microsoft account) come from the cloud and can
        still show; turn them off in Folder Options > Privacy

Phase 2: Jump Lists
  - Taskbar right-click recent files per application
  - Automatic and custom jump lists, INCLUDING items pinned inside taskbar
    jump lists. The Quick Access file (f01b4d95cf55d32a...) is always kept.
    The File Explorer Recent files list (5f7b5f1e01b83767...) is deleted on
    Windows 10, and on Windows 11 only if you answered Y (see Phase 1)

Phase 3: Explorer History
  - Address bar typed paths (TypedPaths registry)
  - File Explorer search history (WordWheelQuery)
  - Recent documents registry (RecentDocs)
  - Open/Save dialog folder history (ComDlg32 MRU)

Phase 4: Run Dialog and Command History
  - Win+R dialog history (RunMRU registry)
  - CMD doskey command history
  - PowerShell PSReadLine command history file

Phase 5: Windows Search History
  - Device search history is turned off (IsDeviceSearchHistoryEnabled = 0)
  - Cloud content search is turned off for Microsoft and work/school accounts
    (IsMSACloudSearchEnabled / IsAADCloudSearchEnabled = 0)
  - Cortana local database
  - Windows Search local state (Win11)

Phase 6: Thumbnail Cache
  - Explorer is stopped first, because it keeps these files open
  - Thumbnail cache files (thumbcache_*.db)
  - Icon cache files (iconcache_*.db)
  - Files that another program still holds open are reported as in use and
    counted as skipped

Phase 7: Application-Specific History
  - Microsoft Word recent files
  - Microsoft Excel recent files
  - Microsoft PowerPoint recent files
  - Paint recent files
  - WordPad recent files
  - Windows Media Player recent files
  - Notepad tab state (Windows 11). This is the ONLY copy of unsaved Notepad
    tabs, so it is deleted only if you answered Y at the start and Notepad is
    not running; otherwise it is kept

Phase 8: Windows Activity Timeline and Clipboard
  - Activity history policy (admin only): sets EnableActivityFeed,
    PublishUserActivities and UploadUserActivities = 0 under
    HKLM\SOFTWARE\Policies\Microsoft\Windows\System. This is a machine-wide
    policy: the Activity history settings are locked for EVERY account on the
    PC until it is removed (see HOW TO RESTORE / UNDO)
  - Activity Timeline database files (ActivitiesCache.db). With admin, the
    per-user CDPUserSvc_* service that keeps the file open is stopped briefly
    and started again; without admin an in-use database is reported as skipped
  - Clipboard history (cleared, and clipboard history is turned off)

Phase 9: Prefetch and Temp Traces
  - Prefetch data (app launch traces) - requires admin
  - User temp folder (skipped when the script itself runs from inside %TEMP%,
    for example when it was double-clicked inside a ZIP - extract it first)
  - System temp folder - requires admin
  - Notification history. With admin, the per-user WpnUserService_* service
    that keeps wpndatabase.db open is stopped briefly and started again;
    without admin an in-use database is reported as skipped


WHAT IS NOT CLEARED
-------------------
- Browser history, cookies, cache, and saved passwords
  (Use your browser's built-in clear data feature instead)
- Installed programs and their settings
- Saved files and documents
- Desktop files and shortcuts
- Quick Access pinned and frequent folders
- Windows 11, if you answered N: File Explorer Favorites (pinned files) and
  the whole File Explorer Home "Recent" files list, which share one file
  (on Windows 10 the Quick Access Recent files list is always cleared)
- Other system settings. The only settings changed are: device search history
  off, cloud content search off, clipboard history off, and (admin only) the
  Activity history policy. See HOW TO RESTORE / UNDO
- Event logs (use Event Viewer for those)


HOW TO RESTORE / UNDO
---------------------
Most cleared items cannot be restored. The data is deleted, not archived.

However:
- Quick Access will repopulate as you open files
- Thumbnail cache will rebuild as you browse folders
- Prefetch data will rebuild as you launch programs
- Jump lists will rebuild as you use applications
- File Explorer Favorites removed by answering Y (Windows 11) cannot be
  restored; pin files again with right-click > Add to favorites

To restore Activity Timeline (if you used it):
  1. Sign back into your Microsoft account
  2. Timeline data synced to the cloud may restore
  3. Local-only activities cannot be recovered

To re-enable Activity history (remove the policy; admin Command Prompt):
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /f

To re-enable device search history:
  reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsDeviceSearchHistoryEnabled /t REG_DWORD /d 1 /f

To re-enable cloud content search:
  Windows 11: Settings > Privacy & security > Search permissions >
              Cloud content search > On
  Windows 10: Settings > Search > Permissions & History >
              Cloud content search > On
  Or (both versions, Command Prompt):
  reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsMSACloudSearchEnabled /t REG_DWORD /d 1 /f
  reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v IsAADCloudSearchEnabled /t REG_DWORD /d 1 /f

To re-enable clipboard history:
  Settings > System > Clipboard > Clipboard history > On


ADMIN VS NON-ADMIN
------------------
Without admin:
  - Most items are still cleared (Recent files, jump lists, Explorer
    history, Run dialog, search history, app history, clipboard)
  - Activity Timeline policy is skipped (requires admin)
  - Prefetch data is skipped (requires admin)
  - System temp folder is skipped (requires admin)
  - Activity Timeline and notification databases may be in use and are then
    reported as skipped (the script stops their services only with admin)

With admin:
  - Full cleanup including the Activity Timeline policy, prefetch, system
    temp, and the Activity Timeline / notification databases
  - The admin account must be the account signed in to the desktop. When a
    standard user elevates with another account's password, the script stops
    with an error, because it would otherwise clean the admin's profile


NOTES
-----
- Explorer is stopped at the start of Phase 6 and restarted at the end
- Some caches rebuild naturally as you use Windows (this is normal)
- Browser history requires separate cleanup via browser settings
- Running this on a schedule is not recommended (let Windows work normally)
- For ongoing privacy, consider adjusting Windows Privacy settings:
  Settings > Privacy & security
- This script pairs well with WindowsTweaks.bat (Privacy category)
  which disables activity collection at the source


TIPS
----
- Run before handing a shared computer to another user
- Run before a screen share or presentation to hide recent activity
- For maximum privacy, also clear browser data separately:
  Chrome: Ctrl+Shift+Delete
  Firefox: Ctrl+Shift+Delete
  Edge: Ctrl+Shift+Delete
- Consider disabling Activity Timeline permanently:
  Settings > Privacy > Activity history > uncheck all boxes
- To prevent Quick Access from showing recent files permanently:
  Explorer > Options > Privacy > uncheck both boxes
