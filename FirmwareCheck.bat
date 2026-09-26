@echo off
setlocal enabledelayedexpansion
title Firmware ^& Driver Version Checker
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
echo/
echo Gathering system information... This may take a moment.
echo/

:: Set output file. Resolve the real Desktop folder: it can be redirected (e.g.
:: OneDrive folder backup moves it to %USERPROFILE%\OneDrive\Desktop), so
:: %USERPROFILE%\Desktop is not always the Desktop the user sees. If that path
:: is missing or cannot be used, fall back to %USERPROFILE%\Desktop, then to
:: the profile folder.
set "DESKTOP_DIR="
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP_DIR=%%D"
if not defined DESKTOP_DIR set "DESKTOP_DIR=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_DIR%\" set "DESKTOP_DIR=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_DIR%\" set "DESKTOP_DIR=%USERPROFILE%"
set "EXPORT_FILE=%DESKTOP_DIR%\FirmwareInfo_%COMPUTERNAME%.txt"

:: Start output file
echo ============================================================================ > "%EXPORT_FILE%"
echo  FIRMWARE ^& DRIVER VERSION REPORT >> "%EXPORT_FILE%"
echo  Computer: %COMPUTERNAME% >> "%EXPORT_FILE%"
echo  Date: %DATE% %TIME% >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

:: ============================================================================
:: BIOS / UEFI Information
:: ============================================================================
echo [1/8] Checking BIOS/UEFI...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  BIOS / UEFI >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"

:: Read BIOS, motherboard, CPU and Windows details with ONE PowerShell (CIM)
:: call that prints KEY=VALUE lines. This replaces WMIC, which is not
:: available on Windows 11 24H2 and later. The CPU and Windows values are
:: used in steps 2 and 8. The BIOS date is formatted as yyyy-MM-dd here.
:: Clear the values first so none is inherited from the environment when
:: PowerShell does not report it.
set "BIOS_MFR=" & set "BIOS_VER=" & set "BIOS_DATE_FMT="
set "MB_MFR=" & set "MB_MODEL=" & set "CPU_NAME="
set "WIN_NAME=" & set "WIN_VER=" & set "WIN_BUILD="
for /f "tokens=1,* delims==" %%a in ('powershell -NoProfile -Command "$b = @(Get-CimInstance Win32_BIOS)[0]; $m = @(Get-CimInstance Win32_BaseBoard)[0]; $c = @(Get-CimInstance Win32_Processor)[0]; $o = @(Get-CimInstance Win32_OperatingSystem)[0]; $inv = [Globalization.CultureInfo]::InvariantCulture; 'BIOS_MFR=' + ([string]$b.Manufacturer).Trim(); 'BIOS_VER=' + ([string]$b.SMBIOSBIOSVersion).Trim(); if ($b.ReleaseDate) { 'BIOS_DATE_FMT=' + $b.ReleaseDate.ToUniversalTime().ToString('yyyy-MM-dd', $inv) }; 'MB_MFR=' + ([string]$m.Manufacturer).Trim(); 'MB_MODEL=' + ([string]$m.Product).Trim(); 'CPU_NAME=' + ([string]$c.Name).Trim(); 'WIN_NAME=' + ([string]$o.Caption).Trim(); 'WIN_VER=' + ([string]$o.Version).Trim(); 'WIN_BUILD=' + ([string]$o.BuildNumber).Trim()" 2^>nul') do set "%%a=%%b"

echo/ >> "%EXPORT_FILE%"
echo   Motherboard: !MB_MFR! !MB_MODEL! >> "%EXPORT_FILE%"
echo   BIOS Version: !BIOS_VER! >> "%EXPORT_FILE%"
echo   BIOS Date: !BIOS_DATE_FMT! >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"
echo   [SEARCH] !MB_MFR! !MB_MODEL! BIOS update >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

echo   Motherboard: !MB_MFR! !MB_MODEL!
echo   BIOS: !BIOS_VER! [!BIOS_DATE_FMT!]

:: ============================================================================
:: CPU Information
:: ============================================================================
echo [2/8] Checking CPU...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  CPU >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"

:: CPU_NAME was read in step 1

echo/ >> "%EXPORT_FILE%"
echo   Processor: !CPU_NAME! >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"
echo   [SEARCH] !CPU_NAME! chipset driver >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

echo   CPU: !CPU_NAME!

:: ============================================================================
:: GPU Information
:: ============================================================================
echo [3/8] Checking GPU...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  GRAPHICS CARD >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

