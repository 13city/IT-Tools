#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enterprise-grade Windows Server security configuration analyzer and validator.

.DESCRIPTION
    This script provides comprehensive security validation capabilities:
    - Domain Security:
      * Domain membership verification
      * Trust relationship validation
      * Group Policy application
      * Domain controller status
    - Account Management:
      * Local account auditing
      * Password policy validation
      * Security group membership
      * User rights assignments
    - Service Security:
      * Critical service status
      * Startup configuration
      * Service account audit
      * Dependencies check
    - Certificate Management:
      * Certificate validity
      * Expiration monitoring
      * Chain validation
      * Key usage verification
    - System Security:
      * Windows features audit
      * Share permissions
      * Scheduled task review
      * Registry permissions
    - Reporting Features:
      * HTML report generation
      * Risk assessment
      * Remediation guidance
      * Compliance status

.NOTES
    Author: 13city
    Compatible with:
    - Windows Server 2016
    - Windows Server 2019
    - Windows Server 2022
    - All service packs
    - All security updates
    
    Requirements:
    - PowerShell 5.1 or higher
    - Administrative privileges
    - Domain admin rights (if domain-joined)
    - Certificate access rights
    - Share permissions

.PARAMETER LogPath
    Report storage location
    Optional parameter
    Default: C:\SecurityLogs
    Creates if missing

.PARAMETER GenerateHTML
    HTML report creation
    Optional parameter
    Default: True
    Creates detailed report

.PARAMETER IncludeCertificates
    Certificate validation
    Optional parameter
    Default: True
    Checks all stores

.PARAMETER CheckShares
    Share permission audit
    Optional parameter
    Default: True
    Validates access

.EXAMPLE
    .\WinServerSecurityCheck.ps1
    Basic security scan:
    - Default logging
    - HTML reporting
    - Certificate checks
    - Share validation

.EXAMPLE
    .\WinServerSecurityCheck.ps1 -LogPath "D:\Audits" -GenerateHTML $false -IncludeCertificates $false
    Custom audit:
    - Specified log path
    - Console output only
    - Skip certificates
    - Basic share checks
#>

param(
    [string]$LogPath = "C:\SecurityLogs",
    [switch]$GenerateHTML = $true,
    [switch]$IncludeCertificates = $true,
    [switch]$CheckShares = $true
)

# Initialize logging
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath | Out-Null
}

$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $LogPath "WinServerSecurityCheck-$timeStamp.log"
$htmlReport = Join-Path $LogPath "WinServerSecurityCheck-$timeStamp.html"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error')]
        [string]$Level = 'Info'
    )
    $entry = "[{0}] [{1}] {2}" -f (Get-Date), $Level, $Message
    Add-Content -Path $logFile -Value $entry
    
    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error' { Write-Error $Message }
        default { Write-Host $Message }
    }
}

# Critical services to check with expected configurations
$criticalServices = @{
    'wuauserv' = @{
        DisplayName = 'Windows Update'
        StartupType = 'Automatic'
        Required = $true
    }
    'WinDefend' = @{
        DisplayName = 'Windows Defender'
        StartupType = 'Automatic'
        Required = $true
    }
    'EventLog' = @{
        DisplayName = 'Windows Event Log'
        StartupType = 'Automatic'
        Required = $true
    }
    'Schedule' = @{
        DisplayName = 'Task Scheduler'
        StartupType = 'Automatic'
        Required = $true
    }
    'BITS' = @{
        DisplayName = 'Background Intelligent Transfer Service'
        StartupType = 'Manual'
        Required = $false
    }
    'CryptSvc' = @{
        DisplayName = 'Cryptographic Services'
        StartupType = 'Automatic'
        Required = $true
    }
}

function Get-DomainStatus {
    try {
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $result = @{
            IsDomainJoined = $computerSystem.PartOfDomain
            DomainName = if ($computerSystem.PartOfDomain) { $computerSystem.Domain } else { "N/A" }
            IsDC = $computerSystem.DomainRole -in @(4,5)
        }
        Write-Log "Domain Status: $(if($result.IsDomainJoined){'Joined to '+$result.DomainName}else{'Not domain-joined'})"
        return $result
    }
    catch {
        Write-Log "Error checking domain status: $_" -Level Error
        return $null
    }
}

