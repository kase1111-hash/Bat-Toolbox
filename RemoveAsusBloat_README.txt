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
5. Choose whether to also uninstall third-party programs (McAfee, Norton,
   WinZip, ExpressVPN, Dropbox, Spotify). Answer N if you installed or paid
   for any of them yourself. Pressing Enter without typing Y counts as N.
6. Wait for all phases to complete
7. Restart when prompted


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

If you KEEP it (answer N, or just press Enter), the script leaves all of
these alone:
  - Processes and services: ArmouryCrateService, ArmouryCrateControlInterface,
    ArmourySocketServer, AsusCertService, AsusFanControlService,
    GameSDK Service, LightingService (Aura), ROGLiveService
  - Scheduled tasks for Armoury Crate, ROG Live Service, Aura/Lighting,
    fan control and AsusCertService
  - ROG mouse power agents (P508PowerAgent / P513PowerAgent) and their
    scheduled tasks
  - The ArmouryCrate / LightingService / ROGLiveService / AuraSync startup
    entries
  - The Armoury Crate, Aura Creator and Gaming Center Store apps
  - The Armoury Crate / Aura / ROG program folders

If you REMOVE it, all of the above are stopped, disabled or removed, and the
installed Armoury Crate, ROG, Aura and LightingService programs are uninstalled.


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
  - ASUS scheduled tasks that trigger reinstallation (except the
    "ASUS Optimization ..." task, which starts the Fn-key handler)
  - ASUS installer cache and promotion directories

Third-Party Software (OPTIONAL - only if you answer Y to its own prompt):
  - McAfee
  - Norton
  - WinZip
  - ExpressVPN
  - Dropbox
  - Spotify
  Nothing checks whether these came pre-installed or were installed by you,
  so answer N if you use or paid for any of them.

How desktop programs are uninstalled:
  Installed programs are matched by name against the Windows uninstall list
  and removed silently with "msiexec /x <ProductCode> /qn /norestart". This
  replaces "wmic product ... call uninstall", because WMIC is not available
  on Windows 11 24H2 and later. Only MSI-installed programs are removed this
  way; a program with its own installer (for example McAfee LiveSafe) may
  need its vendor's uninstaller or removal tool - see MCAFEE COMPLETE REMOVAL.
  The script prints "Uninstalled: <name> [exit N]" for each product it
  removes (exit 0 or 3010 means success).
  "ROG" and "AURA" are matched as whole words only, so unrelated programs
  whose names merely contain those letters ("Program...", "Laura...") are
  not touched.


WHAT STAYS INTACT
-----------------
  - Chipset drivers
  - Audio drivers (Realtek, etc.)
  - Network/WiFi/Bluetooth drivers
  - Graphics drivers
  - BIOS/UEFI components
  - Windows functionality
  - Hardware sensor access
  - Fn hotkeys / OSD: the ASUS Optimization service (ASUSOptimization) and
    its "ASUS Optimization ..." scheduled task, which starts AsusHotkey.exe,
    the ASUS System Control Interface package itself (not uninstalled,
    although its System Analysis and System Diagnosis services are still
    disabled), and the ASUS Keyboard Hotkeys Store app
  - Armoury Crate and its services/tasks, if you chose to keep it
  - Third-party programs, unless you chose to remove them


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

To re-enable a service the script disabled (run as Administrator):
  sc config "<ServiceName>" start= auto
  sc start "<ServiceName>"
  Services it may disable: AsusAppService, AsusLinkNear, AsusLinkRemote,
  AsusSoftwareManager, AsusSoftwareManagerAgent, AsusSystemAnalysis,
  AsusSystemDiagnosis, AsusUpdateCheck, NahimicService, ScreenXpertService,
  asus, asusm, ASUSLiveUpdate, ASUSSwitch - plus, only if you chose to
  remove Armoury Crate: ArmouryCrateControlInterface, ArmouryCrateService,
  ArmourySocketServer, AsusCertService, AsusFanControlService,
  "GameSDK Service", LightingService, ROGLiveService

Fn hotkeys stopped working after running an OLDER version of this script?
Older versions also disabled the ASUS Optimization service and removed its
"ASUS Optimization ..." scheduled task. This version leaves both alone.
To restore the service (run as Administrator):
  sc config ASUSOptimization start= auto
  sc start ASUSOptimization
If the hotkeys still do not work, reinstall "ASUS System Control Interface"
from your model's support page (Drivers & Tools).

Kept Armoury Crate but ran an OLDER version of this script?
Older versions disabled the Armoury Crate / Aura / fan services, removed its
tasks (including the ROG mouse power agent tasks) and Store app even when you
answered N. Re-enable the Armoury services listed above with the sc
commands, then reinstall Armoury Crate from
https://www.asus.com/campaign/Armoury-Crate/ to restore its tasks and app.


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
The script only removes MSI-installed McAfee components, and only if you
answered Y to the third-party prompt. McAfee LiveSafe / Total Protection use
their own installer. If McAfee wasn't fully removed, use the official
removal tool:
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
