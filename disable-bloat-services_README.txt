================================================================================
 disable-bloat-services.bat - Instructions
================================================================================

DESCRIPTION
-----------
A two-tier service cleanup that extends beyond ASUS. It disables a set of
known-bloat services silently, then interactively asks about a hardware-
dependent service so you keep control over anything that might matter on your
machine. Changes are made at the Service Control Manager layer (sc config),
except for the per-user CDPUserSvc template, whose Start value is set directly
in the registry (see HOW TO RESTORE / UNDO); all changes are individually
reversible. Idempotent - safe to re-run.


TIER 1 - SILENT DISABLE (no prompt)
-----------------------------------
  - ASUS Software Manager
  - ASUS Switch
  - ASUS System Analysis
  - ASUS System Diagnosis
  - ASUS App Service
  - Connected Devices Platform Service (CDPSvc)
  - Connected Devices Platform User Service (CDPUserSvc)   - a per-user
        service: Windows creates a new CDPUserSvc_xxxxx instance (random
        suffix, e.g. "_7c5be") from the CDPUserSvc template at every
        sign-in. The script sets the TEMPLATE's Start value to 4 (Disabled) -
        disabling only the instance would not persist - and stops the one that
        is currently running. Takes full effect from the next sign-in.

TIER 2 - INTERACTIVE (asks y/n)
-------------------------------
  - Dolby DAX API Service   (only useful if you have Dolby Atmos hardware;
        the script shows its current state and any recent related process-
        history entries, then asks before touching it)

Intentionally EXCLUDED:
  - ASUS Optimization  (parent of AsusHotkey.exe / Fn-key handler)
  - Sync Host_7c5be    (left alone by design)


HOW TO USE
----------
1. Right-click disable-bloat-services.bat
2. Select "Run as administrator" (REQUIRED)
3. Tier 1 runs automatically. Each matching service is stopped and disabled.
4. Tier 2 pauses and asks "Disable this service? (y/n)" for Dolby. Answer n
   to keep it.
5. Review the summary (stopped / disabled / not-found / skipped counts).


WHAT IT DOES
------------
- Tier 1: for each entry it enumerates every service whose service name or
  display name matches (via PowerShell Get-Service), stops each if running,
  then runs "sc config <name> start= disabled". CDPSvc is looked up by its
  service name, because Windows' own display names are translated on
  non-English systems (the ASUS display names are not).
  For CDPUserSvc it writes
    HKLM\SYSTEM\CurrentControlSet\Services\CDPUserSvc  Start = 4 (DWORD)
  and stops any running CDPUserSvc_xxxxx instance ("sc config" cannot change
  a per-user instance, and the instance is recreated at each sign-in).
- Tier 2: shows the service state, binary path, and the last few process-
  history entries that reference the vendor tag (if the process-history log
  exists), then prompts before making any change.


BEFORE YOU RUN
--------------
- This reaches beyond ASUS (Connected Devices Platform, optionally Dolby).
  Read the Tier 1 list above and make sure none are ones you rely on.
- Connected Devices Platform Service supports "Nearby Sharing" and some
  cross-device features; if you use those, re-enable it afterward (see below).
- The Tier 2 process-history display only populates if you have installed the
  process-history logger (see install-process-history-logger.bat). Without it,
  Tier 2 still works - it just shows no recent-process context.


HOW TO RESTORE / UNDO
---------------------
Re-enable any service by its SHORT name (printed by the script):

  sc config "<ServiceName>" start= auto      (or start= demand)
  sc start  "<ServiceName>"

Common re-enables:
  sc config "CDPSvc" start= delayed-auto & sc start "CDPSvc"
      (Automatic - Delayed Start is the Windows default for CDPSvc)
  sc config "DolbyDAXAPI" start= demand & sc start "DolbyDAXAPI"

Connected Devices Platform User Service (per-user template):
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\CDPUserSvc" /v Start /t REG_DWORD /d 2 /f
  Then sign out and back in - a new CDPUserSvc_xxxxx instance is created
  and started at sign-in.


VERIFICATION
------------
  sc qc "<ServiceName>" | findstr START_TYPE   (DISABLED when off)
  sc query "<ServiceName>" | findstr STATE     (STOPPED when off)
  reg query "HKLM\SYSTEM\CurrentControlSet\Services\CDPUserSvc" /v Start
                                               (0x4 when the template is off)


TIPS
----
- ASUS Optimization is deliberately left running (Fn keys). Do not disable it
  unless you know you don't need hotkeys.
- If you only want the ASUS subset, use disable-asus-services.bat instead.
- The randomly-suffixed CDPUserSvc_xxxxx instance is handled through its
  CDPUserSvc template, so it stays disabled across sign-ins and reboots.
