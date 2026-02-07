@echo off
setlocal enabledelayedexpansion
title Windows Power User Tweaks
color 0B

:: ============================================================================
:: Windows Power User Tweaks
:: ============================================================================
:: Advanced Windows customizations not easily accessible through settings.
:: Includes performance, gaming, UI, privacy, and Explorer tweaks.
:: ============================================================================

echo ============================================================================
echo  Windows Power User Tweaks
echo ============================================================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo [ERROR] This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

:MENU
cls
echo ============================================================================
echo  Windows Power User Tweaks - Main Menu
echo ============================================================================
echo.
echo  [1] Apply ALL Tweaks [Recommended]
echo.
echo  Individual Categories:
echo  [2] Performance Tweaks
echo  [3] Gaming Tweaks
echo  [4] UI / Visual Tweaks
echo  [5] Privacy Tweaks
echo  [6] Explorer Tweaks
echo  [7] Network Tweaks
echo  [8] Input Tweaks
echo.
echo  [9] Restore Defaults
echo  [0] Exit
echo.
echo ============================================================================
set /p "choice=Select an option [0-9]: "

if "%choice%"=="1" goto ALL_TWEAKS
if "%choice%"=="2" goto PERFORMANCE
if "%choice%"=="3" goto GAMING
if "%choice%"=="4" goto UI_VISUAL
if "%choice%"=="5" goto PRIVACY
if "%choice%"=="6" goto EXPLORER
if "%choice%"=="7" goto NETWORK
if "%choice%"=="8" goto INPUT
if "%choice%"=="9" goto RESTORE
if "%choice%"=="0" goto EXIT
goto MENU

:: ============================================================================
:: ALL TWEAKS
:: ============================================================================
:ALL_TWEAKS
cls
echo ============================================================================
echo  Applying All Tweaks
echo ============================================================================
echo.
echo This will apply all performance, gaming, UI, privacy, explorer, network,
echo and input tweaks. Some changes require a restart to take effect.
echo.
set /p "confirm=Continue? [Y/N]: "
if /i not "%confirm%"=="Y" goto MENU

call :DO_PERFORMANCE
call :DO_GAMING
call :DO_UI_VISUAL
call :DO_PRIVACY
call :DO_EXPLORER
call :DO_NETWORK
call :DO_INPUT

echo.
echo ============================================================================
echo  All tweaks applied! Restart recommended.
echo ============================================================================
pause
goto MENU

:: ============================================================================
:: PERFORMANCE TWEAKS
:: ============================================================================
:PERFORMANCE
cls
echo ============================================================================
echo  Performance Tweaks
echo ============================================================================
echo.
call :DO_PERFORMANCE
pause
goto MENU

:DO_PERFORMANCE
echo [PERFORMANCE] Applying performance tweaks...
echo.

:: Disable SysMain/Superfetch (better for SSDs)
echo   - Disabling SysMain/Superfetch [improves SSD lifespan]...
sc config "SysMain" start= disabled >nul 2>&1
sc stop "SysMain" >nul 2>&1

:: Disable Windows Search Indexing
echo   - Disabling Windows Search Indexing [reduces disk usage]...
sc config "WSearch" start= disabled >nul 2>&1
sc stop "WSearch" >nul 2>&1

:: Disable Prefetch
echo   - Disabling Prefetch [better for SSDs]...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable Fast Startup (can cause issues with dual boot and updates)
echo   - Disabling Fast Startup [fixes dual-boot and wake issues]...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable hibernation (saves disk space)
echo   - Disabling Hibernation [saves disk space]...
powercfg /hibernate off >nul 2>&1

:: Disable USB selective suspend
echo   - Disabling USB Selective Suspend [prevents USB disconnects]...
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1

:: Disable Power Throttling
echo   - Disabling Power Throttling [max performance]...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f >nul 2>&1

:: Set processor performance to 100%
echo   - Setting processor to 100%% performance...
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1
powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1

:: Disable NTFS last access time stamp
echo   - Disabling NTFS Last Access timestamps [reduces disk writes]...
fsutil behavior set disablelastaccess 1 >nul 2>&1

:: Increase NTFS memory usage
echo   - Optimizing NTFS memory usage...
fsutil behavior set memoryusage 2 >nul 2>&1

