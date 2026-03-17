================================================================================
 HardenPrintSpooler.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables or hardens the Windows Print Spooler service to mitigate
PrintNightmare (CVE-2021-1675 / CVE-2021-34527) and related spooler
privilege escalation and remote code execution vulnerabilities.

The Print Spooler runs as SYSTEM and has been the target of multiple
critical CVEs. This script offers two modes:

  Option 1: Disable completely
    Stops and disables the Print Spooler service entirely. Best for
    machines that never print (servers, VMs, development boxes).

  Option 2: Harden only
    Keeps local printing functional but restricts dangerous features:
    Point and Print driver installs, web-based printing, and remote
    driver downloads.

Both options apply registry hardening as defense-in-depth.


HOW TO USE
----------
1. Right-click HardenPrintSpooler.bat
2. Select "Run as administrator" (REQUIRED)
3. Review the current spooler status
4. Choose Option 1 (disable) or Option 2 (harden)
5. No reboot required (takes effect immediately)


WHAT IT DOES
------------
Registry hardening (applied by both options):

  Point and Print restrictions:
    NoWarningNoElevationOnInstall = 0  (require UAC for driver install)
    UpdatePromptSettings = 0           (show warning on driver update)
    RestrictDriverInstallationToAdministrators = 1

  Web/HTTP printing:
    DisableWebPnPDownload = 1          (block internet driver download)
    DisableHTTPPrinting = 1            (block IPP/HTTP printing)

  RPC security:
    RpcAuthnLevelPrivacyEnabled = 1    (require encrypted RPC)

Option 1 additionally:
  - Stops the Spooler service
  - Sets start type to Disabled

Option 2 additionally:
  - Sets start type to Manual (starts only when needed)


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Harden Print Spooler"
5. Click Create and wait for completion

Also check:
- Do you print from this machine? If no, use Option 1 (disable).
- Do you need to install new print drivers? Admin credentials will be
  required after hardening (this is intentional).


WHEN TO USE THIS SCRIPT
-----------------------
- On any machine that doesn't print (servers, VMs, dev boxes)
- After a security audit flags PrintNightmare vulnerabilities
- Compliance with CIS benchmarks or STIG requirements
- Hardening workstations in high-security environments
- When you need to print but want to restrict the attack surface


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select "Before Harden Print Spooler" restore point
  3. Follow the wizard to restore

Option 2: Manual Reversal
  Run these commands as Administrator:

  Step 1 - Re-enable Print Spooler:
    sc config Spooler start= auto
    sc start Spooler

  Step 2 - Remove Point and Print restrictions:
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /f

  Step 3 - Re-enable web/HTTP printing:
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v DisableWebPnPDownload /f
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v DisableHTTPPrinting /f

  Step 4 - Remove RPC hardening:
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /f


VERIFICATION
------------
After running the script:

  1. Check spooler status:
     sc query Spooler
     (State should be STOPPED if disabled, or RUNNING only when printing)

  2. Check Point and Print:
     reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
     (NoWarningNoElevationOnInstall should be 0x0)

  3. Test printing (Option 2 only):
     Print a test page from any application. It should still work for
     already-installed printers.


TIPS
----
- This script is safe to run multiple times (idempotent)
- Option 2 does NOT break existing printer connections
- New printer driver installs will require admin credentials (by design)
- If a future Windows update re-enables the spooler, re-run this script
- For print servers, use Option 2 only (Option 1 breaks print serving)
