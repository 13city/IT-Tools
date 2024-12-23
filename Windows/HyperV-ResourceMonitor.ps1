#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

<#
.SYNOPSIS
    Comprehensive Hyper-V health monitoring script that checks for resource contention, snapshots, and infrastructure issues.

.DESCRIPTION
    This script connects to a Hyper-V host, enumerates all VMs, and performs comprehensive health checks including:
    - CPU and memory usage monitoring
    - Snapshot age and space usage analysis
    - Storage health verification
    - Network performance checks
    - Resource contention detection
    
    It logs findings, suggests remediation steps, and can send email alerts for critical issues.

.PARAMETER HostName
    The Hyper-V host to monitor. Default is localhost.

.PARAMETER LogPath
    Path where log files will be stored. Default is "C:\Logs\HyperV"

.PARAMETER CpuThreshold
    CPU usage threshold percentage that triggers alerts. Default is 90.

.PARAMETER MemoryThreshold
    Memory usage threshold percentage that triggers alerts. Default is 85.

.PARAMETER SnapshotAgeThreshold
    Maximum age in days for snapshots before triggering alerts. Default is 7.

.PARAMETER EmailAlert
    Switch to enable email alerts.

.PARAMETER SmtpServer
    SMTP server for sending alerts.

.PARAMETER EmailFrom
    Email address to send alerts from.

.PARAMETER EmailTo
    Email address to send alerts to.

.EXAMPLE
    .\HyperV-ResourceMonitor.ps1 -HostName "HyperV01" -EmailAlert -SmtpServer "smtp.company.com" -EmailFrom "hyperv@company.com" -EmailTo "admin@company.com"
#>

[CmdletBinding()]
param (
    [string]$HostName = "localhost",
    [string]$LogPath = "C:\Logs\HyperV",
    [int]$CpuThreshold = 90,
    [int]$MemoryThreshold = 85,
    [int]$SnapshotAgeThreshold = 7,
    [switch]$EmailAlert,
    [string]$SmtpServer,
    [string]$EmailFrom,
    [string]$EmailTo
)

