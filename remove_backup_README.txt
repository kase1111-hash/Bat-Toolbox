================================================================================
 remove_backup.bat - Instructions
================================================================================

DESCRIPTION
-----------
Disables Windows Backup and the related backup/restore infrastructure:
Block Level Backup Engine (wbengine), Windows Backup (SDRSVC), File History
(fhsvc), the Software Shadow Copy Provider (swprv), and Volume Shadow Copy
(VSS). It also disables backup-related scheduled tasks, sets backup/System
Restore/File History policies, blocks OneDrive folder backup (Known Folder
Move), and DELETES existing shadow copies / restore points.

*** IMPORTANT: This is a destructive, opinionated script. ***
It disables VSS and deletes ALL existing restore points and shadow copies.
Read "BEFORE YOU RUN" carefully.


HOW TO USE
----------
1. Right-click remove_backup.bat and choose "Run as administrator" (REQUIRED).
2. It prints a warning and pauses ("Press Ctrl+C to abort, or..."). Press
   Ctrl+C now if you did not intend to disable backups. Otherwise press a key.
3. It runs 5 phases: delete existing shadow copies and disable System
   Protection on the system drive -> disable services -> disable tasks ->
   policies -> OneDrive folder backup. The shadow-copy cleanup runs FIRST
   because vssadmin needs the VSS service, which the next phase disables.
4. In the OneDrive phase it asks (Y/N) whether to also remove OneDrive from
   startup. Answer N if your Desktop/Documents/Pictures are in OneDrive.
5. Reboot afterward.


WHAT IT DOES
------------
  [1/5] vssadmin delete shadows /all /quiet  AND
        Disable-ComputerRestore on the system drive (%SystemDrive%, usually C:)
        (runs before VSS/swprv are disabled; if vssadmin fails it says so
        instead of reporting DELETED)
  [2/5] sc stop + sc config start= disabled + Start=4 for: wbengine, SDRSVC,
        fhsvc, swprv, VSS
  [3/5] Disables scheduled tasks: WindowsBackup (ConfigNotification,
        AutomaticBackup, Monitor), FileHistory, SystemRestore SR, CloudBackup
  [4/5] Policies: DisableBackupUI, DisableSR, DisableConfig, File History
        Disabled
  [5/5] OneDrive: KFMBlockOptIn (blocks Known Folder Move, i.e. OneDrive
        folder backup). OneDrive itself keeps working and syncing.
        OPTIONAL (Y/N prompt): removes the OneDrive value from the HKCU Run
        key so it does not start at sign-in.


BEFORE YOU RUN
--------------
- This DELETES all existing System Restore points and shadow copies and turns
  OFF System Protection. After this, you CANNOT roll back to an earlier
  restore point until you re-enable protection and create new ones.
- Disabling VSS breaks anything that relies on shadow copies: many disk-
  imaging tools, some installers/updaters, "Previous Versions" of files, and
  some backup software. The script notes VSS can be re-enabled temporarily
  with "sc config VSS start= demand" if something breaks.
- Older versions of this script also set DisableFileSyncNGSC=1, which turns
  OneDrive off completely. This version does not; see HOW TO RESTORE / UNDO
  to repair a machine that ran an older version.
- Because it removes your recovery options, consider whether you actually want
  no backups at all before running this.


HOW TO RESTORE / UNDO
---------------------
Re-enable the services (run as Administrator):
  sc config wbengine start= demand
  sc config SDRSVC   start= demand
  sc config fhsvc    start= demand
  sc config swprv    start= demand
  sc config VSS      start= demand
(sc needs the space after "start=".)

Delete the policy keys:
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Backup" /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\FileHistory" /f

Re-allow OneDrive folder backup. The second command repairs machines where an
older version of this script turned OneDrive off completely:
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v KFMBlockOptIn /f
  reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /f
Then start OneDrive from the Start menu as your normal user (NOT from an
admin prompt - OneDrive refuses to run elevated). Starting it also restores
its own startup entry if you removed it.

Re-enable System Protection (then create a fresh restore point):
  powershell -NoProfile -Command "Enable-ComputerRestore -Drive ($env:SystemDrive + '\')"

Re-enable any scheduled tasks you disabled via Task Scheduler, then reboot.
NOTE: Deleted restore points and shadow copies are gone permanently; undo only
restores the ability to make NEW ones.


VERIFICATION
------------
  sc query VSS       (STATE: STOPPED while disabled)
  sc qc SDRSVC       (START_TYPE: DISABLED)
  vssadmin list shadows   (fails with a service-disabled error while VSS is
                           disabled; to check, run "sc config VSS start= demand"
                           first - it should then report no shadow copies)


TIPS
----
- If you use disk-imaging software (Macrium, Veeam Agent, Windows' own image
  backup), do NOT run this, or re-enable VSS before imaging.
- Pairs conceptually with remove_telemetry.bat and remove_store.bat as part of
  a broader "reclaim the machine" pass - but this one is the most destructive
  because of the restore-point deletion.
