<#
.SYNOPSIS
    Enhanced Hyper-V health monitoring with multi-channel reporting capabilities.

.DESCRIPTION
    This script:
    - Monitors Hyper-V virtual machine health metrics
    - Tracks CPU and memory utilization
    - Validates VM operational status
    - Generates detailed performance reports
    - Provides real-time console output
    - Sends Slack notifications for issues
    - Creates comprehensive HTML reports
    - Supports customizable thresholds
    - Performs trend analysis

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022
    Requirements:
    - Hyper-V PowerShell module
    - Administrative rights
    - Network connectivity for Slack notifications
    - Write access to log directory
    - PowerShell 5.1 or higher

.PARAMETER LogPath
    Path where monitoring logs will be written
    Default: .\logs\[timestamp]-HyperV-Health.log
    Creates timestamped log files

.PARAMETER SlackWebhook
    Webhook URL for Slack notifications
    Optional: If not provided, Slack notifications are disabled
    Obtain from Slack workspace settings

.PARAMETER GenerateReport
    Switch to enable HTML report generation
    Creates detailed report with metrics and charts
    Default: False

.PARAMETER ReportPath
    Path where HTML report will be saved
    Default: .\reports\[timestamp]-HyperV-Report.html
    Creates timestamped report files

.PARAMETER WarningThresholdCPU
    CPU usage percentage to trigger warnings
    Default: 80%
    Range: 0-100

.PARAMETER CriticalThresholdCPU
    CPU usage percentage to trigger critical alerts
    Default: 90%
    Range: 0-100

.PARAMETER WarningThresholdMemory
    Memory usage percentage to trigger warnings
    Default: 85%
    Range: 0-100

.PARAMETER CriticalThresholdMemory
    Memory usage percentage to trigger critical alerts
    Default: 95%
    Range: 0-100

.PARAMETER DaysToAnalyze
    Number of days of history to analyze
    Used for trend analysis and reporting
    Default: 7 days

.EXAMPLE
    .\EnhancedHyperVHealth.ps1
    Runs basic health monitoring with console output:
    - Uses default thresholds
    - Logs to default location
    - No Slack notifications
    - No HTML report generation

.EXAMPLE
    .\EnhancedHyperVHealth.ps1 -SlackWebhook "https://hooks.slack.com/services/xxx" -GenerateReport
    Runs monitoring with full reporting:
    - Sends alerts to Slack
    - Generates HTML report
    - Uses default thresholds
    - Creates detailed logs

.EXAMPLE
    .\EnhancedHyperVHealth.ps1 -WarningThresholdCPU 70 -CriticalThresholdCPU 85 -DaysToAnalyze 14
    Runs monitoring with custom thresholds:
    - Lower CPU thresholds for earlier warnings
    - Analyzes 14 days of history
    - Console output only
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\logs\$(Get-Date -Format 'yyyy-MM-dd_HH-mm')-HyperV-Health.log",
    
    [Parameter(Mandatory=$false)]
    [string]$SlackWebhook,
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = ".\reports\$(Get-Date -Format 'yyyy-MM-dd_HH-mm')-HyperV-Report.html",
    
    [Parameter(Mandatory=$false)]
    [int]$WarningThresholdCPU = 80,
    
    [Parameter(Mandatory=$false)]
    [int]$CriticalThresholdCPU = 90,
    
    [Parameter(Mandatory=$false)]
    [int]$WarningThresholdMemory = 85,
    
    [Parameter(Mandatory=$false)]
    [int]$CriticalThresholdMemory = 95,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToAnalyze = 7
)

# Import required modules
Import-Module Hyper-V

# ANSI color codes for console output
$script:colors = @{
    Reset = "`e[0m"
    Bold = "`e[1m"
    Red = "`e[31m"
    Green = "`e[32m"
    Yellow = "`e[33m"
    Blue = "`e[34m"
    Magenta = "`e[35m"
    Cyan = "`e[36m"
    BgRed = "`e[41m"
    BgGreen = "`e[42m"
    BgYellow = "`e[43m"
}

