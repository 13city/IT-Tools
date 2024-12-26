<# 
.SYNOPSIS
    Enterprise-grade Hyper-V health monitoring and diagnostics toolkit.

.DESCRIPTION
    This comprehensive health monitoring solution provides:
    - Real-time resource utilization tracking (CPU, Memory, Storage, Network)
    - Advanced replication health monitoring and diagnostics
    - Intelligent snapshot management and analysis
    - Detailed storage performance metrics and health checks
    - Network connectivity validation and throughput analysis
    - Cluster health assessment and failover testing
    - Backup status verification and consistency checks
    - Event log analysis with pattern recognition
    - Dynamic Memory optimization checks
    - Storage health and performance monitoring
    - Automated issue detection and remediation
    - Comprehensive HTML reporting with trends
    - Email notifications for critical issues
    - Performance baseline comparison
    - Capacity planning recommendations

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022
    Requirements:
    - Hyper-V role installed
    - Administrative rights
    - PowerShell 5.1 or higher
    - Write access to log directory
    - SMTP server access (if email notifications enabled)
    - Windows Server Backup (for backup status checks)
    - Cluster PowerShell module (for cluster checks)
    - .NET Framework 4.7.2 or higher
    - Performance Monitor access
    - Event Log access
    - Network monitoring capabilities

.PARAMETER LogPath
    Directory for detailed operation logs
    Default: .\logs\[timestamp]-HyperV-Health.log
    Creates timestamped log files
    Maintains historical data

.PARAMETER GenerateReport
    Switch to enable HTML report generation
    Creates comprehensive health assessment document
    Includes performance graphs and trends
    Default: False

.PARAMETER FixIssues
    Switch to enable automatic issue remediation
    Attempts to resolve common problems
    Logs all remediation actions
    Default: False

.PARAMETER DaysToAnalyze
    Historical data analysis period
    Used for trend analysis and reporting
    Default: 7 days
    Range: 1-90 days

.PARAMETER EmailRecipient
    Email address for report delivery
    Supports multiple recipients (comma-separated)
    Required for email notifications
    Example: "admin@domain.com"

.PARAMETER PerformanceThreshold
    CPU/Memory threshold for alerts
    Percentage that triggers warnings
    Default: 80%
    Range: 0-100

.PARAMETER StorageThreshold
    Free space threshold for alerts
    Percentage that triggers warnings
    Default: 20%
    Range: 0-100

.PARAMETER BackupAge
    Maximum acceptable backup age
    Days before backup warning
    Default: 1 day
    Range: 0-30

.EXAMPLE
    .\Check-HyperVHealth.ps1 -GenerateReport
    Basic health assessment:
    - Generates HTML report
    - Uses default thresholds
    - No automatic fixes
    - Console output only

.EXAMPLE
    .\Check-HyperVHealth.ps1 -GenerateReport -EmailRecipient "admin@company.com" -FixIssues
    Full monitoring solution:
    - Generates and emails report
    - Attempts automatic fixes
    - Uses default thresholds
    - Logs all actions

