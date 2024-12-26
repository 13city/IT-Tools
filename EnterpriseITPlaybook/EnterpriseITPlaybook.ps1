#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory, GroupPolicy, DnsServer

<#
.SYNOPSIS
    Enterprise IT Operations Playbook for Windows Environments
.DESCRIPTION
    Comprehensive IT management toolkit for Windows enterprise environments.
    Includes system health monitoring, security checks, maintenance tasks,
    and automated reporting capabilities.
.NOTES
    Version: 2.0
    Author: Enterprise IT Team
#>

# Initialize Environment
$Script:LogPath = "$env:ProgramData\EnterpriseITPlaybook"
$Script:LogFile = "$LogPath\Operations_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$Script:ReportPath = "$LogPath\Reports"
$Script:ConfigPath = "$LogPath\Config"

# Create required directories
@($LogPath, $ReportPath, $ConfigPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# Enhanced Logging Function
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error','Critical','Success')]$Level = 'Info',
        [switch]$NoConsole
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    
    if (-not $NoConsole) {
        $Color = switch ($Level) {
            'Info'     { 'White' }
            'Warning'  { 'Yellow' }
            'Error'    { 'Red' }
            'Critical' { 'Red' }
            'Success'  { 'Green' }
        }
        Write-Host $LogMessage -ForegroundColor $Color
    }
}

# Active Directory Health Check
function Test-ADHealth {
    param([switch]$Detailed)
    
    Write-Log "Starting Active Directory health check..."
    $Issues = @()
    
    # Check DC Status
    try {
        $DCs = Get-ADDomainController -Filter *
        foreach ($DC in $DCs) {
            $Connectivity = Test-NetConnection -ComputerName $DC.HostName -Port 389 -WarningAction SilentlyContinue
            if (-not $Connectivity.TcpTestSucceeded) {
                $Issues += "Connectivity failed to DC: $($DC.HostName)"
            }
            
            # Check Services
            $Services = @('NTDS', 'DNS', 'Netlogon', 'W32Time')
            $ServiceStatus = Invoke-Command -ComputerName $DC.HostName -ScriptBlock {
                param($Services)
                Get-Service -Name $Services
            } -ArgumentList $Services -ErrorAction SilentlyContinue
            
            $StoppedServices = $ServiceStatus | Where-Object Status -ne 'Running'
            if ($StoppedServices) {
                $Issues += "Stopped services on $($DC.HostName): $($StoppedServices.Name -join ', ')"
            }
        }
    }
    catch {
        $Issues += "Error checking DC status: $_"
    }
    
    # Check Replication
    try {
        $Replication = Get-ADReplicationPartnerMetadata -Target * -Scope Server
        $FailingReplications = $Replication | Where-Object LastReplicationResult -ne 0
        if ($FailingReplications) {
            $Issues += "Replication failures detected: $($FailingReplications.Partner -join ', ')"
        }
    }
    catch {
        $Issues += "Error checking replication: $_"
    }
    
    # Check FSMO Roles
    try {
        $FSMORoles = Get-ADDomain | Select-Object PDCEmulator, RIDMaster, InfrastructureMaster
        $FSMORoles += Get-ADForest | Select-Object DomainNamingMaster, SchemaMaster
        
        foreach ($Role in $FSMORoles.PSObject.Properties) {
            $Connectivity = Test-NetConnection -ComputerName $Role.Value -Port 389 -WarningAction SilentlyContinue
            if (-not $Connectivity.TcpTestSucceeded) {
                $Issues += "Cannot connect to FSMO role holder: $($Role.Name) on $($Role.Value)"
            }
        }
    }
    catch {
        $Issues += "Error checking FSMO roles: $_"
    }
    
    # Return Results
    if ($Issues) {
        Write-Log "AD Health Check found issues: $($Issues -join '; ')" -Level Warning
        return @{
            Healthy = $false
            Issues = $Issues
            Details = if ($Detailed) { Get-ADHealthDetails }
        }
    }
    
    Write-Log "AD Health Check completed successfully" -Level Success
    return @{
        Healthy = $true
        Issues = @()
        Details = if ($Detailed) { Get-ADHealthDetails }
    }
}

