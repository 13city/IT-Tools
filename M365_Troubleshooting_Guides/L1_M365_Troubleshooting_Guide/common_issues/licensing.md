# License Management Troubleshooting Guide for Microsoft 365

## 1. Initial Assessment

### 1.1 Client Questions
1. "What specific features or applications are you unable to access?"
   - Helps identify which licenses/services are affected
   - Examples: Teams, Exchange, SharePoint, specific Office apps

2. "What happens when you try to access these features?"
   - Specific error messages
   - License-related prompts
   - Access denied messages

3. "When did you first notice this issue?"
   - Timeline of the problem
   - Correlation with recent changes

### 1.2 Account Status Verification
1. License Type
   - E3, E5, Business Premium, etc.
   - Recently changed license types
   - Expected features

2. Account Changes
   - Department changes
   - Role modifications
   - Location changes
   - Title updates

3. Service Access
   - Working services
   - Affected services
   - Partial access issues

## 2. License Diagnostics

### 2.1 Check License Assignment
```powershell
# Check user license status
Get-MsolUser -UserPrincipalName user@domain.com | Select-Object Licenses

# Get detailed license information
Get-MsolUser -UserPrincipalName user@domain.com | Select-Object -ExpandProperty Licenses | 
    Select-Object AccountSkuId, ServiceStatus
```

### 2.2 Verify Service Plans
```powershell
# List all service plans
Get-MsolAccountSku | Select-Object AccountSkuId, ActiveUnits, ConsumedUnits

# Check specific service plan status
$user = Get-MsolUser -UserPrincipalName user@domain.com
$user.Licenses.ServiceStatus | Where-Object {$_.ProvisioningStatus -ne "Success"}
```

### 2.3 Group-Based Licensing
```powershell
# Check group membership
Get-AzureADUserMembership -ObjectId (Get-AzureADUser -ObjectId user@domain.com).ObjectId

# Verify group license assignment
Get-AzureADGroup -ObjectId <groupId> | Select-Object AssignedLicenses
```

## 3. Common Issues and Solutions

### 3.1 License Assignment Issues
1. Direct Assignment
```powershell
# Assign license directly
Set-MsolUserLicense -UserPrincipalName user@domain.com -AddLicenses "contoso:ENTERPRISEPACK"
```

2. Remove and Reassign
```powershell
# Remove existing license
Set-MsolUserLicense -UserPrincipalName user@domain.com -RemoveLicenses "contoso:ENTERPRISEPACK"

# Wait 60 seconds
Start-Sleep -Seconds 60

# Reassign license
Set-MsolUserLicense -UserPrincipalName user@domain.com -AddLicenses "contoso:ENTERPRISEPACK"
```

### 3.2 Service Plan Management
1. Disable Specific Services
```powershell
# Get current license options
$user = Get-MsolUser -UserPrincipalName user@domain.com
$SKU = $user.Licenses[0].AccountSkuId
$Disabled = @("YAMMER_ENTERPRISE")

# Create license options
$LO = New-MsolLicenseOptions -AccountSkuId $SKU -DisabledPlans $Disabled

# Apply license options
Set-MsolUserLicense -UserPrincipalName user@domain.com -LicenseOptions $LO
```

2. Enable All Services
```powershell
# Enable all service plans
$LO = New-MsolLicenseOptions -AccountSkuId $SKU -DisabledPlans @()
Set-MsolUserLicense -UserPrincipalName user@domain.com -LicenseOptions $LO
```

## 4. Advanced Troubleshooting

### 4.1 License Inventory
```powershell
# Get license inventory report
$report = @()
Get-MsolAccountSku | ForEach-Object {
    $report += [PSCustomObject]@{
        License = $_.AccountSkuId
        Total = $_.ActiveUnits
        Assigned = $_.ConsumedUnits
        Available = $_.ActiveUnits - $_.ConsumedUnits
    }
}
$report | Format-Table -AutoSize
```

### 4.2 Service Plan Analysis
```powershell
# Analyze service plan status across users
$users = Get-MsolUser -All
$serviceStatus = @()
foreach ($user in $users) {
    if ($user.IsLicensed) {
        foreach ($license in $user.Licenses) {
            foreach ($service in $license.ServiceStatus) {
                $serviceStatus += [PSCustomObject]@{
                    User = $user.UserPrincipalName
                    Service = $service.ServicePlan.ServiceName
                    Status = $service.ProvisioningStatus
                }
            }
        }
    }
}
$serviceStatus | Group-Object Service, Status | Select-Object Count, Name
```

## 5. License Management Best Practices

### 5.1 Regular Auditing
1. License Usage Review
```powershell
# Get license usage report
$usage = Get-MsolAccountSku | Select-Object AccountSkuId,
    @{Name="Assigned";Expression={$_.ConsumedUnits}},
    @{Name="Available";Expression={$_.ActiveUnits - $_.ConsumedUnits}}
$usage | Format-Table -AutoSize
```

2. Inactive User Review
```powershell
# Find licensed users who haven't signed in recently
$cutoffDate = (Get-Date).AddDays(-90)
Get-MsolUser -All | Where-Object {
    $_.IsLicensed -and $_.LastDirSyncTime -lt $cutoffDate
} | Select-Object UserPrincipalName, LastDirSyncTime
```

### 5.2 Group-Based Assignment
1. Create License Group
```powershell
# Create new group for license assignment
New-AzureADGroup -DisplayName "E3 License Group" -MailEnabled $false -SecurityEnabled $true -MailNickName "E3LicenseGroup"
```

2. Configure Group License
```powershell
# Assign license to group
$groupId = (Get-AzureADGroup -SearchString "E3 License Group").ObjectId
Set-AzureADGroup -ObjectId $groupId -AssignedLicenses $licenseAssignment
```

## 6. Documentation Requirements

### 6.1 License Documentation
- License types and quantities
- Assignment methods
- Group configurations
- Service plan customizations
- Special configurations

### 6.2 Change Documentation
- License modifications
- Group membership changes
- Service plan adjustments
- Policy updates
- Assignment methods

## 7. Preventive Measures

### 7.1 Monitoring
1. Set up alerts for:
   - License threshold reached
   - Assignment failures
   - Group membership changes
   - Service plan status

2. Regular reporting on:
   - License usage
   - Unassigned licenses
   - Failed assignments
   - Group-based licensing

### 7.2 Best Practices
1. License Management
   - Use group-based licensing
   - Regular usage reviews
   - Documented procedures
   - Clear ownership

2. User Management
   - Onboarding procedures
   - Offboarding checklist
   - Regular access reviews
   - License optimization

## 8. Escalation Procedures

### 8.1 When to Escalate
- Bulk assignment failures
- Service plan errors
- Group licensing issues
- Tenant-wide problems
- Complex configurations

### 8.2 Required Information
- License details
- Error messages
- Assignment method
- Recent changes
- Impact assessment

## 9. Additional Resources

### 9.1 Microsoft Tools
- Microsoft 365 Admin Center
- Azure AD Admin Center
- License Management Portal
- Group Management Tools
- PowerShell Modules

### 9.2 Documentation
- Microsoft 365 Licensing Guide
- Service Plan Reference
- PowerShell Commands Reference
- Group-Based Licensing Guide
- Troubleshooting Guide
