# PowerShell Scripts for M365 Troubleshooting

## 1. Connection Scripts

### 1.1 Connect to All Services
```powershell
# Connect to Microsoft 365 Services
function Connect-M365Services {
    # Exchange Online
    Connect-ExchangeOnline

    # SharePoint Online
    $orgName = Read-Host -Prompt "Enter your SharePoint organization name"
    Connect-SPOService -Url "https://$orgName-admin.sharepoint.com"

    # Teams
    Connect-MicrosoftTeams

    # Azure AD
    Connect-AzureAD

    # Security & Compliance
    Connect-IPPSSession

    Write-Host "Connected to all Microsoft 365 services" -ForegroundColor Green
}
```

### 1.2 Check Connection Status
```powershell
function Test-M365Connections {
    $connections = @{
        "Exchange Online" = { Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange"} }
        "SharePoint Online" = { Get-SPOTenant -ErrorAction SilentlyContinue }
        "Teams" = { Get-Team -ErrorAction SilentlyContinue }
        "Azure AD" = { Get-AzureADTenantDetail -ErrorAction SilentlyContinue }
    }

    foreach ($service in $connections.Keys) {
        try {
            $result = & $connections[$service]
            $status = if ($result) { "Connected" } else { "Disconnected" }
        }
        catch {
            $status = "Disconnected"
        }
        Write-Host "$service : $status"
    }
}
```

## 2. User Management Scripts

