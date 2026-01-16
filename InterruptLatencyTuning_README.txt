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
   - AMD: Disables ULPS (wake latency)
   - Network: Disables interrupt moderation, EEE
   - USB: Disables selective suspend
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
5. Restart when prompted

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

A. MSI Mode (restore to line-based interrupts):
   Delete the "MessageSignaledInterruptProperties" registry keys, or set:
   reg add "...\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d 0 /f

B. Timer settings:
   bcdedit /deletevalue disabledynamictick
   bcdedit /deletevalue useplatformtick

C. DPC Watchdog:
   reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DpcWatchdogPeriod" /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DpcTimeout" /f

D. Thread scheduling (restore Windows default):
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 2 /f

E. Power throttling:
   reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /f

F. CPU core parking (re-enable):
   powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 10
   powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR IDLEDISABLE 0
   powercfg /setactive SCHEME_CURRENT

G. MMCSS (restore defaults):
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 10 /f
   reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 20 /f

H. Nagle's algorithm (re-enable):
   For each interface in HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces:
   reg delete "...\Interfaces\{interface}" /v "TcpAckFrequency" /f
   reg delete "...\Interfaces\{interface}" /v "TCPNoDelay" /f

I. Memory paging (restore default):
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 0 /f


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
Fix: Expected tradeoff; re-enable core parking if needed

Issue: Audio still crackling
Fix: Try different audio driver, check buffer sizes in audio apps

Issue: Game still stutters
Fix: May be GPU driver issue, shader compilation, or game-specific

================================================================================
