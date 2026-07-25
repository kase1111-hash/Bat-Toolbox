@echo off
REM ============================================================================
REM  kill-dosvc.bat
REM  Disable Delivery Optimization (DoSvc) — the P2P Windows Update layer that
REM  uploads update bits from your machine to other PCs on the internet using
REM  YOUR bandwidth and data without meaningful consent.
REM
REM  Critical companion target: WaaSMedicSvc (Windows Update Medic Service).
REM  WaaSMedic actively detects "tampered" update components and reverts them.
REM  Disabling DoSvc without disabling WaaSMedic first means DoSvc gets
REM  silently restored on the next medic remediation pass. WaaSMedic's reg
REM  key is TrustedInstaller-protected, so this script escalates ownership
REM  the same way the Dnscache script did.
REM
REM  What gets touched:
REM    1) WaaSMedicSvc:                 Stop + Start=4 (with ownership escalation)
REM    2) DoSvc:                        Stop + Start=4
REM    3) DODownloadMode policy:        0 (HTTP-only, no peering)
REM    4) WaaSMedic scheduled tasks:    Disabled
REM    5) HOSTS file:                   Null-route DO-specific endpoints
REM    6) Firewall:                     Block svchost service=DoSvc + TCP 7680
REM
REM  What still works:
REM    - Windows Update (downloads direct from Microsoft instead of P2P)
REM    - Microsoft Store updates (slower but functional)
REM    - Defender signature updates
REM
REM  Reversal: see RESTORE block at bottom.
REM ============================================================================

setlocal enabledelayedexpansion

net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: Run as Administrator.
    pause
    exit /b 1
)

echo/
echo === PHASE 1 / RECON =======================================================
echo DoSvc:
sc qc DoSvc 2>nul | findstr /i "START_TYPE"
sc query DoSvc 2>nul | findstr /i "STATE"
echo/
echo WaaSMedicSvc ^(the auto-reverter^):
sc qc WaaSMedicSvc 2>nul | findstr /i "START_TYPE"
sc query WaaSMedicSvc 2>nul | findstr /i "STATE"
echo/
echo Current DODownloadMode:
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode 2>nul
echo/

echo === PHASE 2 / DISABLE WAASMEDICSVC FIRST ==================================
REM This must be first. If WaaSMedic is alive when we disable DoSvc, it will
REM revert the change on its next remediation pass.

sc stop WaaSMedicSvc >nul 2>&1
sc failure WaaSMedicSvc reset= 0 actions= //// >nul 2>&1

reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
if errorlevel 1 goto :MedicEscalate
echo WaaSMedicSvc: Start=4 ^(Disabled^).
goto :PostMedic

:MedicEscalate
echo Direct write blocked. Escalating ownership for WaaSMedicSvc...
call :TakeOwnership "SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
if errorlevel 1 (
    echo WARNING: Could not disable WaaSMedicSvc. DoSvc may revert.
) else (
    echo WaaSMedicSvc: Start=4 ^(via escalation^).
)

:PostMedic
REM Also disable the WaaSMedicPS triggered task that can resurrect things
sc stop WaaSMedicSvc >nul 2>&1
echo/

echo === PHASE 3 / DISABLE DOSVC ===============================================
sc stop DoSvc >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" /v Start /t REG_DWORD /d 4 /f >nul
if errorlevel 1 (
    echo WARNING: Could not write DoSvc Start value.
) else (
    echo DoSvc: Start=4 ^(Disabled^).
)
echo/

echo === PHASE 4 / SET DELIVERY OPTIMIZATION POLICY ============================
REM DODownloadMode values:
REM   0   = HTTP only, no peering (what we want)
REM   1   = HTTP + LAN peering
REM   2   = HTTP + Group peering
REM   3   = HTTP + Internet peering (default — the privacy violation)
REM   100 = Bypass DO entirely, use BITS (can break Store)

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DOMaxBackgroundDownloadBandwidth /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DOMaxForegroundDownloadBandwidth /t REG_DWORD /d 1 /f >nul
echo Policy: DODownloadMode=0 ^(HTTP only, no peering^).
echo/

echo === PHASE 5 / DISABLE WAASMEDIC SCHEDULED TASKS ===========================
call :KillTask "\Microsoft\Windows\WaaSMedic\PerformRemediation"
call :KillTask "\Microsoft\Windows\UpdateOrchestrator\USO_BootRebootTask"
call :KillTask "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
echo/

echo === PHASE 6 / NULL-ROUTE DELIVERY OPTIMIZATION ENDPOINTS ==================
REM HOSTS file does not support wildcards. These are the most common static
REM FQDNs DoSvc reaches. For comprehensive coverage use a real DNS sinkhole
REM (Pi-hole, Unbound with blocklist, AdGuard Home).
set "HOSTSFILE=%SystemRoot%\System32\drivers\etc\hosts"
copy /Y "%HOSTSFILE%" "%HOSTSFILE%.bak.dosvc" >nul 2>&1
echo Backup: %HOSTSFILE%.bak.dosvc