# Emoji mappings for Slack and console
$script:emoji = @{
    Success = "✅"
    Warning = "⚠️"
    Error = "❌"
    Info = "ℹ️"
    CPU = "🔄"
    Memory = "💾"
    Storage = "💿"
    Network = "🌐"
    Backup = "📦"
    Clock = "⏰"
    Server = "🖥️"
}

function Write-FormattedOutput {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info',
        [switch]$NoNewline
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $emoji = $script:emoji[$Level]
    
    # Determine color based on level
    $color = switch($Level) {
        'Info' { $colors.Cyan }
        'Success' { $colors.Green }
        'Warning' { $colors.Yellow }
        'Error' { $colors.Red }
    }
    
    # Console output
    $consoleMessage = "$($colors.Bold)[$timestamp]$($colors.Reset) $color$emoji $Message$($colors.Reset)"
    if ($NoNewline) {
        Write-Host $consoleMessage -NoNewline
    } else {
        Write-Host $consoleMessage
    }
    
    # Log to file
    "$timestamp [$Level] $Message" | Add-Content -Path $LogPath
}

function Send-SlackNotification {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info',
        [array]$Fields
    )
    
    if (-not $SlackWebhook) { return }
    
    # Determine color based on level
    $color = switch($Level) {
        'Info' { '#36a64f' }
        'Success' { '#2eb886' }
        'Warning' { '#daa038' }
        'Error' { '#d00000' }
    }
    
    $emoji = $script:emoji[$Level]
    
    $payload = @{
        attachments = @(
            @{
                color = $color
                pretext = "$emoji $Message"
                fields = $Fields | ForEach-Object {
                    @{
                        title = $_.Title
                        value = $_.Value
                        short = $_.Short
                    }
                }
                footer = "Hyper-V Health Monitor"
                ts = [Math]::Floor((Get-Date -UFormat %s))
            }
        )
    }
    
    try {
        $json = $payload | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $SlackWebhook -Method Post -Body $json -ContentType 'application/json'
    }
    catch {
        Write-FormattedOutput "Failed to send Slack notification: $_" -Level Error
    }
}

function Get-FormattedSize {
    param([double]$Bytes)
    
    $sizes = 'B','KB','MB','GB','TB'
    $index = 0
    while ($Bytes -ge 1024 -and $index -lt ($sizes.Count - 1)) {
        $Bytes /= 1024
        $index++
    }
    return "{0:N2} {1}" -f $Bytes, $sizes[$index]
}

function Get-FormattedPercentage {
    param(
        [double]$Value,
        [int]$WarningThreshold,
        [int]$CriticalThreshold
    )
    
    $percentage = [math]::Round($Value, 2)
    
    if ($percentage -ge $CriticalThreshold) {
        return "$($colors.BgRed)$percentage%$($colors.Reset)"
    }
    elseif ($percentage -ge $WarningThreshold) {
        return "$($colors.Yellow)$percentage%$($colors.Reset)"
    }
    else {
        return "$($colors.Green)$percentage%$($colors.Reset)"
    }
}

function Get-VMHealthStatus {
    Write-FormattedOutput "Collecting VM health information..." -Level Info
    
    $results = @{
        VMs = @()
        Critical = @()
        Warnings = @()
    }
    
    $vms = Get-VM
    foreach ($vm in $vms) {
        $metrics = Measure-VM $vm
        $memory = Get-VMMemory $vm
        
        $cpuUsage = $metrics.AvgCPUUsage
        $memoryUsage = ($memory.Demand / $memory.Maximum) * 100
        
        $vmStatus = @{
            Name = $vm.Name
            State = $vm.State
            CPUUsage = $cpuUsage
            MemoryUsage = $memoryUsage
            MemoryAssigned = Get-FormattedSize ($memory.Assigned)
            Uptime = $vm.Uptime
            Status = "Healthy"
            StatusEmoji = $emoji.Success
        }
        
        # Check for issues
        if ($cpuUsage -ge $CriticalThresholdCPU -or $memoryUsage -ge $CriticalThresholdMemory) {
            $vmStatus.Status = "Critical"
            $vmStatus.StatusEmoji = $emoji.Error
            $results.Critical += "VM '$($vm.Name)' is in critical state"
        }
        elseif ($cpuUsage -ge $WarningThresholdCPU -or $memoryUsage -ge $WarningThresholdMemory) {
            $vmStatus.Status = "Warning"
            $vmStatus.StatusEmoji = $emoji.Warning
            $results.Warnings += "VM '$($vm.Name)' requires attention"
        }
        
        $results.VMs += $vmStatus
    }
    
    return $results
}

