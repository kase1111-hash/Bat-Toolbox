# ServiceAnalyzer.ps1
# Helper script for ServiceAnalyzer.bat
# Categorizes Windows services and identifies unnecessary automatic services

# Windows Service Analyzer
# Categorizes services and identifies unnecessary automatic services

# Essential services - NEVER disable these
$essentialServices = @(
    # Core Windows
    'BrokerInfrastructure', 'CoreMessagingRegistrar', 'DcomLaunch', 'LSM',
    'Power', 'Plug and Play', 'RpcEptMapper', 'RpcSs', 'SamSs', 'Schedule',
    'SENS', 'SystemEventsBroker', 'Themes', 'UserManager', 'Winmgmt',
    'EventLog', 'EventSystem', 'FontCache', 'gpsvc', 'iphlpsvc',
    'LanmanServer', 'LanmanWorkstation', 'lmhosts', 'mpssvc', 'netprofm',
    'NlaSvc', 'nsi', 'ProfSvc', 'SecurityHealthService', 'Wcmsvc',
    'WinDefend', 'WdNisSvc', 'wscsvc', 'WSearch', 'Spooler',
    # Hardware
    'AudioEndpointBuilder', 'Audiosrv', 'BthServ', 'BTHUSB',
    'DeviceAssociationService', 'DeviceInstall', 'Dhcp', 'Dnscache',
    'DPS', 'hidserv', 'IKEEXT', 'KeyIso', 'netman', 'Netlogon',
    'PolicyAgent', 'ShellHWDetection', 'StorSvc', 'SysMain', 'TrkWks',
    'UsoSvc', 'WdiServiceHost', 'WdiSystemHost', 'Wecsvc', 'WEPHOSTSVC',
    'WlanSvc', 'WwanSvc', 'TokenBroker', 'TimeBrokerSvc', 'StateRepository',
    # Display
    'DisplayEnhancementService', 'DsSvc', 'GraphicsPerfSvc',
    # Security
    'BFE', 'CryptSvc', 'EFS', 'VaultSvc', 'WbioSrvc', 'Netlogon',
    # Required for many apps
    'Appinfo', 'AppXSvc', 'ClipSVC', 'camsvc', 'cbdhsvc', 'CDPSvc',
    'CDPUserSvc', 'ClickToRunSvc', 'COMSysApp', 'DoSvc', 'DispBrokerDesktopSvc',
    'InstallService', 'LicenseManager', 'lfsvc', 'NgcSvc', 'NgcCtnrSvc',
    'OneSyncSvc', 'sppsvc', 'TabletInputService', 'TextInputManagementService',
    'TieringEngineService', 'UmRdpService', 'WpnService', 'WpnUserService'
)

# Services that can be set to Manual (start when needed)
$manualServices = @{
    # Print (if you rarely print)
    'Spooler' = 'Print Spooler - Set to Manual if you rarely print'
    # Bluetooth (if not using)
    'bthserv' = 'Bluetooth Support - Manual if not using Bluetooth'
    'BthAvctpSvc' = 'Bluetooth Audio - Manual if not using BT audio'
    # Fax (almost nobody uses)
    'Fax' = 'Fax Service - Disable unless you fax'
    # Tablet/Touch (if not touchscreen)
    'TabletInputService' = 'Touch Keyboard - Manual if no touchscreen'
    # Parental Controls
    'WpcMonSvc' = 'Parental Controls - Disable if not using'
    # Phone Link
    'PhoneSvc' = 'Phone Service - Manual if not using Phone Link'
    # Geolocation
    'lfsvc' = 'Geolocation - Manual if not using location services'
    # Secondary Logon
    'seclogon' = 'Secondary Logon - Manual unless using RunAs frequently'
    # Remote Desktop
    'TermService' = 'Remote Desktop - Disable if not using RDP'
    'SessionEnv' = 'Remote Desktop Config - Disable with TermService'
    'UmRdpService' = 'Remote Desktop Redirector - Disable with TermService'
    # Windows Insider
    'wisvc' = 'Windows Insider Service - Disable if not in Insider program'
    # Retail Demo
    'RetailDemo' = 'Retail Demo - Disable (store display mode)'
    # Smart Card
    'SCardSvr' = 'Smart Card - Manual unless using smart cards'
    'ScDeviceEnum' = 'Smart Card Enum - Manual with SCardSvr'
    # Hyper-V (if not using VMs)
    'vmicguestinterface' = 'Hyper-V Guest - Disable if not using VMs'
    'vmicheartbeat' = 'Hyper-V Heartbeat - Disable if not using VMs'
    'vmickvpexchange' = 'Hyper-V KVP - Disable if not using VMs'
    'vmicrdv' = 'Hyper-V Remote Desktop - Disable if not using VMs'
    'vmicshutdown' = 'Hyper-V Shutdown - Disable if not using VMs'
    'vmictimesync' = 'Hyper-V Time Sync - Disable if not using VMs'
    'vmicvmsession' = 'Hyper-V PowerShell - Disable if not using VMs'
    'vmicvss' = 'Hyper-V VSS - Disable if not using VMs'
    'HvHost' = 'Hyper-V Host - Disable if not using VMs'
    # Peer networking
    'p2pimsvc' = 'Peer Networking Identity - Usually not needed'
    'p2psvc' = 'Peer Networking Grouping - Usually not needed'
    'PNRPsvc' = 'Peer Name Resolution - Usually not needed'
    'PNRPAutoReg' = 'PNRP Auto Registration - Usually not needed'
    # AllJoyn (IoT)
    'AJRouter' = 'AllJoyn Router - Disable unless using IoT devices'
    # Downloaded Maps
    'MapsBroker' = 'Downloaded Maps Manager - Manual if not using offline maps'
    # Wallet
    'WalletService' = 'Wallet Service - Manual if not using Windows Wallet'
    # Network sharing
    'NetTcpPortSharing' = 'Net.Tcp Port Sharing - Manual for most users'
}

