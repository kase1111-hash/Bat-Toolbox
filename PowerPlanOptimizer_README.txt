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
Note: Power plan changes are easily reversible.
Option [5] restores all Windows defaults.


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
| Network adapter            | Max Performance | Max Performance    | Moderate            |
| Timer resolution           | Maximum         | Default            | Default             |


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


HOW TO RESTORE / UNDO
---------------------
Option 1: Use menu option [5]
  - Restores all default power plans
  - Removes custom Maximum/Balanced Performance plans
  - Switches to Balanced plan

Option 2: Control Panel
  - Control Panel > Power Options > Select a different plan

Option 3: Command line
  powercfg /restoredefaultschemes


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


NOTES
-----
- Script auto-detects laptop vs desktop
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
- Run option [3] to verify settings were applied
- Use option [4] to unlock all hidden settings for manual tweaking
- Pair with InterruptLatencyTuning.bat for lowest possible latency
- Use LatencyMon to verify improvements
- If your PC runs too hot, switch to Balanced Performance
- For competitive gaming, combine with:
  1. PowerPlanOptimizer.bat (this script)
  2. InterruptLatencyTuning.bat
  3. StorageLatencyTuning.bat
  4. GPUDriverOptimizer.bat
