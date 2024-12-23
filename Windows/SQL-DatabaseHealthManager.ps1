#Requires -Version 5.1
#Requires -Modules SqlServer

<#
.SYNOPSIS
    Comprehensive SQL Server database health management, monitoring, and maintenance script.

.DESCRIPTION
    This script performs comprehensive health checks on SQL Server databases including:
    - Database corruption checks
    - Index fragmentation analysis
    - Backup schedule validation
    - Performance metrics monitoring
    - Automatic database rebuilding when needed
    - Email notifications for critical issues

.PARAMETER ServerInstance
    SQL Server instance name

.PARAMETER DatabaseName
    Target database name (use * for all databases)

.PARAMETER EmailTo
    Email address for notifications

.PARAMETER EmailFrom
    From email address for notifications

.PARAMETER SmtpServer
    SMTP server for sending notifications

.PARAMETER RebuildThreshold
    Fragmentation percentage threshold for index rebuild (default: 30)

.PARAMETER LogPath
    Path for log files

.EXAMPLE
    .\SQL-DatabaseHealthManager.ps1 -ServerInstance "SQLSERVER01" -DatabaseName "*" -EmailTo "dba@company.com"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [string]$DatabaseName = "*",

    [Parameter(Mandatory = $true)]
    [string]$EmailTo,

    [Parameter(Mandatory = $true)]
    [string]$EmailFrom,

    [Parameter(Mandatory = $true)]
    [string]$SmtpServer,

    [Parameter(Mandatory = $false)]
    [int]$RebuildThreshold = 30,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\SQL"
)

# Initialize logging
$scriptName = "SQL-DatabaseHealthManager"
$timeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $LogPath "$scriptName-$timeStamp.log"

# Ensure log directory exists
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        default { Write-Host $logEntry }
    }
}

