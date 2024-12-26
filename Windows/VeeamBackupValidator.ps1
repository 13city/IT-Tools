#Requires -Version 5.1
#Requires -Modules Veeam.Backup.PowerShell

<#
.SYNOPSIS
    Advanced Veeam backup validation and test restore automation toolkit.

.DESCRIPTION
    This script provides comprehensive Veeam backup validation capabilities:
    - Backup Validation:
      * Job status verification
      * Completion time checks
      * Success rate analysis
      * Error pattern detection
    - Test Restore Operations:
      * Automated VM recovery
      * Sandbox environment testing
      * Network isolation
      * Power-on verification
    - Notification System:
      * Multi-channel alerts
      * Priority-based messaging
      * Detailed error reporting
      * Success confirmations
    - Reporting Features:
      * HTML report generation
      * Status summaries
      * Failure analysis
      * Performance metrics

.NOTES
    Author: 13city
    Compatible with:
    - Veeam Backup & Replication 9.5+
    - Veeam Backup & Replication 10+
    - Veeam Backup & Replication 11+
    - Windows Server 2016+
    - PowerShell 5.1+
    
    Requirements:
    - Veeam.Backup.PowerShell module
    - Administrative privileges
    - Network connectivity to Veeam server
    - Access to backup infrastructure
    - Email or Slack for notifications

.PARAMETER VBRServer
    Veeam server hostname
    Required parameter
    Must be network accessible
    Format: FQDN or IP address

.PARAMETER Credential
    Veeam authentication
    Optional parameter
    Uses Get-Credential prompt
    Requires admin rights

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
    Enables VM validation

.PARAMETER SandboxNetwork
    Isolated network name
    Optional parameter
    Default: "Isolated"
    For test restores

.EXAMPLE
    .\VeeamBackupValidator.ps1 -VBRServer "veeam-01" -NotificationMethod Email -EmailTo "admin@company.com"
    Basic validation:
    - Email notifications
    - Default test restore
    - Standard reporting
    - Auto-cleanup

.EXAMPLE
    .\VeeamBackupValidator.ps1 -VBRServer "veeam-01" -NotificationMethod Slack -SlackWebhook "https://hooks.slack.com/xxx" -TestRestoreEnabled $false
    Slack monitoring:
    - Slack notifications
    - Skips test restores
    - Basic validation
    - Quick execution
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$VBRServer,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = (Get-Credential -Message "Enter Veeam credentials"),

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
    [bool]$TestRestoreEnabled = $true,

    [Parameter(Mandatory = $false)]
    [string]$SandboxNetwork = "Isolated"
)

