================================================================================
 DisableUPnP.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables UPnP (Universal Plug and Play) and SSDP Discovery to prevent
applications from automatically opening firewall ports without user consent.

UPnP allows any local application to instruct your router to forward
external ports to your machine. This means malware, a compromised browser
plugin, or any application can silently expose services to the internet.

SSDP (Simple Service Discovery Protocol) is the discovery layer that
broadcasts on UDP 1900 to find UPnP devices on the network.

This script also disables Function Discovery services which provide
network device discovery on the local subnet.


HOW TO USE
----------
1. Right-click DisableUPnP.bat
2. Select "Run as administrator" (REQUIRED)
3. Review the current service status
4. Confirm with Y to proceed
5. No reboot required (takes effect immediately)


WHAT IT DOES
------------
Services disabled:
  1. SSDP Discovery (SSDPSRV)
     - Discovers networked devices using SSDP protocol
     - Broadcasts on UDP 1900

  2. UPnP Device Host (upnphost)
     - Allows UPnP devices to be hosted on this computer
     - Processes port-forwarding requests

  3. Function Discovery Provider Host (fdPHost)
     - Provides network device discovery

  4. Function Discovery Resource Publication (FDResPub)
     - Publishes this computer on the network for discovery

Firewall rules added:
  - Block SSDP (UDP 1900) inbound
  - Block SSDP (UDP 1900) outbound


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Disable UPnP"
5. Click Create and wait for completion

Also check:
- Do you use applications that require UPnP port forwarding?
  (Some games, BitTorrent clients, and VoIP apps use UPnP)
- These applications will still work but may need manual port
  forwarding configured in your router's admin panel instead.


WHEN TO USE THIS SCRIPT
-----------------------
- Hardening a workstation to prevent silent port exposure
- After discovering unexpected open ports from a port scan
- Compliance with security baselines that require UPnP disabled
- Environments where you control router port forwarding manually
- Reducing attack surface on machines connected to untrusted networks


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select "Before Disable UPnP" restore point
  3. Follow the wizard to restore

Option 2: Manual Reversal
  Run these commands as Administrator:

  Step 1 - Re-enable services:
    sc config SSDPSRV start= demand
    sc config upnphost start= demand
    sc config fdPHost start= demand
    sc config FDResPub start= demand
    sc start SSDPSRV
    sc start upnphost

  Step 2 - Remove firewall rules:
    netsh advfirewall firewall delete rule name="Block SSDP (UDP 1900)"
    netsh advfirewall firewall delete rule name="Block SSDP outbound (UDP 1900)"


WHAT STILL WORKS AFTER DISABLING
---------------------------------
  - Normal internet browsing
  - File sharing (SMB/CIFS)
  - Printers added manually by IP address
  - All applications that don't rely on UPnP auto-port-forwarding
  - Chromecast/smart TV casting (uses mDNS, not UPnP)

WHAT MAY NEED MANUAL PORT FORWARDING
-------------------------------------
  - Online gaming (if NAT type becomes "Strict")
  - BitTorrent clients (incoming connections)
  - VoIP applications
  - Self-hosted game servers

To manually port forward:
  1. Log into your router admin panel (usually 192.168.1.1)
  2. Find Port Forwarding or NAT settings
  3. Add a rule for the specific port and your machine's local IP
  4. This is more secure than UPnP because you control exactly
     which ports are open


VERIFICATION
------------
After running the script:

  1. Check services are disabled:
     sc query SSDPSRV
     sc query upnphost
     (Both should show STATE: STOPPED)

  2. Check no SSDP traffic:
     netstat -an | findstr "1900"
     (Should return no results)

  3. Check firewall rules:
     netsh advfirewall firewall show rule name=all | findstr "SSDP"


TIPS
----
- This script is safe to run multiple times (idempotent)
- If a game reports "NAT Type: Strict" after running this, add a manual
  port forward in your router for that game's specific ports
- Most modern applications handle NAT traversal without UPnP (using STUN/TURN)
- Disabling UPnP on your router's admin panel is also recommended as a
  complementary step (this script only disables the Windows client side)
