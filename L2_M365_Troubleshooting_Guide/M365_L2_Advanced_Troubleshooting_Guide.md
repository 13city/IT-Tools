# Microsoft 365 Advanced Troubleshooting Guide for L2 Support
## Version 1.0

## Table of Contents
1. [Exchange Online Advanced Issues](#exchange-online-advanced-issues)
2. [SharePoint and OneDrive Complex Scenarios](#sharepoint-and-onedrive-complex-scenarios)
3. [Teams Advanced Troubleshooting](#teams-advanced-troubleshooting)
4. [Azure AD and Identity Management](#azure-ad-and-identity-management)
5. [Security and Compliance](#security-and-compliance)
6. [PowerShell Diagnostic Commands](#powershell-diagnostic-commands)
7. [Network Troubleshooting](#network-troubleshooting)
8. [Performance Optimization](#performance-optimization)

---

## Exchange Online Advanced Issues

### 1. Calendar Delegation and Permissions Issues

#### Problem: Calendar permissions not propagating or inconsistent behavior
**Advanced Diagnosis Steps:**
1. Check effective permissions using PowerShell:
```powershell
Get-MailboxFolderPermission -Identity user@domain.com:\Calendar
Get-CalendarProcessing -Identity user@domain.com
```

2. Verify calendar folder ID hasn't been corrupted:
```powershell
Get-MailboxFolderStatistics -Identity user@domain.com -FolderScope Calendar | Select FolderId, Name
```

**Solution Methods:**
1. Reset Calendar Folder Permissions:
```powershell
Remove-MailboxFolderPermission -Identity user@domain.com:\Calendar -User delegate@domain.com -Confirm:$false
Add-MailboxFolderPermission -Identity user@domain.com:\Calendar -User delegate@domain.com -AccessRights Editor
```

*Why this works:* Removes potentially corrupted permission entries and recreates them cleanly. The Exchange permission cache is cleared when permissions are completely removed and readded.

2. Rebuild Calendar Folder:
```powershell
New-MailboxRepairRequest -Mailbox user@domain.com -CorruptionType ProvisionedFolder
```

*Why this works:* Reconstructs the calendar folder's underlying structure while preserving appointments, fixing any corruption in the folder's attributes or hierarchy.

### 2. Message Transport and Routing Issues

#### Problem: NDRs with "550 5.7.64 TenantAttribution" or Similar
**Advanced Diagnosis:**
1. Check message trace with enhanced details:
```powershell
Get-MessageTrace -SenderAddress sender@domain.com -StartDate (Get-Date).AddHours(-24) | Get-MessageTraceDetail
```

2. Verify tenant configuration:
```powershell
Get-AcceptedDomain | Select DomainName, DomainType, Default
Get-TransportConfig | Select *GenerationLimit*
```

**Solution Methods:**
1. Reset Organization Transport Settings:
```powershell
Set-TransportConfig -MaxReceiveSize 25MB -MaxSendSize 25MB
Set-TransportService -MaxOutboundConnections 1000 -MaxPerDomainOutboundConnections 100
```

*Why this works:* Resets transport quotas and connection limits to default values, clearing any misconfigured or corrupted settings that might affect message routing.

2. Verify and Update DNS Records:
```powershell
Get-MxRecordReport -Domain domain.com | Format-List
```
Then update if needed:
- Ensure proper SPF record: "v=spf1 include:spf.protection.outlook.com -all"
- Verify DKIM is enabled and properly configured
- Check DMARC policy alignment

*Why this works:* Ensures proper email authentication and routing by maintaining correct DNS records, reducing the likelihood of messages being blocked or misrouted.

## SharePoint and OneDrive Complex Scenarios

### 1. Site Collection Performance Issues

#### Problem: Slow Site Performance with Large Lists/Libraries
**Advanced Diagnosis:**
1. Check site collection health:
```powershell
Get-SPOSite -Identity https://tenant.sharepoint.com/sites/sitename -Detailed | Select StorageQuota, StorageUsageCurrent, LockIssue
```

2. Analyze list thresholds:
```powershell
Get-SPOList -Identity "https://tenant.sharepoint.com/sites/sitename/lists/listname" | Select ItemCount, EnableThrottling
```

**Solution Methods:**
1. Implement Indexed Columns:
```powershell
$list = Get-PnPList -Identity "ListName"
Add-PnPField -List $list -DisplayName "IndexedColumn" -InternalName "IndexedColumn" -Type Text -AddToDefaultView
Set-PnPField -List $list -Identity "IndexedColumn" -Values @{Indexed=$true}
```

*Why this works:* Creates properly indexed columns that optimize query performance by creating a B-tree index structure, significantly reducing the time needed to locate items.

2. Enable List View Optimization:
```powershell
Set-PnPList -Identity "ListName" -EnableVersioning $true -EnableMinorVersions $false -MajorVersionLimit 50
```

*Why this works:* Reduces database load by limiting version history while maintaining necessary change tracking, improving overall performance.

## Teams Advanced Troubleshooting

### 1. Call Quality and Media Issues

#### Problem: Poor Call Quality or Media Stream Failures
**Advanced Diagnosis:**
1. Analyze call quality dashboard:
```powershell
$session = New-CsOnlineSession
Import-PSSession $session
Get-CsUserSession -UserUri "user@domain.com" -StartTime (Get-Date).AddDays(-7)
```

2. Check network configuration:
```powershell
Get-CsTenantNetworkConfiguration
Test-NetConnection -ComputerName "*.teams.microsoft.com" -Port 443
```

**Solution Methods:**
1. Optimize QoS Settings:
```powershell
New-CsTeamsQoSConfiguration -Identity Global -ApplyQoSToAllSites $true
Set-CsTeamsQoSConfiguration -Identity Global -AudioStreamPriority "High" -VideoStreamPriority "Medium"
```

*Why this works:* Implements proper Quality of Service tagging for Teams traffic, ensuring audio and video packets receive appropriate network prioritization.

2. Configure Media Optimization:
```powershell
Set-CsTeamsMeetingConfiguration -Identity Global -ClientVideoOptimizationLevel "Heavy"
Set-CsTeamsMediaConfiguration -Identity Global -MaxVideoResolution "HD1080p"
```

*Why this works:* Balances video quality with available bandwidth, preventing network congestion while maintaining acceptable video quality.

## Azure AD and Identity Management

### 1. Conditional Access and MFA Issues

#### Problem: Unexpected Access Denials or MFA Prompts
**Advanced Diagnosis:**
1. Check sign-in logs with detailed authentication steps:
```powershell
Get-AzureADAuditSignInLogs | Where-Object {$_.UserPrincipalName -eq "user@domain.com"} | Select CreatedDateTime, Status, ConditionalAccessStatus
```

2. Analyze CA policy evaluation:
```powershell
Get-AzureADMSConditionalAccessPolicy | Where-Object {$_.State -eq "enabled"} | Select DisplayName, Conditions
```

**Solution Methods:**
1. Implement Named Locations with MFA Bypass:
```powershell
$ipRanges = @("10.0.0.0/24", "192.168.1.0/24")
New-AzureADMSNamedLocationPolicy -DisplayName "Corporate Network" -IpRanges $ipRanges -IsTrusted $true
```

*Why this works:* Creates a trusted network definition that can be used in CA policies to bypass MFA requirements when users are on known, secure networks.

2. Configure Authentication Strength:
```powershell
New-AzureADMSAuthenticationStrengthPolicy -DisplayName "High Security" -AllowedAuthenticationMethodCombinations @("windowsHelloForBusiness","phoneAppNotification")
```

*Why this works:* Defines specific authentication method combinations that provide appropriate security levels while maintaining user convenience.

## Security and Compliance

### 1. Data Loss Prevention (DLP) Issues

#### Problem: False Positives or Missed Violations
**Advanced Diagnosis:**
1. Analyze DLP rule matches:
```powershell
Get-DlpDetailReport -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) | Where-Object {$_.PolicyName -eq "Policy Name"}
```

2. Check policy configuration:
```powershell
Get-DlpCompliancePolicy | Select Name, Mode, Priority
Get-DlpComplianceRule | Where-Object {$_.ParentPolicyName -eq "Policy Name"} | Select Name, ContentContainsSensitiveInformation
```

**Solution Methods:**
1. Implement Custom Sensitive Information Types:
```powershell
$customSIT = @{
    Name = "Custom Financial Data"
    Description = "Matches specific financial patterns"
    Pattern = @{
        Pattern = "(\b[A-Z]{2}\d{2}[ ]\d{4}[ ]\d{4}[ ]\d{4}[ ]\d{4}\b)"
        Type = "RegEx"
        ConfidenceLevel = "High"
    }
}
New-DlpSensitiveInformationType @customSIT
```

*Why this works:* Creates precisely targeted pattern matching that reduces false positives while maintaining detection accuracy for specific data types.

2. Configure Advanced DLP Rules:
```powershell
New-DlpComplianceRule -Policy "Policy Name" -Name "Advanced Rule" `
    -ContentContainsSensitiveInformation @{Name="Custom Financial Data"; MinCount=2} `
    -ExceptIfRecipientDomainIs "trusted-partner.com" `
    -GenerateAlert $true
```

*Why this works:* Combines multiple conditions and exceptions to create more accurate detection scenarios while allowing legitimate business communications.

## PowerShell Diagnostic Commands

### Essential Diagnostic Commands Collection

```powershell
# Comprehensive Exchange Online Diagnostics
Get-MailboxDatabaseCopyStatus
Get-Queue
Test-MAPIConnectivity
Test-OutlookWebServices
Get-LogonStatistics

# SharePoint Online Health Check
Test-SPOSite -Identity https://tenant.sharepoint.com/sites/sitename
Measure-SPOSite -Identity https://tenant.sharepoint.com/sites/sitename
Get-SPOSiteGroup -Site https://tenant.sharepoint.com/sites/sitename

# Teams Service Health
Get-CsOnlineUser -Identity user@domain.com | Select TeamsUpgradeEffectiveMode
Get-CsTenantNetworkSite
Get-CsOnlineVoiceRoute
```

## Network Troubleshooting

### 1. Advanced Network Connectivity Issues

#### Problem: Intermittent Connection Drops or Latency
**Advanced Diagnosis:**
1. Run comprehensive network tests:
```powershell
$endpoints = @(
    "outlook.office365.com",
    "teams.microsoft.com",
    "sharepoint.com"
)

foreach ($endpoint in $endpoints) {
    Test-NetConnection -ComputerName $endpoint -Port 443 -InformationLevel Detailed
    Resolve-DnsName -Name $endpoint -Type ALL
}
```

2. Check network routes and latency:
```powershell
tracert outlook.office365.com > network_trace.txt
Get-NetRoute | Where-Object {$_.DestinationPrefix -like "*.microsoft.com"} | Format-Table
```

**Solution Methods:**
1. Optimize TCP Settings:
```powershell
# Enable TCP Window Auto-Tuning
netsh int tcp set global autotuninglevel=normal
# Set TCP Keep-Alive Time
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "KeepAliveTime" -Value 30000
```

*Why this works:* Optimizes TCP window scaling and keep-alive settings to maintain stable connections and improve throughput for M365 services.

2. Implement Split Tunneling:
```powershell
# PowerShell script to configure split tunneling for M365 traffic
$m365Endpoints = Get-Content "M365_IP_Ranges.txt"
foreach ($endpoint in $m365Endpoints) {
    Route ADD $endpoint MASK 255.255.255.0 192.168.1.1 METRIC 1
}
```

*Why this works:* Routes M365 traffic directly to the internet instead of through the VPN tunnel, reducing latency and improving performance.

## Performance Optimization

### 1. Client-Side Performance Issues

#### Problem: Slow Client Application Performance
**Advanced Diagnosis:**
1. Analyze client health:
```powershell
Get-OfficeClickToRunConfiguration
Get-AppvClientPackage | Where-Object {$_.Name -like "*Microsoft*"}
```

2. Check system resources:
```powershell
Get-WmiObject Win32_LogicalDisk | Select DeviceID, Size, FreeSpace
Get-Counter '\Process(*)\% Processor Time' | Where-Object {$_.CounterSamples.InstanceName -like "*OUTLOOK*"}
```

**Solution Methods:**
1. Optimize Office Cache:
```powershell
# Clear and rebuild Office cache
Remove-Item "$env:LOCALAPPDATA\Microsoft\Office\16.0\OfficeFileCache\*" -Force -Recurse
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Common\General" -Name "MaxCacheSizeInMB" -Value 8192
```

*Why this works:* Removes potentially corrupted cache files and optimizes cache size for better performance while maintaining necessary temporary data.

2. Implement Registry Optimizations:
```powershell
# Registry optimizations for Office applications
$regPath = "HKCU:\Software\Microsoft\Office\16.0"
Set-ItemProperty -Path "$regPath\Common" -Name "EnableAutoSave" -Value 1
Set-ItemProperty -Path "$regPath\Outlook\AutoDiscover" -Name "ExcludeHttpRedirect" -Value 1
Set-ItemProperty -Path "$regPath\Common\Graphics" -Name "DisableHardwareAcceleration" -Value 0
```

*Why this works:* Configures optimal registry settings for auto-save, discovery, and hardware acceleration, improving overall application responsiveness.

---

## Best Practices for L2 Support

1. **Documentation and Tracking**
   - Maintain detailed incident logs
   - Document all PowerShell commands used and their outcomes
   - Track recurring issues for pattern analysis

2. **Escalation Guidelines**
   - Clear criteria for L3 escalation
   - Required information gathering before escalation
   - Communication templates for different scenarios

3. **Performance Monitoring**
   - Regular health checks implementation
   - Proactive monitoring setup
   - Baseline performance metrics establishment

4. **Security Considerations**
   - Least privilege principle enforcement
   - Audit logging enablement
   - Regular security review implementation

---

## Additional Resources

- Microsoft 365 Admin Center: https://admin.microsoft.com
- Microsoft 365 Service Health: https://status.office365.com
- Exchange Online PowerShell Reference: https://docs.microsoft.com/powershell/exchange
- SharePoint Online Management Shell: https://docs.microsoft.com/powershell/sharepoint
- Microsoft Teams PowerShell Reference: https://docs.microsoft.com/microsoftteams/teams-powershell-overview

---

*Note: This guide is intended for L2 support personnel with advanced PowerShell knowledge and deep understanding of Microsoft 365 services. Always test solutions in a non-production environment first.*
