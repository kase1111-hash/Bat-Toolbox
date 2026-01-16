@echo off
:: ============================================================================
:: Windows 10 Debloat - Disable Scheduled Tasks
:: ============================================================================
:: This script disables telemetry and data collection scheduled tasks.
:: These tasks run in the background and send data to Microsoft.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Disable Scheduled Tasks
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

echo This script will disable scheduled tasks related to:
echo  - Telemetry and data collection
echo  - Customer Experience Improvement Program
echo  - Disk diagnostics data collection
echo  - Feedback collection
echo  - Cloud sync features
echo  - Family safety monitoring
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo ============================================================================
echo  Disabling Telemetry Tasks...
echo ============================================================================

echo Disabling Microsoft Compatibility Appraiser...
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1

echo Disabling ProgramDataUpdater...
schtasks /Change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1

echo Disabling Autochk Proxy...
schtasks /Change /TN "\Microsoft\Windows\Autochk\Proxy" /Disable >nul 2>&1

echo Disabling CEIP Consolidator...
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1

echo Disabling USB CEIP...
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1

echo Disabling Disk Diagnostic Data Collector...
schtasks /Change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable >nul 2>&1

echo.
echo ============================================================================
echo  Disabling Feedback Tasks...
echo ============================================================================

echo Disabling DmClient...
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /Disable >nul 2>&1

echo Disabling DmClientOnScenarioDownload...
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable >nul 2>&1

echo.
echo ============================================================================
echo  Disabling Cloud/Sync Tasks...
echo ============================================================================

echo Disabling CloudExperienceHost CreateObjectTask...
schtasks /Change /TN "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask" /Disable >nul 2>&1

echo Disabling Maps Toast Task...
schtasks /Change /TN "\Microsoft\Windows\Maps\MapsToastTask" /Disable >nul 2>&1

echo Disabling Maps Update Task...
schtasks /Change /TN "\Microsoft\Windows\Maps\MapsUpdateTask" /Disable >nul 2>&1

echo.
echo ============================================================================
echo  Disabling Maintenance/Optional Tasks...
echo ============================================================================

echo Disabling Scheduled Diagnosis...
schtasks /Change /TN "\Microsoft\Windows\Diagnosis\Scheduled" /Disable >nul 2>&1

echo Disabling Power Efficiency Diagnostics...
schtasks /Change /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /Disable >nul 2>&1

echo Disabling Family Safety Monitor...
schtasks /Change /TN "\Microsoft\Windows\Shell\FamilySafetyMonitor" /Disable >nul 2>&1

echo Disabling Family Safety Refresh...
schtasks /Change /TN "\Microsoft\Windows\Shell\FamilySafetyRefreshTask" /Disable >nul 2>&1

echo.
echo ============================================================================
echo  Scheduled tasks disabled successfully!
echo ============================================================================
echo.
echo NOTE: To re-enable a task, use:
echo schtasks /Change /TN "TaskPath" /Enable
echo.

pause