call :AddHostsBlock "geo.prod.do.dsp.mp.microsoft.com"
call :AddHostsBlock "kv501.prod.do.dsp.mp.microsoft.com"
call :AddHostsBlock "cp401.prod.do.dsp.mp.microsoft.com"
call :AddHostsBlock "cp501.prod.do.dsp.mp.microsoft.com"
call :AddHostsBlock "cp601.prod.do.dsp.mp.microsoft.com"
call :AddHostsBlock "cp701.prod.do.dsp.mp.microsoft.com"
call :AddHostsBlock "cs.dds.microsoft.com"
call :AddHostsBlock "emdl.ws.microsoft.com"
call :AddHostsBlock "v10.delivery.mp.microsoft.com"
call :AddHostsBlock "v20.delivery.mp.microsoft.com"
call :AddHostsBlock "tlu.dl.delivery.mp.microsoft.com"
call :AddHostsBlock "ctldl.windowsupdate.com.delivery.mp.microsoft.com"
echo/

echo === PHASE 7 / FIREWALL RULES ==============================================
netsh advfirewall firewall delete rule name="BLOCK DoSvc service" >nul 2>&1
netsh advfirewall firewall delete rule name="BLOCK DO P2P port 7680 in" >nul 2>&1
netsh advfirewall firewall delete rule name="BLOCK DO P2P port 7680 out" >nul 2>&1

netsh advfirewall firewall add rule name="BLOCK DoSvc service" dir=out action=block service=DoSvc enable=yes profile=any >nul
netsh advfirewall firewall add rule name="BLOCK DO P2P port 7680 in" dir=in action=block protocol=TCP localport=7680 enable=yes profile=any >nul
netsh advfirewall firewall add rule name="BLOCK DO P2P port 7680 out" dir=out action=block protocol=TCP remoteport=7680 enable=yes profile=any >nul
echo Firewall rules added: service=DoSvc and TCP 7680 in/out blocked.
echo/

echo === PHASE 8 / VERIFY ======================================================
echo DoSvc:
sc qc DoSvc | findstr /i "START_TYPE"
sc query DoSvc | findstr /i "STATE"
echo/
echo WaaSMedicSvc:
sc qc WaaSMedicSvc | findstr /i "START_TYPE"
sc query WaaSMedicSvc | findstr /i "STATE"
echo/
echo DODownloadMode policy:
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode

echo/
echo ===========================================================================
echo  DONE. Reboot recommended to clear in-flight DO uploads/downloads and
echo  ensure WaaSMedic doesn't get one last remediation pass.
echo  Verify after reboot:
echo    sc query DoSvc           ^( STATE: STOPPED ^)
echo    sc qc DoSvc              ^( START_TYPE: DISABLED ^)
echo    sc query WaaSMedicSvc    ^( STATE: STOPPED ^)
echo    sc qc WaaSMedicSvc       ^( START_TYPE: DISABLED ^)
echo ===========================================================================
pause
exit /b 0


REM ===========================================================================
REM  Subroutines
REM ===========================================================================

:KillTask
schtasks /Change /TN %~1 /Disable >nul 2>&1
if errorlevel 1 (
    echo   [skip] %~1
) else (
    echo   [off]  %~1
)
exit /b 0

:AddHostsBlock
findstr /i /c:"%~1" "%HOSTSFILE%" >nul 2>&1
if errorlevel 1 (
    echo 0.0.0.0 %~1>> "%HOSTSFILE%"
    echo   [+] %~1
) else (
    echo   [=] %~1 ^(already present^)
)
exit /b 0

:TakeOwnership
REM  $1 = registry subkey path under HKLM
powershell -NoProfile -Command ^
  "$k = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('%~1', 'ReadWriteSubTree', 'TakeOwnership');" ^
  "$acl = $k.GetAccessControl();" ^
  "$acl.SetOwner([System.Security.Principal.NTAccount]'BUILTIN\Administrators');" ^
  "$k.SetAccessControl($acl);" ^
  "$k.Close();" ^
  "$k = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('%~1', 'ReadWriteSubTree', 'ChangePermissions');" ^
  "$acl = $k.GetAccessControl();" ^
  "$rule = New-Object System.Security.AccessControl.RegistryAccessRule('BUILTIN\Administrators','FullControl','Allow');" ^
  "$acl.AddAccessRule($rule);" ^
  "$k.SetAccessControl($acl);" ^
  "$k.Close()" 2>nul
exit /b 0


REM ===========================================================================
REM  RESTORE -- run as admin to revert:
REM
REM    sc config DoSvc start= auto
REM    sc config WaaSMedicSvc start= demand
REM    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /f
REM    netsh advfirewall firewall delete rule name="BLOCK DoSvc service"
REM    netsh advfirewall firewall delete rule name="BLOCK DO P2P port 7680 in"
REM    netsh advfirewall firewall delete rule name="BLOCK DO P2P port 7680 out"
REM    copy /Y "%SystemRoot%\System32\drivers\etc\hosts.bak.dosvc" "%SystemRoot%\System32\drivers\etc\hosts"
REM    REM Re-enable scheduled tasks: schtasks /Change /TN "<task path>" /Enable
REM    REM then reboot
REM ===========================================================================
