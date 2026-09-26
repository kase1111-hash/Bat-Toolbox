================================================================================
 RemoveRealtekBloat.bat - Instructions
================================================================================

DESCRIPTION
-----------
Removes Realtek Audio Console, Nahimic, A-Volute, and other audio bloatware
that ships bundled with Realtek HD Audio drivers. These components cause audio
conflicts, phantom audio processing, and unnecessary resource usage.
The core Realtek HD Audio driver remains intact.


HOW TO USE
----------
1. Right-click RemoveRealtekBloat.bat
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
4. Name it "Before Realtek Bloat Removal"
5. Click Create and wait for completion


WHAT GETS REMOVED
-----------------
- Realtek Audio Console (UWP app - the settings/equalizer UI)
- Nahimic / Nahimic Companion (audio effects engine by A-Volute)
- A-Volute Sonic Studio / Sonic Radar (spatial audio processing)
- Waves MaxxAudio / DTS Audio Processing (if bundled)
- Nahimic Audio Processing Object (APO) entries on the audio endpoints,
  where Windows allows it (see "NAHIMIC APO" below)
- Related services, scheduled tasks, and startup entries
- Desktop (MSI) versions of the above are uninstalled silently with
  msiexec /x (found in Apps & features; WMIC is no longer used, as it is
  not available on Windows 11 24H2 and later)

WHAT STAYS INTACT
-----------------
- Realtek HD Audio driver (core audio functionality)
- Windows Audio Service (AudioSrv / AudioEndpointBuilder)
- All audio devices and endpoints (speakers, headphones, mic)
- System sounds and volume controls
- Dolby Access / Dolby Audio / Dolby Atmos apps (not touched)
- Your audio will continue to work normally


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your "Before Realtek Bloat Removal" restore point
  3. Follow the wizard to restore

Option 2: Reinstall Realtek Audio Console
  1. Open the Microsoft Store
  2. Search for "Realtek Audio Console" or "Realtek Audio Control"
  3. Click Install

Option 3: Reinstall Nahimic (if desired)
  1. Open the Microsoft Store
  2. Search for "Nahimic" or "Nahimic Companion"
  3. Click Install

Option 4: Reinstall Full Realtek Driver Package
  1. Download the latest Realtek HD Audio driver from your
     motherboard/laptop manufacturer's support page
  2. Run the installer (this will reinstall all bundled components)


WHY REMOVE THESE?
-----------------
Nahimic / A-Volute:
  - Known to cause audio crackling, popping, and latency issues
  - Conflicts with pro audio software (DAWs, ASIO drivers)
  - Runs multiple background services even when "disabled"
  - Reinstalls itself after Windows updates
  - Provides marginal audio "enhancement" most users don't need

Realtek Audio Console:
  - UWP app that duplicates Windows sound settings
  - Often fails to launch or shows blank window
  - Phones home for telemetry
  - Not required for audio to function

Waves MaxxAudio / DTS:
  - Adds latency to audio processing pipeline
  - Conflicts with external DAC/amp setups
  - Not needed for standard audio output


WHAT YOU LOSE
-------------
- Nahimic spatial audio effects (surround virtualization)
- Realtek Audio Console equalizer and presets
- Per-application volume control via Realtek UI
- Waves MaxxAudio enhancement profiles

WHAT YOU GAIN
-------------
- Reduced audio latency
- Less audio crackling/popping caused by Nahimic (fully gone only once its
  APO is no longer loaded - see "NAHIMIC APO" below)
- Lower CPU usage from background audio services
- Cleaner audio signal path (no forced processing)
- Better compatibility with pro audio software and ASIO drivers


NAHIMIC APO
-----------
The Nahimic audio effect (APO) is registered per audio endpoint under
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio as CLSIDs.
The script resolves each CLSID to its COM registration to find the Nahimic /
A-Volute ones and tries to remove those entries. It never removes an entry
that also lists other (e.g. Realtek) effects, and it only reports
"Cleared APO entry" when the delete really worked. These endpoint keys are
normally protected (owned by TrustedInstaller), so Windows usually refuses
the delete; the script then says the APO was found but not removed.

To unload a Nahimic APO that is still active, remove its driver package:
  1. Open Device Manager (Win+X > Device Manager)
  2. Expand "Software components" (and "Sound, video and game controllers")
  3. For each entry named Nahimic or A-Volute (leave the Realtek audio
     device itself alone): right-click > Uninstall device, tick
     "Attempt to remove the driver for this device", click Uninstall
  4. Restart. Windows Update may reinstall it with a later driver update.
To undo, reinstall the full audio driver package from your PC maker
(Option 4 above) or use System Restore.


NOTES
-----
- After Realtek driver updates, bloatware may be reinstalled
- Run this script again after driver updates if Nahimic reappears
- Windows built-in spatial sound and equalizer are available as alternatives:
  Right-click speaker icon > Sound settings > Audio enhancements
- For pro audio work, consider dedicated ASIO drivers instead


TIPS
----
- If audio sounds "flat" after removal, that is clean unprocessed output
- Use Windows sound settings for basic EQ adjustments
- Third-party EQ software like Equalizer APO is a lightweight alternative
- If you use a USB DAC or external audio interface, these removals are
  especially beneficial as they eliminate processing conflicts
