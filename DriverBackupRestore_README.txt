================================================================================
 DriverBackupRestore.bat - Instructions
================================================================================

DESCRIPTION
-----------
Exports all third-party (non-inbox) drivers to a folder using DISM and pnputil.
Creates a portable backup with an optional self-contained restore script.
Invaluable before a clean Windows install — lets you restore non-inbox drivers
without hunting for downloads on manufacturer websites.


HOW TO USE
----------
1. Right-click DriverBackupRestore.bat
2. Select "Run as administrator" (REQUIRED)
3. Choose from the menu:
   [1] Backup all third-party drivers
   [2] List installed third-party drivers
   [3] Restore drivers from backup
   [4] Backup and create restore script


BEFORE YOU RUN
--------------
No system changes are made during backup (options 1, 2, 4).
Option 3 (restore) installs drivers — create a restore point first.


MENU OPTIONS
------------
Option 1: Backup All Third-Party Drivers
  - Uses DISM /export-driver to copy all non-inbox drivers
  - Falls back to pnputil if DISM has issues
  - Creates a DriverInventory.txt with full driver listing
  - Saves to Desktop by default (custom path supported)
  - Folder name includes computer name and date

Option 2: List Installed Third-Party Drivers
  - Shows all non-Microsoft drivers currently installed
  - Displays class, published name, provider, and version
  - Read-only, no changes made

Option 3: Restore Drivers from Backup
  - Bulk install: installs all .inf files from backup folder
  - Selective install: review each driver before installing
  - Skips drivers already installed or not needed
  - Recommends reboot after restore

Option 4: Backup with Self-Contained Restore Script
  - Performs a full backup (same as option 1)
  - Creates RestoreAllDrivers.bat inside the backup folder
  - The restore script is portable — works on any Windows install
  - Copy the entire folder to USB for clean install recovery


WHAT GETS BACKED UP
-------------------
- GPU drivers (NVIDIA, AMD, Intel)
- Audio drivers (Realtek, etc.)
- Network drivers (WiFi, Ethernet, Bluetooth)
- Chipset drivers
- Storage controllers (NVMe, AHCI)
- USB controllers and device drivers
- Printer drivers
- Any other third-party driver in the Windows driver store

WHAT IS NOT BACKED UP
---------------------
- Microsoft inbox drivers (already included in Windows)
- Driver companion software (GeForce Experience, Realtek Audio Console)
- Driver settings and profiles


OUTPUT
------
Creates a folder on Desktop (or custom path):
  DriverBackup_COMPUTERNAME_DATE/
    ├── oem0.inf, oem1.inf, ...   (driver packages)
    ├── *.sys, *.dll, *.cat       (driver files)
    ├── DriverInventory.txt        (full driver listing)
    └── RestoreAllDrivers.bat      (if option 4 used)


TYPICAL WORKFLOW
----------------
Before clean install:
  1. Run DriverBackupRestore.bat > Option [4]
  2. Copy backup folder to USB drive
  3. Also run ExportInstalledPrograms.bat for software list
  4. Perform clean Windows install

After clean install:
  1. Plug in USB drive
  2. Right-click RestoreAllDrivers.bat > Run as administrator
  3. Reboot
  4. Windows will configure the restored drivers
  5. Update drivers as needed from manufacturer websites


NOTES
-----
- DISM /export-driver only exports third-party drivers, not inbox
- pnputil /add-driver /install stages and installs the driver
- Some drivers may not install if the corresponding hardware is missing
- Driver backup is hardware-specific; don't restore GPU drivers from
  an NVIDIA system onto an AMD system
- Backup size varies: typically 200MB-2GB depending on installed hardware
- The backup includes all driver versions currently in the store
- After a clean install, Windows Update may also install newer drivers


TIPS
----
- Run option [2] first to see what will be backed up
- Keep backups on a USB drive labeled with computer name and date
- After restoring, check Device Manager for any devices with issues
- For GPU drivers, consider downloading the latest from manufacturer
  instead of restoring old versions
- Pair with FirmwareCheck.bat to document current driver versions
- NVCleanstall (NVIDIA) or minimal AMD installer may be better for
  GPU drivers specifically
