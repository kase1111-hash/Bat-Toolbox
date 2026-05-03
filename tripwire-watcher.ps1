# =====================================================================
# tripwire-watcher.ps1   (v3 - dedup + summarizer + enrichment)
#
# User-session sidecar for sovereign-shell tripwire.
#
# v3 adds forensic enrichment: every tripwire event has its full
# ancestry chain resolved against process-history.log, with the
# (access denied) and (exited before we could read it) slots filled
# in with actual exe paths and command lines. Output goes to
# enriched-events.jsonl alongside the existing watcher.log and
# fingerprints.json.
#
# Enrichment is additive: it does not affect fingerprinting or toast
# logic. If process-history.log is missing or stale, records still
# get written, just with "enriched": null for unreachable entries.
#
# Runs under PowerShell 5.1 (Windows PowerShell). Keep on powershell.exe,
# not pwsh.exe - WinRT loading differs on PS7+.
# =====================================================================

$ErrorActionPreference = 'Continue'

# === Paths and tunables ===
$LogPath              = 'C:\ProgramData\sovereign-shell\tripwire.log'
$ProcHistoryPath      = 'C:\ProgramData\sovereign-shell\process-history.log'
$ProcHistoryOldPath   = 'C:\ProgramData\sovereign-shell\process-history.old.log'
$StateDir             = Join-Path $env:LOCALAPPDATA 'sovereign-shell'
$CursorPath           = Join-Path $StateDir 'tripwire.log.cursor'
$WatcherLog           = Join-Path $StateDir 'watcher.log'
$FingerprintsPath     = Join-Path $StateDir 'fingerprints.json'
$EnrichedPath         = Join-Path $StateDir 'enriched-events.jsonl'
$Separator            = '=== Tripwire activated ==='
$AppId                = 'SovereignShell.Tripwire'
$PollSec              = 5
$RollupCheckSec       = 60
$SummaryIntervalHours = 24
$ResurrectionDays     = 7
$ReplayN              = 3

if (-not (Test-Path $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
}

function Write-WatcherLog($msg) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts $msg" | Out-File -FilePath $WatcherLog -Append -Encoding utf8
}

# === Single-instance guard ===
$mutexName  = 'Global\SovereignShellTripwireWatcher'
$createdNew = $false
$script:Mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) {
    Write-WatcherLog 'Another watcher instance is already running. Exiting.'
    exit 0
}
Write-WatcherLog "Watcher v3 starting. Log=$LogPath"

# === WinRT toast plumbing ===
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.UI.Notifications.ToastNotification,        Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument,                  Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

function Show-Toast($title, $line1, $line2) {
    $esc = [System.Security.SecurityElement]
    $xml = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$($esc::Escape($title))</text>
      <text>$($esc::Escape($line1))</text>
      <text>$($esc::Escape($line2))</text>
    </binding>
  </visual>
</toast>
"@
    try {
        $doc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $doc.LoadXml($xml)
        $toast    = [Windows.UI.Notifications.ToastNotification]::new($doc)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId)
        $notifier.Show($toast)
    } catch {
        Write-WatcherLog "Toast failed: $_"
    }
}

# === Fingerprint helpers ===

function Canonicalize-Args($s) {
    if (-not $s) { return '' }
    $c = $s -replace '\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b', '<GUID>'
    $c = $c -replace '\b\d{6,}\b', '<NUM>'
    return $c
}

function Compute-Fingerprint($evt) {
    $canonArgs = Canonicalize-Args $evt.Args
    $canon  = "$($evt.Spoofed)|$($evt.User)|$($evt.Session)|$($evt.ParentChain)|$canonArgs"
    $bytes  = [System.Text.Encoding]::UTF8.GetBytes($canon)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash   = $sha256.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($hash) -replace '-','').ToLower().Substring(0,16)
}

function ConvertTo-Hashtable($obj) {
    if ($null -eq $obj) { return $null }
    if ($obj -is [System.Management.Automation.PSCustomObject]) {
        $h = @{}
        foreach ($p in $obj.PSObject.Properties) {
            $h[$p.Name] = ConvertTo-Hashtable $p.Value
        }
        return $h
    }
    if ($obj -is [System.Collections.IList] -and -not ($obj -is [string])) {
        return @($obj | ForEach-Object { ConvertTo-Hashtable $_ })
    }
    return $obj
}

function Load-Fingerprints {
    if (-not (Test-Path $FingerprintsPath)) {
        return @{ version = 1; fingerprints = @{} }
    }
    try {
        $raw = Get-Content -Raw $FingerprintsPath -ErrorAction Stop
        $obj = $raw | ConvertFrom-Json
        $store = ConvertTo-Hashtable $obj
        if (-not $store.fingerprints) { $store.fingerprints = @{} }
        return $store
    } catch {
        Write-WatcherLog "Fingerprint load failed ($_). Starting fresh."
        return @{ version = 1; fingerprints = @{} }
    }
}

