@echo off
setlocal enabledelayedexpansion
title Windows Service Analyzer
color 0B

:: ============================================================================
:: Windows Service Analyzer
:: ============================================================================
:: Analyzes Windows services to find unnecessary automatic services.
:: Identifies bloatware services, telemetry, and services that can be
:: safely set to manual or disabled.
:: ============================================================================

echo ============================================================================
echo  Windows Service Analyzer
echo ============================================================================
echo.
echo Analyzing Windows services...
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

:: Create PowerShell script for service analysis
set "PSSCRIPT=%TEMP%\analyze_services.ps1"

(
echo # Windows Service Analyzer
echo # Categorizes services and identifies unnecessary automatic services
echo.
echo # Essential services - NEVER disable these
echo $essentialServices = @(
echo     # Core Windows
echo     'BrokerInfrastructure', 'CoreMessagingRegistrar', 'DcomLaunch', 'LSM',
echo     'Power', 'Plug and Play', 'RpcEptMapper', 'RpcSs', 'SamSs', 'Schedule',
echo     'SENS', 'SystemEventsBroker', 'Themes', 'UserManager', 'Winmgmt',
echo     'EventLog', 'EventSystem', 'FontCache', 'gpsvc', 'iphlpsvc',
echo     'LanmanServer', 'LanmanWorkstation', 'lmhosts', 'mpssvc', 'netprofm',
echo     'NlaSvc', 'nsi', 'ProfSvc', 'SecurityHealthService', 'Wcmsvc',
echo     'WinDefend', 'WdNisSvc', 'wscsvc', 'WSearch', 'Spooler',
echo     # Hardware
echo     'AudioEndpointBuilder', 'Audiosrv', 'BthServ', 'BTHUSB',
echo     'DeviceAssociationService', 'DeviceInstall', 'Dhcp', 'Dnscache',
echo     'DPS', 'hidserv', 'IKEEXT', 'KeyIso', 'netman', 'Netlogon',
echo     'PolicyAgent', 'ShellHWDetection', 'StorSvc', 'SysMain', 'TrkWks',
echo     'UsoSvc', 'WdiServiceHost', 'WdiSystemHost', 'Wecsvc', 'WEPHOSTSVC',
echo     'WlanSvc', 'WwanSvc', 'TokenBroker', 'TimeBrokerSvc', 'StateRepository',
echo     # Display
echo     'DisplayEnhancementService', 'DsSvc', 'GraphicsPerfSvc',
echo     # Security
echo     'BFE', 'CryptSvc', 'EFS', 'VaultSvc', 'WbioSrvc', 'Netlogon',
echo     # Required for many apps
echo     'Appinfo', 'AppXSvc', 'ClipSVC', 'camsvc', 'cbdhsvc', 'CDPSvc',
echo     'CDPUserSvc', 'ClickToRunSvc', 'COMSysApp', 'DoSvc', 'DispBrokerDesktopSvc',
echo     'InstallService', 'LicenseManager', 'lfsvc', 'NgcSvc', 'NgcCtnrSvc',
echo     'OneSyncSvc', 'sppsvc', 'TabletInputService', 'TextInputManagementService',
echo     'TieringEngineService', 'UmRdpService', 'WpnService', 'WpnUserService'
echo ^)
echo.
echo # Services that can be set to Manual ^(start when needed^)
echo $manualServices = @{
echo     # Print ^(if you rarely print^)
echo     'Spooler' = 'Print Spooler - Set to Manual if you rarely print'
echo     # Bluetooth ^(if not using^)
echo     'bthserv' = 'Bluetooth Support - Manual if not using Bluetooth'
echo     'BthAvctpSvc' = 'Bluetooth Audio - Manual if not using BT audio'
echo     # Fax ^(almost nobody uses^)
echo     'Fax' = 'Fax Service - Disable unless you fax'
echo     # Tablet/Touch ^(if not touchscreen^)
echo     'TabletInputService' = 'Touch Keyboard - Manual if no touchscreen'
echo     # Parental Controls
echo     'WpcMonSvc' = 'Parental Controls - Disable if not using'
echo     # Phone Link
echo     'PhoneSvc' = 'Phone Service - Manual if not using Phone Link'
echo     # Geolocation
echo     'lfsvc' = 'Geolocation - Manual if not using location services'
echo     # Secondary Logon
echo     'seclogon' = 'Secondary Logon - Manual unless using RunAs frequently'
echo     # Remote Desktop
echo     'TermService' = 'Remote Desktop - Disable if not using RDP'
echo     'SessionEnv' = 'Remote Desktop Config - Disable with TermService'
echo     'UmRdpService' = 'Remote Desktop Redirector - Disable with TermService'
echo     # Windows Insider
echo     'wisvc' = 'Windows Insider Service - Disable if not in Insider program'
echo     # Retail Demo
echo     'RetailDemo' = 'Retail Demo - Disable ^(store display mode^)'
echo     # Smart Card
echo     'SCardSvr' = 'Smart Card - Manual unless using smart cards'
echo     'ScDeviceEnum' = 'Smart Card Enum - Manual with SCardSvr'
echo     # Hyper-V ^(if not using VMs^)
echo     'vmicguestinterface' = 'Hyper-V Guest - Disable if not using VMs'
echo     'vmicheartbeat' = 'Hyper-V Heartbeat - Disable if not using VMs'
echo     'vmickvpexchange' = 'Hyper-V KVP - Disable if not using VMs'
echo     'vmicrdv' = 'Hyper-V Remote Desktop - Disable if not using VMs'
echo     'vmicshutdown' = 'Hyper-V Shutdown - Disable if not using VMs'
echo     'vmictimesync' = 'Hyper-V Time Sync - Disable if not using VMs'
echo     'vmicvmsession' = 'Hyper-V PowerShell - Disable if not using VMs'
echo     'vmicvss' = 'Hyper-V VSS - Disable if not using VMs'
echo     'HvHost' = 'Hyper-V Host - Disable if not using VMs'
echo     # Peer networking
echo     'p2pimsvc' = 'Peer Networking Identity - Usually not needed'
echo     'p2psvc' = 'Peer Networking Grouping - Usually not needed'
echo     'PNRPsvc' = 'Peer Name Resolution - Usually not needed'
echo     'PNRPAutoReg' = 'PNRP Auto Registration - Usually not needed'
echo     # AllJoyn ^(IoT^)
echo     'AJRouter' = 'AllJoyn Router - Disable unless using IoT devices'
echo     # Downloaded Maps
echo     'MapsBroker' = 'Downloaded Maps Manager - Manual if not using offline maps'
echo     # Wallet
echo     'WalletService' = 'Wallet Service - Manual if not using Windows Wallet'
echo     # Network sharing
echo     'NetTcpPortSharing' = 'Net.Tcp Port Sharing - Manual for most users'
echo }
echo.
echo # Telemetry and data collection services - recommend disabling
echo $telemetryServices = @{
echo     'DiagTrack' = 'Connected User Experiences and Telemetry - Microsoft data collection'
echo     'dmwappushservice' = 'WAP Push Message Routing - Telemetry related'
echo     'diagnosticshub.standardcollector.service' = 'Diagnostics Hub - Data collection'
echo     'WerSvc' = 'Windows Error Reporting - Sends crash data to Microsoft'
echo     'wercplsupport' = 'Error Reporting Support - Related to WerSvc'
echo     'Wecsvc' = 'Windows Event Collector - Often not needed'
echo     'PcaSvc' = 'Program Compatibility Assistant - Can be disabled'
echo     'BITS' = 'Background Intelligent Transfer - Used by Windows Update ^(careful^)'
echo }
echo.
echo # Bloatware/Third-party services that often auto-start unnecessarily
echo $bloatwareServices = @{
echo     # Adobe
echo     'AdobeARMservice' = 'Adobe Updater - Updates when you open Adobe apps'
echo     'AGSService' = 'Adobe Genuine Service - Unnecessary verification'
echo     'AdobeUpdateService' = 'Adobe Update Service - Unnecessary'
echo     # Google
echo     'gupdate' = 'Google Update - Chrome updates itself'
echo     'gupdatem' = 'Google Update ^(Manual^) - Unnecessary'
echo     'GoogleChromeElevationService' = 'Chrome Elevation - Rarely needed'
echo     # Microsoft Edge
echo     'edgeupdate' = 'Edge Update - Edge updates itself'
echo     'edgeupdatem' = 'Edge Update ^(Manual^) - Unnecessary'
echo     'MicrosoftEdgeElevationService' = 'Edge Elevation - Rarely needed'
echo     # Opera/Brave/Other browsers
echo     'OperaGXStable Update Service' = 'Opera GX Update - Unnecessary'
echo     'brave' = 'Brave Update - Browser updates itself'
echo     # Java
echo     'JavaQuickStarterService' = 'Java Quick Starter - Slows boot for minimal gain'
echo     # Apple
echo     'Apple Mobile Device Service' = 'Apple Mobile Device - Manual unless syncing'
echo     'iPod Service' = 'iPod Service - Unnecessary if not using iPod'
echo     'Bonjour Service' = 'Bonjour - Apple network discovery, rarely needed'
echo     # Gaming
echo     'Steam Client Service' = 'Steam Service - Launch Steam manually'
echo     'EasyAntiCheat' = 'Easy Anti-Cheat - Only when gaming'
echo     'BEService' = 'BattlEye - Only when gaming'
echo     'vgc' = 'Vanguard ^(Valorant^) - Only when gaming ^(security concern^)'
echo     # NVIDIA
echo     'NvTelemetryContainer' = 'NVIDIA Telemetry - Data collection, disable'
echo     'NVDisplay.ContainerLocalSystem' = 'NVIDIA Container - Can cause issues'
echo     # AMD
echo     'AMD External Events Utility' = 'AMD Events - Usually not needed'
echo     # Third-party antivirus
echo     'avast! Antivirus' = 'Avast - Windows Defender is sufficient'
echo     'AVG Antivirus' = 'AVG - Windows Defender is sufficient'
echo     'McAfee' = 'McAfee - Windows Defender is sufficient'
echo     'Norton' = 'Norton - Windows Defender is sufficient'
echo     # VPN
echo     'ExpressVPN' = 'ExpressVPN Service - Start VPN manually'
echo     'NordVPN' = 'NordVPN Service - Start VPN manually'
echo     # Cloud Storage
echo     'OneDrive Updater Service' = 'OneDrive Updater - Manual if not using OneDrive'
echo     'DropboxUpdate' = 'Dropbox Update - Unnecessary background service'
echo     'dbupdate' = 'Dropbox Update - Unnecessary'
echo     'dbupdatem' = 'Dropbox Update Manual - Unnecessary'
echo     # Vendor
echo     'ASUSSystemAnalysis' = 'ASUS Analysis - Bloatware'
echo     'ASUSSystemDiagnosis' = 'ASUS Diagnosis - Bloatware'
echo     'ASUSOptimization' = 'ASUS Optimization - Bloatware'
echo     'ASUSSoftwareManager' = 'ASUS Software Manager - Bloatware'
echo     'LightingService' = 'ASUS Aura - Only if using RGB'
echo     'ArmouryCrateService' = 'ASUS Armoury - Only if using RGB/fans'
echo     'GamingServices' = 'Xbox Gaming Services - Only if gaming'
echo     'GamingServicesNet' = 'Xbox Gaming Network - Only if Xbox gaming'
echo     'HPSupportSolutionsFrameworkService' = 'HP Support - Bloatware'
echo     'DellTechHub' = 'Dell TechHub - Bloatware'
echo     'SupportAssistAgent' = 'Dell SupportAssist - Bloatware'
echo     # PUPs
echo     'IObitUnSvr' = 'IObit Service - PUP, remove IObit'
echo     'LiveUpdate' = 'IObit LiveUpdate - PUP'
echo     'AdvancedSystemCareService' = 'ASC Service - PUP'
echo     'AusLogicsBoostSpeed' = 'Auslogics Service - PUP'
echo }
echo.
echo # Xbox services - can disable if not Xbox gaming on PC
echo $xboxServices = @{
echo     'XblAuthManager' = 'Xbox Live Auth Manager'
echo     'XblGameSave' = 'Xbox Live Game Save'
echo     'XboxGipSvc' = 'Xbox Accessory Management'
echo     'XboxNetApiSvc' = 'Xbox Live Networking'
echo }
echo.
echo # Get all services
echo $services = Get-Service ^| Select-Object Name, DisplayName, Status, StartType
echo $autoServices = $services ^| Where-Object { $_.StartType -eq 'Automatic' }
echo.
echo $essential = @^(^)
echo $canBeManual = @^(^)
echo $telemetry = @^(^)
echo $bloatware = @^(^)
echo $xbox = @^(^)
echo $unknown = @^(^)
echo.
echo foreach ^($svc in $autoServices^) {
echo     $name = $svc.Name
echo     $found = $false
echo.
echo     # Check essential
echo     if ^($essentialServices -contains $name^) {
echo         $essential += $svc
echo         continue
echo     }
echo.
echo     # Check can be manual
echo     if ^($manualServices.ContainsKey^($name^)^) {
echo         $svc ^| Add-Member -NotePropertyName 'Reason' -NotePropertyValue $manualServices[$name] -Force
echo         $canBeManual += $svc
echo         continue
echo     }
echo.
echo     # Check telemetry
echo     if ^($telemetryServices.ContainsKey^($name^)^) {
echo         $svc ^| Add-Member -NotePropertyName 'Reason' -NotePropertyValue $telemetryServices[$name] -Force
echo         $telemetry += $svc
echo         continue
echo     }
echo.
echo     # Check bloatware
echo     foreach ^($key in $bloatwareServices.Keys^) {
echo         if ^($name -like "*$key*" -or $svc.DisplayName -like "*$key*"^) {
echo             $svc ^| Add-Member -NotePropertyName 'Reason' -NotePropertyValue $bloatwareServices[$key] -Force
echo             $bloatware += $svc
echo             $found = $true
echo             break
echo         }
echo     }
echo     if ^($found^) { continue }
echo.
echo     # Check Xbox
echo     if ^($xboxServices.ContainsKey^($name^)^) {
echo         $svc ^| Add-Member -NotePropertyName 'Reason' -NotePropertyValue $xboxServices[$name] -Force
echo         $xbox += $svc
echo         continue
echo     }
echo.
echo     # Check for common patterns
echo     if ^($name -like "*Update*" -or $name -like "*Updater*"^) {
echo         $svc ^| Add-Member -NotePropertyName 'Reason' -NotePropertyValue 'Update service - may be unnecessary' -Force
echo         $canBeManual += $svc
echo         continue
echo     }
echo.
echo     # Unknown automatic service
echo     $unknown += $svc
echo }
echo.
echo # Display results
echo ''
echo '============================================================================'
echo ' SERVICE ANALYSIS RESULTS'
echo '============================================================================'
echo ''
echo "Total Automatic Services: $^($autoServices.Count^)"
echo "Essential: $^($essential.Count^) | Can be Manual: $^($canBeManual.Count^) | Telemetry: $^($telemetry.Count^)"
echo "Bloatware: $^($bloatware.Count^) | Xbox: $^($xbox.Count^) | Unknown: $^($unknown.Count^)"
echo ''
echo.
echo if ^($bloatware.Count -gt 0^) {
echo     Write-Host '============================================================================' -ForegroundColor Red
echo     Write-Host ' [BLOATWARE] Third-Party Services Running Automatically' -ForegroundColor Red
echo     Write-Host '============================================================================' -ForegroundColor Red
echo     Write-Host ''
echo     foreach ^($svc in $bloatware^) {
echo         $statusColor = if ^($svc.Status -eq 'Running'^) { 'Red' } else { 'DarkRed' }
echo         Write-Host "  [X] $^($svc.DisplayName^)" -ForegroundColor $statusColor
echo         Write-Host "      Service: $^($svc.Name^) - Status: $^($svc.Status^)" -ForegroundColor Gray
echo         Write-Host "      $^($svc.Reason^)" -ForegroundColor DarkYellow
echo     }
echo     Write-Host ''
echo     $bloatware ^| ForEach-Object { $_.Name } ^| Out-File -FilePath "$env:TEMP\bloatware_services.txt" -Encoding ASCII
echo }
echo.
echo if ^($telemetry.Count -gt 0^) {
echo     Write-Host '============================================================================' -ForegroundColor Magenta
echo     Write-Host ' [TELEMETRY] Data Collection Services' -ForegroundColor Magenta
echo     Write-Host '============================================================================' -ForegroundColor Magenta
echo     Write-Host ''
echo     foreach ^($svc in $telemetry^) {
echo         $statusColor = if ^($svc.Status -eq 'Running'^) { 'Magenta' } else { 'DarkMagenta' }
echo         Write-Host "  [!] $^($svc.DisplayName^)" -ForegroundColor $statusColor
echo         Write-Host "      Service: $^($svc.Name^) - Status: $^($svc.Status^)" -ForegroundColor Gray
echo         Write-Host "      $^($svc.Reason^)" -ForegroundColor DarkYellow
echo     }
echo     Write-Host ''
echo     $telemetry ^| ForEach-Object { $_.Name } ^| Out-File -FilePath "$env:TEMP\telemetry_services.txt" -Encoding ASCII
echo }
echo.
echo if ^($canBeManual.Count -gt 0^) {
echo     Write-Host '============================================================================' -ForegroundColor Yellow
echo     Write-Host ' [OPTIONAL] Services That Can Be Set to Manual' -ForegroundColor Yellow
echo     Write-Host '============================================================================' -ForegroundColor Yellow
echo     Write-Host ''
echo     foreach ^($svc in $canBeManual^) {
echo         Write-Host "  [?] $^($svc.DisplayName^)" -ForegroundColor Yellow
echo         Write-Host "      Service: $^($svc.Name^)" -ForegroundColor Gray
echo         if ^($svc.Reason^) { Write-Host "      $^($svc.Reason^)" -ForegroundColor DarkGray }
echo     }
echo     Write-Host ''
echo     $canBeManual ^| ForEach-Object { $_.Name } ^| Out-File -FilePath "$env:TEMP\manual_services.txt" -Encoding ASCII
echo }
echo.
echo if ^($xbox.Count -gt 0^) {
echo     Write-Host '============================================================================' -ForegroundColor Green
echo     Write-Host ' [XBOX] Xbox Services ^(Disable if not Xbox gaming on PC^)' -ForegroundColor Green
echo     Write-Host '============================================================================' -ForegroundColor Green
echo     Write-Host ''
echo     foreach ^($svc in $xbox^) {
echo         Write-Host "  [G] $^($svc.DisplayName^)" -ForegroundColor Green
echo         Write-Host "      Service: $^($svc.Name^)" -ForegroundColor Gray
echo     }
echo     Write-Host ''
echo     $xbox ^| ForEach-Object { $_.Name } ^| Out-File -FilePath "$env:TEMP\xbox_services.txt" -Encoding ASCII
echo }
echo.
echo Write-Host '============================================================================' -ForegroundColor Cyan
echo Write-Host ' [INFO] Unknown Automatic Services' -ForegroundColor Cyan
echo Write-Host '============================================================================' -ForegroundColor Cyan
echo Write-Host ''
echo Write-Host "  $^($unknown.Count^) services not categorized ^(likely Windows or legitimate software^)" -ForegroundColor Cyan
echo Write-Host '  Use services.msc to review if interested' -ForegroundColor DarkGray
echo Write-Host ''
echo.
echo Write-Host '============================================================================' -ForegroundColor White
echo Write-Host ' Summary' -ForegroundColor White
echo Write-Host '============================================================================' -ForegroundColor White
) > "%PSSCRIPT%"

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%"

