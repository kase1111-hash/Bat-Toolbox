@echo off
setlocal
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

:: Clean up any leftover temp files from interrupted runs
del "%TEMP%\remove-bloatware.ps1" 2>nul

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
echo $removedCount = 0
echo $skippedCount = 0
echo.
echo foreach ^($app in $bloatware^) {
echo     $packages = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
echo     $provPackages = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue ^| Where-Object DisplayName -Like $app
echo.
echo     if ^($packages -or $provPackages^) {
echo         Write-Host "Removing $app..." -ForegroundColor Yellow
echo         $success = $false
echo.
echo         # Remove for current user
echo         foreach ^($pkg in $packages^) {
echo             try {
echo                 Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
echo                 $success = $true
echo             } catch {
echo                 # Try without -AllUsers if it fails
echo             }
echo         }
echo.
echo         # Remove provisioned package ^(prevents reinstall for new users^)
echo         foreach ^($provPkg in $provPackages^) {
echo             try {
echo                 Remove-AppxProvisionedPackage -Online -PackageName $provPkg.PackageName -ErrorAction Stop ^| Out-Null
echo                 $success = $true
echo             } catch {
echo                 # Package may already be removed
echo             }
echo         }
echo.
echo         if ^($success^) {
echo             Write-Host "  Removed." -ForegroundColor Green
echo             $removedCount++
echo         } else {
echo             Write-Host "  Could not remove ^(may require restart or already removed^)." -ForegroundColor DarkYellow
echo             $skippedCount++
echo         }
echo     }
echo }
echo.
echo Write-Host ''
echo Write-Host 'Removing third-party bloatware...' -ForegroundColor Cyan
echo $thirdParty = @^('*CandyCrush*', '*Facebook*', '*Twitter*', '*Spotify*', '*Netflix*', '*Dolby*', '*FitbitCoach*', '*PandoraMedia*', '*LinkedIn*', '*Disney*', '*Amazon*', '*TikTok*', '*Instagram*'^)
echo.
echo foreach ^($pattern in $thirdParty^) {
echo     $packages = Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue
echo     $provPackages = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue ^| Where-Object DisplayName -Like $pattern
echo.
echo     foreach ^($pkg in $packages^) {
echo         Write-Host "Removing $^($pkg.Name^)..." -ForegroundColor Yellow
echo         try {
echo             Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
echo             Write-Host "  Removed." -ForegroundColor Green
echo             $removedCount++
echo         } catch {
echo             Write-Host "  Could not remove." -ForegroundColor DarkYellow
echo             $skippedCount++
echo         }
echo     }
echo.
echo     foreach ^($provPkg in $provPackages^) {
echo         try {
echo             Remove-AppxProvisionedPackage -Online -PackageName $provPkg.PackageName -ErrorAction Stop ^| Out-Null
echo         } catch { }
echo     }
echo }
echo.
echo Write-Host ''
echo Write-Host "========================================" -ForegroundColor Cyan
echo Write-Host "  Removed: $removedCount apps" -ForegroundColor Green
echo Write-Host "  Skipped/Failed: $skippedCount apps" -ForegroundColor Yellow
echo Write-Host "========================================" -ForegroundColor Cyan
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
echo If some apps failed to remove:
echo  - Try restarting and running again
echo  - Some system apps cannot be removed without third-party tools
echo.
echo A reboot is recommended to complete the removal process.
echo.

pause
