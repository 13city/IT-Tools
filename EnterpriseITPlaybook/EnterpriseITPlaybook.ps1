#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enterprise IT Operations Playbook for Tier 2/3 Support
.DESCRIPTION
    Comprehensive diagnostic and escalation framework for Windows Server environments.
    Includes AD, DNS, Network, and Database health checks with automated escalation.
#>

# Initialize Logging
$LogPath = "$env:ProgramData\EnterpriseITPlaybook"
$LogFile = "$LogPath\Diagnostic_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$TicketPath = "$LogPath\Tickets"

# Ensure directories exist
@($LogPath, $TicketPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# Logging Function
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error','Critical')]$Level = 'Info',
        [switch]$NoTicket
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    
    switch ($Level) {
        'Info'     { Write-Host $LogMessage -ForegroundColor Green }
        'Warning'  { Write-Host $LogMessage -ForegroundColor Yellow }
        'Error'    { Write-Host $LogMessage -ForegroundColor Red }
        'Critical' { 
            Write-Host $LogMessage -ForegroundColor Red -BackgroundColor White
            if (-not $NoTicket) {
                New-EscalationTicket -Issue $Message -Severity "Critical"
            }
        }
    }
}

# Ticket Generation
function New-EscalationTicket {
    param(
        [string]$Issue,
        [ValidateSet('Low','Medium','High','Critical')]$Severity,
        [string[]]$AttachmentPaths
    )
    
    $TicketFile = Join-Path $TicketPath "Ticket_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $TicketData = @{
        Timestamp = Get-Date -Format 'o'
        Issue = $Issue
        Severity = $Severity
        ComputerName = $env:COMPUTERNAME
        Username = $env:USERNAME
        Logs = @{
            DiagnosticLog = $LogFile
            AdditionalLogs = $AttachmentPaths
        }
        SystemState = @{
            OS = (Get-CimInstance Win32_OperatingSystem).Caption
            LastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
            Memory = @{
                Total = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
                Free = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
            }
            Processor = @{
                Load = (Get-CimInstance Win32_Processor).LoadPercentage
                Name = (Get-CimInstance Win32_Processor).Name
            }
        }
    }
    
    $TicketData | ConvertTo-Json -Depth 10 | Set-Content $TicketFile
    Write-Log "Escalation ticket created: $TicketFile" -Level Warning -NoTicket
    return $TicketFile
}

# AD Replication Status
function Test-ADReplication {
    Write-Log "Testing AD Replication Status..."
    
    try {
        $Results = Get-ADReplicationPartnerMetadata -Target * -Scope Server
        $FailingPartners = $Results | Where-Object { $_.LastReplicationResult -ne 0 }
        
        if ($FailingPartners) {
            $Message = "AD Replication failures detected on: $($FailingPartners.Partner -join ', ')"
            Write-Log $Message -Level Critical
            return $false
        }
        
        Write-Log "AD Replication check completed successfully"
        return $true
    }
    catch {
        Write-Log "Error testing AD replication: $_" -Level Error
        return $false
    }
}

# DNS Health Check
function Test-DNSHealth {
    Write-Log "Checking DNS Health..."
    
    $Issues = @()
    
    # Test DNS Service
    try {
        $DNSService = Get-Service -Name "DNS" -ErrorAction Stop
        if ($DNSService.Status -ne "Running") {
            $Issues += "DNS Service is not running"
        }
    }
    catch {
        $Issues += "Unable to query DNS service: $_"
    }
    
    # Test DNS Resolution
    $TestDomains = @(
        "www.google.com",
        $env:USERDNSDOMAIN
    )
    
    foreach ($Domain in $TestDomains) {
        try {
            $null = Resolve-DnsName -Name $Domain -ErrorAction Stop
        }
        catch {
            $Issues += "Failed to resolve $Domain"
        }
    }
    
    # Check DNS Records
    if ($env:USERDNSDOMAIN) {
        try {
            $null = Get-DnsServerZone -Name $env:USERDNSDOMAIN -ErrorAction Stop
        }
        catch {
            $Issues += "Unable to query DNS zone $env:USERDNSDOMAIN"
        }
    }
    
    if ($Issues) {
        Write-Log "DNS Health Issues Found: $($Issues -join '; ')" -Level Critical
        return $false
    }
    
    Write-Log "DNS health check completed successfully"
    return $true
}

