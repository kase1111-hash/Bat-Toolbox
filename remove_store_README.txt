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
apps (Xbox, Bing, Zune, Solitaire, promoted junk, Copilot, and more).

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
  [1/7] Store policy: RemoveWindowsStore, DisableStoreApps, AutoDownload=2,
        DisableOSUpgrade
  [2/7] ContentDeliveryManager: disables silent installs, suggested apps,
        subscribed content (many SubscribedContent-* keys)
  [3/7] Sets Start=4 on: PushToInstall, InstallService, WSService, wlidsvc,
        ClipSVC (AppXSvc is intentionally left commented out)
  [4/7] Disables Store/InstallService scheduled tasks
  [5/7] Removes the Microsoft Store package (current user + provisioned) and
        StorePurchaseApp
  [6/7] Removes UWP apps: Xbox, Bing (News/Weather/Finance/Sports), Zune,
        People/Maps/Messaging, Solitaire/CandyCrush/Disney/Spotify/TikTok/
        Facebook/Instagram/Twitter, Clipchamp/Todos/PowerAutomate, Teams
        (consumer), Feedback Hub/GetHelp/GetStarted, Copilot
  [7/7] CloudContent policies to block reinstall + disable suggestions


BEFORE YOU RUN
--------------
- Removing the Store makes it hard to install/update UWP apps later. You can
  re-register it (see undo) but it is fiddly.
- CAUTION on wlidsvc (Microsoft Account Sign-in Assistant): the script
  disables it. If you SIGN IN to Windows with a Microsoft account, this can
  interfere with account sign-in. Comment out that line (Phase 3) if you use
  a Microsoft account.
- The app-removal list is broad. If you use Xbox, Groove, Maps, Clipchamp,
  Teams, etc., comment out those lines first.
- AppXSvc is deliberately NOT disabled (needed to install/update any UWP app).


HOW TO RESTORE / UNDO
---------------------
Re-enable services (run as Administrator), e.g.:
  sc config InstallService start= demand
  sc config ClipSVC        start= demand
  sc config wlidsvc        start= demand

Delete the policy keys:
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /f

Reinstall the Store (PowerShell as Admin):
  Get-AppxPackage -AllUsers Microsoft.WindowsStore | ForEach-Object {
    Add-AppxPackage -Register "$($_.InstallLocation)\AppxManifest.xml" -DisableDevelopmentMode }
  wsreset.exe

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
