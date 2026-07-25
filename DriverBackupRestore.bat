@echo off
setlocal enabledelayedexpansion
title Driver Backup and Restore
color 0B

:: ============================================================================
:: Driver Backup and Restore
:: ============================================================================
:: Exports all third-party (non-inbox) drivers to a folder using DISM and
:: pnputil. Invaluable before a clean install — lets you restore drivers
:: without hunting for downloads. Also supports restoring from a backup.
:: ============================================================================

:: Set up color codes
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

echo %CYAN%============================================================================%RESET%
echo %CYAN% Driver Backup and Restore%RESET%
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

echo %GREEN%[INFO] Administrator privileges confirmed.%RESET%
echo/

:MainMenu
echo %CYAN%============================================================================%RESET%
echo %CYAN% Main Menu%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   [1] Backup all third-party drivers
echo   [2] List installed third-party drivers
echo   [3] Restore drivers from backup
echo   [4] Backup and create restore script
echo   [0] Exit
echo/

set "choice="
set /p "choice=Select option: "

if "%choice%"=="1" goto BackupDrivers
if "%choice%"=="2" goto ListDrivers
if "%choice%"=="3" goto RestoreDrivers
if "%choice%"=="4" goto BackupWithScript
if "%choice%"=="0" goto Exit

echo %RED%Invalid option.%RESET%
echo/
goto MainMenu

:: ============================================================================
:: Option 1: Backup Drivers
:: ============================================================================
:BackupDrivers
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Backup Third-Party Drivers%RESET%
echo %CYAN%============================================================================%RESET%
echo/

:: Set default backup location
set "DEFAULT_BACKUP=%USERPROFILE%\Desktop\DriverBackup_%COMPUTERNAME%"

echo Default backup location:
echo   %DEFAULT_BACKUP%
echo/
set /p "BACKUP_PATH=Press Enter to use default, or type a custom path: "

if "!BACKUP_PATH!"=="" set "BACKUP_PATH=%DEFAULT_BACKUP%"

:: Add date to folder name
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "dt=%%I"
set "BACKUP_PATH=!BACKUP_PATH!_%dt:~0,8%"

echo/
echo Backup will be saved to:
echo   %YELLOW%!BACKUP_PATH!%RESET%
echo/

set /p "confirm=Continue? [Y/N]: "
if /i not "%confirm%"=="Y" goto MainMenu

:: Create backup directory
mkdir "!BACKUP_PATH!" 2>nul

echo/
echo [1/4] Enumerating installed third-party drivers...
echo/

:: Count third-party drivers first
set "driverCount=0"
for /f "tokens=1,2 delims=:" %%a in ('pnputil /enum-drivers 2^>nul ^| findstr /i /c:"Published Name"') do (
    echo %%a | findstr /i /c:"Published Name" >nul 2>&1
    if not errorlevel 1 (
        set /a driverCount+=1
    )
)
echo       Found approximately !driverCount! driver packages in the store.
echo/

echo [2/4] Exporting drivers using DISM...
echo       This may take a few minutes depending on the number of drivers.
echo/

dism /online /export-driver /destination:"!BACKUP_PATH!" >nul 2>&1
if %errorlevel% equ 0 (
    echo       %GREEN%[OK] DISM driver export complete%RESET%
) else (
    echo       %YELLOW%[WARN] DISM export had issues, falling back to pnputil...%RESET%
    echo/

    :: Fallback: use pnputil to export each driver
    for /f "tokens=2 delims=:" %%d in ('pnputil /enum-drivers 2^>nul ^| findstr /i /c:"Published Name"') do (
        set "drvName=%%d"
        set "drvName=!drvName: =!"
        pnputil /export-driver "!drvName!" "!BACKUP_PATH!" >nul 2>&1
    )
    echo       %GREEN%[OK] pnputil driver export complete%RESET%
)

echo/
echo [3/4] Generating driver inventory...

:: Create detailed driver list
set "INVENTORY=!BACKUP_PATH!\DriverInventory.txt"

(
echo ============================================================================
echo  Driver Backup Inventory
echo  Computer: %COMPUTERNAME%
echo  Date: %dt:~0,4%-%dt:~4,2%-%dt:~6,2%
echo  OS:
) > "!INVENTORY!"

:: Get OS version
for /f "tokens=2 delims==" %%v in ('wmic os get Caption /value 2^>nul ^| find "="') do (
    echo  %%v>> "!INVENTORY!"
)

(echo ============================================================================) >> "!INVENTORY!"
(echo/) >> "!INVENTORY!"

