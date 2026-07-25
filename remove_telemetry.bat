@echo off
REM ============================================================================
REM  REMOVE_TELEMETRY.BAT
REM  Disables Microsoft telemetry, diagnostics, data collection, and all
REM  phone-home behavior as thoroughly as possible via readable code.
REM
REM  PREREQUISITES:
REM    1. Run as Administrator (right-click > Run as administrator)
REM    2. Reboot after running
REM
REM  WHAT THIS DOES:
REM    - Sets telemetry level to zero (Security only / disabled)
REM    - Disables diagnostic data collection services
REM    - Disables Connected User Experiences (the core telemetry pipeline)
REM    - Disables Compatibility Telemetry (CompatTelRunner.exe)
REM    - Disables Customer Experience Improvement Program (CEIP)
REM    - Disables Application Impact Telemetry (AIT)
REM    - Disables Activity Feed / Timeline history collection
REM    - Disables advertising ID and tracking
REM    - Disables Cortana data collection
REM    - Disables input personalization (keylogger-adjacent features)
REM    - Disables location tracking
REM    - Disables Wi-Fi Sense (network sharing telemetry)
REM    - Disables feedback prompts
REM    - Disables handwriting/typing data collection
REM    - Blocks known Microsoft telemetry endpoints via hosts file
REM    - Disables telemetry scheduled tasks
REM    - Disables error reporting (WER)
REM    - Disables inventory collection and device census
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
echo  REMOVE_TELEMETRY.BAT - Microsoft Telemetry Removal Script
echo ============================================================================
echo/
echo  This will disable all Microsoft telemetry and data collection.
echo  Press Ctrl+C to abort, or...
pause

echo/
echo [1/12] Setting telemetry level to zero...
echo ------------------------------------------

REM -- AllowTelemetry = 0: "Security" level, the absolute minimum. --
REM -- On Enterprise/Education this means zero diagnostic data. --
REM -- On Home/Pro, Microsoft still collects "required" data but this --
REM -- is the lowest setting available. --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

REM -- MaxTelemetryAllowed: Belt-and-suspenders, caps the level --
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v MaxTelemetryAllowed /t REG_DWORD /d 0 /f

REM -- Disable diagnostic data viewer and optional data --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DisableDiagnosticDataViewer /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DisableOneSettingsDownloads /t REG_DWORD /d 1 /f

REM -- Disable sending browsing data to Microsoft --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v MicrosoftEdgeDataOptIn /t REG_DWORD /d 0 /f

echo/
echo [2/12] Disabling Connected User Experiences and Telemetry service...
echo --------------------------------------------------------------------

REM -- DiagTrack: "Connected User Experiences and Telemetry" --
REM -- This is THE main telemetry pipeline in Windows. It collects --
REM -- diagnostic data and sends it to Microsoft. Kill it. --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DiagTrack" /v Start /t REG_DWORD /d 4 /f
sc stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1

REM -- dmwappushservice: Device Management WAP Push Message Routing --
REM -- Routes telemetry data collected by DiagTrack. Servant of DiagTrack. --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice" /v Start /t REG_DWORD /d 4 /f
sc stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1

REM -- diagsvc: Diagnostic Execution Service --
REM -- Executes diagnostic actions for troubleshooting. Also phones home. --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\diagsvc" /v Start /t REG_DWORD /d 4 /f

REM -- DPS: Diagnostic Policy Service --
REM -- Detects and "troubleshoots" problems. Collects data in the process. --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DPS" /v Start /t REG_DWORD /d 4 /f

REM -- WdiServiceHost / WdiSystemHost: Diagnostic infrastructure hosts --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdiServiceHost" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdiSystemHost" /v Start /t REG_DWORD /d 4 /f

echo/
echo [3/12] Disabling Compatibility Telemetry...
echo ---------------------------------------------

REM -- CompatTelRunner.exe: "Microsoft Compatibility Telemetry" --
REM -- This process is infamous for high CPU usage. It inventories your --
REM -- installed software and sends it to Microsoft, ostensibly for --
REM -- compatibility assessment. It runs as a scheduled task. --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v AITEnable /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableInventory /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableUAR /t REG_DWORD /d 1 /f

REM -- Disable Program Compatibility Assistant --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisablePCA /t REG_DWORD /d 1 /f

REM -- Disable Steps Recorder (psr.exe) - records screen steps, sends data --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableEngine /t REG_DWORD /d 1 /f

