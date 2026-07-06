================================================================================
 inventory-asus-staging.bat - Instructions
================================================================================

DESCRIPTION
-----------
A READ-ONLY inventory tool. It makes NO changes to your system. For three
"observe before deciding" services it prints the service state, startup type,
binary path, and current PID, plus the most recent process-history entries
that reference the matching vendor. Use it to decide - per service - whether
to disable, tripwire, or leave alone.

Services inspected:
  - ASUS App Service
  - ASUS Optimization
  - Microsoft Edge Elevation Service


HOW TO USE
----------
1. Right-click inventory-asus-staging.bat
2. Select "Run as administrator" (REQUIRED - needed to query service config
   and read the process-history log)
3. Read the per-service report and the decision guide printed at the end.

Nothing is changed. You can run this as often as you like.


WHAT IT SHOWS (per service)
---------------------------
  - Service short name (resolved from the display name)
  - State (RUNNING / STOPPED / ...)
  - Startup type (AUTO / DEMAND / DISABLED)
  - Binary path
  - Current PID and state (or "not running")
  - Last 20 process-history entries whose path matches the vendor tag
    (asus / edge), if the process-history log exists


DECISION GUIDE (printed by the script)
--------------------------------------
  Running, no descendants   -> candidate for direct disable
  Running, vendor children  -> candidate for tripwire (add its binaries to
                               your tripwire installer's target list)
  Running, hardware ties    -> leave alone (Fn keys, fan curves, RGB, etc.)


BEFORE YOU RUN
--------------
- This is diagnostic only; there is nothing to undo.
- The recent-process section only has data if the SYSTEM process logger is
  installed (see install-process-history-logger.bat). Without it, the service
  details still print - only the recent-process analysis will be empty, and
  the script warns you of this up front.


VERIFICATION
------------
Not applicable - the script only reads and reports.


TIPS
----
- Run this FIRST, before disable-asus-services.bat or
  disable-bloat-services.bat, to confirm what each service is doing on your
  particular machine.
- ASUS Optimization typically shows a hardware tie (it parents the Fn-key
  handler) and should usually be left alone.
- Pair with install-process-history-logger.bat to get the recent-process
  context populated.