function Save-Fingerprints($store) {
    try {
        $store | ConvertTo-Json -Depth 10 | Out-File -FilePath $FingerprintsPath -Encoding utf8
    } catch {
        Write-WatcherLog "Fingerprint save failed: $_"
    }
}

# === Process-history lookup for enrichment ===

# For a list of PIDs, scan process-history (current and .old) and return
# a hashtable mapping PID -> @{Time;PID;PPID;Exe;Cmd} for the most recent
# entry whose timestamp is at or before $eventTimeStr.
function Resolve-Pids($pidsToResolve, $eventTimeStr) {
    $results = @{}
    foreach ($p in $pidsToResolve) { $results[$p] = $null }
    if ($pidsToResolve.Count -eq 0) { return $results }

    $eventDt = $null
    try { $eventDt = [DateTime]::ParseExact($eventTimeStr, 'yyyy-MM-dd HH:mm:ss', $null) } catch {}

    foreach ($file in @($ProcHistoryPath, $ProcHistoryOldPath)) {
        if (-not (Test-Path $file)) { continue }
        $lines = $null
        try { $lines = [System.IO.File]::ReadAllLines($file, [System.Text.Encoding]::UTF8) } catch { continue }
        foreach ($line in $lines) {
            if (-not $line -or $line.StartsWith('#')) { continue }   # skip self-test markers
            $parts = $line -split "`t"
            if ($parts.Count -lt 5) { continue }
            $entryPid = 0
            if (-not [int]::TryParse($parts[1], [ref]$entryPid)) { continue }
            if (-not $results.ContainsKey($entryPid)) { continue }

            $entryDt = $null
            try { $entryDt = [DateTime]::Parse($parts[0]) } catch { continue }

            # Reject entries newer than the event time (PID reuse protection).
            if ($eventDt -and $entryDt -gt $eventDt) { continue }

            $existing = $results[$entryPid]
            if ($null -eq $existing -or $entryDt -gt $existing.Time) {
                $entryPpid = 0
                [void][int]::TryParse($parts[2], [ref]$entryPpid)
                $results[$entryPid] = @{
                    Time = $entryDt
                    PID  = $entryPid
                    PPID = $entryPpid
                    Exe  = $parts[3]
                    Cmd  = $parts[4]
                }
            }
        }
    }
    return $results
}

# Build a structured forensic record from a parsed event + fingerprint.
# For each ancestry slot whose status isn't 'resolved', try to fill in
# enrichment data from process-history.
function Build-EnrichedRecord($evt, $fingerprint) {
    $pidsToResolve = @()
    foreach ($a in $evt.AncestryEntries) {
        if ($a.Status -ne 'resolved') { $pidsToResolve += [int]$a.PID }
    }
    $resolution = Resolve-Pids $pidsToResolve $evt.Time

    $ancestry = @()
    foreach ($a in $evt.AncestryEntries) {
        $rec = [ordered]@{
            depth    = $a.Depth
            pid      = $a.PID
            name     = $a.Name
            status   = $a.Status
            path     = $a.Path
            enriched = $null
        }
        if ($a.Status -ne 'resolved') {
            $hist = $resolution[[int]$a.PID]
            if ($hist) {
                $rec.enriched = [ordered]@{
                    exe          = $hist.Exe
                    cmd          = $hist.Cmd
                    ppid         = $hist.PPID
                    history_time = $hist.Time.ToString('o')
                }
            }
        }
        $ancestry += $rec
    }

    return [ordered]@{
        event_time   = $evt.Time
        spoofed      = $evt.Spoofed
        spoofed_path = $evt.SpoofedPath
        pid          = $evt.PID
        user         = $evt.User
        session      = $evt.Session
        args         = $evt.Args
        fingerprint  = $fingerprint
        ancestry     = $ancestry
    }
}

function Append-Enriched($record) {
    try {
        $json = ($record | ConvertTo-Json -Depth 10 -Compress)
        [System.IO.File]::AppendAllText($EnrichedPath, $json + "`r`n", [System.Text.Encoding]::UTF8)
    } catch {
        Write-WatcherLog "Enriched append failed: $_"
    }
}