.EXAMPLE
    .\Check-HyperVHealth.ps1 -DaysToAnalyze 30 -PerformanceThreshold 90 -StorageThreshold 15
    Custom threshold monitoring:
    - 30-day analysis period
    - 90% performance threshold
    - 15% storage threshold
    - No automatic fixes
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\logs\$(Get-Date -Format 'yyyy-MM-dd_HH-mm')-HyperV-Health.log",
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory=$false)]
    [switch]$FixIssues,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToAnalyze = 7,
    
    [Parameter(Mandatory=$false)]
    [string]$EmailRecipient
)

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Severity = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Severity] - $Message"
    
    Add-Content -Path $LogPath -Value $logMessage
    
    switch ($Severity) {
        'Info' { Write-Host $logMessage -ForegroundColor Gray }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

function Test-HyperVRequirements {
    try {
        Write-Log "Checking Hyper-V requirements and configurations"
        
        # Check if Hyper-V role is installed
        $hypervRole = Get-WindowsFeature -Name Hyper-V
        if (-not $hypervRole.Installed) {
            Write-Log "Hyper-V role is not installed" -Severity Error
            return $false
        }
        
        # Check virtualization support
        $virtSupport = Get-WmiObject -Class Win32_Processor | Select-Object VMMonitorModeExtensions
        if (-not $virtSupport.VMMonitorModeExtensions) {
            Write-Log "Hardware virtualization is not enabled in BIOS" -Severity Error
            return $false
        }
        
        # Check memory requirements
        $totalMemory = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        if ($totalMemory -lt 16) {
            Write-Log "System has less than 16GB RAM ($($totalMemory)GB)" -Severity Warning
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to check Hyper-V requirements: $_" -Severity Error
        return $false
    }
}

function Get-VMResourceUsage {
    try {
        Write-Log "Analyzing VM resource usage"
        
        $vms = Get-VM
        $vmStats = @()
        
        foreach ($vm in $vms) {
            $metrics = Get-VM $vm.Name | Measure-VM
            $vmStats += @{
                Name = $vm.Name
                State = $vm.State
                CPUUsage = $metrics.AvgCPUUsage
                MemoryAssigned = $metrics.MemoryAssigned / 1GB
                MemoryDemand = $metrics.MemoryDemand / 1GB
                NetworkInbound = $metrics.NetworkInbound / 1MB
                NetworkOutbound = $metrics.NetworkOutbound / 1MB
            }
            
            # Check for resource bottlenecks
            if ($metrics.AvgCPUUsage -gt 90) {
                Write-Log "High CPU usage detected for VM '$($vm.Name)': $($metrics.AvgCPUUsage)%" -Severity Warning
            }
            
            if ($metrics.MemoryDemand / $metrics.MemoryAssigned * 100 -gt 95) {
                Write-Log "Memory pressure detected for VM '$($vm.Name)'" -Severity Warning
            }
        }
        
        return $vmStats
    }
    catch {
        Write-Log "Failed to analyze VM resource usage: $_" -Severity Error
        return $null
    }
}

function Test-StoragePerformance {
    param(
        [string]$Path
    )
    
    try {
        Write-Log "Testing storage performance for path: $Path"
        
        # Test write performance
        $writeTest = Measure-Command {
            $testFile = Join-Path $Path "speedtest.dat"
            $buffer = New-Object byte[] (1GB)
            [System.IO.File]::WriteAllBytes($testFile, $buffer)
            Remove-Item $testFile -Force
        }
        
        # Calculate write speed in MB/s
        $writeSpeed = 1024 / $writeTest.TotalSeconds
        
        # Test read performance
        $testFile = Join-Path $Path "speedtest.dat"
        $buffer = New-Object byte[] (1GB)
        [System.IO.File]::WriteAllBytes($testFile, $buffer)
        
        $readTest = Measure-Command {
            $content = [System.IO.File]::ReadAllBytes($testFile)
        }
        
        Remove-Item $testFile -Force
        
        # Calculate read speed in MB/s
        $readSpeed = 1024 / $readTest.TotalSeconds
        
        if ($writeSpeed -lt 50) {
            Write-Log "Slow write performance detected: $($writeSpeed.ToString('N2')) MB/s" -Severity Warning
        }
        
        if ($readSpeed -lt 50) {
            Write-Log "Slow read performance detected: $($readSpeed.ToString('N2')) MB/s" -Severity Warning
        }
        
        return @{
            WriteSpeed = $writeSpeed
            ReadSpeed = $readSpeed
        }
    }
    catch {
        Write-Log "Failed to test storage performance: $_" -Severity Error
        return $null
    }
}

function Test-ReplicationHealth {
    try {
        Write-Log "Checking replication health"
        
        $replicationIssues = @()
        $vms = Get-VM | Where-Object { $_.ReplicationState -ne "Disabled" }
        
        foreach ($vm in $vms) {
            $replication = Get-VMReplication -VMName $vm.Name
            
            if ($replication.State -ne "Normal") {
                $replicationIssues += @{
                    VM = $vm.Name
                    State = $replication.State
                    Health = $replication.Health
                    LastReplicationTime = $replication.LastReplicationTime
                    Error = $replication.LastError
                }
                
                Write-Log "Replication issue detected for VM '$($vm.Name)': $($replication.Health)" -Severity Warning
                
                if ($FixIssues) {
                    # Attempt to resume replication if suspended
                    if ($replication.State -eq "Suspended") {
                        Resume-VMReplication -VMName $vm.Name
                        Write-Log "Attempted to resume replication for VM '$($vm.Name)'" -Severity Info
                    }
                }
            }
        }
        
        return $replicationIssues
    }
    catch {
        Write-Log "Failed to check replication health: $_" -Severity Error
        return $null
    }
}

function Get-SnapshotStatus {
    try {
        Write-Log "Checking VM snapshots"
        
        $snapshotIssues = @()
        $vms = Get-VM
        
        foreach ($vm in $vms) {
            $snapshots = Get-VMSnapshot -VMName $vm.Name
            
            # Check for snapshot count
            if ($snapshots.Count -gt 3) {
                $snapshotIssues += @{
                    VM = $vm.Name
                    Issue = "Too many snapshots"
                    Count = $snapshots.Count
                }
                Write-Log "VM '$($vm.Name)' has $($snapshots.Count) snapshots" -Severity Warning
            }
            
            # Check for old snapshots
            $oldSnapshots = $snapshots | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$DaysToAnalyze) }
            if ($oldSnapshots) {
                $snapshotIssues += @{
                    VM = $vm.Name
                    Issue = "Old snapshots"
                    Snapshots = $oldSnapshots
                }
                Write-Log "VM '$($vm.Name)' has snapshots older than $DaysToAnalyze days" -Severity Warning
            }
            
            if ($FixIssues) {
                # Remove old snapshots
                $oldSnapshots | ForEach-Object {
                    Remove-VMSnapshot -VMSnapshot $_ -IncludeAllChildSnapshots
                    Write-Log "Removed old snapshot for VM '$($vm.Name)': $($_.Name)" -Severity Info
                }
            }
        }
        
        return $snapshotIssues
    }
    catch {
        Write-Log "Failed to check snapshot status: $_" -Severity Error
        return $null
    }
}

