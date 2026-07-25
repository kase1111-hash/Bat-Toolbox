@echo off
:: =====================================================================
:: disable_asus_updatechecker.bat
::
:: Belt-and-suspenders disable of AsusUpdateChecker.exe (the binary
:: spoofed in 129 of 132 tripwire events) plus AsusSoftwareManagerAgent.exe
:: (the other 3). Reversible. Run as Administrator.
::
:: Layers applied (each independent, any one is usually sufficient):
::   1. Kill any running instances right now
::   2. Find and disable scheduled tasks that reference the binary
::   3. Install an IFEO debugger redirect (intercepts every future launch
::      regardless of who invoked it or where it lives on disk)
::   4. Disable any service whose ImagePath references the binary
::
:: To undo a layer manually:
::   1. (no undo needed - process is gone)
::   2. schtasks /Change /TN "<task name>" /ENABLE
::   3. reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\
::                  Image File Execution Options\AsusUpdateChecker.exe" /f
::   4. sc config "<service>" start= auto  (or whatever it was)
:: =====================================================================

setlocal enabledelayedexpansion
set "TARGET=AsusUpdateChecker.exe"
set "SECONDARY=AsusSoftwareManagerAgent.exe"
set "STUB=%SystemRoot%\System32\systray.exe"
set "IFEO_BASE=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"

:: --- Admin check ---
net session >nul 2>&1
if errorlevel 1 (
    echo [FATAL] This script must be run as Administrator.
    echo         Right-click the .bat and choose "Run as administrator".
    pause
    exit /b 1
)

echo/
echo ==========================================================
echo  Disabling %TARGET% via four layers
echo ==========================================================
echo/

set /a KILLED=0
set /a TASKS_DISABLED=0
set /a IFEO_INSTALLED=0
set /a SERVICES_DISABLED=0

:: ===== Layer 1: kill running instances =====
echo [1/4] Killing any running instances...
for %%E in ("%TARGET%" "%SECONDARY%") do (
    tasklist /FI "IMAGENAME eq %%~E" 2>nul | find /I "%%~E" >nul
    if not errorlevel 1 (
        taskkill /F /IM "%%~E" /T >nul 2>&1
        if not errorlevel 1 (
            echo       Killed %%~E.
            set /a KILLED+=1
        ) else (
            echo       Found %%~E running, but kill failed.
        )
    ) else (
        echo       %%~E not currently running.
    )
)
echo/

:: ===== Layer 2: disable scheduled tasks =====
echo [2/4] Scanning scheduled tasks for references to %TARGET%...
:: schtasks /FO CSV emits TaskName as the first comma-separated field.
:: For each task, query its verbose detail and grep for our binary.
for /f "skip=1 tokens=1 delims=," %%T in ('schtasks /Query /FO CSV /NH 2^>nul') do (
    set "tname=%%~T"
    if not "!tname!"=="" if /I not "!tname!"=="TaskName" (
        schtasks /Query /TN "!tname!" /V /FO LIST 2>nul | findstr /I "%TARGET% %SECONDARY%" >nul
        if not errorlevel 1 (
            echo       Found: !tname!
            schtasks /Change /TN "!tname!" /DISABLE >nul 2>&1
            if not errorlevel 1 (
                echo         -^> disabled.
                set /a TASKS_DISABLED+=1
            ) else (
                echo         -^> disable FAILED ^(check task path/permissions^).
            )
        )
    )
)
if !TASKS_DISABLED! EQU 0 echo       No scheduled tasks reference the targets.
echo/

:: ===== Layer 3: IFEO debugger redirect =====
echo [3/4] Installing IFEO redirect for %TARGET%...
:: Windows checks this key by binary basename before launching any process.
:: Pointing "Debugger" at systray.exe (a harmless Windows stub) means
:: any future attempt to launch the target is intercepted and no-ops.
:: Catches the binary regardless of who invokes it or where it lives.
for %%E in ("%TARGET%" "%SECONDARY%") do (
    reg add "%IFEO_BASE%\%%~E" /v "Debugger" /t REG_SZ /d "%STUB%" /f >nul 2>&1
    if not errorlevel 1 (
        echo       Installed redirect for %%~E.
        set /a IFEO_INSTALLED+=1
    ) else (
        echo       FAILED to install IFEO key for %%~E.
    )
)
echo/

:: ===== Layer 4: disable services that launch the binary =====
echo [4/4] Scanning services for references to %TARGET%...
for /f "tokens=2" %%S in ('sc query state^= all 2^>nul ^| findstr /I "SERVICE_NAME"') do (
    sc qc "%%S" 2>nul | findstr /I "%TARGET% %SECONDARY%" >nul
    if not errorlevel 1 (
        echo       Found service: %%S
        sc stop "%%S" >nul 2>&1
        sc config "%%S" start= disabled >nul 2>&1
        if not errorlevel 1 (
            echo         -^> stopped and disabled.
            set /a SERVICES_DISABLED+=1
        ) else (
            echo         -^> disable FAILED.
        )
    )
)
if !SERVICES_DISABLED! EQU 0 echo       No services reference the targets.
echo/

:: ===== Report =====
echo ==========================================================
echo  Summary
echo ==========================================================
echo   Running instances killed:   !KILLED!
echo   Scheduled tasks disabled:   !TASKS_DISABLED!
echo   IFEO redirects installed:   !IFEO_INSTALLED!  (out of 2)
echo   Services disabled:          !SERVICES_DISABLED!
echo/
echo  Watch tripwire.log over the next 24 hours. New firings should
echo  drop to zero. If anything still appears, the new entries will
echo  reveal the launcher we missed - share them and we'll pinpoint it.
echo/

endlocal
pause
exit /b 0