:: List all third-party drivers with details
set "PSINVENTORY=%TEMP%\driver_inventory.ps1"

(
echo $drivers = Get-WindowsDriver -Online -ErrorAction SilentlyContinue ^| Where-Object { $_.Driver -ne $null }
echo $thirdParty = $drivers ^| Where-Object { $_.ProviderName -ne 'Microsoft' }
echo/
echo Write-Output "THIRD-PARTY DRIVERS ^($^($thirdParty.Count^) total^)"
echo Write-Output "============================================================================"
echo Write-Output ""
echo Write-Output ^("{0,-40} {1,-30} {2,-15} {3}" -f "Driver Name", "Provider", "Version", "Class"^)
echo Write-Output ^("{0,-40} {1,-30} {2,-15} {3}" -f ^("-" * 39^), ^("-" * 29^), ^("-" * 14^), ^("-" * 20^)^)
echo/
echo foreach ^($drv in $thirdParty ^| Sort-Object ClassName, ProviderName^) {
echo     $name = if ^($drv.OriginalFileName^) { [System.IO.Path]::GetFileNameWithoutExtension^($drv.OriginalFileName^) } else { $drv.Driver }
echo     if ^($name.Length -gt 39^) { $name = $name.Substring^(0, 36^) + '...' }
echo     $provider = if ^($drv.ProviderName.Length -gt 29^) { $drv.ProviderName.Substring^(0, 26^) + '...' } else { $drv.ProviderName }
echo     $version = $drv.Version
echo     if ^($version -and $version.Length -gt 14^) { $version = $version.Substring^(0, 14^) }
echo     $class = $drv.ClassName
echo     Write-Output ^("{0,-40} {1,-30} {2,-15} {3}" -f $name, $provider, $version, $class^)
echo }
echo/
echo Write-Output ""
echo Write-Output "============================================================================"
echo Write-Output "DRIVER CLASSES SUMMARY"
echo Write-Output "============================================================================"
echo Write-Output ""
echo $thirdParty ^| Group-Object ClassName ^| Sort-Object Count -Descending ^| ForEach-Object {
echo     Write-Output ^("  {0,-35} {1} drivers" -f $_.Name, $_.Count^)
echo }
echo/
echo Write-Output ""
echo Write-Output "MICROSOFT ^(INBOX^) DRIVERS: $^($drivers.Count - $thirdParty.Count^)"
echo Write-Output "THIRD-PARTY DRIVERS:       $^($thirdParty.Count^)"
echo Write-Output "TOTAL DRIVERS:             $^($drivers.Count^)"
) > "!PSINVENTORY!"

powershell -ExecutionPolicy Bypass -File "!PSINVENTORY!" >> "!INVENTORY!" 2>nul
powershell -ExecutionPolicy Bypass -File "!PSINVENTORY!" 2>nul
del "!PSINVENTORY!" 2>nul

echo/
echo [4/4] Calculating backup size...

:: Count files and estimate size
set "fileCount=0"
set "totalSize=0"
for /f %%f in ('dir /s /b "!BACKUP_PATH!\*.inf" 2^>nul ^| find /c /v ""') do set "fileCount=%%f"
for /f "tokens=3" %%s in ('dir /s "!BACKUP_PATH!" 2^>nul ^| findstr "File(s)"') do set "totalSize=%%s"

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Backup Complete%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   %GREEN%Driver packages exported: !fileCount!%RESET%
echo   Backup location: !BACKUP_PATH!
echo   Inventory file:  !INVENTORY!
echo/
echo %YELLOW%TIPS:%RESET%
echo  - Copy this folder to a USB drive before your clean install
echo  - Use option [3] to restore drivers after reinstalling Windows
echo  - Use option [4] to create a self-contained restore script
echo/

pause
goto MainMenu

:: ============================================================================
:: Option 2: List Drivers
:: ============================================================================
:ListDrivers
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Installed Third-Party Drivers%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo Loading driver information...
echo/

set "PSLIST=%TEMP%\driver_list.ps1"

