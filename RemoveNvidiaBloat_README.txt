================================================================================
 RemoveNvidiaBloat.bat - Instructions
================================================================================

DESCRIPTION
-----------
Removes NVIDIA bloatware (GeForce Experience, telemetry, background services)
while keeping the essential graphics driver intact.


HOW TO USE
----------
1. Right-click RemoveNvidiaBloat.bat
2. Select "Run as administrator" (REQUIRED)
3. Confirm when prompted (Y/N)
4. Wait for all phases to complete
5. Restart when prompted (recommended)


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before NVIDIA Bloat Removal"
5. Click Create and wait for completion


WHAT GETS REMOVED
-----------------
- GeForce Experience (game optimization/recording app)
- NVIDIA Telemetry (data collection services)
- NVIDIA Container services
- NvNode / NvBackend (NodeJS server and backend)
- NVIDIA Web Helper (browser integration)
- All NVIDIA scheduled tasks
- Startup entries

WHAT STAYS INTACT
-----------------
- NVIDIA graphics driver (core functionality)
- NVIDIA Control Panel
- Display/rendering capabilities
- Your games will still work normally


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your "Before NVIDIA Bloat Removal" restore point
  3. Follow the wizard to restore

Option 2: Reinstall GeForce Experience
  1. Download GeForce Experience from:
     https://www.nvidia.com/en-us/geforce/geforce-experience/
  2. Run the installer
  3. This will reinstall all removed components

Option 3: Reinstall Full NVIDIA Driver Package
  1. Download the latest driver from:
     https://www.nvidia.com/Download/index.aspx
  2. Run the installer
  3. Select "Custom (Advanced)" installation
  4. Check all components you want to install
  5. Check "Perform a clean installation"


WHAT YOU LOSE WITHOUT GEFORCE EXPERIENCE
----------------------------------------
- Automatic driver update notifications
- Game optimization feature
- ShadowPlay/screen recording
- NVIDIA Highlights
- Ansel photo mode
- Game streaming features

WHAT YOU GAIN
-------------
- Reduced background processes
- Lower RAM/CPU usage
- No telemetry data collection
- Fewer startup programs
- Cleaner system tray


NOTES
-----
- After NVIDIA driver updates, bloatware may be reinstalled
- Run this script again after driver updates
- Consider using NVCleanstall for clean driver installations:
  https://www.techpowerup.com/download/techpowerup-nvcleanstall/
- NVCleanstall lets you install drivers without bloatware from the start


TIPS
----
- You can still update drivers manually from nvidia.com
- Use DDU (Display Driver Uninstaller) for complete driver removal
- If you need screen recording, use OBS Studio instead of ShadowPlay
- Windows Game Bar (Win+G) also offers basic recording
