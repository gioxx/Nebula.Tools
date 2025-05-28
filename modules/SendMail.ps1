<#
.SYNOPSIS
    E-mail functions for PowerShell scripts.
.DESCRIPTION
    This module contains functions for sending e-mails.
    The Send-Mail function sends an e-mail using the SMTP server and port specified in the configuration file.
.PARAMETER SMTPServer
    The SMTP server to use for sending the e-mail.
.PARAMETER SMTPPort
    The SMTP port to use for sending the e-mail. Default is 25.
.PARAMETER From
    The e-mail address of the sender.
.PARAMETER To
    The e-mail address of the recipient.
.PARAMETER CC
    The e-mail address of the recipient in CC (Carbon Copy).
.PARAMETER Bcc
    The e-mail address of the recipient in BCC (Blind Carbon Copy).
.PARAMETER Subject
    The subject of the e-mail.
.PARAMETER Body
    The body of the e-mail.
.PARAMETER AttachmentPath
    The path to the file to attach to the e-mail.
.EXAMPLE
    Send-Mail -Config $config -From "lM2tH@example.com" -To "lM2tH@example.com" -Subject "Test e-mail" -Body "This is a test e-mail." -AttachmentPath "C:\test.txt"
.NOTES
    Author: Giovanni Solone

    Modification History:
    - 2025/05/23: Added CC parameter to the Send-Mail function.
    - 2025/04/03: Added Parameter informations to this help.
    - 2025/03/27: Initial version (isolation of e-mail functions from main script).
#>

# Mail Function
function Send-Mail {
    param (
        [string] $SMTPServer,
        [int] $SMTPPort = 25,
        [string] $From,
        [string] $To,
        [string] $Cc = "",
        [string] $Bcc = "",
        [string] $Subject,
        [string] $Body,
        [string] $AttachmentPath
    )

    try {
        $mailMessage = New-Object System.Net.Mail.MailMessage($From, $To, $Subject, $Body)
        $mailMessage.IsBodyHtml = $true
        if ($AttachmentPath -ne "") { 
            $attachment = New-Object System.Net.Mail.Attachment($AttachmentPath)
            $mailMessage.Attachments.Add($attachment)
        }
        if ($Cc -ne "") { $mailMessage.CC.Add($Cc) }
        if ($Bcc -ne "") { $mailMessage.Bcc.Add($Bcc) }
        $smtpClient = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort)
        $smtpClient.Send($mailMessage)
    } catch {
        Write-Error "Failed to send e-mail: $_"
    }
}