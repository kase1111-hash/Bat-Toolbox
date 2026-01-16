================================================================================
 RestoreRecycleBin.bat - Instructions
================================================================================

DESCRIPTION
-----------
Restores the Recycle Bin icon to your Windows desktop if it was accidentally
hidden or removed by debloat scripts, registry tweaks, or other modifications.


HOW TO USE
----------
1. Double-click RestoreRecycleBin.bat (no administrator required)
2. Wait for the script to complete
3. Explorer will restart automatically
4. The Recycle Bin should appear on your desktop


BEFORE YOU RUN
--------------
No preparation needed. This script makes safe registry changes to restore
a default Windows feature.


WHAT THE SCRIPT DOES
--------------------
1. Removes registry flags that hide the Recycle Bin icon
2. Re-registers the Recycle Bin in the desktop namespace
3. Sets the visibility flag to "show"
4. Restarts Explorer to apply changes


HOW TO RESTORE / UNDO
---------------------
If you want to HIDE the Recycle Bin again after restoring it:

Option 1: Windows Settings (Easiest)
  1. Right-click on desktop > Personalize
  2. Click "Themes" in the left menu
  3. Click "Desktop icon settings" on the right
  4. Uncheck "Recycle Bin"
  5. Click Apply

Option 2: Registry (Manual)
  1. Press Win+R, type "regedit", press Enter
  2. Navigate to:
     HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel
  3. Find or create a DWORD value named:
     {645FF040-5081-101B-9F08-00AA002F954E}
  4. Set its value to 1 (hide) or 0 (show)
  5. Restart Explorer or log out/in


IF THE RECYCLE BIN STILL DOESN'T APPEAR
---------------------------------------
Try the manual method:
  1. Right-click on desktop
  2. Select "Personalize"
  3. Click "Themes" (left side)
  4. Click "Desktop icon settings" (right side)
  5. Check the "Recycle Bin" checkbox
  6. Click Apply, then OK

If that doesn't work:
  1. Press Win+R, type "regedit", press Enter
  2. Navigate to:
     HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace
  3. Right-click NameSpace > New > Key
  4. Name it: {645FF040-5081-101B-9F08-00AA002F954E}
  5. Restart Explorer (taskkill /f /im explorer.exe && start explorer.exe)


NOTES
-----
- The Recycle Bin CLSID is: {645FF040-5081-101B-9F08-00AA002F954E}
- This is a standard Windows feature, not third-party software
- Files in the Recycle Bin are not affected by this script
- The script only affects the desktop icon visibility


TIPS
----
- You can also access Recycle Bin via File Explorer address bar:
  Type "Recycle Bin" or "shell:RecycleBinFolder"
- Create a keyboard shortcut: Win+R, type "shell:RecycleBinFolder"
- The Recycle Bin can also be pinned to Quick Access in File Explorer
