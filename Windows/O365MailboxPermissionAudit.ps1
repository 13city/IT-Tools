<#
.SYNOPSIS
   Audits mailbox permissions in Office 365/Exchange Online.

.DESCRIPTION
   - Connects to Exchange Online via Modern Auth.
   - Enumerates mailboxes and permissions.
   - Checks for Full Access, Send As, Send On Behalf.
   - Generates a CSV report.

.NOTES
   Requires: ExchangeOnlineManagement module
#>

param(
    [string]$ReportPath = "C:\Logs\MailboxPerms.csv"
)

try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop

    # This assumes you're using modern auth with interactive or app-based creds
    Connect-ExchangeOnline -ShowBanner:$false

    $mailboxes = Get-Mailbox -ResultSize Unlimited
    $permissionReport = @()

    foreach ($mb in $mailboxes) {
        $accessRights = Get-MailboxPermission $mb.Alias -ErrorAction SilentlyContinue
        $sendAsRights = Get-RecipientPermission $mb.Alias -ErrorAction SilentlyContinue
        $delegates    = Get-Mailbox $mb.Alias -ErrorAction SilentlyContinue | Select-Object -ExpandProperty GrantSendOnBehalfTo

        foreach ($ar in $accessRights) {
            if ($ar.AccessRights -match "FullAccess") {
                $permissionReport += [PSCustomObject]@{
                    Mailbox        = $mb.Alias
                    PermissionType = "FullAccess"
                    GrantedTo      = $ar.User
                }
            }
        }

        foreach ($sa in $sendAsRights) {
            if ($sa.AccessRights -contains "SendAs") {
                $permissionReport += [PSCustomObject]@{
                    Mailbox        = $mb.Alias
                    PermissionType = "SendAs"
                    GrantedTo      = $sa.Trustee
                }
            }
        }

        if ($delegates) {
            foreach ($delegate in $delegates) {
                $permissionReport += [PSCustomObject]@{
                    Mailbox        = $mb.Alias
                    PermissionType = "SendOnBehalf"
                    GrantedTo      = $delegate
                }
            }
        }
    }

    $permissionReport | Export-Csv $ReportPath -NoTypeInformation
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Host "Audit completed. Results in $ReportPath"
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
