# BrightnessDiagnostic.ps1 - Helper script for BrightnessDiagnostic.bat
# This script handles all PowerShell operations for the brightness diagnostic tool

param(
    [Parameter(Mandatory=$true)]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [double]$GammaValue = 1.0
)

# ---------------------------------------------------------------------------
# Settings changed by the batch file's fixes (and restored by Reset)
# ---------------------------------------------------------------------------
$DisplayClassPath = 'SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$BackupRootPath = 'SOFTWARE\BrightnessDiagnostic'
$BackupPath = 'SOFTWARE\BrightnessDiagnostic\Backup'
$SubVideo = '7516b95f-f776-4464-8c53-06167f40cc99'
$AdaptBrightGuid = 'fbd9aa66-9553-4097-ba44-ed6e9d65eab8'   # ADAPTBRIGHT - Enable adaptive brightness
$DimBrightnessGuid = 'f1fbfde2-a960-4165-9f88-50667911ce96' # Dimmed display brightness, percent
$DimTimeoutGuid = '17aaa29b-8b43-4b94-aafe-35f64daaf1ee'    # VIDEODIM - Dim display after, seconds, 0 = never
# Values the batch file CREATES on display-class instances 0000/0001. The Intel
# FeatureTestControl value is only ever modified when it already exists.
$CreatedDriverValues = @('KMD_EnableBrightnessInterface2', 'PP_VariBrightFeatureControl', 'Disable_PSR', 'EnablePSR')

function Get-PowerIndexes {
    param([string]$Scheme, [string]$Setting)
    # powercfg labels are localized, so read the numbers instead: the last two
    # 0x######## values are the current AC and DC index. /qh also lists hidden
    # settings (VIDEODIM is hidden by default); fall back to /q if it is rejected.
    foreach ($querySwitch in '/qh', '/q') {
        $q = (powercfg $querySwitch $Scheme $SubVideo $Setting 2>$null) | Out-String
        $hex = @([regex]::Matches($q, ':\s*0x([0-9a-fA-F]{8})') | ForEach-Object { [Convert]::ToUInt32($_.Groups[1].Value, 16) })
        if ($hex.Count -ge 2) { return ,@($hex[-2], $hex[-1]) }
    }
    return $null
}

function Get-ActiveSchemeGuid {
    # Only the GUID in "powercfg /getactivescheme" output is language-independent.
    $text = (powercfg /getactivescheme 2>$null) | Out-String
    if ($text -match '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}') { return $matches[0] }
    return $null
}

function Get-DisplayInstanceNames {
    # Adapter instance keys (0000, 0001, ...) under the Display class key. Only
    # the names are enumerated: the sibling "Properties" key denies access.
    try {
        $cls = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($DisplayClassPath)
        if (-not $cls) { return }
        try { $cls.GetSubKeyNames() | Where-Object { $_ -match '^\d{4}$' } } finally { $cls.Close() }
    } catch { return }
}

