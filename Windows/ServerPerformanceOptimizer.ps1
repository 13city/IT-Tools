# Windows Server Performance Monitor and Optimizer
# This script monitors server performance metrics and performs optimization tasks

param (
    [Parameter(Mandatory=$false)]
    [string]$ComputerName = $env:COMPUTERNAME,
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "$env:USERPROFILE\Desktop\Server-Performance.html",
    [Parameter(Mandatory=$false)]
    [int]$MonitoringMinutes = 60,
    [Parameter(Mandatory=$false)]
    [int]$SampleInterval = 5,
    [Parameter(Mandatory=$false)]
    [switch]$PerformOptimization,
    [Parameter(Mandatory=$false)]
    [int]$CPUThreshold = 80,
    [Parameter(Mandatory=$false)]
    [int]$MemoryThreshold = 85,
    [Parameter(Mandatory=$false)]
    [int]$DiskSpaceThreshold = 90
)

# Function to get system information
function Get-SystemInfo {
    param (
        [string]$ComputerName
    )
    
    try {
        $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
        $cs = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName
        $proc = Get-WmiObject -Class Win32_Processor -ComputerName $ComputerName
        
        return [PSCustomObject]@{
            OSVersion = $os.Caption
            ServicePack = $os.ServicePackMajorVersion
            Architecture = $os.OSArchitecture
            LastBoot = $os.ConvertToDateTime($os.LastBootUpTime)
            TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory/1GB, 2)
            Processors = $proc.Count
            LogicalProcessors = $cs.NumberOfLogicalProcessors
            ComputerModel = $cs.Model
            Manufacturer = $cs.Manufacturer
        }
    }
    catch {
        Write-Error "Failed to get system information: $_"
        return $null
    }
}

