# Security Policy

## About This Project

Bat-Toolbox contains scripts that modify Windows system settings, registry entries, and services. These scripts require elevated (Administrator) privileges and make changes that affect system behavior. **Always review scripts before running them.**

## Reporting Security Issues

If you discover a security vulnerability in Bat-Toolbox, please report it by:

1. **Opening a GitHub issue** with the label "security"
2. **Including:**
   - Description of the vulnerability
   - Which script(s) are affected
   - Steps to reproduce
   - Potential impact

Since this project is open source and the scripts are meant to be readable, we handle security issues transparently rather than through private disclosure.

## Security Design Principles

### Transparency

- All scripts are plain text batch files - you can read every line
- No obfuscated code, no compiled binaries, no external downloads
- Scripts explain what they do before executing

### User Consent

- Scripts ask for confirmation before making changes
- Dangerous operations require explicit Y/N approval
- Users can review changes before applying them

### Reversibility

- Each script includes undo/reversal instructions
- System restore point creation is offered before major changes
- Most changes set services to "manual" rather than "disabled"

### Minimal Scope

- Scripts only modify what's necessary for their stated purpose
- No unnecessary data collection or telemetry
- No network connections or external dependencies

## Safe Usage Guidelines

### Before Running Any Script

1. **Read the script** - Open it in a text editor and review what it does
2. **Read the README** - Each script has documentation explaining its effects
3. **Create a restore point** - Use `windows-debloat/00-Create-Restore-Point.bat` or Windows Settings
4. **Run as Administrator** - Right-click > "Run as administrator"

### Scripts That Require Extra Caution

| Script | Risk Level | Reason |
|--------|------------|--------|
| `windows-debloat/*.bat` | Medium | Modifies many system settings and services |
| `InterruptLatencyTuning.bat` | Medium | Changes kernel-level timer and interrupt settings |
| `StorageLatencyTuning.bat` | Low-Medium | Modifies storage power management |
| `RemoveNvidiaBloat.bat` | Low | Uninstalls software and modifies services |
| `RemoveAsusBloat.bat` | Low | Uninstalls software and modifies services |
| `Honeypot.bat` | Low | Will shut down your computer when triggered |

### If Something Goes Wrong

1. **Use System Restore** to revert to a previous state
2. **Boot into Safe Mode** if Windows won't start normally
3. **Check the script's README** for specific reversal instructions
4. **Open an issue** if you believe there's a bug in a script

## Known Limitations

### Not Malware Protection

These scripts do not:
- Detect or remove malware
- Provide real-time protection
- Replace antivirus software

### System Requirements

- Designed for Windows 10 and Windows 11
- Some features may not work on older Windows versions
- Server editions are not tested or supported

### Third-Party Software

Scripts that remove vendor bloatware (NVIDIA, ASUS) may:
- Break vendor-specific features (RGB lighting, fan control)
- Require manual driver reinstallation
- Need to be re-run after driver updates

## Verification

To verify you have authentic Bat-Toolbox scripts:

1. Download only from the official GitHub repository
2. Check file hashes if provided in releases
3. Review the code yourself before running

## Disclaimer

These scripts are provided "as-is" without warranty. By running these scripts, you accept responsibility for any changes made to your system. Always:

- Back up important data before making system changes
- Create a system restore point
- Understand what each script does before running it

## Contact

For security concerns, open an issue on GitHub with the "security" label.
