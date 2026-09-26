@echo off
:: Add Recycle Bin to File Explorer Navigation Pane
:: Run as Administrator for best results

echo Adding Recycle Bin to Navigation Pane...

:: Remove the per-user ShellFolder Attributes override written by earlier
:: versions of this script - it pinned nothing and changed how the shell
:: treats the Recycle Bin for this user.
reg delete "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\ShellFolder" /f >nul 2>&1
:: System.IsPinnedToNameSpaceTree=1 is what pins an item to the Navigation Pane
reg add "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 1 /f >nul 2>&1

echo Done. Restarting Explorer...

taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe

echo/
echo Recycle Bin should now appear in the Navigation Pane.
pause
