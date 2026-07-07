================================================================================
 remove_defender.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables Windows Defender (Microsoft Defender Antivirus) as fully as possible
using readable, auditable registry and service edits. It turns off real-time
protection, cloud/sample submission, Exploit Guard, Network Protection,
Controlled Folder Access, and SmartScreen; disables the Defender services and
scheduled tasks; removes the Security tray icon; and cleans up scan history
and cached data.

*** SECURITY WARNING ***
This removes your machine's built-in antivirus. Only do this if you fully
understand the risk and have a deliberate reason (e.g. you run a different AV,
or an isolated/offline machine). Leaving a networked Windows machine with no
antivirus is dangerous.


REQUIRED MANUAL STEP FIRST
--------------------------
Before running, you MUST turn OFF Tamper Protection by hand - no script can do
this, Windows requires a GUI action:

  Settings > Windows Security > Virus & Threat Protection >
  Manage Settings > toggle OFF "Tamper Protection"

If Tamper Protection is left ON, most of this script's changes will be
reverted by Windows automatically.


HOW TO USE
----------
1. Turn off Tamper Protection (above).
2. Right-click remove_defender.bat and choose "Run as administrator".
3. It prints a warning and pauses. Press Ctrl+C to abort, or a key to proceed.
4. It runs 8 phases (policies -> real-time/cloud -> Exploit Guard ->
   SmartScreen -> services -> tasks -> tray icon/notifications -> cleanup).
5. REBOOT for changes to take effect.


WHAT IT DOES (summary)
----------------------
  [1/8] DisableAntiSpyware / DisableAntiVirus / ServiceKeepAlive policies
  [2/8] Disables real-time monitoring, behavior monitoring, on-access, IOAV;
        turns off SpyNet reporting and sample submission
  [3/8] Disables Network Protection and Controlled Folder Access
  [4/8] Disables SmartScreen (Explorer, Edge, Store apps)
  [5/8] Sets Start=4 on: WinDefend, WdNisSvc, WdFilter, WdBoot, WdNisDrv,
        SecurityHealthService, wscsvc, SgrmBroker, Sense
  [6/8] Disables Defender + ExploitGuard scheduled tasks
  [7/8] Removes SecurityHealth Run entry; disables Security Center notifications
  [8/8] Deletes scan history, engine db, and definition-updates cache


BEFORE YOU RUN
--------------
- Confirm Tamper Protection is OFF (required).
- Make sure you have an alternative security plan (another AV, network
  isolation, disciplined browsing) before removing Defender.
- Microsoft may restore Defender via feature updates; you may need to re-run.


HOW TO RESTORE / UNDO
---------------------
1. Delete the policy keys:
     reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /f
     reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center" /f
2. Set the disabled services back to their defaults (most are 2=Auto or
   3=Manual; e.g. WinDefend is normally 2):
     reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v Start /t REG_DWORD /d 2 /f
   Repeat for each service the script disabled (WdNisSvc, WdFilter, WdBoot,
   WdNisDrv, SecurityHealthService, wscsvc, SgrmBroker, Sense).
3. Re-enable Tamper Protection in Windows Security.
4. Run Windows Update, then reboot. Defender should come back.


VERIFICATION
------------
After reboot:
  - Task Manager: no MsMpEng.exe running
  - services.msc: WinDefend shows Disabled
  - sc query WinDefend


TIPS
----
- The script mentions an OPTIONAL "nuclear" DISM removal
  (DISM /Online /Remove-Feature /FeatureName:Windows-Defender). It is NOT run
  automatically; it only works on some editions and is harder to reverse.
- If nothing seems to change after running, Tamper Protection was almost
  certainly still on - turn it off and re-run.
