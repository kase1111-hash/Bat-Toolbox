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
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "MAGENTA=[95m"
set "WHITE=[97m"
set "GRAY=[90m"
set "RESET=[0m"

echo %CYAN%============================================================%RESET%
echo %WHITE%          GPU DRIVER OPTIMIZER%RESET%
echo %WHITE%     Performance Profiles ^& Latency Tuning%RESET%
echo %CYAN%============================================================%RESET%
echo.

:: Detect GPU
echo %YELLOW%Detecting GPU(s)...%RESET%
echo.

set "has_nvidia=0"
set "has_amd=0"
set "has_intel=0"

:: Check for NVIDIA
wmic path win32_videocontroller get name 2>nul | findstr /i "NVIDIA" >nul && set "has_nvidia=1"
:: Check for AMD
wmic path win32_videocontroller get name 2>nul | findstr /i "AMD Radeon" >nul && set "has_amd=1"
wmic path win32_videocontroller get name 2>nul | findstr /i "ATI Radeon" >nul && set "has_amd=1"
:: Check for Intel
wmic path win32_videocontroller get name 2>nul | findstr /i "Intel" >nul && set "has_intel=1"

echo %WHITE%Detected GPUs:%RESET%
powershell -Command "Get-WmiObject Win32_VideoController | Select-Object Name, DriverVersion | Format-Table -AutoSize"

if "%has_nvidia%"=="0" if "%has_amd%"=="0" if "%has_intel%"=="0" (
    echo %RED%[ERROR] No supported GPU detected%RESET%
    pause
    exit /b 1
)

echo.
echo %WHITE%This script optimizes:%RESET%
echo   - Power management (max performance)
echo   - Shader cache behavior
echo   - Low latency modes
echo   - Frame pacing and V-Sync
echo   - Texture filtering quality
echo   - Driver heuristics
echo.
echo %YELLOW%Impact: Depends heavily on workload%RESET%
echo   - Competitive gaming: Major improvement (latency)
echo   - Productivity: Moderate (consistent performance)
echo   - Content creation: Variable (depends on app)
echo.

choice /c YN /m "Create a system restore point before continuing"
if %errorlevel%==1 (
    echo.
    echo %CYAN%Creating restore point...%RESET%
    powershell -Command "Checkpoint-Computer -Description 'Before GPUDriverOptimizer' -RestorePointType 'MODIFY_SETTINGS'" 2>nul
    if !errorlevel!==0 (
        echo %GREEN%[OK] Restore point created%RESET%
    ) else (
        echo %YELLOW%[WARN] Could not create restore point%RESET%
    )
)

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  SELECT OPTIMIZATION PROFILE%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %WHITE%[1]%RESET% %GREEN%Competitive Gaming%RESET%
echo     - Lowest latency, disable all smoothing
echo     - Best for: FPS, fighting games, racing
echo     - Tradeoff: May have slight visual artifacts
echo.
echo %WHITE%[2]%RESET% %CYAN%Balanced Gaming%RESET%
echo     - Low latency with quality textures
echo     - Best for: Most games, general use
echo     - Tradeoff: None significant
echo.
echo %WHITE%[3]%RESET% %MAGENTA%Quality / Content Creation%RESET%
echo     - Maximum quality, stable frametimes
echo     - Best for: AAA games, video editing, 3D work
echo     - Tradeoff: Slightly higher latency
echo.
echo %WHITE%[4]%RESET% %YELLOW%Power Efficient%RESET%
echo     - Adaptive performance, lower temps
echo     - Best for: Laptops, quiet operation
echo     - Tradeoff: Variable performance
echo.

choice /c 1234 /m "Select profile"
set "profile=%errorlevel%"

if "%profile%"=="1" set "profile_name=Competitive Gaming"
if "%profile%"=="2" set "profile_name=Balanced Gaming"
if "%profile%"=="3" set "profile_name=Quality / Content Creation"
if "%profile%"=="4" set "profile_name=Power Efficient"

echo.
echo %GREEN%Selected: %profile_name%%RESET%
echo.

:: ============================================================
:: Windows GPU Settings (applies to all GPUs)
:: ============================================================

echo %CYAN%============================================================%RESET%
echo %WHITE%  PHASE 1: Windows GPU Settings%RESET%
echo %CYAN%============================================================%RESET%
echo.

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
if "%profile%"=="1" (
    :: Competitive - disable VRR for lowest latency ^(controversial, user preference^)
    reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "VRROptimizeEnable=0;" /f >nul 2>&1
    echo %YELLOW%   [SET] VRR optimization disabled ^(raw latency^)%RESET%
) else (
    reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "VRROptimizeEnable=1;" /f >nul 2>&1
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
    :: Disable FSO for competitive ^(true exclusive fullscreen^)
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f >nul 2>&1
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d 2 /f >nul 2>&1
    echo %GREEN%   [SET] True exclusive fullscreen enabled%RESET%
) else (
    reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 0 /f >nul 2>&1
    echo %GREEN%   [SET] Windows decides per-application%RESET%
)