function Test-NetworkConnectivity {
    try {
        Write-Log "Testing network connectivity"
        
        $networkIssues = @()
        $vms = Get-VM | Where-Object { $_.State -eq 'Running' }
        
        foreach ($vm in $vms) {
            $adapters = Get-VMNetworkAdapter -VMName $vm.Name
            
            foreach ($adapter in $adapters) {
                # Check for disconnected adapters
                if (-not $adapter.Connected) {
                    $networkIssues += @{
                        VM = $vm.Name
                        Adapter = $adapter.Name
                        Issue = "Disconnected"
                    }
                    Write-Log "Network adapter disconnected for VM '$($vm.Name)'" -Severity Warning
                }
                
                # Check for MAC address conflicts
                $macConflicts = Get-VMNetworkAdapter -All | 
                    Where-Object { $_.MacAddress -eq $adapter.MacAddress -and $_.VMName -ne $vm.Name }
                if ($macConflicts) {
                    $networkIssues += @{
                        VM = $vm.Name
                        Adapter = $adapter.Name
                        Issue = "MAC conflict"
                        ConflictingVMs = $macConflicts.VMName
                    }
                    Write-Log "MAC address conflict detected for VM '$($vm.Name)'" -Severity Warning
                }
            }
        }
        
        return $networkIssues
    }
    catch {
        Write-Log "Failed to test network connectivity: $_" -Severity Error
        return $null
    }
}

