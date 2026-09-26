================================================================================
 PowerPlanOptimizer.bat - Instructions
================================================================================

DESCRIPTION
-----------
Goes beyond the basic "High Performance" power plan. Creates custom power
plans with hidden settings like CPU core parking, frequency scaling, PCI
Express link state, USB selective suspend, and timer resolution. Creates
a "Maximum Performance" plan for desktops/gaming and a "Balanced Performance"
plan for laptops. Includes an option to unhide all hidden power settings
in Control Panel.


HOW TO USE
----------
1. Right-click PowerPlanOptimizer.bat
2. Select "Run as administrator" (REQUIRED)
3. Choose from the menu:
   [1] Create "Maximum Performance" plan (desktop/gaming)
   [2] Create "Balanced Performance" plan (laptop-friendly)
   [3] View current power plan details
   [4] Unhide all power settings in Control Panel
   [5] Restore Windows default power plans


BEFORE YOU RUN
--------------
Note: Power plan changes are easily reversible. Option [5] switches to
Balanced, deletes the two Bat-Toolbox plans and resets all power plans to
the Windows defaults (see HOW TO RESTORE / UNDO for what else it does and
does not undo). Two changes are outside the power plans:
  - Option [1] disables the dynamic timer tick (a boot setting). Option [5]
    asks separately whether to re-enable it.
  - Option [4] changes the visibility of power settings in the registry. It
    saves a backup (PowerSettings_Attributes_backup_<COMPUTERNAME>.reg)
    first.


PLAN COMPARISON
---------------
| Setting                    | Maximum Perf    | Balanced Perf (AC) | Balanced Perf (DC) |
|----------------------------|-----------------|--------------------|---------------------|
| CPU min state              | 100%            | 10%                | 5%                  |
| CPU max state              | 100%            | 100%               | 100%                |
| Core parking min           | 100% (disabled) | 50%                | 25%                 |
| Boost policy               | Aggressive      | Moderate           | Conservative        |
| CPU cooling                | Active          | Active             | Active              |
| PCI Express ASPM           | Off             | Off                | Moderate            |
| USB selective suspend      | Disabled        | Disabled           | Enabled             |
| Hard disk spin-down        | Never           | Never              | 20 min              |
| Display off                | Never           | 15 min             | 5 min               |
| Sleep                      | Never           | Never              | 30 min              |
| Hibernate                  | Never           | Never              | Default             |
| Network adapter            | Max Performance | Max Performance    | Medium saving       |
| Timer resolution           | Maximum         | Default            | Default             |

On laptops (including 2-in-1s), the Maximum Performance plan turns the
display off after 15 min on battery instead of "Never".


WHAT EACH SETTING DOES
-----------------------
CPU Minimum Processor State:
  Controls the lowest frequency the CPU will drop to at idle.
  100% = CPU never downclocks. Lower values save power.

CPU Core Parking:
  Windows can "park" (disable) CPU cores when not needed.
  Parking adds wake-up latency (50-200μs per core unpark).
  Disabling keeps all cores active and ready.

PCI Express ASPM (Active State Power Management):
  Allows PCIe devices (GPU, NVMe) to enter low-power states.
  Transitions add latency (microseconds to milliseconds).
  Disabling eliminates random stutter from state transitions.

USB Selective Suspend:
  Allows Windows to power down USB devices when idle.
  Can cause mice, keyboards, and headsets to disconnect briefly.
  Disabling keeps all USB devices always powered.

Processor Performance Boost:
  Controls how aggressively the CPU uses boost/turbo clocks.
  Aggressive = faster ramp-up to max frequency.

Timer Resolution:
  Windows timer tick rate. Higher resolution = more precise scheduling.
  Reduces input latency in games and real-time applications.

Hard Disk Spin-Down:
  Time before spinning HDDs enter standby.
  "Never" prevents the delay when the drive wakes back up.
  (Does not affect SSDs.)

NVMe Latency Tolerance (Maximum Performance plan):
  Primary and secondary NVMe power state transition latency tolerance are
  set to 0 ms, so NVMe drives do not enter idle power states (APST).

Display / Sleep / Disk Timeouts:
  powercfg stores these values in seconds. The script writes 900 s
  (15 min), 300 s (5 min), 1800 s (30 min) and 1200 s (20 min).
  Earlier versions of this script wrote the minute numbers as seconds
  (for example, display off after 5 seconds on battery). If you ran an
  older version, run option [1] or [2] again (or option [5]) to fix it.


