# BrightnessDiagnostic.ps1 - Helper script for BrightnessDiagnostic.bat
# This script handles all PowerShell operations for the brightness diagnostic tool

param(
    [Parameter(Mandatory=$true)]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [double]$GammaValue = 1.0
)

function Show-BrightnessInfo {
    Write-Host "Monitor Brightness Information" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host ""

    $brightness = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue
    if ($brightness) {
        Write-Host "Current Brightness Level: " -NoNewline
        Write-Host "$($brightness.CurrentBrightness)%" -ForegroundColor Green
        Write-Host ""
        Write-Host "Available Brightness Levels:" -ForegroundColor White
        Write-Host ($brightness.Level -join '%  ') -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "[INFO] Software brightness control not available" -ForegroundColor Yellow
        Write-Host "This is normal for desktop monitors - use physical buttons" -ForegroundColor Gray
        Write-Host ""
    }

    Write-Host ""
    Write-Host "Connected Monitors" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan

    $monitors = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorID -ErrorAction SilentlyContinue
    foreach ($mon in $monitors) {
        $name = ($mon.UserFriendlyName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ''
        $mfg = ($mon.ManufacturerName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_}) -join ''
        Write-Host "  Monitor: $name" -ForegroundColor White
        Write-Host "  Manufacturer: $mfg" -ForegroundColor Gray
        Write-Host ""
    }
}

function Get-CurrentBrightness {
    $brightness = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue
    if ($brightness) {
        Write-Host "  Current Brightness: $($brightness.CurrentBrightness)%" -ForegroundColor Cyan
        Write-Host "  Brightness Levels Available: $($brightness.Level -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "  [WARNING] Cannot read brightness - may be desktop monitor or unsupported display" -ForegroundColor Yellow
    }
}

function Get-DisplayAdapters {
    $adapters = Get-CimInstance Win32_VideoController
    foreach ($adapter in $adapters) {
        Write-Host "  Display: $($adapter.Name)" -ForegroundColor White
        Write-Host "  Driver Version: $($adapter.DriverVersion)" -ForegroundColor Gray
        $statusColor = if ($adapter.Status -eq 'OK') { 'Green' } else { 'Red' }
        Write-Host "  Status: $($adapter.Status)" -ForegroundColor $statusColor
        Write-Host ""
    }
}

function Get-SensorService {
    $service = Get-Service -Name 'SensrSvc' -ErrorAction SilentlyContinue
    if ($service) {
        $status = $service.Status
        $color = if ($status -eq 'Running') { 'Yellow' } else { 'Green' }
        Write-Host "  Sensor Monitoring Service: $status" -ForegroundColor $color
        if ($status -eq 'Running') {
            Write-Host "  [!] This service can cause auto-dimming based on ambient light" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Sensor Monitoring Service: Not Found" -ForegroundColor Green
    }
}

function Get-PowerPlanBrightness {
    $activeGuid = (powercfg /getactivescheme) -replace '.*GUID: ([a-f0-9-]+).*','$1'
    Write-Host "  Active Power Plan GUID: $activeGuid" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Checking display brightness settings..." -ForegroundColor White

    $dimSettings = powercfg /query $activeGuid 7516b95f-f776-4464-8c53-06167f40cc99 2>$null
    $dimSettingsText = $dimSettings | Out-String

    # Parse AC setting
    if ($dimSettingsText -match 'Current AC Power Setting Index:\s*0x([0-9a-fA-F]+)') {
        $acDim = [int]('0x' + $matches[1])
        $acColor = if ($acDim -lt 100) { 'Yellow' } else { 'Green' }
        Write-Host "  Display Dim Brightness (AC): $acDim%" -ForegroundColor $acColor
    } else {
        Write-Host "  Display Dim Brightness (AC): Not available" -ForegroundColor Gray
    }

    # Parse DC (battery) setting
    if ($dimSettingsText -match 'Current DC Power Setting Index:\s*0x([0-9a-fA-F]+)') {
        $dcDim = [int]('0x' + $matches[1])
        $dcColor = if ($dcDim -lt 100) { 'Yellow' } else { 'Green' }
        Write-Host "  Display Dim Brightness (Battery): $dcDim%" -ForegroundColor $dcColor
    } else {
        Write-Host "  Display Dim Brightness (Battery): Not available (desktop PC)" -ForegroundColor Gray
    }
}

function Get-CABCStatus {
    $cabc = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'KMD_EnableBrightnessInterface2' -ErrorAction SilentlyContinue
    if ($cabc) {
        if ($cabc.KMD_EnableBrightnessInterface2 -eq 1) {
            Write-Host "  CABC (Content Adaptive): ENABLED - may cause dimming based on content" -ForegroundColor Yellow
        } else {
            Write-Host "  CABC (Content Adaptive): DISABLED" -ForegroundColor Green
        }
    } else {
        Write-Host "  CABC: Setting not found (GPU may not support it)" -ForegroundColor Gray
    }
}

function Get-DPSTStatus {
    $dpst = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'DPST_Enabled' -ErrorAction SilentlyContinue
    if ($dpst) {
        if ($dpst.DPST_Enabled -eq 1) {
            Write-Host "  Intel DPST: ENABLED - causes auto-dimming!" -ForegroundColor Yellow
        } else {
            Write-Host "  Intel DPST: DISABLED" -ForegroundColor Green
        }
    }

    $variBright = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'PP_VariBrightFeatureControl' -ErrorAction SilentlyContinue
    if ($variBright) {
        Write-Host "  AMD Vari-Bright: Value = $($variBright.PP_VariBrightFeatureControl)" -ForegroundColor Yellow
    }
}

function Get-NightLightStatus {
    $nightLight = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.bluelightreductionstate\windows.data.bluelightreduction.bluelightreductionstate' -ErrorAction SilentlyContinue
    if ($nightLight.Data) {
        Write-Host "  Night Light: Configuration exists (may affect perceived brightness)" -ForegroundColor Yellow
    } else {
        Write-Host "  Night Light: Not configured or disabled" -ForegroundColor Green
    }
}

function Set-MaxBrightness {
    $brightness = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods -ErrorAction SilentlyContinue
    if ($brightness) {
        $brightness | Invoke-CimMethod -MethodName WmiSetBrightness -Arguments @{Brightness=100; Timeout=0} | Out-Null
        Write-Host "[OK] Brightness set to 100%" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Cannot set brightness via WMI - trying alternate method..." -ForegroundColor Yellow
        try {
            (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(0, 100)
            Write-Host "[OK] Brightness set to 100%" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Could not set brightness. This may be a desktop monitor." -ForegroundColor Red
            Write-Host "Desktop monitors typically use physical buttons for brightness." -ForegroundColor Yellow
        }
    }
}

function Set-GammaBoost {
    param([double]$Gamma)

    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class GammaRamp {
    [DllImport("gdi32.dll")]
    public static extern bool SetDeviceGammaRamp(IntPtr hDC, ref RAMP lpRamp);
    [DllImport("gdi32.dll")]
    public static extern bool GetDeviceGammaRamp(IntPtr hDC, ref RAMP lpRamp);
    [DllImport("user32.dll")]
    public static extern IntPtr GetDC(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct RAMP {
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256)]
        public UInt16[] Red;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256)]
        public UInt16[] Green;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256)]
        public UInt16[] Blue;
    }
}
"@

    $hdc = [GammaRamp]::GetDC([IntPtr]::Zero)
    $ramp = New-Object GammaRamp+RAMP
    $ramp.Red = New-Object UInt16[] 256
    $ramp.Green = New-Object UInt16[] 256
    $ramp.Blue = New-Object UInt16[] 256

    for ($i = 0; $i -lt 256; $i++) {
        $value = [Math]::Pow($i / 255.0, 1.0 / $Gamma) * 65535
        $value = [Math]::Min(65535, [Math]::Max(0, $value))
        $ramp.Red[$i] = [UInt16]$value
        $ramp.Green[$i] = [UInt16]$value
        $ramp.Blue[$i] = [UInt16]$value
    }

    $result = [GammaRamp]::SetDeviceGammaRamp($hdc, [ref]$ramp)
    [GammaRamp]::ReleaseDC([IntPtr]::Zero, $hdc) | Out-Null

    if ($result) {
        Write-Host "[OK] Gamma set to $Gamma" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to set gamma" -ForegroundColor Red
    }
}

