================================================================================
                   InterruptLatencyTuning.bat - Instructions
================================================================================

PURPOSE:
--------
Reduces interrupt (ISR) and Deferred Procedure Call (DPC) latency to eliminate
microstutter in games, audio crackling, and input lag spikes.

Impact: ⭐⭐⭐⭐⭐ - This is what causes "microstutter"


WHAT CAUSES HIGH DPC/ISR LATENCY:
---------------------------------

ISR (Interrupt Service Routine):
  - Hardware sends interrupt to CPU
  - Driver's ISR runs to acknowledge/handle it
  - Poor drivers can take milliseconds (should be <100μs)

DPC (Deferred Procedure Call):
  - Work queued by ISR for later processing
  - Runs at elevated priority, blocking normal threads
  - Poorly written drivers queue excessive DPCs

Common symptoms:
  - Frame drops every few seconds
  - Audio pops/crackles during gaming
  - Mouse movement feels "chunky"
  - Inconsistent frame pacing


WHAT THIS SCRIPT OPTIMIZES:
---------------------------

1. MSI (Message Signaled Interrupts)
   - Enables MSI/MSI-X for GPU, NIC, Storage, USB
   - Eliminates shared interrupt lines
   - Allows direct CPU core targeting
   - Result: ~10-50% reduction in interrupt overhead

2. Interrupt Affinity
   - Distributes interrupts across multiple CPU cores
   - Prevents "interrupt storm" on core 0
   - Configures GPU/NIC to use specific cores
   - Result: More even CPU utilization

3. System Timer Resolution
   - Disables dynamic tick (consistent timer intervals)
   - Configures platform timer for lowest latency
   - Disables HPET (uses TSC instead)
   - Result: More precise thread scheduling

4. Kernel Scheduler
   - Optimizes thread quantum for responsiveness
   - Disables DPC watchdog timeout
   - Disables CPU core parking
   - Disables deep C-states
   - Result: Faster context switches

5. Driver-Specific Fixes
   - NVIDIA: Disables telemetry, HDCP overhead
   - AMD: Disables ULPS (wake latency) - sets EnableUlps = 0 in the display
     adapter's class key, only where the driver already created the value
   - Network: Disables interrupt moderation, flow control and Energy
     Efficient Ethernet (*InterruptModeration, *FlowControl, *EEE,
     EEELinkAdvertisement) - only on adapters whose driver defines them
   - USB: Disables selective suspend, and per-device enhanced power
     management (EnhancedPowerManagementEnabled = 0 on devices that have it)
   - Result: Lower per-driver latency

6. Multimedia Class Scheduler (MMCSS)
   - Disables network throttling
   - Sets system responsiveness to 0
   - Optimizes "Games" task priority
   - Result: Better scheduling for games/audio

7. Network Latency
   - Disables Nagle's algorithm
   - Sets TcpAckFrequency to 1
   - Result: Lower network latency


TECHNICAL TARGETS:
------------------

Good:
  - Average DPC latency: <500μs
  - Max DPC latency: <1000μs
  - Average ISR latency: <100μs

Acceptable:
  - Average DPC latency: <1000μs
  - Max DPC latency: <2000μs
  - Occasional spikes during disk I/O

Bad (needs fixing):
  - Average DPC latency: >1000μs
  - Max DPC latency: >8000μs
  - Frequent spikes


HOW TO USE:
-----------
1. Right-click InterruptLatencyTuning.bat
2. Select "Run as administrator"
3. Choose whether to create a restore point (recommended)
4. Confirm you want to apply optimizations
5. Restart when prompted. The restart is scheduled 30 seconds ahead; press A
   at the prompt to abort it (Ctrl+C does NOT cancel a scheduled restart -
   use "shutdown /a" if the prompt is gone)

Verification:
1. Download LatencyMon: https://www.resplendence.com/latencymon
2. Run LatencyMon after restart
3. Use your system normally (game, browse, etc.)
4. Check the "Drivers" tab for highest latency offenders
5. Monitor DPC/ISR counts and latency values


COMMON HIGH-LATENCY DRIVERS AND FIXES:
--------------------------------------

1. Realtek HD Audio (RTKVHD64.sys)
   Problem: Often causes 1-10ms DPC spikes
   Fixes:
   - Update to latest driver from Realtek website
   - Use Windows generic "High Definition Audio Device" driver
   - If using external DAC, disable onboard audio in BIOS

2. NVIDIA HD Audio (nvlddmkm.sys)
   Problem: Can spike when switching audio/video modes
   Fixes:
   - Disable "HD Audio" in NVIDIA driver installer
   - Use DisplayPort audio instead of HDMI if needed

3. Network drivers (various)
   Problem: Interrupt moderation batches interrupts
   Fixes:
   - Disable "Interrupt Moderation" in adapter properties
   - Disable "Energy Efficient Ethernet" (EEE)
   - Update to latest manufacturer driver

4. ACPI.sys
   Problem: BIOS/firmware communication latency
   Fixes:
   - Update BIOS to latest version
   - Disable unused devices in BIOS
   - Check for BIOS power management settings

5. Wireless drivers (various)
   Problem: Power saving causes connection latency
   Fixes:
   - Set "Power Saving Mode" to "Maximum Performance"
   - Disable "Roaming Aggressiveness"
   - Use ethernet for gaming if possible


HOW TO RESTORE DEFAULTS:
------------------------

Option 1: System Restore
- Open System Restore (rstrui.exe)
- Select the restore point created before running the script
- Follow prompts to restore

