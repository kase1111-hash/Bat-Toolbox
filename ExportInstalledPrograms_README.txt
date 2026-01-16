================================================================================
 ExportInstalledPrograms.bat - Instructions
================================================================================

DESCRIPTION
-----------
Scans your system and creates a comprehensive list of all installed programs.
Useful for documenting what to reinstall after a clean Windows install.
Also creates a Winget JSON file for automated bulk reinstallation.


HOW TO USE
----------
1. Double-click to run (no administrator required)
2. Press any key when prompted to start scanning
3. Wait for the scan to complete (may take 1-2 minutes)
4. Choose whether to open the report when finished

Output files are saved to your Desktop:
  - InstalledPrograms_COMPUTERNAME_DATE.txt (human-readable list)
  - WingetPrograms_COMPUTERNAME_DATE.json (for automated reinstall)


BEFORE YOU RUN
--------------
- Close unnecessary programs to speed up the scan
- Ensure Winget is installed for the JSON export feature
  (Windows 10/11 usually has it pre-installed)


WHAT IT CAPTURES
----------------
- Desktop applications (64-bit and 32-bit)
- User-installed applications
- Microsoft Store apps
- Enabled Windows optional features
- Detailed list with versions and publishers
- Winget-compatible program list


HOW TO USE THE EXPORT AFTER CLEAN INSTALL
-----------------------------------------
Method 1: Winget Import (Automated)
  1. Copy WingetPrograms_*.json to your new Windows install
  2. Open Command Prompt or PowerShell as Administrator
  3. Run: winget import -i "WingetPrograms_COMPUTERNAME_DATE.json" --accept-package-agreements
  4. Winget will automatically download and install all programs

Method 2: Manual Installation
  1. Open InstalledPrograms_*.txt
  2. Use it as a checklist to manually install programs
  3. Use Ninite.com for common programs (faster)

Method 3: Combination
  1. Use Winget import for programs in the repository
  2. Manually install the rest using the text file as reference


HOW TO RESTORE / UNDO
---------------------
This script only READS information and creates files. It makes NO changes
to your system. Nothing to restore.

To delete the export files:
  1. Go to your Desktop
  2. Delete InstalledPrograms_*.txt and WingetPrograms_*.json


TIPS
----
- Run this BEFORE doing a clean install
- Save both files to a USB drive or cloud storage
- The Winget JSON only includes programs available in Winget's repository
- Programs not in Winget must be installed manually
- Also export browser bookmarks and extension lists separately
