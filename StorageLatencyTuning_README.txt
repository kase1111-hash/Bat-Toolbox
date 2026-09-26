================================================================================
                    StorageLatencyTuning.bat - Instructions
================================================================================

PURPOSE:
--------
Optimizes NVMe/SSD storage for minimum latency and maximum throughput.
Addresses the #1 performance bottleneck that affects everything on your system.

Impact: ⭐⭐⭐⭐⭐ (Storage touches everything - OS, apps, games, file operations)


WHAT IT OPTIMIZES:
------------------

1. NVMe Power State Transitions
   - Disables PS3/PS4 low-power states (can add 100-500+ microseconds latency)
   - Prevents Autonomous Power State Transition (APST)
   - Sets latency tolerance to minimum
   - Why: NVMe drives aggressively sleep to save power, causing I/O stalls

2. AHCI Link Power Management (ASPM)
   - Disables HIPM (Host Initiated Power Management)
   - Disables DIPM (Device Initiated Power Management)
   - Disables PCIe Active State Power Management
   - Why: Link power states add wake latency to every I/O operation

3. Write Cache Optimization
   - Explains how to enable write-back caching (Device Manager > Policies);
     not changed automatically
   - Optimizes NTFS behavior (disables last access timestamps)
   - Disables 8.3 filename creation overhead
   - Why: Stable write caching prevents random latency spikes

4. Queue Depth Settings
   - Increases NVMe queue depth to 256 (Windows defaults are conservative)
   - Disables interrupt coalescing (trades throughput for latency)
   - Enables MSI-X for efficient interrupt handling
   - Why: NVMe supports 64K queues × 64K entries, underutilization = waste

5. Power Plan Optimization
   - Activates the Ultimate Performance plan (or High Performance if Ultimate
     is unavailable) BEFORE any power setting is written, so the NVMe, AHCI,
     PCIe ASPM and disk idle settings apply to the plan that stays active.
     Plans are selected by GUID, so this works on non-English Windows.
   - The Ultimate Performance copy always uses the GUID
     3ff9831b-6f80-4830-8178-736cd4229e7b, so running the script again reuses
     it instead of adding another duplicate plan
   - If neither plan can be activated (e.g. Modern Standby laptops), the
     current plan is kept and the settings are written to it
   - The plan that was active before is printed at the start ("Previous plan")
   - Exposes hidden NVMe power options in Control Panel
   - Disables disk idle timeouts
   - Why: Balanced/Power Saver plans throttle storage

6. Additional Storage Optimizations
   - Prefetch/Superfetch are disabled only when the disk holding the Windows
     drive is an SSD
   - The ScheduledDefrag task is disabled only when EVERY physical disk is an
     SSD; with any HDD (or unknown media type) it is kept, because it also
     defragments HDDs


TECHNICAL BACKGROUND:
---------------------

Why default settings are conservative:
- Laptops: Battery life prioritized over performance
- Thermals: Lower power = less heat
- Enterprise: Power costs scale with thousands of servers

What you gain:
- Reduced random I/O latency (measured in microseconds)
- Consistent sequential throughput
- Faster application launches
- Reduced game stutter from asset loading
- Snappier file operations

What you trade:
- ~1-3W higher power consumption
- Slightly warmer SSD temperatures
- Less battery life on laptops


WHEN TO USE:
------------
- Desktop gaming/workstation PCs (always recommended)
- After fresh Windows install
- If experiencing random micro-stutters
- Before benchmarking storage performance
- Content creation workstations

WHEN NOT TO USE:
----------------
- Laptops where battery life is critical
- Systems with poor cooling
- Old/failing SSDs with thermal throttling issues


HOW TO USE:
-----------
1. Right-click StorageLatencyTuning.bat
2. Select "Run as administrator"
3. Choose whether to create a restore point (recommended)
4. Confirm you want to apply optimizations
5. Restart when prompted. The restart is scheduled 30 seconds ahead; press A
   at the prompt to abort it (Ctrl+C does NOT cancel a scheduled restart -
   use "shutdown /a" if the prompt is gone)

Verification:
- Run CrystalDiskMark before and after
- Compare 4K Random Read/Write latency
- Check Queue Depth 32 results for improvement


HOW TO RESTORE DEFAULTS:
------------------------

Option 1: System Restore
- Open System Restore (rstrui.exe)
- Select the restore point created before running the script
- Follow prompts to restore

Option 2: Manual Restoration

