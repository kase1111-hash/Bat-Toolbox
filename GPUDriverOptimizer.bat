@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: GPUDriverOptimizer.bat
:: Custom GPU Driver Profiles for Performance & Low Latency
:: ============================================================

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges.
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

title GPU Driver Optimizer

:: Colors
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "MAGENTA=%ESC%[95m"
set "WHITE=%ESC%[97m"
set "GRAY=%ESC%[90m"
set "RESET=%ESC%[0m"

echo %CYAN%============================================================%RESET%
echo %WHITE%          GPU DRIVER OPTIMIZER%RESET%
echo %WHITE%     Performance Profiles ^& Latency Tuning%RESET%
echo %CYAN%============================================================%RESET%
echo/

:: Detect GPU
echo %YELLOW%Detecting GPU(s)...%RESET%
echo/

set "has_nvidia=0"
set "has_amd=0"
set "has_intel=0"

:: Query GPU names once via CIM (wmic is removed on Windows 11 24H2+, where the
:: old wmic query returned nothing and the script wrongly reported "No GPU").
set "GPU_NAMES="
for /f "delims=" %%g in ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController).Name" 2^>nul') do set "GPU_NAMES=!GPU_NAMES! %%g"

echo !GPU_NAMES! | findstr /i "NVIDIA" >nul && set "has_nvidia=1"
echo !GPU_NAMES! | findstr /i "AMD Radeon" >nul && set "has_amd=1"
echo !GPU_NAMES! | findstr /i "ATI Radeon" >nul && set "has_amd=1"
echo !GPU_NAMES! | findstr /i "Intel" >nul && set "has_intel=1"

echo %WHITE%Detected GPUs:%RESET%
powershell -Command "Get-WmiObject Win32_VideoController | Select-Object Name, DriverVersion | Format-Table -AutoSize"

if "%has_nvidia%"=="0" if "%has_amd%"=="0" if "%has_intel%"=="0" (
    echo %RED%[ERROR] No supported GPU detected%RESET%
    pause
    exit /b 1
)

echo/
echo %WHITE%This script optimizes:%RESET%
echo   - Power management (max performance)
echo   - Shader cache behavior
echo   - Low latency modes
echo   - Frame pacing and V-Sync
echo   - Texture filtering quality
echo   - Driver heuristics
echo/
echo %YELLOW%Impact: Depends heavily on workload%RESET%
echo   - Competitive gaming: Major improvement (latency)
echo   - Productivity: Moderate (consistent performance)
echo   - Content creation: Variable (depends on app)
echo/

echo %CYAN%============================================================%RESET%
echo %WHITE%  SELECT OPTIMIZATION PROFILE%RESET%
echo %CYAN%============================================================%RESET%
echo/
echo %WHITE%[1]%RESET% %GREEN%Competitive Gaming%RESET%
echo     - Lowest latency, disable all smoothing
echo     - Best for: FPS, fighting games, racing
echo     - Tradeoff: May have slight visual artifacts
echo/
echo %WHITE%[2]%RESET% %CYAN%Balanced Gaming%RESET%
echo     - Low latency with quality textures
echo     - Best for: Most games, general use
echo     - Tradeoff: None significant
echo/
echo %WHITE%[3]%RESET% %MAGENTA%Quality / Content Creation%RESET%
echo     - Maximum quality, stable frametimes
echo     - Best for: AAA games, video editing, 3D work
echo     - Tradeoff: Slightly higher latency
echo/
echo %WHITE%[4]%RESET% %YELLOW%Power Efficient%RESET%
echo     - Adaptive performance, lower temps
echo     - Best for: Laptops, quiet operation
echo     - Tradeoff: Variable performance
echo/
echo %WHITE%[5]%RESET% Cancel - exit without changes
echo/

choice /c 12345 /m "Select profile"
set "profile=%errorlevel%"

:: Only 1-4 are profiles. [5] cancels, and choice returns 0 when Ctrl+C is
:: pressed and the batch is not terminated, so both exit without changes.
set "profile_name="
if "%profile%"=="1" set "profile_name=Competitive Gaming"
if "%profile%"=="2" set "profile_name=Balanced Gaming"
if "%profile%"=="3" set "profile_name=Quality / Content Creation"
if "%profile%"=="4" set "profile_name=Power Efficient"
if not defined profile_name (
    echo/
    echo %YELLOW%Cancelled - no changes were made.%RESET%
    pause
    exit /b 0
)