# Function to get performance metrics
function Get-PerformanceMetrics {
    param (
        [string]$ComputerName,
        [int]$SampleInterval
    )
    
    try {
        $cpu = Get-Counter -ComputerName $ComputerName `
            -Counter "\Processor(_Total)\% Processor Time" `
            -SampleInterval $SampleInterval `
            -MaxSamples 1
        
        $memory = Get-Counter -ComputerName $ComputerName `
            -Counter "\Memory\% Committed Bytes In Use" `
            -SampleInterval $SampleInterval `
            -MaxSamples 1
        
        $diskIO = Get-Counter -ComputerName $ComputerName `
            -Counter "\PhysicalDisk(_Total)\Avg. Disk Queue Length" `
            -SampleInterval $SampleInterval `
            -MaxSamples 1
        
        return [PSCustomObject]@{
            CPUUsage = [math]::Round($cpu.CounterSamples.CookedValue, 2)
            MemoryUsage = [math]::Round($memory.CounterSamples.CookedValue, 2)
            DiskQueueLength = [math]::Round($diskIO.CounterSamples.CookedValue, 2)
        }
    }
    catch {
        Write-Error "Failed to get performance metrics: $_"
        return $null
    }
}

# Function to get disk space
function Get-DiskSpace {
    param (
        [string]$ComputerName
    )
    
    try {
        $disks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $ComputerName -Filter "DriveType = 3"
        $results = foreach ($disk in $disks) {
            [PSCustomObject]@{
                Drive = $disk.DeviceID
                VolumeName = $disk.VolumeName
                TotalGB = [math]::Round($disk.Size/1GB, 2)
                FreeGB = [math]::Round($disk.FreeSpace/1GB, 2)
                PercentFree = [math]::Round(($disk.FreeSpace/$disk.Size)*100, 2)
            }
        }
        return $results
    }
    catch {
        Write-Error "Failed to get disk space information: $_"
        return $null
    }
}

# Function to get top processes
function Get-TopProcesses {
    param (
        [string]$ComputerName
    )
    
    try {
        $processes = Get-Process -ComputerName $ComputerName | 
            Sort-Object CPU -Descending |
            Select-Object -First 10 |
            Select-Object ProcessName, CPU, WorkingSet, Handles
        
        return $processes | ForEach-Object {
            [PSCustomObject]@{
                ProcessName = $_.ProcessName
                CPUTime = [math]::Round($_.CPU, 2)
                MemoryMB = [math]::Round($_.WorkingSet/1MB, 2)
                Handles = $_.Handles
            }
        }
    }
    catch {
        Write-Error "Failed to get top processes: $_"
        return $null
    }
}

# Function to get network statistics
function Get-NetworkStats {
    param (
        [string]$ComputerName
    )
    
    try {
        $network = Get-Counter -ComputerName $ComputerName `
            -Counter @(
                "\Network Interface(*)\Bytes Total/sec",
                "\Network Interface(*)\Current Bandwidth"
            ) `
            -MaxSamples 1
        
        $results = foreach ($counter in $network.CounterSamples) {
            if ($counter.InstanceName -notmatch "isatap|loopback") {
                [PSCustomObject]@{
                    Interface = $counter.InstanceName
                    Metric = $counter.Path -replace '.*\\'
                    Value = [math]::Round($counter.CookedValue, 2)
                }
            }
        }
        return $results
    }
    catch {
        Write-Error "Failed to get network statistics: $_"
        return $null
    }
}

# Function to optimize system performance
function Optimize-ServerPerformance {
    param (
        [string]$ComputerName
    )
    
    try {
        $optimizations = @()
        
        # Clear temporary files
        $tempFolders = @(
            "$env:TEMP",
            "$env:SystemRoot\Temp",
            "$env:SystemRoot\Prefetch"
        )
        
        foreach ($folder in $tempFolders) {
            Remove-Item -Path "$folder\*" -Force -Recurse -ErrorAction SilentlyContinue
            $optimizations += "Cleared temporary files in $folder"
        }
        
        # Stop unnecessary services
        $unnecessaryServices = @(
            "TabletInputService",
            "WSearch",
            "WerSvc"
        )
        
        foreach ($service in $unnecessaryServices) {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                Stop-Service -Name $service -Force
                Set-Service -Name $service -StartupType Disabled
                $optimizations += "Stopped and disabled service: $service"
            }
        }
        
        # Disable unnecessary scheduled tasks
        $unnecessaryTasks = @(
            "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
            "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
        )
        
        foreach ($task in $unnecessaryTasks) {
            Disable-ScheduledTask -TaskPath $task -ErrorAction SilentlyContinue
            $optimizations += "Disabled scheduled task: $task"
        }
        
        # Clean up Windows Update cache
        Stop-Service -Name wuauserv -Force
        Remove-Item "$env:SystemRoot\SoftwareDistribution\*" -Force -Recurse -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv
        $optimizations += "Cleaned Windows Update cache"
        
        return $optimizations
    }
    catch {
        Write-Error "Failed to perform optimizations: $_"
        return $null
    }
}

# Function to generate HTML report
function New-HTMLReport {
    param (
        [object]$SystemInfo,
        [object]$PerformanceMetrics,
        [object]$DiskSpace,
        [object]$TopProcesses,
        [object]$NetworkStats,
        [object]$Optimizations
    )

    $html = @"
    <!DOCTYPE html>
    <html>
    <head>
        <title>Server Performance Report</title>
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
        <h1>Server Performance Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</h1>
        
        <h2>System Information</h2>
        $($SystemInfo | ConvertTo-Html -Fragment)
        
        <h2>Performance Metrics</h2>
        $($PerformanceMetrics | ConvertTo-Html -Fragment)
        
        <h2>Disk Space</h2>
        $($DiskSpace | ConvertTo-Html -Fragment)
        
        <h2>Top Processes</h2>
        $($TopProcesses | ConvertTo-Html -Fragment)
        
        <h2>Network Statistics</h2>
        $($NetworkStats | ConvertTo-Html -Fragment)
        
        $(if ($Optimizations) {
            "<h2>Optimizations Performed</h2>
            $($Optimizations | ConvertTo-Html -Fragment)"
        })
    </body>
    </html>
"@

    return $html
}

# Main execution
try {
    Write-Host "Starting server performance monitoring..."
    
    # Get system information
    $systemInfo = Get-SystemInfo -ComputerName $ComputerName
    Write-Host "System information collected"
    
    # Monitor performance for specified duration
    $endTime = (Get-Date).AddMinutes($MonitoringMinutes)
    $performanceData = @()
    
    while ((Get-Date) -lt $endTime) {
        $metrics = Get-PerformanceMetrics -ComputerName $ComputerName -SampleInterval $SampleInterval
        $performanceData += $metrics
        Write-Host "Performance sample collected: CPU $($metrics.CPUUsage)%, Memory $($metrics.MemoryUsage)%"
        Start-Sleep -Seconds $SampleInterval
    }
    
    # Calculate averages
    $avgMetrics = [PSCustomObject]@{
        AverageCPU = [math]::Round(($performanceData.CPUUsage | Measure-Object -Average).Average, 2)
        AverageMemory = [math]::Round(($performanceData.MemoryUsage | Measure-Object -Average).Average, 2)
        AverageDiskQueue = [math]::Round(($performanceData.DiskQueueLength | Measure-Object -Average).Average, 2)
    }
    
    # Get current metrics
    $diskSpace = Get-DiskSpace -ComputerName $ComputerName
    Write-Host "Disk space information collected"
    
    $topProcesses = Get-TopProcesses -ComputerName $ComputerName
    Write-Host "Top processes identified"
    
    $networkStats = Get-NetworkStats -ComputerName $ComputerName
    Write-Host "Network statistics collected"
    
    # Perform optimizations if requested
    $optimizations = $null
    if ($PerformOptimization) {
        Write-Host "Performing system optimizations..."
        $optimizations = Optimize-ServerPerformance -ComputerName $ComputerName
        Write-Host "Optimizations completed"
    }
    
    # Generate and save report
    $report = New-HTMLReport -SystemInfo $systemInfo `
                            -PerformanceMetrics $avgMetrics `
                            -DiskSpace $diskSpace `
                            -TopProcesses $topProcesses `
                            -NetworkStats $networkStats `
                            -Optimizations $optimizations
    
    $report | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Performance report generated successfully at: $ReportPath"
    
    # Check for critical conditions
    if ($avgMetrics.AverageCPU -gt $CPUThreshold) {
        Write-Warning "High average CPU usage detected: $($avgMetrics.AverageCPU)%"
    }
    
    if ($avgMetrics.AverageMemory -gt $MemoryThreshold) {
        Write-Warning "High average memory usage detected: $($avgMetrics.AverageMemory)%"
    }
    
    $criticalDisks = $diskSpace | Where-Object { $_.PercentFree -lt (100 - $DiskSpaceThreshold) }
    if ($criticalDisks) {
        Write-Warning "Low disk space detected on drives: $($criticalDisks.Drive -join ', ')"
    }
}
catch {
    Write-Error "An error occurred during performance monitoring: $_"
}