### 2.1 User License and Service Check
```powershell
function Get-UserLicenseStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName
    )

    # Get user license details
    $user = Get-MsolUser -UserPrincipalName $UserPrincipalName
    $licenses = $user.Licenses

    foreach ($license in $licenses) {
        Write-Host "License: $($license.AccountSkuId)"
        Write-Host "Service Status:"
        
        foreach ($service in $license.ServiceStatus) {
            Write-Host "`t$($service.ServicePlan.ServiceName): $($service.ProvisioningStatus)"
        }
    }
}
```

### 2.2 User Access Check
```powershell
function Test-UserAccess {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName
    )

    # Check Exchange
    $mailbox = Get-Mailbox -Identity $UserPrincipalName -ErrorAction SilentlyContinue
    Write-Host "Exchange Mailbox: $(if($mailbox){'Exists'}else{'Not Found'})"

    # Check SharePoint
    $spo = Get-SPOUser -Site "https://tenant.sharepoint.com" -LoginName $UserPrincipalName -ErrorAction SilentlyContinue
    Write-Host "SharePoint Access: $(if($spo){'Granted'}else{'Not Found'})"

    # Check Teams
    $teams = Get-Team -User $UserPrincipalName -ErrorAction SilentlyContinue
    Write-Host "Teams Membership: $(if($teams){'Active in Teams'}else{'No Teams'})"
}
```

## 3. Service Health Scripts

### 3.1 Service Status Check
```powershell
function Get-M365ServiceHealth {
    # Get current service health
    $health = Get-ServiceHealth
    
    # Group by workload
    $health | Group-Object Workload | ForEach-Object {
        Write-Host "`n$($_.Name) Status:"
        $_.Group | ForEach-Object {
            Write-Host "`t$($_.StatusDisplayName)"
            if ($_.IncidentIds) {
                Write-Host "`tActive Incidents: $($_.IncidentIds -join ', ')"
            }
        }
    }
}
```

### 3.2 Message Center Updates
```powershell
function Get-M365Updates {
    param(
        [int]$Days = 7
    )

    $startDate = (Get-Date).AddDays(-$Days)
    $messages = Get-MessageCenterMessage -StartDate $startDate

    $messages | ForEach-Object {
        Write-Host "`nTitle: $($_.Title)"
        Write-Host "Category: $($_.Category)"
        Write-Host "Action Required: $($_.ActionRequiredByDate)"
        Write-Host "Message: $($_.Message)"
    }
}
```

## 4. Exchange Online Scripts

### 4.1 Mail Flow Test
```powershell
function Test-MailFlow {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Sender,
        [Parameter(Mandatory=$true)]
        [string]$Recipient
    )

    # Test mail flow
    $testResult = Test-MessageFlow -Sender $Sender -Recipient $Recipient
    
    # Check message trace
    $trace = Get-MessageTrace -SenderAddress $Sender -RecipientAddress $Recipient -StartDate (Get-Date).AddMinutes(-10)
    
    Write-Host "Mail Flow Test Results:"
    Write-Host "Test Status: $($testResult.Status)"
    Write-Host "Message Trace Status: $($trace.Status)"
    Write-Host "Delivery Time: $($trace.Received)"
}
```

### 4.2 Mailbox Permission Audit
```powershell
function Get-MailboxPermissionAudit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Mailbox
    )

    # Get mailbox permissions
    $permissions = Get-MailboxPermission -Identity $Mailbox
    
    # Get folder permissions
    $folderPermissions = Get-MailboxFolderPermission -Identity "$Mailbox:\Calendar"
    
    Write-Host "Mailbox Permissions:"
    $permissions | Format-Table User,AccessRights
    
    Write-Host "`nCalendar Permissions:"
    $folderPermissions | Format-Table User,AccessRights
}
```

## 5. SharePoint Online Scripts

### 5.1 Site Collection Health Check
```powershell
function Test-SPOSiteHealth {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SiteUrl
    )

    # Get site collection details
    $site = Get-SPOSite $SiteUrl
    
    Write-Host "Site Collection Health Check:"
    Write-Host "Storage Used: $($site.StorageUsageCurrent) MB of $($site.StorageQuota) MB"
    Write-Host "Lock Status: $($site.LockState)"
    
    # Check sharing capabilities
    Write-Host "Sharing Capability: $($site.SharingCapability)"
    
    # Test site status
    $test = Test-SPOSite $SiteUrl
    Write-Host "Site Status: $($test.Status)"
}
```

### 5.2 Permission Report
```powershell
function Get-SPOPermissionReport {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SiteUrl
    )

    # Get site users
    $users = Get-SPOUser -Site $SiteUrl
    
    Write-Host "Site Permissions Report:"
    foreach ($user in $users) {
        Write-Host "`nUser: $($user.LoginName)"
        Write-Host "Permissions: $($user.Groups -join ', ')"
    }
}
```

## 6. Teams Scripts

### 6.1 Teams Policy Check
```powershell
function Get-TeamsUserPolicies {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName
    )

    # Get user policy assignments
    $policies = Get-CsUserPolicyAssignment -Identity $UserPrincipalName
    
    Write-Host "Teams Policies for $UserPrincipalName"
    $policies | ForEach-Object {
        Write-Host "`nPolicy Type: $($_.PolicyType)"
        Write-Host "Policy Name: $($_.PolicyName)"
    }
}
```

### 6.2 Teams Meeting Configuration
```powershell
function Test-TeamsMeetingConfig {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName
    )

    # Get meeting configuration
    $config = Get-CsTeamsMeetingConfiguration
    
    # Get user policy
    $userPolicy = Get-CsTeamsMeetingPolicy -Identity (Get-CsUserPolicyAssignment -Identity $UserPrincipalName | 
        Where-Object {$_.PolicyType -eq "TeamsMeetingPolicy"}).PolicyName
    
    Write-Host "Teams Meeting Configuration:"
    Write-Host "Allow Anonymous Join: $($config.DisableAnonymousJoin)"
    Write-Host "Lobby Setting: $($userPolicy.AutoAdmittedUsers)"
    Write-Host "Recording Allowed: $($userPolicy.AllowCloudRecording)"
}
```

## 7. Security Scripts

### 7.1 Conditional Access Check
```powershell
function Get-ConditionalAccessStatus {
    # Get all policies
    $policies = Get-AzureADMSConditionalAccessPolicy
    
    foreach ($policy in $policies) {
        Write-Host "`nPolicy: $($policy.DisplayName)"
        Write-Host "State: $($policy.State)"
        Write-Host "Conditions:"
        Write-Host "Users: $($policy.Conditions.Users.IncludeUsers.Count) included, $($policy.Conditions.Users.ExcludeUsers.Count) excluded"
        Write-Host "Applications: $($policy.Conditions.Applications.IncludeApplications.Count) included"
    }
}
```

### 7.2 Security Alert Review
```powershell
function Get-SecurityAlertSummary {
    param(
        [int]$Days = 7
    )

    $startDate = (Get-Date).AddDays(-$Days)
    $alerts = Get-SecurityAlert -StartTime $startDate
    
    Write-Host "Security Alerts Summary (Last $Days days):"
    $alerts | Group-Object Category | ForEach-Object {
        Write-Host "`n$($_.Name): $($_.Count) alerts"
    }
}
```

## 8. Best Practices

### 8.1 Script Usage
1. Test in non-production first
2. Use error handling
3. Log operations
4. Document changes
5. Use secure credentials

### 8.2 Error Handling Example
```powershell
function Invoke-SafeCommand {
    param(
        [scriptblock]$Command
    )
    
    try {
        & $Command
    }
    catch {
        Write-Error "Error executing command: $_"
        Write-Error $_.ScriptStackTrace
    }
}