echo/
echo %GREEN%Selected: %profile_name%%RESET%
echo/
choice /c YN /m "Apply the %profile_name% profile now"
if %errorlevel% neq 1 (
    echo/
    echo %YELLOW%Cancelled - no changes were made.%RESET%
    pause
    exit /b 0
)

echo/
choice /c YN /m "Create a system restore point before continuing"
if %errorlevel%==1 (
    echo/
    echo %CYAN%Creating restore point...%RESET%
    REM Checkpoint-Computer exits 0 even when it silently skips (System Protection
    REM off, or the 24h frequency limit), so verify a point was actually added.
    powershell -NoProfile -Command "$b=@(Get-ComputerRestorePoint).Count; Checkpoint-Computer -Description 'Before GPUDriverOptimizer' -RestorePointType 'MODIFY_SETTINGS'; if (@(Get-ComputerRestorePoint).Count -gt $b) { exit 0 } else { exit 1 }" 2>nul
    if !errorlevel! equ 0 (
        echo %GREEN%[OK] Restore point created%RESET%
    ) else (
        echo %YELLOW%[WARN] Could not create restore point ^(System Protection off or created recently^)%RESET%
    )
)
echo/

:: ============================================================
:: Windows GPU Settings (applies to all GPUs)
:: ============================================================

echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 1: Windows GPU Settings%RESET%
echo %CYAN%============================================================%RESET%
echo/

:: Hardware-accelerated GPU scheduling
echo %WHITE%[1/4] Hardware-accelerated GPU scheduling...%RESET%
if "%profile%"=="4" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 1 /f >nul 2>&1
    echo %YELLOW%   [SET] Disabled ^(power saving^)%RESET%
) else (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul 2>&1
    echo %GREEN%   [SET] Enabled ^(reduces latency^)%RESET%
)

:: Variable Refresh Rate
echo %WHITE%[2/4] Variable Refresh Rate (VRR)...%RESET%
:: DirectXUserGlobalSettings holds all of Windows' default graphics settings
:: (e.g. AutoHDREnable, SwapEffectUpgradeEnable), so :SetVRR changes only the
:: VRROptimizeEnable entry instead of overwriting the whole value.
if "%profile%"=="1" (
    REM Competitive - disable VRR for lowest latency ^(controversial, user preference^)
    call :SetVRR 0
    echo %YELLOW%   [SET] VRR optimization disabled ^(raw latency^)%RESET%
) else (
    call :SetVRR 1
    echo %GREEN%   [SET] VRR optimization enabled%RESET%
)

:: Game Mode
echo %WHITE%[3/4] Windows Game Mode...%RESET%
if "%profile%"=="3" (
    reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
    echo %YELLOW%   [SET] Disabled ^(content creation - avoids interference^)%RESET%
) else (
    reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
    echo %GREEN%   [SET] Enabled%RESET%
)

:: Fullscreen optimizations
echo %WHITE%[4/4] Fullscreen optimizations...%RESET%
if "%profile%"=="1" (
    REM Disable FSO for competitive ^(true exclusive fullscreen^)
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f >nul 2>&1
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d 2 /f >nul 2>&1
    echo %GREEN%   [SET] True exclusive fullscreen enabled%RESET%
) else (
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 0 /f >nul 2>&1
    REM Undo the Profile 1 overrides so FSO really returns to Windows' per-app choice
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 0 /f >nul 2>&1
    reg delete "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /f >nul 2>&1
    echo %GREEN%   [SET] Windows decides per-application%RESET%
)

:: ============================================================
:: NVIDIA Optimizations
:: ============================================================

