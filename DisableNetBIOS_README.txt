================================================================================
 DisableNetBIOS.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables NetBIOS over TCP/IP on all network adapters to close ports 137
(NetBIOS Name Service), 138 (NetBIOS Datagram), and 139 (NetBIOS Session).

NetBIOS is a legacy protocol originally used for file sharing and printer
discovery on local networks. Modern Windows uses DNS and SMB directly over
TCP port 445, making NetBIOS unnecessary in most environments. Disabling it
reduces attack surface by closing three ports per adapter.


HOW TO USE
----------
1. Right-click DisableNetBIOS.bat
2. Select "Run as administrator" (REQUIRED)
3. Review the current NetBIOS status shown for each adapter
4. Confirm with Y to proceed
5. Reboot when convenient for full effect


WHAT IT DOES
------------
The script performs four steps:

  1. Per-adapter disable: Sets TcpipNetbiosOptions to 2 (Disabled) on every
     IP-enabled adapter via WMI.

  2. NetBT driver: Sets the NetBIOS over TCP/IP transport driver to disabled
     and stops it if running.

  3. lmhosts service: Sets the TCP/IP NetBIOS Helper service to disabled
     and stops it if running.

  4. Firewall rules: Adds three inbound block rules:
     - Block NetBIOS-NS (UDP 137)
     - Block NetBIOS-DGM (UDP 138)
     - Block NetBIOS-SSN (TCP 139)


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Disable NetBIOS"
5. Click Create and wait for completion

Also check:
- Do you access shared folders by hostname (e.g., \\OLDSERVER)?
- Do you use WINS-based printer discovery?
- Do you have very old applications that rely on NetBIOS name resolution?

If you answered YES to any of the above, do NOT disable NetBIOS.


WHEN TO USE THIS SCRIPT
-----------------------
- After a port scan reveals 137/138/139 are open
- Hardening a workstation or server that doesn't use legacy file sharing
- Reducing attack surface on networks with untrusted devices
- Compliance with security baselines (CIS, STIG) that recommend
  disabling NetBIOS


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select "Before Disable NetBIOS" restore point
  3. Follow the wizard to restore

Option 2: Manual Reversal
  Run these commands as Administrator:

  Step 1 - Re-enable NetBIOS on adapters (PowerShell):
    Get-WmiObject Win32_NetworkAdapterConfiguration | Where {$_.IPEnabled} | ForEach { $_.SetTcpipNetbios(0) }

  Step 2 - Re-enable services (Command Prompt):
    sc config NetBT start= system
    sc config lmhosts start= auto
    sc start lmhosts

  Step 3 - Remove firewall rules (Command Prompt):
    netsh advfirewall firewall delete rule name="Block NetBIOS-NS (UDP 137)"
    netsh advfirewall firewall delete rule name="Block NetBIOS-DGM (UDP 138)"
    netsh advfirewall firewall delete rule name="Block NetBIOS-SSN (TCP 139)"

  Step 4 - Reboot


VERIFICATION
------------
After running the script and rebooting, verify with:

  1. Check adapter setting (PowerShell):
     Get-WmiObject Win32_NetworkAdapterConfiguration | Where {$_.IPEnabled} | Select Description, TcpipNetbiosOptions
     (Value 2 = Disabled)

  2. Check ports are closed:
     netstat -an | findstr "137 138 139"
     (Should return no results)

  3. Check firewall rules:
     netsh advfirewall firewall show rule name=all | findstr "NetBIOS"


TIPS
----
- A reboot is recommended after running for the driver changes to take full
  effect
- This script is safe to run multiple times (idempotent)
- SMB file sharing over TCP 445 is NOT affected by this script
- If you later add a new network adapter, re-run this script to disable
  NetBIOS on the new adapter
