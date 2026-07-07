================================================================================
 remove_backup.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables Windows Backup and the related backup/restore infrastructure:
Block Level Backup Engine (wbengine), Windows Backup (SDRSVC), File History
(fhsvc), the Software Shadow Copy Provider (swprv), and Volume Shadow Copy
(VSS). It also disables backup-related scheduled tasks, sets backup/System
Restore/File History policies, disables OneDrive backup integration, and
DELETES existing shadow copies / restore points.

*** IMPORTANT: This is a destructive, opinionated script. ***
It disables VSS and deletes ALL existing restore points and shadow copies.
Read "BEFORE YOU RUN" carefully.


HOW TO USE
----------
1. Right-click remove_backup.bat and choose "Run as administrator" (REQUIRED).
2. It prints a warning and pauses ("Press Ctrl+C to abort, or..."). Press
   Ctrl+C now if you did not intend to disable backups. Otherwise press a key.
3. It runs 5 phases: disable services -> disable tasks -> policies ->
   OneDrive backup -> delete existing shadow copies and disable System
   Protection on C:.
4. Reboot afterward.


WHAT IT DOES
------------
  [1/5] sc stop + sc config start=disabled + Start=4 for: wbengine, SDRSVC,
        fhsvc, swprv, VSS
  [2/5] Disables scheduled tasks: WindowsBackup (ConfigNotification,
        AutomaticBackup, Monitor), FileHistory, SystemRestore SR, CloudBackup
  [3/5] Policies: DisableBackupUI, DisableSR, DisableConfig, File History
        Disabled
  [4/5] OneDrive: DisableFileSyncNGSC, KFMBlockOptIn, removes OneDrive Run key
  [5/5] vssadmin delete shadows /all /quiet  AND
        Disable-ComputerRestore -Drive C:\


BEFORE YOU RUN
--------------
- This DELETES all existing System Restore points and shadow copies and turns
  OFF System Protection. After this, you CANNOT roll back to an earlier
  restore point until you re-enable protection and create new ones.
- Disabling VSS breaks anything that relies on shadow copies: many disk-
  imaging tools, some installers/updaters, "Previous Versions" of files, and
  some backup software. The script notes VSS can be re-enabled temporarily
  with "sc config VSS start=demand" if something breaks.
- Because it removes your recovery options, consider whether you actually want
  no backups at all before running this.


HOW TO RESTORE / UNDO
---------------------
Re-enable the services (run as Administrator):
  sc config wbengine start=demand
  sc config SDRSVC   start=demand
  sc config fhsvc    start=manual
  sc config swprv    start=manual
  sc config VSS      start=manual

Delete the policy keys:
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Backup" /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\FileHistory" /f

Re-enable System Protection (then create a fresh restore point):
  powershell -NoProfile -Command "Enable-ComputerRestore -Drive 'C:\'"

Re-enable any scheduled tasks you disabled via Task Scheduler, then reboot.
NOTE: Deleted restore points and shadow copies are gone permanently; undo only
restores the ability to make NEW ones.


VERIFICATION
------------
  sc query VSS       (STATE: STOPPED while disabled)
  sc qc SDRSVC       (START_TYPE: DISABLED)
  vssadmin list shadows   (should report none after running)


TIPS
----
- If you use disk-imaging software (Macrium, Veeam Agent, Windows' own image
  backup), do NOT run this, or re-enable VSS before imaging.
- Pairs conceptually with remove_telemetry.bat and remove_store.bat as part of
  a broader "reclaim the machine" pass - but this one is the most destructive
  because of the restore-point deletion.
