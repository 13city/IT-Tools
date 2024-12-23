# Active Directory Health Monitor and Maintenance Script
# This script performs comprehensive AD health checks and maintenance tasks

param (
    [Parameter(Mandatory=$false)]
    [string]$DomainController = $env:COMPUTERNAME,
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "$env:USERPROFILE\Desktop\AD-HealthReport.html",
    [Parameter(Mandatory=$false)]
    [int]$MaxPasswordAge = 90,
    [Parameter(Mandatory=$false)]
    [int]$InactiveDays = 30,
    [Parameter(Mandatory=$false)]
    [switch]$FixIssues
)

# Import required modules
Import-Module ActiveDirectory

# Function to test DC connectivity and services
function Test-DomainController {
    param (
        [string]$DCName
    )
    
    try {
        $services = @(
            "NTDS",          # AD DS
            "DFSR",          # DFS Replication
            "DNS",           # DNS Server
            "KDC",           # Kerberos Key Distribution Center
            "NetLogon"       # Net Logon
        )
        
        $results = foreach ($service in $services) {
            $svc = Get-Service -ComputerName $DCName -Name $service -ErrorAction SilentlyContinue
            [PSCustomObject]@{
                ServiceName = $service
                Status = $svc.Status
                StartType = $svc.StartType
            }
        }
        
        # Test LDAP connectivity
        $null = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$DCName")
        
        return $results
    }
    catch {
        Write-Error "Failed to connect to Domain Controller $DCName : $_"
        return $null
    }
}

# Function to check AD replication status
function Get-ADReplicationStatus {
    try {
        $results = Get-ADReplicationPartnerMetadata -Target * -Scope Server |
            Select-Object Server, Partner, LastReplicationSuccess, LastReplicationResult, ConsecutiveReplicationFailures
        
        return $results
    }
    catch {
        Write-Error "Failed to get replication status: $_"
        return $null
    }
}

# Function to check FSMO roles
function Get-FSMORoles {
    try {
        $roles = Get-ADDomain | Select-Object InfrastructureMaster, RIDMaster, PDCEmulator
        $forestRoles = Get-ADForest | Select-Object DomainNamingMaster, SchemaMaster
        
        return [PSCustomObject]@{
            InfrastructureMaster = $roles.InfrastructureMaster
            RIDMaster = $roles.RIDMaster
            PDCEmulator = $roles.PDCEmulator
            DomainNamingMaster = $forestRoles.DomainNamingMaster
            SchemaMaster = $forestRoles.SchemaMaster
        }
    }
    catch {
        Write-Error "Failed to get FSMO roles: $_"
        return $null
    }
}

# Function to check DNS health
function Test-DNSHealth {
    param (
        [string]$DCName
    )
    
    try {
        $results = @()
        
        # Check DNS service
        $dnsService = Get-Service -ComputerName $DCName -Name DNS
        $results += [PSCustomObject]@{
            Check = "DNS Service"
            Status = $dnsService.Status
            Details = "DNS Server service status"
        }
        
        # Check DNS zones
        $zones = Get-DnsServerZone -ComputerName $DCName
        foreach ($zone in $zones) {
            $results += [PSCustomObject]@{
                Check = "Zone: $($zone.ZoneName)"
                Status = $zone.ZoneType
                Details = "Records: $($zone.RecordCount)"
            }
        }
        
        # Check SRV records
        $dcSrvRecords = Get-DnsServerResourceRecord -ComputerName $DCName -ZoneName $env:USERDNSDOMAIN -RRType SRV
        $results += [PSCustomObject]@{
            Check = "DC SRV Records"
            Status = if ($dcSrvRecords) { "Present" } else { "Missing" }
            Details = "Count: $($dcSrvRecords.Count)"
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to check DNS health: $_"
        return $null
    }
}

# Function to check AD database and log files
function Test-ADDatabase {
    param (
        [string]$DCName
    )
    
    try {
        $ntdsPath = Invoke-Command -ComputerName $DCName -ScriptBlock {
            $ntdsParams = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters"
            return $ntdsParams."DSA Database file"
        }
        
        $dbPath = Split-Path $ntdsPath -Parent
        $results = Invoke-Command -ComputerName $DCName -ScriptBlock {
            param($path)
            
            $files = Get-ChildItem $path -Filter "*.dit*"
            $logs = Get-ChildItem $path -Filter "*.log"
            
            return [PSCustomObject]@{
                DatabaseSize = (Get-Item "$path\ntds.dit").Length
                LogFiles = $logs.Count
                LogSize = ($logs | Measure-Object Length -Sum).Sum
                FreeSpace = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -eq (Split-Path $path -Qualifier) }).Free
            }
        } -ArgumentList $dbPath
        
        return $results
    }
    catch {
        Write-Error "Failed to check AD database: $_"
        return $null
    }
}