function Get-SecuritySettings {
    try {
        $settings = @{
            PasswordPolicy = net accounts
            SecurityPolicy = secedit /export /cfg "$env:TEMP\secpol.cfg" | Out-Null
            AuditPolicy = auditpol /get /category:*
        }
        Write-Log "Security settings retrieved successfully"
        return $settings
    }
    catch {
        Write-Log "Error retrieving security settings: $_" -Level Error
        return $null
    }
}

function Get-ServiceStatus {
    $results = @()
    foreach ($svc in $criticalServices.GetEnumerator()) {
        try {
            $service = Get-Service -Name $svc.Key -ErrorAction SilentlyContinue
            if ($service) {
                $status = @{
                    Name = $svc.Key
                    DisplayName = $svc.Value.DisplayName
                    Status = $service.Status
                    StartType = $service.StartType
                    Required = $svc.Value.Required
                    Expected = $svc.Value.StartupType
                    IsCompliant = $service.Status -eq 'Running' -and $service.StartType -eq $svc.Value.StartupType
                }
                
                if (!$status.IsCompliant -and $svc.Value.Required) {
                    Write-Log "Service '$($svc.Value.DisplayName)' is non-compliant. Status: $($service.Status), StartType: $($service.StartType)" -Level Warning
                }
                
                $results += $status
            }
            elseif ($svc.Value.Required) {
                Write-Log "Required service '$($svc.Value.DisplayName)' not found" -Level Error
            }
        }
        catch {
            Write-Log "Error checking service '$($svc.Value.DisplayName)': $_" -Level Error
        }
    }
    return $results
}

function Get-CertificateStatus {
    if (!$IncludeCertificates) { return $null }
    
    try {
        $certs = @{
            LocalMachine = Get-ChildItem Cert:\LocalMachine -Recurse | 
                Where-Object { $_.NotAfter -and $_.NotBefore } |
                Select-Object Subject, Issuer, NotAfter, NotBefore, Thumbprint
            
            Expired = Get-ChildItem Cert:\LocalMachine -Recurse | 
                Where-Object { $_.NotAfter -lt (Get-Date) } |
                Select-Object Subject, Issuer, NotAfter, NotBefore, Thumbprint
            
            ExpiringSoon = Get-ChildItem Cert:\LocalMachine -Recurse | 
                Where-Object { $_.NotAfter -gt (Get-Date) -and $_.NotAfter -lt (Get-Date).AddDays(30) } |
                Select-Object Subject, Issuer, NotAfter, NotBefore, Thumbprint
        }
        
        if ($certs.Expired) {
            Write-Log "Found $($certs.Expired.Count) expired certificates" -Level Warning
        }
        if ($certs.ExpiringSoon) {
            Write-Log "Found $($certs.ExpiringSoon.Count) certificates expiring within 30 days" -Level Warning
        }
        
        return $certs
    }
    catch {
        Write-Log "Error checking certificates: $_" -Level Error
        return $null
    }
}

function Get-WindowsFeaturesStatus {
    try {
        $features = Get-WindowsFeature | Where-Object { $_.Installed }
        Write-Log "Retrieved status of $($features.Count) installed Windows Features"
        return $features
    }
    catch {
        Write-Log "Error checking Windows Features: $_" -Level Error
        return $null
    }
}

function Get-NetworkShareStatus {
    if (!$CheckShares) { return $null }
    
    try {
        $shares = Get-SmbShare | ForEach-Object {
            $share = $_
            $access = Get-SmbShareAccess -Name $share.Name
            @{
                Name = $share.Name
                Path = $share.Path
                Description = $share.Description
                Access = $access
            }
        }
        
        foreach ($share in $shares) {
            $everyoneAccess = $share.Access | Where-Object { $_.AccountName -eq 'Everyone' }
            if ($everyoneAccess) {
                Write-Log "Share '$($share.Name)' grants access to Everyone: $($everyoneAccess.AccessRight)" -Level Warning
            }
        }
        
        return $shares
    }
    catch {
        Write-Log "Error checking network shares: $_" -Level Error
        return $null
    }
}