# Initialize Logging
function Initialize-Logging {
    if (-not (Test-Path -Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
    $script:LogFile = Join-Path -Path $LogPath -ChildPath "HyperV-Monitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    Write-Log "Script started - Monitoring host: $HostName"
}

function Write-Log {
    param([string]$Message)
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $script:LogFile -Value $LogMessage
    Write-Verbose $LogMessage
}

function Send-AlertEmail {
    param (
        [string]$Subject,
        [string]$Body
    )
    
    if ($EmailAlert -and $SmtpServer -and $EmailFrom -and $EmailTo) {
        try {
            $emailParams = @{
                From = $EmailFrom
                To = $EmailTo
                Subject = "Hyper-V Alert: $Subject"
                Body = $Body
                SmtpServer = $SmtpServer
            }
            Send-MailMessage @emailParams -BodyAsHtml -Priority High
            Write-Log "Alert email sent: $Subject"
        }
        catch {
            Write-Log "Failed to send email alert: $_"
        }
    }
}

function Get-VMResourceUsage {
    param([Microsoft.HyperV.PowerShell.VirtualMachine]$VM)
    
    try {
        $vmCpu = Measure-VM -VM $VM
        $vmMemory = $VM | Select-Object @{
            Name = 'MemoryUsage'
            Expression = { $_.MemoryAssigned / $_.MemoryStartup * 100 }
        }
        
        return @{
            CpuUsage = [math]::Round($vmCpu.AvgCPUUsage, 2)
            MemoryUsage = [math]::Round($vmMemory.MemoryUsage, 2)
        }
    }
    catch {
        Write-Log "Error getting resource usage for VM '$($VM.Name)': $_"
        return $null
    }
}

function Test-VMNetworkHealth {
    param([Microsoft.HyperV.PowerShell.VirtualMachine]$VM)
    
    $issues = @()
    
    foreach ($adapter in $VM.NetworkAdapters) {
        if ($adapter.Status -ne 'Ok') {
            $issues += "Network adapter '$($adapter.Name)' status: $($adapter.Status)"
        }
        
        # Check for bandwidth usage
        $bandwidth = Get-VMNetworkAdapter -VMName $VM.Name | 
            Select-Object -ExpandProperty BandwidthSetting
        
        if ($bandwidth.MaximumBandwidth -gt 0) {
            $currentUsage = $bandwidth.CurrentBandwidth
            $maxBandwidth = $bandwidth.MaximumBandwidth
            $usagePercent = ($currentUsage / $maxBandwidth) * 100
            
            if ($usagePercent -gt 80) {
                $issues += "High network bandwidth usage: $($usagePercent)%"
            }
        }
    }
    
    return $issues
}

function Test-VMStorageHealth {
    param([Microsoft.HyperV.PowerShell.VirtualMachine]$VM)
    
    $issues = @()
    
    foreach ($drive in $VM.HardDrives) {
        try {
            $vhd = Get-VHD -Path $drive.Path
            
            # Check VHD fragmentation
            if ($vhd.FragmentationPercentage -gt 30) {
                $issues += "High fragmentation on VHD '$($drive.Path)': $($vhd.FragmentationPercentage)%"
            }
            
            # Check available space for dynamically expanding disks
            if ($vhd.VhdType -eq 'Dynamic') {
                $freeSpace = $vhd.Size - $vhd.FileSize
                $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
                if ($freeSpaceGB -lt 10) {
                    $issues += "Low free space on dynamic VHD '$($drive.Path)': $freeSpaceGB GB remaining"
                }
            }
            
            # Check physical disk performance where VHD is stored
            $diskPath = Split-Path -Path $drive.Path -Qualifier
            $diskPerf = Get-Counter "\PhysicalDisk(*)\% Idle Time" -ErrorAction Stop |
                Where-Object { $_.InstanceName -match $diskPath }
            
            if ($diskPerf.CookedValue -lt 20) {
                $issues += "High disk activity on volume '$diskPath': $($diskPerf.CookedValue)% idle time"
            }
        }
        catch {
            $issues += "Error checking storage health for drive '$($drive.Path)': $_"
        }
    }
    
    return $issues
}

function Get-SnapshotStatus {
    param([Microsoft.HyperV.PowerShell.VirtualMachine]$VM)
    
    $issues = @()
    $snapshots = Get-VMSnapshot -VMName $VM.Name
    
    foreach ($snapshot in $snapshots) {
        $age = (Get-Date) - $snapshot.CreationTime
        if ($age.Days -gt $SnapshotAgeThreshold) {
            $issues += "Old snapshot found: '$($snapshot.Name)' - Age: $($age.Days) days"
        }
        
        # Check snapshot storage space
        try {
            $snapshotSize = (Get-Item $snapshot.HardDrives[0].Path).Length / 1GB
            if ($snapshotSize -gt 50) {
                $issues += "Large snapshot found: '$($snapshot.Name)' - Size: $([math]::Round($snapshotSize, 2)) GB"
            }
        }
        catch {
            $issues += "Error checking snapshot size for '$($snapshot.Name)': $_"
        }
    }
    
    return $issues
}

function Get-RemediationSteps {
    param(
        [string[]]$Issues
    )
    
    $remediation = @()
    
    foreach ($issue in $Issues) {
        switch -Wildcard ($issue) {
            "*CPU usage*" {
                $remediation += @"
CPU Contention Remediation:
- Review resource allocation and adjust if needed
- Check for runaway processes within the VM
- Consider migrating some workloads to other hosts
- Enable processor compatibility for potential live migration
"@
            }
            "*Memory usage*" {
                $remediation += @"
Memory Usage Remediation:
- Review and adjust dynamic memory settings
- Check for memory leaks within the VM
- Consider adding more physical memory to the host
- Enable resource metering to track usage patterns
"@
            }
            "*Network*bandwidth*" {
                $remediation += @"
Network Bandwidth Remediation:
- Review and adjust bandwidth limits
- Check for network-intensive applications
- Consider implementing QoS policies
- Monitor for potential network bottlenecks
"@
            }
            "*fragmentation*" {
                $remediation += @"
VHD Fragmentation Remediation:
- Schedule defragmentation during off-hours
- Consider converting to fixed VHD if appropriate
- Implement regular maintenance schedule
"@
            }
            "*free space*" {
                $remediation += @"
Storage Space Remediation:
- Clean up unnecessary files and snapshots
- Expand VHD size if needed
- Consider storage migration to larger volume
- Implement storage monitoring alerts
"@
            }
            "*snapshot*" {
                $remediation += @"
Snapshot Management Remediation:
- Review and remove unnecessary snapshots
- Implement automated snapshot cleanup
- Consider backup strategy instead of long-term snapshots
- Monitor snapshot chain depth
"@
            }
            default {
                $remediation += "General Issue: $issue`nRecommendation: Review system logs and monitor for recurring patterns"
            }
        }
    }
    
    return $remediation
}

# Main execution block
try {
    Initialize-Logging
    
    # Connect to Hyper-V host
    if ($HostName -ne "localhost") {
        $session = New-PSSession -ComputerName $HostName -ErrorAction Stop
        Write-Log "Connected to remote host: $HostName"
    }
    
    # Get all VMs
    $vms = Get-VM -ErrorAction Stop
    Write-Log "Found $($vms.Count) virtual machines"
    
    $criticalIssues = @()
    
    foreach ($vm in $vms) {
        Write-Log "Analyzing VM: $($vm.Name)"
        $vmIssues = @()
        
        # Check resource usage
        $resources = Get-VMResourceUsage -VM $vm
        if ($resources) {
            if ($resources.CpuUsage -gt $CpuThreshold) {
                $vmIssues += "High CPU usage: $($resources.CpuUsage)%"
            }
            if ($resources.MemoryUsage -gt $MemoryThreshold) {
                $vmIssues += "High memory usage: $($resources.MemoryUsage)%"
            }
        }
        
        # Check network health
        $networkIssues = Test-VMNetworkHealth -VM $vm
        $vmIssues += $networkIssues
        
        # Check storage health
        $storageIssues = Test-VMStorageHealth -VM $vm
        $vmIssues += $storageIssues
        
        # Check snapshots
        $snapshotIssues = Get-SnapshotStatus -VM $vm
        $vmIssues += $snapshotIssues
        
        if ($vmIssues.Count -gt 0) {
            $criticalIssues += "Issues found for VM '$($vm.Name)':"
            $criticalIssues += $vmIssues
            
            # Get remediation steps
            $remediation = Get-RemediationSteps -Issues $vmIssues
            $criticalIssues += "Remediation Steps:"
            $criticalIssues += $remediation
            $criticalIssues += "------------------"
            
            # Send email alert if enabled
            if ($EmailAlert) {
                $emailBody = @"
<h2>Issues detected for VM: $($vm.Name)</h2>
<h3>Issues:</h3>
<ul>
$(($vmIssues | ForEach-Object { "<li>$_</li>" }) -join "`n")
</ul>
<h3>Recommended Actions:</h3>
<ul>
$(($remediation | ForEach-Object { "<li>$_</li>" }) -join "`n")
</ul>
"@
                Send-AlertEmail -Subject "Critical Issues - VM: $($vm.Name)" -Body $emailBody
            }
        }
    }
    
    # Log all findings
    if ($criticalIssues.Count -gt 0) {
        Write-Log "Critical issues found:"
        $criticalIssues | ForEach-Object { Write-Log $_ }
    }
    else {
        Write-Log "No critical issues found"
    }
    
    # Cleanup
    if ($session) {
        Remove-PSSession $session
        Write-Log "Disconnected from remote host: $HostName"
    }
    
    Write-Log "Script completed successfully"
}
catch {
    $errorMessage = "Error: $_"
    Write-Log $errorMessage
    if ($EmailAlert) {
        Send-AlertEmail -Subject "Script Error" -Body $errorMessage
    }
    throw $_
}