(
echo $drivers = Get-WindowsDriver -Online -ErrorAction SilentlyContinue
echo $thirdParty = $drivers ^| Where-Object { $_.ProviderName -ne 'Microsoft' } ^| Sort-Object ClassName, ProviderName
echo/
echo Write-Host ""
echo Write-Host ^("{0,-15} {1,-35} {2,-25} {3}" -f "Class", "Published Name", "Provider", "Version"^)
echo Write-Host ^("{0,-15} {1,-35} {2,-25} {3}" -f ^("-" * 14^), ^("-" * 34^), ^("-" * 24^), ^("-" * 15^)^)
echo/
echo foreach ^($drv in $thirdParty^) {
echo     $class = if ^($drv.ClassName.Length -gt 14^) { $drv.ClassName.Substring^(0,11^) + '...' } else { $drv.ClassName }
echo     $name = $drv.Driver
echo     if ^($name.Length -gt 34^) { $name = $name.Substring^(0,31^) + '...' }
echo     $provider = if ^($drv.ProviderName.Length -gt 24^) { $drv.ProviderName.Substring^(0,21^) + '...' } else { $drv.ProviderName }
echo     $version = $drv.Version
echo     if ^($version -and $version.Length -gt 15^) { $version = $version.Substring^(0,15^) }
echo     Write-Host ^("{0,-15} {1,-35} {2,-25} {3}" -f $class, $name, $provider, $version^)
echo }
echo/
echo Write-Host ""
echo Write-Host "Total third-party drivers: $^($thirdParty.Count^)" -ForegroundColor Green
echo Write-Host "Total inbox ^(Microsoft^) drivers: $^($drivers.Count - $thirdParty.Count^)"
echo Write-Host ""
) > "!PSLIST!"

powershell -ExecutionPolicy Bypass -File "!PSLIST!" 2>nul
del "!PSLIST!" 2>nul

pause
goto MainMenu

:: ============================================================================
:: Option 3: Restore Drivers
:: ============================================================================
:RestoreDrivers
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Restore Drivers from Backup%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo Enter the path to your driver backup folder:
echo   Example: D:\DriverBackup_MYPC_20260101
echo/
set /p "RESTORE_PATH=Backup path: "

if not exist "!RESTORE_PATH!" (
    echo/
    echo %RED%[ERROR] Path not found: !RESTORE_PATH!%RESET%
    echo/
    pause
    goto MainMenu
)

:: Count INF files
set "infCount=0"
for /f %%c in ('dir /s /b "!RESTORE_PATH!\*.inf" 2^>nul ^| find /c /v ""') do set "infCount=%%c"

if !infCount! equ 0 (
    echo/
    echo %RED%[ERROR] No driver packages (.inf) found in !RESTORE_PATH!%RESET%
    echo/
    pause
    goto MainMenu
)

echo/
echo Found %GREEN%!infCount!%RESET% driver packages in the backup.
echo/
echo %YELLOW%Options:%RESET%
echo   [1] Install ALL drivers from backup
echo   [2] Install drivers one at a time (review each)
echo   [0] Cancel
echo/

set /p "restoreChoice=Select option: "

if "%restoreChoice%"=="0" goto MainMenu
if "%restoreChoice%"=="2" goto RestoreSelective

:: Bulk install all drivers
echo/
echo Installing all drivers from backup...
echo/

set "installed=0"
set "failed=0"

for /r "!RESTORE_PATH!" %%f in (*.inf) do (
    echo   Installing: %%~nxf
    pnputil /add-driver "%%f" /install >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%[OK]%RESET%
        set /a installed+=1
    ) else (
        echo       %YELLOW%[SKIP] Already installed or not needed%RESET%
        set /a failed+=1
    )
)

echo/
echo %CYAN%============================================================================%RESET%
echo   Installed: !installed!
echo   Skipped:   !failed!
echo %CYAN%============================================================================%RESET%
echo/
echo %YELLOW%A reboot is recommended to load newly installed drivers.%RESET%
echo/

set /p "reboot=Restart now? [Y/N]: "
if /i "%reboot%"=="Y" (
    shutdown /r /t 10 /c "Driver Restore - Restart"
)

pause
goto MainMenu

:: Selective restore
:RestoreSelective
echo/
echo Reviewing drivers one at a time...
echo/

set "installed=0"
set "skippedDrv=0"

for /r "!RESTORE_PATH!" %%f in (*.inf) do (
    echo   %WHITE%%%~nxf%RESET%

    REM Try to show driver provider/description from the INF
    for /f "tokens=1,* delims==" %%a in ('findstr /i /r "^Provider ^DriverVer ^CatalogFile" "%%f" 2^>nul') do (
        set "infoKey=%%a"
        set "infoVal=%%b"
        echo     !infoKey!= !infoVal!
    )

    set /p "installThis=  Install this driver? [Y/N]: "
    if /i "!installThis!"=="Y" (
        pnputil /add-driver "%%f" /install >nul 2>&1
        if not errorlevel 1 (
            echo       %GREEN%[OK] Installed%RESET%
            set /a installed+=1
        ) else (
            echo       %YELLOW%[SKIP] Already installed or not needed%RESET%
        )
    ) else (
        set /a skippedDrv+=1
    )
    echo/
)

