================================================================================
 OpenPortScanner.bat - Instructions
================================================================================

DESCRIPTION
-----------
Scans all listening TCP and UDP ports on your system, resolves PIDs to process
names, flags known-suspicious ports, and highlights unexpected services
listening on 0.0.0.0 (all interfaces). Also checks firewall status, remote
access services, and established connections. A lightweight local audit
without installing Nmap or other third-party tools.


HOW TO USE
----------
1. Right-click OpenPortScanner.bat
2. Select "Run as administrator" (RECOMMENDED)
3. Confirm when prompted (Y/N)
4. Review the output on screen
5. Check the report saved to your Desktop


BEFORE YOU RUN
--------------
No system changes are made. This is a read-only audit tool.
Can be run without admin, but some process names may show as "Unknown".


WHAT IT SCANS
-------------
Phase 1: Listening Ports
  - All TCP ports in LISTEN state
  - All UDP endpoints
  - Resolves each PID to its process name
  - Flags known-suspicious ports (malware, backdoors, insecure services)
  - Highlights wildcard listeners (0.0.0.0 / ::)

Phase 2: Firewall Status
  - Domain profile (corporate networks)
  - Standard/Private profile (home networks)
  - Public profile (untrusted networks)

Phase 3: Remote Access
  - Remote Desktop (RDP) on port 3389
  - OpenSSH Server on port 22
  - WinRM (remote PowerShell) on port 5985/5986
  - Telnet Server on port 23

Phase 4: Established Connections
  - All active outbound TCP connections
  - Process name for each connection


PORT STATUS MEANINGS
--------------------
OK           - Normal, expected port for the associated process
SUSPICIOUS   - Port commonly associated with malware or insecure services
HIGH RISK    - Port strongly associated with known trojans/backdoors
WILDCARD     - Service listening on all network interfaces (0.0.0.0)


KNOWN SUSPICIOUS PORTS FLAGGED
------------------------------
| Port  | Association                    |
|-------|--------------------------------|
| 23    | Telnet (insecure, plaintext)   |
| 1234  | Common backdoor                |
| 1337  | Common backdoor ("leet")       |
| 4444  | Metasploit/Meterpreter default |
| 4445  | Metasploit alternate           |
| 5555  | Android ADB / potential backdoor|
| 6666  | IRC backdoor                   |
| 6667  | IRC C2 channel                 |
| 12345 | NetBus trojan                  |
| 27374 | SubSeven trojan                |
| 31337 | Back Orifice                   |
| 3127  | MyDoom worm                    |

Also flags database/service ports if unexpectedly exposed:
  1433 (SQL Server), 3306 (MySQL), 5432 (PostgreSQL),
  27017 (MongoDB), 6379 (Redis), 9200 (Elasticsearch),
  2375 (Docker API unencrypted)


OUTPUT
------
Creates: PortScan_COMPUTERNAME_DATE.txt on Desktop

Contains:
  - Full listing of all listening TCP/UDP ports
  - Firewall profile status
  - Remote access service status
  - Established connections list
  - Summary with port counts and risk assessment


WHAT TO DO IF SUSPICIOUS PORTS ARE FOUND
-----------------------------------------
1. Note the process name and PID associated with the port
2. Open Task Manager (Ctrl+Shift+Esc) > Details tab
3. Find the PID and check the executable path
4. Right-click > Open file location to inspect the file
5. Search the executable name online for known malware associations
6. If confirmed malicious:
   a. Disconnect from the network immediately
   b. Run a full Windows Defender scan
   c. Consider using Malwarebytes for a second opinion
   d. Check startup entries with StartupAnalyzer.bat


WHAT TO DO ABOUT WILDCARD LISTENERS
------------------------------------
Services on 0.0.0.0 accept connections from any network interface, including
external networks. This is normal for:
  - Windows system services (RPC, SMB)
  - Web servers you intentionally run
  - Database servers for development

But investigate if you see unexpected processes on 0.0.0.0, especially on
low-numbered ports you don't recognize.


NOTES
-----
- This is a read-only tool. No system changes are made.
- Run periodically to check for new unexpected listeners
- Run after installing new software to see what ports it opens
- Pairs well with ProcessScanner.bat and ServiceAnalyzer.bat
- For network-wide scanning, consider Nmap (https://nmap.org)
- Windows Firewall blocks most inbound connections by default,
  but a listening port on 0.0.0.0 is still a potential risk


TIPS
----
- Run as admin for complete process name resolution
- Check the report after installing new software
- If a port is flagged but belongs to a known program, it's likely safe
- Database ports (MySQL, PostgreSQL, etc.) are normal on dev machines
- RDP should be disabled if you don't use remote access
- Keep Windows Firewall enabled on ALL profiles
