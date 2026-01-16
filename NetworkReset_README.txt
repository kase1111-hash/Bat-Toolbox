================================================================================
 NetworkReset.bat - Instructions
================================================================================

DESCRIPTION
-----------
Performs a complete network stack reset to fix connectivity issues.
Resets IP, DNS, Winsock, TCP/IP, and cycles the network adapter.


HOW TO USE
----------
1. Right-click NetworkReset.bat
2. Select "Run as administrator" (REQUIRED)
3. Wait for each step to complete
4. Restart your computer when finished

The script performs these steps in order:
  1. Releases current IP address
  2. Flushes DNS cache
  3. Clears ARP cache
  4. Resets Winsock catalog
  5. Resets TCP/IP stack
  6. Disables network adapter (5 second wait)
  7. Re-enables network adapter (5 second wait)
  8. Renews IP address
  9. Displays new IP configuration


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Network Reset"
5. Click Create and wait for completion

Also note:
- You will temporarily lose internet connection during the reset
- Close any programs that require internet
- Download any needed files before running


WHEN TO USE THIS SCRIPT
-----------------------
- Internet connection is unstable or not working
- DNS resolution problems ("DNS_PROBE_FINISHED_NXDOMAIN")
- "No Internet" despite being connected to WiFi/Ethernet
- After removing malware
- VPN connection issues
- Network-related error messages
- "Limited connectivity" or "Unidentified network"


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select "Before Network Reset" restore point
  3. Follow the wizard to restore

Option 2: Manual Reversal
  Most settings are auto-configured by Windows/DHCP after reset.
  If you had static IP settings, you'll need to reconfigure them:

  1. Open Control Panel > Network and Sharing Center
  2. Click your connection > Properties
  3. Select "Internet Protocol Version 4 (TCP/IPv4)"
  4. Click Properties
  5. Re-enter your static IP, subnet mask, gateway, and DNS

Option 3: Reset Network Settings via Windows
  1. Open Settings > Network & Internet
  2. Click "Network reset" at the bottom
  3. Click "Reset now"


IF INTERNET STILL DOESN'T WORK
------------------------------
1. Restart your router/modem (unplug for 30 seconds)
2. Check physical cable connections
3. Try a different DNS server:
   - Open Command Prompt as Administrator
   - Run: netsh interface ip set dns "Ethernet" static 8.8.8.8
   - (Replace "Ethernet" with your connection name)
4. Update network adapter drivers
5. Contact your ISP


TIPS
----
- This script fixes most common network issues
- If problems persist, the issue may be hardware or ISP-related
- Keep a copy of your static IP settings if you use them
- Run this script before calling tech support
