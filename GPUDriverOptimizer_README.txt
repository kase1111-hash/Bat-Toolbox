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
   - Power: Adaptive for thermal management
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
- PowerMizer / power management mode
- Shader cache size
- Telemetry opt-out
- Background task scheduling
- (Manual) Low latency mode, threaded optimization

AMD-Specific:
- ULPS (Ultra Low Power State)
- Telemetry scheduled tasks
- (Manual) Anti-Lag, Boost, Chill, Enhanced Sync

Intel-Specific:
- Graphics power plan
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
3. Choose whether to create a restore point
4. Select your desired profile (1-4)
5. Follow any manual configuration prompts
6. Restart when complete

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
   - Power Management: Optimal Power
   - Texture Filtering Quality: High Quality
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

Windows GPU settings:
  reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /f
  reg delete "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /f
  reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /f

NVIDIA telemetry (restore):
  reg delete "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /f

AMD ULPS (restore):
  For each key in HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000:
  reg add "...\0000" /v "EnableULPS" /t REG_DWORD /d 1 /f

Scheduled tasks (restore):
  schtasks /change /tn "NvTmRepOnLogon_{...}" /enable
  schtasks /change /tn "NvTmRep_{...}" /enable
  schtasks /change /tn "AMDInstallLauncher" /enable


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