# === Event parsing (full ancestry) ===
function Parse-Event($block) {
    $h = @{
        Time=''; SpoofedPath=''; Spoofed=''; PID=''
        User=''; Session=''; Args=''
        Parent=''; ParentChain=''
        AncestryEntries = @()
    }
    $inAncestry  = $false
    $current     = $null
    foreach ($line in ($block -split "`r?`n")) {
        if ($line -match '^Time:\s+(.+)$')        { $h.Time        = $matches[1].Trim(); continue }
        if ($line -match '^Spoofed:\s+(.+)$')     {
            $h.SpoofedPath = $matches[1].Trim()
            $h.Spoofed     = Split-Path -Leaf $h.SpoofedPath
            continue
        }
        if ($line -match '^PID:\s+(.+)$')         { $h.PID     = $matches[1].Trim(); continue }
        if ($line -match '^User:\s+(.+)$')        { $h.User    = $matches[1].Trim(); continue }
        if ($line -match '^Session:\s+(.+)$')     { $h.Session = $matches[1].Trim(); continue }
        if ($line -match '^Args:\s+(.+)$')        { $h.Args    = $matches[1].Trim(); continue }
        if ($line -match '^---\s*Process ancestry') { $inAncestry = $true; continue }

        if ($inAncestry) {
            # Depth/PID/name line: "  N. PID NNNN    rest"
            if ($line -match '^\s+(\d+)\.\s+PID\s+(\d+)\s+(.+)$') {
                if ($current) { $h.AncestryEntries += $current }
                $depth  = [int]$matches[1]
                $pidVal = [int]$matches[2]
                $rest   = $matches[3].Trim()
                if ($rest -match '^\(exited') {
                    $current = @{ Depth=$depth; PID=$pidVal; Name=''; Status='exited'; Path='' }
                } else {
                    $current = @{ Depth=$depth; PID=$pidVal; Name=$rest; Status='resolved'; Path='' }
                }
                continue
            }
            # Path/status follow-on line
            if ($current -and $line -match '^\s+(.+)$') {
                $payload = $matches[1].Trim()
                if ($payload -eq '(access denied)') {
                    $current.Status = 'access denied'
                } elseif ($payload -eq '?') {
                    # exited case - already marked
                } else {
                    $current.Path = $payload
                }
            }
        }
    }
    if ($current) { $h.AncestryEntries += $current }

    if ($h.AncestryEntries.Count -gt 0) {
        $h.Parent      = $h.AncestryEntries[0].Name
        $h.ParentChain = (($h.AncestryEntries | ForEach-Object { $_.Name }) -join ' -> ')
    }
    return $h
}

# === Decision: handle one freshly-read event. Returns the fingerprint. ===
function Process-Event($evt, $store, [bool]$silent) {
    $fp     = Compute-Fingerprint $evt
    $now    = Get-Date
    $nowStr = $now.ToString('yyyy-MM-dd HH:mm:ss')
    $rec    = $store.fingerprints[$fp]

    if ($null -eq $rec) {
        $rec = @{
            spoofed              = $evt.Spoofed
            spoofed_path         = $evt.SpoofedPath
            user                 = $evt.User
            session              = $evt.Session
            parent_chain         = $evt.ParentChain
            args_canonical       = Canonicalize-Args $evt.Args
            first_seen           = $evt.Time
            last_seen            = $evt.Time
            count                = 1
            count_at_last_summary= 1
            last_summary_toast   = $nowStr
        }
        $store.fingerprints[$fp] = $rec
        if (-not $silent) {
            Show-Toast 'Tripwire (NEW)' `
                "$($evt.Spoofed)  -  $($evt.User)" `
                "$($evt.Time)  via $($evt.Parent)"
            Write-WatcherLog "NEW fingerprint $fp ($($evt.Spoofed))"
        }
        return $fp
    }

    $rec.count    = $rec.count + 1
    $prevLastSeen = $rec.last_seen
    $rec.last_seen = $evt.Time

    if (-not $silent) {
        try {
            $prevDt = [DateTime]::ParseExact($prevLastSeen, 'yyyy-MM-dd HH:mm:ss', $null)
            $gap    = $now - $prevDt
            if ($gap.TotalDays -ge $ResurrectionDays) {
                Show-Toast "Tripwire (returned after $([int]$gap.TotalDays)d)" `
                    "$($evt.Spoofed)  -  $($evt.User)" `
                    "$($evt.Time)  via $($evt.Parent)"
                Write-WatcherLog "RETURNED fingerprint $fp after $([int]$gap.TotalDays)d"
            } else {
                Write-WatcherLog "Silent: $fp ($($evt.Spoofed)) count=$($rec.count)"
            }
        } catch {}
    }
    return $fp
}

