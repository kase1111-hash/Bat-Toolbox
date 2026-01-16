# Windows 10 Debloat Scripts

A collection of batch scripts for stripping Windows 10 down to essentials by removing bloatware, disabling telemetry, and optimizing performance.

## Important Warning

These scripts make significant changes to your Windows installation. **Always create a restore point first** (use script `00`) and understand what each script does before running it.

---

## Quick Start

1. **Run as Administrator** - Right-click each `.bat` file and select "Run as administrator"
2. **Start with script 00** - Always create a restore point first
3. **Run scripts in order** - The numbering suggests the recommended order
4. **Reboot after** - Restart your computer after running scripts

---

## Script Reference

### 00-Create-Restore-Point.bat

**Purpose:** Creates a Windows System Restore point before making changes.

**What it does:**
- Enables System Restore if disabled
- Creates a restore point named "Before Windows 10 Debloat"

**When to use:** ALWAYS run this first before any other scripts.

**Reversibility:** N/A - This is your safety net.

---

### 01-Remove-Bloatware.bat

**Purpose:** Removes pre-installed Windows apps (AppX packages).

**What it removes:**
- 3D apps (3D Builder, 3D Viewer, Mixed Reality Portal)
- Bing apps (Finance, News, Sports, Weather)
- Entertainment (Solitaire, Groove Music, Movies & TV)
- Communication (Skype, People, Messaging, Your Phone)
- Xbox apps (if you don't PC game)
- Utilities (Maps, Alarms, Camera, Sound Recorder)
- Microsoft apps (Office Hub, OneNote, Feedback Hub)
- Third-party bloat (Candy Crush, Facebook, Spotify, etc.)

**When to use:** Safe for most users who don't use these apps.

**Reversibility:** Most apps can be reinstalled from Microsoft Store.

**Note:** Some apps may return after Windows updates.

---

### 02-Disable-Services.bat

**Purpose:** Disables unnecessary Windows services.

**Services disabled:**

| Category | Services |
|----------|----------|
| Telemetry | DiagTrack, dmwappushservice, WMPNetworkSvc |
| Xbox | XblAuthManager, XblGameSave, XboxGipSvc, XboxNetApiSvc |
| Consumer | MapsBroker, lfsvc (Location), RetailDemo |
| Rarely Used | Fax, WpcMonSvc, wisvc, PhoneSvc, WerSvc |

**When to use:**
- Safe if you don't use Xbox features, location services, or fax
- Skip Xbox services if you play games on PC

**Reversibility:** Run `sc config "ServiceName" start=auto` to re-enable.

---

### 03-Disable-Tasks.bat

**Purpose:** Disables telemetry and data collection scheduled tasks.

**Tasks disabled:**
- Compatibility Appraiser (telemetry)
- Customer Experience Improvement Program
- Disk Diagnostic Data Collector
- Feedback/DmClient tasks
- Maps update tasks
- Family Safety monitoring

**When to use:** Safe for all users concerned about privacy.

**Reversibility:** Run `schtasks /Change /TN "TaskPath" /Enable` to re-enable.

---

### 04-Registry-Privacy.bat

**Purpose:** Applies registry tweaks to enhance privacy.

**What it disables:**
- Windows telemetry
- Cortana
- Bing/web search in Start Menu
- Activity history and timeline
- Advertising ID
- App suggestions and silent app installs
- Lock screen spotlight/ads
- OneDrive integration
- Windows tips and suggestions

**When to use:** Recommended for privacy-conscious users.

**Reversibility:** Changes can be reversed via Registry Editor (regedit).

---

### 05-Registry-Performance.bat

**Purpose:** Applies registry tweaks for better performance.

**What it disables:**
- Window minimize/maximize animations
- Taskbar animations
- Aero Peek

**When to use:** Good for older hardware or if you prefer snappy UI.

**Reversibility:**
- System Properties > Advanced > Performance Settings
- Select "Let Windows choose what's best"

---

### 06-Remove-Features.bat

**Purpose:** Removes optional Windows features using DISM.

**Features removed:**
| Feature | Reason |
|---------|--------|
| Internet Explorer 11 | Legacy browser |
| Windows Media Player | Legacy media player |
| Work Folders Client | Enterprise feature |
| XPS Printing | Rarely used |
| Fax Services | Legacy feature |
| SMB 1.0 Protocol | **Security risk** (WannaCry) |
| PowerShell 2.0 | **Security risk** (bypasses security) |

**When to use:** Safe for most users. SMB1 and PS2 should be removed for security.

**Reversibility:** Run `dism /online /Enable-Feature /FeatureName:FeatureName`

**Note:** Requires reboot to complete.

---

### 07-Block-Telemetry-Hosts.bat

**Purpose:** Adds entries to the Windows hosts file to block telemetry domains.

**What it blocks:**
- Microsoft telemetry servers (vortex, watson, etc.)
- Feedback servers
- Advertising networks (MSN ads, DoubleClick)

**When to use:** Additional layer of protection after disabling services.

**Reversibility:**
- Backup is created automatically
- Edit `C:\Windows\System32\drivers\etc\hosts` to remove entries

---

### 08-Firewall-Rules.bat

**Purpose:** Creates firewall rules to block telemetry executables.

**What it blocks:**
| Executable | Purpose |
|------------|---------|
| CompatTelRunner.exe | Compatibility Telemetry |
| DeviceCensus.exe | Device Census |
| smartscreen.exe | SmartScreen filter |
| wsqmcons.exe | SQM Consolidator |

**When to use:** For maximum telemetry blocking.

**Warning:** Blocking smartscreen.exe reduces security protection against malicious downloads.

**Reversibility:** Delete rules in Windows Firewall with Advanced Security.

---

### 09-Uninstall-OneDrive.bat

**Purpose:** Completely removes Microsoft OneDrive.

**What it does:**
- Stops and uninstalls OneDrive
- Removes OneDrive folders
- Removes OneDrive from Explorer sidebar

**When to use:** If you don't use OneDrive cloud storage.

**Warning:** Any files only in OneDrive will be lost! Sync important files first.

**Reversibility:** Re-download OneDrive from Microsoft.

---

### 10-Performance-Tweaks.bat

**Purpose:** Applies performance optimizations.

**What it does:**
| Tweak | Benefit |
|-------|---------|
| Disable Hibernation | Saves GB of disk space |
| Clear Temp Files | Frees disk space |
| Disable Prefetch/Superfetch | Better for SSDs |
| Disable Windows Search | Reduces disk activity |

**When to use:**
- Hibernation: If you shut down instead of hibernate
- Prefetch: If you have an SSD
- Windows Search: If using alternative search (Everything)

**Reversibility:**
- Hibernation: `powercfg /hibernate on`
- Superfetch: `sc config SysMain start=auto && net start SysMain`
- Search: `sc config WSearch start=auto && net start WSearch`

---

### 11-Cleanup-Temp-Cache.bat

**Purpose:** Cleans up temporary files and caches to free disk space.

**What it cleans:**
| Location | Description |
|----------|-------------|
| User Temp (%TEMP%) | User temporary files |
| Windows Temp | System temporary files |
| Windows Update Cache | Downloaded update files |
| Prefetch | Application prefetch data |
| Thumbnail Cache | Explorer thumbnail database |
| Icon Cache | Explorer icon database |
| Edge Cache | Microsoft Edge browser cache |
| Chrome Cache | Google Chrome browser cache |
| Firefox Cache | Mozilla Firefox browser cache |
| DNS Cache | DNS resolver cache |
| Windows Installer | Orphaned patch cache |
| Error Reports | Windows Error Reporting files |
| Recent Documents | Recent files list |

**When to use:**
- Run periodically to free up disk space
- Before creating a system backup
- When disk space is running low
- After uninstalling many programs

**Warning:** Close all browsers before running this script.

**Reversibility:** Caches will rebuild automatically as needed. Recent documents list will repopulate with use.

---

### 12-Interactive-Remover.bat

**Purpose:** Interactive guided removal of optional Windows programs and features.

**How it works:**
- Goes through each removable item one by one
- Shows what the program/feature does
- Warns if removal may break something
- Asks Y/N before each removal
- Only shows items that are actually installed

**Categories covered:**

| Category | Examples |
|----------|----------|
| 3D Apps | 3D Builder, 3D Viewer, Print 3D, Mixed Reality |
| Bing Apps | Finance, News, Sports, Weather |
| Communication | People, Messaging, Skype, Phone Link |
| Entertainment | Groove Music, Movies & TV, Solitaire |
| Office | Office Hub, OneNote |
| Utilities | Alarms, Camera, Maps, Paint 3D, Feedback Hub |
| Xbox | Game Bar, Xbox App, Identity Provider |
| Third-Party | Candy Crush, Spotify, Netflix, Facebook, etc. |
| Caution Items | Photos, Calculator, Store (warns before removal) |
| Windows Features | IE11, Media Player, SMB1, PowerShell 2.0 |

**When to use:**
- First time debloating (learn what each app does)
- When you want fine-grained control
- When unsure what's safe to remove

**Default behavior:**
- Safe-to-remove items default to Y (remove)
- Items that may break things default to N (keep)
- Press Enter to accept the default

**Reversibility:** Most apps can be reinstalled from Microsoft Store. Features can be re-enabled via DISM.

---

## Recommended Order of Operations

1. **00-Create-Restore-Point.bat** - Always first!
2. **01-Remove-Bloatware.bat** - Remove unwanted apps
3. **04-Registry-Privacy.bat** - Apply privacy settings
4. **02-Disable-Services.bat** - Disable unnecessary services
5. **03-Disable-Tasks.bat** - Disable scheduled tasks
6. **06-Remove-Features.bat** - Remove optional features
7. **07-Block-Telemetry-Hosts.bat** - Block at network level
8. **08-Firewall-Rules.bat** - Block executables
9. **09-Uninstall-OneDrive.bat** - Remove OneDrive (optional)
10. **10-Performance-Tweaks.bat** - Performance tuning
11. **11-Cleanup-Temp-Cache.bat** - Clean temp files and caches
12. **Reboot**

---

## Things That May Break

| If You Remove/Disable | This May Break |
|-----------------------|----------------|
| Xbox services | Xbox Game Bar, Game DVR |
| Your Phone app | Phone Link integration |
| Windows Search | Start menu search (use Everything instead) |
| OneDrive | Cloud file sync |
| SmartScreen firewall rule | Download protection |
| Location service | Weather, Maps, location-aware apps |
| BITS service | Windows Update downloads |

---

## Recommended Alternative Software

| Purpose | Recommendation |
|---------|----------------|
| File Search | [Everything](https://www.voidtools.com/) |
| Archive Handling | [7-Zip](https://www.7-zip.org/) |
| Media Player | [VLC](https://www.videolan.org/) |
| Image Viewer | [IrfanView](https://www.irfanview.com/) |
| Text Editor | [Notepad++](https://notepad-plus-plus.org/) |
| Browser | Firefox or Brave |

---

## Troubleshooting

**Script won't run:**
- Right-click and select "Run as administrator"
- Check that execution policy allows scripts

**Something broke after running scripts:**
- Use System Restore to revert to the restore point created by script 00
- Control Panel > Recovery > Open System Restore

**Apps came back after update:**
- Re-run script 01 after Windows updates

**Need to re-enable a service:**
```batch
sc config "ServiceName" start=auto
net start "ServiceName"
```

---

## License

These scripts are provided as-is for educational and personal use. Use at your own risk.