echo.

:: Ask about disabling bloatware services
if exist "%TEMP%\bloatware_services.txt" (
    set "bloat_count=0"
    for /f %%a in ('type "%TEMP%\bloatware_services.txt" 2^>nul ^| find /c /v ""') do set "bloat_count=%%a"

    if !bloat_count! gtr 0 (
        echo.
        set /p "disablebloat=Disable BLOATWARE services? [Y/N]: "
        if /i "!disablebloat!"=="Y" (
            echo.
            echo Disabling bloatware services...
            for /f "tokens=*" %%s in ('type "%TEMP%\bloatware_services.txt"') do (
                sc stop "%%s" >nul 2>&1
                sc config "%%s" start= disabled >nul 2>&1
                if not errorlevel 1 (
                    echo   [DISABLED] %%s
                ) else (
                    echo   [FAILED] %%s - may be protected
                )
            )
        )
    )
    del "%TEMP%\bloatware_services.txt" 2>nul
)

:: Ask about disabling telemetry services
if exist "%TEMP%\telemetry_services.txt" (
    set "tele_count=0"
    for /f %%a in ('type "%TEMP%\telemetry_services.txt" 2^>nul ^| find /c /v ""') do set "tele_count=%%a"

    if !tele_count! gtr 0 (
        echo.
        set /p "disabletele=Disable TELEMETRY services? [Y/N]: "
        if /i "!disabletele!"=="Y" (
            echo.
            echo Disabling telemetry services...
            for /f "tokens=*" %%s in ('type "%TEMP%\telemetry_services.txt"') do (
                sc stop "%%s" >nul 2>&1
                sc config "%%s" start= disabled >nul 2>&1
                if not errorlevel 1 (
                    echo   [DISABLED] %%s
                ) else (
                    echo   [FAILED] %%s - may be protected
                )
            )
        )
    )
    del "%TEMP%\telemetry_services.txt" 2>nul
)

