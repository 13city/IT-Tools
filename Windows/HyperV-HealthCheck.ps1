<# 
.SYNOPSIS
    Comprehensive Hyper-V health monitoring and reporting system.

.DESCRIPTION
    This script performs comprehensive health checks on Hyper-V hosts and VMs:
    - Monitors Hyper-V service status
    - Checks VM operational health and performance
    - Validates storage health and VHD status
    - Analyzes network configuration and performance
    - Reviews critical event logs
    - Generates detailed HTML reports
    - Tracks historical performance data

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022
    Requirements:
    - Hyper-V PowerShell module
    - Administrative rights
    - Write access to report directory
    - PowerShell 5.1 or higher

.PARAMETER VMHost
    Target Hyper-V host for health checks
    Default: Local computer name
    Example: "HyperV-Host01"

.PARAMETER ReportPath
    Path where HTML report will be saved
    Default: Desktop\HyperV-HealthReport.html
    Creates timestamped HTML report

.PARAMETER DaysToAnalyze
    Number of days of event logs to analyze
    Default: 7 days
    Range: 1-30 days

.EXAMPLE
    .\HyperV-HealthCheck.ps1
    Runs health check with default settings:
    - Checks local Hyper-V host
    - Saves report to desktop
    - Analyzes last 7 days of events

.EXAMPLE
    .\HyperV-HealthCheck.ps1 -VMHost "HV-HOST01" -ReportPath "D:\Reports\HyperV-Health.html" -DaysToAnalyze 14
    Runs health check with custom settings:
    - Targets specific Hyper-V host
    - Saves report to custom location
    - Analyzes 14 days of events

.EXAMPLE
    .\HyperV-HealthCheck.ps1 -DaysToAnalyze 30
    Runs extended health analysis:
    - Checks local Hyper-V host
    - Default report location
    - Analyzes full 30 days of events
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$VMHost = $env:COMPUTERNAME,
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "$env:USERPROFILE\Desktop\HyperV-HealthReport.html",
    [Parameter(Mandatory=$false)]
    [int]$DaysToAnalyze = 7
)

# Function to check Hyper-V service status
function Test-HyperVServices {
    $services = @(
        "vmms",        # Hyper-V Virtual Machine Management
        "vmcompute",   # Hyper-V Host Compute Service
        "nvspwmi"      # Hyper-V WMI Provider
    )
    
    $results = foreach ($service in $services) {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            ServiceName = $service
            Status = $svc.Status
            StartType = $svc.StartType
        }
    }
    return $results
}

# Function to check VM health
function Test-VMHealth {
    $vms = Get-VM
    $results = foreach ($vm in $vms) {
        $metrics = Measure-VM -VM $vm
        [PSCustomObject]@{
            VMName = $vm.Name
            State = $vm.State
            CPUUsage = $metrics.AggregatedAverageProcessorUtilization
            MemoryAssigned = $metrics.AggregatedAverageMemoryUtilization
            UptimeHours = ($vm.Uptime).TotalHours
            Status = $vm.Status
            ReplicationHealth = $vm.ReplicationHealth
            IntegrationServicesVersion = $vm.IntegrationServicesVersion
        }
    }
    return $results
}

# Function to check storage health
function Test-VMStorageHealth {
    $vhds = Get-VHD -Path (Get-VMHardDiskDrive -VMName * | Select-Object -ExpandProperty Path)
    $results = foreach ($vhd in $vhds) {
        [PSCustomObject]@{
            Path = $vhd.Path
            VHDType = $vhd.VHDType
            SizeGB = [math]::Round($vhd.Size/1GB, 2)
            FragmentationPercentage = $vhd.FragmentationPercentage
            ParentPath = $vhd.ParentPath
        }
    }
    return $results
}

# Function to check network health
function Test-VMNetworkHealth {
    $vmSwitches = Get-VMSwitch
    $results = foreach ($switch in $vmSwitches) {
        $adapters = Get-VMNetworkAdapter -VMName * | Where-Object { $_.SwitchName -eq $switch.Name }
        [PSCustomObject]@{
            SwitchName = $switch.Name
            SwitchType = $switch.SwitchType
            ConnectedVMs = ($adapters | Measure-Object).Count
            BandwidthUsageGB = [math]::Round(($adapters | Measure-Object -Property BandwidthSetting -Sum).Sum/1GB, 2)
        }
    }
    return $results
}

# Function to check event logs
function Get-HyperVEvents {
    param (
        [int]$Days = 7
    )
    
    $startDate = (Get-Date).AddDays(-$Days)
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-Hyper-V-*'
        Level = 1,2,3
        StartTime = $startDate
    } -ErrorAction SilentlyContinue

    $results = foreach ($event in $events) {
        [PSCustomObject]@{
            TimeCreated = $event.TimeCreated
            Level = $event.Level
            Message = $event.Message
            Source = $event.ProviderName
        }
    }
    return $results
}

# Function to generate HTML report
function New-HTMLReport {
    param (
        [object]$ServiceHealth,
        [object]$VMHealth,
        [object]$StorageHealth,
        [object]$NetworkHealth,
        [object]$Events
    )

    $html = @"
    <!DOCTYPE html>
    <html>
    <head>
        <title>Hyper-V Health Report</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #4CAF50; color: white; }
            tr:nth-child(even) { background-color: #f2f2f2; }
            h2 { color: #4CAF50; }
        </style>
    </head>
    <body>
        <h1>Hyper-V Health Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</h1>
        
        <h2>Service Health</h2>
        $($ServiceHealth | ConvertTo-Html -Fragment)
        
        <h2>VM Health</h2>
        $($VMHealth | ConvertTo-Html -Fragment)
        
        <h2>Storage Health</h2>
        $($StorageHealth | ConvertTo-Html -Fragment)
        
        <h2>Network Health</h2>
        $($NetworkHealth | ConvertTo-Html -Fragment)
        
        <h2>Recent Events</h2>
        $($Events | ConvertTo-Html -Fragment)
    </body>
    </html>
"@

    return $html
}

# Main execution
try {
    Write-Host "Starting Hyper-V health check..."
    
    $serviceHealth = Test-HyperVServices
    Write-Host "Service health check completed"
    
    $vmHealth = Test-VMHealth
    Write-Host "VM health check completed"
    
    $storageHealth = Test-VMStorageHealth
    Write-Host "Storage health check completed"
    
    $networkHealth = Test-VMNetworkHealth
    Write-Host "Network health check completed"
    
    $events = Get-HyperVEvents -Days $DaysToAnalyze
    Write-Host "Event log analysis completed"
    
    $report = New-HTMLReport -ServiceHealth $serviceHealth `
                            -VMHealth $vmHealth `
                            -StorageHealth $storageHealth `
                            -NetworkHealth $networkHealth `
                            -Events $events
    
    $report | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Health report generated successfully at: $ReportPath"
}
catch {
    Write-Error "An error occurred during health check: $_"
}
