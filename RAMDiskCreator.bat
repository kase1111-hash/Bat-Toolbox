@echo off
setlocal enabledelayedexpansion
title RAM Disk Creator
color 0B

:: ============================================================================
:: RAM Disk Creator
:: ============================================================================
:: Creates a RAM disk using ImDisk or the built-in Windows approach for temp
:: files, browser caches, or shader caches. Redirects %TEMP% to it for a
:: solid performance boost on machines with 32GB+ RAM.
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
echo %CYAN% RAM Disk Creator%RESET%
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

:: Detect total RAM
set "totalRAM=0"
for /f "tokens=2 delims==" %%m in ('wmic computersystem get TotalPhysicalMemory /value 2^>nul ^| find "="') do (
    set "totalBytes=%%m"
)

:: Convert to GB using PowerShell (batch can't handle large numbers)
for /f %%g in ('powershell -Command "[math]::Round(%totalBytes% / 1GB, 1)"') do set "totalGB=%%g"
for /f %%g in ('powershell -Command "[math]::Floor(%totalBytes% / 1GB)"') do set "totalGBint=%%g"

:: Get available RAM
for /f %%g in ('powershell -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 1)"') do set "freeGB=%%g"

echo %WHITE%System RAM:%RESET%  !totalGB! GB total, !freeGB! GB available
echo/

:: Check if ImDisk is installed
set "hasImDisk=0"
where imdisk >nul 2>&1
if %errorlevel% equ 0 set "hasImDisk=1"
if exist "%ProgramFiles%\ImDisk\imdisk.exe" set "hasImDisk=1"
if exist "%SystemRoot%\System32\imdisk.exe" set "hasImDisk=1"

if "!hasImDisk!"=="1" (
    echo %GREEN%[OK] ImDisk detected — full RAM disk support available%RESET%
) else (
    echo %YELLOW%[INFO] ImDisk not detected — will use built-in subst method%RESET%
    echo %YELLOW%       For persistent NTFS RAM disks, install ImDisk:%RESET%
    echo %YELLOW%       https://sourceforge.net/projects/imdisk-toolkit/%RESET%
)

:: RAM recommendation
if !totalGBint! LSS 16 (
    echo/
    echo %RED%[WARNING] Your system has less than 16 GB RAM.%RESET%
    echo %RED%          RAM disks are not recommended below 16 GB.%RESET%
    echo %RED%          This may cause out-of-memory issues.%RESET%
    echo/
    set /p "forceConfirm=Continue anyway? [Y/N]: "
    if /i not "!forceConfirm!"=="Y" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
)

echo/

:MainMenu
echo %CYAN%============================================================================%RESET%
echo %CYAN% Main Menu%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   [1] Create RAM disk
echo   [2] Redirect %%TEMP%% to RAM disk
echo   [3] View current RAM disk status
echo   [4] Remove RAM disk
echo   [5] Recommended sizes guide
echo   [0] Exit
echo/

set /p "choice=Select option: "

if "%choice%"=="1" goto CreateDisk
if "%choice%"=="2" goto RedirectTemp
if "%choice%"=="3" goto Status
if "%choice%"=="4" goto RemoveDisk
if "%choice%"=="5" goto SizeGuide
if "%choice%"=="0" goto Exit

echo %RED%Invalid option.%RESET%
echo/
goto MainMenu

:: ============================================================================
:: Option 1: Create RAM Disk
:: ============================================================================
:CreateDisk
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Create RAM Disk%RESET%
echo %CYAN%============================================================================%RESET%
echo/

:: Suggest a size
if !totalGBint! GEQ 64 (
    set "suggestSize=8"
) else if !totalGBint! GEQ 32 (
    set "suggestSize=4"
) else if !totalGBint! GEQ 16 (
    set "suggestSize=2"
) else (
    set "suggestSize=1"
)

echo   Available RAM:     !freeGB! GB
echo   Suggested size:    !suggestSize! GB
echo/
echo   %YELLOW%RAM disk contents are LOST on reboot or shutdown.%RESET%
echo   %YELLOW%Do not store important data on the RAM disk.%RESET%
echo/

set /p "diskSize=RAM disk size in GB (default !suggestSize!): "
if "!diskSize!"=="" set "diskSize=!suggestSize!"

:: Choose drive letter
set "driveLetter=R"
echo/
set /p "driveLetter=Drive letter (default R): "
if "!driveLetter!"=="" set "driveLetter=R"
set "driveLetter=!driveLetter:~0,1!"

:: Check if drive letter is in use
if exist "!driveLetter!:\" (
    echo/
    echo %RED%[ERROR] Drive !driveLetter!: is already in use.%RESET%
    echo Choose a different letter.
    echo/
    pause
    goto CreateDisk
)

