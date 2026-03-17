================================================================================
 ScheduledTaskAuditor.bat - Instructions
================================================================================

DESCRIPTION
-----------
Scans all Windows scheduled tasks, categorizes them as essential, telemetry,
bloatware, or optional, and lets you selectively disable unwanted ones.
Saves a full audit report to your Desktop.


HOW TO USE
----------
1. Right-click ScheduledTaskAuditor.bat
2. Select "Run as administrator" (REQUIRED)
3. Wait for the scan to complete
4. Review the categorized task list
5. Choose to disable telemetry tasks when prompted
6. Choose to disable bloatware tasks when prompted
7. Optionally review optional tasks one by one


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Task Audit"
5. Click Create and wait for completion


WHAT EACH CATEGORY MEANS
------------------------

[TELEMETRY] - Magenta
  Microsoft data collection and diagnostics tasks:
  - Compatibility Appraiser (collects system data for MS)
  - CEIP tasks (Customer Experience Improvement Program)
  - DiagTrack related tasks
  - DmClient (diagnostics management)
  - SmartScreen data tasks
  - Office Telemetry tasks
  - Maps data collection

[BLOATWARE] - Red
  Third-party tasks that run unnecessarily:
  - Adobe updaters and license checkers (AdobeGC, ARM)
  - Google Chrome/Update tasks
  - Antivirus update tasks (when using Defender)
  - CCleaner, IObit, Driver Booster tasks
  - Browser update tasks (Opera, Brave, Vivaldi)
  - Java/Apple/Dropbox updaters
  - Vendor telemetry (HP, Dell, Lenovo, ASUS)

[OPTIONAL] - Yellow
  Legitimate but potentially unwanted tasks:
  - Xbox/Gaming tasks (if not gaming on PC)
  - OneDrive tasks (if not using OneDrive)
  - Edge update tasks
  - Office background tasks
  - Cortana tasks
  - Windows Update tasks (disable with caution)

[ESSENTIAL] - Green
  Core Windows tasks that should NOT be disabled:
  - Windows Defender scans
  - Disk defragmentation
  - System maintenance
  - Time synchronization
  - Startup optimization

[WINDOWS] - Not shown individually
  Standard Microsoft\Windows tasks not matching other categories.
  Generally safe and not suggested for disabling.


OUTPUT FILE
-----------
Saved to Desktop as: TaskAudit_COMPUTERNAME_DATE.txt

Contains:
  - Full categorized list of tasks
  - Task states (Ready, Running, Disabled)
  - Full task paths
  - Summary counts
  - Actions taken (which tasks were disabled)


HOW TO RESTORE / UNDO
---------------------
Option 1: Re-enable Individual Tasks
  Open Command Prompt as Administrator:
    schtasks /Change /TN "\Microsoft\Windows\TaskName" /Enable

Option 2: Re-enable via PowerShell
  Open PowerShell as Administrator:
    Enable-ScheduledTask -TaskName "TaskName" -TaskPath "\Path\"

Option 3: Task Scheduler GUI
  1. Press Win+R, type "taskschd.msc", press Enter
  2. Navigate to the task in the tree
  3. Right-click the task and select "Enable"

Option 4: System Restore
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your restore point
  3. Follow the wizard


COMMON TASKS SAFE TO DISABLE
-----------------------------
Almost always safe:
  - Microsoft Compatibility Appraiser (telemetry)
  - Consolidator (telemetry)
  - UsbCeip (USB data collection)
  - KernelCeipTask (kernel data collection)
  - ProgramDataUpdater (telemetry)
  - QueueReporting (error reporting queue)
  - Adobe ARM / AdobeGC* (Adobe license/update checks)
  - GoogleUpdate* (Chrome updates - update manually)
  - All third-party antivirus tasks (if using Defender)

Safe if not using the feature:
  - Xbox tasks (if not gaming)
  - OneDrive tasks (if not using OneDrive)
  - Office telemetry (doesn't affect Office functionality)
  - Maps tasks (if not using Windows Maps)
  - Speech model downloads (if not using voice)


TASKS TO BE CAREFUL WITH
-------------------------
Don't disable without understanding:
  - Windows Defender tasks (your security)
  - Windows Update tasks (security patches)
  - SilentCleanup (disk space management)
  - Defrag (SSD TRIM and HDD optimization)
  - Any task you don't recognize

If in doubt:
  Don't disable it. Unknown tasks are shown for information
  but not suggested for disabling.


WHEN TO USE
-----------
- After a fresh Windows install
- After installing new software (many add scheduled tasks)
- To reduce background CPU/disk activity
- To improve privacy by disabling telemetry tasks
- To speed up boot and login times
- As part of a regular system audit


TIPS
----
- Disabled tasks don't run but are NOT deleted
- Re-enabling a task restores it completely
- Some tasks recreate themselves after Windows updates
- Run this script periodically to catch newly added tasks
- Use ServiceAnalyzer.bat to also audit services
- Use StartupAnalyzer.bat to audit startup programs
- Together these three scripts give full background activity control


RELATED TOOLS
-------------
Built-in Windows tools:
  - Task Scheduler (taskschd.msc) - Full task management GUI
  - schtasks command - Command-line task management
  - PowerShell Get-ScheduledTask - Script-friendly task management

From this toolbox:
  - ServiceAnalyzer.bat - Audit Windows services
  - StartupAnalyzer.bat - Audit startup programs
  - ProcessScanner.bat - Find running bloatware
  - WindowsTweaks.bat - Privacy tweaks including telemetry
  - windows-debloat/03-Disable-Tasks.bat - Aggressive task disabling
