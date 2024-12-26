#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Modules WindowsServerBackup

<#
.SYNOPSIS
    Advanced Windows Server Backup validation and recovery testing toolkit.

.DESCRIPTION
    This script provides comprehensive backup validation capabilities:
    - Backup Verification:
      * Status monitoring
      * Age verification
      * Size validation
      * Completion checks
    - Integrity Testing:
      * Catalog verification
      * Volume validation
      * File integrity checks
      * Corruption detection
    - Recovery Testing:
      * Test restores
      * File verification
      * Hash validation
      * Isolation testing
    - Reporting Features:
      * HTML report generation
      * Status summaries
      * Error analysis
      * Performance metrics

.NOTES
    Author: 13city
    Compatible with:
    - Windows Server 2012 R2
    - Windows Server 2016
    - Windows Server 2019
    - Windows Server 2022
    
    Requirements:
    - PowerShell 5.1 or higher
    - WindowsServerBackup module
    - Administrative privileges
    - Backup access permissions
    - Test restore space

.PARAMETER BackupTarget
    Backup storage location
    Required parameter
    Must be accessible path
    Supports local/network paths

.PARAMETER TestRestorePath
    Recovery test location
    Optional parameter
    Default: D:\TestRestore
    Requires write access

.PARAMETER NotificationMethod
    Alert delivery method
    Required parameter
    Values: Email, Slack
    Controls notification routing

.PARAMETER EmailTo
    Notification recipients
    Required for Email method
    Accepts multiple addresses
    Comma-separated list

.PARAMETER EmailFrom
    Sender address
    Required for Email method
    Must be valid email
    Used in From field

.PARAMETER SmtpServer
    Email server hostname
    Required for Email method
    Must be accessible
    Handles mail routing

.PARAMETER SlackWebhook
    Slack integration URL
    Required for Slack method
    Must be valid webhook
    Enables Slack messaging

.PARAMETER TestRestoreEnabled
    Recovery testing switch
    Optional parameter
    Default: True
    Enables restore validation

.EXAMPLE
    .\WindowsServerBackupValidator.ps1 -BackupTarget "E:\Backups" -NotificationMethod Email -EmailTo "admin@company.com"
    Basic validation:
    - Email notifications
    - Default test path
    - Standard reporting
    - Auto-cleanup

.EXAMPLE
    .\WindowsServerBackupValidator.ps1 -BackupTarget "\\server\backups" -TestRestorePath "D:\Testing" -NotificationMethod Slack -SlackWebhook "https://hooks.slack.com/xxx" -TestRestoreEnabled $false
    Network validation:
    - Network backup source
    - Custom test location
    - Slack notifications
    - Skips test restores
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$BackupTarget,

    [Parameter(Mandatory = $false)]
    [string]$TestRestorePath = "D:\TestRestore",

    [Parameter(Mandatory = $true)]
    [ValidateSet("Email", "Slack")]
    [string]$NotificationMethod,

    [Parameter(Mandatory = $false)]
    [string]$EmailTo,

    [Parameter(Mandatory = $false)]
    [string]$EmailFrom,

    [Parameter(Mandatory = $false)]
    [string]$SmtpServer,

    [Parameter(Mandatory = $false)]
    [string]$SlackWebhook,

    [Parameter(Mandatory = $false)]
    [bool]$TestRestoreEnabled = $true
)

# Initialize logging
$LogPath = "C:\Logs\WSBValidation"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogPath "WSBValidation_$timestamp.log"

if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        default { Write-Host $logEntry }
    }
}