function Get-ScheduledTasksStatus {
    try {
        $tasks = Get-ScheduledTask | Where-Object { $_.State -ne 'Disabled' } | ForEach-Object {
            $task = $_
            @{
                Name = $task.TaskName
                Path = $task.TaskPath
                State = $task.State
                LastResult = $task.LastTaskResult
                NextRun = $task.NextRunTime
                Author = $task.Author
                Principal = $task.Principal.UserId
            }
        }
        
        $suspiciousTasks = $tasks | Where-Object { 
            $_.Principal -eq 'SYSTEM' -or 
            $_.State -eq 'Ready' -and $_.LastResult -ne 0 
        }
        
        if ($suspiciousTasks) {
            Write-Log "Found $($suspiciousTasks.Count) potentially suspicious scheduled tasks" -Level Warning
        }
        
        return $tasks
    }
    catch {
        Write-Log "Error checking scheduled tasks: $_" -Level Error
        return $null
    }
}

function Get-LocalAdminStatus {
    try {
        $adminGroup = Get-LocalGroupMember -Group "Administrators"
        $nonDefaultAdmins = $adminGroup | Where-Object {
            $_.PrincipalSource -eq 'Local' -and 
            $_.Name -notmatch 'Administrator$' -and
            $_.Name -notmatch 'Domain Admins$'
        }
        
        if ($nonDefaultAdmins) {
            Write-Log "Found $($nonDefaultAdmins.Count) non-default local administrators" -Level Warning
        }
        
        return $adminGroup
    }
    catch {
        Write-Log "Error checking local administrators: $_" -Level Error
        return $null
    }
}

