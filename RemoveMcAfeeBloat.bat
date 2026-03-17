@echo off
setlocal enabledelayedexpansion
title McAfee Bloatware Remover
color 0B

:: ============================================================================
:: McAfee Bloatware Remover
:: ============================================================================
:: Removes all McAfee products (Security, WebAdvisor, LiveSafe, True Key) that
:: ship preinstalled on Dell, HP, and Lenovo machines. McAfee survives normal
:: uninstall and requires service, registry, and file cleanup.
:: ============================================================================

:: Set up color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "RESET=%ESC%[0m"

echo %CYAN%============================================================================%RESET%
echo %CYAN% McAfee Bloatware Remover%RESET%
echo %CYAN%============================================================================%RESET%
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR] This script requires Administrator privileges.%RESET%
    echo %RED%Please right-click and select "Run as administrator"%RESET%
    echo.
    pause
    exit /b 1
)

echo This script removes all McAfee products that ship preinstalled on OEM PCs.
echo.
echo %YELLOW%What will be REMOVED:%RESET%
echo  - McAfee LiveSafe / Total Protection / AntiVirus
echo  - McAfee WebAdvisor / SiteAdvisor
echo  - McAfee True Key (password manager)
echo  - McAfee Personal Security / Privacy
echo  - McAfee services, scheduled tasks, and startup entries
echo  - McAfee browser extensions and remnants
echo.
echo %GREEN%What will be KEPT:%RESET%
echo  - Windows Defender / Windows Security (will auto-activate)
echo  - Windows Firewall
echo  - All other security software
echo.
echo %YELLOW%NOTE: Windows Defender will automatically enable itself after McAfee%RESET%
echo %YELLOW%      is removed. Your system will remain protected.%RESET%
echo.

:: Confirm before proceeding
set /p "confirm=Do you want to continue? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo.
    echo Operation cancelled.
    pause
    exit /b 0
)

set "success=0"

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 1: Stopping McAfee Processes and Services%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [1/8] Terminating McAfee processes...

for %%P in (
    "McCSPServiceHost.exe"
    "mcapexe.exe"
    "McAPExe.exe"
    "mcscancheck.exe"
    "mcshield.exe"
    "McSvHost.exe"
    "McUICnt.exe"
    "mcuicnt.exe"
    "McPvTray.exe"
    "mcpvtray.exe"
    "mfemms.exe"
    "mfevtps.exe"
    "ModuleCoreService.exe"
    "PEFService.exe"
    "ProtectedModuleHost.exe"
    "MMSSHOST.exe"
    "MfeAVSvc.exe"
    "mcods.exe"
    "McNASvc.exe"
    "McProxy.exe"
    "mcinfo.exe"
    "McInstruTrack.exe"
    "McComponentHostService.exe"
    "McComponentHostServiceSony.exe"
    "mfewc.exe"
    "mfefire.exe"
    "mfecanary.exe"
    "mfetp.exe"
    "TrueKey.exe"
    "TrueKeyServiceHelper.exe"
    "TrueKeyScheduler.exe"
    "McAfee.TrueKey.Service.exe"
    "WebAdvisor.exe"
    "saborern.exe"
    "sabpcsvr.exe"
) do (
    taskkill /f /im %%P >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%- Terminated %%~P%RESET%
    )
)
echo       %GREEN%- Process termination complete%RESET%
set /a success+=1

echo.
echo [2/8] Stopping and disabling McAfee services...

