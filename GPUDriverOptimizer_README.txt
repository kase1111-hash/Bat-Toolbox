================================================================================
                     GPUDriverOptimizer.bat - Instructions
================================================================================

PURPOSE:
--------
Configures GPU driver profiles for optimal performance based on your use case.
Supports NVIDIA, AMD, and Intel (including Arc) GPUs.

Impact: ⭐⭐☆☆☆ → ⭐⭐⭐⭐☆ (highly situational)
- Competitive gaming: Major improvement in input latency
- Casual gaming: Moderate improvement in consistency
- Content creation: Variable, depends on application
- Power users: Fine-tuning for specific workflows


AVAILABLE PROFILES:
-------------------

1. COMPETITIVE GAMING
   Goal: Absolute minimum input latency
   Settings:
   - All power saving disabled
   - Low latency mode: Ultra
   - V-Sync: Disabled (use frame cap instead)
   - Texture quality: Performance
   - Shader cache: Driver default
   - Exclusive fullscreen: Forced
   Best for: FPS games, fighting games, racing games
   Tradeoff: Slightly lower visual quality, higher power draw

2. BALANCED GAMING
   Goal: Good visuals with low latency
   Settings:
   - Power: Maximum performance
   - Low latency mode: On
   - V-Sync: Application controlled
   - Texture quality: Quality
   - VRR: Enabled
   Best for: Most games, everyday gaming
   Tradeoff: None significant

3. QUALITY / CONTENT CREATION
   Goal: Maximum image quality, stable performance
   Settings:
   - Power: Driver default (adaptive) for thermal management
   - Low latency mode: Off
   - V-Sync: Enabled for smooth frametimes
   - Texture quality: Maximum
   - Shader cache: Unlimited
   Best for: AAA single-player, video editing, 3D rendering
   Tradeoff: Higher input latency

4. POWER EFFICIENT
   Goal: Battery life and low temperatures
   Settings:
   - Power: Adaptive/Balanced
   - Dynamic features: Enabled (Chill, etc.)
   - V-Sync: Enabled to prevent overwork
   - Quality: Standard
   Best for: Laptops on battery, quiet operation
   Tradeoff: Variable and lower performance


WHAT THE SCRIPT CONFIGURES:
---------------------------

Windows-Level Settings:
- Hardware-accelerated GPU scheduling (HAGS)
- Variable Refresh Rate optimization
- Windows Game Mode
- Fullscreen optimization behavior

NVIDIA-Specific:
- PowerMizer / power management mode (Profiles 1-2 force maximum
  performance; Profiles 3-4 remove those overrides so the driver's adaptive
  default applies)
- Shader cache size
- Both are written to the NVIDIA adapter's own display-class registry key
  (the 000N subkey whose ProviderName is NVIDIA). If that key cannot be found
  the step is skipped. \0000 is often the Intel/AMD iGPU on laptops, so the
  script no longer assumes \0000.
- Telemetry opt-out
- Background task scheduling
- (Manual) Low latency mode, threaded optimization

AMD-Specific:
- ULPS (Ultra Low Power State)
- Update/telemetry scheduled tasks (AMDInstallLauncher, AMDLinkUpdate).
  StartCN (starts AMD Software at logon) and StartDVR (ReLive / Instant
  Replay) are not telemetry and are left alone.
- (Manual) Anti-Lag, Boost, Chill, Enhanced Sync

Intel-Specific:
- Intel Graphics Power Plan (a Windows power option: Maximum Performance for
  Profiles 1-3, Balanced for Profile 4, plugged-in only). Skipped if the Intel
  driver does not expose it. The driver's FeatureTestControl value is never
  touched.
- (Manual) Arc Control settings, Smooth Sync


TECHNICAL BACKGROUND:
---------------------

Why driver settings matter:

1. Power Management
   - GPUs throttle to save power by default
   - "Adaptive" waits for load, adds latency
   - "Maximum" keeps GPU ready but uses more power

2. Frame Queue / Pre-rendered Frames
   - GPU works ahead to smooth framerates
   - More frames = smoother but higher latency
   - Competitive: 1 frame | Quality: 2-3 frames

3. Shader Cache
   - Pre-compiled shaders avoid in-game stuttering
   - Larger cache = fewer recompiles
   - Takes disk space (10GB+ for large cache)

4. V-Sync and Frame Pacing
   - V-Sync: Waits for monitor refresh (adds latency)
   - VRR/G-Sync/FreeSync: Variable refresh (less latency)
   - Best competitive setup: VRR on, V-Sync off, FPS capped

