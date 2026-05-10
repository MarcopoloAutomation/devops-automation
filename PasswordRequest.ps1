# ============================================================
# PasswordRequest.ps1
# Author: Marek Lyszczarz
# Script to generate one-time password for temp admin.
# ============================================================

# ============================================================
# CONFIGURATION
# ============================================================
$GmailAdres      = "yourEmail"                  
$GmailHasloApp   = "XXXXXXXX"        # 16-character password to myaccount.google.com/apppasswords
$AdminAccount    = "LocalAdmin"       # local admin account                    
$HasloWaznoscMin = 60                 # password validity in minutes (after that time password will be changed automatically)                                   
# ============================================================

# Check if it's running as administrator
$currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Generate random strong password (16 charakters)
$chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$%'
$haslo = -join (1..16 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })

# Set it up on admin account
try {
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    Set-LocalUser -Name $AdminAccount -Password $securePassword
    Enable-LocalUser -Name $AdminAccount
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Setting password fail: $_", "Fail", "OK", "Error")
    exit
}

# Send a password by gmail
$time     = Get-Date -Format "dd.MM.yyyy HH:mm"
$computer = $env:COMPUTERNAME

try {
    $smtpServer   = "smtp.gmail.com"
    $smtpPort     = 587
    $credentials  = New-Object System.Net.NetworkCredential($GmailAdres, $GmailHasloApp)

    $mail         = New-Object System.Net.Mail.MailMessage
    $mail.From    = $GmailAdres
    $mail.To.Add($GmailAdres)
    $mail.Subject = "Password request - $komputer"
    $mail.Body    = @"
Kasia asks about a installation password!

Computer : $computer
Time     : $time
Important    : $PasswordValidMin minutes 

Password to admin account '$AdminAccount':

    $password

After $PasswordValidMin minutes the password will change automatically.
"@

    $smtp = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $smtp.EnableSsl             = $true
    $smtp.Credentials          = $credentials
    $smtp.Send($mail)

    # Communicate for a user that request has sent out.
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Request has sent out.`n`nWait for a password - will be valid for $PasswordValidMin minutes.",
        "Request has sent",
        "OK",
        "Information"
    )
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Sending fail. Check your internet connection.`n`nFail: $_",
        "Fail",
        "OK",
        "Error"
    )
    exit
}

# Automatic password reset scheduling after X minutes.
$resetScript = @"
`$chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#`$%'
`$newPassword = -join (1..16 | ForEach-Object { `$chars[(Get-Random -Maximum `$chars.Length)] })
`$secure = ConvertTo-SecureString `$noweHaslo -AsPlainText -Force
Set-LocalUser -Name '$AdminAccount' -Password `$secure
Disable-LocalUser -Name '$AdminAccount'
"@

$resetScriptPath = "$env:TEMP\ResetAdmin.ps1"
$resetScript | Out-File -FilePath $resetScriptPath -Encoding UTF8

$taskName  = "ResetAdminPassword"
$trigger   = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes($PasswordValidMin)
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$resetScriptPath`""
$settings  = New-ScheduledTaskSettingsSet -DeleteExpiredTaskAfter 00:01:00
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Principal $principal | Out-Null