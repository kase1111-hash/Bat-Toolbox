================================================================================
 BATTERY CHARGE LIMIT - README
================================================================================

DESCRIPTION
-----------
Sets the maximum battery charge threshold on supported Windows laptops.
Limiting the maximum charge level (e.g., to 80%) significantly extends the
long-term lifespan of lithium-ion batteries by reducing stress on the cells.

SUPPORTED MANUFACTURERS
-----------------------
* Lenovo     - Via Lenovo Energy Management WMI or registry (*)
* ASUS       - Via ASUS ATK ACPI WMI or Battery Health Charging registry (*)
* Microsoft  - Surface Battery Limit is a firmware setting that cannot be
               changed from Windows. The script shows how to set it in
               Surface UEFI or the Surface app.
* HP         - Via HP Instrumented BIOS WMI or Battery Health Manager policy (*)
* Dell       - Via DCIM WMI or Dell Command | Configure (CCTK)
* Huawei     - Via Huawei PC Manager registry (*)
* Samsung    - Via Samsung Battery Life Extender WMI
* LG         - Via LG Control Center registry (*)
* MSI        - Via MSI WMI interface
* Razer      - Via Razer Synapse 3 registry (*)
* Toshiba    - Via Toshiba ACPI eco Charge WMI

(*) Registry fallbacks: the script only writes a vendor registry value if
    that vendor's key already exists (it never creates the key). Nothing
    can confirm that the vendor software reads the value, so the script
    reports the result as UNVERIFIED instead of success. Check your
    manufacturer app or BIOS to confirm the limit is active.

CHARGE LIMIT OPTIONS
--------------------
* 50%   - Maximum longevity. Best for laptops always plugged in.
          (ASUS uses 60% and Dell uses 55%, their lowest supported values.
          The script tells you when it uses a different value.)
* 80%   - Recommended balance between capacity and lifespan.
* 90%   - Slight protection while keeping most capacity available.
* 100%  - No limit. Charges to full (removes any previously set limit).

WHY LIMIT BATTERY CHARGE?
--------------------------
Lithium-ion batteries degrade faster when kept at high charge levels.
Keeping the battery between 20-80% can double or triple its useful lifespan.

Approximate cycle life by charge level:
  100% charge limit: ~300-500 full cycles
  80% charge limit:  ~800-1200 full cycles
  50% charge limit:  ~1500+ full cycles

If your laptop is mostly plugged in at a desk, 50-80% is ideal.
If you travel frequently, 80-90% gives a good balance.

MENU OPTIONS
------------
[1] Set charge limit to 50%  - Maximum longevity
[2] Set charge limit to 80%  - Recommended balance
[3] Set charge limit to 90%  - Slight protection
[4] Set charge limit to 100% - No limit (full charge)
[5] View current battery status - Shows charge, health, and capacity info
    (on laptops with two batteries, capacity and health are combined)
[6] Detect supported method - Scans for available WMI/registry interfaces
    (Surface Battery Limit is a firmware setting and cannot be detected)

HOW TO USE
----------
1. Right-click BatteryChargeLimit.bat
2. Select "Run as administrator"
3. The script will detect your laptop manufacturer automatically
4. Select a charge limit option (1-4)
5. Confirm when prompted

PREREQUISITES
-------------
Most manufacturers require their companion software/driver to be installed:

* Lenovo:    Lenovo Vantage or Lenovo Energy Management
* ASUS:      MyASUS or ASUS System Control Interface driver
* Surface:   Nothing to install - set it in Surface UEFI or the Surface app
* HP:        HP Battery Health Manager (may be BIOS-only on some models)
* Dell:      Dell Command | Power Manager or Dell Command | Configure
             (cctk.exe is found in its default install folder, so it does
             not need to be on PATH)
* Huawei:    Huawei PC Manager
* Samsung:   Samsung Settings or Samsung System Agent
* LG:        LG Control Center
* MSI:       MSI Center or MSI Dragon Center
* Razer:     Razer Synapse 3
* Toshiba:   Toshiba System Settings or Dynabook Settings

Use option [6] to detect which interfaces are available on your system.

