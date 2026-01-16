================================================================================
 StartupAnalyzer.bat - Instructions
================================================================================

DESCRIPTION
-----------
Scans all Windows startup programs and categorizes them into four groups:
  - KEEP: Essential programs that should not be disabled
  - OPTIONAL: Safe to disable, with explanations
  - UNKNOWN: Not recognized, research before disabling
  - REMOVE: Known bloatware recommended for removal

Offers to automatically disable bloatware items with your permission.


HOW TO USE
----------
1. Right-click StartupAnalyzer.bat
2. Select "Run as administrator" (recommended for full access)
3. Wait for the scan to complete
4. Review the categorized list
5. When prompted, choose whether to remove bloatware items (Y/N)
6. Optionally review optional items in Task Manager


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Startup Cleanup"
5. Click Create and wait for completion


WHAT EACH CATEGORY MEANS
------------------------

[KEEP] - Essential Programs
  These are required for your system to function properly:
  - Windows Security / Defender
  - Audio drivers (Realtek, etc.)
  - Graphics drivers (NVIDIA, AMD, Intel)
  - Touchpad drivers (Synaptics, ELAN)
  - Bluetooth services
  DO NOT DISABLE THESE

[OPTIONAL] - Your Choice
  Legitimate programs that aren't essential at startup:
  - Printer software (only needed when printing)
  - RGB/peripheral software (Razer, Corsair, etc.)
  - Password managers (can launch manually)
  - Clipboard managers (Windows has Win+V built-in)
  - Screenshot tools (can launch when needed)
  These are safe to disable if you don't need them running 24/7

[UNKNOWN] - Research First
  Programs not in our database. Before disabling:
  1. Search the program name online
  2. Check if it's required for your hardware
  3. When in doubt, leave it enabled

[REMOVE] - Bloatware
  Known unnecessary programs including:
  - Third-party antivirus (Windows Defender is sufficient)
  - Updater services (programs update when you open them)
  - Pre-installed trials (McAfee, Norton, WinZip)
  - Social apps auto-starters (Discord, Spotify, Steam)
  - PUPs and scareware (Driver Booster, registry cleaners)
  These are safe to remove and will speed up your boot time


HOW TO RESTORE / UNDO
---------------------
Option 1: Task Manager (Easiest)
  1. Press Ctrl+Shift+Esc to open Task Manager
  2. Go to the "Startup" tab
  3. Right-click any disabled item
  4. Select "Enable"

Option 2: System Restore
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your restore point
  3. Follow the wizard

Option 3: Registry (Manual)
  If you know the exact registry values:
  1. Press Win+R, type "regedit", press Enter
  2. Navigate to:
     HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
     or
     HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
  3. Add the value back

Option 4: Reinstall the Program
  Most programs add themselves back to startup when reinstalled
  or have a "Start with Windows" option in their settings.


WHAT THE SCRIPT SCANS
---------------------
1. HKEY_CURRENT_USER\...\Run (user startup)
2. HKEY_LOCAL_MACHINE\...\Run (system startup)
3. HKEY_LOCAL_MACHINE\...\Run (32-bit on 64-bit)
4. User Startup folder
5. All Users Startup folder


PROGRAMS MARKED AS BLOATWARE
----------------------------
The script flags these types of programs:

Unnecessary Updaters:
  - Google Update, Adobe Updater, Java Update
  - Programs update when you open them anyway

Third-Party Antivirus:
  - McAfee, Norton, Avast, AVG, Kaspersky
  - Windows Defender is built-in and sufficient

Auto-Starting Apps:
  - Steam, Discord, Spotify, Zoom, Teams, Skype
  - These can be launched manually when needed

Cloud Sync:
  - OneDrive, Dropbox, Google Drive
  - Can be disabled if not actively using cloud sync

PUPs (Potentially Unwanted Programs):
  - Driver Booster, IObit, Auslogics, Glary Utilities
  - Registry cleaners, system optimizers
  - Often bundled with other software

Known Malware/Scareware:
  - Segurazo, ByteFence, Reimage, PC Accelerate
  - REMOVE THESE IMMEDIATELY


TIPS
----
- Fewer startup programs = faster boot time
- Most apps don't need to run at startup
- You can always launch programs manually when needed
- Use Task Manager's Startup tab for ongoing management
- Check startup impact: High impact programs slow boot the most
- Browser extensions also run at startup - review those separately


ALTERNATIVE TOOLS
-----------------
For more detailed startup management:
  - Autoruns (Microsoft Sysinternals) - most comprehensive
  - Task Manager Startup tab - built into Windows
  - msconfig - classic Windows tool (run > msconfig > Startup)