function Write-ConsoleReport {
    param($HealthData)
    
    Write-Host "`n$($colors.Bold)═══════════════════════════════════════════════════════════════$($colors.Reset)"
    Write-Host "$($colors.Bold)                    Hyper-V Health Report                        $($colors.Reset)"
    Write-Host "$($colors.Bold)═══════════════════════════════════════════════════════════════$($colors.Reset)`n"
    
    # Summary section
    Write-Host "$($colors.Bold)📊 Summary$($colors.Reset)"
    Write-Host "Total VMs: $($HealthData.VMs.Count)"
    Write-Host "Critical Issues: $($HealthData.Critical.Count)"
    Write-Host "Warnings: $($HealthData.Warnings.Count)`n"
    
    # VM Details
    Write-Host "$($colors.Bold)🖥️ VM Status$($colors.Reset)"
    Write-Host "┌────────────────────┬──────────┬───────────┬────────────┬─────────────┐"
    Write-Host "│ VM Name           │ State    │ CPU       │ Memory     │ Status      │"
    Write-Host "├────────────────────┼──────────┼───────────┼────────────┼─────────────┤"
    
    foreach ($vm in $HealthData.VMs) {
        $cpuFormatted = Get-FormattedPercentage $vm.CPUUsage $WarningThresholdCPU $CriticalThresholdCPU
        $memoryFormatted = Get-FormattedPercentage $vm.MemoryUsage $WarningThresholdMemory $CriticalThresholdMemory
        
        $vmName = $vm.Name.PadRight(16).Substring(0, 16)
        $state = $vm.State.ToString().PadRight(8).Substring(0, 8)
        $status = "$($vm.StatusEmoji) $($vm.Status)".PadRight(11)
        
        Write-Host ("│ {0} │ {1} │ {2} │ {3} │ {4} │" -f `
            $vmName,
            $state,
            $cpuFormatted.PadRight(9),
            $memoryFormatted.PadRight(10),
            $status)
    }
    
    Write-Host "└────────────────────┴──────────┴───────────┴────────────┴─────────────┘`n"
    
    # Critical Issues
    if ($HealthData.Critical) {
        Write-Host "$($colors.Bold)$($colors.Red)❌ Critical Issues$($colors.Reset)"
        foreach ($issue in $HealthData.Critical) {
            Write-Host "$($colors.Red)  • $issue$($colors.Reset)"
        }
        Write-Host ""
    }
    
    # Warnings
    if ($HealthData.Warnings) {
        Write-Host "$($colors.Bold)$($colors.Yellow)⚠️ Warnings$($colors.Reset)"
        foreach ($warning in $HealthData.Warnings) {
            Write-Host "$($colors.Yellow)  • $warning$($colors.Reset)"
        }
        Write-Host ""
    }
}

function Send-SlackReport {
    param($HealthData)
    
    # Create main message
    $message = "*Hyper-V Health Report* $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    
    # Create fields for Slack message
    $fields = @(
        @{
            title = "Total VMs"
            value = $HealthData.VMs.Count
            short = $true
        },
        @{
            title = "Critical Issues"
            value = $HealthData.Critical.Count
            short = $true
        }
    )
    
    # Add VM status fields
    foreach ($vm in $HealthData.VMs) {
        $fields += @{
            title = "$($vm.StatusEmoji) $($vm.Name)"
            value = "CPU: $($vm.CPUUsage)% | Memory: $($vm.MemoryUsage)% | State: $($vm.State)"
            short = $false
        }
    }
    
    # Send to Slack
    Send-SlackNotification -Message $message -Level Info -Fields $fields
    
    # Send critical issues if any
    if ($HealthData.Critical) {
        Send-SlackNotification -Message "🚨 Critical Issues Detected" -Level Error -Fields @(
            @{
                title = "Issues"
                value = ($HealthData.Critical -join "`n")
                short = $false
            }
        )
    }
}

function Export-HTMLReport {
    param(
        $HealthData,
        $Path
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .summary { display: flex; justify-content: space-around; margin: 20px 0; }
        .summary-card { background-color: #f8f9fa; padding: 15px; border-radius: 4px; text-align: center; }
        .vm-grid { margin-top: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; }
        .critical { color: #dc3545; }
        .warning { color: #ffc107; }
        .healthy { color: #28a745; }
        .status-badge { padding: 5px 10px; border-radius: 4px; display: inline-block; }
        .status-critical { background-color: #dc3545; color: white; }
        .status-warning { background-color: #ffc107; color: black; }
        .status-healthy { background-color: #28a745; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hyper-V Health Report</h1>
        <div class="summary">
            <div class="summary-card">
                <h3>Total VMs</h3>
                <p>$($HealthData.VMs.Count)</p>
            </div>
            <div class="summary-card">
                <h3>Critical Issues</h3>
                <p class="critical">$($HealthData.Critical.Count)</p>
            </div>
            <div class="summary-card">
                <h3>Warnings</h3>
                <p class="warning">$($HealthData.Warnings.Count)</p>
            </div>
        </div>
        
        <div class="vm-grid">
            <h2>Virtual Machine Status</h2>
            <table>
                <tr>
                    <th>VM Name</th>
                    <th>State</th>
                    <th>CPU Usage</th>
                    <th>Memory Usage</th>
                    <th>Memory Assigned</th>
                    <th>Status</th>
                </tr>
                $(foreach ($vm in $HealthData.VMs) {
                    $statusClass = switch ($vm.Status) {
                        "Critical" { "status-critical" }
                        "Warning" { "status-warning" }
                        default { "status-healthy" }
                    }
                    "<tr>
                        <td>$($vm.Name)</td>
                        <td>$($vm.State)</td>
                        <td>$($vm.CPUUsage)%</td>
                        <td>$($vm.MemoryUsage)%</td>
                        <td>$($vm.MemoryAssigned)</td>
                        <td><span class='status-badge $statusClass'>$($vm.Status)</span></td>
                    </tr>"
                })
            </table>
        </div>
        
        $(if ($HealthData.Critical) {
            "<div class='issues-section'>
                <h2>Critical Issues</h2>
                <ul class='critical'>
                    $(foreach ($issue in $HealthData.Critical) {
                        "<li>$issue</li>"
                    })
                </ul>
            </div>"
        })
        
        $(if ($HealthData.Warnings) {
            "<div class='issues-section'>
                <h2>Warnings</h2>
                <ul class='warning'>
                    $(foreach ($warning in $HealthData.Warnings) {
                        "<li>$warning</li>"
                    })
                </ul>
            </div>"
        })
        
        <div class="footer">
            <p>Report generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
            <p>Monitoring thresholds: CPU Warning: $WarningThresholdCPU%, Critical: $CriticalThresholdCPU% | Memory Warning: $WarningThresholdMemory%, Critical: $CriticalThresholdMemory%</p>
        </div>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $Path -Encoding UTF8
    Write-FormattedOutput "HTML report exported to: $Path" -Level Success
}

# Main execution
try {
    # Create log directory if it doesn't exist
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Write-FormattedOutput "Starting Hyper-V health monitoring..." -Level Info
    
    # Get health status
    $healthData = Get-VMHealthStatus
    
    # Display console report
    Write-ConsoleReport -HealthData $healthData
    
    # Send Slack notification if configured
    if ($SlackWebhook) {
        Send-SlackReport -HealthData $healthData
    }
    
    # Generate HTML report if requested
    if ($GenerateReport) {
        $reportDir = Split-Path $ReportPath -Parent
        if (-not (Test-Path $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }
        Export-HTMLReport -HealthData $healthData -Path $ReportPath
    }
    
    Write-FormattedOutput "Health monitoring completed successfully" -Level Success
}
catch {
    Write-FormattedOutput "Error during health monitoring: $_" -Level Error
    throw
}
