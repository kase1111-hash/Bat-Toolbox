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
echo/

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%[ERROR] This script requires Administrator privileges.%RESET%
    echo %RED%Please right-click and select "Run as administrator"%RESET%
    echo/
    pause
    exit /b 1
)

echo This script removes all McAfee products that ship preinstalled on OEM PCs.
echo/
echo %YELLOW%What will be REMOVED:%RESET%
echo  - McAfee LiveSafe / Total Protection / AntiVirus
echo  - McAfee WebAdvisor / SiteAdvisor
echo  - McAfee True Key (password manager)
echo  - McAfee Personal Security / Privacy
echo  - McAfee services, scheduled tasks, and startup entries
echo  - McAfee browser extensions and remnants
echo/
echo %GREEN%What will be KEPT:%RESET%
echo  - Windows Defender / Windows Security (will auto-activate)
echo  - Windows Firewall
echo  - All other security software
echo/
echo %YELLOW%NOTE: Windows Defender will automatically enable itself after McAfee%RESET%
echo %YELLOW%      is removed. Your system will remain protected.%RESET%
echo/
echo %YELLOW%NOTE: McAfee's own uninstaller runs first - follow its window if one opens.%RESET%
echo %YELLOW%      The forced cleanup only runs once no McAfee product is installed.%RESET%
echo/

:: Confirm before proceeding
set "confirm="
set /p "confirm=Do you want to continue? [Y/N]: "
if /i not "%confirm%"=="Y" (
    echo/
    echo Operation cancelled.
    pause
    exit /b 0
)

set "success=0"

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 1: Running McAfee Uninstallers%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [1/8] Running McAfee's own registered uninstallers...