5. Driver Heuristics
   - Drivers guess what settings games need
   - Per-app profiles override these guesses
   - Manual tuning beats automatic for specific games


HOW TO USE:
-----------
1. Right-click GPUDriverOptimizer.bat
2. Select "Run as administrator"
3. Select your desired profile (1-4), or 5 to exit without changes
4. Confirm with Y to apply the profile (N exits without changes)
5. Choose whether to create a restore point
6. Follow any manual configuration prompts
7. Restart when complete. If you choose to restart from the script, it waits
   10 seconds (press Ctrl+C, then Y, to cancel) and then restarts normally,
   so open apps can still ask you to save your work.

After running:
1. Open your GPU control panel
2. Verify settings match the recommended values
3. Test with your games/applications
4. Fine-tune individual game profiles as needed


MANUAL CONFIGURATION STEPS:
---------------------------

NVIDIA Control Panel (must be done manually):

1. Open NVIDIA Control Panel
2. Manage 3D Settings > Global Settings
3. Configure based on profile:

   Competitive:
   - Low Latency Mode: Ultra
   - Max Frame Rate: 3 below refresh (e.g., 141 for 144Hz)
   - Power Management: Prefer Maximum Performance
   - Texture Filtering Quality: High Performance
   - Threaded Optimization: Off
   - Vertical Sync: Off

   Balanced:
   - Low Latency Mode: On
   - Max Frame Rate: Off
   - Power Management: Prefer Maximum Performance
   - Texture Filtering Quality: Quality
   - Threaded Optimization: Auto
   - Vertical Sync: Use Application Setting

   Quality:
   - Low Latency Mode: Off
   - Power Management: Normal (driver default)
   - Texture Filtering Quality: High Quality
   - Threaded Optimization: Auto
   - Vertical Sync: On

   Power Efficient:
   - Power Management: Adaptive / Optimal Power
   - Shader Cache: Driver Default
   - Texture Filtering Quality: Quality
   - Threaded Optimization: Auto
   - Vertical Sync: On

4. For per-game overrides: Program Settings tab


AMD Software Configuration:

1. Open AMD Software (Adrenalin)
2. Gaming > Graphics
3. Configure based on profile:

   Competitive:
   - Radeon Anti-Lag: Enabled
   - Radeon Boost: Optional
   - Radeon Chill: Disabled
   - Wait for Vertical Refresh: Off (use FreeSync)
   - Tessellation Mode: Off or 8x max
   - Texture Filtering: Performance

   Balanced:
   - Radeon Anti-Lag: Enabled
   - Enhanced Sync: Enabled
   - Tessellation Mode: AMD Optimized

   Quality:
   - All latency features: Disabled
   - Wait for Vertical Refresh: Always On
   - Texture Filtering: High Quality

   Power Efficient:
   - Radeon Chill: Enabled
   - Set min/max FPS range

4. For per-game profiles: Games tab


Intel Arc Control / Graphics Command Center:

1. Open Intel software
2. For Arc GPUs:
   - Performance > GPU > Increase power limit
   - Games > Smooth Sync (enable/disable per profile)
   - Verify Resizable BAR in BIOS

3. For Integrated Graphics:
   - System > Power > Maximum Performance
   - Display > Disable Panel Self-Refresh (for latency)


RECOMMENDED COMPANION TOOLS:
----------------------------

1. RTSS (RivaTuner Statistics Server)
   - Precise frame rate limiting
   - Scanline sync for additional latency reduction
   - On-screen display for monitoring
   - Download: guru3d.com/files-details/rtss-rivatuner-statistics-server-download

2. NVIDIA Profile Inspector
   - Access hidden NVIDIA driver settings
   - Create detailed per-game profiles
   - Backup/restore driver profiles
   - Download: github.com/Orbmu2k/nvidiaProfileInspector

3. CapFrameX
   - Frame time analysis
   - Latency testing
   - Compare before/after changes
   - Download: capframex.com

4. LatencyMon
   - System-wide latency analysis
   - Identify driver issues
   - Download: resplendence.com/latencymon


HOW TO RESTORE DEFAULTS:
------------------------

Option 1: System Restore
- Run rstrui.exe
- Select restore point created before running script

Option 2: GPU Control Panel Reset

NVIDIA:
- NVIDIA Control Panel > Manage 3D Settings
- Click "Restore" button

AMD:
- AMD Software > Settings (gear icon)
- Click "Reset" or "Restore Factory Defaults"

