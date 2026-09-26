================================================================================
 edge-disable.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables Microsoft Edge WITHOUT uninstalling it. It kills running Edge
processes, stops and disables the Edge update services, disables the Edge
update scheduled tasks, blocks auto-update via policy, turns off prelaunch /
startup boost / background mode, strips Edge auto-launch from the user Run
key, and OPTIONALLY renames msedge.exe so nothing can execute it. Fully
reversible.


HOW TO USE
----------
1. Double-click or right-click edge-disable.bat. It self-elevates: if not
   already admin it re-launches itself via "Start-Process -Verb RunAs" and
   you approve the UAC prompt.
2. Confirm with Y at the "Continue? (Y/N)" prompt; steps 1-5 then run (kill,
   services, tasks, policy, prelaunch). Save work in Edge and WebView2 apps
   (new Outlook, Teams) first - they are force-closed. N cancels with no
   changes made.
3. Step 6 is OPTIONAL and prompts: "Rename msedge.exe? (y/N)". This is the
   most aggressive step - it takes ownership of msedge.exe and renames it to
   msedge_disabled.exe so nothing (including Widgets or microsoft-edge://
   handlers) can launch it. Default is N.
4. Reboot when done (recommended).


WHAT IT DOES (step by step)
---------------------------
  [1/6] Kills msedge.exe, MicrosoftEdge.exe, msedgewebview2.exe,
        MicrosoftEdgeUpdate.exe.
  [2/6] sc stop + sc config start= disabled for "edgeupdate" and "edgeupdatem".
  [3/6] Disables MicrosoftEdgeUpdateTaskMachineCore and ...MachineUA tasks.
  [4/6] Policy: UpdateDefault=0, InstallDefault=0, AutoUpdateCheckPeriodMinutes=0
        under HKLM\...\Policies\Microsoft\EdgeUpdate.
  [5/6] StartupBoostEnabled=0, BackgroundModeEnabled=0, AllowPrelaunch=0,
        AllowTabPreloading=0; removes MicrosoftEdgeAutoLaunch* from HKCU Run.
  [6/6] OPTIONAL rename of msedge.exe (takeown + icacls + ren). On a re-run,
        a msedge_disabled.exe left by an earlier run is deleted first so the
        newer msedge.exe can be renamed; success is reported only if
        msedge.exe is really gone.


BEFORE YOU RUN
--------------
- WebView2 is used by many OTHER apps (Widgets, some Office/Teams surfaces,
  various third-party apps). This script kills msedgewebview2.exe once, and the
  rename step renames only msedge.exe, not the WebView2 runtime. HOWEVER, the
  WebView2 Runtime is updated by the same Microsoft Edge Update services, tasks
  and policies that steps 2-4 disable, so after running this script WebView2
  STOPS receiving security and feature updates. Apps that need a newer runtime
  may eventually refuse to start. Run the HOW TO RESTORE / UNDO commands
  periodically (or update the WebView2 Runtime manually) to keep it patched.
- If Edge is your default browser, set a different default browser FIRST, or
  you may have no working browser after the rename step.
- The rename step (step 6) is the only hard-to-notice change; skip it if you
  are unsure.


HOW TO RESTORE / UNDO
---------------------
Run as Administrator:

  sc config edgeupdate   start= demand
  sc config edgeupdatem  start= demand
  schtasks /Change /TN "MicrosoftEdgeUpdateTaskMachineCore" /Enable
  schtasks /Change /TN "MicrosoftEdgeUpdateTaskMachineUA"   /Enable
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge"       /f

If you ran step 6, rename the binary back:
  cd "C:\Program Files (x86)\Microsoft\Edge\Application"
  ren msedge_disabled.exe msedge.exe

Then reboot.


VERIFICATION
------------
  sc qc edgeupdate | findstr START_TYPE     (DISABLED)
  tasklist | findstr /i msedge              (no msedge.exe when idle)


TIPS
----
- Windows may re-enable Edge update components after a cumulative or feature
  update. Re-run this script if that happens.
- To reverse ONLY the rename without touching everything else, just rename
  msedge_disabled.exe back to msedge.exe.
