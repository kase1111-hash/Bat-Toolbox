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
4. If a McAfee uninstall window opens, follow it through to the end
   (the script waits until it closes)
5. Wait for all phases to complete
6. Restart when prompted (recommended)
7. Open Windows Security to verify Defender is active


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
- Stale McAfee entries in Windows Security Center (WMI root\SecurityCenter2)

WHAT STAYS INTACT
-----------------
- Windows Defender / Windows Security (re-enabled automatically)
- Windows Firewall
- All other installed security software
- Browser settings (extensions may need manual removal)


HOW IT WORKS
------------
1. Runs McAfee's own uninstaller for every McAfee product listed in
   Apps & features (LiveSafe / Total Protection, WebAdvisor, True Key, ...).
   MSI-based products are removed silently with msiexec /x; the others open
   McAfee's normal uninstall window. (The old "wmic product" method only saw
   MSI products, so it never removed the McAfee suites - and WMIC is not
   available on Windows 11 24H2 and later.)
2. Checks Apps & features again. If any McAfee product is STILL installed,
   the script lists it and stops WITHOUT running the forced cleanup below,
   because force-deleting the services, drivers, registry keys and files of a
   live, self-protected McAfee install leaves it half-removed and breaks its
   own uninstaller. Restart if McAfee asked you to, or remove it via
   Settings > Apps or McAfee's MCPR tool, then run the script again.
3. Only when no McAfee product is installed any more: removes McAfee Store
   apps, stops/disables/deletes leftover services and kernel drivers, removes
   scheduled tasks, startup entries, registry keys, browser policies, context
   menu handlers and leftover folders.
4. Re-enables Windows Defender and reports whether Defender is actually
   active. Services that cannot be disabled (access denied) are shown in red
   instead of being reported as disabled.


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
- If Windows Security still lists McAfee as your antivirus after the
  restart, or the script stops because McAfee is still installed and its
  uninstaller fails, use McAfee's official removal tool (MCPR - "McAfee
  Consumer Product Removal"), available from McAfee's support site.


TIPS
----
- Run Windows Defender full scan after removal to establish baseline
- Keep Windows Update enabled to receive Defender definition updates
- Consider enabling Windows Defender's built-in ransomware protection:
  Windows Security > Virus & threat protection > Ransomware protection
- If you need a third-party antivirus, consider lightweight alternatives
  like Bitdefender Free or Kaspersky Free
