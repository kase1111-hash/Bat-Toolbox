@echo off
setlocal enabledelayedexpansion
title File Sorter by Type
color 0A

:: Get script directory and name
set "basedir=%~dp0"
set "scriptname=%~nx0"

echo ============================================
echo   FILE SORTER BY TYPE
echo ============================================
echo.
echo Base directory: %basedir%
echo.
echo This will organize all files into folders
echo named by their file extension.
echo.
set /p "confirm=Continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
echo Scanning files...
echo.

set "moved=0"
set "skipped=0"
set "errors=0"

:: Process all files recursively
for /r "%basedir%" %%F in (*) do (
    :: Get file info
    set "filepath=%%F"
    set "filename=%%~nxF"
    set "fileext=%%~xF"
    set "filedir=%%~dpF"

    :: Skip this script
    if /i "!filename!"=="%scriptname%" (
        echo [SKIP] !filename! ^(this script^)
        set /a skipped+=1
    ) else (
        :: Handle files with no extension
        if "!fileext!"=="" (
            set "typename=NO_EXTENSION"
        ) else (
            :: Remove the dot and convert to uppercase
            set "typename=!fileext:~1!"
            for %%U in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
                set "typename=!typename:%%U=%%U!"
            )
        )

        :: Set target folder
        set "targetdir=%basedir%!typename!"

        :: Check if file is already in a type folder
        if /i "!filedir!"=="!targetdir!\" (
            echo [SKIP] !filename! ^(already sorted^)
            set /a skipped+=1
        ) else (
            :: Create folder if it doesn't exist
            if not exist "!targetdir!" (
                mkdir "!targetdir!" 2>nul
                if errorlevel 1 (
                    echo [ERROR] Could not create folder: !typename!
                    set /a errors+=1
                ) else (
                    echo [NEW]  Created folder: !typename!
                )
            )

            :: Check if file with same name exists in target
            if exist "!targetdir!\!filename!" (
                echo [SKIP] !filename! ^(duplicate name in !typename!^)
                set /a skipped+=1
            ) else (
                :: Move the file
                move "!filepath!" "!targetdir!\" >nul 2>&1
                if errorlevel 1 (
                    echo [ERROR] !filename!
                    set /a errors+=1
                ) else (
                    echo [MOVED] !filename! -^> !typename!
                    set /a moved+=1
                )
            )
        )
    )
)

echo.
echo ============================================
echo   COMPLETE
echo ============================================
echo.
echo Files moved:   %moved%
echo Files skipped: %skipped%
echo Errors:        %errors%
echo.
echo ============================================
pause
