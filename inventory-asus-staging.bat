@echo off
:: =====================================================================
:: inventory-asus-staging.bat   (v2)
::
:: Read-only inventory of the three "observe before deciding" services:
::   - ASUS App Service
::   - ASUS Optimization
::   - Microsoft Edge Elevation Service
::
:: PARALLEL to the tripwire system. Makes no changes.
::
:: For each target prints:
::   * Service name + state + startup type + binary path + current PID
::   * Last 20 entries from process-history.log whose path matches
::     the vendor tag (asus / edge), so you can see what's been
::     running under the same vendor.
::
:: Run as Administrator.
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

echo/
echo ==========================================================
echo  Staging Inventory (read-only)
echo ==========================================================
echo/

if not exist "%PROC_LOG%" (
    echo [WARN] %PROC_LOG% not found.
    echo        Service binaries will be reported, but recent-process
    echo        analysis will be empty.
    echo/
)

call :inspect "ASUS App Service"                 asus
call :inspect "ASUS Optimization"                asus
call :inspect "Microsoft Edge Elevation Service" edge

echo ==========================================================
echo  Decision guide
echo ==========================================================
echo   Running, no descendants  -^> candidate for direct disable
echo   Running, vendor children -^> candidate for tripwire
echo                                ^(add binaries to your existing
echo                                tripwire installer's target list^)
echo   Running, hardware ties   -^> leave alone
echo                                ^(Fn keys, fan curves, RGB, etc.^)
echo/

endlocal
pause
exit /b 0


:: =====================================================================
:: :inspect <"Display Name"> <vendor-tag>
:: =====================================================================
:inspect
set "DISPNAME=%~1"
set "VENDOR=%~2"
echo --------------------------------------------------------------
echo  %DISPNAME%
echo --------------------------------------------------------------

set "SVCNAME="
for /f "delims=" %%N in ('powershell -NoProfile -Command "(Get-Service -DisplayName '%~1' -ErrorAction SilentlyContinue).Name" 2^>nul') do set "SVCNAME=%%N"

if not defined SVCNAME (
    echo   Not found on this system.
    echo/
    goto :eof
)
echo   Service name : !SVCNAME!

:: State
for /f "tokens=3" %%S in ('sc query "!SVCNAME!" 2^>nul ^| findstr /I "STATE"') do (
    echo   State        : %%S
)

:: Startup type
for /f "tokens=2 delims=:" %%S in ('sc qc "!SVCNAME!" 2^>nul ^| findstr /I "START_TYPE"') do (
    set "ST=%%S"
    echo   Startup      :!ST!
)

:: Binary path
for /f "tokens=1,* delims=:" %%A in ('sc qc "!SVCNAME!" 2^>nul ^| findstr /I "BINARY_PATH_NAME"') do (
    echo   Binary       :%%B
)

:: Current PID
echo|set /p="   Current PID  : "
powershell -NoProfile -Command "$s = Get-CimInstance Win32_Service -Filter ('Name=' + [char]39 + '!SVCNAME!' + [char]39) -ErrorAction SilentlyContinue; if ($s -and $s.ProcessId -gt 0) { '{0} ({1})' -f $s.ProcessId, $s.State } else { 'not running' }"

:: Recent vendor processes
echo   Recent processes touching '%VENDOR%' (last 20):
if exist "%PROC_LOG%" (
    powershell -NoProfile -Command "$pat = '%VENDOR%'; $lines = @(); foreach ($f in @('%PROC_LOG_OLD%','%PROC_LOG%')) { if (Test-Path $f) { $lines += [System.IO.File]::ReadAllLines($f) } }; $hits = $lines | Where-Object { $_ -match $pat -and -not $_.StartsWith('#') } | Select-Object -Last 20; if ($hits) { foreach ($h in $hits) { $p = $h -split [char]9; if ($p.Count -ge 4) { '     {0}  PID={1,6}  PPID={2,6}  {3}' -f $p[0].Substring(0, [Math]::Min(19,$p[0].Length)), $p[1], $p[2], $p[3] } } } else { '     (none)' }"
) else (
    echo      ^(process-history.log not present^)
)

echo/
goto :eof
