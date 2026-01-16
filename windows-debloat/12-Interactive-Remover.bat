@echo off
:: ============================================================================
:: Windows 10 Debloat - Interactive Program Remover
:: ============================================================================
:: This script goes through optional Windows programs and features one by one,
:: explains what each does, warns about potential issues, and lets you choose
:: whether to remove each one.
:: ============================================================================

setlocal EnableDelayedExpansion

echo ============================================================================
echo  Windows 10 Debloat - Interactive Program Remover
echo ============================================================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo This script will go through optional Windows programs and features.
echo For each item, you'll see:
echo   - What it is
echo   - Whether removing it may break something
echo   - Option to remove (Y) or skip (N)
echo.
echo TIP: Press Enter to use the default choice shown in [brackets]
echo.
echo Press any key to begin...
pause >nul

set "REMOVED_COUNT=0"
set "SKIPPED_COUNT=0"

echo.
echo ============================================================================
echo  PART 1: Pre-installed Apps (AppX Packages)
echo ============================================================================
echo.

:: -------------------------------------------------------------------------
:: 3D Apps
:: -------------------------------------------------------------------------

call :AskRemoveApp "Microsoft.3DBuilder" "3D Builder" "Create and print 3D models. Rarely used by most people." "No - safe to remove" "N"
call :AskRemoveApp "Microsoft.Microsoft3DViewer" "3D Viewer" "View 3D model files (.fbx, .obj, .3mf, etc)." "No - safe to remove unless you work with 3D files" "N"
call :AskRemoveApp "Microsoft.Print3D" "Print 3D" "Send 3D models to 3D printers." "No - safe to remove unless you have a 3D printer" "N"
call :AskRemoveApp "Microsoft.MixedReality.Portal" "Mixed Reality Portal" "Setup and use Windows Mixed Reality VR headsets." "No - safe to remove unless you have a VR headset" "N"

:: -------------------------------------------------------------------------
:: Bing Apps
:: -------------------------------------------------------------------------

call :AskRemoveApp "Microsoft.BingFinance" "MSN Money (Bing Finance)" "Stock quotes and financial news." "No - safe to remove" "N"
call :AskRemoveApp "Microsoft.BingNews" "MSN News (Bing News)" "News aggregator app." "No - safe to remove" "N"
call :AskRemoveApp "Microsoft.BingSports" "MSN Sports (Bing Sports)" "Sports scores and news." "No - safe to remove" "N"
call :AskRemoveApp "Microsoft.BingWeather" "MSN Weather (Bing Weather)" "Weather forecasts. Taskbar weather widget uses this." "Maybe - taskbar weather widget won't work" "N"

:: -------------------------------------------------------------------------
:: Communication Apps
:: -------------------------------------------------------------------------

call :AskRemoveApp "Microsoft.People" "People" "Contact management app, integrates with Mail and Calendar." "Maybe - Mail app contact suggestions affected" "N"
call :AskRemoveApp "Microsoft.Messaging" "Messaging" "SMS messaging (requires phone link)." "No - safe to remove" "N"
call :AskRemoveApp "Microsoft.SkypeApp" "Skype" "Video calling and messaging." "No - safe to remove if you don't use Skype" "N"
call :AskRemoveApp "Microsoft.YourPhone" "Phone Link (Your Phone)" "Connect Android/iPhone to PC for calls, texts, photos." "No - safe to remove if you don't use this feature" "N"
call :AskRemoveApp "Microsoft.OneConnect" "Mobile Plans (OneConnect)" "Buy mobile data plans (cellular PCs only)." "No - safe to remove" "N"

:: -------------------------------------------------------------------------
:: Entertainment Apps
:: -------------------------------------------------------------------------

call :AskRemoveApp "Microsoft.ZuneMusic" "Groove Music" "Music player app (service discontinued)." "No - safe to remove, use VLC or other player" "N"
call :AskRemoveApp "Microsoft.ZuneVideo" "Movies & TV" "Video player for purchased/rented content." "Maybe - can't play Store purchases without it" "N"
call :AskRemoveApp "Microsoft.MicrosoftSolitaireCollection" "Microsoft Solitaire Collection" "Card games (Solitaire, FreeCell, Spider, etc)." "No - safe to remove" "N"

