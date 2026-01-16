# Bat-Toolbox

A collection of Windows batch scripts for system maintenance, security, debloating, and automation tasks.

## Quick Start

1. **Run as Administrator** - Right-click each `.bat` file and select "Run as administrator"
2. **Read the prompts** - Most scripts ask for confirmation before making changes
3. **Reboot when prompted** - Some changes require a restart to take effect

---

## Main Scripts

### FileSorter.bat

**Purpose:** Automatically organizes files into folders based on their file extension.

**What it does:**
- Scans all files in the script's directory (recursively)
- Creates folders named after file extensions (e.g., `PDF`, `JPG`, `DOCX`)
- Moves files into their corresponding extension folders
- Skips files that are already sorted or have duplicate names

**Usage:**
1. Place the script in the folder you want to organize
2. Run the script
3. Confirm when prompted

**Example result:**
```
Before:                    After:
/Downloads/                /Downloads/
  photo.jpg                  /JPG/photo.jpg
  document.pdf               /PDF/document.pdf
  song.mp3                   /MP3/song.mp3
  FileSorter.bat             FileSorter.bat
```

**Admin required:** No

---

### ExportInstalledPrograms.bat

**Purpose:** Scans and exports a list of all installed programs for clean install recovery.

**What it captures:**
| Source | Description |
|--------|-------------|
| 64-bit Registry | Standard desktop applications |
| 32-bit Registry (WoW64) | 32-bit apps on 64-bit Windows |
| User Registry | Per-user installed applications |
| Microsoft Store | AppX packages (non-framework) |
| Windows Features | Enabled optional features |
| Detailed List | Name, version, and publisher info |

**Output:** Creates `InstalledPrograms_COMPUTERNAME_DATE.txt` on Desktop

**Sample output:**
```
============================================================================
 DESKTOP APPLICATIONS (64-bit)
============================================================================

Mozilla Firefox
Google Chrome
Visual Studio Code
...

============================================================================
 DETAILED PROGRAM LIST (Name, Version, Publisher)
============================================================================

NAME                                      | VERSION     | PUBLISHER
----------------------------------------- | ----------- | --------------------
7-Zip                                     | 23.01       | Igor Pavlov
Adobe Acrobat Reader                      | 23.006      | Adobe Inc.
...
```

**Also includes:**
- Manual checklist (browser extensions, bookmarks, license keys, etc.)
- Tips for using Ninite, Chocolatey, and Winget for reinstallation
- Winget export command for automated bulk reinstall

**When to use:**
- Before a clean Windows install
- Before major system changes
- For system documentation/inventory

**Admin required:** No (but some features detected may require admin)

---

### FirmwareCheck.bat

**Purpose:** Scans system firmware and driver versions, outputs search-ready strings for checking updates online.

**What it detects:**
| Component | Information Gathered |
|-----------|---------------------|
| BIOS/UEFI | Manufacturer, version, date, motherboard model |
| CPU | Processor name for chipset driver search |
| GPU | Graphics card model, driver version and date |
| Network | Adapter names, driver versions |
| Audio | Sound device names, driver versions |
| Storage | Disk models, firmware revisions |
| Chipset | Platform detection for driver search |

**Output:** Creates `FirmwareInfo_COMPUTERNAME.txt` on Desktop

**Sample output:**
```
QUICK SEARCH STRINGS [Copy into your browser]

  BIOS:    ASUS ROG STRIX B550-F GAMING BIOS update download
  Chipset: ASUS ROG STRIX B550-F GAMING chipset driver
  GPU:     NVIDIA GeForce driver download

DIRECT LINKS
  NVIDIA:   https://www.nvidia.com/Download/index.aspx
  AMD:      https://www.amd.com/en/support
  Intel:    https://www.intel.com/content/www/us/en/download-center/home.html
```

**Features:**
- Pre-formatted search strings ready to paste into Google
- Direct download links for major vendors (NVIDIA, AMD, Intel, Realtek)
- Motherboard-specific support links (ASUS, MSI, Gigabyte, ASRock, Dell, HP, Lenovo)
- Current driver versions to compare against latest available

**When to use:**
- After a fresh Windows install to update drivers
- Periodically to check for firmware/driver updates
- Before troubleshooting hardware issues

**Admin required:** No

---

### Honeypot.bat

**Purpose:** A decoy file that logs information about anyone who opens it, then shuts down the computer.

**What it does:**
1. **Silently collects evidence:**
   - Timestamp of access
   - Username, computer name, domain
   - Network/IP information
   - List of running processes

2. **Displays warning screens:**
   - Shows fake "intrusion detected" messages
   - Plays audio alerts via text-to-speech
   - Shows dramatic countdown

3. **Forces shutdown** after the countdown

**Output:** Creates `IntruderLog.txt` in the same directory with collected data.

**Use case:** Leave this disguised (renamed) in a sensitive folder to catch unauthorized access.

**Warning:** This script WILL shut down the computer when run.

**Admin required:** No (but shutdown may be blocked by system policies)

---

### NetworkReset.bat

**Purpose:** Performs a complete network stack reset to fix connectivity issues.

