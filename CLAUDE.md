# CLAUDE.md

This file provides guidance for AI assistants working with the Bat-Toolbox codebase.

## Project Overview

Bat-Toolbox is a collection of Windows batch scripts and PowerShell utilities for:
- Removing bloatware and pre-installed junk software
- Disabling telemetry and data collection
- Optimizing system performance (storage, interrupt latency, GPU)
- Analyzing running processes, services, and startup programs
- Providing diagnostic and maintenance utilities

**Target Platform:** Windows 10 and Windows 11
**License:** CC0 1.0 Universal (Public Domain)

## Directory Structure

```
/
├── *.bat                    # Root-level scripts (56 main scripts)
├── *.ps1                    # PowerShell helper scripts (6 files)
├── *_README.txt             # Individual documentation per script (56 files)
├── windows-debloat/         # Windows debloat suite (13 numbered scripts 00-12)
├── README.md                # Main documentation
├── CHANGELOG.md             # Version history
├── CONTRIBUTING.md          # Contribution guidelines
├── SECURITY.md              # Security policy
├── AUDIT_REPORT.md          # Software audit findings
├── CLAUDE.md                # AI assistant guidelines
├── .gitignore               # Git ignore rules
└── LICENSE                  # CC0 1.0 Universal
```

## Technologies

- **Primary:** Windows Batch (.bat) - CMD.exe scripting
- **Secondary:** PowerShell (.ps1) - helper scripts
- **No external dependencies** - uses only built-in Windows tools (registry, services, WMI, DISM)

## Running Scripts

No compilation needed. Scripts are run directly:
1. Right-click any `.bat` file
2. Select "Run as administrator" (most scripts require admin)
3. Follow the confirmation prompts

Scripts that do NOT require admin (no admin gate in the script): `Add_RecycleBin_to_NavPane.bat`, `ExportInstalledPrograms.bat`, `FileSorter.bat`, `FirmwareCheck.bat`, `Honeypot.bat`, `ProcessScanner.bat`, `RestoreRecycleBin.bat`, `ScreenSleepGuard.bat`, `StartupAnalyzer.bat`

Scripts with partial admin requirements (they run without admin but warn and offer reduced functionality):
- `BrightnessDiagnostic.bat` - diagnostic features work without admin, but fixes require admin
- `WifiPasswordExporter.bat` - warns when not elevated; some profiles may not reveal passwords
- `ProcessScanner.bat` / `StartupAnalyzer.bat` - analysis works unelevated; termination and removal of system-owned entries need admin

Every other script hard-exits with an error when launched without elevation.

## Code Conventions

### Batch Script Structure

```batch
@echo off
setlocal enabledelayedexpansion
title Script Name
color 0B
chcp 65001 >nul 2>nul

:: Script Name: YourScript.bat
:: Purpose: Brief description

:: Setup colors early (before admin check so errors can be colored)
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "DIM=%ESC%[90m"
set "BOLD=%ESC%[1m"
set "RESET=%ESC%[0m"

:: Admin check (if required)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Requires admin
    pause
    exit /b 1
)

:: Box-drawing header
cls
echo/
echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Script Name%RESET%                                                            %CYAN%║%RESET%
echo   %CYAN%║%RESET%  %DIM%Brief description of what this script does%RESET%                          %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
echo/
title [1/N] Script Name - Current phase...

:: Main logic here

pause
```

### Style Requirements

- **Clear variable names:** `set "processName=notepad.exe"` not `set "pn=notepad.exe"`
- **Color-coded output:**
  - RED = Errors and warnings
  - GREEN = Success messages
  - YELLOW = Information/prompts
  - CYAN = Section headers and box-drawing borders
  - WHITE+BOLD = Headings and emphasis
  - DIM (gray) = Secondary text, descriptions, keyboard shortcuts
- **Comments** for non-obvious logic
- **Delayed expansion** for complex variables: `setlocal enabledelayedexpansion`
- **Errorlevel checking:** Use `if %errorlevel% neq 0` syntax (standardized across codebase)

### Color Implementation Pattern

```batch
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "DIM=%ESC%[90m"
set "BOLD=%ESC%[1m"
set "RESET=%ESC%[0m"
echo %GREEN%[OK] Success%RESET%
```

### Console Visual Effects

Scripts should use these visual polish techniques for a professional look:

**Box-drawing headers** (preferred over plain `====` dividers):
```batch
echo   %CYAN%╔══════════════════════════════════════════════════════════════════════════╗%RESET%
echo   %CYAN%║%RESET%  %BOLD%%WHITE%Section Title%RESET%                                                          %CYAN%║%RESET%
echo   %CYAN%╠══════════════════════════════════════════════════════════════════════════╣%RESET%
echo   %CYAN%║%RESET%  %DIM%-%RESET% Bullet point item                                                   %CYAN%║%RESET%
echo   %CYAN%╚══════════════════════════════════════════════════════════════════════════╝%RESET%
```

**Animated progress dots** (for operations that take a moment):
```batch
<nul set /p "=  %CYAN%[%RESET%%WHITE%*%RESET%%CYAN%]%RESET% Scanning"
for /l %%i in (1,1,3) do (
    <nul set /p "=."
    timeout /t 0 /nobreak >nul
)
echo/
```

