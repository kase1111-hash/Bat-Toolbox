================================================================================
 PasswordPolicyAudit.bat - Instructions
================================================================================

DESCRIPTION
-----------
Audits local password policy, account lockout settings, user accounts, audit
policy, and general security configuration. Reports security posture with a
letter grade (A-F) and actionable recommendations. No changes are made.
Especially useful for shared machines, family computers, and small offices.


HOW TO USE
----------
1. Right-click PasswordPolicyAudit.bat
2. Select "Run as administrator" (REQUIRED)
3. Confirm when prompted (Y/N)
4. Review the output on screen
5. Check the report saved to your Desktop


BEFORE YOU RUN
--------------
No system changes are made. This is a read-only audit tool.


WHAT IT CHECKS
--------------
Phase 1: Password Policy (local security policy, read with secedit)
  - Minimum password length
  - Maximum/minimum password age
  - Password history (reuse prevention)
  - Account lockout threshold
  - Lockout duration and observation window (shown as N/A and not scored
    while account lockout is disabled, because they have no effect then)

Phase 2: Password Complexity
  - Whether complexity requirements are enabled
  - Whether reversible encryption is disabled

Phase 3: User Accounts
  - Guest account status (should be disabled)
  - Built-in Administrator account status
  - All local accounts with last logon and password dates
  - Accounts that don't require a password
  - Local Administrators group membership

Phase 4: Audit Policy
  - Logon/Logoff auditing
  - Account lockout auditing
  - User and security group management auditing
  - Policy change auditing
  - Process creation auditing

Phase 5: Additional Security
  - UAC (User Account Control) status and level
  - Auto-logon configuration
  - Screen lock timeout (only counts when a screen saver is actually selected;
    choosing "(None)" leaves the old timeout behind but nothing locks)
  - Screen saver password requirement
  - Group Policy screen saver settings override the user's own settings
  - Windows Defender status

Language and renamed accounts:
  Phases 1-3 read the language-neutral key names of the security policy
  export (secedit /export) instead of the localized "net accounts" / "net
  user" text, so they also work on non-English Windows and when the Guest or
  Administrator account has been renamed. Phase 4 looks the audit
  subcategories up by GUID ("auditpol /backup"), and the Administrators group
  is found by its well-known SID, for the same reason.

Phase 6: Security Score
  - Overall score as percentage and letter grade
  - Specific command-line fixes for critical issues


SCORING
-------
| Grade | Score   | Meaning                              |
|-------|---------|--------------------------------------|
| A     | 90-100% | Excellent security posture            |
| B     | 75-89%  | Good, minor improvements possible     |
| C     | 60-74%  | Acceptable but improvements needed    |
| D     | 40-59%  | Weak, action needed                   |
| F     | 0-39%   | Critical issues, fix immediately      |


STATUS MEANINGS
---------------
[PASS] - Setting meets security best practices
[WARN] - Setting is acceptable but could be improved
[FAIL] - Setting is a security risk, should be fixed
[INFO] - Informational, no action needed
[N/A]  - Setting has no effect in the current configuration (not scored)
[SKIP] - Could not check (e.g. the security policy export failed)


RECOMMENDED SETTINGS
--------------------
| Setting                    | Recommended Value        |
|----------------------------|--------------------------|
| Minimum password length    | 12+ characters           |
| Password complexity        | Enabled                  |
| Password history           | 5+ passwords remembered  |
| Account lockout threshold  | 5-10 attempts            |
| Lockout duration           | 15+ minutes              |
| Guest account              | Disabled                 |
| Built-in Administrator     | Disabled                 |
| UAC                        | Enabled (default level)  |
| Auto-logon                 | Disabled                 |
| Screen lock timeout        | 5-15 minutes             |


HOW TO FIX COMMON ISSUES
-------------------------
Set minimum password length to 12:
  net accounts /minpwlen:12

Set account lockout after 5 attempts:
  net accounts /lockoutthreshold:5

Set lockout duration to 30 minutes:
  net accounts /lockoutduration:30

Set password history to remember 5:
  net accounts /uniquepw:5

Disable Guest account:
  net user Guest /active:no
  (On non-English Windows or if the account was renamed, use its real name,
  e.g. "Gast" - the report's recommendation shows the current name.)

Disable built-in Administrator:
  net user Administrator /active:no
  (Use the localized or renamed name if it differs, e.g. "Administrateur".)

Turn on a locking screen saver:
  Settings > Personalization > Lock screen > Screen saver: pick any screen
  saver (not "(None)"), set the wait time, and tick "On resume, display
  logon screen".

Enable password complexity (requires secpol.msc):
  1. Press Win+R, type "secpol.msc", press Enter
  2. Navigate to: Account Policies > Password Policy
  3. Double-click "Password must meet complexity requirements"
  4. Set to "Enabled"

Enable UAC:
  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
      /v EnableLUA /t REG_DWORD /d 1 /f


OUTPUT
------
Creates: PasswordAudit_COMPUTERNAME_DATE.txt on Desktop

Contains:
  - All check results with PASS/WARN/FAIL status
  - User account listing with password dates
  - Audit policy configuration
  - Security score and grade
  - Specific fix commands for found issues


NOTES
-----
- This is a read-only tool. No system changes are made.
- Password policy, complexity and Guest/Administrator checks use the security
  policy export (secedit /export). It is written to %TEMP% and deleted
  right after it is read.
- Audit policy requires auditpol access (admin only). A temporary
  auditpol_backup.csv in %TEMP% is read and deleted.
- Run periodically to verify security posture
- Run after joining a domain to compare local vs domain policy
- Domain-joined machines may have different policies from Group Policy


TIPS
----
- Run on all shared/family computers
- Save the report for compliance documentation
- Compare reports over time to track improvements
- Pairs well with OpenPortScanner.bat for full security audit
- On domain-joined machines, Group Policy may override local settings
- Consider using Windows Security Baselines for enterprise environments:
  https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/windows-security-baselines