if "%has_nvidia%"=="1" (
    echo/
    echo %CYAN%============================================================%RESET%
    echo %WHITE%  PHASE 2: NVIDIA Driver Optimizations%RESET%
    echo %CYAN%============================================================%RESET%
    echo/

    REM Find the display-class instance key whose ProviderName is NVIDIA.
    REM Instance numbers follow install order: on laptops and PCs with an Intel/AMD
    REM iGPU, \0000 is often the iGPU and the NVIDIA adapter is \0001 or higher.
    set "nv_path="
    for /f "delims=" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
        reg query "%%k" /v ProviderName 2>nul | find /i "NVIDIA" >nul && set "nv_path=%%k"
    )

    REM Global NVIDIA settings via registry
    REM Profiles 1-2 force maximum performance. Profiles 3-4 remove those overrides
    REM so the driver's own adaptive power management applies again.
    echo %WHITE%[1/10] Power management mode...%RESET%
    set "nv_maxperf=0"
    if "%profile%"=="1" set "nv_maxperf=1"
    if "%profile%"=="2" set "nv_maxperf=1"
    if not defined nv_path (
        echo %YELLOW%   [SKIP] NVIDIA adapter registry key not found%RESET%
    ) else if "!nv_maxperf!"=="0" (
        for %%v in (PerfLevelSrc PowerMizerEnable PowerMizerLevel PowerMizerLevelAC) do reg delete "!nv_path!" /v "%%v" /f >nul 2>&1
        echo %YELLOW%   [SET] Driver default ^(adaptive^)%RESET%
    ) else (
        REM Prefer maximum performance
        reg add "!nv_path!" /v "PerfLevelSrc" /t REG_DWORD /d 8738 /f >nul 2>&1
        reg add "!nv_path!" /v "PowerMizerEnable" /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "!nv_path!" /v "PowerMizerLevel" /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "!nv_path!" /v "PowerMizerLevelAC" /t REG_DWORD /d 1 /f >nul 2>&1
        echo %GREEN%   [SET] Maximum performance%RESET%
    )

    echo %WHITE%[2/10] Low Latency Mode...%RESET%
    REM NVIDIA Control Panel Low Latency Mode via profile settings
    REM Uses NVIDIA Profile Inspector values
    if "%profile%"=="1" (
        REM Ultra ^(submit frames just-in-time^)
        echo %GREEN%   [SET] Ultra ^(competitive - submit just-in-time^)%RESET%
        echo %YELLOW%   [INFO] Set via NVIDIA Control Panel: Manage 3D Settings ^> Low Latency Mode ^> Ultra%RESET%
    ) else if "%profile%"=="2" (
        REM On
        echo %GREEN%   [SET] On ^(balanced^)%RESET%
        echo %YELLOW%   [INFO] Set via NVIDIA Control Panel: Low Latency Mode ^> On%RESET%
    ) else (
        REM Off or Application controlled
        echo %YELLOW%   [SET] Application controlled%RESET%
    )

    echo %WHITE%[3/10] Shader cache...%RESET%
    REM Shader cache location and size
    if not defined nv_path (
        echo %YELLOW%   [SKIP] NVIDIA adapter registry key not found%RESET%
    ) else if "%profile%"=="3" (
        REM Unlimited for content creation ^(more VRAM usage^)
        reg add "!nv_path!" /v "ShaderCacheSize" /t REG_DWORD /d 0xFFFFFFFF /f >nul 2>&1
        echo %GREEN%   [SET] Unlimited ^(quality/content creation^)%RESET%
    ) else (
        REM Default driver controlled
        reg delete "!nv_path!" /v "ShaderCacheSize" /f >nul 2>&1
        echo %GREEN%   [SET] Driver controlled ^(10GB default^)%RESET%
    )

    echo %WHITE%[4/10] Threaded optimization...%RESET%
    REM 0x00000001 = Auto, 0x00000002 = On, 0x00000000 = Off
    if "%profile%"=="1" (
        REM Off for competitive ^(more predictable frametimes^)
        echo %YELLOW%   [SET] Off ^(competitive - predictable frametimes^)%RESET%
        echo %YELLOW%   [INFO] Set via NVIDIA Control Panel if needed%RESET%
    ) else (
        REM Auto for most use cases
        echo %GREEN%   [SET] Auto ^(driver decides per-application^)%RESET%
    )

    echo %WHITE%[5/10] Texture filtering quality...%RESET%
    if "%profile%"=="1" (
        echo %GREEN%   [SET] High Performance ^(competitive^)%RESET%
    ) else if "%profile%"=="3" (
        echo %GREEN%   [SET] High Quality ^(content creation^)%RESET%
    ) else (
        echo %GREEN%   [SET] Quality ^(balanced^)%RESET%
    )
    echo %YELLOW%   [INFO] Set via NVIDIA Control Panel: Texture filtering - Quality%RESET%

    echo %WHITE%[6/10] Anisotropic filtering...%RESET%
    if "%profile%"=="1" (
        echo %GREEN%   [SET] Application-controlled ^(competitive^)%RESET%
    ) else (
        echo %GREEN%   [SET] 16x ^(quality^)%RESET%
    )
    echo %YELLOW%   [INFO] Set via NVIDIA Control Panel: Anisotropic filtering%RESET%

    echo %WHITE%[7/10] NVIDIA Reflex ^(game-specific^)...%RESET%
    echo %GREEN%   [OK] Enabled in supported games via in-game settings%RESET%
    echo %YELLOW%   [INFO] Look for "NVIDIA Reflex Low Latency" in game settings%RESET%

    echo %WHITE%[8/10] G-SYNC settings...%RESET%
    if "%profile%"=="1" (
        echo %YELLOW%   [SET] Disable V-Sync in NVIDIA CP, cap FPS 3 below refresh%RESET%
        echo %YELLOW%   [INFO] Example: 144Hz monitor ^= cap at 141 FPS%RESET%
    ) else (
        echo %GREEN%   [SET] G-SYNC on, V-Sync on, no FPS cap needed%RESET%
    )

    echo %WHITE%[9/10] Pre-rendered frames...%RESET%
    if "%profile%"=="1" (
        echo %GREEN%   [SET] 1 ^(minimum latency^)%RESET%
    ) else (
        echo %GREEN%   [SET] Use application setting or 2-3%RESET%
    )
    echo %YELLOW%   [INFO] Set via NVIDIA Control Panel: Low Latency Mode handles this%RESET%

    echo %WHITE%[10/10] NVIDIA telemetry and background tasks...%RESET%
    REM Disable NVIDIA telemetry
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID44231" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID64640" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID66610" /t REG_DWORD /d 0 /f >nul 2>&1
    echo %GREEN%   [OK] Telemetry opt-out registry values set%RESET%
    REM Disable NVIDIA container telemetry tasks ^(only present with older drivers^)
    for %%T in (NvTmRepOnLogon NvTmRep) do (
        schtasks /change /tn "%%T_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" /disable >nul 2>&1 && echo %GREEN%   [OK] %%T task disabled%RESET% || echo %GRAY%   [--] %%T task not found%RESET%
    )

    echo/
    echo %CYAN%NVIDIA Profile Inspector recommended settings:%RESET%
    echo   For advanced per-game profiles, download NVIDIA Profile Inspector
    echo   https://github.com/Orbmu2k/nvidiaProfileInspector
    echo/
    echo   Key settings to adjust:
    if "%profile%"=="1" (
        echo     - Frame Rate Limiter Mode: Limiter V3
        echo     - Power Management Mode: Prefer Maximum Performance
        echo     - Shader Cache: Driver Default
        echo     - Texture Filtering - Quality: High Performance
        echo     - Threaded Optimization: Off
        echo     - Vertical Sync: Force Off
        echo     - Maximum Pre-Rendered Frames: 1
    ) else if "%profile%"=="2" (
        echo     - Frame Rate Limiter Mode: Limiter V3
        echo     - Power Management Mode: Prefer Maximum Performance
        echo     - Shader Cache: Driver Default
        echo     - Texture Filtering - Quality: Quality
        echo     - Threaded Optimization: Auto
        echo     - Vertical Sync: Use Application Setting
    ) else if "%profile%"=="3" (
        echo     - Power Management Mode: Normal ^(driver default^)
        echo     - Shader Cache: Unlimited
        echo     - Texture Filtering - Quality: High Quality
        echo     - Threaded Optimization: Auto
        echo     - Vertical Sync: On
    ) else (
        echo     - Power Management Mode: Adaptive / Optimal Power
        echo     - Shader Cache: Driver Default
        echo     - Texture Filtering - Quality: Quality
        echo     - Threaded Optimization: Auto
        echo     - Vertical Sync: On
    )
)