# Security Compliance Check
function Test-SecurityCompliance {
    param([switch]$GenerateReport)
    
    Write-Log "Starting security compliance check..."
    $Findings = @()
    
    # Password Policy Check
    try {
        $PasswordPolicy = Get-ADDefaultDomainPasswordPolicy
        if ($PasswordPolicy.MinPasswordLength -lt 12) {
            $Findings += "Minimum password length is less than recommended (12)"
        }
        if (-not $PasswordPolicy.ComplexityEnabled) {
            $Findings += "Password complexity is not enabled"
        }
    }
    catch {
        $Findings += "Error checking password policy: $_"
    }
    
    # Privileged Group Audit
    try {
        $AdminGroups = @('Domain Admins', 'Enterprise Admins', 'Schema Admins')
        foreach ($Group in $AdminGroups) {
            $Members = Get-ADGroupMember -Identity $Group -Recursive
            if ($Members.Count -gt 5) {
                $Findings += "$Group has $($Members.Count) members - review recommended"
            }
        }
    }
    catch {
        $Findings += "Error checking admin groups: $_"
    }
    
    # Inactive Account Check
    try {
        $InactiveAccounts = Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00
        if ($InactiveAccounts) {
            $Findings += "Found $($InactiveAccounts.Count) inactive accounts"
        }
    }
    catch {
        $Findings += "Error checking inactive accounts: $_"
    }
    
    # Generate Report if requested
    if ($GenerateReport) {
        $ReportFile = "$ReportPath\SecurityCompliance_$(Get-Date -Format 'yyyyMMdd').html"
        $ReportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Security Compliance Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .finding { margin: 10px 0; padding: 10px; border-left: 4px solid #ff9800; }
        .critical { border-left-color: #f44336; }
    </style>
</head>
<body>
    <h1>Security Compliance Report</h1>
    <p>Generated: $(Get-Date)</p>
    <h2>Findings</h2>
    $(foreach ($Finding in $Findings) {
        "<div class='finding'>$Finding</div>"
    })
</body>
</html>
"@
        $ReportContent | Set-Content -Path $ReportFile
        Write-Log "Security compliance report generated: $ReportFile" -Level Success
    }
    
    return @{
        Compliant = $Findings.Count -eq 0
        Findings = $Findings
    }
}

# System Performance Analysis
function Get-SystemPerformanceAnalysis {
    param(
        [int]$SampleInterval = 5,
        [int]$SampleCount = 12
    )
    
    Write-Log "Starting system performance analysis..."
    $Metrics = @()
    
    for ($i = 1; $i -le $SampleCount; $i++) {
        $Sample = @{
            Timestamp = Get-Date
            CPU = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
            Memory = @{
                Total = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
                Available = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue / 1024
            }
            DiskIO = @{
                ReadBytes = (Get-Counter '\PhysicalDisk(_Total)\Disk Read Bytes/sec').CounterSamples.CookedValue
                WriteBytes = (Get-Counter '\PhysicalDisk(_Total)\Disk Write Bytes/sec').CounterSamples.CookedValue
            }
            NetworkIO = @{
                ReceivedBytes = (Get-Counter '\Network Interface(*)\Bytes Received/sec').CounterSamples.CookedValue
                SentBytes = (Get-Counter '\Network Interface(*)\Bytes Sent/sec').CounterSamples.CookedValue
            }
        }
        
        $Metrics += $Sample
        
        if ($i -lt $SampleCount) {
            Start-Sleep -Seconds $SampleInterval
        }
    }
    
    # Analyze metrics
    $Analysis = @{
        CPU = @{
            Average = ($Metrics.CPU | Measure-Object -Average).Average
            Max = ($Metrics.CPU | Measure-Object -Maximum).Maximum
        }
        Memory = @{
            AverageUsedGB = ($Metrics.Memory | ForEach-Object { $_.Total - $_.Available } | Measure-Object -Average).Average
            PercentUsed = ($Metrics.Memory | ForEach-Object { (($_.Total - $_.Available) / $_.Total) * 100 } | Measure-Object -Average).Average
        }
        DiskIO = @{
            AverageReadMBps = (($Metrics.DiskIO.ReadBytes | Measure-Object -Average).Average / 1MB)
            AverageWriteMBps = (($Metrics.DiskIO.WriteBytes | Measure-Object -Average).Average / 1MB)
        }
        NetworkIO = @{
            AverageReceivedMBps = (($Metrics.NetworkIO.ReceivedBytes | Measure-Object -Average).Average / 1MB)
            AverageSentMBps = (($Metrics.NetworkIO.SentBytes | Measure-Object -Average).Average / 1MB)
        }
    }
    
    # Generate alerts for concerning metrics
    $Alerts = @()
    
    if ($Analysis.CPU.Average -gt 80) {
        $Alerts += "High average CPU usage: $([math]::Round($Analysis.CPU.Average, 2))%"
    }
    
    if ($Analysis.Memory.PercentUsed -gt 90) {
        $Alerts += "High memory usage: $([math]::Round($Analysis.Memory.PercentUsed, 2))%"
    }
    
    return @{
        Metrics = $Metrics
        Analysis = $Analysis
        Alerts = $Alerts
    }
}

# Main Operations Function
function Start-EnterpriseITOperations {
    param(
        [switch]$FullHealthCheck,
        [switch]$SecurityAudit,
        [switch]$PerformanceAnalysis,
        [switch]$GenerateReport
    )
    
    Write-Log "Starting Enterprise IT Operations..."
    $Results = @{}
    
    if ($FullHealthCheck -or $GenerateReport) {
        $Results.ADHealth = Test-ADHealth -Detailed
        Write-Log "AD Health Check completed"
    }
    
    if ($SecurityAudit -or $GenerateReport) {
        $Results.Security = Test-SecurityCompliance
        Write-Log "Security Compliance Check completed"
    }
    
    if ($PerformanceAnalysis -or $GenerateReport) {
        $Results.Performance = Get-SystemPerformanceAnalysis
        Write-Log "Performance Analysis completed"
    }
    
    if ($GenerateReport) {
        $ReportFile = "$ReportPath\EnterpriseReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $ReportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Enterprise IT Operations Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; }
        .alert { color: #721c24; background-color: #f8d7da; padding: 10px; margin: 5px 0; }
        .success { color: #155724; background-color: #d4edda; padding: 10px; margin: 5px 0; }
    </style>
</head>
<body>
    <h1>Enterprise IT Operations Report</h1>
    <p>Generated: $(Get-Date)</p>
    
    $(if ($Results.ADHealth) {
        @"
    <div class='section'>
        <h2>Active Directory Health</h2>
        <div class='$(if($Results.ADHealth.Healthy){"success"}else{"alert"})'>
            Status: $(if($Results.ADHealth.Healthy){"Healthy"}else{"Issues Detected"})
        </div>
        $(if($Results.ADHealth.Issues) {
            "<ul>" + ($Results.ADHealth.Issues | ForEach-Object { "<li>$_</li>" }) + "</ul>"
        })
    </div>
"@
    })
    
    $(if ($Results.Security) {
        @"
    <div class='section'>
        <h2>Security Compliance</h2>
        <div class='$(if($Results.Security.Compliant){"success"}else{"alert"})'>
            Status: $(if($Results.Security.Compliant){"Compliant"}else{"Non-Compliant"})
        </div>
        $(if($Results.Security.Findings) {
            "<ul>" + ($Results.Security.Findings | ForEach-Object { "<li>$_</li>" }) + "</ul>"
        })
    </div>
"@
    })
    
    $(if ($Results.Performance) {
        @"
    <div class='section'>
        <h2>Performance Analysis</h2>
        <h3>System Metrics</h3>
        <ul>
            <li>Average CPU Usage: $([math]::Round($Results.Performance.Analysis.CPU.Average, 2))%</li>
            <li>Memory Usage: $([math]::Round($Results.Performance.Analysis.Memory.PercentUsed, 2))%</li>
            <li>Disk I/O (Read/Write MB/s): $([math]::Round($Results.Performance.Analysis.DiskIO.AverageReadMBps, 2)) / $([math]::Round($Results.Performance.Analysis.DiskIO.AverageWriteMBps, 2))</li>
        </ul>
        $(if($Results.Performance.Alerts) {
            "<h3>Alerts</h3><ul>" + ($Results.Performance.Alerts | ForEach-Object { "<li>$_</li>" }) + "</ul>"
        })
    </div>
"@
    })
</body>
</html>
"@
        $ReportContent | Set-Content -Path $ReportFile
        Write-Log "Enterprise IT Operations report generated: $ReportFile" -Level Success
    }
    
    return $Results
}

# Execute if running directly
if ($MyInvocation.InvocationName -ne '.') {
    Start-EnterpriseITOperations -FullHealthCheck -SecurityAudit -PerformanceAnalysis -GenerateReport
}
