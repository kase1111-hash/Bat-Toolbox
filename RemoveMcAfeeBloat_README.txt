================================================================================
 RemoveMcAfeeBloat.bat - Instructions
================================================================================

DESCRIPTION
-----------
Removes all McAfee products (Security, WebAdvisor, LiveSafe, True Key) that
ship preinstalled on Dell, HP, and Lenovo machines. McAfee survives normal
uninstall attempts and requires deep service, registry, and driver cleanup.
Windows Defender is automatically re-enabled after removal.


HOW TO USE
----------
1. Right-click RemoveMcAfeeBloat.bat
2. Select "Run as administrator" (REQUIRED)
3. Confirm when prompted (Y/N)
4. Wait for all phases to complete
5. Restart when prompted (recommended)
6. Open Windows Security to verify Defender is active


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before McAfee Removal"
5. Click Create and wait for completion


WHAT GETS REMOVED
-----------------
- McAfee LiveSafe / Total Protection / AntiVirus Plus
- McAfee WebAdvisor / SiteAdvisor (browser security plugin)
- McAfee True Key (password manager)
- McAfee Personal Security / Privacy
- McAfee kernel filter drivers (mfeavfk, mfefirek, etc.)
- McAfee services and background processes
- McAfee scheduled tasks and startup entries
- McAfee browser extension force-install policies
- McAfee context menu entries (right-click scan)
- McAfee Security Center registration

WHAT STAYS INTACT
-----------------
- Windows Defender / Windows Security (re-enabled automatically)
- Windows Firewall
- All other installed security software
- Browser settings (extensions may need manual removal)


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select your "Before McAfee Removal" restore point
  3. Follow the wizard to restore

Option 2: Reinstall McAfee (if you have a license)
  1. Visit https://www.mcafee.com/consumer/en-us/store/m0/index.html
  2. Sign in with your McAfee account
  3. Download and install the product

Option 3: Use OEM Recovery (Dell/HP/Lenovo)
  1. Check your manufacturer's support page for recovery tools
  2. Note: This may reset other software as well


WHY REMOVE MCAFEE?
------------------
- High CPU and memory usage (often 300-500MB RAM)
- Aggressive popup notifications and upsell prompts
- Slows down boot time significantly
- Browser hijacking (changes default search, installs extensions)
- Difficult to uninstall through normal means (by design)
- Windows Defender provides equivalent protection for free
- Known to conflict with other security software
- Installs kernel filter drivers that persist after "uninstall"
- Trial versions expire and nag for payment


WHAT YOU LOSE
-------------
- McAfee real-time scanning (replaced by Windows Defender)
- McAfee firewall (replaced by Windows Firewall)
- WebAdvisor browser safety ratings
- True Key password manager (export passwords first!)
- McAfee VPN (if included in your plan)

WHAT YOU GAIN
-------------
- Faster boot times (often 10-30 seconds improvement)
- Lower RAM usage (200-500MB freed)
- Lower CPU usage at idle
- No more popup notifications and upsell prompts
- Cleaner browser experience (no forced extensions)
- Windows Defender is lighter and well-integrated with Windows


IMPORTANT: BEFORE REMOVING
--------------------------
1. Export True Key passwords if you use them:
   - Open True Key app
   - Go to Settings > Export
   - Save to a secure location

2. Note any McAfee VPN settings if applicable

3. Ensure Windows Defender definitions are up to date:
   - Open Windows Security
   - Go to Virus & threat protection
   - Click "Check for updates"


NOTES
-----
- Some OEM recovery partitions include McAfee, so it may return after a
  factory reset. Run this script again if that happens.
- Windows Defender will automatically activate after McAfee is removed.
  A reboot may be required for full activation.
- Browser extensions (Chrome/Edge/Firefox) may need manual removal:
  Chrome: chrome://extensions > Remove McAfee WebAdvisor
  Edge: edge://extensions > Remove McAfee WebAdvisor
  Firefox: about:addons > Remove McAfee WebAdvisor
- If Windows Defender does not activate after reboot, open Windows Security
  and click "Turn on" under Virus & threat protection.


TIPS
----
- Run Windows Defender full scan after removal to establish baseline
- Keep Windows Update enabled to receive Defender definition updates
- Consider enabling Windows Defender's built-in ransomware protection:
  Windows Security > Virus & threat protection > Ransomware protection
- If you need a third-party antivirus, consider lightweight alternatives
  like Bitdefender Free or Kaspersky Free