function Check-Rollup($store) {
    $now = Get-Date
    $changed = $false
    foreach ($fp in @($store.fingerprints.Keys)) {
        $rec = $store.fingerprints[$fp]
        $newSinceSummary = $rec.count - $rec.count_at_last_summary
        if ($newSinceSummary -le 0) { continue }
        try {
            $lastSum = [DateTime]::ParseExact($rec.last_summary_toast, 'yyyy-MM-dd HH:mm:ss', $null)
            if (((Get-Date) - $lastSum).TotalHours -lt $SummaryIntervalHours) { continue }
        } catch { continue }

        Show-Toast 'Tripwire summary' `
            "$($rec.spoofed)  -  $newSinceSummary new firings" `
            "Total $($rec.count) since $($rec.first_seen). Same fingerprint."
        Write-WatcherLog "SUMMARY $fp ($($rec.spoofed)) +$newSinceSummary (total=$($rec.count))"

        $rec.count_at_last_summary = $rec.count
        $rec.last_summary_toast    = $now.ToString('yyyy-MM-dd HH:mm:ss')
        $changed = $true
    }
    if ($changed) { Save-Fingerprints $store }
}

function Read-NewEvents([long]$fromOffset) {
    if (-not (Test-Path $LogPath)) { return ,@(@(), $fromOffset) }
    $size = (Get-Item $LogPath).Length
    if ($size -lt $fromOffset) {
        Write-WatcherLog "Log shrank ($fromOffset -> $size). Cursor reset."
        $fromOffset = 0
    }
    if ($size -eq $fromOffset) { return ,@(@(), $size) }

    $events = @()
    try {
        $stream = [System.IO.File]::Open($LogPath, 'Open', 'Read', 'ReadWrite')
        $stream.Seek($fromOffset, 'Begin') | Out-Null
        $reader  = New-Object System.IO.StreamReader($stream)
        $newText = $reader.ReadToEnd()
        $reader.Close()
        $stream.Close()
        foreach ($c in ($newText -split [regex]::Escape($Separator))) {
            if ($c.Trim() -ne '') { $events += $c }
        }
    } catch {
        Write-WatcherLog "Read failed: $_"
        return ,@(@(), $fromOffset)
    }
    return ,@($events, $size)
}

function Bootstrap-Store($store) {
    if (-not (Test-Path $LogPath)) { return 0 }
    $all     = Get-Content -Raw $LogPath
    $chunks  = $all -split [regex]::Escape($Separator) | Where-Object { $_.Trim() -ne '' }
    foreach ($c in $chunks) {
        $evt = Parse-Event $c
        $fp  = Process-Event $evt $store $true
        $enriched = Build-EnrichedRecord $evt $fp
        Append-Enriched $enriched
    }
    Write-WatcherLog "Bootstrap registered $($chunks.Count) historical events into $($store.fingerprints.Count) fingerprints."
    return $chunks.Count
}

# === Main ===
$store = Load-Fingerprints

$cursor = 0
if (Test-Path $CursorPath) {
    $cursor = [long](Get-Content $CursorPath -ErrorAction SilentlyContinue)
    Write-WatcherLog "Resuming from cursor $cursor"
} else {
    Write-WatcherLog "First run - bootstrapping from full log."
    [void](Bootstrap-Store $store)
    Save-Fingerprints $store

    if (Test-Path $LogPath) {
        $all    = Get-Content -Raw $LogPath
        $chunks = $all -split [regex]::Escape($Separator) | Where-Object { $_.Trim() -ne '' }
        $tail   = if ($chunks.Count -ge $ReplayN) { $chunks[-$ReplayN..-1] } else { $chunks }
        foreach ($c in $tail) {
            $evt = Parse-Event $c
            Show-Toast 'Tripwire (replay)' `
                "$($evt.Spoofed)  -  $($evt.User)" `
                "$($evt.Time)  via $($evt.Parent)"
            Start-Sleep -Milliseconds 600
        }
        $cursor = (Get-Item $LogPath).Length
    }
    Set-Content -Path $CursorPath -Value $cursor -Encoding ascii
}

$lastRollup = Get-Date
while ($true) {
    Start-Sleep -Seconds $PollSec

    $result = Read-NewEvents $cursor
    $events = $result[0]
    $cursor = $result[1]
    if ($events -and $events.Count -gt 0) {
        foreach ($c in $events) {
            $evt = Parse-Event $c
            $fp  = Process-Event $evt $store $false
            $enriched = Build-EnrichedRecord $evt $fp
            Append-Enriched $enriched
        }
        Save-Fingerprints $store
        Set-Content -Path $CursorPath -Value $cursor -Encoding ascii
    }

    if (((Get-Date) - $lastRollup).TotalSeconds -ge $RollupCheckSec) {
        Check-Rollup $store
        $lastRollup = Get-Date
    }
}
