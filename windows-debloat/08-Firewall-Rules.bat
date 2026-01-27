@echo off
setlocal
:: ============================================================================
:: Windows 10 Debloat - Add Firewall Rules to Block Telemetry
:: ============================================================================
:: This script creates Windows Firewall rules to block outbound connections
:: from known telemetry executables.
:: ============================================================================

echo ============================================================================
echo  Windows 10 Debloat - Add Firewall Rules
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

:: Clean up any leftover temp files from interrupted runs
del "%TEMP%\firewall-rules.ps1" 2>nul

echo This script will create firewall rules to block:
echo  - CompatTelRunner.exe (Compatibility Telemetry)
echo  - DeviceCensus.exe (Device Census)
echo  - smartscreen.exe (SmartScreen - blocks some functionality)
echo  - wsqmcons.exe (Windows SQM Consolidator)
echo.
echo NOTE: Blocking smartscreen.exe may reduce security protection.
echo       Only proceed if you understand the implications.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo ============================================================================
echo  Creating Firewall Rules...
echo ============================================================================
echo.

:: Create temporary PowerShell script
set "PSSCRIPT=%TEMP%\firewall-rules.ps1"

(
echo $telemetryApps = @^(
echo     @{Path="$env:SystemRoot\System32\CompatTelRunner.exe"; Name='Block CompatTelRunner ^(Telemetry^)'},
echo     @{Path="$env:SystemRoot\System32\DeviceCensus.exe"; Name='Block DeviceCensus ^(Telemetry^)'},
echo     @{Path="$env:SystemRoot\System32\smartscreen.exe"; Name='Block SmartScreen ^(Telemetry^)'},
echo     @{Path="$env:SystemRoot\System32\wsqmcons.exe"; Name='Block wsqmcons ^(Telemetry^)'}
echo ^)
echo.
echo foreach ^($app in $telemetryApps^) {
echo     $expandedPath = [Environment]::ExpandEnvironmentVariables^($app.Path^)
echo     if ^(Test-Path $expandedPath^) {
echo         $existingRule = Get-NetFirewallRule -DisplayName $app.Name -ErrorAction SilentlyContinue
echo         if ^($existingRule^) {
echo             Write-Host "Rule already exists: $^($app.Name^)" -ForegroundColor Yellow
echo         } else {
echo             Write-Host "Creating rule: $^($app.Name^)" -ForegroundColor Green
echo             New-NetFirewallRule -DisplayName $app.Name -Direction Outbound -Program $expandedPath -Action Block ^| Out-Null
echo         }
echo     } else {
echo         Write-Host "File not found ^(skipping^): $expandedPath" -ForegroundColor Gray
echo     }
echo }
echo Write-Host ''
echo Write-Host 'Done!' -ForegroundColor Green
) > "%PSSCRIPT%"

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%PSSCRIPT%"

:: Clean up
del "%PSSCRIPT%" 2>nul

echo.
echo ============================================================================
echo  Firewall rules created successfully!
echo ============================================================================
echo.
echo To view these rules, open Windows Defender Firewall with Advanced Security
echo and check Outbound Rules.
echo.
echo To remove a rule:
echo   netsh advfirewall firewall delete rule name="Rule Name"
echo.

pause
