# Local Admin Password Rotation – my alternative

This solution provides a lightweight alternative to Microsoft LAPS for home workgroup computers not joined to any domain. It allows a standard (non-admin) user to request a one-time Administrator password via a desktop shortcut, which is then delivered securely to the computer owner via Gmail.

The password is automatically rotated, and the Administrator account is disabled after a configurable time window, ensuring the standard user never retains permanent admin access.

---

## 1.1 From the author

I created this for my girlfriend because she doesn't have her own personal PC, so I shared mine with her. For security reasons, I couldn't share the admin password. Before that, I had been reading documentation about LAPS for personal use — a workgroup on Windows 11 22H2. Unfortunately, as very often happens, it didn't work as it should.

I was thinking about an alternative, and then I had an idea: use a PowerShell script. The problem was how to run the script without admin access. After two days, I used my knowledge from my RPG gaming days. Many years ago, I was playing games and creating my own servers to play with gamers across the globe. That's when I had the idea to create a launcher based on a `.vbs` file.

---

## 2. How It Works

### 2.1 Workflow

The solution consists of two components working together:

- **`PasswordRequest.ps1`** — PowerShell script that generates a random password, sets it on the Administrator account, sends it to the owner via Gmail, and schedules automatic password rotation.
- **`PoprosPozwolenie.vbs`** — VBScript launcher that allows a standard user to trigger the PowerShell script via Windows Task Scheduler without requiring admin credentials.

### 2.2 Step-by-Step Flow

1. User clicks the desktop shortcut (`PoprosPozwolenie.vbs`).
2. VBScript triggers the `PasswordRequest` Task Scheduler job without requiring admin privileges.
3. Task Scheduler runs `PasswordRequest.ps1` as the owner's account (with highest privileges).
4. The script generates a 16-character random password and sets it on the local Administrator account.
5. The Administrator account is enabled.
6. The password is sent to the owner's Gmail address.
7. User sees a confirmation message and waits for the owner to share the password.
8. After the configurable time window (default: 60 minutes), a scheduled reset task changes the password again and disables the Administrator account.

---

## 3. System Requirements

| Setting | Value |
|---|---|
| **OS** | Windows 11 (any version) |
| **PowerShell** | 5.1 or later (built-in) |
| **Network** | Internet access required for Gmail SMTP |
| **Gmail** | Google account with 2-Step Verification enabled |
| **Domain** | None — workgroup only |
| **Admin account** | Local `Administrator` account must exist |

---

## 4. File Structure

| Path | Description |
|---|---|
| `C:\foldername\PasswordRequest.ps1` | Main PowerShell script — do not move |
| `C:\foldername\PoprosPozwolenie.vbs` | VBScript launcher — desktop shortcut points here |
| Desktop shortcut | User's shortcut — points to `PoprosPozwolenie.vbs` |

---

## 5. Configuration

### 5.1 PasswordRequest.ps1 — Settings Block

Open `C:\Scripts\PasswordRequest.ps1` and edit the top section:

```powershell
$GmailAdres      = "your@gmail.com"          # Your Gmail address
$GmailHasloApp   = "xxxx xxxx xxxx xxxx"     # 16-char App Password from Google
$AdminAccount    = "Administrator"            # Local admin account name
$HasloWaznoscMin = 60                         # Password valid for X minutes
```

### 5.2 Gmail App Password

- Enable 2-Step Verification at: https://myaccount.google.com/security
- Generate an App Password at: https://myaccount.google.com/apppasswords
- Use the generated 16-character password (without spaces) as `$GmailHasloApp`

---

## 6. Task Scheduler Configuration

The Task Scheduler job `PasswordRequest` must be configured as follows:

| Setting | Value |
|---|---|
| **Task Name** | PasswordRequest |
| **Run As** | Owner's admin account (e.g. `DESKTOP-XXXX\Username`) |
| **Run with highest privileges** | Yes |
| **Trigger** | None (triggered manually by VBScript) |
| **Action — Program** | `powershell.exe` |
| **Action — Arguments** | `-ExecutionPolicy Bypass -File "C:\Scripts\PasswordRequest.ps1"` |
| **Start In** | `C:\Scripts` |
| **Stop task if runs longer than** | 1 hour |
| **AC Power only** | No (unchecked) |

After creating the task, grant standard users permission to run it:

```cmd
icacls "C:\Windows\System32\Tasks\PasswordRequest" /grant "Users:(RX)"
```

Then set the security descriptor via PowerShell (run as admin):

```powershell
$scheduler = New-Object -ComObject "Schedule.Service"
$scheduler.Connect()
$folder = $scheduler.GetFolder("\")
$task = $folder.GetTask("PasswordRequest")
$newSddl = "O:BAG:...your-sddl...(A;;0x1200a9;;;BU)"
$task.SetSecurityDescriptor($newSddl, 0)
```

---

## 7. Password Generation

Each password is randomly generated using the following character set:

```
ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$%
```

- Length: 16 characters
- Excludes ambiguous characters (`0`, `O`, `1`, `l`, `I`) to avoid confusion
- Includes uppercase, lowercase, digits, and special characters
- Generated fresh on every request — never reused

---

## 8. Security Considerations

- The Administrator account is disabled when not in use — only enabled during the active time window.
- The App Password stored in the script grants only SMTP send access — not full Gmail access.
- The script file (`PasswordRequest.ps1`) should be readable only by the owner's account.
- The user's account has no visibility into the script contents or the generated password.
- Passwords are sent over TLS (port 587) — not transmitted in plain text.
- The reset task runs as SYSTEM to ensure the account is locked down even if the owner forgets.

---

## 9. Known Limitations

- Requires internet access — if the network is down, the Gmail send will fail and no password is delivered.
- Windows LAPS Local Storage mode was not available on this system build — this solution was implemented as an alternative.
- The App Password is stored in plain text in the `.ps1` file — secure the file with NTFS permissions.
- Only one active password request at a time — a new request resets the timer and changes the password.

---

## 10. Troubleshooting

| Problem | Solution |
|---|---|
| **Shortcut opens Notepad** | Right-click shortcut → Properties → change Target to: `powershell.exe -ExecutionPolicy Bypass ...` |
| **UAC prompts for password** | Ensure Task Scheduler job runs as owner's account, not SYSTEM. Check VBS uses `Schedule.Service` COM object. |
| **Email not received** | Check App Password is correct. Test by running script manually as admin in PowerShell. |
| **Task shows LastTaskResult 267011** | Task has never run. Check Task Scheduler permissions and run manually first. |
| **Access denied on schtasks /run** | Standard users cannot run schtasks directly — use the VBS launcher instead. |

---

## Sources and Links

**1. Microsoft PowerShell Documentation**
- https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview
- https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-management-policy-settings

**2. Windows Task Scheduler Documentation**
- https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/register-scheduledtask
- https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtaskaction

**3. Gmail SMTP / App Passwords**
- https://support.google.com/accounts/answer/185833