echo/
echo Creating !diskSize! GB RAM disk on !driveLetter!:
echo/

set /p "confirm=Continue? [Y/N]: "
if /i not "%confirm%"=="Y" goto MainMenu

:: Convert GB to MB for ImDisk
set /a diskSizeMB=diskSize*1024

if "!hasImDisk!"=="1" (
    :: ImDisk method - creates a real block device
    echo/
    echo [1/3] Creating RAM disk with ImDisk...

    imdisk -a -s !diskSizeMB!M -m !driveLetter!: -p "/fs:ntfs /q /y" >nul 2>&1
    if !errorlevel! equ 0 (
        echo       %GREEN%[OK] ImDisk RAM disk created on !driveLetter!:%RESET%
    ) else (
        :: Try with the full path
        "%ProgramFiles%\ImDisk\imdisk.exe" -a -s !diskSizeMB!M -m !driveLetter!: -p "/fs:ntfs /q /y" >nul 2>&1
        if !errorlevel! equ 0 (
            echo       %GREEN%[OK] ImDisk RAM disk created on !driveLetter!:%RESET%
        ) else (
            echo       %RED%[ERROR] Failed to create ImDisk RAM disk%RESET%
            echo       Trying built-in method...
            goto BuiltinCreate
        )
    )

    echo [2/3] Setting volume label...
    label !driveLetter!: RAMDisk >nul 2>&1
    echo       %GREEN%[OK] Volume labeled "RAMDisk"%RESET%

    echo [3/3] Creating standard folders...
    mkdir "!driveLetter!:\Temp" 2>nul
    mkdir "!driveLetter!:\Cache" 2>nul
    mkdir "!driveLetter!:\ShaderCache" 2>nul
    echo       %GREEN%[OK] Created Temp, Cache, and ShaderCache folders%RESET%

    goto CreateDone
)

:BuiltinCreate
:: Built-in method using a VHD in memory (Windows 10+)
echo/
echo [1/3] Creating RAM disk using built-in VHD method...

:: Create a PowerShell-based RAM disk
set "PSRAMDISK=%TEMP%\create_ramdisk.ps1"

(
echo # Create a VHD in memory and mount it
echo $vhdPath = "$env:TEMP\ramdisk.vhdx"
echo $sizeBytes = !diskSize!GB
echo/
echo # Remove existing if present
echo if ^(Test-Path $vhdPath^) { Remove-Item $vhdPath -Force }
echo/
echo # Create VHD
echo $diskpartScript = @"
echo create vdisk file="$vhdPath" maximum=!diskSizeMB! type=expandable
echo select vdisk file="$vhdPath"
echo attach vdisk
echo create partition primary
echo format fs=ntfs quick label="RAMDisk"
echo assign letter=!driveLetter!
echo "@
echo/
echo $diskpartScript ^| Out-File -FilePath "$env:TEMP\ramdisk_setup.txt" -Encoding ascii
echo diskpart /s "$env:TEMP\ramdisk_setup.txt" ^| Out-Null
echo Remove-Item "$env:TEMP\ramdisk_setup.txt" -Force -ErrorAction SilentlyContinue
echo/
echo if ^(Test-Path "!driveLetter!:\"^) {
echo     Write-Host "[OK] RAM disk created on !driveLetter!:"
echo } else {
echo     Write-Host "[ERROR] Failed to create RAM disk"
echo     exit 1
echo }
) > "!PSRAMDISK!"