# Telemetry and data collection services - recommend disabling
$telemetryServices = @{
    'DiagTrack' = 'Connected User Experiences and Telemetry - Microsoft data collection'
    'dmwappushservice' = 'WAP Push Message Routing - Telemetry related'
    'diagnosticshub.standardcollector.service' = 'Diagnostics Hub - Data collection'
    'WerSvc' = 'Windows Error Reporting - Sends crash data to Microsoft'
    'wercplsupport' = 'Error Reporting Support - Related to WerSvc'
    'Wecsvc' = 'Windows Event Collector - Often not needed'
    'PcaSvc' = 'Program Compatibility Assistant - Can be disabled'
    'BITS' = 'Background Intelligent Transfer - Used by Windows Update (careful)'
}

# Bloatware/Third-party services that often auto-start unnecessarily
$bloatwareServices = @{
    # Adobe
    'AdobeARMservice' = 'Adobe Updater - Updates when you open Adobe apps'
    'AGSService' = 'Adobe Genuine Service - Unnecessary verification'
    'AdobeUpdateService' = 'Adobe Update Service - Unnecessary'
    # Google
    'gupdate' = 'Google Update - Chrome updates itself'
    'gupdatem' = 'Google Update (Manual) - Unnecessary'
    'GoogleChromeElevationService' = 'Chrome Elevation - Rarely needed'
    # Microsoft Edge
    'edgeupdate' = 'Edge Update - Edge updates itself'
    'edgeupdatem' = 'Edge Update (Manual) - Unnecessary'
    'MicrosoftEdgeElevationService' = 'Edge Elevation - Rarely needed'
    # Opera/Brave/Other browsers
    'OperaGXStable Update Service' = 'Opera GX Update - Unnecessary'
    'brave' = 'Brave Update - Browser updates itself'
    # Java
    'JavaQuickStarterService' = 'Java Quick Starter - Slows boot for minimal gain'
    # Apple
    'Apple Mobile Device Service' = 'Apple Mobile Device - Manual unless syncing'
    'iPod Service' = 'iPod Service - Unnecessary if not using iPod'
    'Bonjour Service' = 'Bonjour - Apple network discovery, rarely needed'
    # Gaming
    'Steam Client Service' = 'Steam Service - Launch Steam manually'
    'EasyAntiCheat' = 'Easy Anti-Cheat - Only when gaming'
    'BEService' = 'BattlEye - Only when gaming'
    'vgc' = 'Vanguard (Valorant) - Only when gaming (security concern)'
    # NVIDIA
    'NvTelemetryContainer' = 'NVIDIA Telemetry - Data collection, disable'
    'NVDisplay.ContainerLocalSystem' = 'NVIDIA Container - Can cause issues'
    # AMD
    'AMD External Events Utility' = 'AMD Events - Usually not needed'
    # Third-party antivirus
    'avast! Antivirus' = 'Avast - Windows Defender is sufficient'
    'AVG Antivirus' = 'AVG - Windows Defender is sufficient'
    'McAfee' = 'McAfee - Windows Defender is sufficient'
    'Norton' = 'Norton - Windows Defender is sufficient'
    # VPN
    'ExpressVPN' = 'ExpressVPN Service - Start VPN manually'
    'NordVPN' = 'NordVPN Service - Start VPN manually'
    # Cloud Storage
    'OneDrive Updater Service' = 'OneDrive Updater - Manual if not using OneDrive'
    'DropboxUpdate' = 'Dropbox Update - Unnecessary background service'
    'dbupdate' = 'Dropbox Update - Unnecessary'
    'dbupdatem' = 'Dropbox Update Manual - Unnecessary'
    # Vendor
    'ASUSSystemAnalysis' = 'ASUS Analysis - Bloatware'
    'ASUSSystemDiagnosis' = 'ASUS Diagnosis - Bloatware'
    'ASUSOptimization' = 'ASUS Optimization - Bloatware'
    'ASUSSoftwareManager' = 'ASUS Software Manager - Bloatware'
    'LightingService' = 'ASUS Aura - Only if using RGB'
    'ArmouryCrateService' = 'ASUS Armoury - Only if using RGB/fans'
    'GamingServices' = 'Xbox Gaming Services - Only if gaming'
    'GamingServicesNet' = 'Xbox Gaming Network - Only if Xbox gaming'
    'HPSupportSolutionsFrameworkService' = 'HP Support - Bloatware'
    'DellTechHub' = 'Dell TechHub - Bloatware'
    'SupportAssistAgent' = 'Dell SupportAssist - Bloatware'
    # PUPs
    'IObitUnSvr' = 'IObit Service - PUP, remove IObit'
    'LiveUpdate' = 'IObit LiveUpdate - PUP'
    'AdvancedSystemCareService' = 'ASC Service - PUP'
    'AusLogicsBoostSpeed' = 'Auslogics Service - PUP'
}

