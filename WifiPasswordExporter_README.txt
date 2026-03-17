================================================================================
 WifiPasswordExporter.bat - Instructions
================================================================================

DESCRIPTION
-----------
Exports all saved Wi-Fi network names and passwords to a plain text file.
Shows security type, cipher, and auto-connect settings for each network.
Essential before reinstalling Windows or setting up a new device.


HOW TO USE
----------
1. Right-click WifiPasswordExporter.bat
2. Select "Run as administrator" (recommended for full access)
3. Confirm when prompted
4. Review the exported list
5. Find the output file on your Desktop


OUTPUT FILE
-----------
Saved to Desktop as: WifiPasswords_COMPUTERNAME_DATE.txt

Contains for each network:
  - Network name (SSID)
  - Password (plain text)
  - Security type (WPA2-Personal, WPA3, etc.)
  - Cipher (CCMP, TKIP, etc.)
  - Auto-connect setting

Sample output:
  Network:    HomeWifi
  Password:   MySecretPassword123
  Security:   WPA2-Personal
  Cipher:     CCMP
  Auto-connect: Connect automatically


SECURITY WARNING
----------------
*** THE OUTPUT FILE CONTAINS PLAIN TEXT PASSWORDS ***

- Delete the file after transferring passwords to a password manager
- Do not email or share the file
- Do not upload it to cloud storage
- Store on an encrypted USB drive if you need to keep it


ADMIN REQUIREMENTS
------------------
- Without admin: Shows network names but some passwords may be hidden
- With admin: Full access to all stored passwords

The script works without admin but may show "(none)" for some
passwords that are only accessible with elevated privileges.


WHEN TO USE
-----------
- Before a clean Windows install
- Setting up a new laptop or device
- Documenting network credentials for a household
- Recovering a forgotten Wi-Fi password
- IT inventory of known wireless networks


HOW IT WORKS
------------
Uses built-in Windows commands:
  netsh wlan show profiles          - Lists all saved networks
  netsh wlan show profile key=clear - Shows password for each network

No external tools or software required.


HOW TO RESTORE / UNDO
---------------------
This script is read-only - it does not modify any settings.
It only reads and exports existing Wi-Fi profiles.

To delete saved Wi-Fi profiles (separate action):
  netsh wlan delete profile name="NetworkName"

To re-add a Wi-Fi profile manually:
  Go to Settings > Network & Internet > Wi-Fi > Manage known networks


MANUAL ALTERNATIVES
-------------------
To view a single network's password:
  netsh wlan show profile name="YourNetwork" key=clear

To list all saved networks:
  netsh wlan show profiles

To export a profile to XML (includes password):
  netsh wlan export profile name="YourNetwork" key=clear folder=C:\Backup


TIPS
----
- Pair with ExportInstalledPrograms.bat before a clean install
- Pair with FirmwareCheck.bat to save driver info too
- Wi-Fi passwords are stored per-user and per-system
- Enterprise WPA2 networks (802.1X) won't show passwords here
- Passwords are stored by Windows in the WLAN profile store
- The script handles multi-word network names correctly


RELATED TOOLS
-------------
Built-in Windows tools:
  - Settings > Network & Internet > Wi-Fi > Known networks
  - netsh wlan - Full Wi-Fi command-line management

From this toolbox:
  - ExportInstalledPrograms.bat - Export installed software list
  - FirmwareCheck.bat - Export driver/firmware versions
  - NetworkReset.bat - Reset network if having connection issues
