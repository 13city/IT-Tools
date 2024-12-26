# Advanced PowerShell Scripts for M365 Troubleshooting

## Overview
This guide provides advanced PowerShell scripts and modules for complex Microsoft 365 troubleshooting scenarios requiring L2-level expertise.

## Exchange Online Advanced Scripts {#exchange-advanced}

### Mail Flow Analysis
```powershell
# Advanced mail flow analysis
function Test-AdvancedMailFlow {
    param(
        [string]$Sender,
        [string]$Recipient,
        [int]$Hours = 24
    )
    
    $startDate = (Get-Date).AddHours(-$Hours)
    $endDate = Get-Date
    
    # Get detailed message trace
    $messages = Get-MessageTrace -SenderAddress $Sender -RecipientAddress $Recipient `
                -StartDate $startDate -EndDate $endDate | 
                Select-Object Received, Status, FromIP, ToIP, Size, Subject
    
    # Get transport rules that affected messages
    $rules = Get-TransportRule | Where-Object {$_.State -eq "Enabled"}
    
    # Get connector information
    $connectors = Get-InboundConnector
    
    return @{
        Messages = $messages
        Rules = $rules
        Connectors = $connectors
    }
}
```

### Advanced Permission Analysis
```powershell
# Comprehensive permission analysis
function Get-AdvancedMailboxPermissions {
    param(
        [string]$Mailbox
    )
    
    # Get mailbox permissions
    $mailboxPerms = Get-MailboxPermission -Identity $Mailbox
    
    # Get folder permissions
    $folderPerms = Get-MailboxFolderPermission -Identity "$Mailbox:\Calendar"
    
    # Get send-as permissions
    $sendAsPerms = Get-RecipientPermission -Identity $Mailbox
    
    # Get transport rules affecting mailbox
    $rules = Get-TransportRule | Where-Object {$_.State -eq "Enabled"}
    
    return @{
        MailboxPermissions = $mailboxPerms
        FolderPermissions = $folderPerms
        SendAsPermissions = $sendAsPerms
        TransportRules = $rules
    }
}
```

## SharePoint Online Advanced Scripts {#sharepoint-advanced}

### Site Collection Analysis
```powershell
# Advanced site collection diagnostics
function Test-AdvancedSiteHealth {
    param(
        [string]$SiteUrl
    )
    
    # Get site collection details
    $site = Get-SPOSite -Identity $SiteUrl -Detailed
    
    # Get storage metrics
    $storage = Get-SPOSiteStorageUsage -Identity $SiteUrl
    
    # Get sharing settings
    $sharing = Get-SPOSiteSharing -Identity $SiteUrl
    
    # Get permissions
    $perms = Get-SPOSitePermissions -Identity $SiteUrl
    
    return @{
        SiteDetails = $site
        StorageMetrics = $storage
        SharingSettings = $sharing
        Permissions = $perms
    }
}
```

### Content Analysis
```powershell
# Advanced content analysis
function Get-AdvancedContentAnalysis {
    param(
        [string]$SiteUrl,
        [string]$LibraryName
    )
    
    # Get library items
    $items = Get-PnPListItem -List $LibraryName -Fields "ID", "Title", "Modified", "Editor"
    
    # Get version history
    $versions = Get-PnPListItemVersions -List $LibraryName
    
    # Get sharing links
    $links = Get-PnPSharingLinks -List $LibraryName
    
    return @{
        Items = $items
        Versions = $versions
        SharingLinks = $links
    }
}
```

## Teams Advanced Scripts {#teams-advanced}

### Teams Configuration Analysis
```powershell
# Advanced Teams diagnostics
function Test-AdvancedTeamsConfiguration {
    param(
        [string]$TeamName
    )
    
    # Get team details
    $team = Get-Team -DisplayName $TeamName
    
    # Get channels
    $channels = Get-TeamChannel -GroupId $team.GroupId
    
    # Get policies
    $policies = Get-TeamMessagingPolicy
    
    # Get apps
    $apps = Get-TeamsApp
    
    return @{
        TeamDetails = $team
        Channels = $channels
        Policies = $policies
        Apps = $apps
    }
}
```

### Meeting Diagnostics
```powershell
# Advanced meeting diagnostics
function Test-AdvancedMeetingConfiguration {
    param(
        [string]$UserPrincipalName
    )
    
    # Get meeting policies
    $policies = Get-CsTeamsMeetingPolicy -Identity Global
    
    # Get conferencing settings
    $conf = Get-CsTeamsConferencingPolicy
    
    # Get user settings
    $userSettings = Get-CsUserPolicyAssignment -Identity $UserPrincipalName
    
    return @{
        MeetingPolicies = $policies
        ConferencingSettings = $conf
        UserSettings = $userSettings
    }
}
```

## Azure AD Advanced Scripts {#azuread-advanced}

### Identity Analysis
```powershell
# Advanced identity diagnostics
function Test-AdvancedIdentityConfiguration {
    param(
        [string]$UserPrincipalName
    )
    
    # Get user details
    $user = Get-AzureADUser -ObjectId $UserPrincipalName
    
    # Get group memberships
    $groups = Get-AzureADUserMembership -ObjectId $user.ObjectId
    
    # Get assigned licenses
    $licenses = Get-AzureADUserLicenseDetail -ObjectId $user.ObjectId
    
    # Get sign-in logs
    $signIns = Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$UserPrincipalName'"
    
    return @{
        UserDetails = $user
        GroupMemberships = $groups
        Licenses = $licenses
        SignInLogs = $signIns
    }
}
```

### Conditional Access Analysis
```powershell
# Advanced conditional access diagnostics
function Test-AdvancedConditionalAccess {
    param(
        [string]$PolicyName
    )
    
    # Get policy details
    $policy = Get-AzureADMSConditionalAccessPolicy -PolicyId $PolicyName
    
    # Get affected users
    $users = Get-AzureADMSConditionalAccessPolicyDetail -PolicyId $PolicyName
    
    # Get policy report
    $report = Get-AzureADMSConditionalAccessPolicyReport -PolicyId $PolicyName
    
    return @{
        PolicyDetails = $policy
        AffectedUsers = $users
        PolicyReport = $report
    }
}
```

## Implementation Guidelines

### Script Usage
1. **Prerequisites**
   - Required modules
   - Permissions
   - Connection requirements
   - Environmental setup

2. **Error Handling**
   - Try-catch blocks
   - Error logging
   - Cleanup procedures
   - Rollback capabilities

### Best Practices
1. **Script Development**
   - Modular design
   - Error handling
   - Logging implementation
   - Performance optimization

2. **Documentation**
   - Parameter descriptions
   - Usage examples
   - Expected output
   - Error scenarios

## Related Resources
- [Microsoft Support Tools](microsoft_tools.md)
- [Network Testing Tools](network_testing.md)
- [Advanced Methodology](../methodology/index.md)
- [Service-Specific Guides](../services/index.md)