# Xbox services - can disable if not Xbox gaming on PC
$xboxServices = @{
    'XblAuthManager' = 'Xbox Live Auth Manager'
    'XblGameSave' = 'Xbox Live Game Save'
    'XboxGipSvc' = 'Xbox Accessory Management'
    'XboxNetApiSvc' = 'Xbox Live Networking'
}

# Get all services
$services = Get-Service | Select-Object Name, DisplayName, Status, StartType
$autoServices = $services | Where-Object { $_.StartType -eq 'Automatic' }

$essential = @()
$canBeManual = @()
$telemetry = @()
$bloatware = @()
$xbox = @()
$unknown = @()

foreach ($svc in $autoServices) {
    $name = $svc.Name
    $found = $false

    # Check essential
    if ($essentialServices -contains $name) {
        $essential += $svc
        continue
    }

    # Check can be manual
    if ($manualServices.ContainsKey($name)) {
        $svc | Add-Member -NotePropertyName 'Reason' -NotePropertyValue $manualServices[$name] -Force
        $canBeManual += $svc
        continue
    }

    # Check telemetry
    if ($telemetryServices.ContainsKey($name)) {
        $svc | Add-Member -NotePropertyName 'Reason' -NotePropertyValue $telemetryServices[$name] -Force
        $telemetry += $svc
        continue
    }

    # Check bloatware
    foreach ($key in $bloatwareServices.Keys) {
        if ($name -like "*$key*" -or $svc.DisplayName -like "*$key*") {
            $svc | Add-Member -NotePropertyName 'Reason' -NotePropertyValue $bloatwareServices[$key] -Force
            $bloatware += $svc
            $found = $true
            break
        }
    }
    if ($found) { continue }

    # Check Xbox
    if ($xboxServices.ContainsKey($name)) {
        $svc | Add-Member -NotePropertyName 'Reason' -NotePropertyValue $xboxServices[$name] -Force
        $xbox += $svc
        continue
    }

    # Check for common patterns
    if ($name -like "*Update*" -or $name -like "*Updater*") {
        $svc | Add-Member -NotePropertyName 'Reason' -NotePropertyValue 'Update service - may be unnecessary' -Force
        $canBeManual += $svc
        continue
    }

    # Unknown automatic service
    $unknown += $svc
}