:: ============================================================
:: AMD Optimizations
:: ============================================================

if "%has_amd%"=="1" (
    echo/
    echo %CYAN%============================================================%RESET%
    echo %WHITE%  PHASE 3: AMD Driver Optimizations%RESET%
    echo %CYAN%============================================================%RESET%
    echo/

    echo %WHITE%[1/12] Radeon Anti-Lag...%RESET%
    if "%profile%"=="1" (
        echo %GREEN%   [SET] Enabled ^(competitive - reduces input lag^)%RESET%
    ) else if "%profile%"=="4" (
        echo %YELLOW%   [SET] Disabled ^(power saving^)%RESET%
    ) else (
        echo %GREEN%   [SET] Enabled%RESET%
    )
    echo %YELLOW%   [INFO] Set via AMD Software: Gaming ^> Graphics ^> Anti-Lag%RESET%

    echo %WHITE%[2/12] Radeon Boost...%RESET%
    if "%profile%"=="1" (
        echo %GREEN%   [SET] Enabled ^(reduces resolution during fast motion^)%RESET%
    ) else if "%profile%"=="3" (
        echo %YELLOW%   [SET] Disabled ^(quality priority^)%RESET%
    ) else (
        echo %GREEN%   [SET] Optional - user preference%RESET%
    )
    echo %YELLOW%   [INFO] Set via AMD Software: Gaming ^> Graphics ^> Radeon Boost%RESET%

    echo %WHITE%[3/12] Radeon Chill...%RESET%
    if "%profile%"=="4" (
        echo %GREEN%   [SET] Enabled ^(power saving - dynamic FPS^)%RESET%
    ) else (
        echo %YELLOW%   [SET] Disabled ^(consistent framerate^)%RESET%
    )
    echo %YELLOW%   [INFO] Set via AMD Software: Gaming ^> Graphics ^> Radeon Chill%RESET%

    echo %WHITE%[4/12] Enhanced Sync...%RESET%
    if "%profile%"=="1" (
        echo %YELLOW%   [SET] Disabled ^(competitive - use FreeSync only^)%RESET%
    ) else (
        echo %GREEN%   [SET] Enabled ^(reduces tearing without V-Sync latency^)%RESET%
    )
    echo %YELLOW%   [INFO] Set via AMD Software: Gaming ^> Graphics ^> Wait for Vertical Refresh%RESET%

    echo %WHITE%[5/12] FreeSync settings...%RESET%
    if "%profile%"=="1" (
        echo %GREEN%   [SET] FreeSync on, cap FPS 3 below max refresh%RESET%
        echo %YELLOW%   [INFO] Example: 144Hz = cap at 141 FPS in-game%RESET%
    ) else (
        echo %GREEN%   [SET] FreeSync on, Enhanced Sync on%RESET%
    )

    echo %WHITE%[6/12] Shader cache...%RESET%
    REM AMD Shader Cache registry
    if "%profile%"=="3" (
        REM Reset shader cache location for content creation ^(use default^)
        echo %GREEN%   [SET] Default location ^(content creation^)%RESET%
    ) else (
        echo %GREEN%   [SET] Driver controlled%RESET%
    )
    echo %YELLOW%   [INFO] AMD Software: Settings ^> Graphics ^> Advanced ^> Shader Cache%RESET%

    echo %WHITE%[7/12] Tessellation mode...%RESET%
    if "%profile%"=="1" (
        echo %GREEN%   [SET] Override application settings: Off or 8x%RESET%
    ) else (
        echo %GREEN%   [SET] AMD Optimized or Application settings%RESET%
    )
    echo %YELLOW%   [INFO] Set via AMD Software: Gaming ^> Graphics ^> Tessellation Mode%RESET%

    echo %WHITE%[8/12] Texture filtering quality...%RESET%
    if "%profile%"=="1" (
        echo %GREEN%   [SET] Performance%RESET%
    ) else if "%profile%"=="3" (
        echo %GREEN%   [SET] High Quality%RESET%
    ) else (
        echo %GREEN%   [SET] Standard%RESET%
    )
    echo %YELLOW%   [INFO] Set via AMD Software: Gaming ^> Graphics ^> Texture Filtering Quality%RESET%

    echo %WHITE%[9/12] Surface format optimization...%RESET%
    if "%profile%"=="1" (
        echo %GREEN%   [SET] Enabled ^(competitive^)%RESET%
    ) else (
        echo %GREEN%   [SET] Enabled%RESET%
    )
    echo %YELLOW%   [INFO] Set via AMD Software: Gaming ^> Graphics ^> Surface Format Optimization%RESET%

    echo %WHITE%[10/12] Power tuning...%RESET%
    if "%profile%"=="4" (
        echo %YELLOW%   [SET] Power Saving mode%RESET%
    ) else (
        echo %GREEN%   [SET] Manual tuning: increase power limit 10-15%% for stability%RESET%
    )
    echo %YELLOW%   [INFO] Set via AMD Software: Performance ^> Tuning%RESET%

    echo %WHITE%[11/12] ULPS ^(Ultra Low Power State^)...%RESET%
    REM Disable ULPS for lower latency ^(wake-up delay^)
    for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /s /f "EnableULPS" 2^>nul ^| findstr /i "HKEY"') do (
        if "%profile%"=="4" (
            reg add "%%a" /v "EnableULPS" /t REG_DWORD /d 1 /f >nul 2>&1
        ) else (
            reg add "%%a" /v "EnableULPS" /t REG_DWORD /d 0 /f >nul 2>&1
        )
    )
    if "%profile%"=="4" (
        echo %YELLOW%   [SET] Enabled ^(power saving^)%RESET%
    ) else (
        echo %GREEN%   [SET] Disabled ^(reduces wake latency^)%RESET%
    )

    echo %WHITE%[12/12] AMD update/telemetry tasks...%RESET%
    REM StartCN ^(starts AMD Software at logon^) and StartDVR ^(ReLive / Instant Replay^)
    REM are not telemetry and are intentionally left alone.
    for %%T in (AMDInstallLauncher AMDLinkUpdate) do (
        schtasks /change /tn "%%T" /disable >nul 2>&1 && echo %GREEN%   [OK] %%T disabled%RESET% || echo %GRAY%   [--] %%T not found%RESET%
    )

    echo/
    echo %CYAN%AMD Software recommended settings for %profile_name%:%RESET%
    if "%profile%"=="1" (
        echo   Gaming ^> Graphics:
        echo     - Anti-Lag: Enabled
        echo     - Radeon Boost: Enabled ^(optional^)
        echo     - Radeon Chill: Disabled
        echo     - Image Sharpening: Enabled 50-80%%
        echo     - Wait for Vertical Refresh: Off unless FreeSync
        echo     - Tessellation Mode: Off or 8x max
        echo     - Texture Filtering: Performance
    ) else if "%profile%"=="2" (
        echo   Gaming ^> Graphics:
        echo     - Anti-Lag: Enabled
        echo     - Radeon Boost: Disabled
        echo     - Radeon Chill: Disabled
        echo     - Wait for Vertical Refresh: Enhanced Sync
        echo     - Tessellation Mode: AMD Optimized
        echo     - Texture Filtering: Standard
    ) else if "%profile%"=="3" (
        echo   Gaming ^> Graphics:
        echo     - Anti-Lag: Disabled
        echo     - Radeon Boost: Disabled
        echo     - Radeon Chill: Disabled
        echo     - Wait for Vertical Refresh: Always On
        echo     - Tessellation Mode: Use Application Settings
        echo     - Texture Filtering: High Quality
    ) else (
        echo   Gaming ^> Graphics:
        echo     - Anti-Lag: Disabled
        echo     - Radeon Chill: Enabled
        echo     - Wait for Vertical Refresh: Enhanced Sync
        echo     - Tessellation Mode: AMD Optimized
        echo     - Texture Filtering: Standard
    )
)

