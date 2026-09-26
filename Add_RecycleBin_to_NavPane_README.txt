================================================================================
 Add_RecycleBin_to_NavPane.bat - Instructions
================================================================================

DESCRIPTION
-----------
Adds a "Recycle Bin" entry to the left-hand Navigation Pane in File Explorer,
so you can reach the Recycle Bin with a single click instead of going back to
the Desktop. The entry behaves like the built-in shortcuts (This PC, Network,
etc.) and sits alongside them in the tree.

This is a cosmetic, per-user convenience tweak. It does not move, empty, or
change the Recycle Bin itself - only where a shortcut to it appears.


HOW TO USE
----------
1. (Recommended) Right-click Add_RecycleBin_to_NavPane.bat and choose
   "Run as administrator" for the most reliable result.
2. The script writes one registry value (and removes an obsolete override
   left by earlier versions), then restarts Explorer so the change appears
   immediately.
3. When Explorer relaunches, open any Explorer window - the Recycle Bin now
   appears in the Navigation Pane on the left.

Note: This script does NOT strictly require admin because it writes only to
HKCU (the current user's hive). Running as admin simply avoids edge cases
where Explorer restart timing differs.


WHAT IT DOES
------------
The script makes these registry changes under the current user's classes
hive for the Recycle Bin CLSID {645FF040-5081-101B-9F08-00AA002F954E}:

  1. Sets the DWORD value System.IsPinnedToNameSpaceTree = 1 on
     HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}
     (creating the key if needed). This is the value Explorer uses to pin
     an item such as This PC, Network or OneDrive to the Navigation Pane.

  2. Deletes the per-user ShellFolder override
     HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\ShellFolder
     if it exists. Earlier versions of this script wrote an Attributes value
     of 0x50000020 there; it did not pin anything and replaced the Recycle
     Bin's normal shell attributes for this user.

It then restarts Explorer:
  - taskkill /f /im explorer.exe
  - waits 2 seconds
  - start explorer.exe


BEFORE YOU RUN
--------------
- Save any work in open Explorer windows. Restarting Explorer closes all
  Explorer windows and briefly hides the taskbar and desktop icons (they
  return within a second or two).
- No restore point is needed; this is a trivial, per-user reversible change.


HOW TO RESTORE / UNDO
---------------------
Remove the Navigation Pane entry by deleting the value the script added:

  reg delete "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" /f

(Setting the value to 0 instead also unpins it. Deleting the whole per-user
key with  reg delete "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /f
also works if nothing else has customized the Recycle Bin for this user.)

Then restart Explorer (or sign out and back in):

  taskkill /f /im explorer.exe & start explorer.exe


VERIFICATION
------------
After the script runs and Explorer restarts:
  - Open File Explorer (Win+E)
  - Look in the left Navigation Pane - "Recycle Bin" should be listed


TIPS
----
- Safe to run multiple times; the second run simply re-writes the same values.
- If the entry does not appear immediately, sign out and back in.
- Because this writes to HKCU, it affects only the user who runs it. Run it
  under each account that wants the shortcut.
