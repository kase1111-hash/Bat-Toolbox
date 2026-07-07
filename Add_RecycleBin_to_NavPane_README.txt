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
2. The script writes two registry values and then restarts Explorer so the
   change appears immediately.
3. When Explorer relaunches, open any Explorer window - the Recycle Bin now
   appears in the Navigation Pane on the left.

Note: This script does NOT strictly require admin because it writes only to
HKCU (the current user's hive). Running as admin simply avoids edge cases
where Explorer restart timing differs.


WHAT IT DOES
------------
The script makes two registry changes under the current user's classes hive
for the Recycle Bin CLSID {645FF040-5081-101B-9F08-00AA002F954E}:

  1. Creates the CLSID key:
     HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}

  2. Sets the ShellFolder Attributes value to 0x50000020, which is the flag
     combination that tells Explorer to show the folder in the Navigation
     Pane tree.

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
Remove the Navigation Pane entry by deleting the CLSID key you added:

  reg delete "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /f

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