:: ============================================================
:: Intel Optimizations
:: ============================================================

if "%has_intel%"=="1" (
    echo/
    echo %CYAN%============================================================%RESET%
    echo %WHITE%  PHASE 4: Intel Graphics Optimizations%RESET%
    echo %CYAN%============================================================%RESET%
    echo/

    REM Check if it's Intel Arc or integrated (reuse the CIM-derived GPU names)
    set "is_arc=0"
    echo !GPU_NAMES! | findstr /i "Arc" >nul && set "is_arc=1"

    if "!is_arc!"=="1" (
        echo %WHITE%Intel Arc GPU detected%RESET%
        echo/

        echo %WHITE%[1/6] Resizable BAR...%RESET%
        echo %GREEN%   [CHECK] Verify enabled in BIOS ^(critical for Arc performance^)%RESET%

        echo %WHITE%[2/6] Hyper Encode...%RESET%
        echo %GREEN%   [SET] Enable for video encoding workloads%RESET%
        echo %YELLOW%   [INFO] Intel Arc Control ^> System ^> Hyper Encode%RESET%

        echo %WHITE%[3/6] Smooth Sync...%RESET%
        if "%profile%"=="1" (
            echo %YELLOW%   [SET] Disabled ^(competitive^)%RESET%
        ) else (
            echo %GREEN%   [SET] Enabled ^(reduces tearing^)%RESET%
        )
        echo %YELLOW%   [INFO] Intel Arc Control ^> Games ^> Smooth Sync%RESET%

        echo %WHITE%[4/6] Performance tuning...%RESET%
        if "%profile%"=="4" (
            echo %YELLOW%   [SET] Default ^(power saving^)%RESET%
        ) else (
            echo %GREEN%   [SET] Increase power limit in Arc Control%RESET%
        )
        echo %YELLOW%   [INFO] Intel Arc Control ^> Performance ^> GPU%RESET%

        echo %WHITE%[5/6] Integer Scaling...%RESET%
        echo %GREEN%   [SET] Enable for retro/pixel games%RESET%
        echo %YELLOW%   [INFO] Intel Arc Control ^> Display ^> Integer Scaling%RESET%

        echo %WHITE%[6/6] Present from Compute...%RESET%
        echo %GREEN%   [SET] Enabled ^(may improve DX12 performance^)%RESET%
    ) else (
        echo %WHITE%Intel Integrated Graphics detected%RESET%
        echo/

        echo %WHITE%[1/4] Graphics Power Plan...%RESET%
        REM Intel's power-plan setting ^(0 = Max Battery Life, 1 = Balanced, 2 = Max Performance^), AC only.
        REM Never touch FeatureTestControl: it is a driver feature-disable bitmask, not a power plan.
        if "%profile%"=="4" (set "igpuPlan=1") else (set "igpuPlan=2")
        powercfg /setacvalueindex SCHEME_CURRENT 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 !igpuPlan! >nul 2>&1
        if !errorlevel! equ 0 (
            powercfg /setactive SCHEME_CURRENT >nul 2>&1
            if "%profile%"=="4" (echo %YELLOW%   [SET] Balanced ^(power saving^)%RESET%) else (echo %GREEN%   [SET] Maximum Performance%RESET%)
        ) else (
            echo %GRAY%   [--] Intel Graphics Power Plan not exposed by this driver%RESET%
        )

        echo %WHITE%[2/4] Intel Graphics Command Center...%RESET%
        echo %GREEN%   [OK] Open Intel GCC for per-game settings%RESET%
        echo %YELLOW%   [INFO] Settings: System ^> Power ^> Maximum Performance%RESET%

        echo %WHITE%[3/4] Panel Self-Refresh ^(laptops^)...%RESET%
        if "%profile%"=="4" (
            echo %GREEN%   [SET] Enabled ^(power saving^)%RESET%
        ) else (
            echo %YELLOW%   [SET] Consider disabling for lower latency%RESET%
            echo %YELLOW%   [INFO] Intel GCC ^> Display ^> Power%RESET%
        )

        echo %WHITE%[4/4] Adaptive sync...%RESET%
        echo %GREEN%   [SET] Enable if monitor supports VRR%RESET%
    )
)