function Reset-Gamma {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class GammaRampReset {
    [DllImport("gdi32.dll")]
    public static extern bool SetDeviceGammaRamp(IntPtr hDC, ref RAMP lpRamp);
    [DllImport("user32.dll")]
    public static extern IntPtr GetDC(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct RAMP {
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256)]
        public UInt16[] Red;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256)]
        public UInt16[] Green;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256)]
        public UInt16[] Blue;
    }
}
"@

    $hdc = [GammaRampReset]::GetDC([IntPtr]::Zero)
    $ramp = New-Object GammaRampReset+RAMP
    $ramp.Red = New-Object UInt16[] 256
    $ramp.Green = New-Object UInt16[] 256
    $ramp.Blue = New-Object UInt16[] 256

    for ($i = 0; $i -lt 256; $i++) {
        $value = $i * 256
        $ramp.Red[$i] = [UInt16]$value
        $ramp.Green[$i] = [UInt16]$value
        $ramp.Blue[$i] = [UInt16]$value
    }

    [GammaRampReset]::SetDeviceGammaRamp($hdc, [ref]$ramp) | Out-Null
    [GammaRampReset]::ReleaseDC([IntPtr]::Zero, $hdc) | Out-Null
    Write-Host "[OK] Gamma reset to default" -ForegroundColor Green
}

function Reset-DisplayAdapter {
    $adapters = Get-PnpDevice -Class Display -Status OK
    foreach ($adapter in $adapters) {
        Write-Host "Restarting: $($adapter.FriendlyName)" -ForegroundColor Yellow
        Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Enable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "[OK] Adapter restarted" -ForegroundColor Green
    }
}

function Restart-DisplayDriver {
    try {
        pnputil /restart-device "DISPLAY\*" 2>$null
        Write-Host "[OK] Display driver restart requested" -ForegroundColor Green
    } catch {
        Write-Host "[INFO] Could not restart display driver - may require restart" -ForegroundColor Yellow
    }
}

# Main action dispatcher
switch ($Action) {
    "view-brightness" { Show-BrightnessInfo }
    "get-brightness" { Get-CurrentBrightness }
    "get-adapters" { Get-DisplayAdapters }
    "get-sensor" { Get-SensorService }
    "get-powerplan" { Get-PowerPlanBrightness }
    "get-cabc" { Get-CABCStatus }
    "get-dpst" { Get-DPSTStatus }
    "get-nightlight" { Get-NightLightStatus }
    "set-max" { Set-MaxBrightness }
    "set-gamma" { Set-GammaBoost -Gamma $GammaValue }
    "reset-gamma" { Reset-Gamma }
    "reset-adapter" { Reset-DisplayAdapter }
    "restart-driver" { Restart-DisplayDriver }
    default { Write-Host "Unknown action: $Action" -ForegroundColor Red }
}