powershell -ExecutionPolicy Bypass -File "!PSRAMDISK!" 2>nul
del "!PSRAMDISK!" 2>nul

if exist "!driveLetter!:\" (
    echo       %GREEN%[OK] VHD-based RAM disk created on !driveLetter!:%RESET%
) else (
    echo       %RED%[ERROR] Could not create RAM disk.%RESET%
    echo       %RED%        Install ImDisk for reliable RAM disk support.%RESET%
    echo/
    pause
    goto MainMenu
)

echo [2/3] Setting up structure...
mkdir "!driveLetter!:\Temp" 2>nul
mkdir "!driveLetter!:\Cache" 2>nul
mkdir "!driveLetter!:\ShaderCache" 2>nul
echo       %GREEN%[OK] Created Temp, Cache, and ShaderCache folders%RESET%

echo [3/3] Done.

:CreateDone
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% RAM Disk Created Successfully%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo   Drive:      !driveLetter!:
echo   Size:       !diskSize! GB
echo   Format:     NTFS
echo   Folders:    !driveLetter!:\Temp, !driveLetter!:\Cache, !driveLetter!:\ShaderCache
echo/
echo %YELLOW%IMPORTANT: RAM disk contents are LOST on reboot!%RESET%
echo/
echo %WHITE%Next steps:%RESET%
echo  - Use option [2] to redirect %%TEMP%% to the RAM disk
echo  - Set game shader cache to !driveLetter!:\ShaderCache
echo  - Set browser cache to !driveLetter!:\Cache
echo/

pause
goto MainMenu

:: ============================================================================
:: Option 2: Redirect TEMP
:: ============================================================================
:RedirectTemp
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Redirect %%TEMP%% to RAM Disk%RESET%
echo %CYAN%============================================================================%RESET%
echo/

set "driveLetter=R"
set /p "driveLetter=RAM disk drive letter (default R): "
if "!driveLetter!"=="" set "driveLetter=R"
set "driveLetter=!driveLetter:~0,1!"

if not exist "!driveLetter!:\" (
    echo %RED%[ERROR] Drive !driveLetter!: does not exist. Create the RAM disk first.%RESET%
    echo/
    pause
    goto MainMenu
)

if not exist "!driveLetter!:\Temp" mkdir "!driveLetter!:\Temp" 2>nul

echo Current TEMP locations:
echo   User TEMP:   %TEMP%
echo   User TMP:    %TMP%
echo/
echo Will be changed to: !driveLetter!:\Temp
echo/
echo %YELLOW%Options:%RESET%
echo   [1] Redirect for current session only (temporary)
echo   [2] Redirect permanently (survives reboot if RAM disk is recreated)
echo   [0] Cancel
echo/

set /p "tempChoice=Select option: "

if "%tempChoice%"=="0" goto MainMenu

if "%tempChoice%"=="1" (
    :: Session-only redirect
    set "TEMP=!driveLetter!:\Temp"
    set "TMP=!driveLetter!:\Temp"
    setx TEMP "!driveLetter!:\Temp" >nul 2>&1
    setx TMP "!driveLetter!:\Temp" >nul 2>&1
    echo/
    echo %GREEN%[OK] TEMP/TMP redirected to !driveLetter!:\Temp for new processes%RESET%
    echo %YELLOW%     Note: Already-running programs will use the old path.%RESET%
)