**Title bar progress** (shows phase in taskbar):
```batch
title [1/3] Script Name - Scanning...
:: ... after phase 1 ...
title [2/3] Script Name - Processing...
:: ... after phase 2 ...
title [3/3] Script Name - Complete
```

**UTF-8 for box-drawing** - Scripts using Unicode box-drawing characters (`╔═╗║╚╝`) must set UTF-8 code page near the top:
```batch
chcp 65001 >nul 2>nul
```

**Safe blank lines** - Always use `echo/` not `echo.`:
```batch
:: CORRECT - safe everywhere including inside ( ) blocks
echo/

:: WRONG - can fail if a file named "echo" exists in working directory
echo.

:: ALSO WRONG - ( breaks paren-counting inside ( ) > file blocks
echo(
```

### Delayed Expansion and Special Character Escaping

When `setlocal enabledelayedexpansion` is active, `!` characters are consumed by CMD.
Carets are processed twice: first when the line is parsed (only *outside*
double quotes), then again by delayed expansion (inside *and* outside quotes,
on any line that contains a `!`). So the escape depends on quoting, not on
whether the line is inside a block:

```batch
:: Unquoted text (top level or inside any ( ) block): use ^^!
echo Operation complete^^!
if condition (
    echo Warning: Something failed^^!
)

:: Inside double quotes: use ^!   ("...^^!" would print ^ and drop the !)
(
echo     Write-Host "Error detected^!" -ForegroundColor Red
) > "%PSSCRIPT%"

:: Single quotes are NOT quotes to CMD, so PowerShell '...' strings are unquoted
echo     $mark = '[^^!]'
```

### Parentheses Inside Blocks

Inside any parenthesized block (if/else bodies, for bodies, `( ) > file`
generators), an unescaped `)` anywhere on a line closes the block - even in the
middle of `echo` text. Any text after it is a fatal
`... was unexpected at this time` error that aborts the whole script before the
statement runs.

```batch
if condition (
    REM CORRECT
    echo Blocked UDP 5355 %DIM%^(LLMNR^)%RESET%
    REM WRONG - the ")" closes the if block, then "%RESET%" is a fatal error
    echo Blocked UDP 5355 %DIM%(LLMNR)%RESET%
)
(
REM Single quotes do not protect parens from CMD - escape them
echo     'avp' = 'Kaspersky ^(avp.exe^)'
REM Double quotes do protect them
echo     Write-Host "Done (all drives)"
) > "%PSSCRIPT%"
```

- Escape both parens as `^(` `^)` (only `)` is strictly required, but keep them paired)
- A `%VAR%` whose value contains `)` (e.g. `%ProgramFiles(x86)%`, or a path under
  a folder like `Bat-Toolbox (1)`) must be inside double quotes within a block
- Use `REM`, not `::`, for comments inside blocks (labels inside blocks are a
  parsing hazard)

### Line Endings

`.bat` files must be checked out with CRLF line endings; with LF-only files
cmd.exe can fail to find `GOTO`/`CALL` labels. `.gitattributes` enforces this
(`*.bat text eol=crlf`), so the repository stores LF and Git converts on
checkout and in downloaded archives.

### Safety Requirements

1. Check admin privileges at start (if needed)
2. Display what changes will be made
3. Ask for Y/N confirmation before system changes
4. Offer to create restore point
5. Document how to undo changes

## Testing

No automated test framework. Manual testing approach:
- Test on both Windows 10 and Windows 11
- Verify user prompts work correctly
- Verify changes can be reversed
- Ensure no hardcoded paths break functionality

## Key Script Categories

| Category | Scripts | Purpose |
|----------|---------|---------|
| Diagnostic | `StartupAnalyzer.bat`, `ProcessScanner.bat`, `ServiceAnalyzer.bat`, `ScheduledTaskAuditor.bat`, `FirmwareCheck.bat`, `BrightnessDiagnostic.bat`, `DiskHealthCheck.bat` | Analyze system state |
| Performance | `StorageLatencyTuning.bat`, `InterruptLatencyTuning.bat`, `GPUDriverOptimizer.bat` | Optimize system performance |
| Debloat | `RemoveNvidiaBloat.bat`, `RemoveAsusBloat.bat`, `RemoveEOSNotification.bat`, `ContextMenuCleaner.bat`, `windows-debloat/` suite | Remove bloatware |
| Maintenance | `WindowsTweaks.bat`, `NetworkReset.bat`, `RestoreRecycleBin.bat`, `WindowsRepairKit.bat` | Fix issues, customize Windows |
| Utilities | `FileSorter.bat`, `ExportInstalledPrograms.bat`, `WifiPasswordExporter.bat`, `Honeypot.bat`, `ScreenSleepGuard.bat` | Backup, organize, security |

## Documentation Requirements

When adding new scripts:
1. Create a corresponding `*_README.txt` file
2. Update the main `README.md` with an entry
3. Add to the admin requirements summary table in README.md

## Common Commands

```bash
# View all batch scripts
ls *.bat

# View windows-debloat suite
ls windows-debloat/

# Check script documentation
cat <ScriptName>_README.txt
```

## Design Philosophies

1. **Transparency** - All code is plain text, readable by anyone
2. **User Consent** - Always ask before making changes
3. **Reversibility** - Include undo instructions for all modifications
4. **Minimal Scope** - Only modify what's necessary
5. **No External Dependencies** - Use only built-in Windows tools
