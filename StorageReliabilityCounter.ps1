# StorageReliabilityCounter.ps1
# Helper script for StorageReliabilityCounter.bat
# Usage: powershell -ExecutionPolicy Bypass -File StorageReliabilityCounter.ps1 -Mode <Quick|Detail|Export> [-ReportPath <path>]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Quick','Detail','Export')]
    [string]$Mode,

    [Parameter(Mandatory=$false)]
    [string]$ReportPath
)

$ErrorActionPreference = 'SilentlyContinue'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ============================================================================
# Quick Health Overview
# ============================================================================
function Show-QuickOverview {
    $disks = Get-PhysicalDisk
    if (-not $disks) {
        Write-Host "[ERROR] Could not enumerate physical disks." -ForegroundColor Red
        exit 1
    }

    Write-Host ("{0,-8} {1,-25} {2,-10} {3,-12} {4,-15} {5}" -f "Disk", "Model", "Size", "Type", "Health", "Status") -ForegroundColor White
    Write-Host ("{0,-8} {1,-25} {2,-10} {3,-12} {4,-15} {5}" -f ("-"*7), ("-"*24), ("-"*9), ("-"*11), ("-"*14), ("-"*10))

    foreach ($disk in $disks) {
        $id = $disk.DeviceID
        $model = $disk.FriendlyName
        if ($model.Length -gt 24) { $model = $model.Substring(0, 21) + '...' }
        $sizeGB = [math]::Round($disk.Size / 1GB, 0)
        $size = "$sizeGB GB"
        $type = $disk.MediaType
        if (-not $type -or $type -eq 'Unspecified') { $type = 'Unknown' }
        $health = $disk.HealthStatus
        $status = $disk.OperationalStatus

        $color = 'Green'
        if ($health -ne 'Healthy') { $color = 'Red' }
        if ($status -ne 'OK') { $color = 'Red' }

        $line = "{0,-8} {1,-25} {2,-10} {3,-12} {4,-15} {5}" -f "Disk $id", $model, $size, $type, $health, $status
        Write-Host $line -ForegroundColor $color
    }

    Write-Host ""

    if ($isAdmin) {
        Write-Host "RELIABILITY COUNTERS" -ForegroundColor White
        Write-Host "====================" -ForegroundColor White
        Write-Host ""

        foreach ($disk in $disks) {
            $id = $disk.DeviceID
            $model = $disk.FriendlyName
            Write-Host "Disk $id - $model" -ForegroundColor Cyan
            Write-Host ("-" * 60)

            $rel = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue

            if ($rel) {
                # Temperature
                $temp = $rel.Temperature
                if ($temp -and $temp -gt 0) {
                    $tempColor = 'Green'
                    $tempStatus = 'OK'
                    if ($temp -ge 50) { $tempColor = 'Yellow'; $tempStatus = 'WARM' }
                    if ($temp -ge 60) { $tempColor = 'Red'; $tempStatus = 'HOT' }
                    if ($temp -ge 70) { $tempColor = 'Red'; $tempStatus = 'CRITICAL' }
                    Write-Host ("  Temperature:          {0}C [{1}]" -f $temp, $tempStatus) -ForegroundColor $tempColor
                } else {
                    Write-Host "  Temperature:          N/A"
                }

                # Power-on hours
                $poh = $rel.PowerOnHours
                if ($poh -and $poh -gt 0) {
                    $days = [math]::Round($poh / 24, 0)
                    $years = [math]::Round($poh / 8760, 1)
                    $pohColor = 'Green'
                    $pohStatus = 'OK'
                    if ($poh -ge 35000) { $pohColor = 'Yellow'; $pohStatus = 'HIGH' }
                    if ($poh -ge 50000) { $pohColor = 'Red'; $pohStatus = 'VERY HIGH' }
                    Write-Host ("  Power-On Hours:       {0} hrs ({1} days / {2} years) [{3}]" -f $poh, $days, $years, $pohStatus) -ForegroundColor $pohColor
                } else {
                    Write-Host "  Power-On Hours:       N/A"
                }

                # Wear level (SSD specific)
                $wear = $rel.Wear
                if ($wear -ne $null -and $wear -ge 0) {
                    $remainPct = 100 - $wear
                    $wearColor = 'Green'
                    $wearStatus = 'OK'
                    if ($remainPct -le 30) { $wearColor = 'Yellow'; $wearStatus = 'WORN' }
                    if ($remainPct -le 10) { $wearColor = 'Red'; $wearStatus = 'REPLACE SOON' }
                    Write-Host ("  Wear Level:           {0}% used, {1}% remaining [{2}]" -f $wear, $remainPct, $wearStatus) -ForegroundColor $wearColor
                }

                # Read/Write errors
                $readErr = $rel.ReadErrorsTotal
                $writeErr = $rel.WriteErrorsTotal
                if ($readErr -ne $null) {
                    $errColor = if ($readErr -gt 0) { 'Yellow' } else { 'Green' }
                    Write-Host ("  Read Errors Total:    {0}" -f $readErr) -ForegroundColor $errColor
                }
                if ($writeErr -ne $null) {
                    $errColor = if ($writeErr -gt 0) { 'Yellow' } else { 'Green' }
                    Write-Host ("  Write Errors Total:   {0}" -f $writeErr) -ForegroundColor $errColor
                }

                # Uncorrected errors
                $readErrUncorr = $rel.ReadErrorsUncorrected
                $writeErrUncorr = $rel.WriteErrorsUncorrected
                if ($readErrUncorr -ne $null -and $readErrUncorr -gt 0) {
                    Write-Host ("  Read Errors Uncorrected:  {0}" -f $readErrUncorr) -ForegroundColor Red
                }
                if ($writeErrUncorr -ne $null -and $writeErrUncorr -gt 0) {
                    Write-Host ("  Write Errors Uncorrected: {0}" -f $writeErrUncorr) -ForegroundColor Red
                }

                # Start/stop count
                $startStop = $rel.StartStopCycleCount
                if ($startStop -and $startStop -gt 0) {
                    Write-Host ("  Start/Stop Cycles:    {0}" -f $startStop)
                }

                # Flash writes (SSD)
                $flashWrites = $rel.FlashWrites
                if ($flashWrites -ne $null -and $flashWrites -gt 0) {
                    Write-Host ("  Flash Writes:         {0}" -f $flashWrites)
                }
            } else {
                Write-Host "  Reliability data not available for this drive."
                Write-Host "  (Drive may not support StorageReliabilityCounter)"
            }

            Write-Host ""
        }
    } else {
        Write-Host "Run as administrator for reliability counters (temperature, wear, errors)." -ForegroundColor Yellow
        Write-Host ""
    }

    # Volume info (works without admin)
    Write-Host "VOLUME INFORMATION" -ForegroundColor White
    Write-Host "==================" -ForegroundColor White
    Write-Host ""
    Write-Host ("{0,-6} {1,-12} {2,-12} {3,-10} {4,-10} {5}" -f "Drive", "Total", "Free", "Free %", "Format", "Label") -ForegroundColor White
    Write-Host ("{0,-6} {1,-12} {2,-12} {3,-10} {4,-10} {5}" -f ("-"*5), ("-"*11), ("-"*11), ("-"*9), ("-"*9), ("-"*15))

    $vols = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($v in $vols) {
        $totalGB = [math]::Round($v.Size / 1GB, 1)
        $freeGB = [math]::Round($v.FreeSpace / 1GB, 1)
        $freePct = if ($v.Size -gt 0) { [math]::Round(($v.FreeSpace / $v.Size) * 100, 1) } else { 0 }
        $freeColor = 'Green'
        if ($freePct -lt 15) { $freeColor = 'Yellow' }
        if ($freePct -lt 5) { $freeColor = 'Red' }
        $line = "{0,-6} {1,-12} {2,-12} {3,-10} {4,-10} {5}" -f $v.DeviceID, "$totalGB GB", "$freeGB GB", "$freePct%", $v.FileSystem, $v.VolumeName
        Write-Host $line -ForegroundColor $freeColor
    }
    Write-Host ""
}