:: Disable 8.3 filename creation
echo   - Disabling 8.3 filename creation [improves NTFS performance]...
fsutil behavior set disable8dot3 1 >nul 2>&1

:: Optimize memory for programs (0) rather than system cache (1)
echo   - Optimizing memory management for programs...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 0 /f >nul 2>&1

echo.
echo [PERFORMANCE] Performance tweaks applied.
echo.
goto :eof

:: ============================================================================
:: GAMING TWEAKS
:: ============================================================================
:GAMING
cls
echo ============================================================================
echo  Gaming Tweaks
echo ============================================================================
echo.
call :DO_GAMING
pause
goto MENU

:DO_GAMING
echo [GAMING] Applying gaming tweaks...
echo.

:: Disable Game DVR and Game Bar background recording
echo   - Disabling Game DVR background recording [frees resources]...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable fullscreen optimizations globally
echo   - Disabling Fullscreen Optimizations [reduces input lag]...
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 1 /f >nul 2>&1

:: Enable Hardware-accelerated GPU scheduling
echo   - Enabling Hardware-accelerated GPU Scheduling...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul 2>&1

:: Disable Game Mode (can cause issues in some games)
echo   - Disabling Game Mode [fixes stuttering in some games]...
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable HPET (can improve performance in some systems)
echo   - Disabling HPET [may improve game performance]...
bcdedit /deletevalue useplatformclock >nul 2>&1

:: Disable dynamic tick
echo   - Disabling Dynamic Tick [more consistent timing]...
bcdedit /set disabledynamictick yes >nul 2>&1

:: Set GPU priority to high for gaming
echo   - Setting GPU priority to high...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1

:: Disable CPU core parking
echo   - Disabling CPU Core Parking [all cores active]...
powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 >nul 2>&1
powercfg -setactive scheme_current >nul 2>&1

:: Set system responsiveness
echo   - Setting system responsiveness for gaming...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xffffffff /f >nul 2>&1

echo.
echo [GAMING] Gaming tweaks applied.
echo.
goto :eof

:: ============================================================================
:: UI / VISUAL TWEAKS
:: ============================================================================
:UI_VISUAL
cls
echo ============================================================================
echo  UI / Visual Tweaks
echo ============================================================================
echo.
call :DO_UI_VISUAL
pause
goto MENU

:DO_UI_VISUAL
echo [UI] Applying visual tweaks...
echo.

:: Disable transparency
echo   - Disabling transparency effects [improves performance]...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable animations
echo   - Disabling window animations [faster UI]...
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul 2>&1

:: Reduce menu show delay
echo   - Reducing menu delay [snappier menus]...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f >nul 2>&1

:: Disable Aero Shake (shake to minimize)
echo   - Disabling Aero Shake [prevents accidental minimize]...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable Snap Assist suggestions
echo   - Disabling Snap Assist suggestions...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SnapAssist" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable window border padding
echo   - Reducing window border padding...
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "PaddedBorderWidth" /t REG_SZ /d "0" /f >nul 2>&1

:: Show seconds in system clock
echo   - Showing seconds in taskbar clock...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSecondsInSystemClock" /t REG_DWORD /d 1 /f >nul 2>&1

:: Windows 11: Restore old right-click context menu
echo   - Restoring classic right-click menu [Windows 11]...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul 2>&1

:: Disable Edge tabs in Alt-Tab
echo   - Removing Edge tabs from Alt-Tab...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "MultiTaskingAltTabFilter" /t REG_DWORD /d 3 /f >nul 2>&1

:: Disable startup delay
echo   - Disabling startup delay...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable tips and suggestions
echo   - Disabling Windows tips and suggestions...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable lock screen tips
echo   - Disabling lock screen tips...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338387Enabled" /t REG_DWORD /d 0 /f >nul 2>&1

echo.
echo [UI] Visual tweaks applied.
echo.
goto :eof

:: ============================================================================
:: PRIVACY TWEAKS
:: ============================================================================
:PRIVACY
cls
echo ============================================================================
echo  Privacy Tweaks
echo ============================================================================
echo.
call :DO_PRIVACY
pause
goto MENU