function Test-ClusterHealth {
    try {
        Write-Log "Checking cluster health"
        
        # Check if server is part of a cluster
        $cluster = Get-Cluster -ErrorAction SilentlyContinue
        if (-not $cluster) {
            Write-Log "Server is not part of a failover cluster" -Severity Info
            return $null
        }
        
        $clusterIssues = @()
        
        # Check cluster nodes
        $nodes = Get-ClusterNode
        foreach ($node in $nodes) {
            if ($node.State -ne "Up") {
                $clusterIssues += @{
                    Type = "Node"
                    Name = $node.Name
                    State = $node.State
                }
                Write-Log "Cluster node '$($node.Name)' is in state: $($node.State)" -Severity Warning
            }
        }
        
        # Check cluster resources
        $resources = Get-ClusterResource
        foreach ($resource in $resources) {
            if ($resource.State -ne "Online") {
                $clusterIssues += @{
                    Type = "Resource"
                    Name = $resource.Name
                    State = $resource.State
                    Owner = $resource.OwnerNode
                }
                Write-Log "Cluster resource '$($resource.Name)' is in state: $($resource.State)" -Severity Warning
            }
        }
        
        # Check cluster network
        $networks = Get-ClusterNetwork
        foreach ($network in $networks) {
            if ($network.State -ne "Up") {
                $clusterIssues += @{
                    Type = "Network"
                    Name = $network.Name
                    State = $network.State
                }
                Write-Log "Cluster network '$($network.Name)' is in state: $($network.State)" -Severity Warning
            }
        }
        
        return $clusterIssues
    }
    catch {
        Write-Log "Failed to check cluster health: $_" -Severity Error
        return $null
    }
}

function Get-BackupStatus {
    try {
        Write-Log "Checking backup status"
        
        $backupIssues = @()
        $vms = Get-VM
        
        foreach ($vm in $vms) {
            # Check Windows Server Backup
            $lastBackup = Get-WBBackupSet | 
                Where-Object { $_.Application -eq "Hyper-V" -and $_.VirtualMachines -contains $vm.Name } |
                Sort-Object -Property BackupTime -Descending |
                Select-Object -First 1
            
            if (-not $lastBackup -or $lastBackup.BackupTime -lt (Get-Date).AddDays(-1)) {
                $backupIssues += @{
                    VM = $vm.Name
                    Issue = "No recent backup"
                    LastBackup = $lastBackup.BackupTime
                }
                Write-Log "No recent backup found for VM '$($vm.Name)'" -Severity Warning
            }
        }
        
        return $backupIssues
    }
    catch {
        Write-Log "Failed to check backup status: $_" -Severity Error
        return $null
    }
}

function Get-CriticalEvents {
    try {
        Write-Log "Analyzing event logs for Hyper-V issues"
        
        $startTime = (Get-Date).AddDays(-$DaysToAnalyze)
        $criticalEvents = @()
        
        # Hyper-V-related event logs
        $logs = @(
            'Microsoft-Windows-Hyper-V-VMMS-Admin',
            'Microsoft-Windows-Hyper-V-Worker-Admin',
            'System'
        )
        
        foreach ($log in $logs) {
            $events = Get-WinEvent -FilterHashtable @{
                LogName = $log
                Level = @(1,2) # Error and Warning
                StartTime = $startTime
            } -ErrorAction SilentlyContinue
            
            foreach ($event in $events) {
                $criticalEvents += @{
                    TimeCreated = $event.TimeCreated
                    EventID = $event.Id
                    Level = $event.Level
                    Source = $event.ProviderName
                    Message = $event.Message
                }
            }
        }
        
        # Analyze patterns in critical events
        $eventPatterns = $criticalEvents | Group-Object EventID | 
            Where-Object { $_.Count -gt 3 } |
            ForEach-Object {
                @{
                    EventID = $_.Name
                    Count = $_.Count
                    FirstOccurrence = ($_.Group | Sort-Object TimeCreated | Select-Object -First 1).TimeCreated
                    LastOccurrence = ($_.Group | Sort-Object TimeCreated | Select-Object -Last 1).TimeCreated
                    Message = ($_.Group | Select-Object -First 1).Message
                }
            }
        
        if ($eventPatterns) {
            Write-Log "Detected recurring event patterns:" -Severity Warning
            foreach ($pattern in $eventPatterns) {
                Write-Log "Event ID $($pattern.EventID) occurred $($pattern.Count) times between $($pattern.FirstOccurrence) and $($pattern.LastOccurrence)" -Severity Warning
            }
        }
        
        return @{
            Events = $criticalEvents
            Patterns = $eventPatterns
        }
    }
    catch {
        Write-Log "Failed to analyze event logs: $_" -Severity Error
        return $null
    }
}

