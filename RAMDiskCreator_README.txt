================================================================================
 RAMDiskCreator.bat - Instructions
================================================================================

DESCRIPTION
-----------
Creates a RAM disk for temp files, browser caches, or game shader caches.
Can redirect %TEMP% to the RAM disk for a solid performance boost.
Uses ImDisk (if installed) or a built-in VHD fallback method.
Recommended for machines with 32GB+ RAM.


HOW TO USE
----------
1. Right-click RAMDiskCreator.bat
2. Select "Run as administrator" (REQUIRED)
3. Choose from the menu:
   [1] Create RAM disk
   [2] Redirect %TEMP% to RAM disk
   [3] View current RAM disk status
   [4] Remove RAM disk
   [5] Recommended sizes guide


BEFORE YOU RUN
--------------
- Check your total RAM (script shows this automatically)
- For best results, install ImDisk Toolkit:
  https://sourceforge.net/projects/imdisk-toolkit/
- Without ImDisk, the script uses a VHD-based fallback


IMPORTANT WARNING
-----------------
*** RAM DISK DATA IS LOST ON EVERY REBOOT OR SHUTDOWN ***

Only store temporary/cache data that rebuilds automatically:
  - Temp files (%TEMP%)
  - Browser cache
  - Shader cache
  - Compilation caches

NEVER store documents, save files, or anything important on a RAM disk.


SIZE RECOMMENDATIONS
--------------------
| Total RAM | Recommended Size | Use Case                        |
|-----------|------------------|---------------------------------|
| 16 GB     | 1-2 GB           | TEMP files only                 |
| 32 GB     | 2-4 GB           | TEMP + browser cache            |
| 64 GB     | 4-8 GB           | TEMP + cache + shader cache     |
| 128 GB    | 8-16 GB          | Everything + game installs      |


METHODS
-------
ImDisk (Recommended):
  - Creates a true block device backed by RAM
  - Formatted as NTFS
  - Can be configured to auto-create on boot
  - Faster and more reliable
  - Download: https://sourceforge.net/projects/imdisk-toolkit/

Built-in VHD Fallback:
  - Uses Windows diskpart to create a virtual hard disk
  - Formatted as NTFS
  - Does not persist across reboots
  - No extra software needed


COMMON REDIRECTIONS
-------------------
TEMP/TMP:
  Use menu option [2] to redirect automatically.

Chrome Cache:
  Shortcut target: chrome.exe --disk-cache-dir=R:\Cache

Firefox Cache:
  about:config > browser.cache.disk.parent_directory > R:\Cache

Edge Cache:
  Shortcut target: msedge.exe --disk-cache-dir=R:\Cache

NVIDIA Shader Cache:
  NVIDIA Control Panel > Manage 3D Settings > Shader Cache Location

AMD Shader Cache:
  AMD Software > Performance > Tuning > Shader Cache location


HOW TO UNDO
-----------
1. Run the script > Option [4] to remove the RAM disk
2. TEMP/TMP will be automatically restored to the default location
3. Or manually restore TEMP:
   setx TEMP "%USERPROFILE%\AppData\Local\Temp"
   setx TMP "%USERPROFILE%\AppData\Local\Temp"


PERSISTENCE ACROSS REBOOTS
---------------------------
RAM disks are lost on reboot. To auto-create on boot:

ImDisk Method:
  1. ImDisk Toolkit includes "RamDisk Configuration" tool
  2. Set it to auto-create your RAM disk on Windows startup
  3. Configure folders and TEMP redirect in the tool

Startup Script Method:
  1. Create a .bat that runs this script's create command
  2. Place in shell:startup or use Task Scheduler
  3. Set to run at logon with admin privileges


PERFORMANCE GAINS
-----------------
Typical improvements with TEMP on RAM disk:
  - Application install/compile: 10-50% faster
  - Browser page loads: marginal (already cached in RAM by OS)
  - Shader compilation: 30-70% faster first-time loads
  - Photoshop scratch operations: 2-5x faster
  - Visual Studio builds: 10-30% faster

The biggest gains are in workloads with heavy small-file I/O.


NOTES
-----
- Script auto-detects total and available RAM
- Warns if system has less than 16 GB
- Creates Temp, Cache, and ShaderCache subfolders automatically
- ImDisk supports auto-creation at boot; VHD method does not
- If TEMP points to a missing RAM disk, applications will error
- The script always offers to restore TEMP when removing the disk


TIPS
----
- Start with a small size (2 GB) and increase if needed
- Monitor RAM usage after creating the disk
- If you see "out of memory" errors, remove or shrink the disk
- Use R: as the drive letter (easy to remember as "RAM")
- Don't redirect TEMP permanently unless ImDisk auto-creates at boot
- For development, also consider redirecting node_modules or build
  output to the RAM disk for faster compilation
