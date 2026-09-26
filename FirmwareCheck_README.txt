================================================================================
 FirmwareCheck.bat - Instructions
================================================================================

DESCRIPTION
-----------
Scans your system for firmware and driver versions, then outputs search-ready
strings you can copy and paste directly into Google to check for updates.
Includes direct download links for major hardware vendors.


HOW TO USE
----------
1. Double-click to run (no administrator required)
2. Wait for the scan to complete (about 30 seconds)
3. View the summary on screen
4. Choose whether to open the full report

Output file is saved to your Desktop:
  - FirmwareInfo_COMPUTERNAME.txt

The script saves to your real Desktop folder, even when it has been moved
(for example to C:\Users\<you>\OneDrive\Desktop by OneDrive folder backup).
If no Desktop folder exists, the file goes to your user profile folder
(C:\Users\<you>). The full path is shown at the end of the scan.


BEFORE YOU RUN
--------------
No preparation needed. This script only reads system information.


WHAT IT DETECTS
---------------
- BIOS/UEFI version and motherboard model
- CPU (for chipset driver searches)
- Graphics card model and driver version
- Network adapter names and driver versions
- Audio device names and drivers
- Storage devices and firmware revisions
- Windows version and build

All information is read with built-in PowerShell (CIM/WMI) commands, so the
script also works on Windows 11 24H2 and later, where the old "wmic" tool
is no longer available.


HOW TO USE THE OUTPUT
---------------------
1. Open the report file or view the on-screen summary
2. Find the "QUICK SEARCH STRINGS" section
3. Copy a search string (e.g., "ASUS ROG STRIX B550-F BIOS update download")
4. Paste it into Google
5. Download updates from the official manufacturer website

Direct download links are provided for:
  - NVIDIA: https://www.nvidia.com/Download/index.aspx
  - AMD: https://www.amd.com/en/support
  - Intel: https://www.intel.com/content/www/us/en/download-center/home.html
  - Realtek: https://www.realtek.com/en/downloads
  - Motherboard vendors (ASUS, MSI, Gigabyte, ASRock, Dell, HP, Lenovo)


HOW TO RESTORE / UNDO
---------------------
This script only READS information and creates a text file. It makes NO
changes to your system. Nothing to restore.

To delete the report file:
  1. Go to your Desktop (or the folder shown at the end of the scan)
  2. Delete FirmwareInfo_*.txt


TIPS
----
- Compare your current driver versions against the latest available
- BIOS updates can fix bugs and add features, but be careful:
  - Never interrupt a BIOS update
  - Use a UPS or ensure stable power
  - Follow manufacturer instructions exactly
- GPU drivers should be updated regularly for game compatibility
- Chipset drivers are important but don't need frequent updates
