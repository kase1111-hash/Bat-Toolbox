================================================================================
 BRIGHTNESS DIAGNOSTIC TOOL - README
================================================================================

DESCRIPTION
-----------
A comprehensive diagnostic and repair tool for screen brightness issues.
Diagnoses why your screen may be auto-dimming and provides fixes including
the ability to boost brightness beyond Windows' normal 100% limit using
gamma adjustment.

COMMON ISSUES THIS TOOL ADDRESSES
---------------------------------
* Screen dims randomly and won't turn back up
* Brightness stuck at low level
* Auto-dimming when watching videos or on battery
* Brightness changes based on screen content
* Adaptive brightness interference from light sensors

FEATURES
--------
1. Full Diagnostic - Checks all brightness-related settings and services
2. Quick Fix - One-click disable of all auto-dimming features
3. Maximum Brightness - Sets screen to 100% via Windows API
4. Gamma Boost - Increases perceived brightness BEYOND Windows limits
5. Reset to Default - Restores all settings to Windows defaults
6. Advanced Options - Fine-grained control over specific features

GAMMA BOOST EXPLAINED
---------------------
Windows limits software brightness control to 100%. However, gamma adjustment
can make your screen appear brighter by boosting the RGB color curves. This
works on ALL monitors including desktop displays that don't support Windows
brightness control.

Gamma values:
  1.0 = Normal (default)
  1.1 = +10% perceived brightness
  1.2 = +20% perceived brightness
  1.3 = +30% perceived brightness
  1.5 = +50% perceived brightness (colors may wash out)

Note: Gamma changes reset when you restart or log off.

WHAT CAUSES AUTO-DIMMING
------------------------
1. Adaptive Brightness - Uses ambient light sensor to adjust brightness
2. Intel DPST - Display Power Saving Technology, dims based on content
3. AMD Vari-Bright - AMD's equivalent power saving feature
4. CABC - Content Adaptive Brightness Control, built into some panels
5. Panel Self-Refresh (PSR) - Can cause brightness fluctuations
6. Power Plan Settings - Windows may dim display when idle or on battery
7. Sensor Monitoring Service - Windows service for light sensor

HOW TO USE
----------
1. Right-click BrightnessDiagnostic.bat
2. Select "Run as administrator" (required for most fixes)
3. Choose option [1] to run the full diagnostic first
4. Review the results to see what's causing dimming
5. Use option [2] Quick Fix to disable all auto-dimming at once

For brightness beyond 100%:
1. Choose option [4] Gamma Boost
2. Select a boost level (start with Slight or Medium)
3. If colors look washed out, reduce the gamma value

ADMIN REQUIREMENTS
------------------
* Diagnostic (option 1) - No admin required
* Quick Fix (option 2) - Requires admin
* Set Max Brightness (option 3) - No admin required
* Gamma Boost (option 4) - No admin required
* Reset Display (option 5) - Partial admin for some features
* View Info (option 6) - No admin required
* Advanced Options (option 7) - Most require admin

TROUBLESHOOTING
---------------
If brightness still dims after using Quick Fix:

1. Check GPU Control Panel:
   - NVIDIA Control Panel > Manage 3D Settings > Power Management
   - AMD Radeon Software > Gaming > Display > Vari-Bright
   - Intel Graphics Command Center > System > Power

2. Check Manufacturer Software:
   - Dell: Dell Power Manager, Dell Display Manager
   - HP: HP Display Control
   - Lenovo: Lenovo Vantage display settings
   - ASUS: Armoury Crate display settings

3. Check BIOS/UEFI:
   - Some laptops have DPST/Vari-Bright toggles in BIOS

4. Desktop Monitors:
   - Use physical buttons on the monitor
   - Access monitor OSD menu for brightness/contrast
   - Some monitors have "Dynamic Contrast" - disable it

RESTORATION
-----------
To undo all changes:
1. Run option [5] Reset Display Settings
2. Or manually:
   - Enable Adaptive Brightness in Settings > Display
   - Set power plan display settings in Control Panel
   - Enable SensrSvc service: sc config SensrSvc start= auto

NOTES
-----
* Gamma boost is temporary and resets on restart
* Some changes require a system restart to take effect
* Desktop monitors typically don't support software brightness control
* For permanent gamma, use your GPU's control panel

================================================================================
