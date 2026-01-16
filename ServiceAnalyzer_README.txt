================================================================================
 ServiceAnalyzer.bat - Instructions
================================================================================

DESCRIPTION
-----------
Analyzes Windows services to find unnecessary ones set to Automatic startup.
Identifies bloatware services, telemetry, and services that can be safely
changed to Manual or Disabled.


HOW TO USE
----------
1. Right-click ServiceAnalyzer.bat
2. Select "Run as administrator" (REQUIRED)
3. Wait for the analysis to complete
4. Review the categorized list
5. Choose which categories to disable when prompted:
   - Bloatware services? [Y/N]
   - Telemetry services? [Y/N]
   - Xbox services? [Y/N]


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Service Changes"
5. Click Create and wait for completion


WHAT EACH CATEGORY MEANS
------------------------

[ESSENTIAL] - Not shown, automatically skipped
  Core Windows services required for the OS to function.
  These are NEVER suggested for disabling.

[BLOATWARE] - Red
  Third-party services that often run unnecessarily:
  - Adobe updaters and "genuine" services
  - Google/Edge/Browser update services
  - Gaming platform services (Steam, Epic, Origin)
  - Third-party antivirus (Windows Defender is sufficient)
  - Vendor bloatware (ASUS, Dell, HP support services)
  - PUP services (IObit, Auslogics, etc.)

[TELEMETRY] - Magenta
  Microsoft data collection services:
  - DiagTrack (Connected User Experiences)
  - Windows Error Reporting
  - Diagnostics Hub
  - WAP Push Message Routing

[OPTIONAL] - Yellow
  Legitimate Windows services that many users don't need:
  - Fax Service
  - Remote Desktop (if not using RDP)
  - Hyper-V services (if not using VMs)
  - Smart Card services
  - Windows Insider Service
  - Peer networking services
  - AllJoyn (IoT) router

[XBOX] - Green
  Xbox gaming services:
  - Xbox Live Auth Manager
  - Xbox Live Game Save
  - Xbox Accessory Management
  - Xbox Live Networking
  Can be disabled if you don't use Xbox features on PC.

[UNKNOWN] - Cyan
  Services not in our database. Usually Windows or legitimate
  software services. Not suggested for disabling without research.


HOW TO RESTORE / UNDO
---------------------
Option 1: Re-enable Individual Services
  Open Command Prompt as Administrator and run:
    sc config "ServiceName" start= auto
    sc start "ServiceName"

  Example:
    sc config "DiagTrack" start= auto
    sc start "DiagTrack"

Option 2: Use services.msc
  1. Press Win+R, type "services.msc", press Enter
  2. Find the service in the list
  3. Double-click it
  4. Change "Startup type" to "Automatic"
  5. Click "Start" then "OK"

Option 3: System Restore
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your restore point
  3. Follow the wizard


SERVICES SAFE TO DISABLE
------------------------
Almost always safe:
  - DiagTrack (Telemetry)
  - dmwappushservice (Telemetry)
  - RetailDemo (Store demo mode)
  - Fax (unless you fax)
  - XblAuthManager, XblGameSave (unless Xbox gaming)
  - wisvc (Windows Insider - unless in program)

Safe if not using the feature:
  - TermService (Remote Desktop)
  - Spooler (Printing)
  - bthserv (Bluetooth)
  - lfsvc (Geolocation)
  - MapsBroker (Offline maps)
  - Hyper-V services (Virtual machines)

Third-party (usually safe):
  - Adobe update services
  - Google/Browser update services
  - Gaming platform services
  - Vendor support services


SERVICES TO BE CAREFUL WITH
---------------------------
Don't disable without understanding:
  - BITS - Used by Windows Update
  - Spooler - Needed for any printing
  - WSearch - Windows Search functionality
  - Themes - Desktop appearance
  - Any service you don't recognize

If in doubt:
  1. Set to "Manual" instead of "Disabled"
  2. Manual services start when needed
  3. This is safer than fully disabling


UNDERSTANDING SERVICE START TYPES
---------------------------------
Automatic: Starts with Windows boot
Automatic (Delayed): Starts shortly after boot
Manual: Starts when requested by a program
Disabled: Cannot start at all

Recommendation:
  - Change "Automatic" to "Manual" for services you might need
  - Only use "Disabled" for services you definitely don't need


TIPS
----
- Fewer automatic services = faster boot time
- Manual services still work, they just don't pre-load
- Some services are interdependent - disabling one may affect others
- Test changes before doing a clean install
- Use ProcessScanner.bat to see what's actually running
- Use StartupAnalyzer.bat for user-space startup programs


RELATED TOOLS
-------------
Built-in Windows tools:
  - services.msc - Service management console
  - msconfig - System Configuration (Services tab)
  - Task Manager - Services tab (basic view)

From this toolbox:
  - ProcessScanner.bat - Scan running processes
  - StartupAnalyzer.bat - Scan startup programs
  - WindowsTweaks.bat - Disable services via registry
