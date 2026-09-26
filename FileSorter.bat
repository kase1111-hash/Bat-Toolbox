@echo off
:: Delayed expansion stays OFF while file names are read (it would strip "!"
:: from names); it is switched on per file inside the loop below.
setlocal DisableDelayedExpansion
title File Sorter by Type
color 0A

:: Get script directory and name
set "basedir=%~dp0"
set "scriptname=%~nx0"

echo ============================================
echo   FILE SORTER BY TYPE
echo ============================================
echo/
echo Base directory: %basedir%
echo/
echo This will organize the files in this folder (not subfolders) into folders
echo named by their file extension.
echo/
set "confirm="
set /p "confirm=Continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo/
echo Scanning files...
echo/

set "moved=0"
set "skipped=0"
set "errors=0"

:: Process only the files directly in this folder. Subfolders are not entered:
:: sorting them would pull project folders and albums apart with no way back.
:: (Plain FOR also skips hidden and system files.)
for %%F in ("%basedir%*") do (
    REM Get file info - read while delayed expansion is off so "!" survives
    set "filepath=%%~fF"
    set "filename=%%~nxF"
    set "fileext=%%~xF"
    set "filedir=%%~dpF"
    setlocal EnableDelayedExpansion

    REM Skip this script
    if /i "!filename!"=="!scriptname!" (
        echo [SKIP] !filename! ^(this script^)
        set /a skipped+=1
    ) else (
        REM Handle files with no extension
        if "!fileext!"=="" (
            set "typename=NO_EXTENSION"
        ) else (
            REM Remove the dot and convert to uppercase
            set "typename=!fileext:~1!"
            for %%U in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
                set "typename=!typename:%%U=%%U!"
            )
        )

        REM Set target folder
        set "targetdir=!basedir!!typename!"

        REM Check if file is already in a type folder
        if /i "!filedir!"=="!targetdir!\" (
            echo [SKIP] !filename! ^(already sorted^)
            set /a skipped+=1
        ) else (
            REM Create folder if it doesn't exist
            if not exist "!targetdir!" (
                mkdir "!targetdir!" 2>nul
                if !errorlevel! neq 0 (
                    echo [ERROR] Could not create folder: !typename!
                    set /a errors+=1
                ) else (
                    echo [NEW]  Created folder: !typename!
                )
            )

            REM Check if file with same name exists in target
            if exist "!targetdir!\!filename!" (
                echo [SKIP] !filename! ^(duplicate name in !typename!^)
                set /a skipped+=1
            ) else (
                REM Move the file
                move "!filepath!" "!targetdir!\" >nul 2>&1
                if !errorlevel! neq 0 (
                    echo [ERROR] !filename!
                    set /a errors+=1
                ) else (
                    echo [MOVED] !filename! -^> !typename!
                    set /a moved+=1
                )
            )
        )
    )

    REM Carry the counters out of the per-file setlocal
    for /f "tokens=1-3" %%a in ("!moved! !skipped! !errors!") do (
        endlocal
        set "moved=%%a"
        set "skipped=%%b"
        set "errors=%%c"
    )
)

echo/
echo ============================================
echo   COMPLETE
echo ============================================
echo/
echo Files moved:   %moved%
echo Files skipped: %skipped%
echo Errors:        %errors%
echo/
echo ============================================
pause
