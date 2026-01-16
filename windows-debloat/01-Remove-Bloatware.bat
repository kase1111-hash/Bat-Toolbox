@echo off
:: ============================================================================
:: Windows 10 Debloat - Remove Pre-Built Apps (AppX Packages)
:: ============================================================================
:: This script removes bloatware apps that come pre-installed with Windows 10.
:: These are generally safe to remove and won't break core Windows functionality.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Remove Bloatware Apps
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

echo This script will remove the following types of apps:
echo  - 3D Builder, 3D Viewer, Mixed Reality Portal
echo  - Bing Finance, News, Sports, Weather
echo  - Microsoft Solitaire, Office Hub, OneNote
echo  - Skype, People, Messaging, Your Phone
echo  - Xbox apps (if you don't game on PC)
echo  - Groove Music, Movies ^& TV (Zune apps)
echo  - Maps, Alarms, Camera, Sound Recorder
echo  - Feedback Hub, Get Help, Tips
echo  - Wallet, Print3D, OneConnect
echo  - Third-party bloat (Candy Crush, Facebook, Spotify, etc.)
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo Removing Microsoft bloatware apps...
echo.

powershell -ExecutionPolicy Bypass -Command ^"^
$bloatware = @(^
    'Microsoft.3DBuilder',^
    'Microsoft.3DViewer',^
    'Microsoft.BingFinance',^
    'Microsoft.BingNews',^
    'Microsoft.BingSports',^
    'Microsoft.BingWeather',^
    'Microsoft.GetHelp',^
    'Microsoft.Getstarted',^
    'Microsoft.Messaging',^
    'Microsoft.Microsoft3DViewer',^
    'Microsoft.MicrosoftOfficeHub',^
    'Microsoft.MicrosoftSolitaireCollection',^
    'Microsoft.MixedReality.Portal',^
    'Microsoft.MSPaint',^
    'Microsoft.Office.OneNote',^
    'Microsoft.OneConnect',^
    'Microsoft.People',^
    'Microsoft.Print3D',^
    'Microsoft.SkypeApp',^
    'Microsoft.Wallet',^
    'Microsoft.WindowsAlarms',^
    'Microsoft.WindowsCamera',^
    'Microsoft.WindowsFeedbackHub',^
    'Microsoft.WindowsMaps',^
    'Microsoft.WindowsSoundRecorder',^
    'Microsoft.Xbox.TCUI',^
    'Microsoft.XboxApp',^
    'Microsoft.XboxGameOverlay',^
    'Microsoft.XboxGamingOverlay',^
    'Microsoft.XboxIdentityProvider',^
    'Microsoft.XboxSpeechToTextOverlay',^
    'Microsoft.YourPhone',^
    'Microsoft.ZuneMusic',^
    'Microsoft.ZuneVideo'^
);^
^
foreach ($app in $bloatware) {^
    Write-Host \"Removing $app...\" -ForegroundColor Yellow;^
    Get-AppxPackage -Name $app -AllUsers 2>$null | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue;^
    Get-AppxProvisionedPackage -Online 2>$null | Where-Object DisplayName -Like $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue;^
}^
^
Write-Host '';^
Write-Host 'Removing third-party bloatware...' -ForegroundColor Cyan;^
$thirdParty = @('*CandyCrush*', '*Facebook*', '*Twitter*', '*Spotify*', '*Netflix*', '*Dolby*', '*FitbitCoach*', '*PandoraMedia*', '*LinkedIn*');^
foreach ($pattern in $thirdParty) {^
    Get-AppxPackage -Name $pattern -AllUsers 2>$null | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue;^
    Get-AppxProvisionedPackage -Online 2>$null | Where-Object DisplayName -Like $pattern | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue;^
}^
^"

echo.
echo ============================================================================
echo  Bloatware removal complete!
echo ============================================================================
echo.
echo NOTE: Some apps may reappear after Windows updates.
echo Run this script again after major updates if needed.
echo.
echo A reboot is recommended to complete the removal process.
echo.

pause