:: -------------------------------------------------------------------------
:: Microsoft Office Apps
:: -------------------------------------------------------------------------

call :AskRemoveApp "Microsoft.MicrosoftOfficeHub" "Office" "Hub for Office apps and Office 365 subscription." "No - doesn't affect installed Office apps" "N"
call :AskRemoveApp "Microsoft.Office.OneNote" "OneNote (Store version)" "Note-taking app (Store version)." "No - desktop OneNote works separately" "N"

:: -------------------------------------------------------------------------
:: Utilities
:: -------------------------------------------------------------------------

call :AskRemoveApp "Microsoft.WindowsAlarms" "Alarms & Clock" "Alarms, world clock, timer, stopwatch." "No - safe to remove if you don't need it" "N"
call :AskRemoveApp "Microsoft.WindowsCamera" "Camera" "Camera app for webcam and built-in cameras." "Maybe - needed if you use your camera" "Y"
call :AskRemoveApp "Microsoft.WindowsMaps" "Maps" "Offline maps and navigation." "No - safe to remove, use Google Maps in browser" "N"
call :AskRemoveApp "Microsoft.WindowsSoundRecorder" "Voice Recorder" "Simple audio recording app." "No - safe to remove" "N"
call :AskRemoveApp "Microsoft.MSPaint" "Paint 3D" "3D version of Paint (NOT classic mspaint.exe)." "No - classic Paint (mspaint.exe) still works" "N"
call :AskRemoveApp "Microsoft.Wallet" "Microsoft Pay" "Mobile payment wallet (rarely used on desktop)." "No - safe to remove" "N"
call :AskRemoveApp "Microsoft.GetHelp" "Get Help" "Windows help and support app." "No - safe to remove, use web search instead" "N"
call :AskRemoveApp "Microsoft.Getstarted" "Tips" "Windows tips and suggestions." "No - safe to remove" "N"
call :AskRemoveApp "Microsoft.WindowsFeedbackHub" "Feedback Hub" "Send feedback to Microsoft." "No - safe to remove" "N"

:: -------------------------------------------------------------------------
:: Xbox Apps
:: -------------------------------------------------------------------------

echo.
echo --- Xbox Apps (skip all if you play PC games) ---
echo.

call :AskRemoveApp "Microsoft.XboxApp" "Xbox Console Companion" "Manage Xbox profile, friends, achievements." "Maybe - needed for Xbox social features" "N"
call :AskRemoveApp "Microsoft.XboxGameOverlay" "Xbox Game Bar Overlay" "In-game overlay (Win+G) for screenshots, recording." "YES - breaks Game Bar if removed" "Y"
call :AskRemoveApp "Microsoft.XboxGamingOverlay" "Xbox Gaming Overlay" "Additional Game Bar components." "YES - breaks Game Bar if removed" "Y"
call :AskRemoveApp "Microsoft.Xbox.TCUI" "Xbox TCUI" "Xbox text/voice chat UI components." "Maybe - Xbox party chat affected" "N"
call :AskRemoveApp "Microsoft.XboxIdentityProvider" "Xbox Identity Provider" "Xbox Live sign-in for games." "YES - Xbox Live games won't authenticate" "Y"
call :AskRemoveApp "Microsoft.XboxSpeechToTextOverlay" "Xbox Speech to Text" "Voice-to-text in Xbox party chat." "No - safe to remove" "N"

:: -------------------------------------------------------------------------
:: Third-Party Bloatware (may not be installed)
:: -------------------------------------------------------------------------

echo.
echo --- Third-Party Apps (installed by OEM or promotions) ---
echo.

