@echo off
setlocal enabledelayedexpansion
title Firmware & Driver Version Checker
color 0B

:: ============================================================================
:: Firmware & Driver Version Checker
:: ============================================================================
:: Displays system firmware and driver versions with search-ready strings
:: for easy copy/paste to check for updates online.
:: ============================================================================

echo ============================================================================
echo  Firmware ^& Driver Version Checker
echo ============================================================================
echo.
echo Gathering system information... This may take a moment.
echo.

:: Set output file
set "EXPORT_FILE=%USERPROFILE%\Desktop\FirmwareInfo_%COMPUTERNAME%.txt"

:: Start output file
echo ============================================================================ > "%EXPORT_FILE%"
echo  FIRMWARE ^& DRIVER VERSION REPORT >> "%EXPORT_FILE%"
echo  Computer: %COMPUTERNAME% >> "%EXPORT_FILE%"
echo  Date: %DATE% %TIME% >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

:: ============================================================================
:: BIOS / UEFI Information
:: ============================================================================
echo [1/8] Checking BIOS/UEFI...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  BIOS / UEFI >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"

for /f "tokens=2 delims==" %%a in ('wmic bios get Manufacturer /value 2^>nul ^| find "="') do set "BIOS_MFR=%%a"
for /f "tokens=2 delims==" %%a in ('wmic bios get SMBIOSBIOSVersion /value 2^>nul ^| find "="') do set "BIOS_VER=%%a"
for /f "tokens=2 delims==" %%a in ('wmic bios get ReleaseDate /value 2^>nul ^| find "="') do set "BIOS_DATE=%%a"

:: Get motherboard info
for /f "tokens=2 delims==" %%a in ('wmic baseboard get Manufacturer /value 2^>nul ^| find "="') do set "MB_MFR=%%a"
for /f "tokens=2 delims==" %%a in ('wmic baseboard get Product /value 2^>nul ^| find "="') do set "MB_MODEL=%%a"

:: Format BIOS date
set "BIOS_DATE_FMT=!BIOS_DATE:~0,4!-!BIOS_DATE:~4,2!-!BIOS_DATE:~6,2!"

echo. >> "%EXPORT_FILE%"
echo   Motherboard: !MB_MFR! !MB_MODEL! >> "%EXPORT_FILE%"
echo   BIOS Version: !BIOS_VER! >> "%EXPORT_FILE%"
echo   BIOS Date: !BIOS_DATE_FMT! >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"
echo   [SEARCH] !MB_MFR! !MB_MODEL! BIOS update >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

echo   Motherboard: !MB_MFR! !MB_MODEL!
echo   BIOS: !BIOS_VER! [!BIOS_DATE_FMT!]

:: ============================================================================
:: CPU Information
:: ============================================================================
echo [2/8] Checking CPU...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  CPU >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"

for /f "tokens=2 delims==" %%a in ('wmic cpu get Name /value 2^>nul ^| find "="') do set "CPU_NAME=%%a"

echo. >> "%EXPORT_FILE%"
echo   Processor: !CPU_NAME! >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"
echo   [SEARCH] !CPU_NAME! chipset driver >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

echo   CPU: !CPU_NAME!

:: ============================================================================
:: GPU Information
:: ============================================================================
echo [3/8] Checking GPU...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  GRAPHICS CARD >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

set "gpu_count=0"
for /f "tokens=*" %%a in ('wmic path win32_videocontroller get Name /value 2^>nul ^| find "="') do (
    set /a gpu_count+=1
    set "GPU_NAME=%%a"
    set "GPU_NAME=!GPU_NAME:Name=!"
    set "GPU_NAME=!GPU_NAME:~1!"

    echo   GPU !gpu_count!: !GPU_NAME! >> "%EXPORT_FILE%"
    echo   GPU !gpu_count!: !GPU_NAME!
)

:: Get driver version
for /f "tokens=*" %%a in ('wmic path win32_videocontroller get DriverVersion /value 2^>nul ^| find "="') do (
    set "GPU_DRIVER=%%a"
    set "GPU_DRIVER=!GPU_DRIVER:DriverVersion=!"
    set "GPU_DRIVER=!GPU_DRIVER:~1!"
    echo   Driver Version: !GPU_DRIVER! >> "%EXPORT_FILE%"
)

:: Get driver date
for /f "tokens=*" %%a in ('wmic path win32_videocontroller get DriverDate /value 2^>nul ^| find "="') do (
    set "GPU_DATE=%%a"
    set "GPU_DATE=!GPU_DATE:DriverDate=!"
    set "GPU_DATE=!GPU_DATE:~1,8!"
    set "GPU_DATE_FMT=!GPU_DATE:~0,4!-!GPU_DATE:~4,2!-!GPU_DATE:~6,2!"
    echo   Driver Date: !GPU_DATE_FMT! >> "%EXPORT_FILE%"
)