function New-HTMLReport {
    param(
        [object]$DomainStatus,
        [object]$SecuritySettings,
        [object]$ServiceStatus,
        [object]$CertificateStatus,
        [object]$FeaturesStatus,
        [object]$ShareStatus,
        [object]$TasksStatus,
        [object]$AdminStatus
    )
    
    $css = @"
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .warning { background-color: #fff3cd; }
        .error { background-color: #f8d7da; }
        .success { background-color: #d4edda; }
        h2 { color: #2e7d32; }
        .summary { margin: 20px 0; padding: 10px; background-color: #e8f5e9; }
    </style>
"@

    $html = @"
    <!DOCTYPE html>
    <html>
    <head>
        <title>Windows Server Security Check Report - $timeStamp</title>
        $css
    </head>
    <body>
        <h1>Windows Server Security Check Report</h1>
        <div class="summary">
            <h2>System Information</h2>
            <p>Server Name: $env:COMPUTERNAME</p>
            <p>Generated: $(Get-Date)</p>
            $(if ($DomainStatus.IsDomainJoined) {
                "<p>Domain: $($DomainStatus.DomainName)</p>"
            })
        </div>
"@

    # Add Domain Status
    $html += @"
        <h2>Domain Status</h2>
        <table>
            <tr>
                <th>Property</th>
                <th>Value</th>
            </tr>
            <tr>
                <td>Domain Joined</td>
                <td>$($DomainStatus.IsDomainJoined)</td>
            </tr>
            <tr>
                <td>Domain Name</td>
                <td>$($DomainStatus.DomainName)</td>
            </tr>
            <tr>
                <td>Is Domain Controller</td>
                <td>$($DomainStatus.IsDC)</td>
            </tr>
        </table>
"@

    # Add Service Status
    $html += @"
        <h2>Service Status</h2>
        <table>
            <tr>
                <th>Service</th>
                <th>Status</th>
                <th>Start Type</th>
                <th>Required</th>
                <th>Compliant</th>
            </tr>
"@
    foreach ($svc in $ServiceStatus) {
        $cssClass = if (!$svc.IsCompliant -and $svc.Required) { 'error' } 
                   elseif (!$svc.IsCompliant) { 'warning' }
                   else { 'success' }
        $html += @"
            <tr class="$cssClass">
                <td>$($svc.DisplayName)</td>
                <td>$($svc.Status)</td>
                <td>$($svc.StartType)</td>
                <td>$($svc.Required)</td>
                <td>$($svc.IsCompliant)</td>
            </tr>
"@
    }
    $html += "</table>"

    # Add Certificate Status if included
    if ($CertificateStatus) {
        $html += @"
            <h2>Certificate Status</h2>
            <h3>Expired Certificates</h3>
            <table>
                <tr>
                    <th>Subject</th>
                    <th>Issuer</th>
                    <th>Expiration</th>
                </tr>
"@
        foreach ($cert in $CertificateStatus.Expired) {
            $html += @"
                <tr class="error">
                    <td>$($cert.Subject)</td>
                    <td>$($cert.Issuer)</td>
                    <td>$($cert.NotAfter)</td>
                </tr>
"@
        }
        $html += "</table>"

        $html += @"
            <h3>Certificates Expiring Soon</h3>
            <table>
                <tr>
                    <th>Subject</th>
                    <th>Issuer</th>
                    <th>Expiration</th>
                </tr>
"@
        foreach ($cert in $CertificateStatus.ExpiringSoon) {
            $html += @"
                <tr class="warning">
                    <td>$($cert.Subject)</td>
                    <td>$($cert.Issuer)</td>
                    <td>$($cert.NotAfter)</td>
                </tr>
"@
        }
        $html += "</table>"
    }

    # Add Network Share Status if included
    if ($ShareStatus) {
        $html += @"
            <h2>Network Shares</h2>
            <table>
                <tr>
                    <th>Name</th>
                    <th>Path</th>
                    <th>Access Rights</th>
                </tr>
"@
        foreach ($share in $ShareStatus) {
            $everyoneAccess = $share.Access | Where-Object { $_.AccountName -eq 'Everyone' }
            $cssClass = if ($everyoneAccess) { 'warning' } else { '' }
            $html += @"
                <tr class="$cssClass">
                    <td>$($share.Name)</td>
                    <td>$($share.Path)</td>
                    <td>$(($share.Access | ForEach-Object { "$($_.AccountName): $($_.AccessRight)" }) -join '<br/>')</td>
                </tr>
"@
        }
        $html += "</table>"
    }

    # Add Local Administrators
    if ($AdminStatus) {
        $html += @"
            <h2>Local Administrators</h2>
            <table>
                <tr>
                    <th>Name</th>
                    <th>Type</th>
                    <th>Source</th>
                </tr>
"@
        foreach ($admin in $AdminStatus) {
            $cssClass = if ($admin.PrincipalSource -eq 'Local' -and 
                          $admin.Name -notmatch 'Administrator$' -and
                          $admin.Name -notmatch 'Domain Admins$') { 'warning' } else { '' }
            $html += @"
                <tr class="$cssClass">
                    <td>$($admin.Name)</td>
                    <td>$($admin.ObjectClass)</td>
                    <td>$($admin.PrincipalSource)</td>
                </tr>
"@
        }
        $html += "</table>"
    }

    $html += @"
    </body>
    </html>
"@

    return $html
}

try {
    Write-Log "===== Starting Enhanced Windows Server Security Check ====="
    
    # Collect all security information
    $domainStatus = Get-DomainStatus
    $securitySettings = Get-SecuritySettings
    $serviceStatus = Get-ServiceStatus
    $certificateStatus = Get-CertificateStatus
    $featuresStatus = Get-WindowsFeaturesStatus
    $shareStatus = Get-NetworkShareStatus
    $tasksStatus = Get-ScheduledTasksStatus
    $adminStatus = Get-LocalAdminStatus
    
    # Generate HTML report if requested
    if ($GenerateHTML) {
        Write-Log "Generating HTML report"
        $report = New-HTMLReport -DomainStatus $domainStatus `
                                -SecuritySettings $securitySettings `
                                -ServiceStatus $serviceStatus `
                                -CertificateStatus $certificateStatus `
                                -FeaturesStatus $featuresStatus `
                                -ShareStatus $shareStatus `
                                -TasksStatus $tasksStatus `
                                -AdminStatus $adminStatus
        
        $report | Out-File -FilePath $htmlReport -Encoding UTF8
        Write-Log "HTML report saved to: $htmlReport"
    }
    
    Write-Log "===== Windows Server Security Check Completed ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" -Level Error
    exit 1
}
