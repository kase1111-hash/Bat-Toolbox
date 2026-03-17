================================================================================
 ContextMenuCleaner.bat - Instructions
================================================================================

DESCRIPTION
-----------
Scans the Windows registry for right-click context menu entries, categorizes
them as bloatware, optional, or essential, and lets you selectively disable
unwanted entries. Also offers to restore the classic full context menu on
Windows 11.


HOW TO USE
----------
1. Right-click ContextMenuCleaner.bat
2. Select "Run as administrator" (REQUIRED)
3. Wait for the registry scan to complete
4. Review the categorized list of context menu entries
5. Choose to disable bloatware entries when prompted
6. Optionally review and disable optional entries one by one
7. On Windows 11, optionally restore the classic context menu


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Context Menu Cleanup"
5. Click Create and wait for completion


WHAT EACH CATEGORY MEANS
------------------------

[BLOATWARE] - Red
  Third-party context menu entries that are typically unwanted:
  - WinZip entries
  - CRC SHA hash entries
  - Edit with Paint 3D
  - McAfee, Norton, Avast scan entries
  - CCleaner, IObit entries
  - Third-party antivirus scan options

[OPTIONAL] - Yellow
  Legitimate but potentially unwanted entries:
  - 7-Zip / WinRAR menus
  - Cloud storage (Dropbox, Google Drive, OneDrive)
  - Git Bash / Git GUI / TortoiseGit
  - Text editor entries (Notepad++, VS Code, Sublime)
  - GPU control panel entries
  - "Give access to", "Share", "Cast to Device"
  - "Include in library", "Pin to Quick access"

[KEEP] - Green
  Essential Windows entries that will NOT be touched:
  - Open with
  - Send to
  - Open in Terminal / PowerShell / Command Prompt
  - Scan with Microsoft Defender

[DISABLED] - Gray
  Entries that are already hidden or disabled.


HOW TO RESTORE / UNDO
---------------------
Option 1: Re-enable Individual Entries
  Open Registry Editor (regedit) and navigate to the entry's path
  (shown during the scan). Delete the "LegacyDisable" value.

Option 2: Re-enable via Command Line
  Open Command Prompt as Administrator:
    reg delete "HKCR\*\shell\EntryName" /v LegacyDisable /f

Option 3: Restore Windows 11 Simplified Menu
  If you restored the classic menu and want it back:
    reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
  Then restart Explorer or reboot.

Option 4: System Restore
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your restore point
  3. Follow the wizard


REGISTRY LOCATIONS SCANNED
--------------------------
The script scans these registry paths for context menu entries:

  Files:
    HKCR\*\shell
    HKCR\*\shellex\ContextMenuHandlers

  Directories:
    HKCR\Directory\shell
    HKCR\Directory\shellex\ContextMenuHandlers
    HKCR\Directory\Background\shell
    HKCR\Directory\Background\shellex\ContextMenuHandlers

  Folders:
    HKCR\Folder\shell
    HKCR\Folder\shellex\ContextMenuHandlers

  Drives:
    HKCR\Drive\shell

  System-wide:
    HKLM\SOFTWARE\Classes\Directory\background\shell
    HKLM\SOFTWARE\Classes\Directory\shell

  Per-user:
    HKCU\SOFTWARE\Classes\Directory\background\shell
    HKCU\SOFTWARE\Classes\Directory\shell


HOW THE DISABLING WORKS
-----------------------
The script uses the "LegacyDisable" registry value to hide entries.
This is the standard Windows mechanism for hiding context menu items.
It does NOT delete anything - entries can be re-enabled by removing
the LegacyDisable value.


TIPS
----
- Context menu entries often come back after software updates
- Some entries are added by shell extensions (DLLs) not just registry
- The Windows 11 classic menu fix is one of the most popular tweaks
- Run this script after installing new software that adds menu entries
- Fewer context menu entries = faster right-click response time
- Some entries may require Explorer restart to disappear


RELATED TOOLS
-------------
Built-in Windows tools:
  - regedit - Manual registry editing
  - ShellExView (NirSoft) - Advanced shell extension manager

From this toolbox:
  - WindowsTweaks.bat - Includes classic context menu option
  - StartupAnalyzer.bat - Related cleanup for startup entries
  - ProcessScanner.bat - Find related background processes