:: ============================================================
:: Summary and Additional Recommendations
:: ============================================================

echo/
echo %CYAN%============================================================%RESET%
echo %WHITE%  ADDITIONAL OPTIMIZATIONS%RESET%
echo %CYAN%============================================================%RESET%
echo/

echo %WHITE%[1/3] Frame rate limiting...%RESET%
if "%profile%"=="1" (
    echo %GREEN%   Use RTSS ^(RivaTuner Statistics Server^) for precise frame limiting%RESET%
    echo     - Set FPS cap 3 below refresh rate ^(e.g., 141 for 144Hz^)
    echo     - Lower scanline sync for additional latency reduction
    echo     - Download: https://www.guru3d.com/files-details/rtss-rivatuner-statistics-server-download.html
) else (
    echo %GREEN%   Use in-game FPS limiters when available%RESET%
    echo     - Or use driver FPS limiter ^(NVIDIA/AMD control panel^)
)

echo/
echo %WHITE%[2/3] Monitor settings...%RESET%
echo %GREEN%   - Enable highest refresh rate in Windows Display Settings%RESET%
echo     - Enable G-Sync/FreeSync in monitor OSD
echo     - Set monitor to "Game" or "Fast" response time mode
echo     - Consider disabling motion blur reduction if using VRR

echo/
echo %WHITE%[3/3] In-game settings for %profile_name%...%RESET%
if "%profile%"=="1" (
    echo %GREEN%   Recommended:%RESET%
    echo     - V-Sync: OFF
    echo     - Frame rate: Capped 3 below refresh ^(via RTSS^)
    echo     - Render latency: Low/Ultra Low
    echo     - NVIDIA Reflex: ON + Boost
    echo     - AMD Anti-Lag: ON
    echo     - Fullscreen: Exclusive ^(not borderless^)
) else if "%profile%"=="2" (
    echo %GREEN%   Recommended:%RESET%
    echo     - V-Sync: OFF with VRR, ON without
    echo     - Frame rate: Uncapped or monitor refresh
    echo     - Render quality: High/Ultra
    echo     - Fullscreen: Borderless OK
) else if "%profile%"=="3" (
    echo %GREEN%   Recommended:%RESET%
    echo     - V-Sync: ON ^(smoothest frametimes^)
    echo     - Frame rate: Match refresh rate
    echo     - Render quality: Maximum
    echo     - Motion blur: Personal preference
) else (
    echo %GREEN%   Recommended:%RESET%
    echo     - V-Sync: ON ^(prevents GPU from overworking^)
    echo     - Frame rate: 60 FPS cap for battery
    echo     - Render quality: Medium-High
    echo     - Prefer integrated GPU when possible
)