if "%tempChoice%"=="2" (
    :: Permanent redirect via registry
    reg add "HKCU\Environment" /v TEMP /t REG_EXPAND_SZ /d "!driveLetter!:\Temp" /f >nul 2>&1
    reg add "HKCU\Environment" /v TMP /t REG_EXPAND_SZ /d "!driveLetter!:\Temp" /f >nul 2>&1
    echo/
    echo %GREEN%[OK] TEMP/TMP permanently redirected to !driveLetter!:\Temp%RESET%
    echo/
    echo %YELLOW%IMPORTANT: You must ensure the RAM disk exists on every boot.%RESET%
    echo %YELLOW%If using ImDisk, set it to auto-create at startup.%RESET%
    echo %YELLOW%If the RAM disk is missing, TEMP operations will fail.%RESET%
    echo/
    echo To revert: run option [4] or manually set TEMP back to:
    echo   %%USERPROFILE%%\AppData\Local\Temp
)

echo/
pause
goto MainMenu

:: ============================================================================
:: Option 3: Status
:: ============================================================================
:Status
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% RAM Disk Status%RESET%
echo %CYAN%============================================================================%RESET%
echo/

echo %WHITE%Current environment variables:%RESET%
echo   TEMP = %TEMP%
echo   TMP  = %TMP%
echo/

echo %WHITE%Registry TEMP/TMP values:%RESET%
for /f "tokens=2,*" %%a in ('reg query "HKCU\Environment" /v TEMP 2^>nul ^| find "TEMP"') do echo   User TEMP = %%b
for /f "tokens=2,*" %%a in ('reg query "HKCU\Environment" /v TMP 2^>nul ^| find "TMP"') do echo   User TMP  = %%b
echo/

:: Check for ImDisk RAM disks
if "!hasImDisk!"=="1" (
    echo %WHITE%ImDisk virtual disks:%RESET%
    imdisk -l 2>nul
    if errorlevel 1 echo   No ImDisk virtual disks found.
    echo/
)

:: Check for VHD disks
echo %WHITE%Checking mounted volumes for RAM disks:%RESET%
echo/

set "foundRAM=0"
for %%d in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\" (
        vol %%d: 2>nul | find /i "RAMDisk" >nul 2>&1
        if not errorlevel 1 (
            echo   %GREEN%[FOUND] %%d: is a RAM disk%RESET%
            for /f "tokens=3" %%s in ('dir %%d:\ 2^>nul ^| findstr "free"') do echo           Free space: %%s bytes
            set "foundRAM=1"
        )
    )
)

if "!foundRAM!"=="0" (
    echo   No RAM disks detected.
)

echo/
pause
goto MainMenu

:: ============================================================================
:: Option 4: Remove RAM Disk
:: ============================================================================
:RemoveDisk
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% Remove RAM Disk%RESET%
echo %CYAN%============================================================================%RESET%
echo/

set "driveLetter=R"
set /p "driveLetter=Drive letter to remove (default R): "
if "!driveLetter!"=="" set "driveLetter=R"
set "driveLetter=!driveLetter:~0,1!"

if not exist "!driveLetter!:\" (
    echo %YELLOW%Drive !driveLetter!: does not exist.%RESET%
    echo/
    pause
    goto MainMenu
)

echo %YELLOW%This will destroy all data on !driveLetter!: immediately.%RESET%
echo/
set /p "confirm=Remove RAM disk !driveLetter!:? [Y/N]: "
if /i not "%confirm%"=="Y" goto MainMenu

:: Restore TEMP if it pointed to this drive
echo %TEMP% | find /i "!driveLetter!:" >nul 2>&1
if not errorlevel 1 (
    echo/
    echo Restoring TEMP/TMP to default location...
    reg add "HKCU\Environment" /v TEMP /t REG_EXPAND_SZ /d "%%USERPROFILE%%\AppData\Local\Temp" /f >nul 2>&1
    reg add "HKCU\Environment" /v TMP /t REG_EXPAND_SZ /d "%%USERPROFILE%%\AppData\Local\Temp" /f >nul 2>&1
    echo       %GREEN%[OK] TEMP/TMP restored to default%RESET%
)

