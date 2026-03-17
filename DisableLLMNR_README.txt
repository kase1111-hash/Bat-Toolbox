================================================================================
 DisableLLMNR.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables three name-resolution protocols that are commonly exploited for
man-in-the-middle attacks on local networks:

  LLMNR (Link-Local Multicast Name Resolution) - UDP 5355
    When DNS fails, Windows broadcasts "who has this name?" to the local
    subnet. Any machine can reply, allowing attackers to capture NTLMv2
    hashes or redirect traffic. Tools like Responder exploit this trivially.

  mDNS (Multicast DNS) - UDP 5353
    Similar to LLMNR but uses the mDNS protocol (same as Apple Bonjour).
    Can be spoofed for the same credential-capture attacks.

  WPAD (Web Proxy Auto-Discovery)
    Windows queries for a proxy configuration at "wpad.<domain>". An
    attacker who responds first can intercept all HTTP traffic through
    a rogue proxy server.

Standard DNS resolution is NOT affected by this script.


HOW TO USE
----------
1. Right-click DisableLLMNR.bat
2. Select "Run as administrator" (REQUIRED)
3. Review the current status shown for each protocol
4. Confirm with Y to proceed
5. Reboot when convenient for full effect


WHAT IT DOES
------------
The script performs five steps:

  1. Disables LLMNR via Group Policy registry key:
     HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient
     EnableMulticast = 0

  2. Disables mDNS via DNS Client parameters:
     HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters
     EnableMDNS = 0

  3. Disables WPAD via multiple registry keys:
     - HKCU WpadOverride = 1
     - HKLM WinHttp DisableWpad = 1
     - HKCU AutoDetect = 0 (disables "Automatically detect settings")
     - Disables WinHTTP Auto-Proxy Discovery service

  4. Adds firewall rules blocking both inbound and outbound:
     - UDP 5355 (LLMNR)
     - UDP 5353 (mDNS)


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Disable LLMNR"
5. Click Create and wait for completion

Also check:
- Do you use Bonjour (iTunes, AirPlay) or Chromecast device discovery?
- Does your organization use WPAD for proxy auto-configuration?
- Do you rely on .local hostname resolution?

If you answered YES to any of the above, some features may stop working.
Standard DNS and internet browsing are NOT affected.


WHEN TO USE THIS SCRIPT
-----------------------
- Hardening a workstation on a network with untrusted devices
- After a penetration test found LLMNR/WPAD poisoning vulnerabilities
- Compliance with CIS benchmarks or STIG requirements
- Preventing Responder/mitm6-style attacks on your machine
- Any environment where DNS is the primary name resolution method


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select "Before Disable LLMNR" restore point
  3. Follow the wizard to restore

Option 2: Manual Reversal
  Run these commands as Administrator:

  Step 1 - Re-enable LLMNR:
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /f

  Step 2 - Re-enable mDNS:
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableMDNS /f

  Step 3 - Re-enable WPAD:
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" /v WpadOverride /f
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v DisableWpad /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 1 /f
    sc config WinHttpAutoProxySvc start= demand

  Step 4 - Remove firewall rules:
    netsh advfirewall firewall delete rule name="Block LLMNR (UDP 5355)"
    netsh advfirewall firewall delete rule name="Block LLMNR outbound (UDP 5355)"
    netsh advfirewall firewall delete rule name="Block mDNS (UDP 5353)"
    netsh advfirewall firewall delete rule name="Block mDNS outbound (UDP 5353)"

  Step 5 - Reboot


VERIFICATION
------------
After running the script and rebooting:

  1. Check LLMNR is disabled:
     reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast
     (Should show 0x0)

  2. Check mDNS is disabled:
     reg query "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableMDNS
     (Should show 0x0)

  3. Verify no LLMNR/mDNS traffic:
     netstat -an | findstr "5353 5355"
     (Should return no results)

  4. Check firewall rules:
     netsh advfirewall firewall show rule name=all | findstr /i "LLMNR mDNS"


TIPS
----
- This script is safe to run multiple times (idempotent)
- Standard DNS, DHCP, and internet browsing are NOT affected
- If Chromecast or AirPlay discovery stops working, re-enable mDNS only:
  reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableMDNS /f
- Corporate environments often disable these via Group Policy already;
  this script achieves the same result locally