:: McAfee LiveSafe / Total Protection, WebAdvisor and True Key are not MSI
:: packages, so Win32_Product (the old "wmic product ... call uninstall") never
:: saw them. Run the uninstaller each McAfee product registered in Apps and
:: Features instead (msiexec /x for the MSI ones), then check what is left.
:: The forced service, driver, registry and file cleanup below only runs once
:: no McAfee product is registered as installed, because force-deleting a live,
:: self-protected McAfee install leaves it half-removed and unrepairable.
set "PSUNINSTALL=%TEMP%\mcafee-uninstall.ps1"
(
echo # Exit code 0 = no McAfee product is registered as installed, 1 = some remain.
echo $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
echo function Get-McAfeeEntries {
echo     Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue ^|
echo         Where-Object { $_.DisplayName -match 'McAfee^|True ?Key^|WebAdvisor^|SiteAdvisor' -and $_.UninstallString }
echo }
echo foreach ^($e in @^(Get-McAfeeEntries^)^) {
echo     # Skip entries already removed by an earlier uninstaller in this loop
echo     if ^(-not ^(Test-Path -LiteralPath $e.PSPath^)^) { continue }
echo     $cmd = if ^($e.QuietUninstallString^) { $e.QuietUninstallString } else { $e.UninstallString }
echo     # MSI: uninstall silently. Otherwise quote an unquoted "C:\Program Files\...exe" path for cmd.
echo     $q = [string][char]34
echo     if ^($cmd -match 'msiexec' -and $e.PSChildName -match '^^\{[0-9A-Fa-f-]{36}\}$'^) { $cmd = "msiexec.exe /x $($e.PSChildName) /qn /norestart" } elseif ^(-not $cmd.TrimStart^(^).StartsWith^($q^) -and $cmd -match '^^\s*^(.+?\.exe^)^(.*^)$'^) { $cmd = $q + $Matches[1] + $q + $Matches[2] }
echo     Write-Host "       - Uninstalling: $($e.DisplayName) (follow the McAfee window if one opens)"
echo     Start-Process -FilePath $env:ComSpec -ArgumentList "/d /s /c `"$cmd`"" -Wait
echo }
echo $left = @^(Get-McAfeeEntries^)
echo foreach ^($e in $left^) { Write-Host "       - Still installed: $($e.DisplayName)" -ForegroundColor Red }
echo if ^($left.Count -gt 0^) { exit 1 }
echo exit 0
) > "%PSUNINSTALL%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSUNINSTALL%" 2>nul
if %errorlevel% neq 0 (
    del "%PSUNINSTALL%" 2>nul
    echo/
    echo       %RED%- McAfee is still installed, so the forced cleanup was NOT run.%RESET%
    echo       %YELLOW%  If the McAfee uninstaller asked for a restart, restart and run this script again.%RESET%
    echo       %YELLOW%  Otherwise uninstall it from Settings ^> Apps, or with McAfee's MCPR removal%RESET%
    echo       %YELLOW%  tool, then run this script again to remove the leftovers.%RESET%
    echo/
    pause
    exit /b 1
)
del "%PSUNINSTALL%" 2>nul
echo       %GREEN%- No McAfee product is registered as installed any more%RESET%
set /a success+=1

echo/
echo [2/8] Removing McAfee AppX packages...

:: Remove UWP/Store versions
set "PSSCRIPT=%TEMP%\remove-mcafee.ps1"

(
echo $packages = @^(
echo     '*McAfee*',
echo     '*mcafee*',
echo     '*TrueKey*'
echo ^)
echo/
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

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 2: Stopping Leftover McAfee Processes and Services%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [3/8] Terminating McAfee processes...

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

echo/
echo [4/8] Stopping and disabling McAfee services...

for %%S in (
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
        if errorlevel 1 (
            echo       %RED%- Could not disable %%~S ^(access denied or blocked by McAfee self-protection^)%RESET%
        ) else (
            echo       %GREEN%- Disabled service: %%~S%RESET%
            set /a success+=1
        )
    )
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 3: Deep Service and Driver Cleanup%RESET%
echo %CYAN%============================================================================%RESET%
echo/

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
        if errorlevel 1 (
            echo       %RED%- Could not disable %%~D ^(access denied or blocked by McAfee self-protection^)%RESET%
        ) else (
            echo       %GREEN%- Disabled driver/service: %%~D%RESET%
            set /a success+=1
        )
    )
)

:: Delete the services entirely (they serve no purpose without McAfee)
echo/
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

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 4: Removing Scheduled Tasks%RESET%
echo %CYAN%============================================================================%RESET%
echo/

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

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 5: Registry Cleanup%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo [7/8] Cleaning McAfee registry entries...

:: Remove startup entries
echo       - Removing startup entries...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "McAfee Remediation" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "mcpltui_exe" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "McAfeeUpdaterUI" /f >nul 2>&1
:: NOTE: The "SecurityHealth" Run value is Windows' own Security tray icon
:: (SecurityHealthSystray.exe), NOT McAfee - deleting it removes the Windows
:: Security notification icon, so it is deliberately left alone.
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

:: Remove stale McAfee registrations from Windows Security Center.
:: Windows 10/11 keep third-party antivirus/firewall registrations in WMI
:: root\SecurityCenter2 (the old "Security Center\Monitoring" registry keys are
:: Windows XP-era and unused). Only entries whose name contains McAfee are removed.
echo       - Removing Security Center registration...
powershell -NoProfile -Command "foreach ($c in 'AntiVirusProduct','AntiSpywareProduct','FirewallProduct') { Get-CimInstance -Namespace root/SecurityCenter2 -ClassName $c -ErrorAction SilentlyContinue | Where-Object { $_.displayName -like '*McAfee*' } | Remove-CimInstance -ErrorAction SilentlyContinue }" >nul 2>&1

:: Remove McAfee browser extension policies.
:: IMPORTANT: Only the McAfee WebAdvisor entries are removed - the whole
:: ExtensionInstallForcelist / Extensions\Install key is NOT deleted, because on
:: managed machines it may force-install unrelated (legitimate) extensions.
:: McAfee WebAdvisor Chrome/Edge extension IDs are matched in each value's data.
echo       - Removing McAfee WebAdvisor browser extension policies...
for %%K in (
    "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
    "HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"
    "HKLM\SOFTWARE\Policies\Mozilla\Firefox\Extensions\Install"
) do (
    for /f "tokens=1,2,*" %%a in ('reg query "%%~K" 2^>nul ^| findstr /i /r "REG_SZ REG_EXPAND_SZ"') do (
        echo %%c | findstr /i "fheoggkfdfchfphceeifdbepaooicaho mfhcjcpoiamplklklblkbcndbppbnamn webadvisor mcafee" >nul 2>&1
        if not errorlevel 1 reg delete "%%~K" /v "%%a" /f >nul 2>&1
    )
)

:: Remove McAfee context menu handlers
echo       - Removing context menu handlers...
reg delete "HKCR\*\shellex\ContextMenuHandlers\McAfee" /f >nul 2>&1
reg delete "HKCR\Directory\shellex\ContextMenuHandlers\McAfee" /f >nul 2>&1
reg delete "HKCR\Drive\shellex\ContextMenuHandlers\McAfee" /f >nul 2>&1

echo       %GREEN%- Registry cleanup complete%RESET%
set /a success+=1

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 6: Removing Leftover Files%RESET%
echo %CYAN%============================================================================%RESET%
echo/

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

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Phase 7: Re-enable Windows Defender%RESET%
echo %CYAN%============================================================================%RESET%
echo/

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

:: WinDefend is a protected service, so the sc calls above can be denied.
:: Report what Defender actually says instead of assuming it worked.
powershell -NoProfile -Command "try { if ((Get-MpComputerStatus -ErrorAction Stop).AntivirusEnabled) { exit 0 } } catch {} ; exit 1" >nul 2>&1
if %errorlevel% neq 0 (
    echo       %YELLOW%- Windows Defender is not active yet - restart, then check Windows Security%RESET%
) else (
    echo       %GREEN%- Windows Defender is active%RESET%
    set /a success+=1
)

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Summary%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo %GREEN%Removal process complete^^!%RESET%
echo Successful operations: %success%
echo/
echo What was removed:
echo  - McAfee LiveSafe / Total Protection / AntiVirus
echo  - McAfee WebAdvisor / SiteAdvisor
echo  - McAfee True Key password manager
echo  - McAfee kernel filter drivers
echo  - McAfee services, scheduled tasks, and startup entries
echo  - McAfee browser extension policies
echo  - McAfee context menu handlers
echo  - McAfee registry entries and leftover files
echo/
echo What was restored:
echo  - Windows Defender (re-enable requested - see Phase 7 above for its state)
echo  - Windows Firewall
echo/
echo %YELLOW%NOTE: After the restart, open Windows Security and confirm Windows Defender%RESET%
echo %YELLOW%      is on. If McAfee is still listed there as your antivirus, run%RESET%
echo %YELLOW%      McAfee's MCPR removal tool.%RESET%
echo/
echo %YELLOW%NOTE: Some OEM recovery partitions may reinstall McAfee after a%RESET%
echo %YELLOW%      Windows reset. This script can be run again if needed.%RESET%
echo/
echo A reboot is recommended to complete the removal process.
echo/

set "reboot="
set /p "reboot=Would you like to restart now? [Y/N]: "
if /i "%reboot%"=="Y" (
    echo/
    echo Restarting in 10 seconds...
    shutdown /r /t 10 /c "McAfee Bloatware Removal - Restart"
)

echo/
pause
exit /b 0

:: ============================================================================
:: Subroutine: CleanFolder
:: ============================================================================
:CleanFolder
:: No ( ) block here: the folder argument is often "C:\Program Files (x86)\..."
:: and its ")" would close a block early and abort the whole script. RD does
:: not reset ERRORLEVEL on success, so check whether the folder is really gone.
if not exist "%~1\" goto :eof
rd /s /q "%~1" >nul 2>&1
if exist "%~1\" goto :eof
echo       %GREEN%- Removed: %~1%RESET%
set /a success+=1
goto :eof
