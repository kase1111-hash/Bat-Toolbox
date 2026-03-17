================================================================================
 DiskHealthCheck.bat - Instructions
================================================================================

DESCRIPTION
-----------
Reads S.M.A.R.T. data, drive temperatures, wear levels, power-on hours,
error counts, and partition usage for all connected drives. Flags drives
that are approaching failure or have concerning metrics.


HOW TO USE
----------
1. Right-click DiskHealthCheck.bat
2. Select "Run as administrator" (REQUIRED)
3. Wait for the scan to complete
4. Review the health report for each drive
5. Check the saved report on your Desktop


OUTPUT FILE
-----------
Saved to Desktop as: DiskHealth_COMPUTERNAME_DATE.txt

Contains for each drive:
  - Model, serial number, firmware version
  - Media type (SSD, HDD, NVMe) and bus type
  - Health status (Healthy, Warning, Unhealthy)
  - Temperature with hot/warm indicators
  - Power-on hours with age estimate
  - SSD wear level percentage
  - Read/write error counts
  - Power cycle count
  - Partition usage and free space
  - WMI drive status


WHAT THE METRICS MEAN
---------------------

Temperature:
  < 45C      = Normal (Green)
  45C - 54C  = Warm (Yellow) - check ventilation
  >= 55C     = Hot (Red) - improve cooling immediately

SSD Wear Level:
  0-49%   = Good (Green) - plenty of life remaining
  50-69%  = Moderate (Yellow) - start planning replacement
  70-89%  = High (Yellow) - replacement within 1-2 years
  90-100% = Critical (Red) - replace as soon as possible

Power-On Hours:
  < 17520  (2 years)  = Relatively new
  17520-35040 (2-4 years) = Normal working age
  > 35040  (4+ years) = Consider replacement planning for HDDs

Read/Write Errors:
  0        = Normal
  > 0      = Investigate - may indicate failing drive

Drive Space:
  < 90% used  = Normal
  90-94% used = Low (Yellow) - free up space soon
  >= 95% used = Critical (Red) - performance will degrade


HEALTH STATUS MEANINGS
----------------------
Healthy     = Drive is operating normally
Warning     = Drive has reported issues, monitor closely
Unhealthy   = Drive is failing or has critical errors
Unknown     = Status could not be determined


HOW TO RESTORE / UNDO
---------------------
This script is read-only - it does not modify any settings or data.
It only reads drive information and S.M.A.R.T. data.


LIMITATIONS
-----------
- USB external drives may not report S.M.A.R.T. data
- Virtual disks (VMs) don't have S.M.A.R.T. data
- Some NVMe drives need manufacturer tools for full S.M.A.R.T.
- Wear level reporting depends on drive firmware support
- Not all drives report temperature via Windows APIs
- RAID arrays may not show individual drive health


WHEN TO USE
-----------
- Monthly as part of system maintenance
- Before buying a used computer
- After hearing unusual drive noises
- When experiencing random crashes or file corruption
- Before long trips (laptop drives under vibration stress)
- After a power outage or forced shutdown


WHAT TO DO IF A DRIVE IS FAILING
---------------------------------
1. BACK UP DATA IMMEDIATELY - this is the #1 priority
2. Order a replacement drive
3. Do NOT defragment a failing drive
4. Do NOT run CHKDSK /R on a failing drive (can worsen damage)
5. Use disk cloning software to migrate to a new drive
6. Consider professional data recovery if data is critical


MANUAL ALTERNATIVES
-------------------
PowerShell commands:
  Get-PhysicalDisk | Format-List *
  Get-StorageReliabilityCounter -PhysicalDisk (Get-PhysicalDisk)
  Get-Volume

Command line:
  wmic diskdrive get model,status,size,interfacetype
  wmic diskdrive get serialnumber,firmwarerevision

Third-party tools (more detailed S.M.A.R.T.):
  - CrystalDiskInfo (free)
  - Hard Disk Sentinel
  - Samsung Magician (Samsung SSDs)
  - Intel SSD Toolbox (Intel SSDs)
  - Western Digital Dashboard (WD drives)


TIPS
----
- SSDs don't need defragmentation (Windows TRIM is sufficient)
- HDDs benefit from occasional defragmentation
- Keep drives below 90% full for best performance
- Good ventilation extends drive life significantly
- Power-on hours matter more than age for reliability
- Pair with StorageLatencyTuning.bat for SSD optimization


RELATED TOOLS
-------------
Built-in Windows tools:
  - Disk Management (diskmgmt.msc)
  - Device Manager - Disk drives
  - Storage Spaces settings

From this toolbox:
  - StorageLatencyTuning.bat - Optimize NVMe/SSD performance
  - WindowsRepairKit.bat - CHKDSK for filesystem errors
  - FirmwareCheck.bat - Check drive firmware versions