:: Try ImDisk removal first
if "!hasImDisk!"=="1" (
    imdisk -D -m !driveLetter!: >nul 2>&1
    if not errorlevel 1 (
        echo       %GREEN%[OK] ImDisk RAM disk !driveLetter!: removed%RESET%
        echo/
        pause
        goto MainMenu
    )
)

:: Try VHD removal
set "PSREMOVE=%TEMP%\remove_ramdisk.ps1"

(
echo $diskpartScript = @"
echo select vdisk file="$env:TEMP\ramdisk.vhdx"
echo detach vdisk
echo "@
echo $diskpartScript ^| Out-File -FilePath "$env:TEMP\ramdisk_remove.txt" -Encoding ascii
echo diskpart /s "$env:TEMP\ramdisk_remove.txt" ^| Out-Null
echo Remove-Item "$env:TEMP\ramdisk_remove.txt" -Force -ErrorAction SilentlyContinue
echo Remove-Item "$env:TEMP\ramdisk.vhdx" -Force -ErrorAction SilentlyContinue
echo Write-Host "[OK] VHD RAM disk removed"
) > "!PSREMOVE!"

powershell -ExecutionPolicy Bypass -File "!PSREMOVE!" 2>nul
del "!PSREMOVE!" 2>nul

:: Fallback: try subst
subst !driveLetter!: /d >nul 2>&1

echo       %GREEN%[OK] RAM disk removed%RESET%
echo/
pause
goto MainMenu

:: ============================================================================
:: Option 5: Size Guide
:: ============================================================================
:SizeGuide
echo/
echo %CYAN%============================================================================%RESET%
echo %CYAN% RAM Disk Size Recommendations%RESET%
echo %CYAN%============================================================================%RESET%
echo/
echo %WHITE%  Total RAM    Recommended Disk    Use Case%RESET%
echo   ---------    ----------------    --------
echo   16 GB        1-2 GB              TEMP files only
echo   32 GB        2-4 GB              TEMP + browser cache
echo   64 GB        4-8 GB              TEMP + cache + shader cache
echo   128 GB       8-16 GB             Everything + game installs
echo/
echo %WHITE%  Common redirections and their typical sizes:%RESET%
echo/
echo   %%TEMP%%/%%TMP%%                     500 MB - 2 GB
echo   Browser cache (Chrome)         500 MB - 2 GB
echo   Browser cache (Firefox)        500 MB - 1 GB
echo   NVIDIA shader cache            200 MB - 1 GB
echo   AMD shader cache               200 MB - 1 GB
echo   Photoshop scratch disk         2 - 8 GB
echo   Game shader compilation cache  1 - 4 GB
echo/
echo %WHITE%  Browser cache redirection:%RESET%
echo/
echo   Chrome:
echo     Create shortcut with --disk-cache-dir=R:\Cache
echo     Or set LOCALAPPDATA to RAM disk
echo/
echo   Firefox:
echo     about:config ^> browser.cache.disk.parent_directory = R:\Cache
echo/
echo   Edge:
echo     Create shortcut with --disk-cache-dir=R:\Cache
echo/
echo %WHITE%  NVIDIA shader cache:%RESET%
echo     NVIDIA Control Panel ^> Manage 3D Settings ^>
echo     Shader Cache Size ^> set to R:\ShaderCache
echo/
echo %WHITE%  AMD shader cache:%RESET%
echo     AMD Software ^> Performance ^> Tuning ^>
echo     Set Reset Shader Cache location
echo/
echo %YELLOW%  REMEMBER: RAM disk data is LOST on every reboot!%RESET%
echo %YELLOW%  Only use for temporary/cache data that rebuilds automatically.%RESET%
echo/

pause
goto MainMenu

:Exit
echo/
echo Goodbye.
exit /b 0
