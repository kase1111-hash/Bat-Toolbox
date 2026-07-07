================================================================================
 disable_asus_updatechecker.bat - Instructions
================================================================================

DESCRIPTION
-----------
A belt-and-suspenders disable of the ASUS update-checker binaries. It applies
FOUR independent layers, any one of which is usually enough on its own, so
that the updater cannot relaunch regardless of who tries to start it or where
it lives on disk. Reversible.

Primary target:    AsusUpdateChecker.exe
Secondary target:  AsusSoftwareManagerAgent.exe


THE FOUR LAYERS
---------------
  [1/4] Kill      - terminates any running instances right now.
  [2/4] Tasks     - scans Scheduled Tasks and disables any task whose
                    definition references the target binaries.
  [3/4] IFEO       - installs an Image File Execution Options "Debugger"
                    redirect pointing the binary name at systray.exe (a
                    harmless Windows stub). Windows checks this key by binary
                    basename before launching ANY process, so every future
                    launch attempt is intercepted and no-ops, no matter who
                    invokes it or from what path.
  [4/4] Services  - scans all services and disables any whose ImagePath
                    references the target binaries.


HOW TO USE
----------
1. Right-click disable_asus_updatechecker.bat
2. Select "Run as administrator" (REQUIRED)
3. Each layer runs in sequence and prints what it found and changed.
4. Review the summary (killed / tasks disabled / IFEO installed / services
   disabled).


BEFORE YOU RUN
--------------
- This is ASUS-specific. On non-ASUS machines every layer simply reports
  "nothing found" and no changes are made.
- The IFEO layer is a blunt instrument: it blocks the binary by NAME for the
  whole machine. If you ever legitimately want the ASUS updater back, you must
  remove the IFEO key (see undo below).


HOW TO RESTORE / UNDO
---------------------
Undo each layer as needed (run as Administrator):

  Layer 1 (kill):    no undo needed - the process was simply terminated.

  Layer 2 (tasks):   re-enable each task the script disabled:
                     schtasks /Change /TN "<task name>" /Enable

  Layer 3 (IFEO):    remove the redirect keys:
     reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\AsusUpdateChecker.exe" /f
     reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\AsusSoftwareManagerAgent.exe" /f

  Layer 4 (service): re-enable any service that was disabled:
                     sc config "<service>" start= auto   (or its prior value)


VERIFICATION
------------
Confirm the IFEO redirect is in place:
  reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\AsusUpdateChecker.exe" /v Debugger

Confirm nothing is running:
  tasklist | findstr /i "AsusUpdateChecker AsusSoftwareManagerAgent"
  (should return nothing)


TIPS
----
- IFEO is the most durable layer: it survives the binary being moved or
  reinstalled to a new path, because it keys on the executable name.
- If you would rather simply stop the ASUS services (no binary-level block),
  use disable-asus-services.bat instead.
- After running, watch behavior for a day. If an ASUS updater still appears,
  its launcher is using a different binary name - note it and add it to the
  target list.
