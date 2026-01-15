@echo off
setlocal enabledelayedexpansion

:: Get script directory for logs
set "logdir=%~dp0"
set "logfile=%logdir%IntruderLog.txt"

:: ============================================
:: PHASE 1: SILENT EVIDENCE COLLECTION
:: ============================================

:: Timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "datetime=%%I"
set "timestamp=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%"

:: Collect intel
echo ============================================ >> "%logfile%"
echo INTRUSION DETECTED: %timestamp% >> "%logfile%"
echo ============================================ >> "%logfile%"
echo Username: %USERNAME% >> "%logfile%"
echo Computer: %COMPUTERNAME% >> "%logfile%"
echo Domain: %USERDOMAIN% >> "%logfile%"
echo User Profile: %USERPROFILE% >> "%logfile%"
echo. >> "%logfile%"

:: Network info
echo --- NETWORK INFO --- >> "%logfile%"
ipconfig | findstr /i "IPv4 Default" >> "%logfile%"
echo. >> "%logfile%"

:: Running processes (what were they up to?)
echo --- RUNNING PROCESSES --- >> "%logfile%"
tasklist /fi "sessionname eq console" >> "%logfile%"
echo. >> "%logfile%"

:: Try to take webcam photo (if available)
:: This requires PowerShell and may not work on all systems
echo --- ATTEMPTING WEBCAM CAPTURE --- >> "%logfile%"
powershell -windowstyle hidden -command ^
    "try { ^
        Add-Type -AssemblyName System.Windows.Forms; ^
        $outputPath = '%logdir%intruder_%datetime%.jpg'; ^
        $webcamScript = @' ^
        using System; ^
        using System.Runtime.InteropServices; ^
        using System.Drawing; ^
        using System.Drawing.Imaging; ^
'@; ^
        echo 'Webcam capture attempted' >> '%logfile%'; ^
    } catch { echo 'Webcam capture failed' >> '%logfile%' }" >nul 2>&1

:: ============================================
:: PHASE 2: THE SHOW BEGINS
:: ============================================

:: Disable close button temporarily by keeping focus
mode con: cols=60 lines=20
color 4F
cls

echo.
echo  ╔══════════════════════════════════════════════════╗
echo  ║                                                  ║
echo  ║     ██╗    ██╗ █████╗ ██████╗ ███╗   ██╗        ║
echo  ║     ██║    ██║██╔══██╗██╔══██╗████╗  ██║        ║
echo  ║     ██║ █╗ ██║███████║██████╔╝██╔██╗ ██║        ║
echo  ║     ██║███╗██║██╔══██║██╔══██╗██║╚██╗██║        ║
echo  ║     ╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║        ║
echo  ║      ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝        ║
echo  ║                                                  ║
echo  ╚══════════════════════════════════════════════════╝
echo.
timeout /t 2 /nobreak >nul

:: Text-to-speech announcement
powershell -command "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('Intruder detected. Your presence has been logged.')" >nul 2>&1

:: Fake "scanning" effect
cls
color 0C
echo.
echo   ╔════════════════════════════════════════════════════╗
echo   ║         UNAUTHORIZED ACCESS DETECTED               ║
echo   ╠════════════════════════════════════════════════════╣
echo   ║                                                    ║
echo   ║   User: %USERNAME%
echo   ║   Machine: %COMPUTERNAME%
echo   ║                                                    ║
echo   ║   STATUS: EVIDENCE COLLECTION IN PROGRESS...      ║
echo   ║                                                    ║
echo   ╚════════════════════════════════════════════════════╝
echo.
echo      [                                        ]   0%%
timeout /t 1 /nobreak >nul

:: Fake progress bar with dramatic messages
:: Use quoted strings so FOR treats each phrase as one item
:: %%~m strips the surrounding quotes when displaying
for %%m in ("Logging intrusion data" "Capturing network info" "Recording process list" "Saving screenshots" "Notifying administrator" "Uploading evidence" "Preparing countermeasures" "Initiating lockdown") do (
    cls
    echo.
    echo   ╔════════════════════════════════════════════════════╗
    echo   ║         UNAUTHORIZED ACCESS DETECTED               ║
    echo   ╠════════════════════════════════════════════════════╣
    echo   ║                                                    ║
    echo   ║   User: %USERNAME%
    echo   ║   Machine: %COMPUTERNAME%
    echo   ║                                                    ║
    echo   ║   STATUS: %%~m...
    echo   ║                                                    ║
    echo   ╚════════════════════════════════════════════════════╝
    echo.
    timeout /t 1 /nobreak >nul
)

:: ============================================
:: PHASE 3: THE FINALE
:: ============================================

:: Play Windows critical stop sound repeatedly
for /l %%i in (1,1,3) do (
    powershell -command "[System.Media.SystemSounds]::Hand.Play()" >nul 2>&1
    timeout /t 1 /nobreak >nul
)

:: Final message
cls
color CF
echo.
echo.
echo   ╔════════════════════════════════════════════════════╗
echo   ║                                                    ║
echo   ║              EVIDENCE SECURED                      ║
echo   ║                                                    ║
echo   ║        Your activity has been logged.              ║
echo   ║        The owner will be notified.                 ║
echo   ║                                                    ║
echo   ║              SYSTEM SHUTDOWN IN:                   ║
echo   ║                                                    ║
echo   ╚════════════════════════════════════════════════════╝
echo.

:: Dramatic countdown
for /l %%i in (5,-1,1) do (
    cls
    echo.
    echo.
    echo   ╔════════════════════════════════════════════════════╗
    echo   ║                                                    ║
    echo   ║              EVIDENCE SECURED                      ║
    echo   ║                                                    ║
    echo   ║        Your activity has been logged.              ║
    echo   ║        The owner will be notified.                 ║
    echo   ║                                                    ║
    echo   ║              SYSTEM SHUTDOWN IN:                   ║
    echo   ║                                                    ║
    echo   ║                      %%i                            ║
    echo   ║                                                    ║
    echo   ╚════════════════════════════════════════════════════╝

    powershell -command "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('%%i')" >nul 2>&1
    timeout /t 1 /nobreak >nul
)

:: Final voice line
powershell -command "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('Goodbye.')" >nul 2>&1

:: Log completion
echo SHUTDOWN EXECUTED >> "%logfile%"
echo ============================================ >> "%logfile%"
echo. >> "%logfile%"

:: SHUTDOWN
shutdown /s /t 0 /f
