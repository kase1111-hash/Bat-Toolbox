================================================================================
 AudioDeviceAnalyzer.bat - Instructions
================================================================================

DESCRIPTION
-----------
Lists all audio endpoints (speakers, headphones, microphones), shows loaded
audio drivers, detects common issues (wrong default device, enhancements
causing crackling, exclusive mode conflicts, problematic audio software),
and provides one-click fixes. Useful since audio problems are a constant
pain point on Windows.


HOW TO USE
----------
1. Right-click AudioDeviceAnalyzer.bat (admin recommended for fixes)
2. Choose from the menu:
   [1] List all audio devices and endpoints
   [2] Audio driver information
   [3] Detect common audio issues
   [4] Audio service status check
   [5] Apply common fixes


ADMIN REQUIREMENTS
------------------
Without admin:
  - List audio devices and endpoints
  - View audio driver information
  - Basic issue detection
  - Open Sound Settings

With admin:
  - Restart audio services
  - Disable audio enhancements via registry
  - Re-register audio components
  - Full issue detection including Event Log errors


MENU OPTIONS
------------
Option 1: List Audio Devices
  - All WMI sound devices with status
  - Registry-based endpoint enumeration (more detail than WMI)
  - Separate output (speakers/headphones) and input (microphones)
  - Shows device state: Active, Disabled, Not Present, Unplugged

Option 2: Driver Information
  - All audio-related drivers with provider, version, date
  - Color-codes old drivers (yellow >2yr, red >5yr)
  - Audio-related services (Audiosrv, AudioEndpointBuilder, etc.)
  - Detects running audio processing software (Nahimic, Waves, etc.)

Option 3: Detect Common Issues
  - 10 automated checks:
    1. Windows Audio Service running
    2. Audio Endpoint Builder running
    3. Sound devices present with OK status
    4. Audio enhancements enabled
    5. Exclusive mode settings
    6. Sample rate configuration
    7. Multiple audio driver conflicts
    8. Problematic audio software (Nahimic, Waves MaxxAudio)
    9. DPC latency (audio stuttering indicator)
    10. Recent audio errors in Event Log

Option 4: Service Status
  - Core audio services with start type verification
  - Related third-party audio services
  - Flags services that should be Automatic but aren't

Option 5: Apply Common Fixes
  - Restart audio services (no reboot needed)
  - Disable all audio enhancements via registry
  - Open Sound Settings for manual format adjustment
  - Re-register audio DLLs and restart services
  - Direct link to Windows Sound Settings


COMMON AUDIO ISSUES AND FIXES
------------------------------
No Sound:
  1. Run option [3] to check services
  2. Use fix [1] to restart audio services
  3. Use fix [5] to check default device in Sound Settings
  4. Use fix [4] to re-register audio components
  5. If none work, check Device Manager for disabled devices

Crackling / Popping:
  1. Run option [3] — check for enhancements and DPC latency
  2. Use fix [2] to disable all audio enhancements
  3. Check sample rate: set all devices to 48kHz/24-bit
  4. Disable exclusive mode in device Advanced properties
  5. Uninstall Nahimic/Waves if detected
  6. Run InterruptLatencyTuning.bat for DPC optimization

Audio Cutting Out:
  1. Check USB selective suspend (PowerPlanOptimizer.bat can fix)
  2. Disable exclusive mode on the device
  3. Check if another app is taking exclusive control
  4. Update audio drivers

Wrong Device Playing:
  1. Use fix [5] to open Sound Settings
  2. Set the correct default device
  3. Set both "Default Device" and "Default Communication Device"

Microphone Not Working:
  1. Check Windows Privacy settings (Settings > Privacy > Microphone)
  2. Ensure app has microphone access
  3. Check input device in Sound Settings
  4. Verify microphone isn't muted in mixer


PROBLEMATIC SOFTWARE
--------------------
The script detects these known problematic audio packages:

Nahimic:
  - Pre-installed on many ASUS/MSI/Lenovo systems
  - Known to cause crackling, audio dropouts, and conflicts
  - Often conflicts with other audio software
  - Fix: Uninstall via Settings > Apps or use RemoveAsusBloat.bat

Waves MaxxAudio:
  - Pre-installed on Dell systems
  - Adds processing latency
  - Can cause distortion at high volumes
  - Fix: Uninstall or disable in Dell Audio app

Sonic Studio:
  - Pre-installed on ASUS systems
  - Conflicts with other audio drivers
  - Fix: Uninstall via Settings > Apps


HOW TO UNDO
-----------
Option [1] Restart services: Services will auto-start on next boot
Option [2] Disable enhancements: Re-enable in Sound Settings >
  Device Properties > Additional device properties > Enhancements tab
Option [4] Re-register: No adverse effects, safe to run multiple times


NOTES
-----
- Audio issues are among the most common Windows complaints
- The script uses WMI, registry, and service queries
- Some checks work better with admin privileges
- Audio enhancements are the #1 cause of crackling/distortion
- Exclusive mode allows apps to take control of audio hardware
  exclusively — if one app crashes, audio may stop for all apps
- DPC latency above 5% can cause audible stuttering
- Old drivers (5+ years) may lack fixes for current Windows versions


TIPS
----
- Always run option [3] first to get a full issue assessment
- For gaming: disable all enhancements and use 48kHz/24-bit
- For music production: set exclusive mode, use ASIO driver
- After Windows updates, audio drivers may need reinstalling
- If Bluetooth audio stutters, check BT driver version
- Pair with InterruptLatencyTuning.bat to minimize audio latency
- For USB audio devices, disable USB selective suspend
  (PowerPlanOptimizer.bat can do this)
- Use LatencyMon to identify specific drivers causing DPC latency