:DO_PRIVACY
echo [PRIVACY] Applying privacy tweaks...
echo.

:: Disable telemetry
echo   - Disabling telemetry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable Cortana
echo   - Disabling Cortana...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable Bing search in Start Menu
echo   - Disabling Bing search in Start Menu...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable Activity History
echo   - Disabling Activity History...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable advertising ID
echo   - Disabling advertising ID...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable app launch tracking
echo   - Disabling app launch tracking...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable suggested apps
echo   - Disabling suggested apps and auto-installs...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable feedback notifications
echo   - Disabling feedback requests...
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "PeriodInNanoSeconds" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable location tracking
echo   - Disabling location tracking...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable WiFi Sense
echo   - Disabling WiFi Sense...
reg add "HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" /v "AutoConnectAllowedOEM" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable cloud clipboard
echo   - Disabling cloud clipboard sync...
reg add "HKCU\SOFTWARE\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowCrossDeviceClipboard" /t REG_DWORD /d 0 /f >nul 2>&1

echo.
echo [PRIVACY] Privacy tweaks applied.
echo.
goto :eof

:: ============================================================================
:: EXPLORER TWEAKS
:: ============================================================================
:EXPLORER
cls
echo ============================================================================
echo  Explorer Tweaks
echo ============================================================================
echo.
call :DO_EXPLORER
pause
goto MENU

:DO_EXPLORER
echo [EXPLORER] Applying Explorer tweaks...
echo.

:: Show file extensions
echo   - Showing file extensions...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul 2>&1

:: Show hidden files
echo   - Showing hidden files...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 1 /f >nul 2>&1

:: Show system files
echo   - Showing protected system files...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSuperHidden" /t REG_DWORD /d 1 /f >nul 2>&1

:: Open to This PC instead of Quick Access
echo   - Opening Explorer to This PC...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable recent files in Quick Access
echo   - Disabling recent files in Quick Access...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable frequent folders in Quick Access
echo   - Disabling frequent folders in Quick Access...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable folder type auto-detection (faster folder loading)
echo   - Disabling folder type auto-detection [faster loading]...
reg delete "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v "FolderType" /t REG_SZ /d "NotSpecified" /f >nul 2>&1

:: Expand navigation pane to current folder
echo   - Expanding navigation pane to current folder...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "NavPaneExpandToCurrentFolder" /t REG_DWORD /d 1 /f >nul 2>&1

:: Show full path in title bar
echo   - Showing full path in title bar...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v "FullPath" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable thumbnail cache
echo   - Disabling thumbnail cache [prevents thumbs.db files]...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisableThumbnailCache" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "DisableThumbsDBOnNetworkFolders" /t REG_DWORD /d 1 /f >nul 2>&1

:: Disable shortcut text
echo   - Removing 'Shortcut' text from new shortcuts...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "link" /t REG_BINARY /d 00000000 /f >nul 2>&1

:: Remove 3D Objects from This PC
echo   - Removing 3D Objects from This PC...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" /f >nul 2>&1

echo.
echo [EXPLORER] Explorer tweaks applied.
echo.
goto :eof

:: ============================================================================
:: NETWORK TWEAKS
:: ============================================================================
:NETWORK
cls
echo ============================================================================
echo  Network Tweaks
echo ============================================================================
echo.
call :DO_NETWORK
pause
goto MENU

:DO_NETWORK
echo [NETWORK] Applying network tweaks...
echo.

:: Disable Nagle's algorithm (reduces latency)
echo   - Disabling Nagle's Algorithm [reduces latency]...
for /f "tokens=3*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s /v IPAddress 2^>nul ^| findstr /i "IPAddress"') do (
    for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s 2^>nul ^| findstr /i "HKEY"') do (
        reg add "%%k" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "%%k" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
    )
)

:: Disable network throttling
echo   - Disabling network throttling...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xffffffff /f >nul 2>&1

:: Disable auto-tuning (can cause issues with some routers)
echo   - Disabling Windows Auto-Tuning [fixes some router issues]...
netsh int tcp set global autotuninglevel=disabled >nul 2>&1

:: Enable Direct Cache Access
echo   - Enabling Direct Cache Access...
netsh int tcp set global dca=enabled >nul 2>&1