:: One PowerShell (CIM) call prints "name|driver version|driver date" for each
:: GPU (replaces WMIC). Each GPU's driver details follow its name.
set "gpu_count=0"
for /f "tokens=1-3 delims=|" %%a in ('powershell -NoProfile -Command "$inv = [Globalization.CultureInfo]::InvariantCulture; Get-CimInstance Win32_VideoController | Where-Object { $_.Name } | ForEach-Object { $ver = ([string]$_.DriverVersion).Trim(); if (-not $ver) { $ver = 'unknown' }; $date = 'unknown'; if ($_.DriverDate) { $date = $_.DriverDate.ToUniversalTime().ToString('yyyy-MM-dd', $inv) }; ([string]$_.Name).Trim() + '|' + $ver + '|' + $date }" 2^>nul') do (
    set /a gpu_count+=1
    set "GPU_NAME=%%a"

    echo   GPU !gpu_count!: !GPU_NAME! >> "%EXPORT_FILE%"
    echo   GPU !gpu_count!: !GPU_NAME!
    echo   Driver Version: %%b >> "%EXPORT_FILE%"
    echo   Driver Date: %%c >> "%EXPORT_FILE%"
)

echo/ >> "%EXPORT_FILE%"

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
echo/ >> "%EXPORT_FILE%"

:: ============================================================================
:: Network Adapters
:: ============================================================================
echo [4/8] Checking Network Adapters...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  NETWORK ADAPTERS >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

:: Get physical network adapters (exclude virtual)
powershell -Command "Get-NetAdapter -Physical | ForEach-Object { Write-Output ('  ' + $_.InterfaceDescription) }" >> "%EXPORT_FILE%" 2>nul

:: Get network adapter details with PowerShell
powershell -Command "$adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue; foreach ($a in $adapters) { $d = Get-WmiObject Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object { $_.DeviceName -like ('*' + $a.InterfaceDescription.Substring(0, [Math]::Min(20, $a.InterfaceDescription.Length)) + '*') } | Select-Object -First 1; if ($d) { Write-Output ('  ' + $a.InterfaceDescription); Write-Output ('    Driver: ' + $d.DriverVersion + ' [' + $(if ($d.DriverDate) { $d.DriverDate.Substring(0,4) + '-' + $d.DriverDate.Substring(4,2) + '-' + $d.DriverDate.Substring(6,2) } else { 'unknown' }) + ']'); Write-Output ('    [SEARCH] ' + $a.InterfaceDescription + ' driver download'); Write-Output '' } }" >> "%EXPORT_FILE%" 2>nul

echo   [See output file for details]

:: ============================================================================
:: Audio Devices
:: ============================================================================
echo [5/8] Checking Audio Devices...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  AUDIO DEVICES >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

powershell -Command "$audio = Get-WmiObject Win32_SoundDevice -ErrorAction SilentlyContinue; foreach ($a in $audio) { if ($a.Name -and $a.Name -notmatch 'NVIDIA|AMD|Intel.*Display') { $d = Get-WmiObject Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object { $_.DeviceName -eq $a.Name } | Select-Object -First 1; Write-Output ('  ' + $a.Name); if ($d.DriverVersion) { Write-Output ('    Driver: ' + $d.DriverVersion) }; Write-Output ('    [SEARCH] ' + $a.Name + ' driver download'); Write-Output '' } }" >> "%EXPORT_FILE%" 2>nul

echo   [See output file for details]

:: ============================================================================
:: Storage Devices
:: ============================================================================
echo [6/8] Checking Storage Devices...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  STORAGE DEVICES >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

:: Get disk info: PowerShell (CIM) prints "firmware|model" for each disk that
:: reports a model (replaces WMIC). Missing firmware is shown as "unknown".
for /f "tokens=1,2 delims=|" %%b in ('powershell -NoProfile -Command "Get-CimInstance Win32_DiskDrive | Where-Object { $_.Model } | ForEach-Object { $fw = ([string]$_.FirmwareRevision).Trim(); if (-not $fw) { $fw = 'unknown' }; $fw + '|' + ([string]$_.Model).Trim() }" 2^>nul') do (
    echo   %%c >> "%EXPORT_FILE%"
    echo     Firmware: %%b >> "%EXPORT_FILE%"
    echo     [SEARCH] %%c firmware update >> "%EXPORT_FILE%"
    echo/ >> "%EXPORT_FILE%"
    echo   Storage: %%c [FW: %%b]
)

:: ============================================================================
:: Chipset / System Devices
:: ============================================================================
echo [7/8] Checking Chipset...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  CHIPSET / SYSTEM >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

:: Detect chipset based on CPU
echo !CPU_NAME! | findstr /i "Intel" >nul && (
    echo   Platform: Intel >> "%EXPORT_FILE%"
    echo   [SEARCH] Intel chipset driver download >> "%EXPORT_FILE%"
    echo   [SEARCH] Intel Management Engine driver >> "%EXPORT_FILE%"
    echo/ >> "%EXPORT_FILE%"
)
echo !CPU_NAME! | findstr /i "AMD Ryzen" >nul && (
    echo   Platform: AMD >> "%EXPORT_FILE%"
    echo   [SEARCH] AMD chipset driver download >> "%EXPORT_FILE%"
    echo   [SEARCH] !MB_MFR! !MB_MODEL! chipset driver >> "%EXPORT_FILE%"
    echo/ >> "%EXPORT_FILE%"
)