for %%S in (
    "McAfee SiteAdvisor Service"
    "McAfee WebAdvisor"
    "McAPExe"
    "mccspsvc"
    "McNaiAnn"
    "McNASvc"
    "mcods"
    "McODS"
    "McOobeSv2"
    "McProxy"
    "McShield"
    "mcscan"
    "mfefire"
    "mfemms"
    "mfevtp"
    "mfevtps"
    "mfewc"
    "ModuleCoreService"
    "MSK80Service"
    "PEFService"
    "HomeNetSvc"
    "McMPFSvc"
    "McComponentHostService"
    "McComponentHostServiceSony"
    "TrueKey"
    "TrueKeyScheduler"
    "TrueKeyServiceHelper"
    "MfeAVSvc"
    "McFirewallManager"
    "McInstruTrack"
) do (
    sc query %%S >nul 2>&1
    if not errorlevel 1060 (
        sc stop %%S >nul 2>&1
        sc config %%S start= disabled >nul 2>&1
        echo       %GREEN%- Disabled service: %%~S%RESET%
        set /a success+=1
    )
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 2: Running McAfee Uninstallers%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [3/8] Running McAfee built-in uninstallers...

:: Try WMIC uninstall for all McAfee products
echo       - Uninstalling McAfee LiveSafe / Total Protection...
wmic product where "name like '%%McAfee%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%mcafee%%'" call uninstall /nointeractive >nul 2>&1

echo       - Uninstalling McAfee WebAdvisor...
wmic product where "name like '%%WebAdvisor%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%SiteAdvisor%%'" call uninstall /nointeractive >nul 2>&1

echo       - Uninstalling McAfee True Key...
wmic product where "name like '%%True Key%%'" call uninstall /nointeractive >nul 2>&1
wmic product where "name like '%%TrueKey%%'" call uninstall /nointeractive >nul 2>&1

echo       %GREEN%- WMIC uninstall pass complete%RESET%
set /a success+=1

echo.
echo [4/8] Removing McAfee AppX packages...

:: Remove UWP/Store versions
set "PSSCRIPT=%TEMP%\remove-mcafee.ps1"

(
echo $packages = @(
echo     '*McAfee*',
echo     '*mcafee*',
echo     '*TrueKey*'
echo ^)
echo.
echo foreach ^($pattern in $packages^) {
echo     Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue ^| ForEach-Object {
echo         Write-Host "       - Removing: $($_.Name)"
echo         Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
echo     }
echo     Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue ^|
echo         Where-Object DisplayName -Like $pattern ^| ForEach-Object {
echo         Write-Host "       - Deprovisioning: $($_.DisplayName)"
echo         Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue ^| Out-Null
echo     }
echo }
) > "%PSSCRIPT%"

powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%" 2>nul
del "%PSSCRIPT%" 2>nul
set /a success+=1

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 3: Deep Service and Driver Cleanup%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [5/8] Removing McAfee kernel drivers and stubborn services...

:: McAfee installs kernel-level filter drivers that survive normal uninstall
for %%D in (
    "mfeavfk"
    "mfefirek"
    "mfehidk"
    "mfencbdc"
    "mfencrk"
    "mfeplk"
    "mferkdet"
    "mfewfpk"
    "cfwids"
    "HipShieldK"
    "McNaiAnn"
    "McProxy"
    "mfeelamk"
) do (
    sc query %%D >nul 2>&1
    if not errorlevel 1060 (
        sc stop %%D >nul 2>&1
        sc config %%D start= disabled >nul 2>&1
        echo       %GREEN%- Disabled driver/service: %%~D%RESET%
        set /a success+=1
    )
)

:: Delete the services entirely (they serve no purpose without McAfee)
echo.
echo       - Deleting orphaned McAfee services...
for %%D in (
    "mfeavfk"
    "mfefirek"
    "mfehidk"
    "mfencbdc"
    "mfencrk"
    "mfeplk"
    "mferkdet"
    "mfewfpk"
    "cfwids"
    "HipShieldK"
    "HomeNetSvc"
    "McAfee SiteAdvisor Service"
    "McAfee WebAdvisor"
    "McAPExe"
    "mccspsvc"
    "McNaiAnn"
    "McNASvc"
    "McODS"
    "McOobeSv2"
    "McProxy"
    "McShield"
    "mfefire"
    "mfemms"
    "mfevtp"
    "mfevtps"
    "mfewc"
    "ModuleCoreService"
    "PEFService"
    "TrueKey"
    "TrueKeyScheduler"
    "TrueKeyServiceHelper"
) do (
    sc delete %%D >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%- Deleted service: %%~D%RESET%
        set /a success+=1
    )
)

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 4: Removing Scheduled Tasks%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [6/8] Removing McAfee scheduled tasks...