call :AskRemoveApp "*CandyCrush*" "Candy Crush (any version)" "Promotional game." "No - safe to remove" "N"
call :AskRemoveApp "*Facebook*" "Facebook" "Facebook app." "No - safe to remove, use browser" "N"
call :AskRemoveApp "*Twitter*" "Twitter/X" "Twitter app." "No - safe to remove, use browser" "N"
call :AskRemoveApp "*Spotify*" "Spotify" "Music streaming app." "No - safe to remove, reinstall from spotify.com if needed" "N"
call :AskRemoveApp "*Netflix*" "Netflix" "Video streaming app." "No - safe to remove, use browser" "N"
call :AskRemoveApp "*Dolby*" "Dolby Audio" "Audio enhancement software." "Maybe - audio features affected on some devices" "Y"
call :AskRemoveApp "*Disney*" "Disney+" "Video streaming app." "No - safe to remove, use browser" "N"
call :AskRemoveApp "*Amazon*" "Amazon Apps" "Amazon shopping/Prime Video." "No - safe to remove, use browser" "N"
call :AskRemoveApp "*TikTok*" "TikTok" "Video app." "No - safe to remove" "N"
call :AskRemoveApp "*Instagram*" "Instagram" "Photo sharing app." "No - safe to remove, use browser" "N"
call :AskRemoveApp "*LinkedIn*" "LinkedIn" "Professional networking app." "No - safe to remove, use browser" "N"
call :AskRemoveApp "*Pandora*" "Pandora" "Music streaming app." "No - safe to remove" "N"
call :AskRemoveApp "*Fitbit*" "Fitbit" "Fitness tracking app." "No - safe to remove" "N"

:: -------------------------------------------------------------------------
:: Potentially Breaking Apps (ask with caution)
:: -------------------------------------------------------------------------

echo.
echo ============================================================================
echo  CAUTION: The following apps may cause issues if removed
echo ============================================================================
echo.

call :AskRemoveAppCaution "Microsoft.Windows.Photos" "Photos" "Default photo viewer and basic editor." "YES - need alternative viewer (IrfanView, etc)" "Y"
call :AskRemoveAppCaution "Microsoft.WindowsCalculator" "Calculator" "Windows Calculator app." "YES - need alternative calculator" "Y"
call :AskRemoveAppCaution "Microsoft.WindowsStore" "Microsoft Store" "App store for installing UWP apps." "YES - cannot install Store apps anymore" "Y"
call :AskRemoveAppCaution "Microsoft.StorePurchaseApp" "Store Purchase App" "Handles Store purchases and licenses." "YES - breaks Store purchases" "Y"
call :AskRemoveAppCaution "Microsoft.DesktopAppInstaller" "App Installer" "Installs .appx, .msix, and winget packages." "YES - breaks modern app installation" "Y"

echo.
echo ============================================================================
echo  PART 2: Optional Windows Features
echo ============================================================================
echo.

:: -------------------------------------------------------------------------
:: Optional Features (DISM)
:: -------------------------------------------------------------------------

call :AskRemoveFeature "Internet-Explorer-Optional-amd64" "Internet Explorer 11" "Legacy web browser, needed for some old enterprise apps." "Maybe - some old apps/sites require IE" "N"
call :AskRemoveFeature "WindowsMediaPlayer" "Windows Media Player" "Legacy media player." "No - safe to remove, use VLC" "N"
call :AskRemoveFeature "WorkFolders-Client" "Work Folders" "Sync files with corporate servers." "No - safe to remove unless used by your employer" "N"
call :AskRemoveFeature "Printing-XPSServices-Features" "XPS Document Writer" "Print to XPS format (like PDF but less common)." "No - safe to remove" "N"
call :AskRemoveFeature "FaxServicesClientPackage" "Windows Fax and Scan" "Send/receive faxes." "No - safe to remove unless you fax" "N"

echo.
echo --- Security Risk Features (recommended to remove) ---
echo.

call :AskRemoveFeature "SMB1Protocol" "SMB 1.0 Protocol" "Old file sharing protocol with security vulnerabilities." "SECURITY RISK - WannaCry exploit. Remove unless needed for old NAS" "N"
call :AskRemoveFeature "MicrosoftWindowsPowerShellV2Root" "PowerShell 2.0" "Old PowerShell version that bypasses security features." "SECURITY RISK - used to bypass security. Safe to remove" "N"

echo.
echo ============================================================================
echo  Summary
echo ============================================================================
echo.
echo  Items removed: %REMOVED_COUNT%
echo  Items skipped: %SKIPPED_COUNT%
echo.

if %REMOVED_COUNT% gtr 0 (
    echo A restart is recommended to complete all changes.
    echo.
)

echo Press any key to exit...
pause >nul
exit /b 0

:: ============================================================================
:: Functions
:: ============================================================================