echo. >> "%EXPORT_FILE%"

:: Determine GPU type for search string
echo !GPU_NAME! | findstr /i "NVIDIA GeForce RTX GTX" >nul && (
    echo   [SEARCH] NVIDIA driver download >> "%EXPORT_FILE%"
    echo   [SEARCH] !GPU_NAME! driver >> "%EXPORT_FILE%"
)
echo !GPU_NAME! | findstr /i "AMD Radeon RX" >nul && (
    echo   [SEARCH] AMD Radeon driver download >> "%EXPORT_FILE%"
    echo   [SEARCH] !GPU_NAME! driver >> "%EXPORT_FILE%"
)
echo !GPU_NAME! | findstr /i "Intel" >nul && (
    echo   [SEARCH] Intel graphics driver download >> "%EXPORT_FILE%"
)
echo. >> "%EXPORT_FILE%"

:: ============================================================================
:: Network Adapters
:: ============================================================================
echo [4/8] Checking Network Adapters...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  NETWORK ADAPTERS >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

:: Get physical network adapters (exclude virtual)
powershell -Command "Get-NetAdapter -Physical | ForEach-Object { $driver = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -eq $_.InterfaceDescription }; Write-Output ('  ' + $_.InterfaceDescription) }" >> "%EXPORT_FILE%" 2>nul

:: Get network adapter details with PowerShell
powershell -Command "$adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue; foreach ($a in $adapters) { $d = Get-WmiObject Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object { $_.DeviceName -like ('*' + $a.InterfaceDescription.Substring(0, [Math]::Min(20, $a.InterfaceDescription.Length)) + '*') } | Select-Object -First 1; if ($d) { Write-Output ('  ' + $a.InterfaceDescription); Write-Output ('    Driver: ' + $d.DriverVersion + ' [' + $d.DriverDate.Substring(0,10) + ']'); Write-Output ('    [SEARCH] ' + $a.InterfaceDescription + ' driver download'); Write-Output '' } }" >> "%EXPORT_FILE%" 2>nul

echo   [See output file for details]

:: ============================================================================
:: Audio Devices
:: ============================================================================
echo [5/8] Checking Audio Devices...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  AUDIO DEVICES >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

powershell -Command "$audio = Get-WmiObject Win32_SoundDevice -ErrorAction SilentlyContinue; foreach ($a in $audio) { if ($a.Name -and $a.Name -notmatch 'NVIDIA|AMD|Intel.*Display') { $d = Get-WmiObject Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object { $_.DeviceName -eq $a.Name } | Select-Object -First 1; Write-Output ('  ' + $a.Name); if ($d.DriverVersion) { Write-Output ('    Driver: ' + $d.DriverVersion) }; Write-Output ('    [SEARCH] ' + $a.Name + ' driver download'); Write-Output '' } }" >> "%EXPORT_FILE%" 2>nul

echo   [See output file for details]

:: ============================================================================
:: Storage Devices
:: ============================================================================
echo [6/8] Checking Storage Devices...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  STORAGE DEVICES >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

:: Get disk info
for /f "skip=1 tokens=*" %%a in ('wmic diskdrive get Model^,FirmwareRevision /format:csv 2^>nul ^| findstr /v "^$"') do (
    for /f "tokens=2,3 delims=," %%b in ("%%a") do (
        if not "%%c"=="" (
            echo   %%c >> "%EXPORT_FILE%"
            echo     Firmware: %%b >> "%EXPORT_FILE%"
            echo     [SEARCH] %%c firmware update >> "%EXPORT_FILE%"
            echo. >> "%EXPORT_FILE%"
            echo   Storage: %%c [FW: %%b]
        )
    )
)

:: ============================================================================
:: Chipset / System Devices
:: ============================================================================
echo [7/8] Checking Chipset...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  CHIPSET / SYSTEM >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

:: Detect chipset based on CPU
echo !CPU_NAME! | findstr /i "Intel" >nul && (
    echo   Platform: Intel >> "%EXPORT_FILE%"
    echo   [SEARCH] Intel chipset driver download >> "%EXPORT_FILE%"
    echo   [SEARCH] Intel Management Engine driver >> "%EXPORT_FILE%"
    echo. >> "%EXPORT_FILE%"
)
echo !CPU_NAME! | findstr /i "AMD Ryzen" >nul && (
    echo   Platform: AMD >> "%EXPORT_FILE%"
    echo   [SEARCH] AMD chipset driver download >> "%EXPORT_FILE%"
    echo   [SEARCH] !MB_MFR! !MB_MODEL! chipset driver >> "%EXPORT_FILE%"
    echo. >> "%EXPORT_FILE%"
)

:: ============================================================================
:: Windows Version
:: ============================================================================
echo [8/8] Checking Windows Version...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  WINDOWS VERSION >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