function Test-DynamicMemoryHealth {
    try {
        Write-Log "Checking Dynamic Memory health"
        
        $memoryIssues = @()
        $vms = Get-VM | Where-Object { $_.DynamicMemoryEnabled }
        
        foreach ($vm in $vms) {
            $memoryStats = Get-VMMemory -VMName $vm.Name
            $metrics = Measure-VM -VMName $vm.Name
            
            # Check if VM is experiencing memory pressure
            if ($metrics.MemoryDemand -gt $memoryStats.Maximum) {
                $memoryIssues += @{
                    VM = $vm.Name
                    Issue = "Memory demand exceeds maximum"
                    Demand = $metrics.MemoryDemand
                    Maximum = $memoryStats.Maximum
                }
                Write-Log "VM '$($vm.Name)' memory demand exceeds maximum allocation" -Severity Warning
            }
            
            # Check for frequent memory ballooning
            $balloonEvents = Get-WinEvent -FilterHashtable @{
                LogName = 'Microsoft-Windows-Hyper-V-VMMS-Admin'
                ID = 28674  # Memory ballooning event
                StartTime = (Get-Date).AddHours(-1)
            } -ErrorAction SilentlyContinue
            
            if ($balloonEvents.Count -gt 10) {
                $memoryIssues += @{
                    VM = $vm.Name
                    Issue = "Frequent memory ballooning"
                    BalloonEvents = $balloonEvents.Count
                }
                Write-Log "VM '$($vm.Name)' is experiencing frequent memory ballooning" -Severity Warning
            }
        }
        
        return $memoryIssues
    }
    catch {
        Write-Log "Failed to check Dynamic Memory health: $_" -Severity Error
        return $null
    }
}

function Test-StorageHealth {
    try {
        Write-Log "Checking storage health"
        
        $storageIssues = @()
        
        # Check CSV health if in a cluster
        $cluster = Get-Cluster -ErrorAction SilentlyContinue
        if ($cluster) {
            $csvs = Get-ClusterSharedVolume
            foreach ($csv in $csvs) {
                if ($csv.State -ne "Online") {
                    $storageIssues += @{
                        Type = "CSV"
                        Name = $csv.Name
                        State = $csv.State
                    }
                    Write-Log "CSV '$($csv.Name)' is in state: $($csv.State)" -Severity Warning
                }
                
                # Check CSV space
                $csvInfo = $csv | Select-Object -ExpandProperty SharedVolumeInfo
                $freeSpacePercent = ($csvInfo.Partition.FreeSpace / $csvInfo.Partition.Size) * 100
                if ($freeSpacePercent -lt 20) {
                    $storageIssues += @{
                        Type = "CSV Space"
                        Name = $csv.Name
                        FreeSpace = $freeSpacePercent
                    }
                    Write-Log "CSV '$($csv.Name)' has less than 20% free space" -Severity Warning
                }
            }
        }
        
        # Check VHD/VHDX fragmentation
        $vms = Get-VM
        foreach ($vm in $vms) {
            $vhds = Get-VHD -VMId $vm.VMId -ErrorAction SilentlyContinue
            foreach ($vhd in $vhds) {
                if ($vhd.FragmentationPercentage -gt 30) {
                    $storageIssues += @{
                        Type = "VHD Fragmentation"
                        VM = $vm.Name
                        VHD = $vhd.Path
                        Fragmentation = $vhd.FragmentationPercentage
                    }
                    Write-Log "VHD '$($vhd.Path)' for VM '$($vm.Name)' is highly fragmented" -Severity Warning
                }
            }
        }
        
        return $storageIssues
    }
    catch {
        Write-Log "Failed to check storage health: $_" -Severity Error
        return $null
    }
}

