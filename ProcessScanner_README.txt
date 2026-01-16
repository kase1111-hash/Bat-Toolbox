================================================================================
 ProcessScanner.bat - Instructions
================================================================================

DESCRIPTION
-----------
Scans all running processes and categorizes them to identify bloatware,
forgotten background programs, and resource hogs. Offers to terminate
bloatware processes with your permission.


HOW TO USE
----------
1. Right-click ProcessScanner.bat
2. Select "Run as administrator" (recommended for full access)
3. Wait for the scan to complete
4. Review the categorized list
5. When prompted, choose whether to terminate bloatware (Y/N)


BEFORE YOU RUN
--------------
- Save any unsaved work in other programs
- Note: Terminating processes is temporary - they may restart
- Use StartupAnalyzer.bat to permanently prevent programs from starting


WHAT EACH CATEGORY MEANS
------------------------

SYSTEM OVERVIEW:
  Shows total process count, memory usage, and bloatware memory impact.

HIGH MEMORY USAGE (Over 500MB):
  Processes using significant RAM. Not necessarily bad, but worth noting.
  - Yellow: 500MB - 1GB
  - Red: Over 1GB

[BLOATWARE] - Red:
  Known unnecessary programs that should be closed/removed:
  - Third-party antivirus (Windows Defender is sufficient)
  - PUPs and scareware (Segurazo, ByteFence, registry cleaners)
  - Unnecessary updaters (Java, Adobe ARM, Google Update)
  - Auto-started apps (Steam, Discord, Spotify in background)
  - Vendor bloatware (GiftBox, support assistants)

[OPTIONAL] - Yellow:
  Legitimate programs that may not need to run constantly:
  - RGB/peripheral software (iCUE, Razer, Logitech)
  - Screenshot tools (ShareX, Greenshot)
  - Password managers (can use browser extension instead)
  - Hardware monitors (HWiNFO, Afterburner)

[UNKNOWN] - Cyan:
  Processes not in our database. Shows larger ones (>50MB).
  Research before terminating:
  1. Right-click process in Task Manager
  2. Select "Search online"
  3. Determine if it's needed


WHAT IT DETECTS AS BLOATWARE
----------------------------
Third-Party Antivirus:
  - Avast, AVG, Avira, McAfee, Norton, Bitdefender, Kaspersky
  - Reason: Windows Defender is built-in and sufficient

PUPs/Scareware (REMOVE THESE):
  - Segurazo, ByteFence, Reimage, PC Accelerate, SpyHunter
  - IObit, Auslogics, Glary, CCleaner monitoring
  - Driver Booster, DriverMax, SlimDrivers

Browser Hijackers:
  - Conduit, Ask Toolbar, Babylon, MyWebSearch
  - Search Protect, Web Companion

Unnecessary Updaters:
  - Java Updater (jusched, jucheck)
  - Adobe ARM, Adobe Genuine Service
  - Google Update, Edge Update

Background Apps:
  - Steam, Discord, Spotify (when not in use)
  - Zoom, Teams, Skype (when not in meetings)
  - OneDrive, Dropbox (if not using cloud sync)

Vendor Bloatware:
  - ASUS GiftBox, MyASUS, GameFirst
  - Dell SupportAssist, HP Support
  - Lenovo Vantage, Acer software
  - CyberLink, Corel trial software


HOW TO RESTORE / UNDO
---------------------
Terminating a process is temporary. The program may:
1. Restart automatically if it has a service
2. Start again next time you boot Windows
3. Be relaunched by another program

To restart a terminated program:
1. Find the program in Start Menu and launch it
2. Or restart your computer

To permanently stop programs from running:
1. Uninstall the program entirely, OR
2. Use StartupAnalyzer.bat to disable startup entries, OR
3. Disable the program's Windows service


UNDERSTANDING MEMORY USAGE
--------------------------
Normal memory usage varies, but as a guide:
  - Chrome/Edge: 100-500MB+ (depends on tabs)
  - Discord: 200-400MB
  - Steam: 100-300MB
  - Games: 2-16GB+
  - System processes: 50-200MB each

High memory isn't always bad:
  - Unused RAM is wasted RAM
  - Windows caches things in memory for speed
  - Close memory hogs only if you need the RAM


TIPS
----
- Run this periodically to catch forgotten programs
- Use with StartupAnalyzer.bat for complete cleanup
- Some processes restart immediately - uninstall to fully remove
- Right-click process > Open file location to find the program
- Task Manager > Details tab shows all processes with more info
- Resource Monitor (resmon.exe) shows detailed resource usage


RELATED TOOLS
-------------
Built-in Windows tools:
  - Task Manager (Ctrl+Shift+Esc)
  - Resource Monitor (resmon.exe)
  - Process Explorer (Microsoft Sysinternals - more detailed)

From this toolbox:
  - StartupAnalyzer.bat - Prevent programs from auto-starting
  - WindowsTweaks.bat - Disable unnecessary services
  - RemoveAsusBloat.bat / RemoveNvidiaBloat.bat - Remove vendor bloatware