MANUFACTURER NOTES
------------------
* HP: Does not support custom percentages via WMI. HP Battery Health Manager
  uses predefined modes. The "Maximize Health" mode typically limits to ~80%.

* Samsung: Battery Life Extender is a toggle (on/off). When enabled, the
  charge limit is typically 85%. Custom values are not supported.

* Toshiba: eco Charge is a toggle. When enabled, the limit is typically ~80%.

* Surface: Battery Limit cannot be set from Windows (the firmware does not
  read any registry value). To set it:
    - Shut down, hold Volume Up and press Power to open Surface UEFI, then
      Boot configuration > Advanced options > Enable Battery Limit
      (On = stop charging at 50%, Off = charge to 100%).
    - Newer models (e.g. Surface Pro 11, Surface Laptop 7): Surface app >
      Battery & charging > Charging mode (Limit to 80% / Charge to 100%).
  Earlier versions of this script wrote EnableBatteryLimit and
  BatteryLimitPercent under HKLM\SOFTWARE\Microsoft\BatteryLimit. Those
  values did nothing; the script now deletes them when run on a Surface.

* ASUS: The WMI method sets the charge-stop percentage directly (DEVS,
  device 0x00120057). ASUS firmware may reset it after a reboot or sleep
  unless MyASUS keeps it, so run the script again if the limit is lost.

* Dell: Supports custom charge start and stop thresholds. Dell requires a
  start value of 50-95% and a stop value of 55-100%. The script sets the
  start threshold to 5% below the stop threshold. The 50% option becomes
  start 50% / stop 55%, because 50% is below Dell's minimum stop value.

TROUBLESHOOTING
---------------
If the script reports failure:

1. Install your manufacturer's companion software (see Prerequisites above)
2. Run option [6] to check which interfaces are detected
3. Check BIOS/UEFI settings - some models only support charge limits in BIOS
4. Ensure you are running as Administrator
5. Try restarting and running again after installing companion software

If changes don't take effect (or the script reports UNVERIFIED):
1. Disconnect and reconnect the AC adapter
2. Restart the laptop
3. Check the manufacturer's app to verify the setting was applied

HOW TO UNDO
-----------
Run the script again and select option [4] to set the limit to 100%.
This removes any charge limit and allows the battery to charge fully.
(HP registry fallback: option [4] deletes the "Setting" policy value.)

Alternatively, use your manufacturer's companion app to change the setting,
or reset in BIOS/UEFI under Power Management settings.

Surface: turn Enable Battery Limit off in Surface UEFI, or choose
"Charge to 100%" in the Surface app (see MANUFACTURER NOTES).

Leftover keys from older versions:
Earlier versions of this script created the registry keys below even when
no vendor software used them, and reported success. Because the script now
only writes to keys that already exist, a key left behind by an older
version is written to again (and reported as UNVERIFIED). Open the key in
regedit first: if it has no subkeys and contains only the values listed
after it (or no values at all), it was created by this script and can be
deleted from an admin Command Prompt:
  reg delete "HKLM\SOFTWARE\Lenovo\PWRMGRV\ConfKeys\Data" /f
      (values: ChargeMode, ChargeStopPercentage)
  reg delete "HKLM\SOFTWARE\ASUS\ASUS Battery Health Charging" /f
      (value: ChargeLimit)
  reg delete "HKLM\SOFTWARE\Policies\HP\HP Battery Health Manager" /f
      (value: Setting)
  reg delete "HKLM\SOFTWARE\Huawei\PCManager\BatteryLife" /f
      (values: SmartCharge, MaxChargeCapacity)
  reg delete "HKLM\SOFTWARE\LG\ControlCenter\BatteryCharge" /f
      (value: ChargeLimit)
  reg delete "HKLM\SOFTWARE\Razer\Synapse3\BatteryDesktop" /f
      (value: ChargeLimit)
If the key also contains other values or subkeys, it belongs to the vendor
software: leave it and change the setting in the vendor app instead.
(The Surface values under HKLM\SOFTWARE\Microsoft\BatteryLimit are removed
automatically when the script runs on a Surface.)

ADMIN REQUIREMENTS
------------------
This script requires Administrator privileges for all operations.

================================================================================