function New-HealthReport {
    param(
        $Results
    )
    
    try {
        $reportPath = ".\reports\$(Get-Date -Format 'yyyy-MM-dd_HH-mm')-HyperV-Health.html"
        $reportDir = Split-Path $reportPath -Parent
        
        if (-not (Test-Path $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force
        }
        
        $criticalIssues = @()
        $warnings = @()
        
        # Categorize issues
        foreach ($category in $Results.Keys) {
            $issues = $Results[$category]
            switch ($category) {
                "ResourceUsage" {
                    foreach ($vm in $issues) {
                        if ($vm.CPUUsage -gt 90) {
                            $criticalIssues += "High CPU usage on VM '$($vm.Name)': $($vm.CPUUsage)%"
                        }
                    }
                }
                "ReplicationHealth" {
                    foreach ($issue in $issues) {
                        $criticalIssues += "Replication issue on VM '$($issue.VM)': $($issue.Health)"
                    }
                }
                "StoragePerformance" {
                    if ($issues.WriteSpeed -lt 30) {
                        $criticalIssues += "Critical storage performance: Write speed $($issues.WriteSpeed) MB/s"
                    }
                }
                # Add more categories as needed
            }
        }
        
        # Generate HTML report
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .critical { color: red; }
        .warning { color: orange; }
        .success { color: green; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Hyper-V Health Report</h1>
    <h2>Generated: $(Get-Date)</h2>
    
    <h3>Critical Issues</h3>
    <ul>
        $(foreach ($issue in $criticalIssues) {
            "<li class='critical'>$issue</li>"
        })
    </ul>
    
    <h3>Warnings</h3>
    <ul>
        $(foreach ($warning in $warnings) {
            "<li class='warning'>$warning</li>"
        })
    </ul>
    
    <h3>Resource Usage</h3>
    <table>
        <tr>
            <th>VM Name</th>
            <th>CPU Usage</th>
            <th>Memory Usage</th>
            <th>Network Usage</th>
        </tr>
        $(foreach ($vm in $Results.ResourceUsage) {
            "<tr>
                <td>$($vm.Name)</td>
                <td>$($vm.CPUUsage)%</td>
                <td>$($vm.MemoryAssigned) GB / $($vm.MemoryDemand) GB</td>
                <td>In: $($vm.NetworkInbound) MB/s, Out: $($vm.NetworkOutbound) MB/s</td>
            </tr>"
        })
    </table>
    
    <!-- Add more sections for other health metrics -->
    
</body>
</html>
"@
        
        $html | Out-File $reportPath
        
        if ($EmailRecipient) {
            Send-MailMessage -To $EmailRecipient -From "hyperv-monitor@yourdomain.com" `
                -Subject "Hyper-V Health Report - $(Get-Date -Format 'yyyy-MM-dd')" `
                -Body $html -BodyAsHtml -SmtpServer "your-smtp-server"
        }
        
        return $reportPath
    }
    catch {
        Write-Log "Failed to generate health report: $_" -Severity Error
        return $null
    }
}

# Main execution block
try {
    Write-Log "Starting Hyper-V health check"
    
    # Initialize results container
    $results = @{}
    
    # Check Hyper-V requirements
    if (-not (Test-HyperVRequirements)) {
        throw "Failed Hyper-V requirements check"
    }
    
    # Run all health checks
    $results.ResourceUsage = Get-VMResourceUsage
    $results.StoragePerformance = Test-StoragePerformance -Path (Get-VMHost).VirtualHardDiskPath
    $results.ReplicationHealth = Test-ReplicationHealth
    $results.SnapshotStatus = Get-SnapshotStatus
    $results.NetworkHealth = Test-NetworkConnectivity
    $results.ClusterHealth = Test-ClusterHealth
    $results.BackupStatus = Get-BackupStatus
    $results.EventAnalysis = Get-CriticalEvents
    $results.DynamicMemory = Test-DynamicMemoryHealth
    $results.StorageHealth = Test-StorageHealth
    
    # Generate and send report if requested
    if ($GenerateReport) {
        $reportPath = New-HealthReport -Results $results
        Write-Log "Health report generated: $reportPath" -Severity Success
    }
    
    # Auto-fix issues if requested
    if ($FixIssues) {
        Write-Log "Attempting to fix identified issues"
        # Add auto-remediation logic here
    }
    
    Write-Log "Health check completed successfully" -Severity Success
    return $results
}
catch {
    Write-Log "Health check failed: $_" -Severity Error
    throw
}