:AskRemoveApp
:: %1 = Package name pattern
:: %2 = Friendly name
:: %3 = Description
:: %4 = Will it break anything?
:: %5 = Default choice (Y/N)

set "PKG=%~1"
set "NAME=%~2"
set "DESC=%~3"
set "BREAKS=%~4"
set "DEFAULT=%~5"

:: Check if app is installed
powershell -Command "if (Get-AppxPackage -Name '%PKG%' -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    goto :eof
)

echo ---------------------------------------------------------------------------
echo  %NAME%
echo ---------------------------------------------------------------------------
echo  What it is: %DESC%
echo  Will removing break anything? %BREAKS%
echo.

if /i "%DEFAULT%"=="Y" (
    set /p "CHOICE=  Remove this app? [y/N]: "
) else (
    set /p "CHOICE=  Remove this app? [Y/n]: "
)

if "%CHOICE%"=="" set "CHOICE=%DEFAULT%"

if /i "%CHOICE%"=="Y" (
    echo  Removing %NAME%...
    powershell -Command "Get-AppxPackage -Name '%PKG%' -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue" >nul 2>&1
    powershell -Command "Get-AppxProvisionedPackage -Online | Where-Object DisplayName -Like '%PKG%' | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue" >nul 2>&1
    echo  Removed.
    set /a "REMOVED_COUNT+=1"
) else (
    echo  Skipped.
    set /a "SKIPPED_COUNT+=1"
)
echo.
goto :eof

:AskRemoveAppCaution
:: Same as AskRemoveApp but with warning color/text

set "PKG=%~1"
set "NAME=%~2"
set "DESC=%~3"
set "BREAKS=%~4"
set "DEFAULT=%~5"

:: Check if app is installed
powershell -Command "if (Get-AppxPackage -Name '%PKG%' -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    goto :eof
)

echo ---------------------------------------------------------------------------
echo  *** CAUTION *** %NAME%
echo ---------------------------------------------------------------------------
echo  What it is: %DESC%
echo  Will removing break anything? %BREAKS%
echo.

if /i "%DEFAULT%"=="Y" (
    set /p "CHOICE=  Remove this app? (NOT recommended) [y/N]: "
) else (
    set /p "CHOICE=  Remove this app? (NOT recommended) [y/N]: "
)

if "%CHOICE%"=="" set "CHOICE=N"

if /i "%CHOICE%"=="Y" (
    echo  Removing %NAME%...
    powershell -Command "Get-AppxPackage -Name '%PKG%' -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue" >nul 2>&1
    powershell -Command "Get-AppxProvisionedPackage -Online | Where-Object DisplayName -Like '%PKG%' | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue" >nul 2>&1
    echo  Removed.
    set /a "REMOVED_COUNT+=1"
) else (
    echo  Skipped.
    set /a "SKIPPED_COUNT+=1"
)
echo.
goto :eof

:AskRemoveFeature
:: %1 = Feature name
:: %2 = Friendly name
:: %3 = Description
:: %4 = Will it break anything?
:: %5 = Default choice (Y/N)

set "FEAT=%~1"
set "NAME=%~2"
set "DESC=%~3"
set "BREAKS=%~4"
set "DEFAULT=%~5"

:: Check if feature is enabled
dism /online /Get-FeatureInfo /FeatureName:%FEAT% 2>nul | find "State : Enabled" >nul
if %errorlevel% neq 0 (
    goto :eof
)

echo ---------------------------------------------------------------------------
echo  %NAME%
echo ---------------------------------------------------------------------------
echo  What it is: %DESC%
echo  Will removing break anything? %BREAKS%
echo.

if /i "%DEFAULT%"=="Y" (
    set /p "CHOICE=  Remove this feature? [y/N]: "
) else (
    set /p "CHOICE=  Remove this feature? [Y/n]: "
)

if "%CHOICE%"=="" set "CHOICE=%DEFAULT%"

if /i "%CHOICE%"=="Y" (
    echo  Removing %NAME%... (this may take a moment^)
    dism /online /Disable-Feature /FeatureName:%FEAT% /NoRestart >nul 2>&1
    echo  Removed (restart required to complete^).
    set /a "REMOVED_COUNT+=1"
) else (
    echo  Skipped.
    set /a "SKIPPED_COUNT+=1"
)
echo.
goto :eof
