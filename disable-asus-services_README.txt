================================================================================
 disable-asus-services.bat - Instructions
================================================================================

DESCRIPTION
-----------
Stops and disables five ASUS background services that are commonly considered
bloat on ASUS laptops and desktops. It works purely at the Service Control
Manager layer (sc config) - no files are deleted or swapped - so every change
is cleanly and individually reversible.

Services targeted:
  - ASUS Software Manager     (update pusher)
  - ASUS Switch               (device migration; rarely used)
  - ASUS System Analysis      (telemetry)
  - ASUS System Diagnosis     (telemetry)
  - ASUS App Service          (passive monitor)

ASUS Optimization is intentionally LEFT RUNNING because it is the parent
process of AsusHotkey.exe, which handles the Fn hotkeys. Disabling it would
break keyboard function keys, so it is deliberately excluded.


HOW TO USE
----------
1. Right-click disable-asus-services.bat
2. Select "Run as administrator" (REQUIRED)
3. Watch the per-service progress. Each service is looked up by its display
   name, stopped if running, then set to start = disabled.
4. Review the summary at the end (disabled / stopped / not-found counts).

The script is idempotent - safe to run again on already-disabled services.


WHAT IT DOES
------------
For each of the five display names, the script:
  1. Resolves the real service short name via PowerShell Get-Service.
  2. If the service is RUNNING, issues "sc stop".
  3. Issues "sc config <name> start= disabled".
  4. Increments the appropriate counter for the summary.

If a service does not exist on your system it is simply counted as
"not found" and skipped - no error.


BEFORE YOU RUN
--------------
- These are ASUS-specific services; on non-ASUS hardware the script will
  simply report all five as "not found" and change nothing.
- No restore point is strictly required (changes are trivially reversible),
  but creating one is never a bad idea before bulk service edits.


HOW TO RESTORE / UNDO
---------------------
Re-enable any single service by name. Use the SHORT service name printed by
the script (not the display name). For example:

  sc config "ASUSSoftwareManager" start= auto
  sc start  "ASUSSoftwareManager"

Repeat for each service you want back. The exact start type each service had
originally is usually "auto" or "demand"; "auto" is a safe default.


VERIFICATION
------------
Confirm a service is disabled:
  sc qc "<ServiceName>" | findstr START_TYPE   (should show DISABLED)
  sc query "<ServiceName>" | findstr STATE     (should show STOPPED)


TIPS
----
- The Fn-key handler (ASUS Optimization) is left alone on purpose. If your Fn
  keys stop working after other tweaks, that service is the one to check.
- If you also want to neutralize the ASUS updater binary itself (not just the
  service), see disable_asus_updatechecker.bat.
- For a broader cleanup that reaches beyond ASUS, see
  disable-bloat-services.bat.