**What it does (in order):**
1. Releases current IP address
2. Flushes DNS cache
3. Clears ARP cache
4. Resets Winsock catalog
5. Resets TCP/IP stack
6. Disables network adapter (5 second wait)
7. Re-enables network adapter (5 second wait)
8. Renews IP address
9. Displays new IP configuration

**When to use:**
- Internet connection is unstable or not working
- DNS resolution problems
- After removing malware
- VPN connection issues
- "No Internet" despite being connected

**Admin required:** Yes

---

### ProcessScanner.bat

**Purpose:** Scans running processes to identify bloatware, forgotten background programs, and resource hogs.

**Categories:**
| Category | Description |
|----------|-------------|
| HIGH MEMORY | Processes using >500MB RAM |
| BLOATWARE | Known unnecessary programs - offers to terminate |
| OPTIONAL | Legitimate but potentially unnecessary |
| UNKNOWN | Unrecognized - research before terminating |

**What it detects:**
- Third-party antivirus running alongside Defender
- PUPs and scareware (Segurazo, registry cleaners, driver updaters)
- Forgotten background apps (Steam, Discord, Spotify)
- Unnecessary updaters (Java, Adobe, Google Update)
- Vendor bloatware processes

**Features:**
- Shows memory usage per process
- Calculates total bloatware memory impact
- Offers to terminate bloatware with permission
- Links to StartupAnalyzer for permanent fixes

**Admin required:** Yes (recommended)

---

### RemoveAsusBloat.bat

**Purpose:** Removes ASUS pre-installed bloatware while keeping essential hardware drivers.

**What it removes:**
| Category | Software |
|----------|----------|
| ASUS Utilities | MyASUS, GIFTBOX, AI Suite, WebStorage, Live Update, Splendid |
| Gaming/Audio | GameFirst, Sonic Studio, Sonic Radar, Nahimic |
| Optional | Armoury Crate, Aura Sync, ROG software (you choose) |
| Third-Party | McAfee, Norton, WinZip, ExpressVPN trials |

**What it keeps:**
- Hardware drivers (chipset, audio, network, Bluetooth)
- BIOS/UEFI components
- Basic system functionality

**Features:**
- Interactive prompt for Armoury Crate removal decision
- Removes services, scheduled tasks, and startup items
- Cleans up leftover folders

**Note:** If you use RGB lighting or custom fan profiles, consider keeping Armoury Crate.

**Admin required:** Yes

---

### RemoveEOSNotification.bat

**Purpose:** Removes the Windows 10 "End of Support" notification that appears in the system tray.

**What it does:**
1. Terminates any running EOSNotify processes
2. Sets registry keys to disable OS upgrade prompts
3. Disables EOSNotify scheduled tasks
4. Renames `EOSNotify.exe` to prevent future execution

**When to use:** If you're staying on Windows 10 and want to remove the upgrade nag.

**Admin required:** Yes

---

### RemoveNvidiaBloat.bat

**Purpose:** Removes NVIDIA bloatware while keeping the essential graphics driver intact.

**What it removes:**
| Component | Description |
|-----------|-------------|
| GeForce Experience | Game optimization/recording app |
| NVIDIA Telemetry | Data collection services |
| NVIDIA Container | Background container processes |
| NvNode / NvBackend | NodeJS server and backend |
| NVIDIA Web Helper | Browser integration |
| Scheduled Tasks | All NVIDIA telemetry/update tasks |

**What it keeps:**
- NVIDIA graphics driver (core functionality)
- NVIDIA Control Panel
- Display/rendering capabilities

**What it does:**
1. Stops all NVIDIA bloatware processes
2. Disables telemetry and container services
3. Runs GeForce Experience uninstaller
4. Removes NVIDIA scheduled tasks
5. Cleans up registry entries
6. Deletes leftover folders

**When to use:** After installing NVIDIA drivers, if you only want the driver without extras.

