# Changelog

All notable changes to Bat-Toolbox are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- CONTRIBUTING.md with contribution guidelines
- CHANGELOG.md for version history
- SECURITY.md with security policy
- .gitignore file

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