echo/
echo   Installed: !installed!  Skipped: !skippedDrv!
echo/

pause
goto MainMenu

:: ============================================================================
:: Option 4: Backup with Restore Script
:: ============================================================================
:BackupWithScript
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Backup with Self-Contained Restore Script%RESET%
echo %CYAN%============================================================================%RESET%
echo/

:: Set backup location
set "DEFAULT_BACKUP=%USERPROFILE%\Desktop\DriverBackup_%COMPUTERNAME%"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set "dt=%%I"
set "BACKUP_PATH=!DEFAULT_BACKUP!_%dt:~0,8%"

echo Backup will be saved to: !BACKUP_PATH!
echo/

set /p "confirm=Continue? [Y/N]: "
if /i not "%confirm%"=="Y" goto MainMenu

mkdir "!BACKUP_PATH!" 2>nul

echo/
echo [1/3] Exporting drivers...

dism /online /export-driver /destination:"!BACKUP_PATH!" >nul 2>&1
if %errorlevel% equ 0 (
    echo       %GREEN%[OK] Drivers exported%RESET%
) else (
    echo       %YELLOW%[WARN] DISM export had issues%RESET%
)

echo/
echo [2/3] Creating restore script...

:: Create a portable restore script inside the backup folder
set "RESTORE_SCRIPT=!BACKUP_PATH!\RestoreAllDrivers.bat"

(
echo @echo off
echo setlocal enabledelayedexpansion
echo title Driver Restore
echo echo ============================================================================
echo echo  Driver Restore Script
echo echo  Created from: %COMPUTERNAME% on %dt:~0,4%-%dt:~4,2%-%dt:~6,2%
echo echo ============================================================================
echo echo/
echo/
echo :: Check for admin
echo net session ^>nul 2^>^&1
echo if %%errorlevel%% neq 0 ^(
echo     echo [ERROR] Run as administrator^^!
echo     pause
echo     exit /b 1
echo ^)
echo/
echo echo This script will install all backed-up drivers.
echo echo/
echo set /p "confirm=Continue? [Y/N]: "
echo if /i not "%%confirm%%"=="Y" exit /b 0
echo/
echo echo/
echo echo Installing drivers...
echo echo/
echo/
echo set "installed=0"
echo set "failed=0"
echo/
echo for /r "%%~dp0" %%%%f in ^(*.inf^) do ^(
echo     echo   Installing: %%%%~nxf
echo     pnputil /add-driver "%%%%f" /install ^>nul 2^>^&1
echo     if not errorlevel 1 ^(
echo         echo       [OK]
echo         set /a installed+=1
echo     ^) else ^(
echo         echo       [SKIP]
echo         set /a failed+=1
echo     ^)
echo ^)
echo/
echo echo/
echo echo   Installed: %%installed%%
echo echo   Skipped:   %%failed%%
echo echo/
echo echo Reboot recommended.
echo pause
) > "!RESTORE_SCRIPT!"

echo       %GREEN%[OK] RestoreAllDrivers.bat created in backup folder%RESET%

echo/
echo [3/3] Generating inventory...

:: Reuse the inventory generation
set "INVENTORY=!BACKUP_PATH!\DriverInventory.txt"

(
echo ============================================================================
echo  Driver Backup Inventory
echo  Computer: %COMPUTERNAME%
echo  Date: %dt:~0,4%-%dt:~4,2%-%dt:~6,2%
echo ============================================================================
echo/
) > "!INVENTORY!"

pnputil /enum-drivers 2>nul | findstr /i "Published Original Class Provider Driver" >> "!INVENTORY!"

echo       %GREEN%[OK] Inventory generated%RESET%

echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Backup Complete%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   Backup location:  !BACKUP_PATH!
echo   Restore script:   !RESTORE_SCRIPT!
echo   Driver inventory:  !INVENTORY!
echo/
echo %YELLOW%To restore on a new install:%RESET%
echo  1. Copy the entire !BACKUP_PATH! folder to USB
echo  2. On the new install, right-click RestoreAllDrivers.bat
echo  3. Select "Run as administrator"
echo  4. Reboot when done
echo/

pause
goto MainMenu

:Exit
echo/
echo Goodbye.
exit /b 0
