@echo off
REM ============================================================================
REM  REMOVE_STORE.BAT
REM  Disables and removes Microsoft Store and related components.
REM
REM  PREREQUISITES:
REM    1. Run as Administrator (right-click > Run as administrator)
REM    2. Reboot after running
REM
REM  WHAT THIS DOES:
REM    - Disables Microsoft Store via Group Policy registry keys
REM    - Removes the Store app package for current user and all users
REM    - Removes Store-related background services and tasks
REM    - Disables automatic app updates and silent installs
REM    - Removes Store purchase/licensing service
REM    - Removes companion apps that depend on the Store
REM    - Disables content delivery (the thing that reinstalls Candy Crush)
REM
REM  WHAT THIS DOES NOT DO:
REM    - Does not break sideloaded .appx/.msix packages
REM    - Does not remove apps already installed (run winget or PowerShell
REM      separately to remove individual UWP apps you don't want)
REM
REM  TO REVERSE:
REM    Delete the policy keys added here, re-enable services,
REM    then run: wsreset.exe
REM    Or reinstall Store via PowerShell:
REM      Get-AppxPackage -AllUsers Microsoft.WindowsStore | 
REM        Foreach {Add-AppxPackage -Register "$($_.InstallLocation)\AppxManifest.xml" -DisableDevelopmentMode}
REM
REM  Author: Kase Branham / True North Construction LLC
REM  License: Public Domain
REM ============================================================================

REM --- Check for admin privileges ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ============================================
    echo  ERROR: This script must be run as Administrator.
    echo  Right-click the file and select "Run as administrator"
    echo ============================================
    pause
    exit /b 1
)

echo ============================================================================
echo  REMOVE_STORE.BAT - Microsoft Store Removal Script
echo ============================================================================
echo/
echo  This will disable and remove the Microsoft Store and related services.
echo  Press Ctrl+C to abort, or...
pause

echo/
echo [1/7] Disabling Microsoft Store via policy...
echo ----------------------------------------------

REM -- RemoveWindowsStore: The main policy kill switch --
REM This prevents the Store from launching even if the package exists.
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /t REG_DWORD /d 1 /f

REM -- DisableStoreApps: Prevents all Store app execution --
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 1 /f

REM -- AutoDownload: Disable automatic app updates from Store --
REM   2 = Never auto-download. Stops Store from pulling updates silently.
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f

REM -- Disable Store offer to update to latest OS --
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableOSUpgrade /t REG_DWORD /d 1 /f

echo/
echo [2/7] Disabling silent app installs and content delivery...
echo -----------------------------------------------------------

REM -- ContentDeliveryManager: This is the system that silently installs --
REM -- Candy Crush, Disney+, TikTok, Spotify, and other junk you never asked for. --
REM -- Every one of these keys stops a different vector of unwanted installs. --

reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEverEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v FeatureManagementEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContentEnabled /t REG_DWORD /d 0 /f

REM -- Disable "Suggested" apps in Start Menu --
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-310093Enabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338393Enabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f

echo/
echo [3/7] Disabling Store services...
echo ----------------------------------

REM -- PushToInstall: Allows remote-triggered installs from the Store website --
REM -- (i.e., click "Install" on a webpage and it pushes to your PC) --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\PushToInstall" /v Start /t REG_DWORD /d 4 /f

REM -- InstallService: Windows Store Install Service --
REM -- Handles package deployment from the Store --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\InstallService" /v Start /t REG_DWORD /d 4 /f

REM -- WSService: Windows Store licensing and purchase service --
REM -- Validates Store licenses and manages purchases --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WSService" /v Start /t REG_DWORD /d 4 /f

REM -- wlidsvc: Microsoft Account Sign-in Assistant --
REM -- Used by Store for authentication. Disabling this also prevents --
REM -- Microsoft account sign-in prompts elsewhere. --
REM -- CAUTION: If you use a Microsoft account to log in, skip this line. --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wlidsvc" /v Start /t REG_DWORD /d 4 /f

REM -- AppXSvc: AppX Deployment Service --
REM -- Needed for installing/updating UWP apps. Disable only if you --
REM -- don't plan to sideload any .appx packages. --
REM -- Uncomment the line below ONLY if you want full UWP lockdown: --
REM reg add "HKLM\SYSTEM\CurrentControlSet\Services\AppXSvc" /v Start /t REG_DWORD /d 4 /f

REM -- ClipSVC: Client License Service --
REM -- Manages Store-bought app licenses. Safe to disable if no Store apps. --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\ClipSVC" /v Start /t REG_DWORD /d 4 /f

