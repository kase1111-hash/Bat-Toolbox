================================================================================
 remove_store.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables and removes the Microsoft Store and a large set of Store-dependent
bloatware. It applies Store policy kill-switches, disables the silent-install
"content delivery" system (the thing that reinstalls Candy Crush, etc.),
disables Store-related services and scheduled tasks, removes the Store app
package for the current user and all users, and removes a long list of UWP
apps (Xbox, Bing, Zune, Solitaire, promoted junk, Copilot, and more) for the
current user and from the provisioned image (so new accounts do not get them).

*** This is aggressive and removes many built-in apps. Read the removal list
in the script before running and comment out anything you want to keep. ***


HOW TO USE
----------
1. Right-click remove_store.bat and choose "Run as administrator" (REQUIRED).
2. It prints a warning and pauses. Press Ctrl+C to abort, or a key to proceed.
3. It runs 7 phases (Store policy -> content delivery -> services -> tasks ->
   remove Store package -> remove bloatware apps -> block reinstall).
4. Reboot afterward.


WHAT IT DOES (summary)
----------------------
  [1/7] Store policy: RemoveWindowsStore, AutoDownload=2, DisableOSUpgrade
        (DisableStoreApps is intentionally left commented out - see
        BEFORE YOU RUN)
  [2/7] ContentDeliveryManager: disables silent installs, suggested apps,
        subscribed content (many SubscribedContent-* keys)
  [3/7] Sets Start=4 on: PushToInstall, InstallService, WSService, wlidsvc
        (ClipSVC and AppXSvc are intentionally left commented out)
  [4/7] Disables the InstallService scheduled tasks (ScanForUpdates,
        ScanForUpdatesAsUser, SmartRetry). The Windows Update "Scheduled
        Start" task is NOT touched (older versions disabled it).
  [5/7] Removes the Microsoft Store package (current user + provisioned) and
        StorePurchaseApp
  [6/7] Removes UWP apps: Xbox, Bing (News/Weather/Finance/Sports), Zune,
        People/Maps/Messaging, Solitaire/CandyCrush/Disney/Spotify/TikTok/
        Facebook/Instagram/Twitter, Clipchamp/Todos/PowerAutomate, Teams
        (consumer), Feedback Hub/GetHelp/GetStarted, Copilot - for the
        current user. Xbox, Bing, Zune, People/Maps/Messaging, Solitaire,
        Clipchamp/Todos/PowerAutomate, Teams, Feedback Hub/GetHelp/
        GetStarted and Copilot are also deprovisioned
        (Remove-AppxProvisionedPackage) so new accounts do not get them
  [7/7] CloudContent policies (HKLM) to block reinstall + disable
        suggestions; DisableTailoredExperiencesWithDiagnosticData is a
        per-user policy and is written to HKCU


BEFORE YOU RUN
--------------
- Removing the Store makes it hard to install/update UWP apps later. You can
  reinstall it (see undo) but it is fiddly.
- CAUTION on wlidsvc (Microsoft Account Sign-in Assistant): the script
  disables it. If you SIGN IN to Windows with a Microsoft account, this can
  interfere with account sign-in. Comment out that line (Phase 3) if you use
  a Microsoft account.
- The app-removal list is broad. If you use Xbox, Groove, Maps, Clipchamp,
  Teams, etc., comment out those lines first - and also delete the app's name
  from the -match list on the "Deprovisioning" line at the end of phase 6.
- AppXSvc is deliberately NOT disabled (needed to install/update any UWP app).
- ClipSVC (Client License Service) is deliberately NOT disabled: inbox apps
  such as Calculator, Photos, Notepad, Paint, Snipping Tool and Terminal are
  Store-licensed and fail to launch without it.
- DisableStoreApps is deliberately NOT set. WARNING if you uncomment it: on
  Enterprise/Education it blocks ALL Store-serviced apps, including the inbox
  apps above, not just the Store.


HOW TO RESTORE / UNDO
---------------------
Run as Administrator:
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\InstallService" /v Start /t REG_DWORD /d 3 /f
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\PushToInstall"  /v Start /t REG_DWORD /d 3 /f
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\ClipSVC"        /v Start /t REG_DWORD /d 3 /f
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\wlidsvc"        /v Start /t REG_DWORD /d 3 /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /f
  reg delete "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /f
  schtasks /Change /TN "\Microsoft\Windows\InstallService\ScanForUpdates" /Enable
  schtasks /Change /TN "\Microsoft\Windows\InstallService\ScanForUpdatesAsUser" /Enable
  schtasks /Change /TN "\Microsoft\Windows\InstallService\SmartRetry" /Enable
(The ClipSVC line is only needed if an older version of this script disabled
it; use reg add rather than "sc config", which can be access-denied on this
protected service.)

If an older version of this script ran, it also disabled a Windows Update
task - re-enable it:
  schtasks /Change /TN "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Enable

REBOOT (the service Start changes only apply after a restart), then reinstall
the Store (elevated, needs internet):
  wsreset.exe -i
  (wait a few minutes; alternative:
   winget install --id 9WZDNCRFJBMP --source msstore --accept-package-agreements)

NOTE: The script removed the Store for the current user AND deprovisioned it,
so on a single-account PC the package is gone. The old re-register command
  Get-AppxPackage -AllUsers Microsoft.WindowsStore | ForEach-Object {
    Add-AppxPackage -Register "$($_.InstallLocation)\AppxManifest.xml" -DisableDevelopmentMode }
only works if another account still has the Store installed.

Removed UWP apps can be reinstalled from the Store once it is back.


VERIFICATION
------------
- Search Start for "Microsoft Store" - it should not launch.
- List remaining UWP apps: Get-AppxPackage | Select Name | Sort Name
- Check disabled services in services.msc.


TIPS
----
- Run "Get-AppxPackage | Select Name" BEFORE running this if you want a record
  of what you had, so you know what to reinstall.
- If bloatware returns after a feature update, re-run this script.
- Pairs with remove_telemetry.bat for a fuller privacy/debloat pass.