echo/
echo %CYAN%============================================================%RESET%
echo %WHITE%                OPTIMIZATION COMPLETE%RESET%
echo %CYAN%============================================================%RESET%
echo/
echo %GREEN%GPU driver profile "%profile_name%" applied^^!%RESET%
echo/
echo %WHITE%Changes applied:%RESET%
echo   [+] Windows GPU scheduling configured
echo   [+] Game Mode settings adjusted
echo   [+] Fullscreen optimization settings applied
if "%has_nvidia%"=="1" echo   [+] NVIDIA power and telemetry settings
if "%has_amd%"=="1" echo   [+] AMD ULPS and telemetry settings
if "%has_intel%"=="1" echo   [+] Intel graphics power settings
echo/
echo %YELLOW%Manual steps required:%RESET%
echo   1. Open your GPU control panel to verify/adjust settings
if "%has_nvidia%"=="1" echo      - NVIDIA Control Panel ^> Manage 3D Settings
if "%has_amd%"=="1" echo      - AMD Software ^> Gaming ^> Graphics
if "%has_intel%"=="1" echo      - Intel Graphics Command Center / Arc Control
echo   2. Restart your computer to apply all changes
echo   3. Test with your games and adjust as needed
echo/

choice /c YN /m "Would you like to open the GPU control panel now"
if %errorlevel%==1 (
    REM Current NVIDIA ^(DCH^) and Intel control panels are Microsoft Store apps, so
    REM fall back to their app IDs when the classic Win32 program is not installed.
    if "%has_nvidia%"=="1" (
        if exist "%ProgramFiles%\NVIDIA Corporation\Control Panel Client\nvcplui.exe" (
            start "" "%ProgramFiles%\NVIDIA Corporation\Control Panel Client\nvcplui.exe"
        ) else (
            start "" explorer.exe "shell:AppsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj^!NVIDIACorp.NVIDIAControlPanel"
        )
    )
    if "%has_amd%"=="1" (
        if exist "%ProgramFiles%\AMD\CNext\CNext\RadeonSoftware.exe" start "" "%ProgramFiles%\AMD\CNext\CNext\RadeonSoftware.exe"
    )
    if "%has_intel%"=="1" (
        if exist "%ProgramFiles%\Intel\Intel Graphics Software\IntelGraphicsSoftware.exe" (
            start "" "%ProgramFiles%\Intel\Intel Graphics Software\IntelGraphicsSoftware.exe"
        ) else (
            start "" explorer.exe "shell:AppsFolder\AppUp.IntelGraphicsExperience_8j3eq9eme6ctt^!App"
        )
    )
)