echo/
echo [4/7] Disabling Store-related scheduled tasks...
echo -------------------------------------------------

REM -- These tasks handle background Store updates and maintenance --
schtasks /Change /TN "Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\InstallService\ScanForUpdates" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\InstallService\ScanForUpdatesAsUser" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\InstallService\SmartRetry" /Disable >nul 2>&1

echo/
echo [5/7] Removing Microsoft Store app packages...
echo -----------------------------------------------

REM -- Remove Store for current user --
echo   Removing Microsoft Store (current user)...
PowerShell -NoProfile -Command "Get-AppxPackage *WindowsStore* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

REM -- Remove Store for all users (prevents it appearing for new accounts) --
echo   Removing Microsoft Store (all users / provisioned)...
PowerShell -NoProfile -Command "Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like '*WindowsStore*'} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue" >nul 2>&1

REM -- Remove Store Purchase App --
echo   Removing Store Purchase App...
PowerShell -NoProfile -Command "Get-AppxPackage *StorePurchaseApp* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like '*StorePurchaseApp*'} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue" >nul 2>&1

echo/
echo [6/7] Removing Store-dependent bloatware...
echo ---------------------------------------------

REM -- These apps serve no purpose without the Store and are typically --
REM -- unwanted. Each line removes for current user and deprovisioned. --
REM -- Comment out any you actually want to keep. --

echo   Removing Xbox components...
PowerShell -NoProfile -Command "Get-AppxPackage *Xbox* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like '*Xbox*'} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue" >nul 2>&1

echo   Removing Bing apps (News, Weather, Finance, Sports)...
PowerShell -NoProfile -Command "Get-AppxPackage *BingNews* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *BingWeather* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *BingFinance* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *BingSports* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

echo   Removing Zune (Groove Music / Movies ^& TV)...
PowerShell -NoProfile -Command "Get-AppxPackage *ZuneMusic* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *ZuneVideo* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

echo   Removing Microsoft People, Maps, Messaging...
PowerShell -NoProfile -Command "Get-AppxPackage *People* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *WindowsMaps* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *Messaging* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

echo   Removing Solitaire, Candy Crush, and other promoted apps...
PowerShell -NoProfile -Command "Get-AppxPackage *Solitaire* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *CandyCrush* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *Disney* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *Spotify* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *TikTok* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *Facebook* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *Instagram* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *Twitter* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

echo   Removing Clipchamp, Microsoft To Do, Power Automate...
PowerShell -NoProfile -Command "Get-AppxPackage *Clipchamp* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *Todos* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *PowerAutomate* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

echo   Removing Microsoft Teams (consumer)...
PowerShell -NoProfile -Command "Get-AppxPackage *MicrosoftTeams* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

echo   Removing Feedback Hub, Get Help, Tips...
PowerShell -NoProfile -Command "Get-AppxPackage *WindowsFeedbackHub* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *GetHelp* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1
PowerShell -NoProfile -Command "Get-AppxPackage *Getstarted* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

echo   Removing Microsoft Copilot...
PowerShell -NoProfile -Command "Get-AppxPackage *Copilot* | Remove-AppxPackage -ErrorAction SilentlyContinue" >nul 2>&1

echo/
echo [7/7] Blocking Store reinstallation via Windows Update...
echo ----------------------------------------------------------

REM -- Prevent Windows Update from reinstalling Store apps --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableSoftLanding /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableCloudOptimizedContent /t REG_DWORD /d 1 /f

REM -- Disable app suggestions and "tips" --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /t REG_DWORD /d 1 /f

echo/
echo ============================================================================
echo  DONE. Microsoft Store and related components have been removed/disabled.
echo ============================================================================
echo/
echo  NEXT STEPS:
echo    1. REBOOT your machine.
echo    2. After reboot, verify Store is gone:
echo       - Search for "Microsoft Store" in Start - should not appear
echo       - Check Services (services.msc) for disabled Store services
echo    3. If bloatware returns after a feature update, re-run this script.
echo/
echo  TO SEE WHAT UWP APPS REMAIN (run in PowerShell):
echo    Get-AppxPackage ^| Select Name ^| Sort Name
echo/
echo  TO REVERSE:
echo    Run in PowerShell as Admin:
echo      Get-AppxPackage -AllUsers Microsoft.WindowsStore ^| ForEach
echo        {Add-AppxPackage -Register "$($_.InstallLocation)\AppxManifest.xml"
echo         -DisableDevelopmentMode}
echo    Then run: wsreset.exe
echo/
pause