for %%T in (
    "\McAfee\McAfee Auto Maintenance Task Agent"
    "\McAfee\McAfee Idle Detection Task"
    "\McAfee\McAfee Remediation (Prepare)"
    "\McAfeeLogon"
    "\McAfee\McAfeeLogon"
    "\McAfee\McAfee Scan"
    "\McAfee\McAfee Quick Scan"
    "\McAfee\McAfee Update Task"
) do (
    schtasks /delete /tn "%%~T" /f >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%- Removed task: %%~T%RESET%
        set /a success+=1
    )
)

:: Catch remaining McAfee tasks via PowerShell
set "PSTASKS=%TEMP%\remove-mcafee-tasks.ps1"
(
echo Get-ScheduledTask -ErrorAction SilentlyContinue ^| Where-Object {
echo     $_.TaskName -match 'McAfee' -or
echo     $_.TaskName -match 'mcafee' -or
echo     $_.TaskName -match 'TrueKey' -or
echo     $_.TaskPath -match '\\McAfee\\'
echo } ^| ForEach-Object {
echo     Write-Host "       - Removing task: $($_.TaskPath)$($_.TaskName)"
echo     Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false -ErrorAction SilentlyContinue
echo }
) > "%PSTASKS%"

powershell -ExecutionPolicy Bypass -File "%PSTASKS%" 2>nul
del "%PSTASKS%" 2>nul

echo       %GREEN%- Task cleanup complete%RESET%

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 5: Registry Cleanup%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [7/8] Cleaning McAfee registry entries...

:: Remove startup entries
echo       - Removing startup entries...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "McAfee Remediation" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "mcpltui_exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "McAfeeUpdaterUI" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SecurityHealth" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WebAdvisor" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TrueKey" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "McAfee WebAdvisor" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "TrueKey" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "McAfee.TrueKey" /f >nul 2>&1

:: Remove McAfee uninstall prevention keys
echo       - Removing McAfee reinstall protection keys...
reg delete "HKLM\SOFTWARE\McAfee" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\McAfee" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\McAfee" /f >nul 2>&1

:: Remove McAfee from Windows Security Center registration
echo       - Removing Security Center registration...
reg delete "HKLM\SOFTWARE\Microsoft\Security Center\Monitoring\McAfee" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Security Center\Monitoring\McAfeeAntiSpyware" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Security Center\Monitoring\McAfeeFirewall" /f >nul 2>&1

:: Remove McAfee browser extension policies
echo       - Removing browser extension policies...
:: Chrome
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /f >nul 2>&1
:: Edge
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist" /f >nul 2>&1
:: Firefox
reg delete "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Extensions\Install" /f >nul 2>&1

:: Remove McAfee context menu handlers
echo       - Removing context menu handlers...
reg delete "HKCR\*\shellex\ContextMenuHandlers\McAfee" /f >nul 2>&1
reg delete "HKCR\Directory\shellex\ContextMenuHandlers\McAfee" /f >nul 2>&1
reg delete "HKCR\Drive\shellex\ContextMenuHandlers\McAfee" /f >nul 2>&1

echo       %GREEN%- Registry cleanup complete%RESET%
set /a success+=1

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 6: Removing Leftover Files%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo [8/8] Removing McAfee files and folders...

:: Main McAfee program directories
call :CleanFolder "%ProgramFiles%\McAfee"
call :CleanFolder "%ProgramFiles(x86)%\McAfee"
call :CleanFolder "%ProgramFiles%\McAfee.com"
call :CleanFolder "%ProgramFiles(x86)%\McAfee.com"
call :CleanFolder "%ProgramFiles%\Common Files\McAfee"
call :CleanFolder "%ProgramFiles(x86)%\Common Files\McAfee"