# ============================================================================
# Detailed Reliability Report
# ============================================================================
function Show-DetailedReport {
    $disks = Get-PhysicalDisk
    if (-not $disks) {
        Write-Host "[ERROR] Could not enumerate physical disks." -ForegroundColor Red
        exit 1
    }

    foreach ($disk in $disks) {
        $id = $disk.DeviceID
        $model = $disk.FriendlyName
        $serial = $disk.SerialNumber
        $fw = $disk.FirmwareVersion
        $sizeGB = [math]::Round($disk.Size / 1GB, 1)
        $type = $disk.MediaType
        $bus = $disk.BusType
        $health = $disk.HealthStatus
        $status = $disk.OperationalStatus

        Write-Host "============================================================================" -ForegroundColor Cyan
        Write-Host " Disk $id - $model" -ForegroundColor White
        Write-Host "============================================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "  IDENTIFICATION" -ForegroundColor White
        Write-Host "  Model:                $model"
        if ($serial) { Write-Host "  Serial Number:        $($serial.Trim())" }
        if ($fw) { Write-Host "  Firmware Version:     $fw" }
        Write-Host "  Capacity:             $sizeGB GB"
        Write-Host "  Media Type:           $type"
        Write-Host "  Bus Type:             $bus"
        Write-Host ""

        # Health assessment
        Write-Host "  HEALTH STATUS" -ForegroundColor White
        $hColor = if ($health -eq 'Healthy') { 'Green' } else { 'Red' }
        Write-Host "  Health:               $health" -ForegroundColor $hColor
        $sColor = if ($status -eq 'OK') { 'Green' } else { 'Red' }
        Write-Host "  Operational Status:   $status" -ForegroundColor $sColor
        Write-Host ""

        if ($isAdmin) {
            $rel = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue

            if ($rel) {
                Write-Host "  RELIABILITY COUNTERS" -ForegroundColor White

                # Temperature
                $temp = $rel.Temperature
                if ($temp -and $temp -gt 0) {
                    $tempC = $temp
                    $tempF = [math]::Round($temp * 9/5 + 32, 0)
                    $tempColor = 'Green'
                    $tempNote = 'Normal'
                    if ($temp -ge 45) { $tempColor = 'Green'; $tempNote = 'Normal (warm)' }
                    if ($temp -ge 50) { $tempColor = 'Yellow'; $tempNote = 'Warm - check airflow' }
                    if ($temp -ge 60) { $tempColor = 'Red'; $tempNote = 'Hot - improve cooling' }
                    if ($temp -ge 70) { $tempColor = 'Red'; $tempNote = 'CRITICAL - drive may throttle or fail' }
                    Write-Host ("  Temperature:          {0}C / {1}F  [{2}]" -f $tempC, $tempF, $tempNote) -ForegroundColor $tempColor
                }

                # Power-on hours
                $poh = $rel.PowerOnHours
                if ($poh -and $poh -gt 0) {
                    $days = [math]::Round($poh / 24, 0)
                    $years = [math]::Round($poh / 8760, 1)
                    $pohColor = 'Green'
                    $pohNote = 'Low usage'
                    if ($poh -ge 10000) { $pohNote = 'Moderate usage' }
                    if ($poh -ge 25000) { $pohNote = 'Well used'; $pohColor = 'Green' }
                    if ($poh -ge 35000) { $pohNote = 'High usage - monitor closely'; $pohColor = 'Yellow' }
                    if ($poh -ge 50000) { $pohNote = 'Very high - consider replacement'; $pohColor = 'Red' }
                    Write-Host ("  Power-On Hours:       {0:N0} hrs ({1} days / {2} years)  [{3}]" -f $poh, $days, $years, $pohNote) -ForegroundColor $pohColor

                    # Estimate daily usage
                    if ($poh -gt 168) {
                        $dailyUse = [math]::Min(24, [math]::Round(24 * ($poh / [math]::Max(1, $days * 24)), 1))
                        Write-Host ("  Average Daily Use:    ~{0:N0} hrs/day (estimated)" -f $dailyUse)
                    }
                }

                # Wear level
                $wear = $rel.Wear
                if ($wear -ne $null -and $wear -ge 0) {
                    $remain = 100 - $wear
                    $wearColor = 'Green'
                    $wearNote = 'Excellent'
                    if ($remain -le 80) { $wearNote = 'Good' }
                    if ($remain -le 50) { $wearNote = 'Fair'; $wearColor = 'Yellow' }
                    if ($remain -le 30) { $wearNote = 'Worn - plan replacement'; $wearColor = 'Yellow' }
                    if ($remain -le 10) { $wearNote = 'CRITICAL - replace immediately'; $wearColor = 'Red' }
                    Write-Host ("  Wear Level:           {0}% used / {1}% remaining  [{2}]" -f $wear, $remain, $wearNote) -ForegroundColor $wearColor

                    # Estimate remaining life based on wear and POH
                    if ($poh -gt 0 -and $wear -gt 0) {
                        $remainHours = [math]::Round(($poh / $wear) * $remain)
                        $remainYears = [math]::Round($remainHours / 8760, 1)
                        if ($remainYears -gt 0 -and $remainYears -lt 50) {
                            Write-Host ("  Est. Remaining Life:  ~{0:N0} hours ({1} years at current rate)" -f $remainHours, $remainYears)
                        }
                    }
                }

                # Error counters
                Write-Host ""
                Write-Host "  ERROR COUNTERS" -ForegroundColor White

                $readErr = $rel.ReadErrorsTotal
                $writeErr = $rel.WriteErrorsTotal
                $readCorr = $rel.ReadErrorsCorrected
                $readUncorr = $rel.ReadErrorsUncorrected
                $writeCorr = $rel.WriteErrorsCorrected
                $writeUncorr = $rel.WriteErrorsUncorrected

                if ($readErr -ne $null) {
                    $c = if ($readErr -gt 0) { 'Yellow' } else { 'Green' }
                    Write-Host ("  Read Errors Total:        {0}" -f $readErr) -ForegroundColor $c
                }
                if ($readCorr -ne $null -and $readCorr -gt 0) {
                    Write-Host ("  Read Errors Corrected:    {0}" -f $readCorr) -ForegroundColor Yellow
                }
                if ($readUncorr -ne $null -and $readUncorr -gt 0) {
                    Write-Host ("  Read Errors UNCORRECTED:  {0}" -f $readUncorr) -ForegroundColor Red
                }
                if ($writeErr -ne $null) {
                    $c = if ($writeErr -gt 0) { 'Yellow' } else { 'Green' }
                    Write-Host ("  Write Errors Total:       {0}" -f $writeErr) -ForegroundColor $c
                }
                if ($writeCorr -ne $null -and $writeCorr -gt 0) {
                    Write-Host ("  Write Errors Corrected:   {0}" -f $writeCorr) -ForegroundColor Yellow
                }
                if ($writeUncorr -ne $null -and $writeUncorr -gt 0) {
                    Write-Host ("  Write Errors UNCORRECTED: {0}" -f $writeUncorr) -ForegroundColor Red
                }

                if (($readErr -eq $null -or $readErr -eq 0) -and ($writeErr -eq $null -or $writeErr -eq 0)) {
                    Write-Host "  No errors detected." -ForegroundColor Green
                }

                # Additional counters
                $startStop = $rel.StartStopCycleCount
                $loadUnload = $rel.LoadUnloadCycleCount
                $flashWrites = $rel.FlashWrites

                if ($startStop -or $loadUnload -or $flashWrites) {
                    Write-Host ""
                    Write-Host "  USAGE COUNTERS" -ForegroundColor White
                    if ($startStop -and $startStop -gt 0) {
                        Write-Host ("  Start/Stop Cycles:    {0:N0}" -f $startStop)
                    }
                    if ($loadUnload -and $loadUnload -gt 0) {
                        Write-Host ("  Load/Unload Cycles:   {0:N0}" -f $loadUnload)
                    }
                    if ($flashWrites -and $flashWrites -gt 0) {
                        Write-Host ("  Flash Writes:         {0:N0}" -f $flashWrites)
                    }
                }
            } else {
                Write-Host "  Reliability counters not available for this drive." -ForegroundColor Yellow
                Write-Host "  (Drive may not expose StorageReliabilityCounter data)"
            }

            # Get partition info
            Write-Host ""
            Write-Host "  PARTITIONS" -ForegroundColor White
            $parts = Get-Partition -DiskNumber $id -ErrorAction SilentlyContinue
            if ($parts) {
                foreach ($p in $parts) {
                    $pSizeGB = [math]::Round($p.Size / 1GB, 1)
                    $letter = if ($p.DriveLetter) { "$($p.DriveLetter):" } else { "(no letter)" }
                    $pType = $p.Type
                    if (-not $pType) { $pType = $p.GptType }
                    Write-Host ("    {0,-10} {1,-10} {2}" -f $letter, "$pSizeGB GB", $pType)
                }
            }
        } else {
            Write-Host "  (Run as administrator for reliability counters)" -ForegroundColor Yellow
        }

        # Overall assessment
        Write-Host ""
        Write-Host "  ASSESSMENT" -ForegroundColor White
        $issues = @()

        if ($health -ne 'Healthy') { $issues += "Health status is $health" }
        if ($status -ne 'OK') { $issues += "Operational status is $status" }

        if ($isAdmin -and $rel) {
            if ($rel.Temperature -ge 60) { $issues += "Temperature is too high ($($rel.Temperature)C)" }
            if ($rel.Wear -ne $null -and (100 - $rel.Wear) -le 10) { $issues += "SSD wear level critical ($($rel.Wear)% used)" }
            if ($rel.ReadErrorsUncorrected -and $rel.ReadErrorsUncorrected -gt 0) { $issues += "Uncorrected read errors detected" }
            if ($rel.WriteErrorsUncorrected -and $rel.WriteErrorsUncorrected -gt 0) { $issues += "Uncorrected write errors detected" }
            if ($rel.PowerOnHours -ge 50000) { $issues += "Very high power-on hours ($($rel.PowerOnHours))" }
        }

        if ($issues.Count -eq 0) {
            Write-Host "  PASS - No issues detected" -ForegroundColor Green
        } else {
            foreach ($issue in $issues) {
                Write-Host "  WARNING: $issue" -ForegroundColor Red
            }
        }

        Write-Host ""
    }

    # WMI disk status fallback
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host " WMI Disk Status (additional data)" -ForegroundColor White
    Write-Host "============================================================================" -ForegroundColor Cyan
    Write-Host ""

    $wmiDisks = Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue
    foreach ($wd in $wmiDisks) {
        $wmiStatus = $wd.Status
        $sColor = if ($wmiStatus -eq 'OK') { 'Green' } else { 'Red' }
        Write-Host ("  {0,-35} Status: {1}  Interface: {2}" -f $wd.Model, $wmiStatus, $wd.InterfaceType) -ForegroundColor $sColor
    }
    Write-Host ""

    # SMART status via WMI (requires admin)
    if ($isAdmin) {
        $smartData = Get-CimInstance -Namespace 'root\WMI' -ClassName 'MSStorageDriver_FailurePredictStatus' -ErrorAction SilentlyContinue
        if ($smartData) {
            Write-Host "S.M.A.R.T. FAILURE PREDICTION" -ForegroundColor White
            Write-Host "=============================" -ForegroundColor White
            Write-Host ""
            foreach ($s in $smartData) {
                $predicted = $s.PredictFailure
                $reason = $s.Reason
                $pColor = if ($predicted) { 'Red' } else { 'Green' }
                $pText = if ($predicted) { 'YES - FAILURE PREDICTED' } else { 'No - OK' }
                Write-Host "  Predict Failure: $pText" -ForegroundColor $pColor
                if ($predicted -and $reason) {
                    Write-Host "  Reason Code:     $reason" -ForegroundColor Red
                }
            }
            Write-Host ""
        }
    }
}

