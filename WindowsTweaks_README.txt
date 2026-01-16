================================================================================
 WindowsTweaks.bat - Instructions
================================================================================

DESCRIPTION
-----------
Interactive menu for applying advanced Windows customizations not easily
accessible through normal settings. Includes performance, gaming, UI,
privacy, explorer, network, and input tweaks.


HOW TO USE
----------
1. Right-click WindowsTweaks.bat
2. Select "Run as administrator" (REQUIRED)
3. Choose from the menu:
   [1] Apply ALL Tweaks (Recommended)
   [2] Performance Tweaks
   [3] Gaming Tweaks
   [4] UI / Visual Tweaks
   [5] Privacy Tweaks
   [6] Explorer Tweaks
   [7] Network Tweaks
   [8] Input Tweaks
   [9] Restore Defaults
   [0] Exit
4. Restart your computer after applying tweaks


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Windows Tweaks"
5. Click Create and wait for completion


WHAT EACH CATEGORY DOES
-----------------------

[2] PERFORMANCE TWEAKS
  - Disable SysMain/Superfetch (better for SSDs)
  - Disable Windows Search Indexing (reduces disk usage)
  - Disable Prefetch (better for SSDs)
  - Disable Fast Startup (fixes dual-boot/wake issues)
  - Disable USB selective suspend (prevents USB disconnects)
  - Disable Power Throttling (max performance)
  - NTFS optimizations (disable last access timestamps, 8.3 filenames)

[3] GAMING TWEAKS
  - Disable Game DVR background recording (frees resources)
  - Disable Fullscreen Optimizations (reduces input lag)
  - Enable Hardware-accelerated GPU Scheduling
  - Disable Game Mode (fixes stuttering in some games)
  - Disable HPET and Dynamic Tick
  - Set GPU/CPU priority for games
  - Disable CPU core parking

[4] UI / VISUAL TWEAKS
  - Disable transparency effects
  - Disable window animations
  - Reduce menu delay (snappier menus)
  - Disable Aero Shake (prevents accidental minimize)
  - Show seconds in taskbar clock
  - Restore classic right-click menu (Windows 11)
  - Remove Edge tabs from Alt-Tab
  - Disable startup delay

[5] PRIVACY TWEAKS
  - Disable telemetry
  - Disable Cortana
  - Disable Bing search in Start Menu
  - Disable Activity History
  - Disable advertising ID
  - Disable app launch tracking
  - Disable suggested apps and auto-installs
  - Disable feedback requests
  - Disable location tracking
  - Disable WiFi Sense
  - Disable cloud clipboard sync

[6] EXPLORER TWEAKS
  - Show file extensions
  - Show hidden files
  - Show protected system files
  - Open Explorer to "This PC" instead of Quick Access
  - Disable recent files in Quick Access
  - Disable frequent folders in Quick Access
  - Disable folder type auto-detection (faster loading)
  - Show full path in title bar
  - Disable thumbnail cache
  - Remove "Shortcut" text from new shortcuts
  - Remove 3D Objects from This PC

[7] NETWORK TWEAKS
  - Disable Nagle's Algorithm (reduces latency)
  - Disable network throttling
  - Disable Windows Auto-Tuning
  - Enable Direct Cache Access
  - Optimize DNS priority
  - Disable Large Send Offload

[8] INPUT TWEAKS
  - Disable mouse acceleration (raw input for gaming)
  - Disable Sticky Keys popup
  - Disable Filter Keys popup
  - Disable Toggle Keys popup
  - Set keyboard repeat rate to maximum
  - Disable touch keyboard auto-popup


HOW TO RESTORE / UNDO
---------------------
Option 1: Use Built-in Restore (Easiest)
  1. Run WindowsTweaks.bat as Administrator
  2. Select option [9] Restore Defaults
  3. Restart your computer

Option 2: System Restore
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your "Before Windows Tweaks" restore point
  3. Follow the wizard to restore

Option 3: Manual Reversal (Individual Settings)
  See the specific commands below for each category.


MANUAL REVERSAL COMMANDS
------------------------

Performance:
  sc config "SysMain" start=auto && net start SysMain
  sc config "WSearch" start=delayed-auto && net start WSearch
  powercfg /hibernate on
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 1 /f

Gaming:
  reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f
  reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 1 /f

UI/Visual:
  reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d 1 /f
  reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "400" /f
  reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f  (restore Win11 menu)

Explorer:
  reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 1 /f
  reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 2 /f
  reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 1 /f

Network:
  netsh int tcp set global autotuninglevel=normal

Input:
  reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f
  reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "6" /f
  reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "10" /f


POTENTIAL SIDE EFFECTS
----------------------
- Disabling SysMain: Slightly slower app launch times on HDDs
- Disabling Windows Search: Start menu search may be slower
- Disabling Game Mode: Some games may perform differently
- Disabling mouse acceleration: Muscle memory adjustment needed
- Disabling Auto-Tuning: May affect very high-speed connections


TIPS
----
- Apply all tweaks at once for best results
- Gaming tweaks are especially helpful for competitive games
- Privacy tweaks significantly reduce data collection
- Restart after applying for all changes to take effect
- Run again after major Windows updates
- Some tweaks may be reset by Windows updates
