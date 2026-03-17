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
4. Wait for all phases to complete
5. Explorer will restart automatically to apply changes


BEFORE YOU RUN
--------------
This script clears usage history. If you need any of the following, save
them first:
  - Recent files you need to find again
  - Run dialog commands you want to remember
  - PowerShell command history you may need
  - Clipboard contents you haven't pasted yet


WHAT GETS CLEARED
-----------------
Phase 1: Recent Files and Quick Access
  - Recent Items folder (%AppData%\Microsoft\Windows\Recent)
  - Quick Access frequent files (AutomaticDestinations)
  - Note: Pinned Quick Access items are kept (user-pinned intentionally)

Phase 2: Jump Lists
  - Taskbar right-click recent files per application
  - Automatic and custom jump list destinations

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
  - Device search history setting
  - Cloud search suggestions
  - Cortana local database
  - Windows Search local state (Win11)

Phase 6: Thumbnail Cache
  - Thumbnail cache files (thumbcache_*.db)
  - Icon cache files (iconcache_*.db)

Phase 7: Application-Specific History
  - Microsoft Word recent files
  - Microsoft Excel recent files
  - Microsoft PowerPoint recent files
  - Paint recent files
  - WordPad recent files
  - Windows Media Player recent files
  - Notepad tab state (Windows 11)

Phase 8: Windows Activity Timeline and Clipboard
  - Activity Timeline (Task View history)
  - Activity Timeline database files
  - Clipboard history

Phase 9: Prefetch and Temp Traces
  - Prefetch data (app launch traces) - requires admin
  - User temp folder
  - System temp folder - requires admin
  - Notification history


WHAT IS NOT CLEARED
-------------------
- Browser history, cookies, cache, and saved passwords
  (Use your browser's built-in clear data feature instead)
- Installed programs and their settings
- Saved files and documents
- Desktop files and shortcuts
- Pinned Quick Access folders
- System settings and configuration
- Event logs (use Event Viewer for those)


HOW TO RESTORE / UNDO
---------------------
Most cleared items cannot be restored. The data is deleted, not archived.

However:
- Quick Access will repopulate as you open files
- Thumbnail cache will rebuild as you browse folders
- Prefetch data will rebuild as you launch programs
- Jump lists will rebuild as you use applications

To restore Activity Timeline (if you used it):
  1. Sign back into your Microsoft account
  2. Timeline data synced to the cloud may restore
  3. Local-only activities cannot be recovered

To re-enable clipboard history:
  Settings > System > Clipboard > Clipboard history > On


ADMIN VS NON-ADMIN
------------------
Without admin:
  - Most items are still cleared (Recent files, jump lists, Explorer
    history, Run dialog, search history, app history, timeline, clipboard)
  - Prefetch data is skipped (requires admin)
  - System temp folder is skipped (requires admin)

With admin:
  - Full cleanup including prefetch and system temp


NOTES
-----
- Explorer will restart at the end to apply changes
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
