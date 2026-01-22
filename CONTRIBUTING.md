# Contributing to Bat-Toolbox

Thank you for your interest in contributing to Bat-Toolbox! This project welcomes contributions from everyone.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. **Check existing issues** first to avoid duplicates
2. **Create a new issue** with a clear title and description
3. **Include relevant details:**
   - Windows version (10/11, build number)
   - Which script(s) are affected
   - Steps to reproduce the problem
   - Any error messages you received

### Submitting Changes

1. **Fork the repository** and create a new branch for your changes
2. **Make your changes** following the guidelines below
3. **Test your changes** on Windows 10 and/or Windows 11
4. **Submit a pull request** with a clear description of what you changed and why

## Coding Guidelines

### Script Structure

Every batch script should follow this structure:

```batch
@echo off
setlocal enabledelayedexpansion

:: Script header with purpose
:: ============================================
:: Script Name: YourScript.bat
:: Purpose: Brief description
:: ============================================

:: Admin check (if required)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges.
    pause
    exit /b 1
)

:: Main script logic here

pause
```

### Style Requirements

- **Use clear variable names** - `set "processName=notepad.exe"` not `set "pn=notepad.exe"`
- **Add comments** for non-obvious logic
- **Use color-coded output:**
  - RED: Errors and warnings
  - GREEN: Success messages
  - YELLOW: Information/prompts
  - CYAN: Section headers
- **Always ask for confirmation** before making system changes
- **Provide undo instructions** in the README or inline comments

### Safety Requirements

All scripts that modify the system must:

1. **Check for admin privileges** at the start (if required)
2. **Display what changes will be made** before executing
3. **Ask for user confirmation** (Y/N prompt)
4. **Offer to create a restore point** for registry/system changes
5. **Be reversible** - document how to undo changes

### Documentation Requirements

When adding a new script:

1. **Create a README file** named `ScriptName_README.txt` containing:
   - Purpose
   - What it does (detailed)
   - Usage instructions
   - Admin requirements
   - How to reverse/undo changes

2. **Update the main README.md** with:
   - Entry in the appropriate category table
   - Full documentation section for the script
   - Admin requirements summary table entry

## Testing Checklist

Before submitting a PR, verify:

- [ ] Script runs without errors on Windows 10
- [ ] Script runs without errors on Windows 11 (if applicable)
- [ ] User prompts work correctly
- [ ] Changes can be reversed
- [ ] README documentation is accurate
- [ ] No hardcoded paths that won't work on other systems

## Types of Contributions Needed

### Scripts We'd Love to See

- Additional vendor bloatware removal (Dell, HP, Lenovo, etc.)
- Browser-specific cleanup tools
- More diagnostic/analysis tools
- Privacy-focused tweaks

### Other Ways to Help

- Improve existing documentation
- Test scripts on different Windows versions/editions
- Report bugs or unexpected behavior
- Suggest improvements to existing scripts

## Questions?

If you're unsure about anything, feel free to open an issue and ask. We're happy to help guide new contributors.

## License

By contributing to Bat-Toolbox, you agree that your contributions will be released under the CC0 1.0 Universal (Public Domain) license.
