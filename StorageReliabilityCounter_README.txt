================================================================================
 StorageReliabilityCounter.bat - Instructions
================================================================================

DESCRIPTION
-----------
Reports temperature, power-on hours, reallocated sectors, wear level, and
reliability counters for SSDs and HDDs. Flags drives approaching failure
with color-coded health assessments and remaining life estimates.
Basic drive info works without admin; full S.M.A.R.T. data requires admin.


HOW TO USE
----------
1. Right-click StorageReliabilityCounter.bat (admin recommended)
2. Or double-click for basic info without admin
3. Choose from the menu:
   [1] Quick health overview (all drives)
   [2] Detailed reliability report
   [3] Export report to Desktop


ADMIN REQUIREMENTS
------------------
Without admin:
  - Drive model, size, type (SSD/HDD), bus type
  - Windows health status and operational status
  - Volume information (capacity, free space, format)

With admin (recommended):
  - Temperature readings
  - Power-on hours with usage estimates
  - SSD wear level with remaining life estimate
  - Read/write error counters (corrected and uncorrected)
  - Start/stop cycle count
  - Flash write counters
  - S.M.A.R.T. failure prediction
  - Serial number and firmware version


HEALTH THRESHOLDS
-----------------
Temperature:
  < 50C        Green    Normal
  50-59C       Yellow   Warm - check airflow
  60-69C       Red      Hot - improve cooling
  70C+         Red      Critical - drive may throttle or fail

Power-On Hours:
  < 25,000     Green    Normal usage
  25,000-35k   Green    Well used
  35,000-50k   Yellow   High - monitor closely
  50,000+      Red      Very high - consider replacement

SSD Wear Level (remaining):
  > 50%        Green    Good condition
  30-50%       Yellow   Fair
  10-30%       Yellow   Worn - plan replacement
  < 10%        Red      Critical - replace immediately


OUTPUT
------
Quick Overview:
  - Table of all drives with health status
  - Reliability counters per drive
  - Volume free space with low-space warnings

Detailed Report:
  - Full identification (model, serial, firmware)
  - All reliability counters with explanations
  - Partition layout
  - Per-drive health assessment (PASS/WARNING)
  - WMI disk status
  - S.M.A.R.T. failure prediction

Export:
  - Text file on Desktop with full report
  - Named: StorageReliability_COMPUTERNAME_DATE.txt


DIFFERENCES FROM DiskHealthCheck.bat
-------------------------------------
DiskHealthCheck.bat focuses on:
  - Full S.M.A.R.T. attribute dump (all 30+ attributes)
  - Requires admin for all features

StorageReliabilityCounter.bat focuses on:
  - Key reliability metrics only (temperature, wear, errors)
  - Works partially without admin
  - Color-coded health assessments with thresholds
  - Remaining life estimates
  - Simpler output, more actionable


NOTES
-----
- Uses Windows built-in Get-StorageReliabilityCounter cmdlet
- No external tools needed (unlike smartmontools/CrystalDiskInfo)
- Some NVMe drives report limited data through Windows APIs
- For comprehensive S.M.A.R.T. data, consider CrystalDiskInfo
- Drive temperature varies by workload — check under load too
- Wear level is most relevant for SSDs with NAND flash
- Power-on hours accumulate even when idle (if powered on)


TIPS
----
- Run monthly to track trends over time
- Use option [3] to save reports and compare over months
- If wear level drops fast, check for excessive writes
  (use Resource Monitor > Disk tab to find heavy writers)
- High temperature? Check case airflow and fan dust filters
- For NVMe SSDs, a heatsink can drop temperatures 10-20C
- Pair with DiskHealthCheck.bat for full S.M.A.R.T. data