A. Switch back to your previous power plan FIRST:
   The script switched to Ultimate Performance (or High Performance) before
   writing any power setting, and printed the plan that was active before it
   ran ("Previous plan"). If that is a different plan from the one the
   script activated, your previous plan was not changed, so switching back
   restores its storage power settings. Balanced:
   powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
   Optional - remove the Ultimate Performance copy the script created
   (it must not be the active plan):
   powercfg /delete 3ff9831b-6f80-4830-8178-736cd4229e7b

B. Restore storage power settings - only needed if the script printed
   "Keeping current power plan" (it then changed your current plan), if the
   previous plan already was the plan the script activated (e.g. a second
   run), or if you ran an older version of this script, which changed the
   plan that was active before it ran:
   powercfg /restoredefaultschemes
   (Resets NVMe idle timeout, NOPPME, AHCI LPM, PCIe ASPM and disk idle on
   every built-in plan, removes the Ultimate Performance copy, and leaves
   Balanced active. Custom plans are deleted.)
   Manual alternative, with the changed plan active (AC and DC):
   powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 200
   powercfg /setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 100
   powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 1200
   powercfg /setdcvalueindex SCHEME_CURRENT SUB_DISK DISKIDLE 600
   (AHCI LPM 0b2d69d7-a2a1-449c-9680-f91c70521c60 and PCIe ASPM
   ee12f906-d277-404b-b6da-e5fa1a576df5: set AC and DC back to your plan's
   defaults in Power Options, or use /restoredefaultschemes)
   powercfg /setactive SCHEME_CURRENT

C. Modern Standby storage D3 (restore sleep power saving):
   reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /f
   The script also set EnableIdlePowerManagement = 0 in each storage
   device's ...\Device Parameters\StorPort key under
   HKLM\SYSTEM\CurrentControlSet\Enum; System Restore (Option 1) reverts it.

D. AHCI registry (re-enable link power management):
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "EnableHIPM" /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "EnableDIPM" /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "EnableAN" /f

E. Queue Depth and interrupt coalescing (restore defaults):
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IoQueueDepth" /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IoCoalescingEnabled" /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "InterruptCoalescingEnabled" /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters" /v "IoLatencyCap" /f

F. File System (restore defaults):
   fsutil behavior set disablelastaccess 2
   fsutil behavior set disable8dot3 2
   fsutil behavior set memoryusage 1

G. Prefetch (re-enable):
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 3 /f
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 3 /f

H. Scheduled Defrag (re-enable; the script disables it only when every
   disk is an SSD):
   schtasks /change /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /enable


EXPECTED RESULTS:
-----------------

Before (typical):
  4K Random Read:   50-80 MB/s @ 0.5-1.0ms latency
  4K Random Write:  100-150 MB/s @ 0.3-0.5ms latency
  Queue Depth 32:   400-600 MB/s random

After (optimized):
  4K Random Read:   60-100 MB/s @ 0.1-0.3ms latency
  4K Random Write:  150-250 MB/s @ 0.1-0.2ms latency
  Queue Depth 32:   600-1000 MB/s random

Note: Actual results depend on your specific NVMe drive model.


ADVANCED: DEVICE MANAGER SETTINGS
---------------------------------

For maximum performance on enterprise/high-end SSDs:

1. Open Device Manager
2. Expand "Disk drives"
3. Right-click your NVMe drive > Properties
4. Go to "Policies" tab
5. Check "Enable write caching on the device"
6. Check "Turn off Windows write-cache buffer flushing"
   (Only if SSD has power loss protection/capacitors!)


COMPATIBILITY:
--------------
- Windows 10 (1903+)
- Windows 11 (all versions)
- Works with all NVMe and SATA SSDs
- Safe for HDDs (some settings won't apply; scheduled defrag is kept when
  any HDD is present)


TROUBLESHOOTING:
----------------

Issue: Drive runs warmer than before
Fix: This is expected. Monitor temps; if >70°C under load, improve airflow

Issue: Laptop battery drains faster
Fix: Run restore steps A-C above (switch plans back first, then restore the
     AC and DC storage settings and Modern Standby D3), or create a separate
     "Battery" power plan

Issue: No improvement in benchmarks
Fix: Your drive may already be optimized, or bottleneck is elsewhere (CPU/RAM)

Issue: System instability after changes
Fix: Use System Restore to revert, then apply changes selectively

================================================================================