function Test-IntelInstance {
    param([string]$Instance)
    try {
        $k = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$DisplayClassPath\$Instance")
        if (-not $k) { return $false }
        try { return ([string]$k.GetValue('ProviderName') -match 'Intel') } finally { $k.Close() }
    } catch { return $false }
}

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
    $activeGuid = Get-ActiveSchemeGuid
    if (-not $activeGuid) { $activeGuid = 'unknown' }
    Write-Host "  Active Power Plan GUID: $activeGuid" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Checking display brightness settings..." -ForegroundColor White

    # Query the individual settings - the first value in the whole Display
    # subgroup is a timeout in seconds, not the dimmed brightness.
    $dim = Get-PowerIndexes 'SCHEME_CURRENT' $DimBrightnessGuid
    if ($dim) {
        Write-Host "  Dimmed Display Brightness (AC): $($dim[0])%" -ForegroundColor $(if ($dim[0] -lt 100) { 'Yellow' } else { 'Green' })
        Write-Host "  Dimmed Display Brightness (Battery): $($dim[1])%" -ForegroundColor $(if ($dim[1] -lt 100) { 'Yellow' } else { 'Green' })
    } else {
        Write-Host "  Dimmed Display Brightness: Not available" -ForegroundColor Gray
    }

    $dimAfter = Get-PowerIndexes 'SCHEME_CURRENT' $DimTimeoutGuid
    if ($dimAfter) {
        foreach ($entry in @(@('AC', $dimAfter[0]), @('Battery', $dimAfter[1]))) {
            if ($entry[1] -eq 0) {
                Write-Host "  Dim Display After ($($entry[0])): never" -ForegroundColor Green
            } else {
                Write-Host "  Dim Display After ($($entry[0])): $($entry[1]) seconds idle" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  Dim Display After: Not available" -ForegroundColor Gray
    }
}

function Get-AdaptiveBrightness {
    # The Settings toggle "Change brightness automatically when lighting
    # changes" is the ADAPTBRIGHT power setting of the active plan.
    $idx = Get-PowerIndexes 'SCHEME_CURRENT' $AdaptBrightGuid
    if ($idx) {
        if ($idx[0] -ne 0 -or $idx[1] -ne 0) {
            Write-Host "  Adaptive Brightness: ENABLED (AC=$($idx[0]) DC=$($idx[1])) - can cause dimming" -ForegroundColor Yellow
        } else {
            Write-Host "  Adaptive Brightness: DISABLED" -ForegroundColor Green
        }
    } else {
        Write-Host "  Adaptive Brightness: not available on this device" -ForegroundColor Gray
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
    # Intel FeatureTestControl is a bitmask of driver features to turn OFF;
    # DPST is off only when bit 0x10 is set.
    $foundFtc = $false
    foreach ($inst in Get-DisplayInstanceNames) {
        if (-not (Test-IntelInstance $inst)) { continue }
        $ftc = (Get-ItemProperty -Path "HKLM:\$DisplayClassPath\$inst" -Name 'FeatureTestControl' -ErrorAction SilentlyContinue).FeatureTestControl
        if ($null -eq $ftc) { continue }
        $foundFtc = $true
        if (($ftc -band 0x10) -ne 0) {
            Write-Host ("  Intel DPST: DISABLED (adapter {0}, FeatureTestControl=0x{1:X})" -f $inst, $ftc) -ForegroundColor Green
        } else {
            Write-Host ("  Intel DPST: ENABLED - causes auto-dimming! (adapter {0}, FeatureTestControl=0x{1:X})" -f $inst, $ftc) -ForegroundColor Yellow
        }
    }
    if (-not $foundFtc) {
        Write-Host "  Intel DPST: no FeatureTestControl value found (no Intel GPU, or driver default)" -ForegroundColor Gray
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
        # 257 (not 256) gives the true identity ramp: 255 * 257 = 65535 (full
        # white). 256 tops out at 65280, leaving the screen fractionally dark.
        $value = $i * 257
        $ramp.Red[$i] = [UInt16]$value
        $ramp.Green[$i] = [UInt16]$value
        $ramp.Blue[$i] = [UInt16]$value
    }

    [GammaRampReset]::SetDeviceGammaRamp($hdc, [ref]$ramp) | Out-Null
    [GammaRampReset]::ReleaseDC([IntPtr]::Zero, $hdc) | Out-Null
    Write-Host "[OK] Gamma reset to default" -ForegroundColor Green
}

function Reset-DisplayAdapter {
    $adapters = @(Get-PnpDevice -Class Display -Status OK -ErrorAction SilentlyContinue)
    if ($adapters.Count -eq 0) {
        Write-Host "[INFO] No working display adapter found" -ForegroundColor Yellow
        return
    }
    foreach ($adapter in $adapters) {
        Write-Host "Restarting: $($adapter.FriendlyName)" -ForegroundColor Yellow
        try {
            Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            Enable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction Stop
            Write-Host "[OK] Adapter restarted" -ForegroundColor Green
        } catch {
            # Never leave the adapter disabled if the disable step went through.
            Enable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "[ERROR] Could not restart adapter: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Restart-DisplayDriver {
    # pnputil /restart-device needs an exact device instance ID (no wildcards),
    # admin rights and Windows 10 2004 or later. pnputil is a native command,
    # so check $LASTEXITCODE rather than try/catch.
    $adapters = @(Get-PnpDevice -Class Display -Status OK -ErrorAction SilentlyContinue)
    $ok = $adapters.Count -gt 0
    foreach ($d in $adapters) {
        pnputil /restart-device "$($d.InstanceId)" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { $ok = $false }
    }
    if ($ok) {
        Write-Host "[OK] Display driver restart requested" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Could not restart display driver - may require admin, Windows 10 2004+, or a manual restart" -ForegroundColor Yellow
    }
}

function Disable-IntelDPST {
    # Sets ONLY bit 0x10 (DPST off) in FeatureTestControl on Intel adapters
    # that already have the value; every other feature bit is kept. Run
    # backup-settings first so Reset can put the original value back.
    $found = 0
    try {
        foreach ($inst in Get-DisplayInstanceNames) {
            if (-not (Test-IntelInstance $inst)) { continue }
            $k = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$DisplayClassPath\$inst", $true)
            if (-not $k) { continue }
            try {
                $v = $k.GetValue('FeatureTestControl')
                if ($null -eq $v -or $k.GetValueKind('FeatureTestControl') -ne [Microsoft.Win32.RegistryValueKind]::DWord) { continue }
                $found++
                if (($v -band 0x10) -ne 0) {
                    Write-Host ("  [OK] Adapter {0}: DPST already disabled (FeatureTestControl=0x{1:X})" -f $inst, $v) -ForegroundColor Green
                } else {
                    $newValue = [int]($v -bor 0x10)
                    $k.SetValue('FeatureTestControl', $newValue, [Microsoft.Win32.RegistryValueKind]::DWord)
                    Write-Host ("  [OK] Adapter {0}: DPST disabled (FeatureTestControl 0x{1:X} -> 0x{2:X})" -f $inst, $v, $newValue) -ForegroundColor Green
                }
            } finally { $k.Close() }
        }
    } catch {
        Write-Host "  [ERROR] Could not change FeatureTestControl: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    if ($found -eq 0) {
        Write-Host "  [SKIP] No Intel adapter with a FeatureTestControl value - DPST setting not present" -ForegroundColor Yellow
    }
}

function Backup-BrightnessSettings {
    # Saves the ORIGINAL values once, before a fix changes them, under
    # HKLM\SOFTWARE\BrightnessDiagnostic\Backup. A value that is already
    # recorded is never overwritten, so running a fix twice cannot replace the
    # original with the fixed value. Returns $false if the backup failed.
    $lm = [Microsoft.Win32.Registry]::LocalMachine
    try {
        $root = $lm.CreateSubKey($BackupPath)
        try {
            # Power plan: stored as "AC,DC" per setting GUID, per plan GUID.
            $scheme = Get-ActiveSchemeGuid
            if ($scheme) {
                $pk = $root.CreateSubKey("Power\$scheme")
                try {
                    foreach ($setting in $AdaptBrightGuid, $DimBrightnessGuid, $DimTimeoutGuid) {
                        if ($null -ne $pk.GetValue($setting)) { continue }
                        $idx = Get-PowerIndexes $scheme $setting
                        if ($idx) { $pk.SetValue($setting, ('{0},{1}' -f $idx[0], $idx[1]), [Microsoft.Win32.RegistryValueKind]::String) }
                    }
                } finally { $pk.Close() }
            }

            # Display-class values: copied with their original type. Values
            # that did not exist are listed in BD_AbsentValues so Reset can
            # delete what the fixes created.
            foreach ($inst in Get-DisplayInstanceNames) {
                # FeatureTestControl is only changed on Intel adapters; the
                # other values are only written to adapters 0000 and 0001.
                $names = @()
                if (Test-IntelInstance $inst) { $names += 'FeatureTestControl' }
                if ($inst -eq '0000' -or $inst -eq '0001') { $names += $CreatedDriverValues }
                if ($names.Count -eq 0) { continue }
                $src = $lm.OpenSubKey("$DisplayClassPath\$inst")
                if (-not $src) { continue }
                $dk = $root.CreateSubKey("Driver\$inst")
                try {
                    $absent = @($dk.GetValue('BD_AbsentValues', @()))
                    foreach ($name in $names) {
                        if ($null -ne $dk.GetValue($name) -or $absent -contains $name) { continue }
                        $orig = $src.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                        if ($null -ne $orig) {
                            $dk.SetValue($name, $orig, $src.GetValueKind($name))
                        } elseif ($name -ne 'FeatureTestControl') {
                            $absent += $name
                        }
                    }
                    if ($absent.Count -gt 0) {
                        $dk.SetValue('BD_AbsentValues', [string[]]$absent, [Microsoft.Win32.RegistryValueKind]::MultiString)
                    }
                } finally { $dk.Close(); $src.Close() }
            }
        } finally { $root.Close() }
        Write-Host "  [OK] Original settings backed up to HKLM\$BackupPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [ERROR] Could not back up the current settings: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Restore-BrightnessSettings {
    # Undoes Quick Fix and the Advanced fixes from the backup made by
    # Backup-BrightnessSettings, then deletes the backup. Returns $false on error
    # (the backup is kept so Reset can be run again).
    $lm = [Microsoft.Win32.Registry]::LocalMachine
    $restoredPower = $false
    $restoredDriver = $false
    try {
        $root = $lm.OpenSubKey($BackupPath)
        if ($root) {
            try {
                $power = $root.OpenSubKey('Power')
                if ($power) {
                    try {
                        foreach ($scheme in $power.GetSubKeyNames()) {
                            $pk = $power.OpenSubKey($scheme)
                            try {
                                foreach ($setting in $pk.GetValueNames()) {
                                    $ac, $dc = ([string]$pk.GetValue($setting)) -split ','
                                    powercfg /setacvalueindex $scheme $SubVideo $setting $ac 2>$null | Out-Null
                                    $acOk = ($LASTEXITCODE -eq 0)
                                    powercfg /setdcvalueindex $scheme $SubVideo $setting $dc 2>$null | Out-Null
                                    if ($acOk -and $LASTEXITCODE -eq 0) { $restoredPower = $true }
                                }
                            } finally { $pk.Close() }
                        }
                    } finally { $power.Close() }
                }

                $driver = $root.OpenSubKey('Driver')
                if ($driver) {
                    try {
                        foreach ($inst in $driver.GetSubKeyNames()) {
                            $bk = $driver.OpenSubKey($inst)
                            $dst = $lm.OpenSubKey("$DisplayClassPath\$inst", $true)
                            try {
                                if (-not $dst) { continue }
                                foreach ($name in $bk.GetValueNames()) {
                                    if ($name -eq 'BD_AbsentValues') { continue }
                                    $dst.SetValue($name, $bk.GetValue($name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames), $bk.GetValueKind($name))
                                    $restoredDriver = $true
                                }
                                foreach ($name in @($bk.GetValue('BD_AbsentValues', @()))) {
                                    $dst.DeleteValue($name, $false)
                                    $restoredDriver = $true
                                }
                            } finally {
                                $bk.Close()
                                if ($dst) { $dst.Close() }
                            }
                        }
                    } finally { $driver.Close() }
                }
            } finally { $root.Close() }
        }

        if ($restoredPower) {
            Write-Host "  [OK] Power plan brightness settings restored from backup" -ForegroundColor Green
        } else {
            # No backup (no fix was run, or it was run by an older version of
            # this tool): turn adaptive brightness back on in the active plan.
            powercfg /setacvalueindex SCHEME_CURRENT $SubVideo $AdaptBrightGuid 1 2>$null | Out-Null
            powercfg /setdcvalueindex SCHEME_CURRENT $SubVideo $AdaptBrightGuid 1 2>$null | Out-Null
            Write-Host "  [OK] No power plan backup found - adaptive brightness turned back on" -ForegroundColor Green
        }
        powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null

        # DPST_Enabled is not an Intel driver value; older versions of this
        # tool created it on adapters 0000/0001, so remove the leftover.
        foreach ($inst in Get-DisplayInstanceNames) {
            if ($inst -ne '0000' -and $inst -ne '0001') { continue }
            $k = $lm.OpenSubKey("$DisplayClassPath\$inst", $true)
            if ($k) { try { $k.DeleteValue('DPST_Enabled', $false) } finally { $k.Close() } }
        }

        if ($restoredDriver) {
            Write-Host "  [OK] Display driver values restored from backup (restart to apply)" -ForegroundColor Green
        } else {
            Write-Host "  [INFO] No display driver backup found - driver values left unchanged" -ForegroundColor Yellow
        }
        $lm.DeleteSubKeyTree($BackupRootPath, $false)
        return $true
    } catch {
        Write-Host "  [ERROR] Could not restore settings: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main action dispatcher
switch ($Action) {
    "view-brightness" { Show-BrightnessInfo }
    "get-brightness" { Get-CurrentBrightness }
    "get-adapters" { Get-DisplayAdapters }
    "get-sensor" { Get-SensorService }
    "get-adaptive" { Get-AdaptiveBrightness }
    "get-powerplan" { Get-PowerPlanBrightness }
    "get-cabc" { Get-CABCStatus }
    "get-dpst" { Get-DPSTStatus }
    "get-nightlight" { Get-NightLightStatus }
    "set-max" { Set-MaxBrightness }
    "set-gamma" { Set-GammaBoost -Gamma $GammaValue }
    "reset-gamma" { Reset-Gamma }
    "reset-adapter" { Reset-DisplayAdapter }
    "restart-driver" { Restart-DisplayDriver }
    "disable-dpst" { Disable-IntelDPST }
    "backup-settings" { if (-not (Backup-BrightnessSettings)) { exit 1 } }
    "restore-settings" { if (-not (Restore-BrightnessSettings)) { exit 1 } }
    default { Write-Host "Unknown action: $Action" -ForegroundColor Red }
}
