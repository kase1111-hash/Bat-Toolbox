@echo off
:: =====================================================================
:: disable-asus-services.bat   (v3 - adds App Service)
::
:: Stops and disables five ASUS services confirmed as bloat:
::   - ASUS Software Manager     (update pusher; tripwire log smoking gun)
::   - ASUS Switch               (device migration; never used)
::   - ASUS System Analysis      (telemetry)
::   - ASUS System Diagnosis     (telemetry)
::   - ASUS App Service          (passive monitor; 14h+ idle, no children)
::
:: ASUS Optimization is intentionally NOT in this list - confirmed
:: parent of AsusHotkey.exe (Fn key handler).
::
:: PARALLEL to the tripwire system. Operates on the Service Control
:: Manager layer (sc config) - no binary swaps, no tripwire involvement.
:: Idempotent - safe to re-run on already-disabled services.
::
:: Reversal per service:
::   sc config "<ServiceName>" start= auto
::   sc start  "<ServiceName>"
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

echo/
echo ==========================================================
echo  Disabling 5 ASUS bloat services
echo ==========================================================
echo/

set /a STOPPED=0
set /a DISABLED=0
set /a NOT_FOUND=0

call :process "ASUS Software Manager"
call :process "ASUS Switch"
call :process "ASUS System Analysis"
call :process "ASUS System Diagnosis"
call :process "ASUS App Service"

echo ==========================================================
echo  Summary
echo ==========================================================
echo   Services disabled:           !DISABLED! / 5
echo   Services stopped this run:   !STOPPED!
echo   Services not on this system: !NOT_FOUND!
echo/
echo  ASUS Optimization left running ^(handles Fn keys via AsusHotkey.exe^).
echo/

endlocal
pause
exit /b 0


:: =====================================================================
:: :process <"Display Name">
:: =====================================================================
:process
echo --- Processing: %~1
set "SVCNAME="
for /f "delims=" %%N in ('powershell -NoProfile -Command "(Get-Service -DisplayName '%~1' -ErrorAction SilentlyContinue).Name" 2^>nul') do set "SVCNAME=%%N"

if not defined SVCNAME (
    echo       Not found on this system.
    set /a NOT_FOUND+=1
    echo/
    goto :eof
)
echo       Service name: !SVCNAME!

sc query "!SVCNAME!" 2>nul | findstr /I "RUNNING" >nul
if !ERRORLEVEL! EQU 0 (
    sc stop "!SVCNAME!" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo         -^> stopped.
        set /a STOPPED+=1
    ) else (
        echo         -^> stop FAILED.
    )
) else (
    echo         -^> already stopped.
)

sc config "!SVCNAME!" start= disabled >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo         -^> disabled.
    set /a DISABLED+=1
) else (
    echo         -^> disable FAILED.
)

echo/
goto :eof