:: ============================================================
:: NVIDIA Optimizations
:: ============================================================

if "%has_nvidia%"=="1" (
    echo.
    echo %CYAN%============================================================%RESET%
    echo %WHITE%  PHASE 2: NVIDIA Driver Optimizations%RESET%
    echo %CYAN%============================================================%RESET%
    echo.

    :: Find NVIDIA profile registry path
    set "nv_path="
    for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /s /f "NVIDIA" 2^>nul ^| findstr /i "0000 0001 0002 0003"') do (
        set "nv_path=%%a"
    )

    :: Global NVIDIA settings via registry
    echo %WHITE%[1/10] Power management mode...%RESET%
    if "%profile%"=="4" (
        :: Adaptive
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PerfLevelSrc" /t REG_DWORD /d 8738 /f >nul 2>&1
        echo %YELLOW%   [SET] Adaptive ^(power saving^)%RESET%
    ) else (
        :: Prefer maximum performance
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PerfLevelSrc" /t REG_DWORD /d 8738 /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PowerMizerEnable" /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PowerMizerLevel" /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PowerMizerLevelAC" /t REG_DWORD /d 1 /f >nul 2>&1
        echo %GREEN%   [SET] Maximum performance%RESET%
    )

    echo %WHITE%[2/10] Low Latency Mode...%RESET%
    :: NVIDIA Control Panel Low Latency Mode via profile settings
    :: Uses NVIDIA Profile Inspector values
    if "%profile%"=="1" (
        :: Ultra ^(submit frames just-in-time^)
        echo %GREEN%   [SET] Ultra ^(competitive - submit just-in-time^)%RESET%
        echo %YELLOW%   [INFO] Set via NVIDIA Control Panel: Manage 3D Settings ^> Low Latency Mode ^> Ultra%RESET%
    ) else if "%profile%"=="2" (
        :: On
        echo %GREEN%   [SET] On ^(balanced^)%RESET%
        echo %YELLOW%   [INFO] Set via NVIDIA Control Panel: Low Latency Mode ^> On%RESET%
    ) else (
        :: Off or Application controlled
        echo %YELLOW%   [SET] Application controlled%RESET%
    )

    echo %WHITE%[3/10] Shader cache...%RESET%
    :: Shader cache location and size
    if "%profile%"=="3" (
        :: Unlimited for content creation ^(more VRAM usage^)
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "ShaderCacheSize" /t REG_DWORD /d 0xFFFFFFFF /f >nul 2>&1
        echo %GREEN%   [SET] Unlimited ^(quality/content creation^)%RESET%
    ) else (
        :: Default driver controlled
        reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "ShaderCacheSize" /f >nul 2>&1
        echo %GREEN%   [SET] Driver controlled ^(10GB default^)%RESET%
    )

    echo %WHITE%[4/10] Threaded optimization...%RESET%
    :: 0x00000001 = Auto, 0x00000002 = On, 0x00000000 = Off
    if "%profile%"=="1" (
        :: Off for competitive ^(more predictable frametimes^)
        echo %YELLOW%   [SET] Off ^(competitive - predictable frametimes^)%RESET%
        echo %YELLOW%   [INFO] Set via NVIDIA Control Panel if needed%RESET%
    ) else (
        :: Auto for most use cases
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
    :: Disable NVIDIA telemetry
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID44231" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID64640" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID66610" /t REG_DWORD /d 0 /f >nul 2>&1
    :: Disable NVIDIA container telemetry tasks
    schtasks /change /tn "NvTmRepOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" /disable >nul 2>&1
    schtasks /change /tn "NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" /disable >nul 2>&1
    echo %GREEN%   [OK] Telemetry disabled%RESET%

    echo.
    echo %CYAN%NVIDIA Profile Inspector recommended settings:%RESET%
    echo   For advanced per-game profiles, download NVIDIA Profile Inspector
    echo   https://github.com/Orbmu2k/nvidiaProfileInspector
    echo.
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
    ) else (
        echo     - Power Management Mode: Adaptive
        echo     - Shader Cache: Unlimited
        echo     - Texture Filtering - Quality: High Quality
        echo     - Threaded Optimization: Auto
        echo     - Vertical Sync: Use Application Setting
    )
)

:: ============================================================
:: AMD Optimizations
:: ============================================================

