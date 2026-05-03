# =====================================================================
# process-history-logger.ps1   (v3 - protected-process fallback +
#                                    per-process creation timestamps +
#                                    UTF-8 without BOM)
#
# Runs as SYSTEM. Subscribes to WMI process-creation events and writes
# every new process to C:\ProgramData\sovereign-shell\process-history.log.
#
# v3 changes:
#   - Static fallback table for protected/kernel-tier processes whose
#     ExecutablePath WMI refuses to return (services.exe, wininit.exe,
#     lsass.exe, smss.exe, etc.). Only triggers when WMI returns empty
#     AND the Name matches a known process - regular processes always
#     have ExecutablePath populated, so name-spoofing malware cannot
#     exploit the fallback.
#   - Snapshot loop uses $p.CreationDate.ToString('o') per process so
#     long-lived boot processes are recorded with their actual birth
#     time, not logger-startup time.
#   - Output written without UTF-8 BOM. Format is now standards-clean
#     and legacy tools like find /C "" work correctly.
# =====================================================================

$ErrorActionPreference = 'Continue'

$LogDir        = 'C:\ProgramData\sovereign-shell'
$LogPath       = Join-Path $LogDir 'process-history.log'
$LogOldPath    = Join-Path $LogDir 'process-history.old.log'
$DiagLogPath   = Join-Path $LogDir 'process-history-logger.log'
$RotateSizeMB  = 20

# UTF-8 encoder that does NOT emit a BOM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Static fallback for kernel/protected processes. WMI returns empty
# ExecutablePath for these even when queried as SYSTEM. Keys are the
# WMI Name field, lowercased. Only consulted when WMI ExecutablePath
# is empty - cannot be exploited by name-spoofing malware because any
# non-protected process has a real ExecutablePath that takes priority.
$ProtectedProcessFallback = @{
    'system idle process' = '<idle>'
    'system'              = '<kernel>'
    'registry'            = '<registry>'
    'memory compression'  = '<memory compression>'
    'secure system'       = '<secure system>'
    'smss.exe'            = 'C:\Windows\System32\smss.exe'
    'csrss.exe'           = 'C:\Windows\System32\csrss.exe'
    'wininit.exe'         = 'C:\Windows\System32\wininit.exe'
    'services.exe'        = 'C:\Windows\System32\services.exe'
    'lsass.exe'           = 'C:\Windows\System32\lsass.exe'
    'winlogon.exe'        = 'C:\Windows\System32\winlogon.exe'
    'fontdrvhost.exe'     = 'C:\Windows\System32\fontdrvhost.exe'
    'dwm.exe'             = 'C:\Windows\System32\dwm.exe'
    'lsaiso.exe'          = 'C:\Windows\System32\LsaIso.exe'
}

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-DiagLog($msg) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts $msg" | Out-File -FilePath $DiagLogPath -Append -Encoding utf8
}

# === Single-instance guard ===
$mutexName  = 'Global\SovereignShellProcessHistoryLogger'
$createdNew = $false
$script:Mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) {
    Write-DiagLog 'Another logger instance is already running. Exiting.'
    exit 0
}

# === Identity check ===
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-DiagLog 'Process history logger v3 starting.'
Write-DiagLog "Running as: $identity"
Write-DiagLog "LogPath: $LogPath"

# === Startup self-test ===
try {
    $stamp = "# self-test $(Get-Date -Format o)`r`n"
    [System.IO.File]::AppendAllText($LogPath, $stamp, $Utf8NoBom)
    Write-DiagLog 'Self-test write succeeded.'
} catch {
    Write-DiagLog "SELF-TEST WRITE FAILED: $($_.Exception.GetType().Name): $($_.Exception.Message)"
    Write-DiagLog 'Aborting.'
    exit 1
}

# === Helpers ===
$script:AppendCount = 0
$script:FailCount   = 0