echo/
echo [4/12] Disabling Customer Experience Improvement Program (CEIP)...
echo ------------------------------------------------------------------

REM -- CEIP: The original "help us improve Windows" telemetry --
REM -- Predates the modern DiagTrack system but still runs alongside it. --
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f

REM -- Disable CEIP for Internet Explorer --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\SQM" /v DisableCustomerImprovementProgram /t REG_DWORD /d 0 /f

REM -- Disable Messenger CEIP --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Messenger\Client" /v CEIP /t REG_DWORD /d 2 /f

echo/
echo [5/12] Disabling Windows Error Reporting...
echo ----------------------------------------------

REM -- WerSvc: Windows Error Reporting Service --
REM -- Sends crash dumps and error reports to Microsoft. --
REM -- Your crashes are your business, not theirs. --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WerSvc" /v Start /t REG_DWORD /d 4 /f
sc stop WerSvc >nul 2>&1

REM -- Policy: Disable error reporting entirely --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f

REM -- Disable sending second-level data (memory dumps, files) --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v DontSendAdditionalData /t REG_DWORD /d 1 /f

REM -- Disable the "Check for solutions" prompts --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f

echo/
echo [6/12] Disabling advertising ID, tracking, and input personalization...
echo -----------------------------------------------------------------------

REM -- Advertising ID: Unique identifier used to track you across apps --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f

REM -- Disable "Let apps use advertising ID" --
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f

REM -- Input Personalization: Sends your typing and inking data to Microsoft --
REM -- for "personalization." Effectively a soft keylogger. --
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v RestrictImplicitInkCollection /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v RestrictImplicitTextCollection /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" /v HarvestContacts /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Personalization\Settings" /v AcceptedPrivacyPolicy /t REG_DWORD /d 0 /f

REM -- Disable handwriting error reports --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" /v PreventHandwritingErrorReports /t REG_DWORD /d 1 /f

REM -- Disable Tablet PC input panel personalization --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" /v PreventHandwritingDataSharing /t REG_DWORD /d 1 /f

echo/
echo [7/12] Disabling location tracking...
echo ---------------------------------------

REM -- Disable location services system-wide --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableLocation /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableLocationScripting /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableWindowsLocationProvider /t REG_DWORD /d 1 /f

REM -- Disable sensor features (hardware sensor telemetry) --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableSensors /t REG_DWORD /d 1 /f

REM -- Disable location service --
reg add "HKLM\SYSTEM\CurrentControlSet\Services\lfsvc" /v Start /t REG_DWORD /d 4 /f

echo/
echo [8/12] Disabling Activity History and Timeline...
echo --------------------------------------------------

REM -- Activity History: Tracks every app you open, every document, --
REM -- every website, and can sync to Microsoft cloud. Timeline is --
REM -- the visible UI for this data. --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f

echo/
echo [9/12] Disabling Cortana and search telemetry...
echo --------------------------------------------------

REM -- Disable Cortana --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f

REM -- Disable web search from Start/Taskbar (sends keystrokes to Bing) --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWebOverMeteredConnections /t REG_DWORD /d 0 /f

REM -- Disable search highlights (ads in search) --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v EnableDynamicContentInWSB /t REG_DWORD /d 0 /f

REM -- Disable Cortana on lock screen --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortanaAboveLock /t REG_DWORD /d 0 /f

REM -- Disable search indexer cloud integration --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCloudSearch /t REG_DWORD /d 0 /f

echo/
echo [10/12] Disabling feedback, Wi-Fi Sense, and Copilot telemetry...
echo ------------------------------------------------------------------

REM -- Disable feedback prompts ("How likely are you to recommend Windows?") --
REM -- 0 = Never ask. These prompts also collect system data. --
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f

REM -- Disable Wi-Fi Sense (shares Wi-Fi passwords, collects network data) --
reg add "HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" /v AutoConnectAllowedOEM /t REG_DWORD /d 0 /f

REM -- Disable Copilot (AI assistant that sends prompts to Microsoft cloud) --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f

REM -- Disable Recall (AI screenshot feature, Windows 11 24H2+) --
REM -- Recall takes screenshots of everything you do and indexes them. --
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /t REG_DWORD /d 1 /f

echo/
echo [11/12] Disabling telemetry scheduled tasks...
echo ------------------------------------------------

REM -- Compatibility Appraiser: CompatTelRunner.exe - the big one --
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1

REM -- Program Data Updater --
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1