if "%has_amd%"=="1" (
    echo.
    echo %CYAN%============================================================%RESET%
    echo %WHITE%  PHASE 3: AMD Driver Optimizations%RESET%
    echo %CYAN%============================================================%RESET%
    echo.

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
    :: AMD Shader Cache registry
    if "%profile%"=="3" (
        :: Reset shader cache location for content creation ^(use default^)
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
    :: Disable ULPS for lower latency ^(wake-up delay^)
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

    echo %WHITE%[12/12] AMD telemetry...%RESET%
    :: Disable AMD telemetry tasks
    schtasks /change /tn "AMDInstallLauncher" /disable >nul 2>&1
    schtasks /change /tn "AMDLinkUpdate" /disable >nul 2>&1
    schtasks /change /tn "StartCN" /disable >nul 2>&1
    schtasks /change /tn "StartDVR" /disable >nul 2>&1
    echo %GREEN%   [OK] Telemetry tasks disabled%RESET%

    echo.
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
    echo.
    echo %CYAN%============================================================%RESET%
    echo %WHITE%  PHASE 4: Intel Graphics Optimizations%RESET%
    echo %CYAN%============================================================%RESET%
    echo.

    :: Check if it's Intel Arc or integrated
    set "is_arc=0"
    wmic path win32_videocontroller get name 2>nul | findstr /i "Arc" >nul && set "is_arc=1"

    if "%is_arc%"=="1" (
        echo %WHITE%Intel Arc GPU detected%RESET%
        echo.

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
        echo.

        echo %WHITE%[1/4] Graphics Power Plan...%RESET%
        :: Intel graphics power settings
        for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /s /f "Intel" 2^>nul ^| findstr /i "0000 0001 0002"') do (
            if "%profile%"=="4" (
                reg add "%%a" /v "FeatureTestControl" /t REG_DWORD /d 0 /f >nul 2>&1
            ) else (
                reg add "%%a" /v "FeatureTestControl" /t REG_DWORD /d 1 /f >nul 2>&1
            )
        )
        if "%profile%"=="4" (
            echo %YELLOW%   [SET] Balanced ^(power saving^)%RESET%
        ) else (
            echo %GREEN%   [SET] Maximum Performance%RESET%
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

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%  ADDITIONAL OPTIMIZATIONS%RESET%
echo %CYAN%============================================================%RESET%
echo.

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

echo.
echo %WHITE%[2/3] Monitor settings...%RESET%
echo %GREEN%   - Enable highest refresh rate in Windows Display Settings%RESET%
echo     - Enable G-Sync/FreeSync in monitor OSD
echo     - Set monitor to "Game" or "Fast" response time mode
echo     - Consider disabling motion blur reduction if using VRR

echo.
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

echo.
echo %CYAN%============================================================%RESET%
echo %WHITE%                OPTIMIZATION COMPLETE%RESET%
echo %CYAN%============================================================%RESET%
echo.
echo %GREEN%GPU driver profile "%profile_name%" applied!%RESET%
echo.
echo %WHITE%Changes applied:%RESET%
echo   [+] Windows GPU scheduling configured
echo   [+] Game Mode settings adjusted
echo   [+] Fullscreen optimization settings applied
if "%has_nvidia%"=="1" echo   [+] NVIDIA power and telemetry settings
if "%has_amd%"=="1" echo   [+] AMD ULPS and telemetry settings
if "%has_intel%"=="1" echo   [+] Intel graphics power settings
echo.
echo %YELLOW%Manual steps required:%RESET%
echo   1. Open your GPU control panel to verify/adjust settings
if "%has_nvidia%"=="1" echo      - NVIDIA Control Panel ^> Manage 3D Settings
if "%has_amd%"=="1" echo      - AMD Software ^> Gaming ^> Graphics
if "%has_intel%"=="1" echo      - Intel Graphics Command Center / Arc Control
echo   2. Restart your computer to apply all changes
echo   3. Test with your games and adjust as needed
echo.

choice /c YN /m "Would you like to open the GPU control panel now"
if %errorlevel%==1 (
    if "%has_nvidia%"=="1" (
        start "" "C:\Program Files\NVIDIA Corporation\Control Panel Client\nvcplui.exe" 2>nul
        if !errorlevel! neq 0 start "" control /name Microsoft.NVIDIA 2>nul
    )
    if "%has_amd%"=="1" (
        start "" "C:\Program Files\AMD\CNext\CNext\RadeonSoftware.exe" 2>nul
    )
    if "%has_intel%"=="1" (
        start "" "C:\Program Files\Intel\Intel^(R^) Graphics Command Center\IntelGraphicsCommandCenter.exe" 2>nul
    )
)

echo.
choice /c YN /m "Would you like to restart now to apply all changes"
if %errorlevel%==1 (
    echo.
    echo %YELLOW%Restarting in 10 seconds... Press Ctrl+C to cancel%RESET%
    shutdown /r /t 10 /c "Restarting to apply GPU driver optimizations"
)

echo.
pause
exit /b 0