HOW TO RESTORE / UNDO
---------------------
Option 1: Use menu option [5]
  - Shows all current plans and asks for confirmation first
  - Switches to Balanced plan
  - Deletes the Bat-Toolbox Maximum/Balanced Performance plans
  - Runs powercfg /restoredefaultschemes, which ALSO deletes any other
    user-created or app-created plan (e.g. an Ultimate Performance copy).
    Export a plan you want to keep first:
      powercfg /export "C:\plan-backup.pow" <GUID>
    and bring it back later with: powercfg /import "C:\plan-backup.pow"
  - Asks whether to re-enable the dynamic timer tick (see below)

Option 2: Control Panel
  - Control Panel > Power Options > Select a different plan

Option 3: Command line
  powercfg /restoredefaultschemes
  WARNING: this also deletes every user-created or app-created plan.
  Export any plan you want to keep first (powercfg /export, see above).

Timer change from option [1] (step 9):
  Option [1] runs "bcdedit /set disabledynamictick yes". This is a boot
  setting, not part of a power plan. To undo it, answer Y to the timer
  question in option [5], or run this from an admin prompt and reboot:
    bcdedit /deletevalue disabledynamictick
  Note: InterruptLatencyTuning.bat and WindowsTweaks.bat set the same
  value, so this also undoes their timer tweak.

Hidden settings from option [4]:
  Before unhiding, option [4] saves the original values to
  PowerSettings_Attributes_backup_<COMPUTERNAME>.reg in the script folder,
  where <COMPUTERNAME> is the name of the PC. There is one backup file per
  PC, so a copy of Bat-Toolbox used on several PCs (USB stick, synced
  folder) keeps a separate backup for each. An existing backup for the PC
  is kept, so it always holds the state from before the first run.
  To hide the settings again, double-click that file, or run from an
  admin prompt (use the full path; an admin prompt starts in System32):
    reg import "<script folder>\PowerSettings_Attributes_backup_<COMPUTERNAME>.reg"
  Import only the file whose name matches this PC's own computer name
  (to see it, run "echo %COMPUTERNAME%" in a command prompt). A backup
  from another PC would write that PC's power settings into this one.


HIDDEN SETTINGS (OPTION 4)
--------------------------
Option [4] unhides settings that Windows keeps hidden by default:
  - Processor performance core parking min/max cores
  - Processor performance boost policy and mode
  - Processor autonomous mode
  - Heterogeneous thread scheduling policy
  - NVMe primary/secondary latency tolerance
  - GPU preference policy
  - Network adapter power settings
  - Advanced sleep settings
  - Hub selective suspend timeout

After unhiding, these appear in:
  Control Panel > Power Options > Change plan settings >
  Change advanced power settings

A backup of the original values is saved first to
PowerSettings_Attributes_backup_<COMPUTERNAME>.reg in the script folder
(one file per PC). If the backup cannot be written (for example, a
read-only folder), nothing is changed.
See HOW TO RESTORE / UNDO to re-hide the settings.


NOTES
-----
- Script auto-detects laptop vs desktop (2-in-1 convertibles, detachables
  and tablets count as laptops)
- Laptop users are warned about battery impact
- Plans persist across reboots (unlike temp files)
- Custom plans can be further tweaked in Control Panel
- The "Ultimate Performance" plan (Windows 10 Pro for Workstations)
  is similar to our Maximum Performance but with fewer tweaks
- These settings complement StorageLatencyTuning.bat and
  InterruptLatencyTuning.bat for maximum system responsiveness


TIPS
----
- Desktop gamers: use Maximum Performance
- Laptop gamers: use Balanced Performance (better thermals)
- Run option [3] to verify settings were applied (values are shown as raw
  hex from powercfg; timeouts are in seconds, e.g. 0x00000384 = 900 s)
- Use option [4] to unlock all hidden settings for manual tweaking
- Pair with InterruptLatencyTuning.bat for lowest possible latency
- Use LatencyMon to verify improvements
- If your PC runs too hot, switch to Balanced Performance
- For competitive gaming, combine with:
  1. PowerPlanOptimizer.bat (this script)
  2. InterruptLatencyTuning.bat
  3. StorageLatencyTuning.bat
  4. GPUDriverOptimizer.bat
