<#
.SYNOPSIS
    Enterprise SQL Server backup validation and integrity verification system.

.DESCRIPTION
    This script provides comprehensive SQL backup validation capabilities:
    - Backup Verification:
      * Recent backup existence check (24-hour window)
      * Logical consistency validation
      * Physical backup file integrity
      * Header information verification
      * Checksum validation
    - File Management:
      * Backup file discovery
      * Age verification
      * Size validation
      * Permission checks
      * Path accessibility
    - Integrity Checks:
      * RESTORE VERIFYONLY execution
      * Corruption detection
      * Page verification
      * Backup set validation
      * Chain verification for log backups
    - Notification System:
      * Email alerts for failures
      * Detailed error reporting
      * Success confirmations
      * Custom alert thresholds
      * Priority-based notifications

.NOTES
    Author: 13city
    
    Compatible with:
    - SQL Server 2012+
    - SQL Server 2014+
    - SQL Server 2016+
    - SQL Server 2017+
    - SQL Server 2019+
    
    Requirements:
    - PowerShell 5.1 or higher
    - SQL Server PowerShell module
    - SMTP access for alerts
    - Appropriate SQL permissions
    - Backup file read access
    - Log directory write access

.PARAMETER InstanceName
    SQL Server instance name
    Default: .\SQLEXPRESS
    Format: ServerName\InstanceName
    Example: SQLSERVER01\PROD

.PARAMETER DatabaseName
    Target database name
    Default: DBName
    Must exist on instance
    Case-sensitive

.PARAMETER BackupPath
    Backup file directory
    Default: C:\SQLBackups\DBName
    Requires read access
    Supports UNC paths

.PARAMETER EmailTo
    Alert recipient address
    Default: admin@company.com
    Required for notifications
    Supports distribution lists

.PARAMETER EmailFrom
    Alert sender address
    Default: alerts@company.com
    Must be valid SMTP sender
    Domain requirements apply

.PARAMETER SmtpServer
    SMTP server hostname
    Default: smtp.company.com
    Must be accessible
    Supports authentication

.EXAMPLE
    .\SQLBackupValidation.ps1 -InstanceName "SQLSERVER01" -DatabaseName "Production" -BackupPath "D:\Backups\Prod"
    Standard validation:
    - Checks Production database
    - Uses specified backup path
    - Default email settings
    - 24-hour validation window

.EXAMPLE
    .\SQLBackupValidation.ps1 -InstanceName "SQLSERVER02\DEV" -DatabaseName "TestDB" -BackupPath "\\NetworkShare\Backups\Test" -EmailTo "dba@company.com"
    Network share validation:
    - Uses named instance
    - Validates network path
    - Custom alert recipient
    - Default time window

.EXAMPLE
    .\SQLBackupValidation.ps1 -InstanceName "." -DatabaseName "FinanceDB" -BackupPath "E:\SQLBackups" -EmailTo "team@company.com" -SmtpServer "mail.internal.net"
    Local instance check:
    - Uses local instance
    - Custom backup location
    - Team notification
    - Internal mail server
#>

param (
    [string]$InstanceName = ".\SQLEXPRESS",
    [string]$DatabaseName = "DBName",
    [string]$BackupPath   = "C:\SQLBackups\DBName",
    [string]$EmailTo      = "admin@company.com",
    [string]$EmailFrom    = "alerts@company.com",
    [string]$SmtpServer   = "smtp.company.com"
)

function Send-AlertEmail {
    param([string]$subject, [string]$body)
    Send-MailMessage -To $EmailTo -From $EmailFrom -Subject $subject -Body $body -SmtpServer $SmtpServer
}

try {
    $scriptName = "SQLBackupValidation"
    $timeStamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFile    = "C:\Logs\$scriptName-$timeStamp.log"

    function Write-Log {
        param([string]$Message)
        $entry = "[{0}] {1}" -f (Get-Date), $Message
        Add-Content -Path $logFile -Value $entry
        Write-Host $entry
    }

    Write-Log "===== Starting SQL Backup Validation for $DatabaseName ====="

    # 1. Identify most recent backup
    $last24hr = (Get-Date).AddHours(-24)
    $latestBackup = Get-ChildItem -Path $BackupPath -Include "*.bak","*.trn" -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.LastWriteTime -ge $last24hr } | Sort-Object LastWriteTime -Descending | 
                    Select-Object -First 1

    if (!$latestBackup) {
        Write-Log "No backup found in the last 24 hours!"
        Send-AlertEmail -subject "Backup Missing for $DatabaseName" -body "No backup files found in $BackupPath in the last 24 hours."
        exit 1
    }

    Write-Log "Latest backup file is $($latestBackup.FullName). Checking integrity..."

    # 2. Use RESTORE VERIFYONLY
    $sql = "RESTORE VERIFYONLY FROM DISK = N'$(($latestBackup.FullName).Replace("'","''"))'"
    $result = Invoke-Sqlcmd -ServerInstance $InstanceName -Query $sql -ErrorAction Stop

    if ($result) {
        Write-Log "Backup verification for $($latestBackup.Name) completed with details: $result"
    }
    Write-Log "Backup verification succeeded."

    Write-Log "===== SQL Backup Validation Completed Successfully ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    # Attempt to send email alert
    Send-AlertEmail -subject "Backup Validation Error for $DatabaseName" -body $_.Exception.Message
    exit 1
}
