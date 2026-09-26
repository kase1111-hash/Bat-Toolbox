# Changelog

All notable changes to Bat-Toolbox are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

A full review of every script (235 verified functional bugs: 7 critical, 43 high, 129 medium, 56 low), plus a check of every `.bat` against a simulator of cmd.exe's parser. Per-script details are in each `*_README.txt`.

### Added
- CONTRIBUTING.md with contribution guidelines
- CHANGELOG.md for version history
- SECURITY.md with security policy
- .gitignore file
- `.gitattributes` forcing CRLF line endings for `*.bat` / `*.cmd` on checkout and in GitHub ZIP downloads (65 of 66 scripts were LF-only, which makes cmd's GOTO/CALL label search unreliable)
- ScheduledTaskAuditor: UNKNOWN category for unrecognized tasks outside `\Microsoft\Windows\` (listed for review, never disabled)
- WindowsTweaks: each category shows what it will change and asks Y/N first; hibernation added to the Performance tweaks; saved folder views are backed up to a .reg file before they are reset

### Changed
- WMIC removed (disabled by default on Windows 11 24H2, removed in 25H2): FirmwareCheck, DriverBackupRestore and PagefileTuner query CIM through PowerShell (PagefileTuner keeps its registry fallback)
- WMIC removed from RemoveAsusBloat, RemoveMcAfeeBloat and RemoveRealtekBloat: MSI products are uninstalled with `msiexec /x <ProductCode>` from the registry uninstall list (no slow Win32_Product enumeration or MSI self-repair); RemoveNvidiaBloat runs GeForce Experience's registered uninstaller instead
- RemoveMcAfeeBloat runs McAfee's own registered uninstallers first and stops before the forced cleanup if a McAfee product is still installed
- StartupAnalyzer disables REMOVE items through the StartupApproved keys, as Task Manager does (re-enable them there), instead of deleting Run values and shortcuts
- MemoryDiagnostic compares the configured RAM speed with the module maximum instead of claiming to detect XMP/DOCP; option [4] opens the mdsched.exe dialog
- BatteryChargeLimit: Surface shows the Surface UEFI / Surface app steps (the registry values it wrote did nothing and are now deleted); vendor registry fallbacks write only to existing keys and report UNVERIFIED; 50% becomes 60% on ASUS and 55% on Dell
- WindowsRepairKit runs DISM /ScanHealth first and /RestoreHealth only when the store is not clean
- RAMDiskCreator: the VHDX fallback lives in `%USERPROFILE%\AppData\Local\RAMDiskCreator` and is described as disk-backed; option [4] removes only RAMDisk-labelled volumes
- DisableNetBIOS also sets `NetbiosOptions = 2` on every NetBT interface, covering disconnected adapters
- DisableLLMNR no longer touches the WinHTTP Auto-Proxy service (`DisableWpad = 1` already covers WinHTTP WPAD)
- Honeypot schedules the shutdown with a 30-second timer, so `shutdown /a` can cancel it
- Root README: admin table lists ProcessScanner, StartupAnalyzer and WifiPasswordExporter as Partial; script sections updated to match the fixes below

### Fixed

#### Crashes and parse errors
- Fatal cmd parse errors ("... was unexpected at this time") in ~20 scripts: an unescaped `)` inside a `( )` block - in echo text, an unquoted `(x86)` path or an app name - closed the block and aborted the script (the ASUS/McAfee/Realtek/NVIDIA removers stopped mid-removal)
- Generated PowerShell corrupted by literal `^` carets inside quoted strings in 19 scripts (AudioDeviceAnalyzer's endpoint list always empty, ProcessScanner's kills failing while it printed "terminated", StartupAnalyzer's removal doing nothing, garbled report lines)
- DiskHealthCheck's generated PowerShell was rejected by the parser (`"DISK $diskIndex:"`)
- `!` in output under delayed expansion: `^!` / `^^!` escaping corrected so exclamation marks print instead of vanishing
- `::` comments inside blocks replaced with `REM`; install-process-history-logger and install-tripwire-watcher no longer abort when run from a folder such as "Bat-Toolbox (1)"

#### Prompts
- `set /p` answers are cleared before every prompt (100+ places), so pressing Enter no longer re-uses an earlier "Y" or menu choice, and an empty answer takes the safe path
- 12-Interactive-Remover: CHOICE was never cleared (Enter could remove the Store) and the default was inverted (Enter removed the items marked as breaking)

#### Data loss and over-broad changes
- 09-Uninstall-OneDrive: `rd /s /q %UserProfile%\OneDrive` deleted Desktop/Documents/Pictures under OneDrive folder backup; the folder is now removed only when empty
- RecentActivityCleaner deleted Quick Access pins and unsaved Windows 11 Notepad tabs (Notepad tabs now only after a Y/N prompt, with Notepad closed)
- FileSorter flattened the whole subfolder tree; it now sorts only the files directly in its folder
- RemoveAsusBloat touched Armoury Crate and Fn-hotkey components even when told to keep them; `ROG`/`AURA` patterns matched unrelated programs ("Program...", "Progress...")
- RemoveNvidiaBloat force-deleted GeForce Experience when its uninstaller was not found
- remove_telemetry, remove_backup and remove_store disabled far more than described (Application Compatibility Engine, all of OneDrive, ClipSVC)

#### Settings that did the wrong thing
- PowerPlanOptimizer: minute values were written to timeouts that take seconds (display, disk and sleep turned off after seconds)
- BrightnessDiagnostic: Quick Fix set a 100-second dim timeout instead of 100% dimmed brightness, and "Disable DPST" left DPST on; Quick Fix now backs up the original values and Reset restores them
- HardenPrintSpooler option 2 set the Spooler to Manual, so printing broke after a reboot (it now stays on Automatic)
- ContextMenuCleaner wrote `LegacyDisable` for shell-extension handlers, which Explorer ignores (they now go on the `Shell Extensions\Blocked` list)
- Add_RecycleBin_to_NavPane used the wrong registry mechanism (now `System.IsPinnedToNameSpaceTree`)
- GPUDriverOptimizer wrote NVIDIA values to display adapter key `0000` regardless of where the NVIDIA GPU is
- DriverBackupRestore: restore never installed anything (FOR /R does not expand a `!delayed!` root folder)

#### Wrong results and reports
- WindowsRepairKit: SFC output is UTF-16, so every status was UNKNOWN; DISM reported "repaired" for healthy stores
- PasswordPolicyAudit: the secedit export is UTF-16 (findstr could not read it), and console output leaked into the report
- StartupAnalyzer truncated value names containing spaces
- WifiPasswordExporter: English-only parsing, and passwords containing `:` or `!` were truncated or mangled
- ProcessScanner, StartupAnalyzer, OpenPortScanner, ScheduledTaskAuditor, DiskHealthCheck and AudioDeviceAnalyzer: logic errors in the generated PowerShell
- Reports go to the real Desktop, including a OneDrive-redirected one, in BrightnessDiagnostic, DiskHealthCheck, ExportInstalledPrograms, FirmwareCheck, OpenPortScanner, ScheduledTaskAuditor, StorageReliabilityCounter, WifiPasswordExporter and WindowsRepairKit
- 07-Block-Telemetry-Hosts detects Defender resetting the hosts file (HostsFileHijack)
- Medium/low fixes across the toolbox: English-only output parsing, undo steps that did not restore the original state, success printed regardless of the result, and "Ctrl+C to cancel" restarts that could not be cancelled

## [1.0.0] - 2026-01

### Added

#### Diagnostic Tools
- **BrightnessDiagnostic.bat** - Screen brightness diagnostics with gamma boost feature
- **FirmwareCheck.bat** - Firmware and driver version checker with search-ready strings
- **StartupAnalyzer.bat** - Startup program analyzer with categorization (keep/optional/remove)
- **ProcessScanner.bat** - Running process scanner for bloatware detection
- **ServiceAnalyzer.bat** - Windows service analyzer for unnecessary automatic services

#### Performance Optimization
- **StorageLatencyTuning.bat** - NVMe/SSD storage latency tuning script
- **InterruptLatencyTuning.bat** - Interrupt and DPC latency tuning script
- **GPUDriverOptimizer.bat** - GPU driver optimizer with profile selection (Competitive/Balanced/Quality/Power Efficient)

#### Bloatware Removal
- **RemoveNvidiaBloat.bat** - NVIDIA bloatware removal (GeForce Experience, telemetry)
- **RemoveAsusBloat.bat** - ASUS bloatware removal script (MyASUS, Armoury Crate, etc.)
- **RemoveEOSNotification.bat** - Windows 10 End of Support notification removal

#### Windows Debloat Suite (`windows-debloat/`)
- **00-Create-Restore-Point.bat** - System restore point creation
- **01-Remove-Bloatware.bat** - Pre-installed Windows app removal
- **02-Disable-Services.bat** - Unnecessary service disabling
- **03-Disable-Tasks.bat** - Telemetry task disabling
- **04-Registry-Privacy.bat** - Privacy-focused registry tweaks
- **05-Registry-Performance.bat** - Performance registry tweaks
- **06-Remove-Features.bat** - Optional Windows feature removal
- **07-Block-Telemetry-Hosts.bat** - Telemetry domain blocking via hosts file
- **08-Firewall-Rules.bat** - Telemetry executable firewall rules
- **09-Uninstall-OneDrive.bat** - Complete OneDrive removal
- **10-Performance-Tweaks.bat** - System performance optimizations
- **11-Cleanup-Temp-Cache.bat** - Temp files and browser cache cleanup
- **12-Interactive-Remover.bat** - Guided interactive removal with Y/N prompts

#### Utilities
- **WindowsTweaks.bat** - Interactive menu for advanced Windows customizations
- **NetworkReset.bat** - Complete network stack reset
- **RestoreRecycleBin.bat** - Recycle Bin icon restoration
- **FileSorter.bat** - Automatic file organization by extension
- **ExportInstalledPrograms.bat** - Installed program list export with winget JSON
- **Honeypot.bat** - Security decoy with intruder logging
- **ScreenSleepGuard.bat** - Monitor lock with key-based unlock

#### Documentation
- Comprehensive README.md with full script documentation
- Individual README files for each script (`*_README.txt`)
- Windows debloat suite documentation (`windows-debloat/README.md`)
- CC0 1.0 Universal License

### Fixed
- Fixed StorageLatencyTuning.bat crash with unescaped parentheses
- Fixed InterruptLatencyTuning.bat crash with unescaped special characters
- Fixed GPU optimizer crash caused by unescaped parentheses
- Refactored brightness tool to use separate PowerShell helper for reliability

## Project History

This project started as a collection of personal Windows optimization scripts and grew into a comprehensive toolbox for debloating, optimizing, and maintaining Windows systems. All scripts prioritize transparency (readable code), safety (confirmation prompts), and reversibility (documented undo procedures).
