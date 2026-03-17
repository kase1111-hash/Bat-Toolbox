================================================================================
 MemoryDiagnostic.bat - Instructions
================================================================================

DESCRIPTION
-----------
Shows installed RAM details (speed, slots used, single/dual channel), checks
for mismatched sticks, detects XMP/DOCP status, reports current memory usage
breakdown by process, provides a configuration grade, and offers to schedule
Windows Memory Diagnostic (mdsched.exe) for next reboot.


HOW TO USE
----------
1. Right-click MemoryDiagnostic.bat (admin recommended for full features)
2. Choose from the menu:
   [1] Hardware info (RAM sticks, speed, slots, channels)
   [2] Current memory usage breakdown by process
   [3] Memory configuration analysis
   [4] Schedule Windows Memory Diagnostic (requires admin)


ADMIN REQUIREMENTS
------------------
Without admin:
  - RAM hardware info (sticks, speed, capacity, manufacturer)
  - Channel mode detection
  - Mismatch detection
  - XMP/DOCP status
  - Memory usage by process

With admin:
  - All above features
  - Schedule Windows Memory Diagnostic (mdsched.exe)
  - View previous diagnostic results


MENU OPTIONS
------------
Option 1: Hardware Info
  - Lists each RAM stick with capacity, speed, type, manufacturer, part number
  - Shows slot usage (e.g., "2 of 4 slots filled")
  - Detects channel mode (single/dual/quad)
  - Flags mismatched sticks (different speeds or capacities)
  - Detects if XMP/DOCP/EXPO is enabled
  - Warns about single-channel mode

Option 2: Usage Breakdown
  - Visual memory usage bar
  - Top 25 processes by memory usage
  - Category breakdown (browsers, system, security, game clients)
  - Highlights processes using >5% of total RAM

Option 3: Configuration Analysis
  - Scores your memory configuration (A-F grade)
  - Checks: total RAM, channel mode, stick matching, XMP/DOCP,
    expansion slots, current usage, pagefile
  - Lists issues and specific recommendations

Option 4: Windows Memory Diagnostic
  - Schedule hardware RAM test for next reboot
  - Option to restart immediately or schedule for later
  - View results from previous diagnostic runs
  - Tests all RAM addresses with multiple patterns


WHAT THE ANALYSIS CHECKS
-------------------------
| Check           | Good                    | Bad                        |
|-----------------|-------------------------|----------------------------|
| Total RAM       | 16+ GB                  | <8 GB                      |
| Channel Mode    | Dual or Quad            | Single                     |
| Stick Matching  | Same speed + capacity   | Mixed speeds or capacities |
| XMP/DOCP        | Running at rated speed  | Below rated speed          |
| Current Usage   | <75%                    | >90%                       |
| Pagefile        | Configured, low usage   | Missing or >50% used       |


COMMON ISSUES DETECTED
-----------------------
Single-Channel Mode:
  - Halves memory bandwidth
  - Fix: Add a matching stick in the correct slot (consult motherboard manual)
  - Performance impact: 10-30% in bandwidth-sensitive tasks

XMP/DOCP Not Enabled:
  - RAM running below rated speed
  - Fix: Enter BIOS > enable XMP (Intel) or DOCP/EXPO (AMD)
  - Example: DDR4-3200 running at 2133 MHz

Mismatched Sticks:
  - All sticks run at the slowest speed
  - Different capacities cause flex mode (partial dual-channel)
  - Fix: Replace with matched kit

High Memory Usage:
  - System may be swapping to pagefile (slow)
  - Fix: Close unnecessary programs, add more RAM, or check for memory leaks


WHEN TO RUN MEMORY DIAGNOSTIC (OPTION 4)
------------------------------------------
Run mdsched.exe if you experience:
  - Blue screens (BSOD) with codes: MEMORY_MANAGEMENT, IRQL_NOT_LESS_OR_EQUAL,
    PAGE_FAULT_IN_NONPAGED_AREA, BAD_POOL_HEADER
  - Random application crashes or freezes
  - Unexplained file corruption
  - System instability after adding new RAM sticks
  - Random restarts without blue screen


HOW TO UNDO
-----------
This script is read-only (diagnostic only) — no system changes are made.
Option 4 schedules a diagnostic but does not modify Windows settings.


NOTES
-----
- Uses Win32_PhysicalMemory WMI class for hardware info
- Channel mode is inferred from stick count (exact detection requires
  motherboard-specific data)
- XMP/DOCP detection compares ConfiguredClockSpeed vs Speed
- Memory Diagnostic (mdsched) runs before Windows loads — takes 10-30 min
- mdsched results are stored in the Windows System event log
- Some virtual machines may not report all RAM details


TIPS
----
- Check option [1] after installing new RAM to verify speed and channel mode
- Run option [3] periodically to check memory health
- If XMP is not enabled, you're leaving free performance on the table
- Use option [2] to find memory-hungry processes to close
- For laptops, check if slots are soldered (no upgrade possible)
- If memory diagnostic finds errors:
  1. Reseat RAM sticks
  2. Test one stick at a time to identify the faulty module
  3. Replace the faulty stick
- Pair with PagefileTuner.bat to optimize virtual memory
