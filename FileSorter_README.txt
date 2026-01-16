================================================================================
 FileSorter.bat - Instructions
================================================================================

DESCRIPTION
-----------
Automatically organizes files in a folder by moving them into subfolders
based on their file extension (e.g., .jpg files go into a "JPG" folder).


HOW TO USE
----------
1. Copy FileSorter.bat into the folder you want to organize
2. Double-click to run (no administrator required)
3. Confirm when prompted
4. Files will be moved into extension-based folders

Example:
  Before:                    After:
  /Downloads/                /Downloads/
    photo.jpg                  /JPG/photo.jpg
    document.pdf               /PDF/document.pdf
    song.mp3                   /MP3/song.mp3
    FileSorter.bat             FileSorter.bat


BEFORE YOU RUN
--------------
- The script will NOT overwrite files with the same name
- The script itself (FileSorter.bat) will not be moved
- Hidden and system files are skipped


HOW TO RESTORE / UNDO
---------------------
This script MOVES files, it does not delete them. To restore:

Option 1: Manual Restore
  1. Open each created folder (JPG, PDF, MP3, etc.)
  2. Select all files (Ctrl+A)
  3. Cut (Ctrl+X) and paste back into the parent folder
  4. Delete the empty folders

Option 2: Use Command Prompt
  1. Open Command Prompt in the sorted folder
  2. Run: for /d %d in (*) do move "%d\*" . 2>nul
  3. Delete empty folders: for /d %d in (*) do rd "%d" 2>nul

Option 3: System Restore (if needed)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select a restore point from before running the script
  3. Follow the wizard to restore


TIPS
----
- Test on a small folder first to see how it works
- Works best with Downloads or Desktop folders
- Run periodically to keep folders organized