REM -- StartupAppTask: Collects data about your startup programs --
schtasks /Change /TN "Microsoft\Windows\Application Experience\StartupAppTask" /Disable >nul 2>&1

REM -- Proxy: Part of the autochk telemetry chain --
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable >nul 2>&1

REM -- CEIP Consolidator and related --
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /Disable >nul 2>&1

REM -- Device Census: Inventories your hardware for Microsoft --
schtasks /Change /TN "Microsoft\Windows\Device Information\Device" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Device Information\Device User" /Disable >nul 2>&1

REM -- DiskDiagnostic data collector --
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable >nul 2>&1

REM -- Feedback notifications --
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClient" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable >nul 2>&1

REM -- Maps telemetry --
schtasks /Change /TN "Microsoft\Windows\Maps\MapsToastTask" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Maps\MapsUpdateTask" /Disable >nul 2>&1

REM -- Cloud Experience Host (OOBE telemetry, "setup" nags) --
schtasks /Change /TN "Microsoft\Windows\CloudExperienceHost\CreateObjectTask" /Disable >nul 2>&1

REM -- NetTrace: Network activity collection --
schtasks /Change /TN "Microsoft\Windows\NetTrace\GatherNetworkInfo" /Disable >nul 2>&1

REM -- Windows Error Reporting tasks --
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable >nul 2>&1

echo/
echo [12/12] Blocking telemetry endpoints via hosts file...
echo -------------------------------------------------------

REM -- This adds entries to C:\Windows\System32\drivers\etc\hosts --
REM -- that redirect known Microsoft telemetry domains to 0.0.0.0 --
REM -- (nowhere). This is a last line of defense if any service --
REM -- somehow restarts and tries to phone home. --
REM --
REM -- NOTE: This appends to your hosts file. It will not duplicate --
REM -- entries if you run this script more than once (we check first). --

set HOSTS=%SystemRoot%\System32\drivers\etc\hosts
set MARKER=# --- TELEMETRY BLOCK (REMOVE_TELEMETRY.BAT) ---

REM -- Check if we've already added our block --
findstr /C:"%MARKER%" "%HOSTS%" >nul 2>&1
if %errorlevel% equ 0 (
    echo   Telemetry hosts entries already present. Skipping.
    goto :skip_hosts
)

echo   Adding telemetry blocks to hosts file...

REM -- Create backup first --
copy "%HOSTS%" "%HOSTS%.bak.%date:~-4%%date:~4,2%%date:~7,2%" >nul 2>&1

