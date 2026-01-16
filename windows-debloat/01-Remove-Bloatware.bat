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
echo  - Groove Music, Movies and TV (Zune apps)
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

:: Create temporary PowerShell script
set "PSSCRIPT=%TEMP%\remove-bloatware.ps1"

(
echo $bloatware = @^(
echo     'Microsoft.3DBuilder',
echo     'Microsoft.3DViewer',
echo     'Microsoft.BingFinance',
echo     'Microsoft.BingNews',
echo     'Microsoft.BingSports',
echo     'Microsoft.BingWeather',
echo     'Microsoft.GetHelp',
echo     'Microsoft.Getstarted',
echo     'Microsoft.Messaging',
echo     'Microsoft.Microsoft3DViewer',
echo     'Microsoft.MicrosoftOfficeHub',
echo     'Microsoft.MicrosoftSolitaireCollection',
echo     'Microsoft.MixedReality.Portal',
echo     'Microsoft.MSPaint',
echo     'Microsoft.Office.OneNote',
echo     'Microsoft.OneConnect',
echo     'Microsoft.People',
echo     'Microsoft.Print3D',
echo     'Microsoft.SkypeApp',
echo     'Microsoft.Wallet',
echo     'Microsoft.WindowsAlarms',
echo     'Microsoft.WindowsCamera',
echo     'Microsoft.WindowsFeedbackHub',
echo     'Microsoft.WindowsMaps',
echo     'Microsoft.WindowsSoundRecorder',
echo     'Microsoft.Xbox.TCUI',
echo     'Microsoft.XboxApp',
echo     'Microsoft.XboxGameOverlay',
echo     'Microsoft.XboxGamingOverlay',
echo     'Microsoft.XboxIdentityProvider',
echo     'Microsoft.XboxSpeechToTextOverlay',
echo     'Microsoft.YourPhone',
echo     'Microsoft.ZuneMusic',
echo     'Microsoft.ZuneVideo'
echo ^)
echo.
echo foreach ^($app in $bloatware^) {
echo     Write-Host "Removing $app..." -ForegroundColor Yellow
echo     Get-AppxPackage -Name $app -AllUsers 2^>$null ^| Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
echo     Get-AppxProvisionedPackage -Online 2^>$null ^| Where-Object DisplayName -Like $app ^| Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
echo }
echo.
echo Write-Host ''
echo Write-Host 'Removing third-party bloatware...' -ForegroundColor Cyan
echo $thirdParty = @^('*CandyCrush*', '*Facebook*', '*Twitter*', '*Spotify*', '*Netflix*', '*Dolby*', '*FitbitCoach*', '*PandoraMedia*', '*LinkedIn*'^)
echo foreach ^($pattern in $thirdParty^) {
echo     Get-AppxPackage -Name $pattern -AllUsers 2^>$null ^| Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
echo     Get-AppxProvisionedPackage -Online 2^>$null ^| Where-Object DisplayName -Like $pattern ^| Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
echo }
echo Write-Host ''
echo Write-Host 'Done!' -ForegroundColor Green
) > "%PSSCRIPT%"

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%"

:: Clean up
del "%PSSCRIPT%" 2>nul

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
