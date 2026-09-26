================================================================================
 WindowsRepairKit.bat - Instructions
================================================================================

DESCRIPTION
-----------
Runs SFC, DISM, and CHKDSK in sequence with progress reporting and result
parsing. Saves a detailed log to your Desktop. A one-stop system integrity
checker instead of remembering three separate commands.


HOW TO USE
----------
1. Right-click WindowsRepairKit.bat
2. Select "Run as administrator" (REQUIRED)
3. Confirm when prompted
4. Wait for all three checks to complete (15-60 minutes)
5. Review the summary and log file


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Repair Kit"
5. Click Create and wait for completion


WHAT EACH CHECK DOES
--------------------

[1] SFC /scannow - System File Checker
  Scans all protected Windows system files and replaces corrupt or
  modified files with the correct version from the component store.

  Possible results:
  - PASS: No integrity violations found
  - FIXED: Found and repaired corrupt files
  - ISSUE: Found corrupt files but could not repair (DISM may help)
  - BLOCKED: Could not run, pending operations require reboot
    ("could not perform the requested operation" or "a system repair
    pending which requires reboot to complete")

  Results are detected from SFC's English output. On other display
  languages the summary shows CHECK LOG - read the log file instead.

[2] DISM /ScanHealth + /RestoreHealth - Deployment Image Servicing
  First runs DISM /ScanHealth to check the Windows component store. Only
  if the scan does not report the store as clean does it run
  DISM /RestoreHealth, which repairs the store and downloads correct file
  versions from Windows Update if needed. (/RestoreHealth reports
  "completed successfully" even when nothing was wrong, so the script
  scans first to tell a healthy store from a repaired one.)

  Possible results:
  - PASS: No component store corruption (scan was clean, no repair run)
  - FIXED: Component store was repaired
  - ERROR: Could not repair (may need Windows install media)

[3] CHKDSK - Check Disk
  Scans the filesystem on your system drive for errors, bad sectors,
  and corruption. Runs in read-only mode first.

  Possible results:
  - PASS: No filesystem errors
  - ISSUE: Problems found (chkdsk reports "found problems", "errors",
    "must be fixed offline" / "spotfix", or exit code 3) - offers to
    schedule CHKDSK /F /R for the next reboot (asks Y/N first)
  - INFO: Scan finished with no recognized problem message but did not
    report "found no problems" - review the log


SMART FEATURES
--------------
- If SFC finds unrepairable files and DISM succeeds, the script offers
  to re-run SFC (DISM often fixes the underlying cause)
- Parses the CBS.log for corruption entries written during this SFC run
  (older entries from earlier runs are ignored)
- Extracts bad sector count from CHKDSK output
- Saves everything to a timestamped log file on your Desktop


OUTPUT FILE
-----------
Saved to Desktop as: RepairKit_COMPUTERNAME_DATE.txt

The script saves to your real Desktop folder, even when it has been moved
(for example to C:\Users\<you>\OneDrive\Desktop by OneDrive folder backup).
If no Desktop folder exists, the log goes to your user profile folder
(C:\Users\<you>). The full path is shown before the checks start.

Contains:
  - Results from each check
  - CBS log entries from this SFC run (last 50 relevant lines)
  - DISM /ScanHealth output, and the /RestoreHealth output if it ran
  - CHKDSK disk statistics
  - Timestamps for start and completion


HOW TO RESTORE / UNDO
---------------------
SFC and DISM only replace corrupted files with correct versions.
These operations are generally safe and don't need undoing.

If CHKDSK /F /R was scheduled:
  - Cancel before reboot: chkntfs /x C:   (use your system drive letter)
    IMPORTANT: this exclusion stays in effect until you undo it. After the
    next restart, restore normal boot-time checking with:  chkntfs /d
  - Or simply reboot and let it run (recommended)

Option: System Restore
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your restore point
  3. Follow the wizard


WHEN TO USE
-----------
- Random crashes or blue screens
- Programs failing to open or behaving strangely
- Windows Update errors
- After malware removal
- After a forced shutdown or power loss
- "Windows Resource Protection" errors
- Corrupt system files warnings


MANUAL ALTERNATIVES
-------------------
If you prefer to run each command yourself:

  sfc /scannow
  DISM /Online /Cleanup-Image /RestoreHealth
  chkdsk C: /F /R

To check DISM component store without repairing:
  DISM /Online /Cleanup-Image /CheckHealth

To scan DISM more thoroughly:
  DISM /Online /Cleanup-Image /ScanHealth


TIPS
----
- Run SFC before DISM if you suspect file corruption
- Run DISM before SFC if SFC fails to repair files
- This script runs them in the optimal order (SFC -> DISM -> CHKDSK)
- CHKDSK /F /R on an SSD is safe - modern SSDs handle it properly
- Keep the log file for reference if issues persist
- If DISM fails, you may need to use Windows install media as a source:
    DISM /Online /Cleanup-Image /RestoreHealth /Source:D:\Sources\install.wim


RELATED TOOLS
-------------
Built-in Windows tools:
  - Event Viewer (eventvwr) - Check for related system errors
  - Reliability Monitor - History of system failures
  - Windows Memory Diagnostic (mdsched.exe) - Test RAM

From this toolbox:
  - ProcessScanner.bat - Check for problematic running processes
  - ServiceAnalyzer.bat - Find problematic services
  - StorageLatencyTuning.bat - Optimize disk performance
