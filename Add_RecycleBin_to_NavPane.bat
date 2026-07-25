@echo off
:: Add Recycle Bin to File Explorer Navigation Pane
:: Run as Administrator for best results

echo Adding Recycle Bin to Navigation Pane...

reg add "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /f >nul 2>&1
reg add "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\ShellFolder" /v Attributes /t REG_DWORD /d 0x50000020 /f >nul 2>&1

echo Done. Restarting Explorer...

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe

echo/
echo Recycle Bin should now appear in the Navigation Pane.
pause
