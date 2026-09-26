================================================================================
 BRIGHTNESS DIAGNOSTIC TOOL - README
================================================================================

REQUIRED FILES
--------------
* BrightnessDiagnostic.bat  - Main batch file (run this)
* BrightnessDiagnostic.ps1  - PowerShell helper script (must be in same folder)

Both files must be in the same directory for the tool to work.

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
2. Quick Fix - Disables all auto-dimming features after a Y/N confirmation,
   backing up the original values first
3. Maximum Brightness - Sets screen to 100% via Windows API
4. Gamma Boost - Increases perceived brightness BEYOND Windows limits
5. Reset Display Settings - Undoes Quick Fix and the Advanced fixes from the
   saved backup, resets gamma (see RESTORATION below for exactly what it does)
6. View Info - Shows current brightness level and connected monitors
7. Advanced Options - Fine-grained control over specific features, plus an
   exported text report (saved to your real Desktop folder, including a
   OneDrive-redirected Desktop)

WHAT QUICK FIX CHANGES
----------------------
Quick Fix lists these changes and asks for Y/N confirmation before applying:
  * Active power plan, on AC and battery:
      - "Enable adaptive brightness" (ADAPTBRIGHT) = Off
      - "Dimmed display brightness" = 100%
      - "Dim display after" = 0 (never)
  * Sensor Monitoring Service (SensrSvc) stopped and set to Disabled
  * Intel DPST: bit 0x10 is set in FeatureTestControl on each Intel display
    adapter that already has that value. Only that bit changes; the rest of
    the driver's feature bitmask is kept. Nothing is written if the value
    does not exist.
  * CABC: KMD_EnableBrightnessInterface2 = 0 on display adapter 0000

Before any change, the original power plan values and display-driver values
are saved under HKLM\SOFTWARE\BrightnessDiagnostic\Backup. If the backup
fails, nothing is changed. Values already in the backup are never
overwritten, so running a fix twice keeps the true originals. Advanced
options [1] DPST, [2] Vari-Bright and [3] PSR make the same backup first.

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
* Advanced Options (option 7) - [1] DPST, [2] Vari-Bright, [3] PSR and
  [4] Reset Display Adapter require admin; [5]-[7] do not

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
To undo Quick Fix and the Advanced fixes, run option [5] Reset Display
Settings as administrator. It:
  1. Resets gamma to the default (1.0)
  2. Restores from the backup (HKLM\SOFTWARE\BrightnessDiagnostic\Backup):
       - the power plan values "Enable adaptive brightness", "Dimmed display
         brightness" and "Dim display after", in the plan(s) they came from
       - the display-driver values FeatureTestControl,
         KMD_EnableBrightnessInterface2, PP_VariBrightFeatureControl,
         Disable_PSR and EnablePSR (values that did not exist before are
         deleted again)
     and then deletes the backup. If there is no backup, it only turns
     adaptive brightness back on in the active power plan.
     It also removes the DPST_Enabled value that older versions of this tool
     created on adapters 0000/0001 (it is not an Intel driver setting).
  3. Sets the Sensor Monitoring Service back to Manual, the Windows default
  4. Restarts the display driver (needs admin and Windows 10 2004 or later)
Restart Windows afterwards so the driver values take effect.

Without admin rights, option [5] resets gamma only; steps 2-4 need admin.

Changes made by an older version of this tool (before backups existed)
cannot be restored exactly. Undo them manually:
   - Enable Adaptive Brightness in Settings > Display (or run
     powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO ADAPTBRIGHT 1
     powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO ADAPTBRIGHT 1
     powercfg /setactive SCHEME_CURRENT)
   - Set power plan display settings in Control Panel > Power Options
   - Set SensrSvc back to its default: sc config SensrSvc start= demand
   - Older versions set FeatureTestControl on adapters 0000/0001 to a fixed
     0x9240 without saving the original. If you know the original value,
     set it back with regedit under
     HKLM\SYSTEM\CurrentControlSet\Control\Class\
     {4d36e968-e325-11ce-bfc1-08002be10318}\000N

NOTES
-----
* Gamma boost is temporary and resets on restart
* Some changes require a system restart to take effect
* Desktop monitors typically don't support software brightness control
* For permanent gamma, use your GPU's control panel

================================================================================
