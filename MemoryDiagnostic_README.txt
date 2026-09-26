================================================================================
 MemoryDiagnostic.bat - Instructions
================================================================================

DESCRIPTION
-----------
Shows installed RAM details (speed, slots used, single/dual channel), checks
for mismatched sticks, compares the configured RAM speed with the module's
reported maximum, reports current memory usage breakdown by process, provides
a configuration grade, and opens the Windows Memory Diagnostic (mdsched.exe)
dialog so you can schedule a RAM test.


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
  - Memory speed vs module maximum
  - Memory usage by process

With admin:
  - All above features
  - Open Windows Memory Diagnostic (mdsched.exe) to schedule a RAM test
  - View previous diagnostic results


MENU OPTIONS
------------
Option 1: Hardware Info
  - Lists each RAM stick with capacity, speed, type, manufacturer, part number
  - Shows slot usage (e.g., "2 of 4 slots filled")
  - Detects channel mode (single/dual/quad)
  - Flags mismatched sticks (different speeds or capacities)
  - Compares configured RAM speed with the module's BIOS-reported maximum
    (cannot confirm XMP/EXPO state; CPU/platform limits also lower speed)
  - Memory type names include DDR-DDR5 and LPDDR-LPDDR5
  - Warns about single-channel mode

Option 2: Usage Breakdown
  - Visual memory usage bar
  - Top 25 processes by memory usage
  - Category breakdown (browsers, system, security, game clients)
  - Highlights processes using >5% of total RAM

Option 3: Configuration Analysis
  - Scores your memory configuration (A-F grade)
  - Checks: total RAM, channel mode, stick matching, memory speed,
    expansion slots, current usage, pagefile
  - Lists issues and specific recommendations

Option 4: Windows Memory Diagnostic
  - [1] / [2] open the Windows Memory Diagnostic dialog (mdsched.exe) and
    tell you which choice to pick there: "Restart now and check for
    problems" or "Check for problems the next time I start my computer".
    Nothing is scheduled or restarted until you choose in that dialog;
    cancelling it changes nothing
  - [3] View results from previous diagnostic runs
  - The test checks all RAM addresses with multiple patterns


WHAT THE ANALYSIS CHECKS
-------------------------
| Check           | Good                    | Bad                        |
|-----------------|-------------------------|----------------------------|
| Total RAM       | 16+ GB                  | <8 GB                      |
| Channel Mode    | Dual or Quad            | Single                     |
| Stick Matching  | Same speed + capacity   | Mixed speeds or capacities |
| Memory Speed    | At module max           | Below module max           |
| Current Usage   | <75%                    | >90%                       |
| Pagefile        | Configured, low usage   | Missing or >50% used       |


COMMON ISSUES DETECTED
-----------------------
Single-Channel Mode:
  - Halves memory bandwidth
  - Fix: Add a matching stick in the correct slot (consult motherboard manual)
  - Performance impact: 10-30% in bandwidth-sensitive tasks

Memory Speed Below Module Max:
  - The configured speed is lower than the maximum speed the BIOS reports
    for the module (SMBIOS "Speed"). That value is usually the JEDEC speed,
    not the XMP/EXPO profile speed, so the script cannot tell whether
    XMP/DOCP/EXPO is on: a kit with XMP off can still show "At module max"
  - Common causes: memory profile off in BIOS, or the CPU/chipset capping
    memory speed (e.g. DDR4-3200 SO-DIMMs on a CPU limited to 2933)
  - Desktops: check the BIOS memory profile (XMP on Intel, DOCP/EXPO on AMD)
  - Laptops and locked chipsets often cap speed and offer no XMP option;
    the script does not recommend a BIOS change for laptops
  - Advisory only: this check does not lower the grade

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
Option 4 only opens the Windows Memory Diagnostic dialog. If you choose to
test there, Windows sets up a one-time boot into the memory tester, which
runs once and then returns to normal startup; nothing else is modified.

Older versions of this script also ran "bcdedit /set {memdiag} locale en-US"
(forcing the memory tester to English) without saying so. To restore your
language, run this in an administrator Command Prompt, replacing de-DE
with your own locale (the "locale" line of "bcdedit /enum {current}"):
  bcdedit /set {memdiag} locale de-DE


NOTES
-----
- Uses Win32_PhysicalMemory WMI class for hardware info
- Channel mode is inferred from stick count (exact detection requires
  motherboard-specific data)
- The memory speed check compares ConfiguredClockSpeed with Speed (the
  BIOS-reported module maximum); it cannot read the XMP/EXPO profile
- Memory Diagnostic (mdsched) runs before Windows loads — takes 10-30 min
- mdsched results are stored in the Windows System event log
- Some virtual machines may not report all RAM details


TIPS
----
- Check option [1] after installing new RAM to verify speed and channel mode
- Run option [3] periodically to check memory health
- On desktops, check that XMP/DOCP/EXPO is enabled in the BIOS if your kit
  is rated above the speed shown (laptops usually have no such option)
- Use option [2] to find memory-hungry processes to close
- For laptops, check if slots are soldered (no upgrade possible)
- If memory diagnostic finds errors:
  1. Reseat RAM sticks
  2. Test one stick at a time to identify the faulty module
  3. Replace the faulty stick
- Pair with PagefileTuner.bat to optimize virtual memory