Intel:
- Intel Graphics Command Center > System
- Click "Restore Original Settings"

Option 3: Manual Registry Restoration
(Run these in an elevated Command Prompt. The "for" lines are written for the
command prompt; inside a .bat file, write %%k and %%v instead of %k and %v.)

Windows GPU settings:
  reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /f
  reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /f
  reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 0 /f
  reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /f
  reg delete "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /f
  reg delete "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /f

Variable refresh rate:
  Do NOT delete DirectXUserGlobalSettings: that one value also stores Auto HDR
  and "Optimizations for windowed games". Instead open Settings > System >
  Display > Graphics > default graphics settings and set "Variable refresh
  rate" back to your previous choice. (Older versions of this script replaced
  the whole value, which reset Auto HDR and windowed-game optimizations to
  their defaults - check those two toggles on the same page as well.)

NVIDIA power and shader cache (restore):
  These values are on the NVIDIA adapter's key, the 000N subkey of
  HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}
  whose ProviderName is NVIDIA. Running the script again with Profile 3 or 4
  removes the power overrides. To remove all of them by hand (this also cleans
  up \0000, where older versions of this script always wrote them, even when
  \0000 was the Intel/AMD iGPU):
  for /f "delims=" %k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do @for %v in (PerfLevelSrc PowerMizerEnable PowerMizerLevel PowerMizerLevelAC ShaderCacheSize) do @reg delete "%k" /v %v /f 2>nul

NVIDIA telemetry (restore):
  reg delete "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /f
  for %v in (EnableRID44231 EnableRID64640 EnableRID66610) do reg delete "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "%v" /f

AMD ULPS (restore):
  For each key in HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000:
  reg add "...\0000" /v "EnableULPS" /t REG_DWORD /d 1 /f

Intel Graphics Power Plan (restore):
  Set the plugged-in value back to your previous choice
  (0 = Maximum Battery Life, 1 = Balanced, 2 = Maximum Performance), e.g.:
  powercfg /setacvalueindex SCHEME_CURRENT 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 1
  powercfg /setactive SCHEME_CURRENT

Intel FeatureTestControl (only if you ran an older version):
  Older versions overwrote the Intel driver's FeatureTestControl value (a
  driver feature bitmask, not a power setting) with 0 or 1 on the Intel
  adapter key. The current version never touches it. To undo, use System
  Restore, reinstall the Intel graphics driver, or set it back to the value
  you had before (commonly 0x9240, or 0x9250 if Intel DPST adaptive
  brightness had been disabled).

Scheduled tasks (restore):
  schtasks /change /tn "NvTmRepOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" /enable
  schtasks /change /tn "NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" /enable
  schtasks /change /tn "AMDInstallLauncher" /enable
  schtasks /change /tn "AMDLinkUpdate" /enable
  Older versions also disabled these two AMD tasks (they start AMD Software
  at logon and ReLive / Instant Replay). Re-enable them if you ran one:
  schtasks /change /tn "StartCN" /enable
  schtasks /change /tn "StartDVR" /enable


COMPETITIVE GAMING COMPLETE SETUP:
----------------------------------

For absolute minimum latency:

1. Run this script with Profile 1 (Competitive)
2. Run InterruptLatencyTuning.bat
3. Run StorageLatencyTuning.bat
4. Configure GPU control panel per instructions above

5. Install RTSS:
   - Set framerate limit to (refresh - 3)
   - Enable "Framerate limiter"
   - Set "Scanline sync" to -10 to -30

6. In-game settings:
   - Fullscreen: Exclusive (not borderless)
   - V-Sync: OFF
   - Frame limiter: OFF (use RTSS)
   - Render latency: Low/Ultra
   - NVIDIA Reflex / AMD Anti-Lag: ON

7. Monitor settings:
   - Response time: Fastest/Extreme
   - G-Sync/FreeSync: ON
   - Overdrive: Medium-High


TROUBLESHOOTING:
----------------

Issue: Game stutters after changes
Fix: Try enabling V-Sync or frame limiter; some games need it

Issue: Screen tearing
Fix: Enable VRR + frame cap, or enable V-Sync

Issue: Higher input lag than before
Fix: Verify fullscreen mode is exclusive, not borderless

Issue: GPU running hotter
Fix: Expected with max performance; improve cooling or use Balanced profile

Issue: No difference in performance
Fix: Bottleneck may be CPU or RAM; profile is already optimal

Issue: Settings don't persist
Fix: Update GPU drivers; some settings require driver reinstall

================================================================================
