# SQL Server Performance and Health Monitor
# This script monitors SQL Server performance metrics, health status, and generates alerts

param (
    [Parameter(Mandatory=$false)]
    [string]$ServerInstance = ".",
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "*",
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "$env:USERPROFILE\Desktop\SQL-HealthReport.html",
    [Parameter(Mandatory=$false)]
    [int]$AlertThresholdCPU = 80,
    [Parameter(Mandatory=$false)]
    [int]$AlertThresholdMemory = 85,
    [Parameter(Mandatory=$false)]
    [int]$MonitoringDuration = 60,
    [Parameter(Mandatory=$false)]
    [int]$SampleInterval = 5
)

# Function to test SQL Server connectivity
function Test-SqlConnection {
    param (
        [string]$ServerInstance
    )
    
    try {
        $query = "SELECT @@VERSION AS Version"
        $result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query -ErrorAction Stop
        return $true
    }
    catch {
        Write-Error "Failed to connect to SQL Server $ServerInstance : $_"
        return $false
    }
}

# Function to get SQL Server version and edition
function Get-SqlServerInfo {
    param (
        [string]$ServerInstance
    )
    
    $query = @"
    SELECT 
        SERVERPROPERTY('ProductVersion') AS Version,
        SERVERPROPERTY('Edition') AS Edition,
        SERVERPROPERTY('ProductLevel') AS ServicePack,
        SERVERPROPERTY('IsClustered') AS IsClustered
"@
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
}

# Function to get database status
function Get-DatabaseStatus {
    param (
        [string]$ServerInstance,
        [string]$DatabaseName
    )
    
    $query = @"
    SELECT 
        name AS DatabaseName,
        state_desc AS Status,
        recovery_model_desc AS RecoveryModel,
        log_reuse_wait_desc AS LogReuseWait,
        compatibility_level AS CompatibilityLevel
    FROM sys.databases
    WHERE name LIKE '$DatabaseName'
"@
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
}

# Function to get performance metrics
function Get-PerformanceMetrics {
    param (
        [string]$ServerInstance
    )
    
    $query = @"
    SELECT 
        (SELECT cntr_value FROM sys.dm_os_performance_counters 
         WHERE counter_name = 'CPU usage %' AND instance_name = '_Total') AS CPUUsage,
        (SELECT cntr_value FROM sys.dm_os_performance_counters 
         WHERE counter_name = 'Buffer cache hit ratio' AND object_name LIKE '%Buffer Manager%') AS BufferCacheHitRatio,
        (SELECT cntr_value FROM sys.dm_os_performance_counters 
         WHERE counter_name = 'Page life expectancy' AND object_name LIKE '%Buffer Manager%') AS PageLifeExpectancy,
        (SELECT SUM(cntr_value) FROM sys.dm_os_performance_counters 
         WHERE counter_name = 'Batch Requests/sec') AS BatchRequestsPerSec
"@
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
}

# Function to get blocking information
function Get-BlockingInfo {
    param (
        [string]$ServerInstance
    )
    
    $query = @"
    SELECT 
        r.session_id AS BlockedSessionID,
        r.blocking_session_id AS BlockingSessionID,
        r.wait_time AS WaitTime,
        r.wait_type AS WaitType,
        s.login_name AS LoginName,
        s.host_name AS HostName,
        DB_NAME(r.database_id) AS DatabaseName,
        r.command AS Command,
        t.text AS SQLText
    FROM sys.dm_exec_requests r
    JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
    WHERE r.blocking_session_id > 0
"@
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
}

# Function to get index fragmentation
function Get-IndexFragmentation {
    param (
        [string]$ServerInstance,
        [string]$DatabaseName
    )
    
    $query = @"
    SELECT 
        DB_NAME(database_id) AS DatabaseName,
        OBJECT_NAME(object_id) AS TableName,
        index_id AS IndexID,
        avg_fragmentation_in_percent AS FragmentationPercent,
        page_count AS Pages
    FROM sys.dm_db_index_physical_stats
        (DB_ID('$DatabaseName'), NULL, NULL, NULL, 'LIMITED')
    WHERE avg_fragmentation_in_percent > 30
    AND page_count > 1000
"@
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
}

# Function to get backup status
function Get-BackupStatus {
    param (
        [string]$ServerInstance,
        [string]$DatabaseName
    )
    
    $query = @"
    SELECT 
        d.name AS DatabaseName,
        MAX(CASE WHEN b.type = 'D' THEN b.backup_finish_date END) AS LastFullBackup,
        MAX(CASE WHEN b.type = 'I' THEN b.backup_finish_date END) AS LastDiffBackup,
        MAX(CASE WHEN b.type = 'L' THEN b.backup_finish_date END) AS LastLogBackup
    FROM sys.databases d
    LEFT JOIN msdb.dbo.backupset b ON d.name = b.database_name
    WHERE d.name LIKE '$DatabaseName'
    GROUP BY d.name
"@
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
}

