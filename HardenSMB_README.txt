================================================================================
 HardenSMB.bat - Instructions
================================================================================

DESCRIPTION
-----------
Hardens SMB 2.0/3.0 by enforcing packet signing, encryption, and
restricting guest/null-session access. Also disables SMB compression to
mitigate SMBGhost (CVE-2020-0796).

Note: SMB1 removal is handled separately by the windows-debloat suite
(06-Remove-Features.bat). This script hardens the remaining SMB stack.


HOW TO USE
----------
1. Right-click HardenSMB.bat
2. Select "Run as administrator" (REQUIRED)
3. Review the current SMB configuration shown
4. Confirm with Y to proceed
5. No reboot required for most settings


WHAT IT DOES
------------
SMB Server Hardening:
  - RequireSecuritySignature = True  (all packets must be signed)
  - EnableSecuritySignature = True
  - EncryptData = True               (all transfers encrypted)
  - RejectUnencryptedAccess = True    (block unencrypted clients)
  - EnableInsecureGuestLogons = False
  - DisableCompression = True         (SMBGhost CVE-2020-0796)

SMB Client Hardening:
  - RequireSecuritySignature = True
  - EnableSecuritySignature = True
  - EnableInsecureGuestLogons = False

Registry Hardening:
  - RestrictAnonymousSAM = 1          (no anonymous SAM enumeration)
  - RestrictAnonymous = 1             (no anonymous share enumeration)
  - NullSessionPipes = (empty)        (no null session named pipes)
  - NullSessionShares = (empty)       (no null session share access)
  - LmCompatibilityLevel = 5          (NTLMv2 only, refuse LM/NTLMv1)


BEFORE YOU RUN
--------------
*** CREATE A RESTORE POINT FIRST ***

1. Press Win+R, type "sysdm.cpl", press Enter
2. Go to "System Protection" tab
3. Click "Create..." button
4. Name it "Before Harden SMB"
5. Click Create and wait for completion

Also check:
- Do you connect to very old NAS devices that don't support SMB signing?
  (Most modern NAS firmware supports it. Check your NAS admin panel.)
- Do you connect to old Linux/Samba shares?
  (Samba 4.2+ supports signing; Samba 4.11+ supports encryption.)
- Windows-to-Windows file sharing is fully compatible with all settings.


WHEN TO USE THIS SCRIPT
-----------------------
- Hardening workstations on networks with sensitive data
- After a penetration test found SMB relay or null session vulnerabilities
- Compliance with CIS benchmarks or STIG requirements
- Preventing NTLM relay attacks (e.g., Responder + ntlmrelayx)
- Environments where SMB1 has been removed but SMB2/3 is unhardened


HOW TO RESTORE / UNDO
---------------------
Option 1: System Restore (Recommended)
  1. Press Win+R, type "rstrui.exe", press Enter
  2. Select "Before Harden SMB" restore point
  3. Follow the wizard to restore

Option 2: Manual Reversal
  Run these commands as Administrator:

  Step 1 - Revert SMB server (PowerShell):
    Set-SmbServerConfiguration -RequireSecuritySignature $false -EncryptData $false -RejectUnencryptedAccess $false -Confirm:$false

  Step 2 - Revert SMB client (PowerShell):
    Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableInsecureGuestLogons $true -Confirm:$false

  Step 3 - Revert registry (Command Prompt):
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymousSAM /t REG_DWORD /d 0 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymous /t REG_DWORD /d 0 /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 3 /f


COMPATIBILITY
-------------
  SMB signing:
    - All Windows versions since Vista/2008 support SMB signing
    - Samba 4.2+ supports signing
    - Most NAS devices support signing (check firmware updates)

  SMB encryption:
    - Windows 8/2012 and later support SMB 3.0 encryption
    - Samba 4.11+ supports SMB 3.0 encryption
    - Older NAS devices may need firmware updates

  NTLMv2:
    - All modern Windows, macOS, and Linux systems support NTLMv2
    - Only Windows 95/98/ME and very old Samba require LM/NTLMv1

If you experience connectivity issues with specific devices:
  1. Check the device's firmware for SMB signing/encryption support
  2. As a temporary workaround, you can revert specific settings while
     keeping the rest of the hardening in place


VERIFICATION
------------
After running the script:

  1. Check SMB server settings (PowerShell):
     Get-SmbServerConfiguration | Select RequireSecuritySignature, EncryptData, RejectUnencryptedAccess

  2. Check SMB client settings (PowerShell):
     Get-SmbClientConfiguration | Select RequireSecuritySignature, EnableInsecureGuestLogons

  3. Check LAN Manager auth level:
     reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel
     (Should show 0x5)

  4. Test file sharing:
     Access a shared folder (\\server\share) to confirm it still works


TIPS
----
- This script is safe to run multiple times (idempotent)
- SMB signing adds ~5-10% CPU overhead on large file transfers
- Encryption adds ~10-15% overhead but prevents network eavesdropping
- The LmCompatibilityLevel = 5 setting is the most impactful security
  improvement, as it forces NTLMv2 and blocks NTLM downgrade attacks
- If you also run DisableNetBIOS.bat, SMB will only use TCP 445 (direct
  hosting), which is the modern and more secure transport