# Function to check account issues
function Get-AccountIssues {
    try {
        $results = @()
        
        # Check expired accounts
        $expiredAccounts = Search-ADAccount -AccountExpired
        $results += [PSCustomObject]@{
            Check = "Expired Accounts"
            Count = $expiredAccounts.Count
            Details = "Accounts that have expired"
        }
        
        # Check locked accounts
        $lockedAccounts = Search-ADAccount -LockedOut
        $results += [PSCustomObject]@{
            Check = "Locked Accounts"
            Count = $lockedAccounts.Count
            Details = "Accounts that are locked out"
        }
        
        # Check password expired
        $pwdExpired = Search-ADAccount -PasswordExpired
        $results += [PSCustomObject]@{
            Check = "Password Expired"
            Count = $pwdExpired.Count
            Details = "Accounts with expired passwords"
        }
        
        # Check inactive accounts
        $inactiveDate = (Get-Date).AddDays(-$InactiveDays)
        $inactiveAccounts = Get-ADUser -Filter {LastLogonTimeStamp -lt $inactiveDate} -Properties LastLogonTimeStamp
        $results += [PSCustomObject]@{
            Check = "Inactive Accounts"
            Count = $inactiveAccounts.Count
            Details = "Accounts inactive for $InactiveDays days"
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to check account issues: $_"
        return $null
    }
}

# Function to check Group Policy status
function Test-GroupPolicy {
    try {
        $results = @()
        
        # Get GPO status
        $gpos = Get-GPO -All
        foreach ($gpo in $gpos) {
            $results += [PSCustomObject]@{
                Name = $gpo.DisplayName
                Status = $gpo.GpoStatus
                UserVersion = $gpo.UserVersion
                ComputerVersion = $gpo.ComputerVersion
                CreationTime = $gpo.CreationTime
                ModificationTime = $gpo.ModificationTime
            }
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to check Group Policy status: $_"
        return $null
    }
}

# Function to fix common issues
function Repair-ADIssues {
    param (
        [object]$AccountIssues
    )
    
    try {
        $fixed = @()
        
        # Unlock accounts
        $lockedAccounts = Search-ADAccount -LockedOut
        foreach ($account in $lockedAccounts) {
            Unlock-ADAccount -Identity $account.SamAccountName
            $fixed += "Unlocked account: $($account.SamAccountName)"
        }
        
        # Enable inactive accounts that should be active
        $inactiveDate = (Get-Date).AddDays(-$InactiveDays)
        $inactiveAccounts = Get-ADUser -Filter {LastLogonTimeStamp -lt $inactiveDate -and Enabled -eq $false} -Properties LastLogonTimeStamp
        foreach ($account in $inactiveAccounts) {
            Enable-ADAccount -Identity $account.SamAccountName
            $fixed += "Enabled account: $($account.SamAccountName)"
        }
        
        return $fixed
    }
    catch {
        Write-Error "Failed to fix AD issues: $_"
        return $null
    }
}

# Function to generate HTML report
function New-HTMLReport {
    param (
        [object]$DCHealth,
        [object]$ReplicationStatus,
        [object]$FSMORoles,
        [object]$DNSHealth,
        [object]$DatabaseStatus,
        [object]$AccountIssues,
        [object]$GPOStatus,
        [object]$FixedIssues
    )

    $html = @"
    <!DOCTYPE html>
    <html>
    <head>
        <title>Active Directory Health Report</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #4CAF50; color: white; }
            tr:nth-child(even) { background-color: #f2f2f2; }
            h2 { color: #4CAF50; }
            .warning { background-color: #fff3cd; }
            .critical { background-color: #f8d7da; }
        </style>
    </head>
    <body>
        <h1>Active Directory Health Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</h1>
        
        <h2>Domain Controller Health</h2>
        $($DCHealth | ConvertTo-Html -Fragment)
        
        <h2>Replication Status</h2>
        $($ReplicationStatus | ConvertTo-Html -Fragment)
        
        <h2>FSMO Roles</h2>
        $($FSMORoles | ConvertTo-Html -Fragment)
        
        <h2>DNS Health</h2>
        $($DNSHealth | ConvertTo-Html -Fragment)
        
        <h2>Database Status</h2>
        $($DatabaseStatus | ConvertTo-Html -Fragment)
        
        <h2>Account Issues</h2>
        $($AccountIssues | ConvertTo-Html -Fragment)
        
        <h2>Group Policy Status</h2>
        $($GPOStatus | ConvertTo-Html -Fragment)
        
        $(if ($FixedIssues) {
            "<h2>Fixed Issues</h2>
            $($FixedIssues | ConvertTo-Html -Fragment)"
        })
    </body>
    </html>
"@

    return $html
}

# Main execution
try {
    Write-Host "Starting Active Directory health check..."
    
    # Check DC health
    $dcHealth = Test-DomainController -DCName $DomainController
    Write-Host "Domain Controller health check completed"
    
    # Check replication
    $replicationStatus = Get-ADReplicationStatus
    Write-Host "Replication status check completed"
    
    # Check FSMO roles
    $fsmoRoles = Get-FSMORoles
    Write-Host "FSMO roles check completed"
    
    # Check DNS
    $dnsHealth = Test-DNSHealth -DCName $DomainController
    Write-Host "DNS health check completed"
    
    # Check database
    $databaseStatus = Test-ADDatabase -DCName $DomainController
    Write-Host "Database check completed"
    
    # Check accounts
    $accountIssues = Get-AccountIssues
    Write-Host "Account issues check completed"
    
    # Check Group Policy
    $gpoStatus = Test-GroupPolicy
    Write-Host "Group Policy check completed"
    
    # Fix issues if requested
    $fixedIssues = $null
    if ($FixIssues) {
        $fixedIssues = Repair-ADIssues -AccountIssues $accountIssues
        Write-Host "Issue remediation completed"
    }
    
    # Generate and save report
    $report = New-HTMLReport -DCHealth $dcHealth `
                            -ReplicationStatus $replicationStatus `
                            -FSMORoles $fsmoRoles `
                            -DNSHealth $dnsHealth `
                            -DatabaseStatus $databaseStatus `
                            -AccountIssues $accountIssues `
                            -GPOStatus $gpoStatus `
                            -FixedIssues $fixedIssues
    
    $report | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Health report generated successfully at: $ReportPath"
    
    # Output critical warnings
    if ($accountIssues.Where({$_.Check -eq "Locked Accounts"}).Count -gt 0) {
        Write-Warning "There are locked accounts that need attention"
    }
    
    if ($replicationStatus.Where({$_.LastReplicationResult -ne 0}).Count -gt 0) {
        Write-Warning "Replication errors detected"
    }
    
    $criticalServices = $dcHealth.Where({$_.Status -ne "Running"})
    if ($criticalServices) {
        Write-Warning "Critical services are not running: $($criticalServices.ServiceName -join ', ')"
    }
}
catch {
    Write-Error "An error occurred during health check: $_"
}
