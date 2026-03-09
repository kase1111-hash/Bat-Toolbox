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
* Lenovo     - Via Lenovo Energy Management WMI or registry
* ASUS       - Via ASUS ATK ACPI WMI or Battery Health Charging registry
* Microsoft  - Via Surface UEFI Battery Limit registry
* HP         - Via HP Instrumented BIOS WMI or Battery Health Manager policy
* Dell       - Via DCIM WMI or Dell Command | Configure (CCTK)
* Huawei     - Via Huawei PC Manager registry
* Samsung    - Via Samsung Battery Life Extender WMI
* LG         - Via LG Control Center registry
* MSI        - Via MSI WMI interface
* Razer      - Via Razer Synapse 3 registry
* Toshiba    - Via Toshiba ACPI eco Charge WMI

CHARGE LIMIT OPTIONS
--------------------
* 50%   - Maximum longevity. Best for laptops always plugged in.
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
[6] Detect supported method - Scans for available WMI/registry interfaces

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
* Surface:   Latest Surface UEFI firmware
* HP:        HP Battery Health Manager (may be BIOS-only on some models)
* Dell:      Dell Command | Power Manager or Dell Command | Configure
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

* Surface: The default Battery Limit feature caps at 50%. Custom values
  require newer firmware versions.

* Dell: Supports custom charge start and stop thresholds. The script sets
  the start threshold to 5% below the stop threshold.

TROUBLESHOOTING
---------------
If the script reports failure:

1. Install your manufacturer's companion software (see Prerequisites above)
2. Run option [6] to check which interfaces are detected
3. Check BIOS/UEFI settings - some models only support charge limits in BIOS
4. Ensure you are running as Administrator
5. Try restarting and running again after installing companion software

If changes don't take effect:
1. Disconnect and reconnect the AC adapter
2. Restart the laptop
3. Check the manufacturer's app to verify the setting was applied

HOW TO UNDO
-----------
Run the script again and select option [4] to set the limit to 100%.
This removes any charge limit and allows the battery to charge fully.

Alternatively, use your manufacturer's companion app to change the setting,
or reset in BIOS/UEFI under Power Management settings.

ADMIN REQUIREMENTS
------------------
This script requires Administrator privileges for all operations.

================================================================================
