@echo off
:: ============================================================================
:: Windows 10 Debloat - Remove Optional Windows Features
:: ============================================================================
:: This script removes optional Windows features using DISM.
:: Some of these are legacy features or potential security risks.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Remove Optional Windows Features
echo ============================================================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo This script will remove/disable the following optional features:
echo  - Internet Explorer 11
echo  - Windows Media Player
echo  - Work Folders Client
echo  - XPS Printing Services
echo  - Fax Services
echo  - SMB 1.0 Protocol (SECURITY RISK - WannaCry vulnerable)
echo  - PowerShell 2.0 (SECURITY RISK - used to bypass security)
echo.
echo NOTE: These changes require a reboot to complete.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo ============================================================================
echo  Removing Internet Explorer 11...
echo ============================================================================
dism /online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /NoRestart

echo.
echo ============================================================================
echo  Removing Windows Media Player...
echo ============================================================================
dism /online /Disable-Feature /FeatureName:WindowsMediaPlayer /NoRestart

echo.
echo ============================================================================
echo  Removing Work Folders Client...
echo ============================================================================
dism /online /Disable-Feature /FeatureName:WorkFolders-Client /NoRestart

echo.
echo ============================================================================
echo  Removing XPS Printing Services...
echo ============================================================================
dism /online /Disable-Feature /FeatureName:Printing-XPSServices-Features /NoRestart

echo.
echo ============================================================================
echo  Removing Fax Services...
echo ============================================================================
dism /online /Disable-Feature /FeatureName:FaxServicesClientPackage /NoRestart

echo.
echo ============================================================================
echo  Removing SMB 1.0 Protocol (Security Risk)...
echo ============================================================================
dism /online /Disable-Feature /FeatureName:SMB1Protocol /NoRestart

echo.
echo ============================================================================
echo  Removing PowerShell 2.0 (Security Risk)...
echo ============================================================================
dism /online /Disable-Feature /FeatureName:MicrosoftWindowsPowerShellV2 /NoRestart
dism /online /Disable-Feature /FeatureName:MicrosoftWindowsPowerShellV2Root /NoRestart

echo.
echo ============================================================================
echo  Optional features removed successfully!
echo ============================================================================
echo.
echo IMPORTANT: A reboot is REQUIRED to complete these changes.
echo.
echo To re-enable any feature, use:
echo dism /online /Enable-Feature /FeatureName:FeatureName
echo.

pause
