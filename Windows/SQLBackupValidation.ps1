<# 
.SYNOPSIS
  Validates recent SQL backups, checks integrity, and sends alert if issues are found.

.DESCRIPTION
  - Verifies if backup files exist for the last 24 hours.
  - Uses RESTORE VERIFYONLY to check logical consistency.
  - Sends email alert if validation fails.

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