# Function to get job status
function Get-JobStatus {
    param (
        [string]$ServerInstance
    )
    
    $query = @"
    SELECT 
        j.name AS JobName,
        CASE j.enabled WHEN 1 THEN 'Enabled' ELSE 'Disabled' END AS Status,
        h.run_date AS LastRunDate,
        h.run_time AS LastRunTime,
        CASE h.run_status 
            WHEN 0 THEN 'Failed'
            WHEN 1 THEN 'Succeeded'
            WHEN 2 THEN 'Retry'
            WHEN 3 THEN 'Canceled'
            ELSE 'Unknown'
        END AS LastRunStatus
    FROM msdb.dbo.sysjobs j
    LEFT JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
    WHERE h.step_id = 0
"@
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
}

# Function to generate HTML report
function New-HTMLReport {
    param (
        [object]$ServerInfo,
        [object]$DatabaseStatus,
        [object]$PerformanceMetrics,
        [object]$BlockingInfo,
        [object]$IndexFragmentation,
        [object]$BackupStatus,
        [object]$JobStatus
    )

    $html = @"
    <!DOCTYPE html>
    <html>
    <head>
        <title>SQL Server Health Report</title>
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
        <h1>SQL Server Health Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</h1>
        
        <h2>Server Information</h2>
        $($ServerInfo | ConvertTo-Html -Fragment)
        
        <h2>Database Status</h2>
        $($DatabaseStatus | ConvertTo-Html -Fragment)
        
        <h2>Performance Metrics</h2>
        $($PerformanceMetrics | ConvertTo-Html -Fragment)
        
        <h2>Blocking Information</h2>
        $($BlockingInfo | ConvertTo-Html -Fragment)
        
        <h2>Index Fragmentation</h2>
        $($IndexFragmentation | ConvertTo-Html -Fragment)
        
        <h2>Backup Status</h2>
        $($BackupStatus | ConvertTo-Html -Fragment)
        
        <h2>Job Status</h2>
        $($JobStatus | ConvertTo-Html -Fragment)
    </body>
    </html>
"@

    return $html
}

# Main execution
try {
    Write-Host "Starting SQL Server health check..."
    
    # Test connection
    if (-not (Test-SqlConnection -ServerInstance $ServerInstance)) {
        throw "Failed to connect to SQL Server"
    }
    
    # Collect metrics
    $serverInfo = Get-SqlServerInfo -ServerInstance $ServerInstance
    Write-Host "Server information collected"
    
    $databaseStatus = Get-DatabaseStatus -ServerInstance $ServerInstance -DatabaseName $DatabaseName
    Write-Host "Database status collected"
    
    $performanceMetrics = Get-PerformanceMetrics -ServerInstance $ServerInstance
    Write-Host "Performance metrics collected"
    
    $blockingInfo = Get-BlockingInfo -ServerInstance $ServerInstance
    Write-Host "Blocking information collected"
    
    $indexFragmentation = Get-IndexFragmentation -ServerInstance $ServerInstance -DatabaseName $DatabaseName
    Write-Host "Index fragmentation information collected"
    
    $backupStatus = Get-BackupStatus -ServerInstance $ServerInstance -DatabaseName $DatabaseName
    Write-Host "Backup status collected"
    
    $jobStatus = Get-JobStatus -ServerInstance $ServerInstance
    Write-Host "Job status collected"
    
    # Generate and save report
    $report = New-HTMLReport -ServerInfo $serverInfo `
                            -DatabaseStatus $databaseStatus `
                            -PerformanceMetrics $performanceMetrics `
                            -BlockingInfo $blockingInfo `
                            -IndexFragmentation $indexFragmentation `
                            -BackupStatus $backupStatus `
                            -JobStatus $jobStatus
    
    $report | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Health report generated successfully at: $ReportPath"
    
    # Check for critical conditions
    if ($performanceMetrics.CPUUsage -gt $AlertThresholdCPU) {
        Write-Warning "High CPU usage detected: $($performanceMetrics.CPUUsage)%"
    }
    
    if ($blockingInfo) {
        Write-Warning "Blocking detected in the database"
    }
    
    $oldBackups = $backupStatus | Where-Object { 
        $_.LastFullBackup -lt (Get-Date).AddDays(-7) 
    }
    if ($oldBackups) {
        Write-Warning "Some databases haven't been backed up in the last 7 days"
    }
}
catch {
    Write-Error "An error occurred during health check: $_"
}