**Note:** After driver updates, bloatware may be reinstalled. Consider using [NVCleanstall](https://www.techpowerup.com/download/techpowerup-nvcleanstall/) for clean driver installations.

**Admin required:** Yes

---

### RestoreRecycleBin.bat

**Purpose:** Restores the Recycle Bin icon to the Windows desktop if it was accidentally hidden or removed.

**What it does:**
1. Removes registry flags that hide the Recycle Bin
2. Re-registers the Recycle Bin in the desktop namespace
3. Sets visibility flag to "show"
4. Restarts Explorer to apply changes

**When to use:** If the Recycle Bin disappeared from your desktop after running debloat scripts or registry tweaks.

**Admin required:** No

---

### StartupAnalyzer.bat

**Purpose:** Scans all startup programs and categorizes them for easy cleanup.

**Categories:**
| Category | Description |
|----------|-------------|
| KEEP | Essential programs (drivers, security) - do not disable |
| OPTIONAL | Legitimate but non-essential - your choice to disable |
| UNKNOWN | Not recognized - research before disabling |
| REMOVE | Known bloatware - recommended for removal |

**What it detects as bloatware:**
- Third-party antivirus (McAfee, Norton, Avast)
- Updater services (Java, Adobe, Google Update)
- Auto-starting apps (Steam, Discord, Spotify)
- PUPs (Driver Booster, IObit, registry cleaners)
- Scareware (Segurazo, ByteFence, Reimage)

**Features:**
- Scans registry Run keys and Startup folders
- Provides explanations for each program
- Asks permission before removing anything
- Opens Task Manager for optional items review

**Admin required:** Yes (recommended for full access)

---

### ScreenSleepGuard.bat

**Purpose:** Turns off the monitor and forces a logout if someone tries to wake it without knowing the secret key combination.

**How it works:**
1. Displays instructions (3 second countdown)
2. Turns off the monitor
3. Monitors for keyboard input:
   - **ALT+TAB** = Safe wake (returns to desktop)
   - **Any other key** = Logs out the user immediately

**Use case:** Step away from your computer briefly while deterring casual snoopers.

**Companion file:** Requires `ScreenSleepGuard.ps1` in the same directory.

**Admin required:** No

---

### WindowsTweaks.bat

**Purpose:** Interactive menu for applying advanced Windows customizations not easily accessible through normal settings.

**Categories available:**

| Category | Tweaks Included |
|----------|-----------------|
| Performance | Disable SysMain/Superfetch, Search Indexing, Prefetch, Fast Startup, Power Throttling, NTFS optimizations |
| Gaming | Disable Game DVR, Fullscreen Optimizations, HPET; Enable Hardware GPU Scheduling; CPU/GPU priority tweaks |
| UI/Visual | Disable transparency, animations, Aero Shake; Restore classic context menu (Win11); Show clock seconds |
| Privacy | Disable telemetry, Cortana, Bing search, Activity History, advertising ID, app suggestions |
| Explorer | Show file extensions/hidden files, open to This PC, disable Quick Access history, remove 3D Objects |
| Network | Disable Nagle's algorithm, network throttling, auto-tuning; Optimize DNS priority |
| Input | Disable mouse acceleration, Sticky/Filter/Toggle Keys popups; Max keyboard repeat rate |

**Menu options:**
```
[1] Apply ALL Tweaks (Recommended)
[2] Performance Tweaks
[3] Gaming Tweaks
[4] UI / Visual Tweaks
[5] Privacy Tweaks
[6] Explorer Tweaks
[7] Network Tweaks
[8] Input Tweaks
[9] Restore Defaults
[0] Exit
```

**Highlights:**
- Disables Game DVR background recording (frees GPU resources)
- Enables Hardware-accelerated GPU Scheduling
- Restores Windows 10 right-click menu on Windows 11
- Disables mouse acceleration for raw input (better for gaming)
- Removes Bing from Start Menu search
- Disables all accessibility key popups (Sticky Keys, etc.)

**When to use:** After a fresh Windows install to optimize for performance and privacy.

**Admin required:** Yes

---

## Windows Debloat Suite

The `windows-debloat/` folder contains a comprehensive set of scripts for stripping Windows 10 down to essentials.

**See [windows-debloat/README.md](windows-debloat/README.md) for full documentation.**

### Quick Reference

| Script | Purpose |
|--------|---------|
| 00-Create-Restore-Point.bat | Create system restore point (run first!) |
| 01-Remove-Bloatware.bat | Remove pre-installed apps |
| 02-Disable-Services.bat | Disable telemetry/unused services |
| 03-Disable-Tasks.bat | Disable data collection tasks |
| 04-Registry-Privacy.bat | Privacy-focused registry tweaks |
| 05-Registry-Performance.bat | Performance registry tweaks |
| 06-Remove-Features.bat | Remove optional Windows features |
| 07-Block-Telemetry-Hosts.bat | Block telemetry via hosts file |
| 08-Firewall-Rules.bat | Block telemetry executables |
| 09-Uninstall-OneDrive.bat | Remove OneDrive completely |
| 10-Performance-Tweaks.bat | System performance optimizations |
| 11-Cleanup-Temp-Cache.bat | Clean temp files and browser caches |
| 12-Interactive-Remover.bat | Guided removal with Y/N prompts |

---

## Admin Requirements Summary

| Script | Admin Required |
|--------|----------------|
| ExportInstalledPrograms.bat | No |
| FileSorter.bat | No |
| FirmwareCheck.bat | No |
| Honeypot.bat | No |
| NetworkReset.bat | Yes |
| ProcessScanner.bat | Yes |
| RemoveAsusBloat.bat | Yes |
| RemoveEOSNotification.bat | Yes |
| RemoveNvidiaBloat.bat | Yes |
| RestoreRecycleBin.bat | No |
| ScreenSleepGuard.bat | No |
| StartupAnalyzer.bat | Yes |
| WindowsTweaks.bat | Yes |
| windows-debloat/*.bat | Yes (all) |

---

## Troubleshooting

**Script won't run:**
- Right-click and select "Run as administrator"
- If blocked by SmartScreen, click "More info" > "Run anyway"

**PowerShell errors:**
- Some scripts use PowerShell internally
- Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Need to undo changes:**
- Use System Restore if you created a restore point
- See individual script documentation for reversal steps

---

## License

These scripts are provided as-is for educational and personal use. Use at your own risk.