# Firewall ACL Review
function Test-FirewallRules {
    Write-Log "Reviewing Firewall Configuration..."
    
    try {
        $Rules = Get-NetFirewallRule | Where-Object { $_.Enabled -eq $true }
        $RiskyRules = $Rules | Where-Object {
            $_.Direction -eq "Inbound" -and 
            $_.Action -eq "Allow" -and 
            ($_.RemoteAddress -eq "Any" -or $_.RemotePort -eq "Any")
        }
        
        if ($RiskyRules) {
            $Message = "Potentially risky firewall rules found: $($RiskyRules.Name -join ', ')"
            Write-Log $Message -Level Warning
            
            # Export risky rules for review
            $RulesFile = Join-Path $LogPath "RiskyFirewallRules.csv"
            $RiskyRules | Export-Csv -Path $RulesFile -NoTypeInformation
            Write-Log "Exported risky rules to: $RulesFile"
        }
        
        Write-Log "Firewall review completed"
        return $true
    }
    catch {
        Write-Log "Error reviewing firewall rules: $_" -Level Error
        return $false
    }
}

# Database Connectivity Check
function Test-DatabaseConnectivity {
    param(
        [string]$ServerInstance,
        [string]$Database,
        [PSCredential]$Credential
    )
    
    Write-Log "Testing database connectivity to $ServerInstance..."
    
    try {
        $ConnectionString = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
        $Connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
        $Connection.Open()
        
        if ($Connection.State -eq 'Open') {
            Write-Log "Successfully connected to database"
            $Connection.Close()
            return $true
        }
    }
    catch {
        Write-Log "Database connectivity failed: $_" -Level Critical
        return $false
    }
}

# Performance Metrics Collection
function Get-SystemPerformanceMetrics {
    Write-Log "Collecting system performance metrics..."
    
    try {
        $Metrics = @{
            CPU = (Get-CimInstance Win32_Processor).LoadPercentage
            Memory = @{
                Total = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
                Free = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
            }
            Disk = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
                @{
                    Drive = $_.DeviceID
                    FreeSpace = [math]::Round($_.FreeSpace / 1GB, 2)
                    TotalSpace = [math]::Round($_.Size / 1GB, 2)
                }
            }
        }
        
        # Check for critical conditions
        if ($Metrics.CPU -gt 90) {
            Write-Log "Critical CPU usage detected: $($Metrics.CPU)%" -Level Critical
        }
        
        $FreeMemoryPercent = ($Metrics.Memory.Free / $Metrics.Memory.Total) * 100
        if ($FreeMemoryPercent -lt 10) {
            Write-Log "Critical memory condition: $($FreeMemoryPercent)% free" -Level Critical
        }
        
        foreach ($Drive in $Metrics.Disk) {
            $FreeSpacePercent = ($Drive.FreeSpace / $Drive.TotalSpace) * 100
            if ($FreeSpacePercent -lt 10) {
                Write-Log "Critical disk space on $($Drive.Drive): $($FreeSpacePercent)% free" -Level Critical
            }
        }
        
        return $Metrics
    }
    catch {
        Write-Log "Error collecting performance metrics: $_" -Level Error
        return $null
    }
}

# Main Diagnostic Function
function Start-ServerDiagnostics {
    param(
        [string]$DatabaseServer,
        [string]$DatabaseName
    )
    
    Write-Log "Starting comprehensive server diagnostics..."
    Write-Log "----------------------------------------"
    
    # Initialize results collection
    $DiagnosticResults = @{
        ADReplication = $false
        DNSHealth = $false
        FirewallRules = $false
        DatabaseConnectivity = $false
        PerformanceMetrics = $null
        Timestamp = Get-Date
    }
    
    # Run diagnostics
    $DiagnosticResults.ADReplication = Test-ADReplication
    $DiagnosticResults.DNSHealth = Test-DNSHealth
    $DiagnosticResults.FirewallRules = Test-FirewallRules
    
    if ($DatabaseServer -and $DatabaseName) {
        $DiagnosticResults.DatabaseConnectivity = Test-DatabaseConnectivity -ServerInstance $DatabaseServer -Database $DatabaseName
    }
    
    $DiagnosticResults.PerformanceMetrics = Get-SystemPerformanceMetrics
    
    # Export results
    $ResultsFile = Join-Path $LogPath "DiagnosticResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $DiagnosticResults | ConvertTo-Json -Depth 10 | Set-Content $ResultsFile
    
    Write-Log "----------------------------------------"
    Write-Log "Diagnostic scan complete. Results saved to: $ResultsFile"
    
    # Return results for further processing
    return $DiagnosticResults
}

# Execute diagnostics if running directly
if ($MyInvocation.InvocationName -ne '.') {
    Start-ServerDiagnostics
}