:: Ask about Xbox services
if exist "%TEMP%\xbox_services.txt" (
    set "xbox_count=0"
    for /f %%a in ('type "%TEMP%\xbox_services.txt" 2^>nul ^| find /c /v ""') do set "xbox_count=%%a"

    if !xbox_count! gtr 0 (
        echo.
        set /p "disablexbox=Disable XBOX services? [Y/N]: "
        if /i "!disablexbox!"=="Y" (
            echo.
            echo Disabling Xbox services...
            for /f "tokens=*" %%s in ('type "%TEMP%\xbox_services.txt"') do (
                sc stop "%%s" >nul 2>&1
                sc config "%%s" start= disabled >nul 2>&1
                if not errorlevel 1 (
                    echo   [DISABLED] %%s
                ) else (
                    echo   [FAILED] %%s - may be protected
                )
            )
        )
    )
    del "%TEMP%\xbox_services.txt" 2>nul
)

:: Cleanup
del "%PSSCRIPT%" 2>nul
del "%TEMP%\manual_services.txt" 2>nul

echo.
echo ============================================================================
echo  Complete!
echo ============================================================================
echo.
echo Tips:
echo  - Use services.msc for manual service management
echo  - Disabled services can be re-enabled anytime
echo  - Some changes require a restart to take effect
echo  - If something breaks, re-enable the service or use System Restore
echo.
echo To re-enable a service:
echo   sc config "ServiceName" start= auto
echo   sc start "ServiceName"
echo.

pause
exit /b 0