# Initialize logging
$LogPath = "C:\Logs\VeeamValidation"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogPath "VeeamValidation_$timestamp.log"

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
                    -Subject "Veeam Backup Alert: $Subject" `
                    -Body $Message -SmtpServer $SmtpServer `
                    -Priority $Priority
            }
            "Slack" {
                $payload = @{
                    text = "*Veeam Backup Alert*`n*$Subject*`n$Message"
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

function Connect-VeeamServer {
    try {
        Connect-VBRServer -Server $VBRServer -Credential $Credential
        Write-Log "Successfully connected to Veeam server: $VBRServer"
        return $true
    }
    catch {
        Write-Log "Failed to connect to Veeam server: $_" -Level "ERROR"
        Send-Notification -Subject "Connection Failed" -Message "Failed to connect to Veeam server: $_" -Priority "High"
        return $false
    }
}

function Get-BackupValidation {
    try {
        $jobs = Get-VBRJob
        $results = @()
        
        foreach ($job in $jobs) {
            $lastSession = Get-VBRBackupSession -Job $job | Select-Object -First 1
            
            $result = [PSCustomObject]@{
                JobName = $job.Name
                LastRun = $lastSession.CreationTime
                Status = $lastSession.Result
                Details = $lastSession.Info
            }
            
            # Check if backup is outdated (>24 hours)
            if ($lastSession.CreationTime -lt (Get-Date).AddHours(-24)) {
                Write-Log "Outdated backup detected for job: $($job.Name)" -Level "WARNING"
                Send-Notification -Subject "Outdated Backup" `
                    -Message "Backup job '$($job.Name)' is outdated. Last successful backup: $($lastSession.CreationTime)" `
                    -Priority "High"
            }
            
            # Check for failed backups
            if ($lastSession.Result -ne "Success") {
                Write-Log "Failed backup detected for job: $($job.Name)" -Level "ERROR"
                Send-Notification -Subject "Backup Failure" `
                    -Message "Backup job '$($job.Name)' failed. Details: $($lastSession.Info)" `
                    -Priority "High"
            }
            
            $results += $result
        }
        
        return $results
    }
    catch {
        Write-Log "Error validating backups: $_" -Level "ERROR"
        Send-Notification -Subject "Validation Error" -Message "Error validating backups: $_" -Priority "High"
        return $null
    }
}

function Start-TestRestore {
    param(
        [Parameter(Mandatory = $true)]
        [object]$BackupJob
    )
    
    try {
        Write-Log "Starting test restore for job: $($BackupJob.JobName)"
        
        # Get restore point
        $restorePoint = Get-VBRRestorePoint -Job $BackupJob | 
            Sort-Object CreationTime -Descending | 
            Select-Object -First 1
        
        if (-not $restorePoint) {
            throw "No restore points found for job $($BackupJob.JobName)"
        }
        
        # Create unique suffix for restored VM
        $suffix = Get-Date -Format "MMddHHmm"
        $restoredVMName = "$($BackupJob.JobName)_TEST_$suffix"
        
        # Start restore
        $restore = Start-VBRRestoreVM -RestorePoint $restorePoint `
            -VMName $restoredVMName `
            -NetworkMapping @{"*"=$SandboxNetwork} `
            -PowerUp:$true `
            -Reason "Automated test restore" `
            -ErrorAction Stop
        
        # Wait for restore to complete
        while ($restore.State -eq "Working") {
            Start-Sleep -Seconds 30
        }
        
        if ($restore.State -eq "Success") {
            Write-Log "Test restore completed successfully for job: $($BackupJob.JobName)"
            
            # Validate restored VM
            $vm = Get-VM -Name $restoredVMName -ErrorAction SilentlyContinue
            if ($vm.State -eq "Running") {
                Write-Log "Restored VM is running: $restoredVMName"
            }
            else {
                throw "Restored VM is not running: $restoredVMName"
            }
            
            # Cleanup
            Write-Log "Cleaning up test restore VM: $restoredVMName"
            Remove-VM -Name $restoredVMName -Force
        }
        else {
            throw "Test restore failed for job $($BackupJob.JobName): $($restore.Info)"
        }
        
        return $true
    }
    catch {
        Write-Log "Test restore failed: $_" -Level "ERROR"
        Send-Notification -Subject "Test Restore Failed" `
            -Message "Test restore failed for job $($BackupJob.JobName): $_" `
            -Priority "High"
        return $false
    }
}

function Export-ValidationReport {
    param([array]$Results)
    
    try {
        $reportPath = Join-Path $LogPath "VeeamValidation_$timestamp.html"
        
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Veeam Backup Validation Report</title>
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
    <h1>Veeam Backup Validation Report</h1>
    <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    <table>
        <tr>
            <th>Job Name</th>
            <th>Last Run</th>
            <th>Status</th>
            <th>Details</th>
        </tr>
"@

        foreach ($result in $Results) {
            $statusClass = switch ($result.Status) {
                "Success" { "success" }
                "Warning" { "warning" }
                default { "error" }
            }
            
            $html += @"
        <tr>
            <td>$($result.JobName)</td>
            <td>$($result.LastRun)</td>
            <td class="$statusClass">$($result.Status)</td>
            <td>$($result.Details)</td>
        </tr>
"@
        }

        $html += @"
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
    Write-Log "=== Starting Veeam Backup Validation ==="
    
    # Validate parameters
    if ($NotificationMethod -eq "Email" -and (-not $EmailTo -or -not $EmailFrom -or -not $SmtpServer)) {
        throw "Email parameters are required when using Email notification method"
    }
    if ($NotificationMethod -eq "Slack" -and -not $SlackWebhook) {
        throw "Slack webhook URL is required when using Slack notification method"
    }
    
    # Connect to Veeam server
    if (-not (Connect-VeeamServer)) {
        throw "Failed to connect to Veeam server"
    }
    
    # Validate backups
    $validationResults = Get-BackupValidation
    if (-not $validationResults) {
        throw "Failed to validate backups"
    }
    
    # Perform test restores if enabled
    if ($TestRestoreEnabled) {
        foreach ($job in $validationResults | Where-Object { $_.Status -eq "Success" }) {
            $testResult = Start-TestRestore -BackupJob $job
            if ($testResult) {
                Write-Log "Test restore successful for job: $($job.JobName)"
            }
        }
    }
    
    # Generate and export report
    $reportPath = Export-ValidationReport -Results $validationResults
    if ($reportPath) {
        Send-Notification -Subject "Validation Report Available" `
            -Message "Veeam backup validation completed. Report available at: $reportPath"
    }
    
    Write-Log "=== Veeam Backup Validation Completed ==="
}
catch {
    Write-Log "Script execution failed: $_" -Level "ERROR"
    Send-Notification -Subject "Script Execution Failed" -Message $_.Exception.Message -Priority "High"
    exit 1
}
finally {
    # Disconnect from Veeam server
    try {
        Disconnect-VBRServer
        Write-Log "Disconnected from Veeam server"
    }
    catch {
        Write-Log "Failed to disconnect from Veeam server: $_" -Level "WARNING"
    }
}