# ============================================================================
# Export Report
# ============================================================================
function Export-Report {
    param([string]$Path)

    $report = @()

    function Add-Line($text) { $script:report += $text; Write-Host $text }

    Add-Line "============================================================================"
    Add-Line " Storage Reliability Report"
    Add-Line " Computer: $env:COMPUTERNAME"
    Add-Line " Date:     $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Add-Line " Admin:    $isAdmin"
    Add-Line "============================================================================"
    Add-Line ""

    $disks = Get-PhysicalDisk
    foreach ($disk in $disks) {
        $id = $disk.DeviceID
        Add-Line "--- Disk $id - $($disk.FriendlyName) ---"
        Add-Line "  Size:       $([math]::Round($disk.Size / 1GB, 1)) GB"
        Add-Line "  Type:       $($disk.MediaType)"
        Add-Line "  Bus:        $($disk.BusType)"
        Add-Line "  Health:     $($disk.HealthStatus)"
        Add-Line "  Status:     $($disk.OperationalStatus)"
        if ($disk.SerialNumber) { Add-Line "  Serial:     $($disk.SerialNumber.Trim())" }
        if ($disk.FirmwareVersion) { Add-Line "  Firmware:   $($disk.FirmwareVersion)" }

        if ($isAdmin) {
            $rel = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
            if ($rel) {
                if ($rel.Temperature -and $rel.Temperature -gt 0) { Add-Line "  Temperature:    $($rel.Temperature)C" }
                if ($rel.PowerOnHours -and $rel.PowerOnHours -gt 0) {
                    $years = [math]::Round($rel.PowerOnHours / 8760, 1)
                    Add-Line "  Power-On Hours: $($rel.PowerOnHours) ($years years)"
                }
                if ($rel.Wear -ne $null -and $rel.Wear -ge 0) { Add-Line "  Wear:           $($rel.Wear)% used, $(100 - $rel.Wear)% remaining" }
                if ($rel.ReadErrorsTotal -ne $null) { Add-Line "  Read Errors:    $($rel.ReadErrorsTotal)" }
                if ($rel.WriteErrorsTotal -ne $null) { Add-Line "  Write Errors:   $($rel.WriteErrorsTotal)" }
                if ($rel.StartStopCycleCount -and $rel.StartStopCycleCount -gt 0) { Add-Line "  Start/Stop:     $($rel.StartStopCycleCount)" }
            }
        }
        Add-Line ""
    }

    # Volume info
    Add-Line "--- Volume Information ---"
    $vols = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($v in $vols) {
        $totalGB = [math]::Round($v.Size / 1GB, 1)
        $freeGB = [math]::Round($v.FreeSpace / 1GB, 1)
        $freePct = if ($v.Size -gt 0) { [math]::Round(($v.FreeSpace / $v.Size) * 100, 1) } else { 0 }
        Add-Line ("  {0}  {1} GB total, {2} GB free ({3}%)" -f $v.DeviceID, $totalGB, $freeGB, $freePct)
    }
    Add-Line ""

    $report | Out-File -FilePath $Path -Encoding UTF8
    Write-Host ""
    Write-Host "Report saved to: $Path" -ForegroundColor Green
}

# ============================================================================
# Main dispatch
# ============================================================================
switch ($Mode) {
    'Quick'  { Show-QuickOverview }
    'Detail' { Show-DetailedReport }
    'Export' { Export-Report -Path $ReportPath }
}
