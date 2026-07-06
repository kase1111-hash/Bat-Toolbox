================================================================================
 kill-dosvc.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables Windows Delivery Optimization (DoSvc) - the peer-to-peer Windows
Update layer that can upload update files from your machine to other PCs on
the internet using your bandwidth. Crucially, it FIRST disables WaaSMedicSvc
(Windows Update Medic Service), which otherwise detects "tampered" update
components and silently reverts them - so without this ordering DoSvc would
come right back.

WaaSMedic's registry key is TrustedInstaller-protected, so the script
escalates ownership to Administrators before writing to it.


WHAT GETS TOUCHED
-----------------
  1) WaaSMedicSvc:              stop + Start=4 (Disabled), with ownership
                                escalation if the direct write is blocked
  2) DoSvc:                     stop + Start=4 (Disabled)
  3) DODownloadMode policy:     0 (HTTP only, no peering)
  4) WaaSMedic scheduled tasks: disabled
  5) HOSTS file:                null-routes common DO endpoints to 0.0.0.0
  6) Firewall:                  blocks svchost service=DoSvc + TCP 7680 in/out

Still works afterward: Windows Update (direct from Microsoft), Store updates
(slower), Defender signature updates.


HOW TO USE
----------
1. Right-click kill-dosvc.bat
2. Select "Run as administrator" (REQUIRED)
3. The script runs in phases (recon -> disable WaaSMedic -> disable DoSvc ->
   policy -> tasks -> hosts -> firewall -> verify) and prints results.
4. Reboot when done (recommended) to clear any in-flight DO transfers and
   prevent one last medic remediation pass.


BEFORE YOU RUN
--------------
- A hosts backup is created automatically at:
    %SystemRoot%\System32\drivers\etc\hosts.bak.dosvc
- Disabling WaaSMedicSvc means Windows will no longer auto-repair broken
  update components. That is the point here, but be aware of it - if Windows
  Update itself breaks later, re-enabling WaaSMedic is part of the fix.
- HOSTS entries cover only the most common static DO FQDNs. For comprehensive
  coverage use a real DNS sinkhole (Pi-hole, AdGuard Home, etc.).


HOW TO RESTORE / UNDO
---------------------
Run as Administrator:

  sc config DoSvc start= auto
  sc config WaaSMedicSvc start= demand
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /f
  netsh advfirewall firewall delete rule name="BLOCK DoSvc service"
  netsh advfirewall firewall delete rule name="BLOCK DO P2P port 7680 in"
  netsh advfirewall firewall delete rule name="BLOCK DO P2P port 7680 out"
  copy /Y "%SystemRoot%\System32\drivers\etc\hosts.bak.dosvc" "%SystemRoot%\System32\drivers\etc\hosts"

Re-enable any scheduled task that was disabled:
  schtasks /Change /TN "<task path>" /Enable

Then reboot.


VERIFICATION (after reboot)
---------------------------
  sc query DoSvc            (STATE: STOPPED)
  sc qc DoSvc               (START_TYPE: DISABLED)
  sc query WaaSMedicSvc     (STATE: STOPPED)
  sc qc WaaSMedicSvc        (START_TYPE: DISABLED)
  reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode


DODownloadMode VALUES (reference)
---------------------------------
  0   = HTTP only, no peering (what this script sets)
  1   = HTTP + LAN peering
  2   = HTTP + Group peering
  3   = HTTP + Internet peering (Windows default)
  100 = Bypass DO entirely, use BITS (can break Store)


TIPS
----
- Order matters: WaaSMedic must be disabled before DoSvc, or DoSvc reverts.
- A cumulative/feature update may re-enable these. Re-run if needed.
- If you only want to keep the Update Orchestrator quiet, see muzzle-uso.bat.