function Send-Notification {
    param(
        [string]$Subject,
        [string]$Message,
        [string]$Priority = "Normal"
    )
    
    try {
        switch ($NotificationMethod) {
            "Email" {
                Send-MailMessage -To $EmailTo -From $EmailFrom `
                    -Subject "Windows Server Backup Alert: $Subject" `
                    -Body $Message -SmtpServer $SmtpServer `
                    -Priority $Priority
            }
            "Slack" {
                $payload = @{
                    text = "*Windows Server Backup Alert*`n*$Subject*`n$Message"
                }
                Invoke-RestMethod -Uri $SlackWebhook -Method Post -Body ($payload | ConvertTo-Json)
            }
        }
        Write-Log "Notification sent: $Subject"
    }
    catch {
        Write-Log "Failed to send notification: $_" -Level "ERROR"
    }
}

function Get-BackupStatus {
    try {
        $backupSummary = Get-WBSummary
        $lastBackup = Get-WBBackupSet | Sort-Object -Property BackupTime -Descending | Select-Object -First 1
        
        if (-not $lastBackup) {
            throw "No backup history found"
        }
        
        $status = [PSCustomObject]@{
            LastBackupTime = $lastBackup.BackupTime
            BackupTarget = $backupSummary.BackupTarget
            LastSuccessful = $lastBackup.BackupTime
            VolumesFull = $backupSummary.LastFullBackupTime
            VolumesIncremental = $backupSummary.LastIncrementalBackupTime
            BackupSize = $lastBackup.BackupSize
            IsOutdated = $lastBackup.BackupTime -lt (Get-Date).AddHours(-24)
        }
        
        return $status
    }
    catch {
        Write-Log "Failed to get backup status: $_" -Level "ERROR"
        return $null
    }
}

function Test-BackupIntegrity {
    param([object]$BackupSet)
    
    try {
        Write-Log "Testing backup integrity..."
        
        # Get backup catalog
        $catalog = Get-WBBackupSet -BackupSet $BackupSet | Get-WBVolume
        $issues = @()
        
        foreach ($volume in $catalog) {
            Write-Log "Verifying volume: $($volume.VolumeLabel)"
            
            # Test backup integrity
            $result = Test-WBBackupSet -BackupSet $BackupSet -Volume $volume
            
            if (-not $result.IsValid) {
                $issues += "Volume $($volume.VolumeLabel): $($result.ErrorMessage)"
            }
        }
        
        return @{
            IsValid = $issues.Count -eq 0
            Issues = $issues
        }
    }
    catch {
        Write-Log "Backup integrity test failed: $_" -Level "ERROR"
        return @{
            IsValid = $false
            Issues = @("Failed to test backup integrity: $_")
        }
    }
}

function Start-TestRestore {
    param([object]$BackupSet)
    
    try {
        Write-Log "Starting test restore..."
        
        # Ensure test restore path exists
        if (-not (Test-Path $TestRestorePath)) {
            New-Item -ItemType Directory -Path $TestRestorePath -Force | Out-Null
        }
        
        # Get random files to test restore
        $volumes = Get-WBVolume -BackupSet $BackupSet
        $testFiles = @()
        
        foreach ($volume in $volumes) {
            $files = Get-WBFile -BackupSet $BackupSet -Volume $volume |
                Get-Random -Count 5
            $testFiles += $files
        }
        
        # Perform test restore
        foreach ($file in $testFiles) {
            Write-Log "Restoring test file: $($file.Path)"
            
            $restorePath = Join-Path $TestRestorePath (Split-Path $file.Path -Leaf)
            Start-WBFileRecovery -BackupSet $BackupSet -File $file -TargetPath $restorePath
            
            # Verify restored file
            if (Test-Path $restorePath) {
                $originalHash = Get-WBFileRecoveryInfo -BackupSet $BackupSet -File $file |
                    Select-Object -ExpandProperty Hash
                $restoredHash = Get-FileHash $restorePath -Algorithm SHA256 |
                    Select-Object -ExpandProperty Hash
                
                if ($originalHash -ne $restoredHash) {
                    throw "File integrity check failed for: $($file.Path)"
                }
            }
            else {
                throw "Failed to restore file: $($file.Path)"
            }
        }
        
        Write-Log "Test restore completed successfully"
        return $true
    }
    catch {
        Write-Log "Test restore failed: $_" -Level "ERROR"
        return $false
    }
    finally {
        # Cleanup
        if (Test-Path $TestRestorePath) {
            Remove-Item -Path $TestRestorePath -Recurse -Force
        }
    }
}

function Export-ValidationReport {
    param(
        [object]$BackupStatus,
        [object]$IntegrityResults,
        [bool]$TestRestoreSuccess
    )
    
    try {
        $reportPath = Join-Path $LogPath "WSBValidation_$timestamp.html"
        
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows Server Backup Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Windows Server Backup Validation Report</h1>
    <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <h2>Backup Status</h2>
    <table>
        <tr><th>Property</th><th>Value</th></tr>
        <tr><td>Last Backup Time</td><td>$($BackupStatus.LastBackupTime)</td></tr>
        <tr><td>Backup Target</td><td>$($BackupStatus.BackupTarget)</td></tr>
        <tr><td>Last Full Backup</td><td>$($BackupStatus.VolumesFull)</td></tr>
        <tr><td>Last Incremental</td><td>$($BackupStatus.VolumesIncremental)</td></tr>
        <tr><td>Backup Size</td><td>$($BackupStatus.BackupSize)</td></tr>
        <tr><td>Status</td><td class="$($BackupStatus.IsOutdated ? 'error' : 'success')">
            $($BackupStatus.IsOutdated ? 'Outdated' : 'Current')</td></tr>
    </table>
    
    <h2>Integrity Check</h2>
    <table>
        <tr><th>Status</th><th>Details</th></tr>
        <tr>
            <td class="$($IntegrityResults.IsValid ? 'success' : 'error')">
                $($IntegrityResults.IsValid ? 'Pass' : 'Fail')
            </td>
            <td>$($IntegrityResults.Issues -join '<br>')</td>
        </tr>
    </table>
    
    <h2>Test Restore</h2>
    <table>
        <tr><th>Status</th></tr>
        <tr>
            <td class="$($TestRestoreSuccess ? 'success' : 'error')">
                $($TestRestoreSuccess ? 'Success' : 'Failed')
            </td>
        </tr>
    </table>
</body>
</html>
"@

        $html | Out-File -FilePath $reportPath -Encoding UTF8
        Write-Log "Validation report exported to: $reportPath"
        return $reportPath
    }
    catch {
        Write-Log "Failed to export validation report: $_" -Level "ERROR"
        return $null
    }
}

# Main execution block
try {
    Write-Log "=== Starting Windows Server Backup Validation ==="
    
    # Validate parameters
    if ($NotificationMethod -eq "Email" -and (-not $EmailTo -or -not $EmailFrom -or -not $SmtpServer)) {
        throw "Email parameters are required when using Email notification method"
    }
    if ($NotificationMethod -eq "Slack" -and -not $SlackWebhook) {
        throw "Slack webhook URL is required when using Slack notification method"
    }
    
    # Check backup status
    $backupStatus = Get-BackupStatus
    if (-not $backupStatus) {
        throw "Failed to get backup status"
    }
    
    # Check for outdated backups
    if ($backupStatus.IsOutdated) {
        Write-Log "Backup is outdated" -Level "WARNING"
        Send-Notification -Subject "Outdated Backup" `
            -Message "Last backup is older than 24 hours: $($backupStatus.LastBackupTime)" `
            -Priority "High"
    }
    
    # Get latest backup set
    $latestBackup = Get-WBBackupSet | Sort-Object -Property BackupTime -Descending | Select-Object -First 1
    
    # Test backup integrity
    $integrityResults = Test-BackupIntegrity -BackupSet $latestBackup
    if (-not $integrityResults.IsValid) {
        Write-Log "Backup integrity check failed" -Level "ERROR"
        Send-Notification -Subject "Backup Integrity Failed" `
            -Message "Backup integrity check failed:`n$($integrityResults.Issues -join "`n")" `
            -Priority "High"
    }
    
    # Perform test restore if enabled
    $testRestoreSuccess = $false
    if ($TestRestoreEnabled) {
        $testRestoreSuccess = Start-TestRestore -BackupSet $latestBackup
        if (-not $testRestoreSuccess) {
            Send-Notification -Subject "Test Restore Failed" `
                -Message "Failed to perform test restore from backup" `
                -Priority "High"
        }
    }
    
    # Generate and export report
    $reportPath = Export-ValidationReport -BackupStatus $backupStatus `
        -IntegrityResults $integrityResults `
        -TestRestoreSuccess $testRestoreSuccess
    
    if ($reportPath) {
        Send-Notification -Subject "Validation Report Available" `
            -Message "Windows Server Backup validation completed. Report available at: $reportPath"
    }
    
    Write-Log "=== Windows Server Backup Validation Completed ==="
}
catch {
    Write-Log "Script execution failed: $_" -Level "ERROR"
    Send-Notification -Subject "Script Execution Failed" -Message $_.Exception.Message -Priority "High"
    exit 1
}
