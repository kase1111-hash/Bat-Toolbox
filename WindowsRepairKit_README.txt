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

[2] DISM /RestoreHealth - Deployment Image Servicing
  Repairs the Windows component store itself. Downloads correct file
  versions from Windows Update if needed.

  Possible results:
  - PASS: No component store corruption
  - FIXED: Component store was repaired
  - ERROR: Could not repair (may need Windows install media)

[3] CHKDSK - Check Disk
  Scans the filesystem on your system drive for errors, bad sectors,
  and corruption. Runs in read-only mode first.

  Possible results:
  - PASS: No filesystem errors
  - ISSUE: Errors found - offers to schedule repair for next reboot


SMART FEATURES
--------------
- If SFC finds unrepairable files and DISM succeeds, the script offers
  to re-run SFC (DISM often fixes the underlying cause)
- Parses the CBS.log for actual corruption entries
- Extracts bad sector count from CHKDSK output
- Saves everything to a timestamped log file on your Desktop


OUTPUT FILE
-----------
Saved to Desktop as: RepairKit_COMPUTERNAME_DATE.txt

Contains:
  - Results from each check
  - CBS log error entries (last 50 relevant lines)
  - Full DISM output
  - CHKDSK disk statistics
  - Timestamps for start and completion


HOW TO RESTORE / UNDO
---------------------
SFC and DISM only replace corrupted files with correct versions.
These operations are generally safe and don't need undoing.

If CHKDSK /F /R was scheduled:
  - Cancel before reboot: chkntfs /x C:
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
