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
5. Find the output file on your Desktop (the path is shown before the
   export starts)


OUTPUT FILE
-----------
Saved to Desktop as: WifiPasswords_COMPUTERNAME_DATE.txt
The script asks Windows for the real Desktop folder, so this is also correct
when OneDrive folder backup has moved the Desktop into OneDrive. If that
folder cannot be found, the file goes to your user folder (%USERPROFILE%).

Contains for each network:
  - Network name (SSID)
  - Password (plain text, exactly as stored - including ":" "!" "^" etc.)
  - Security type, as stored in the Wi-Fi profile (WPA2PSK, WPA3SAE,
    WPA2 = WPA2-Enterprise, open, ...)
  - Cipher (AES, TKIP, WEP, none)
  - Auto-connect setting (auto / manual)

Sample output:
  Network:    HomeWifi
  Password:   MySecretPassword123
  Security:   WPA2PSK
  Cipher:     AES
  Auto-connect: auto

Networks without a readable password are labelled instead of being listed
as open networks:
  (none - open network)                    - no security at all
  (not available - run as administrator
   to reveal it)                           - secured, but Windows only
                                             reveals the key when elevated
  (not available - 802.1X/Enterprise
   network, no stored password)            - enterprise/802.1X network
The summary counts these separately ("Key not available").


SECURITY WARNING
----------------
*** THE OUTPUT FILE CONTAINS PLAIN TEXT PASSWORDS ***

- Delete the file after transferring passwords to a password manager
- Do not email or share the file
- Do not upload it to cloud storage
- Store on an encrypted USB drive if you need to keep it


ADMIN REQUIREMENTS
------------------
- Without admin: Shows network names, but passwords of secured networks
  are hidden
- With admin: Full access to all stored passwords

The script works without admin, but Windows then exports the keys
encrypted, so secured networks show "(not available - run as administrator
to reveal it)" instead of the password.


WHEN TO USE
-----------
- Before a clean Windows install
- Setting up a new laptop or device
- Documenting network credentials for a household
- Recovering a forgotten Wi-Fi password
- IT inventory of known wireless networks


HOW IT WORKS
------------
Uses built-in Windows tools:
  netsh wlan export profile key=clear folder=<temp folder>
      - Exports every saved profile as an XML file (the same format on
        every Windows display language)
  PowerShell (built in)
      - Reads the XML files and writes the network name, password,
        security, cipher and auto-connect setting to the output file

The XML files are written to a private folder in %TEMP% and deleted as
soon as they have been read. If the script is interrupted while it runs,
delete any leftover %TEMP%\wlan_export_* folder - it contains passwords.

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
- Enterprise WPA2 networks (802.1X) have no stored password; they are
  listed as "not available - 802.1X/Enterprise network"
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
