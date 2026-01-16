@echo off
setlocal
title Restore Recycle Bin
color 0A

:: ============================================================================
:: Restore Recycle Bin
:: ============================================================================
:: Restores the Recycle Bin icon to the Windows desktop.
:: ============================================================================

echo ============================================================================
echo  Restore Recycle Bin
echo ============================================================================
echo.
echo This script will restore the Recycle Bin icon to your desktop.
echo.

:: Recycle Bin CLSID
set "RECYCLE_BIN={645FF040-5081-101B-9F08-00AA002F954E}"

echo [1/4] Unhiding Recycle Bin from desktop icons...

:: Remove hide flags for NewStartPanel (Windows 7+)
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "%RECYCLE_BIN%" /f >nul 2>&1
if %errorlevel% equ 0 (
    echo       - Removed hide flag [NewStartPanel]
) else (
    echo       - No hide flag found [NewStartPanel]
)

:: Remove hide flags for ClassicStartMenu
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "%RECYCLE_BIN%" /f >nul 2>&1
if %errorlevel% equ 0 (
    echo       - Removed hide flag [ClassicStartMenu]
) else (
    echo       - No hide flag found [ClassicStartMenu]
)

echo.
echo [2/4] Ensuring Recycle Bin is registered in desktop namespace...

:: Add Recycle Bin to desktop namespace
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\%RECYCLE_BIN%" /ve /d "Recycle Bin" /f >nul 2>&1
echo       - Registered Recycle Bin in namespace

echo.
echo [3/4] Enabling Recycle Bin in desktop icon settings...

:: Set the desktop icon setting to show (0 = show, 1 = hide)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "%RECYCLE_BIN%" /t REG_DWORD /d 0 /f >nul 2>&1
echo       - Set visibility flag to show

echo.
echo [4/4] Refreshing desktop...

:: Refresh the desktop/explorer to apply changes
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
echo       - Explorer restarted

echo.
echo ============================================================================
echo  Recycle Bin Restored!
echo ============================================================================
echo.
echo The Recycle Bin should now be visible on your desktop.
echo.
echo If it's still missing, try:
echo  1. Right-click desktop ^> Personalize ^> Themes ^> Desktop icon settings
echo  2. Check the "Recycle Bin" checkbox
echo  3. Click Apply
echo.

pause
exit /b 0
