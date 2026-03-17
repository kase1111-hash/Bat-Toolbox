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
- Audio Processing Object (APO) hooks in the driver chain
- Related services, scheduled tasks, and startup entries

WHAT STAYS INTACT
-----------------
- Realtek HD Audio driver (core audio functionality)
- Windows Audio Service (AudioSrv / AudioEndpointBuilder)
- All audio devices and endpoints (speakers, headphones, mic)
- System sounds and volume controls
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
- Elimination of audio crackling/popping caused by APO conflicts
- Lower CPU usage from background audio services
- Cleaner audio signal path (no forced processing)
- Better compatibility with pro audio software and ASIO drivers


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
