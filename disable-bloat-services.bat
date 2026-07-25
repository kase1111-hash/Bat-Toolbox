@echo off
:: =====================================================================
:: disable-bloat-services.bat   (v4 - extended beyond ASUS)
::
:: Two-tier service cleanup. Run as Administrator. Idempotent.
::
::   Tier 1 - Silent disable (7 services):
::     ASUS Software Manager       ASUS Switch
::     ASUS System Analysis        ASUS System Diagnosis
::     ASUS App Service            Connected Devices Platform Service
::     Connected Devices Platform User Service*  (wildcard - covers
::         the per-session instance like _7c5be)
::
::   Tier 2 - Interactive (depends on hardware):
::     Dolby DAX API Service       (only useful with Dolby Atmos
::         hardware; bat shows current state and asks y/n)
::
:: Sync Host_7c5be intentionally excluded.
:: ASUS Optimization intentionally excluded (handles Fn keys via
::   AsusHotkey.exe, confirmed via inventory).
::
:: PARALLEL to the tripwire system - operates at the SCM layer (sc
:: config), no binary swaps, no tripwire involvement.
::
:: Reversal per service:
::   sc config "<ServiceName>" start= auto
::   sc start  "<ServiceName>"
:: =====================================================================

setlocal enabledelayedexpansion

net session >nul 2>&1
if errorlevel 1 (
    echo [FATAL] Run as Administrator.
    pause
    exit /b 1
)

set "PROC_LOG=C:\ProgramData\sovereign-shell\process-history.log"
set "PROC_LOG_OLD=C:\ProgramData\sovereign-shell\process-history.old.log"

set /a STOPPED=0
set /a DISABLED=0
set /a NOT_FOUND=0
set /a SKIPPED=0

echo/
echo ==========================================================
echo  Tier 1 - Silent disable
echo ==========================================================
echo/

call :process "ASUS Software Manager"
call :process "ASUS Switch"
call :process "ASUS System Analysis"
call :process "ASUS System Diagnosis"
call :process "ASUS App Service"
call :process "Connected Devices Platform Service"
call :process "Connected Devices Platform User Service*"

echo/
echo ==========================================================
echo  Tier 2 - Hardware-dependent (you decide)
echo ==========================================================
echo/

call :process_interactive "Dolby DAX API Service" "dolby"

echo/
echo ==========================================================
echo  Summary
echo ==========================================================
echo   Services stopped this run:   !STOPPED!
echo   Services disabled:           !DISABLED!
echo   Services not on this system: !NOT_FOUND!
echo   Services skipped (n^):        !SKIPPED!
echo/
echo  Watcher should now be quiet for ASUS-branded events forever.
echo  ASUS Optimization remains running ^(Fn key handler^).
echo/

endlocal
pause
exit /b 0


:: =====================================================================
:: :process <"DisplayName or DisplayName*">
:: Loops over all services matching the (possibly wildcarded) display
:: name. Stops + disables each. Counts misses as NOT_FOUND.
:: =====================================================================
:process
echo --- Processing: %~1
set /a FOUND=0
for /f "delims=" %%N in ('powershell -NoProfile -Command "@(Get-Service -DisplayName '%~1' -ErrorAction SilentlyContinue) | ForEach-Object { $_.Name }" 2^>nul') do (
    set /a FOUND+=1
    call :stop_and_disable "%%N"
)
if !FOUND! EQU 0 (
    echo       Not found on this system.
    set /a NOT_FOUND+=1
)
echo/
goto :eof


:: =====================================================================
:: :process_interactive <"DisplayName"> <vendor-tag>
:: Shows service info and recent process-history entries matching the
:: vendor tag, then prompts y/n. On y, stops + disables. On n, skip.
:: =====================================================================
:process_interactive
echo --- Investigating: %~1
set "SVCNAME="
for /f "delims=" %%N in ('powershell -NoProfile -Command "(Get-Service -DisplayName '%~1' -ErrorAction SilentlyContinue).Name" 2^>nul') do set "SVCNAME=%%N"

if not defined SVCNAME (
    echo       Not found on this system.
    set /a NOT_FOUND+=1
    echo/
    goto :eof
)

echo       Service name: !SVCNAME!
for /f "tokens=3" %%S in ('sc query "!SVCNAME!" 2^>nul ^| findstr /I "STATE"') do echo       State: %%S
for /f "tokens=1,* delims=:" %%A in ('sc qc "!SVCNAME!" 2^>nul ^| findstr /I "BINARY_PATH_NAME"') do echo       Binary:%%B

echo       Recent processes touching '%~2' (last 10):
if exist "%PROC_LOG%" (
    powershell -NoProfile -Command "$pat='%~2'; $lines=@(); foreach ($f in @('%PROC_LOG_OLD%','%PROC_LOG%')) { if (Test-Path $f) { $lines += [System.IO.File]::ReadAllLines($f) } }; $hits = $lines | Where-Object { $_ -match $pat -and -not $_.StartsWith('#') } | Select-Object -Last 10; if ($hits) { foreach ($h in $hits) { $p = $h -split [char]9; if ($p.Count -ge 4) { '         {0}  PID={1,6}  PPID={2,6}  {3}' -f $p[0].Substring(0,[Math]::Min(19,$p[0].Length)), $p[1], $p[2], $p[3] } } } else { '         (no hits in process-history)' }"
) else (
    echo          ^(process-history.log not present^)
)
echo/

set "DECISION="
set /p "DECISION=       Disable this service? (y/n): "
if /I "!DECISION!"=="y" (
    call :stop_and_disable "!SVCNAME!"
) else (
    echo         -^> skipped.
    set /a SKIPPED+=1
)
echo/
goto :eof


:: =====================================================================
:: :stop_and_disable <ServiceName>
:: Inner helper - stops if running, disables, updates counters.
:: =====================================================================
:stop_and_disable
set "SVC=%~1"
echo       Service name: !SVC!

sc query "!SVC!" 2>nul | findstr /I "RUNNING" >nul
if !ERRORLEVEL! EQU 0 (
    sc stop "!SVC!" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo         -^> stopped.
        set /a STOPPED+=1
    ) else (
        echo         -^> stop FAILED.
    )
) else (
    echo         -^> already stopped.
)

sc config "!SVC!" start= disabled >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo         -^> disabled.
    set /a DISABLED+=1
) else (
    echo         -^> disable FAILED.
)
goto :eof