function Rotate-Log {
    try {
        if (Test-Path $LogOldPath) { Remove-Item $LogOldPath -Force }
        Move-Item -Path $LogPath -Destination $LogOldPath -Force
        Write-DiagLog 'Rotated log to .old.'
    } catch {
        Write-DiagLog "Rotation failed: $_"
    }
}

function Sanitize($s) {
    if (-not $s) { return '' }
    return ($s -replace "`t", ' ' -replace "`r?`n", ' ')
}

function Resolve-ExePath($name, $exePath) {
    if ($exePath) { return $exePath }
    if (-not $name) { return '' }
    $key = $name.ToLower()
    if ($ProtectedProcessFallback.ContainsKey($key)) {
        return $ProtectedProcessFallback[$key]
    }
    return ''
}

function Write-Line($ts, $thisPid, $ppid, $name, $exe, $cmd) {
    $script:AppendCount++
    if (($script:AppendCount % 100) -eq 0 -and (Test-Path $LogPath)) {
        $sz = (Get-Item $LogPath).Length / 1MB
        if ($sz -ge $RotateSizeMB) { Rotate-Log }
    }
    $resolvedExe = Resolve-ExePath $name $exe
    $line = "$ts`t$thisPid`t$ppid`t$(Sanitize $resolvedExe)`t$(Sanitize $cmd)`r`n"
    try {
        [System.IO.File]::AppendAllText($LogPath, $line, $Utf8NoBom)
    } catch {
        $script:FailCount++
        if ($script:FailCount -eq 1 -or ($script:FailCount % 100) -eq 0) {
            Write-DiagLog "Append failed (#$($script:FailCount)/$($script:AppendCount)): $($_.Exception.GetType().Name): $($_.Exception.Message)"
        }
    }
}

# === Snapshot existing processes at startup, per-process timestamps ===
function Snapshot-Existing {
    Write-DiagLog 'Snapshotting existing processes ...'
    try {
        $procs = Get-CimInstance -ClassName Win32_Process `
            -Property ProcessId,ParentProcessId,Name,ExecutablePath,CommandLine,CreationDate `
            -ErrorAction Stop
        $count = 0
        $fallbackNow = Get-Date -Format o
        foreach ($p in $procs) {
            $procTs = if ($null -ne $p.CreationDate) { $p.CreationDate.ToString('o') } else { $fallbackNow }
            Write-Line $procTs $p.ProcessId $p.ParentProcessId $p.Name $p.ExecutablePath $p.CommandLine
            $count++
        }
        $written = $script:AppendCount - $script:FailCount
        Write-DiagLog "Snapshot iterated $count processes; $written lines written, $($script:FailCount) failures."
    } catch {
        Write-DiagLog "Snapshot failed: $_"
    }
}
Snapshot-Existing

# === WMI subscription ===
$query = "SELECT * FROM __InstanceCreationEvent WITHIN 1 WHERE TargetInstance ISA 'Win32_Process'"
try {
    $opt   = New-Object System.Management.ConnectionOptions
    $scope = New-Object System.Management.ManagementScope -ArgumentList '\\.\root\cimv2', $opt
    $scope.Connect()
    $eq      = New-Object System.Management.WqlEventQuery -ArgumentList $query
    $watcher = New-Object System.Management.ManagementEventWatcher -ArgumentList $scope, $eq
    $watcher.Start()
    Write-DiagLog 'WMI subscription active. Listening for process creations.'
} catch {
    Write-DiagLog "WMI subscription failed: $_. Exiting."
    exit 1
}

try {
    while ($true) {
        $evt = $watcher.WaitForNextEvent()
        $p   = $evt['TargetInstance']
        Write-Line (Get-Date -Format o) $p['ProcessId'] $p['ParentProcessId'] $p['Name'] $p['ExecutablePath'] $p['CommandLine']
    }
} finally {
    try { $watcher.Stop() } catch {}
    Write-DiagLog 'Logger exiting.'
}