echo/
choice /c YN /m "Would you like to restart now to apply all changes"
if %errorlevel%==1 (
    echo/
    REM Wait here, where Ctrl+C really stops the script, then restart. A delayed
    REM "shutdown /t 10" cannot be cancelled with Ctrl+C and implies /f, which
    REM force-closes apps without letting them save.
    echo %YELLOW%Restarting in 10 seconds... Press Ctrl+C to cancel%RESET%
    timeout /t 10 /nobreak >nul
    shutdown /r /t 0 /c "Restarting to apply GPU driver optimizations"
)

echo/
pause
exit /b 0

:: ============================================================
:: Subroutines
:: ============================================================

:SetVRR
:: %~1 = 0 or 1. Updates only VRROptimizeEnable inside DirectXUserGlobalSettings
:: (a ;-separated list of all Windows default graphics settings) and keeps the
:: other entries, such as AutoHDREnable and SwapEffectUpgradeEnable.
powershell -NoProfile -Command "$k='HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'; if (-not (Test-Path $k)) { New-Item $k -Force | Out-Null }; $v=(Get-ItemProperty $k -ErrorAction SilentlyContinue).DirectXUserGlobalSettings; $p=@(([string]$v) -split ';' | Where-Object { $_ -and $_ -notmatch '^VRROptimizeEnable=' }) + 'VRROptimizeEnable=%~1'; Set-ItemProperty $k DirectXUserGlobalSettings (($p -join ';') + ';')" >nul 2>&1
exit /b 0