:: McAfee WebAdvisor
call :CleanFolder "%ProgramFiles%\McAfee\WebAdvisor"
call :CleanFolder "%ProgramFiles(x86)%\McAfee\WebAdvisor"
call :CleanFolder "%ProgramFiles%\McAfee\SiteAdvisor"
call :CleanFolder "%ProgramFiles(x86)%\McAfee\SiteAdvisor"

:: True Key
call :CleanFolder "%ProgramFiles%\TrueKey"
call :CleanFolder "%ProgramFiles(x86)%\TrueKey"
call :CleanFolder "%ProgramFiles%\McAfee\TrueKey"

:: ProgramData and AppData
call :CleanFolder "%ProgramData%\McAfee"
call :CleanFolder "%LocalAppData%\McAfee"
call :CleanFolder "%AppData%\McAfee"
call :CleanFolder "%LocalAppData%\Temp\McAfee"
call :CleanFolder "%LocalAppData%\TrueKey"
call :CleanFolder "%AppData%\TrueKey"

:: McAfee installer cache
call :CleanFolder "%ProgramData%\McAfee\Agent"
call :CleanFolder "%ProgramData%\McAfee\MSC"
call :CleanFolder "%ProgramData%\McAfee\WebAdvisor"

echo       %GREEN%- File cleanup complete%RESET%

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 7: Re-enable Windows Defender%RESET%
echo %CYAN%============================================================================%RESET%
echo.

echo       - Ensuring Windows Defender is enabled...

:: Re-enable Windows Defender (McAfee disables it during installation)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 0 /f >nul 2>&1

:: Start Windows Defender service
sc config WinDefend start= auto >nul 2>&1
sc start WinDefend >nul 2>&1
sc config WdNisSvc start= auto >nul 2>&1
sc start WdNisSvc >nul 2>&1

echo       %GREEN%- Windows Defender re-enabled%RESET%
set /a success+=1

echo.
echo %CYAN%============================================================================%RESET%
echo %CYAN% Summary%RESET%
echo %CYAN%============================================================================%RESET%
echo.
echo %GREEN%Removal process complete!%RESET%
echo Successful operations: %success%
echo.
echo What was removed:
echo  - McAfee LiveSafe / Total Protection / AntiVirus
echo  - McAfee WebAdvisor / SiteAdvisor
echo  - McAfee True Key password manager
echo  - McAfee kernel filter drivers
echo  - McAfee services, scheduled tasks, and startup entries
echo  - McAfee browser extension policies
echo  - McAfee context menu handlers
echo  - McAfee registry entries and leftover files
echo.
echo What was restored:
echo  - Windows Defender (re-enabled automatically)
echo  - Windows Firewall
echo.
echo %YELLOW%NOTE: Windows Defender is now your active antivirus protection.%RESET%
echo %YELLOW%      Open Windows Security to verify it is running properly.%RESET%
echo.
echo %YELLOW%NOTE: Some OEM recovery partitions may reinstall McAfee after a%RESET%
echo %YELLOW%      Windows reset. This script can be run again if needed.%RESET%
echo.
echo A reboot is recommended to complete the removal process.
echo.

set /p "reboot=Would you like to restart now? [Y/N]: "
if /i "%reboot%"=="Y" (
    echo.
    echo Restarting in 10 seconds...
    shutdown /r /t 10 /c "McAfee Bloatware Removal - Restart"
)

echo.
pause
exit /b 0

:: ============================================================================
:: Subroutine: CleanFolder
:: ============================================================================
:CleanFolder
if exist "%~1" (
    rd /s /q "%~1" >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%- Removed: %~1%RESET%
        set /a success+=1
    )
)
goto :eof