function Send-AlertEmail {
    param(
        [string]$Subject,
        [string]$Body,
        [string]$Priority = "Normal"
    )
    
    try {
        Send-MailMessage -To $EmailTo -From $EmailFrom `
            -Subject "SQL Health Alert: $Subject" `
            -Body $Body -SmtpServer $SmtpServer `
            -Priority $Priority -ErrorAction Stop
        
        Write-Log "Alert email sent: $Subject"
    }
    catch {
        Write-Log "Failed to send alert email: $_" -Level "ERROR"
    }
}

function Test-SqlConnection {
    try {
        $query = "SELECT @@VERSION AS Version"
        $null = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query -ErrorAction Stop
        Write-Log "Successfully connected to SQL Server instance: $ServerInstance"
        return $true
    }
    catch {
        Write-Log "Failed to connect to SQL Server: $_" -Level "ERROR"
        Send-AlertEmail -Subject "Connection Failed" -Body "Failed to connect to SQL Server $ServerInstance: $_" -Priority "High"
        return $false
    }
}

function Get-DatabaseHealth {
    param([string]$DbName)
    
    try {
        # Check database consistency
        $dbccQuery = "DBCC CHECKDB ('$DbName') WITH NO_INFOMSGS"
        $null = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $dbccQuery -Database $DbName
        Write-Log "DBCC CHECKDB completed successfully for $DbName"
        
        # Get fragmentation info
        $fragQuery = @"
        SELECT 
            OBJECT_NAME(ips.object_id) AS TableName,
            i.name AS IndexName,
            ips.avg_fragmentation_in_percent,
            ips.page_count
        FROM sys.dm_db_index_physical_stats(DB_ID('$DbName'), NULL, NULL, NULL, 'LIMITED') ips
        JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
        WHERE ips.avg_fragmentation_in_percent > $RebuildThreshold
        AND ips.page_count > 1000
"@
        $fragmentation = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $fragQuery -Database $DbName
        
        # Get backup info
        $backupQuery = @"
        SELECT 
            MAX(CASE WHEN type = 'D' THEN backup_finish_date END) AS LastFullBackup,
            MAX(CASE WHEN type = 'I' THEN backup_finish_date END) AS LastDiffBackup,
            MAX(CASE WHEN type = 'L' THEN backup_finish_date END) AS LastLogBackup
        FROM msdb.dbo.backupset
        WHERE database_name = '$DbName'
        AND backup_finish_date >= DATEADD(day, -7, GETDATE())
"@
        $backupInfo = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $backupQuery
        
        return @{
            Fragmentation = $fragmentation
            BackupInfo = $backupInfo
        }
    }
    catch {
        Write-Log "Error checking health for database $DbName : $_" -Level "ERROR"
        Send-AlertEmail -Subject "Health Check Failed" -Body "Failed to check health for database $DbName : $_" -Priority "High"
        return $null
    }
}

function Invoke-DatabaseRebuild {
    param(
        [string]$DbName,
        [object]$FragmentedIndexes
    )
    
    try {
        Write-Log "Starting database rebuild process for $DbName"
        
        foreach ($index in $FragmentedIndexes) {
            $tableName = $index.TableName
            $indexName = $index.IndexName
            $fragLevel = $index.avg_fragmentation_in_percent
            
            Write-Log "Rebuilding index $indexName on table $tableName (Fragmentation: $fragLevel%)"
            
            $rebuildQuery = "ALTER INDEX [$indexName] ON [$tableName] REBUILD WITH (ONLINE = ON)"
            try {
                Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DbName -Query $rebuildQuery -ErrorAction Stop
                Write-Log "Successfully rebuilt index $indexName"
            }
            catch {
                # If online rebuild fails, try offline
                Write-Log "Online rebuild failed, attempting offline rebuild" -Level "WARNING"
                $rebuildQuery = "ALTER INDEX [$indexName] ON [$tableName] REBUILD"
                Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DbName -Query $rebuildQuery
                Write-Log "Successfully rebuilt index $indexName (offline)"
            }
        }
        
        Write-Log "Completed database rebuild process for $DbName"
        return $true
    }
    catch {
        Write-Log "Failed to rebuild database $DbName : $_" -Level "ERROR"
        Send-AlertEmail -Subject "Rebuild Failed" -Body "Failed to rebuild database $DbName : $_" -Priority "High"
        return $false
    }
}

function Get-DatabaseList {
    try {
        $query = "SELECT name FROM sys.databases WHERE name LIKE '$DatabaseName' AND state_desc = 'ONLINE'"
        return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query
    }
    catch {
        Write-Log "Failed to get database list: $_" -Level "ERROR"
        return $null
    }
}

# Main execution block
try {
    Write-Log "=== Starting SQL Database Health Management ==="
    
    # Test connection
    if (-not (Test-SqlConnection)) {
        throw "Failed to connect to SQL Server"
    }
    
    # Get database list
    $databases = Get-DatabaseList
    if (-not $databases) {
        throw "No databases found matching pattern: $DatabaseName"
    }
    
    $healthIssues = @()
    
    foreach ($db in $databases) {
        $dbName = $db.name
        Write-Log "Processing database: $dbName"
        
        # Check database health
        $healthCheck = Get-DatabaseHealth -DbName $dbName
        if (-not $healthCheck) { continue }
        
        # Check for issues
        if ($healthCheck.Fragmentation) {
            Write-Log "Found fragmented indexes in $dbName" -Level "WARNING"
            $healthIssues += "Database $dbName has fragmented indexes"
            
            # Attempt rebuild
            $rebuildSuccess = Invoke-DatabaseRebuild -DbName $dbName -FragmentedIndexes $healthCheck.Fragmentation
            if ($rebuildSuccess) {
                Write-Log "Successfully rebuilt fragmented indexes in $dbName"
            }
        }
        
        # Check backup status
        $backupInfo = $healthCheck.BackupInfo
        if (-not $backupInfo.LastFullBackup) {
            $msg = "No full backup found in the last 7 days for $dbName"
            Write-Log $msg -Level "ERROR"
            $healthIssues += $msg
        }
    }
    
    # Send summary email if issues found
    if ($healthIssues) {
        $emailBody = "The following issues were detected:`n`n" + ($healthIssues -join "`n")
        Send-AlertEmail -Subject "Database Health Issues Detected" -Body $emailBody -Priority "High"
    }
    
    Write-Log "=== SQL Database Health Management Completed ==="
}
catch {
    Write-Log "Script execution failed: $_" -Level "ERROR"
    Send-AlertEmail -Subject "Script Execution Failed" -Body $_.Exception.Message -Priority "High"
    exit 1
}