Option 2: Manual Restoration

A. MSI Mode:
   Do NOT delete MessageSignaledInterruptProperties or set MSISupported=0 -
   most NVMe, USB 3, GPU and NIC drivers enable MSI themselves and would fall
   back to legacy line-based interrupts (worse than before the script ran).
   To undo, use System Restore (Option 1).
   If one specific device misbehaves after the script (its driver did not
   enable MSI itself), delete only that device's value (admin Command Prompt):
   reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\PCI\<device>\<instance>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v MSISupported /f
   (<device>\<instance> is the rest of the "Device instance path" shown in
   Device Manager > device > Properties > Details, after "PCI\".) Restart
   Windows afterwards. Updating or rolling back the driver does NOT remove
   the value the script wrote.

B. Timer settings:
   bcdedit /deletevalue disabledynamictick
   bcdedit /deletevalue useplatformtick
   (The script also ran "bcdedit /deletevalue useplatformclock". That value
   is absent by default; only if you had set it yourself before, set it
   again with: bcdedit /set useplatformclock true)

C. DPC Watchdog:
   reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DpcWatchdogPeriod" /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DpcTimeout" /f

D. Thread scheduling (restore Windows default):
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 2 /f

E. Power throttling:
   reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /f

F. CPU power settings (re-enable idle, parking and throttling, AC and DC):
   The script changed the plan that was active when it ran (SCHEME_CURRENT);
   run these with that plan active.
   powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 0
   powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 0
   powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 10
   powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 10
   powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5
   powercfg /setactive SCHEME_CURRENT
   (Simplest and exact for built-in plans: powercfg /restoredefaultschemes -
   note it also deletes custom plans.)

G. MMCSS (restore defaults):
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 10 /f
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 20 /f
   Games task (the script raised Priority, Scheduling Category and SFIO Priority):
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "Medium" /f
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "Normal" /f

H. Nagle's algorithm (re-enable):
   For each interface in HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces:
   reg delete "...\Interfaces\{interface}" /v "TcpAckFrequency" /f
   reg delete "...\Interfaces\{interface}" /v "TCPNoDelay" /f

I. Memory paging (restore default):
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 0 /f

J. Interrupt affinity (GPU and Realtek NIC):
   For each affected device instance under
   HKLM\SYSTEM\CurrentControlSet\Enum\PCI\VEN_10DE*, VEN_1002*, VEN_10EC*:
   reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\PCI\<device>\<instance>\Device Parameters\Interrupt Management\Affinity Policy" /f

K. NVIDIA:
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v DisableHDCP /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v RmDisableHdcp22 /f

L. USB power management:
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /f
   The script also set EnhancedPowerManagementEnabled = 0 in each USB
   device's Device Parameters key (HKLM\SYSTEM\CurrentControlSet\Enum\USB\
   <device>\<instance>\Device Parameters) that had the value. System Restore
   reverts this exactly; otherwise set it back to 1 on the devices where you
   want USB power saving:
   reg add "HKLM\SYSTEM\CurrentControlSet\Enum\USB\<device>\<instance>\Device Parameters" /v EnhancedPowerManagementEnabled /t REG_DWORD /d 1 /f

M. Network adapter advanced settings:
   Device Manager > Network adapters > your adapter > Properties > Advanced:
   set Interrupt Moderation, Flow Control and Energy Efficient Ethernet back
   to their defaults (or set *InterruptModeration=1, *FlowControl=3, *EEE=1
   as REG_SZ in the adapter's
   HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\000N key)

N. AMD ULPS:
   Set EnableUlps back to 1 (REG_DWORD) in the same display adapter key(s):
   HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\000N
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\000N" /v EnableUlps /t REG_DWORD /d 1 /f


ADVANCED: MANUAL INTERRUPT AFFINITY:
------------------------------------

To manually set which CPU core handles a device's interrupts:

1. Open Device Manager
2. Right-click device > Properties > Resources
3. Note the IRQ or MSI message number
4. Use Microsoft Interrupt Affinity Policy Tool, or:

   Registry path for device:
   HKLM\SYSTEM\CurrentControlSet\Enum\{device}\Device Parameters\Interrupt Management\Affinity Policy

   Values:
   - DevicePolicy (DWORD):
     0 = Default (Windows decides)
     1 = All close processors
     2 = One close processor
     3 = All processors
     4 = Specified processors (use AssignmentSetOverride)
     5 = Spread messages across all processors

   - AssignmentSetOverride (BINARY):
     Bitmask of allowed CPUs
     01 = CPU 0 only
     02 = CPU 1 only
     0C = CPU 2 and 3
     FF = All 8 CPUs


COMPATIBILITY:
--------------
- Windows 10 (1903+)
- Windows 11 (all versions)
- Works with Intel, AMD, and hybrid CPUs
- Works with NVIDIA, AMD, and Intel GPUs


TROUBLESHOOTING:
----------------

Issue: System unstable after changes
Fix: Boot to Safe Mode, run System Restore

Issue: No improvement in LatencyMon
Fix: Check "Drivers" tab - specific driver may need updating

Issue: Higher power consumption / heat
Fix: Expected tradeoff. To undo it, follow step F above (it restores CPU idle
     states, core parking and minimum processor state for both AC and battery)

Issue: Audio still crackling
Fix: Try different audio driver, check buffer sizes in audio apps

Issue: Game still stutters
Fix: May be GPU driver issue, shader compilation, or game-specific

================================================================================
