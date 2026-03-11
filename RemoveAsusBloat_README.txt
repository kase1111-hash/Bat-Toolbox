================================================================================
 RemoveAsusBloat.bat - Instructions
================================================================================

DESCRIPTION
-----------
Removes ASUS pre-installed bloatware from ASUS laptops, desktops, and
motherboards while keeping essential hardware drivers intact. Also disables
ASUS auto-reinstallers and update agents to prevent removed software from
coming back.


HOW TO USE
----------
1. Right-click RemoveAsusBloat.bat
2. Select "Run as administrator" (REQUIRED)
3. Confirm when prompted
4. Choose whether to remove Armoury Crate/ROG software (see below)
5. Wait for all phases to complete
6. Restart when prompted


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before ASUS Bloat Removal"
5. Click Create and wait for completion


ARMOURY CRATE DECISION
----------------------
The script will ask if you want to remove Armoury Crate. Consider:

KEEP Armoury Crate if you:
  - Use RGB lighting (Aura Sync)
  - Use custom fan profiles
  - Use performance modes (Silent/Balanced/Turbo)
  - Have ROG peripherals synced with your PC

REMOVE Armoury Crate if you:
  - Don't use RGB lighting
  - Are fine with BIOS-controlled fan profiles
  - Want a cleaner, lighter system
  - Experience issues with Armoury Crate


WHAT GETS REMOVED
-----------------
ASUS Software:
  - MyASUS
  - ASUS GIFTBOX
  - ASUS AI Suite (I, II, III)
  - ASUS GameFirst
  - ASUS Sonic Studio / Sonic Radar
  - ASUS WebStorage
  - ASUS Live Update
  - ASUS Splendid Video Enhancement
  - ASUS Smart Gesture
  - ASUS HiPost
  - ASUS Product Register
  - ASUS Instant Connect
  - ASUS Console / Tutor / Screen Saver
  - ASUS GlideX
  - ASUS ScreenXpert
  - ASUS Link (Near/Remote)
  - Nahimic audio software
  - (Optional) Armoury Crate, Aura Sync, ROG software

Auto-Reinstallers (blocked):
  - ASUS Software Manager and its agent
  - ASUS Live Update auto-updater
  - ASUS Download Agent
  - ASUS Update Check service
  - All ASUS scheduled tasks that trigger reinstallation
  - ASUS installer cache and promotion directories

Bundled Third-Party Software:
  - McAfee (antivirus trial)
  - Norton (antivirus trial)
  - WinZip (trial)
  - ExpressVPN (trial)
  - Dropbox
  - Spotify (if bundled)


WHAT STAYS INTACT
-----------------
  - Chipset drivers
  - Audio drivers (Realtek, etc.)
  - Network/WiFi/Bluetooth drivers
  - Graphics drivers
  - BIOS/UEFI components
  - Windows functionality
  - Hardware sensor access


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select "Before ASUS Bloat Removal" restore point
  3. Follow the wizard to restore

Option 2: Reinstall Individual Software
  - MyASUS: Download from Microsoft Store or ASUS website
  - Armoury Crate: https://www.asus.com/campaign/Armoury-Crate/
  - AI Suite: Download from your motherboard's support page
  - Other software: ASUS support page for your specific model

Option 3: Reinstall All ASUS Software
  1. Go to https://www.asus.com/support/
  2. Enter your product model
  3. Download desired utilities from the Drivers & Tools section

To re-enable ASUS auto-updates (if needed):
  1. Reinstall ASUS Software Manager from your model's support page
  2. The script sets registry keys to disable auto-install; reinstalling
     the software will restore these settings


IF YOU REMOVED ARMOURY CRATE
----------------------------
Without Armoury Crate:
  - RGB lighting will use default/last saved settings or stay off
  - Fans will use BIOS profiles (configurable in BIOS settings)
  - Performance modes not available (use Windows power plans instead)

To control fans without Armoury Crate:
  1. Enter BIOS (press DEL or F2 at boot)
  2. Find Q-Fan Control or similar
  3. Set fan curves manually
  4. Save and exit

Alternative RGB control:
  - OpenRGB (open source): https://openrgb.org/
  - SignalRGB: https://signalrgb.com/


MCAFEE COMPLETE REMOVAL
-----------------------
If McAfee wasn't fully removed, use the official removal tool:
  1. Download MCPR from:
     https://www.mcafee.com/consumer/en-us/store/m0/catalog/mwad_702/mcafee-removal-tool.html
  2. Run the tool and follow instructions
  3. Restart your computer


PREVENTING RE-INSTALLATION
--------------------------
This script blocks known ASUS auto-reinstall mechanisms including:
  - ASUS Software Manager service and scheduled tasks
  - ASUS Live Update service
  - ASUS Download Agent
  - Update check registry entries
  - Installer staging/cache directories

If ASUS software still returns after a Windows feature update:
  1. Run this script again after the update completes
  2. Windows feature updates can restore provisioned AppX packages;
     the script removes provisioning to prevent this where possible


NOTES
-----
- Some ASUS software may reinstall after major Windows feature updates
- Run this script again if bloatware returns
- Removing AI Suite won't affect CPU/RAM overclocking in BIOS
- BIOS updates can still be done manually via EZ Flash


TIPS
----
- Use Windows Security (Defender) instead of McAfee
- Use 7-Zip instead of WinZip (free and better)
- Consider keeping Armoury Crate if you paid for RGB peripherals
- Check ASUS support page for important driver updates separately
- BIOS fan control is often more reliable than software control