:: ============================================================================
:: Windows Version
:: ============================================================================
echo [8/8] Checking Windows Version...

echo ============================================================================ >> "%EXPORT_FILE%"
echo  WINDOWS VERSION >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

:: WIN_NAME, WIN_VER and WIN_BUILD were read in step 1

echo/  !WIN_NAME! >> "%EXPORT_FILE%"
echo   Version: !WIN_VER! [Build !WIN_BUILD!] >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

echo   Windows: !WIN_NAME! [Build !WIN_BUILD!]

:: ============================================================================
:: Quick Search Links Summary
:: ============================================================================

echo/ >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  QUICK SEARCH STRINGS [Copy and paste into browser] >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"
echo   BIOS:     !MB_MFR! !MB_MODEL! BIOS update download >> "%EXPORT_FILE%"
echo   Chipset:  !MB_MFR! !MB_MODEL! chipset driver >> "%EXPORT_FILE%"

:: Add GPU search based on detected GPU (names read with PowerShell/CIM)
for /f "delims=" %%a in ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController).Name" 2^>nul') do (
    set "GPU=%%a"
    echo !GPU! | findstr /i "NVIDIA" >nul && echo   GPU:      NVIDIA GeForce driver download >> "%EXPORT_FILE%"
    echo !GPU! | findstr /i "AMD Radeon" >nul && echo   GPU:      AMD Radeon Adrenalin driver download >> "%EXPORT_FILE%"
    echo !GPU! | findstr /i "Intel" >nul && echo   GPU:      Intel graphics driver download >> "%EXPORT_FILE%"
)

echo   Audio:    Realtek audio driver download >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo  DIRECT DOWNLOAD LINKS >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"
echo   NVIDIA:   https://www.nvidia.com/Download/index.aspx >> "%EXPORT_FILE%"
echo   AMD:      https://www.amd.com/en/support >> "%EXPORT_FILE%"
echo   Intel:    https://www.intel.com/content/www/us/en/download-center/home.html >> "%EXPORT_FILE%"
echo   Realtek:  https://www.realtek.com/en/downloads >> "%EXPORT_FILE%"
echo/ >> "%EXPORT_FILE%"

:: Motherboard specific
echo !MB_MFR! | findstr /i "ASUS" >nul && echo   ASUS:     https://www.asus.com/support/ >> "%EXPORT_FILE%"
:: MSI boards report "Micro-Star International", older HP systems "Hewlett-Packard"
echo !MB_MFR! | findstr /i /c:"MSI" /c:"Micro-Star" >nul && echo   MSI:      https://www.msi.com/support >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "Gigabyte" >nul && echo   Gigabyte: https://www.gigabyte.com/Support >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "ASRock" >nul && echo   ASRock:   https://www.asrock.com/support/index.asp >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "Dell" >nul && echo   Dell:     https://www.dell.com/support/home >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i /c:"HP" /c:"Hewlett" >nul && echo   HP:       https://support.hp.com/drivers >> "%EXPORT_FILE%"
echo !MB_MFR! | findstr /i "Lenovo" >nul && echo   Lenovo:   https://support.lenovo.com/solutions/ht003029 >> "%EXPORT_FILE%"

echo/ >> "%EXPORT_FILE%"
echo ============================================================================ >> "%EXPORT_FILE%"

:: ============================================================================
:: Display Summary
:: ============================================================================

echo/
echo ============================================================================
echo  Scan Complete^^!
echo ============================================================================
echo/
echo Report saved to:
echo   !EXPORT_FILE!
echo/
echo ============================================================================
echo  QUICK SEARCH STRINGS [Copy into your browser]
echo ============================================================================
echo/
echo   BIOS:    !MB_MFR! !MB_MODEL! BIOS update download
echo   Chipset: !MB_MFR! !MB_MODEL! chipset driver

:: Display GPU search
for /f "delims=" %%a in ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController).Name" 2^>nul ^| findstr /v "Microsoft"') do (
    set "GPU=%%a"
    if not "!GPU!"=="" (
        echo !GPU! | findstr /i "NVIDIA" >nul && echo   GPU:     NVIDIA GeForce driver download
        echo !GPU! | findstr /i "AMD Radeon" >nul && echo   GPU:     AMD Radeon Adrenalin driver download
        echo !GPU! | findstr /i "Intel" >nul && echo   GPU:     Intel graphics driver download
    )
)

echo/
echo ============================================================================
echo  DIRECT LINKS
echo ============================================================================
echo/
echo   NVIDIA:   https://www.nvidia.com/Download/index.aspx
echo   AMD:      https://www.amd.com/en/support
echo   Intel:    https://www.intel.com/content/www/us/en/download-center/home.html
echo/

:: Ask if user wants to open the file
set "openfile="
set /p "openfile=Would you like to open the full report? [Y/N]: "
if /i "%openfile%"=="Y" (
    notepad "%EXPORT_FILE%"
)

echo/
pause
exit /b 0