for /f "tokens=2 delims==" %%a in ('wmic os get Caption /value 2^>nul ^| find "="') do set "WIN_NAME=%%a"
for /f "tokens=2 delims==" %%a in ('wmic os get Version /value 2^>nul ^| find "="') do set "WIN_VER=%%a"
for /f "tokens=2 delims==" %%a in ('wmic os get BuildNumber /value 2^>nul ^| find "="') do set "WIN_BUILD=%%a"

echo   !WIN_NAME! >> "%EXPORT_FILE%"
echo   Version: !WIN_VER! [Build !WIN_BUILD!] >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

echo   Windows: !WIN_NAME! [Build !WIN_BUILD!]

:: ============================================================================
:: Quick Search Links Summary
:: ============================================================================

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  QUICK SEARCH STRINGS [Copy and paste into browser] >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"
echo   BIOS:     !MB_MFR! !MB_MODEL! BIOS update download >> "%EXPORT_FILE%"
echo   Chipset:  !MB_MFR! !MB_MODEL! chipset driver >> "%EXPORT_FILE%"

:: Add GPU search based on detected GPU
for /f "tokens=*" %%a in ('wmic path win32_videocontroller get Name /value 2^>nul ^| find "="') do (
    set "GPU=%%a"
    set "GPU=!GPU:Name=!"
    set "GPU=!GPU:~1!"
    echo !GPU! | findstr /i "NVIDIA" >nul && echo   GPU:      NVIDIA GeForce driver download >> "%EXPORT_FILE%"
    echo !GPU! | findstr /i "AMD Radeon" >nul && echo   GPU:      AMD Radeon Adrenalin driver download >> "%EXPORT_FILE%"
    echo !GPU! | findstr /i "Intel" >nul && echo   GPU:      Intel graphics driver download >> "%EXPORT_FILE%"
)

echo   Audio:    Realtek audio driver download >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  DIRECT DOWNLOAD LINKS >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"
echo   NVIDIA:   https://www.nvidia.com/Download/index.aspx >> "%EXPORT_FILE%"
echo   AMD:      https://www.amd.com/en/support >> "%EXPORT_FILE%"
echo   Intel:    https://www.intel.com/content/www/us/en/download-center/home.html >> "%EXPORT_FILE%"
echo   Realtek:  https://www.realtek.com/en/downloads >> "%EXPORT_FILE%"
echo. >> "%EXPORT_FILE%"

:: Motherboard specific
echo !MB_MFR! | findstr /i "ASUS" >nul && echo   ASUS:     https://www.asus.com/support/ >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "MSI" >nul && echo   MSI:      https://www.msi.com/support >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "Gigabyte" >nul && echo   Gigabyte: https://www.gigabyte.com/Support >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "ASRock" >nul && echo   ASRock:   https://www.asrock.com/support/index.asp >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "Dell" >nul && echo   Dell:     https://www.dell.com/support/home >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "HP" >nul && echo   HP:       https://support.hp.com/drivers >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "Lenovo" >nul && echo   Lenovo:   https://support.lenovo.com/solutions/ht003029 >> "%EXPORT_FILE%"

echo. >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"

:: ============================================================================
:: Display Summary
:: ============================================================================

echo.
echo ============================================================================
echo  Scan Complete!
echo ============================================================================
echo.
echo Report saved to:
echo   %EXPORT_FILE%
echo.
echo ============================================================================
echo  QUICK SEARCH STRINGS [Copy into your browser]
echo ============================================================================
echo.
echo   BIOS:    !MB_MFR! !MB_MODEL! BIOS update download
echo   Chipset: !MB_MFR! !MB_MODEL! chipset driver

:: Display GPU search
for /f "tokens=*" %%a in ('wmic path win32_videocontroller get Name /value 2^>nul ^| find "=" ^| findstr /v "Microsoft"') do (
    set "GPU=%%a"
    set "GPU=!GPU:Name=!"
    set "GPU=!GPU:~1!"
    if not "!GPU!"=="" (
        echo !GPU! | findstr /i "NVIDIA" >nul && echo   GPU:     NVIDIA GeForce driver download
        echo !GPU! | findstr /i "AMD Radeon" >nul && echo   GPU:     AMD Radeon Adrenalin driver download
        echo !GPU! | findstr /i "Intel" >nul && echo   GPU:     Intel graphics driver download
    )
)

echo.
echo ============================================================================
echo  DIRECT LINKS
echo ============================================================================
echo.
echo   NVIDIA:   https://www.nvidia.com/Download/index.aspx
echo   AMD:      https://www.amd.com/en/support
echo   Intel:    https://www.intel.com/content/www/us/en/download-center/home.html
echo.

:: Ask if user wants to open the file
set /p "openfile=Would you like to open the full report? [Y/N]: "
if /i "%openfile%"=="Y" (
    notepad "%EXPORT_FILE%"
)

echo.
pause
exit /b 0
