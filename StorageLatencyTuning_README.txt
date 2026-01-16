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
   - Enables write-back caching policy
   - Optimizes NTFS behavior (disables last access timestamps)
   - Disables 8.3 filename creation overhead
   - Why: Stable write caching prevents random latency spikes

4. Queue Depth Settings
   - Increases NVMe queue depth to 256 (Windows defaults are conservative)
   - Disables interrupt coalescing (trades throughput for latency)
   - Enables MSI-X for efficient interrupt handling
   - Why: NVMe supports 64K queues × 64K entries, underutilization = waste

5. Power Plan Optimization
   - Activates Ultimate/High Performance plan
   - Exposes hidden NVMe power options in Control Panel
   - Disables disk idle timeouts
   - Why: Balanced/Power Saver plans throttle storage


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
5. Restart when prompted

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

A. NVMe Power States (restore power saving):
   powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 100
   powercfg /setactive SCHEME_CURRENT

B. AHCI Link Power Management (re-enable):
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "EnableHIPM" /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v "EnableDIPM" /f
   powercfg /setacvalueindex SCHEME_CURRENT SUB_DISK 0b2d69d7-a2a1-449c-9680-f91c70521c60 1
   powercfg /setactive SCHEME_CURRENT

C. PCIe ASPM (re-enable):
   powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 2
   powercfg /setactive SCHEME_CURRENT

D. Queue Depth (restore defaults):
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IoQueueDepth" /f
   reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IoCoalescingEnabled" /f

E. File System (restore defaults):
   fsutil behavior set disablelastaccess 2
   fsutil behavior set disable8dot3 2
   fsutil behavior set memoryusage 1

F. Prefetch (re-enable):
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 3 /f
   reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 3 /f

G. Scheduled Defrag (re-enable):
   schtasks /change /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /enable

H. Power Plan (restore Balanced):
   powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e


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
- Safe for HDDs (some settings won't apply)


TROUBLESHOOTING:
----------------

Issue: Drive runs warmer than before
Fix: This is expected. Monitor temps; if >70°C under load, improve airflow

Issue: Laptop battery drains faster
Fix: Run restore commands above, or create a separate "Battery" power plan

Issue: No improvement in benchmarks
Fix: Your drive may already be optimized, or bottleneck is elsewhere (CPU/RAM)

Issue: System instability after changes
Fix: Use System Restore to revert, then apply changes selectively

================================================================================