:: Disable RSS (Receive Side Scaling) on older systems
echo   - Optimizing TCP settings...
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1

:: Set DNS priority
echo   - Optimizing DNS priority...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "LocalPriority" /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "HostsPriority" /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "DnsPriority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "NetbtPriority" /t REG_DWORD /d 7 /f >nul 2>&1

:: Disable Large Send Offload
echo   - Disabling Large Send Offload...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DisableTaskOffload" /t REG_DWORD /d 1 /f >nul 2>&1

echo.
echo [NETWORK] Network tweaks applied.
echo.
goto :eof

:: ============================================================================
:: INPUT TWEAKS
:: ============================================================================
:INPUT
cls
echo ============================================================================
echo  Input Tweaks
echo ============================================================================
echo.
call :DO_INPUT
pause
goto MENU

:DO_INPUT
echo [INPUT] Applying input tweaks...
echo.

:: Disable mouse acceleration
echo   - Disabling mouse acceleration [raw input]...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul 2>&1

:: Enable enhanced pointer precision OFF
reg add "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f >nul 2>&1

:: Disable Sticky Keys popup
echo   - Disabling Sticky Keys popup...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f >nul 2>&1

:: Disable Filter Keys popup
echo   - Disabling Filter Keys popup...
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f >nul 2>&1

:: Disable Toggle Keys popup
echo   - Disabling Toggle Keys popup...
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "58" /f >nul 2>&1

:: Set keyboard repeat rate to max
echo   - Setting keyboard repeat rate to maximum...
reg add "HKCU\Control Panel\Keyboard" /v "KeyboardDelay" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v "KeyboardSpeed" /t REG_SZ /d "31" /f >nul 2>&1

:: Disable touch keyboard
echo   - Disabling touch keyboard auto-popup...
reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "TipbandDesiredVisibility" /t REG_DWORD /d 0 /f >nul 2>&1

echo.
echo [INPUT] Input tweaks applied.
echo.
goto :eof

:: ============================================================================
:: RESTORE DEFAULTS
:: ============================================================================
:RESTORE
cls
echo ============================================================================
echo  Restore Defaults
echo ============================================================================
echo.
echo This will attempt to restore Windows default settings.
echo Note: Some changes may require a fresh Windows install to fully reverse.
echo.
set /p "confirm=Continue? [Y/N]: "
if /i not "%confirm%"=="Y" goto MENU

echo.
echo Restoring defaults...
echo.

:: Re-enable services
echo   - Re-enabling SysMain...
sc config "SysMain" start= auto >nul 2>&1
sc start "SysMain" >nul 2>&1

echo   - Re-enabling Windows Search...
sc config "WSearch" start= delayed-auto >nul 2>&1
sc start "WSearch" >nul 2>&1

:: Re-enable Fast Startup
echo   - Re-enabling Fast Startup...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 1 /f >nul 2>&1

:: Re-enable Game DVR
echo   - Re-enabling Game DVR...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 1 /f >nul 2>&1

:: Re-enable transparency
echo   - Re-enabling transparency...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 1 /f >nul 2>&1

:: Re-enable animations
echo   - Re-enabling animations...
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "1" /f >nul 2>&1

:: Restore menu delay
echo   - Restoring menu delay...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "400" /f >nul 2>&1

:: Restore Explorer defaults
echo   - Restoring Explorer defaults...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 1 /f >nul 2>&1

:: Restore Windows 11 context menu
echo   - Restoring Windows 11 context menu...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1

:: Restore mouse acceleration
echo   - Restoring mouse acceleration...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "6" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "10" /f >nul 2>&1

:: Restore network auto-tuning
echo   - Restoring network auto-tuning...
netsh int tcp set global autotuninglevel=normal >nul 2>&1

echo.
echo ============================================================================
echo  Defaults restored! Restart recommended.
echo ============================================================================
pause
goto MENU

:: ============================================================================
:: EXIT
:: ============================================================================
:EXIT
echo.
echo Refreshing Explorer to apply changes...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
echo.
echo Thank you for using Windows Power User Tweaks!
echo A restart is recommended to apply all changes.
echo.
pause
exit /b 0