# Display results
''
'============================================================================'
' SERVICE ANALYSIS RESULTS'
'============================================================================'
''
"Total Automatic Services: $($autoServices.Count)"
"Essential: $($essential.Count) | Can be Manual: $($canBeManual.Count) | Telemetry: $($telemetry.Count)"
"Bloatware: $($bloatware.Count) | Xbox: $($xbox.Count) | Unknown: $($unknown.Count)"
''

if ($bloatware.Count -gt 0) {
    Write-Host '============================================================================' -ForegroundColor Red
    Write-Host ' [BLOATWARE] Third-Party Services Running Automatically' -ForegroundColor Red
    Write-Host '============================================================================' -ForegroundColor Red
    Write-Host ''
    foreach ($svc in $bloatware) {
        $statusColor = if ($svc.Status -eq 'Running') { 'Red' } else { 'DarkRed' }
        Write-Host "  [X] $($svc.DisplayName)" -ForegroundColor $statusColor
        Write-Host "      Service: $($svc.Name) - Status: $($svc.Status)" -ForegroundColor Gray
        Write-Host "      $($svc.Reason)" -ForegroundColor DarkYellow
    }
    Write-Host ''
    $bloatware | ForEach-Object { $_.Name } | Out-File -FilePath "$env:TEMP\bloatware_services.txt" -Encoding ASCII
}

if ($telemetry.Count -gt 0) {
    Write-Host '============================================================================' -ForegroundColor Magenta
    Write-Host ' [TELEMETRY] Data Collection Services' -ForegroundColor Magenta
    Write-Host '============================================================================' -ForegroundColor Magenta
    Write-Host ''
    foreach ($svc in $telemetry) {
        $statusColor = if ($svc.Status -eq 'Running') { 'Magenta' } else { 'DarkMagenta' }
        Write-Host "  [!] $($svc.DisplayName)" -ForegroundColor $statusColor
        Write-Host "      Service: $($svc.Name) - Status: $($svc.Status)" -ForegroundColor Gray
        Write-Host "      $($svc.Reason)" -ForegroundColor DarkYellow
    }
    Write-Host ''
    $telemetry | ForEach-Object { $_.Name } | Out-File -FilePath "$env:TEMP\telemetry_services.txt" -Encoding ASCII
}

if ($canBeManual.Count -gt 0) {
    Write-Host '============================================================================' -ForegroundColor Yellow
    Write-Host ' [OPTIONAL] Services That Can Be Set to Manual' -ForegroundColor Yellow
    Write-Host '============================================================================' -ForegroundColor Yellow
    Write-Host ''
    foreach ($svc in $canBeManual) {
        Write-Host "  [?] $($svc.DisplayName)" -ForegroundColor Yellow
        Write-Host "      Service: $($svc.Name)" -ForegroundColor Gray
        if ($svc.Reason) { Write-Host "      $($svc.Reason)" -ForegroundColor DarkGray }
    }
    Write-Host ''
    $canBeManual | ForEach-Object { $_.Name } | Out-File -FilePath "$env:TEMP\manual_services.txt" -Encoding ASCII
}

if ($xbox.Count -gt 0) {
    Write-Host '============================================================================' -ForegroundColor Green
    Write-Host ' [XBOX] Xbox Services (Disable if not Xbox gaming on PC)' -ForegroundColor Green
    Write-Host '============================================================================' -ForegroundColor Green
    Write-Host ''
    foreach ($svc in $xbox) {
        Write-Host "  [G] $($svc.DisplayName)" -ForegroundColor Green
        Write-Host "      Service: $($svc.Name)" -ForegroundColor Gray
    }
    Write-Host ''
    $xbox | ForEach-Object { $_.Name } | Out-File -FilePath "$env:TEMP\xbox_services.txt" -Encoding ASCII
}

Write-Host '============================================================================' -ForegroundColor Cyan
Write-Host ' [INFO] Unknown Automatic Services' -ForegroundColor Cyan
Write-Host '============================================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "  $($unknown.Count) services not categorized (likely Windows or legitimate software)" -ForegroundColor Cyan
Write-Host '  Use services.msc to review if interested' -ForegroundColor DarkGray
Write-Host ''

Write-Host '============================================================================' -ForegroundColor White
Write-Host ' Summary' -ForegroundColor White
Write-Host '============================================================================' -ForegroundColor White
