================================================================================
 PagefileTuner.bat - Instructions
================================================================================

DESCRIPTION
-----------
Analyzes RAM usage patterns, recommends pagefile size based on total RAM,
offers to move the pagefile to a faster drive, or lock it to a fixed size
to prevent fragmentation. Shows current vs recommended configuration with
drive type detection (NVMe/SSD/HDD).


HOW TO USE
----------
1. Right-click PagefileTuner.bat
2. Select "Run as administrator" (REQUIRED)
3. Choose from the menu:
   [1] Analyze current pagefile and RAM usage
   [2] Apply recommended pagefile settings
   [3] Set custom fixed pagefile size
   [4] Move pagefile to a different drive
   [5] Disable pagefile (not recommended)
   [6] Restore Windows automatic management


BEFORE YOU RUN
--------------
All pagefile changes require a reboot to take effect.
The script will prompt you to reboot after making changes.
Option [6] restores Windows default automatic management.


SIZE RECOMMENDATIONS
--------------------
| Total RAM | Recommended Pagefile | Rationale                      |
|-----------|---------------------|--------------------------------|
| 8 GB      | 12 - 24 GB          | Essential — RAM runs out fast  |
| 16 GB     | 16 GB (fixed)       | Standard — most apps fit      |
| 32 GB     | 16 GB (fixed)       | Moderate — safety net          |
| 64 GB     | 16 GB (fixed)       | Minimal — rarely used          |
| 128 GB    | 16 GB (fixed)       | Crash dump support only        |


WHY FIXED SIZE?
---------------
Windows automatic management creates a dynamic pagefile that:
  - Grows and shrinks based on demand
  - Fragments the pagefile on disk over time
  - Can cause stutter when the file grows (I/O spike)
  - May be undersized or oversized

A fixed pagefile (initial = maximum):
  - Never fragments (allocated as one contiguous block)
  - No I/O spikes from resizing
  - Consistent behavior
  - Slightly wastes disk space (acceptable trade-off)


WHY MOVE TO A DIFFERENT DRIVE?
------------------------------
The pagefile benefits from being on the fastest drive available:
  - NVMe SSD: Best — lowest latency for page swaps
  - SATA SSD: Good — much better than HDD
  - HDD: Poor — page faults cause noticeable stutter

If your OS drive (C:) is an HDD but you have an SSD as a secondary drive,
moving the pagefile to the SSD dramatically improves swap performance.

If you have multiple NVMe SSDs, placing the pagefile on a separate drive
from the OS can reduce I/O contention.


CRASH DUMP CONSIDERATIONS
--------------------------
Windows crash dumps (blue screen analysis) require a pagefile on C: that
is at least as large as your physical RAM. If you move the pagefile to
another drive:

  - Keep a small pagefile on C: (800 MB) for minidumps
  - Or accept that full crash dumps won't be available
  - Minidumps (most useful for debugging) need only ~800 MB
  - Full memory dumps need pagefile >= RAM size


DISABLING THE PAGEFILE
-----------------------
Only recommended if:
  - You have 64+ GB RAM
  - You never exceed your physical RAM capacity
  - You don't need crash dumps for debugging
  - You've monitored your RAM usage over weeks and never maxed out

Risks of disabling:
  - Programs crash with "out of memory" even with free RAM
    (some programs require a pagefile regardless of available RAM)
  - No Windows crash dumps
  - Memory-mapped file operations may fail
  - Some Windows features degrade


HOW TO RESTORE / UNDO
---------------------
Option 1: Use menu option [6]
  - Restores Windows automatic pagefile management
  - This is the Windows default

Option 2: System Properties
  1. Press Win+R, type "sysdm.cpl", press Enter
  2. Advanced tab > Performance > Settings > Advanced tab
  3. Virtual Memory > Change
  4. Check "Automatically manage paging file size for all drives"
  5. Click OK and reboot


WHAT THE ANALYSIS SHOWS
------------------------
  - Total / Used / Free physical RAM
  - Current pagefile location, size, and usage
  - Peak pagefile usage (highest since boot)
  - Whether pagefile is system-managed or manually configured
  - Available drives with type (NVMe/SSD/HDD) and free space
  - Calculated recommendation based on your RAM amount


NOTES
-----
- All changes require a reboot to take effect
- The old pagefile.sys is deleted on reboot after changes
- A new pagefile.sys is created at the specified size
- Pagefile usage is viewable in Task Manager > Performance > Memory
- Resource Monitor > Memory tab shows detailed pagefile activity
- Windows may still create a hidden swapfile.sys (1-256 MB) for
  modern/UWP apps — this is separate from the pagefile


TIPS
----
- Start with option [1] to understand your current configuration
- For gaming PCs with 32+ GB RAM, a fixed 16 GB pagefile is ideal
- For workstations (video editing, CAD), match pagefile to RAM size
- Always place the pagefile on the fastest available drive
- Monitor pagefile usage over a week before deciding on size
- If "peak usage" in the analysis is very low, you can safely
  reduce the pagefile size
- Pair with RAMDiskCreator.bat if you have excess RAM
