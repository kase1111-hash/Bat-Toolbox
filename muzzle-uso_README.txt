================================================================================
 muzzle-uso.bat - Instructions
================================================================================

DESCRIPTION
-----------
Keeps UsoSvc (Update Orchestrator Service) disabled across reboots. Windows
cumulative updates periodically re-enable UsoSvc and reset its start type;
this script installs a boot-triggered scheduled task that stops and re-disables
the service every time the machine starts, so the "muzzle" survives updates.

Unlike most scripts in this toolbox, this one takes COMMAND-LINE SWITCHES.


USAGE
-----
  muzzle-uso.bat            Install the boot task (and disable UsoSvc now)
  muzzle-uso.bat /u         Uninstall the boot task
  muzzle-uso.bat /uninstall (same as /u)
  muzzle-uso.bat /remove    (same as /u)
  muzzle-uso.bat /status    Show the task and current service state

All modes require Administrator. If you double-click the file with no
argument, it defaults to install.


HOW TO USE
----------
1. Right-click muzzle-uso.bat and choose "Run as administrator", OR open an
   elevated Command Prompt and run it with the switch you want.
2. Install mode:
     - stops UsoSvc and sets it to start= disabled immediately
     - creates the scheduled task "Muzzle-UsoSvc" (ONSTART, RU SYSTEM,
       RL HIGHEST) that re-applies the disable on every boot
3. Use /status any time to confirm the task exists and see the service state.


WHAT IT DOES
------------
- Task name: Muzzle-UsoSvc
- Trigger:   at system startup (/SC ONSTART)
- Runs as:   SYSTEM, elevated (/RU SYSTEM /RL HIGHEST)
- Action:    cmd.exe /c sc stop UsoSvc & sc config UsoSvc start= disabled

(The space after "start=" is required by sc.exe - do not remove it.)


BEFORE YOU RUN
--------------
- UsoSvc is part of the Windows Update pipeline. With it disabled, Windows
  Update scan/download/install orchestration will not run normally. This is
  intended if you are deliberately taking manual control of updates, but it
  does affect automatic updating.
- Microsoft may also re-enable WaaSMedicSvc (Update Medic), which can revert
  this. WaaSMedic is hardened against sc.exe; neutralizing it requires the
  registry-ownership approach used in kill-dosvc.bat - a separate exercise.


HOW TO RESTORE / UNDO
---------------------
Remove the boot task:
  muzzle-uso.bat /u

The service start type is NOT changed by the uninstall. Re-enable it manually:
  sc config UsoSvc start= demand
  sc start  UsoSvc


VERIFICATION
------------
  muzzle-uso.bat /status

or manually:
  schtasks /Query /TN "Muzzle-UsoSvc" /FO LIST
  sc qc UsoSvc | findstr START_TYPE     (DISABLED when muzzled)
  sc query UsoSvc | findstr STATE       (STOPPED when muzzled)


TIPS
----
- To fully suppress Delivery Optimization + the Update Medic reverter, pair
  this with kill-dosvc.bat.
- The boot task is what makes this durable; without it, the next cumulative
  update would silently turn UsoSvc back on.