(
    echo/
    echo %MARKER%
    echo # Core telemetry endpoints
    echo 0.0.0.0 vortex.data.microsoft.com
    echo 0.0.0.0 vortex-win.data.microsoft.com
    echo 0.0.0.0 telecommand.telemetry.microsoft.com
    echo 0.0.0.0 telecommand.telemetry.microsoft.com.nsatc.net
    echo 0.0.0.0 oca.telemetry.microsoft.com
    echo 0.0.0.0 oca.telemetry.microsoft.com.nsatc.net
    echo 0.0.0.0 sqm.telemetry.microsoft.com
    echo 0.0.0.0 sqm.telemetry.microsoft.com.nsatc.net
    echo 0.0.0.0 watson.telemetry.microsoft.com
    echo 0.0.0.0 watson.telemetry.microsoft.com.nsatc.net
    echo 0.0.0.0 redir.metaservices.microsoft.com
    echo 0.0.0.0 choice.microsoft.com
    echo 0.0.0.0 choice.microsoft.com.nsatc.net
    echo 0.0.0.0 df.telemetry.microsoft.com
    echo 0.0.0.0 reports.wes.df.telemetry.microsoft.com
    echo 0.0.0.0 wes.df.telemetry.microsoft.com
    echo 0.0.0.0 services.wes.df.telemetry.microsoft.com
    echo 0.0.0.0 sqm.df.telemetry.microsoft.com
    echo 0.0.0.0 telemetry.microsoft.com
    echo 0.0.0.0 watson.ppe.telemetry.microsoft.com
    echo 0.0.0.0 telemetry.appex.bing.net
    echo 0.0.0.0 telemetry.urs.microsoft.com
    echo 0.0.0.0 telemetry.appex.bing.net:443
    echo 0.0.0.0 settings-sandbox.data.microsoft.com
    echo 0.0.0.0 watson.microsoft.com
    echo 0.0.0.0 statsfe2.ws.microsoft.com
    echo # Diagnostic data endpoints
    echo 0.0.0.0 v10.events.data.microsoft.com
    echo 0.0.0.0 v10.vortex-win.data.microsoft.com
    echo 0.0.0.0 v20.events.data.microsoft.com
    echo 0.0.0.0 us-v20.events.data.microsoft.com
    echo 0.0.0.0 eu-v20.events.data.microsoft.com
    echo 0.0.0.0 v10c.events.data.microsoft.com
    echo 0.0.0.0 v10.vortex-win.data.metron.live.com.nsatc.net
    echo 0.0.0.0 umwatsonc.events.data.microsoft.com
    echo 0.0.0.0 ceuswatcab01.blob.core.windows.net
    echo 0.0.0.0 ceuswatcab02.blob.core.windows.net
    echo # CEIP and error reporting
    echo 0.0.0.0 compatexchange.cloudapp.net
    echo 0.0.0.0 cs1.wpc.v0cdn.net
    echo 0.0.0.0 a-0001.a-msedge.net
    echo 0.0.0.0 statsfe2.update.microsoft.com.akadns.net
    echo 0.0.0.0 sls.update.microsoft.com.akadns.net
    echo 0.0.0.0 fe2cr.update.microsoft.com.akadns.net
    echo 0.0.0.0 diagnostics.support.microsoft.com
    echo # Advertising and tracking
    echo 0.0.0.0 ads1.msn.com
    echo 0.0.0.0 ad.doubleclick.net
    echo 0.0.0.0 adnxs.com
    echo 0.0.0.0 adnexus.net
    echo 0.0.0.0 g.msn.com
    echo 0.0.0.0 a.ads2.msads.net
    echo 0.0.0.0 b.ads2.msads.net
    echo 0.0.0.0 ac3.msn.com
    echo # Cortana and search data
    echo 0.0.0.0 www.bing.com.fdfe.gp.dl.google.com
    echo 0.0.0.0 corp.sts.microsoft.com
    echo 0.0.0.0 corpext.msitadfs.glbdns2.microsoft.com
    echo 0.0.0.0 feedback.microsoft-hohm.com
    echo 0.0.0.0 feedback.search.microsoft.com
    echo 0.0.0.0 feedback.windows.microsoft.com
    echo # OneDrive telemetry
    echo 0.0.0.0 vortex.data.microsoft.com
    echo 0.0.0.0 vortex-sandbox.data.microsoft.com
    echo # Recall / AI telemetry
    echo 0.0.0.0 inference.windows.com
    echo # --- END TELEMETRY BLOCK ---
) >> "%HOSTS%"

echo   Hosts file updated. Backup saved as %HOSTS%.bak.*

:skip_hosts

echo/
echo ============================================================================
echo  DONE. Microsoft telemetry has been disabled.
echo ============================================================================
echo/
echo  NEXT STEPS:
echo    1. REBOOT your machine for all changes to take effect.
echo    2. After reboot, verify:
echo       - Open Services (services.msc), confirm DiagTrack is disabled
echo       - Open Task Manager, confirm no CompatTelRunner.exe running
echo       - Run: sc query DiagTrack (should show STOPPED / DISABLED)
echo    3. If telemetry returns after a Windows feature update, re-run this.
echo/
echo  WHAT WAS DISABLED:
echo    Services:  DiagTrack, dmwappushservice, diagsvc, DPS, WerSvc,
echo               WdiServiceHost, WdiSystemHost, lfsvc
echo    Features:  Telemetry, CEIP, Error Reporting, Advertising ID,
echo               Input Personalization, Location, Activity History,
echo               Cortana, Web Search, Wi-Fi Sense, Copilot, Recall
echo    Tasks:     Compatibility Appraiser, Device Census, CEIP,
echo               DiskDiagnostic, Feedback, Maps, NetTrace, WER
echo    Network:   60+ telemetry domains blocked via hosts file
echo/
echo  TO REVERSE:
echo    - Delete policy keys under HKLM\SOFTWARE\Policies\Microsoft
echo    - Set service Start values back to 2 or 3
echo    - Remove the telemetry block section from:
echo      %SystemRoot%\System32\drivers\etc\hosts
echo    - Re-enable scheduled tasks via Task Scheduler
echo/
echo  OPTIONAL - VERIFY NOTHING IS PHONING HOME:
echo    Open PowerShell and run:
echo      netstat -b -n ^| findstr /i "microsoft"
echo    Or use Wireshark/TCPView to monitor outbound connections.
echo/
pause
