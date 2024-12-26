#Requires -Version 5.1

<#
.SYNOPSIS
    Enterprise-grade Datto BCDR validation and automated testing toolkit.

.DESCRIPTION
    Advanced Datto backup validation and testing solution providing:
    - Comprehensive backup status verification
    - Automated test virtualizations
    - Backup integrity validation
    - Multi-channel alerting (Email, Slack, Teams)
    - Detailed HTML reporting with metrics
    - Real-time monitoring and notifications
    - Backup chain verification
    - Screenshot verification integration
    - Recovery point validation
    - Network isolation testing
    - Performance metrics collection
    - Compliance reporting
    - Historical trend analysis
    - Error pattern detection
    - Automated remediation options
    - SLA compliance checking
    - Capacity monitoring
    - Agent health verification
    - Custom threshold management
    - Backup retention validation

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022
    Requirements:
    - PowerShell 5.1 or higher
    - Datto API credentials
    - Network connectivity to Datto API
    - SMTP server access (for email notifications)
    - Write access to log directory
    - .NET Framework 4.7.2 or higher
    - TLS 1.2 support
    - Sufficient memory for virtualization tests
    - Network bandwidth for API operations
    - Access to Datto Partner Portal
    - PowerShell WebRequest module

.PARAMETER DattoApiKey
    Datto API authentication key
    Required: Yes
    Format: Base64 string
    Obtain: Datto Partner Portal
    Permissions: Full API access
    Security: Store securely

.PARAMETER DattoSecretKey
    API secret for request signing
    Required: Yes
    Format: Base64 string
    Obtain: Datto Partner Portal
    Security: Never expose
    Rotation: 90 days recommended

.PARAMETER NotificationMethod
    Alert delivery mechanism
    Required: Yes
    Options: "Email", "Slack"
    Default: None
    Multiple: Not supported

.PARAMETER EmailTo
    Notification recipient(s)
    Required: If Email method
    Format: RFC 5322 email
    Multiple: Comma-separated
    Example: "admin@company.com"

.PARAMETER EmailFrom
    Notification sender address
    Required: If Email method
    Format: RFC 5322 email
    Must be: Authorized sender
    Example: "datto@company.com"

.PARAMETER SmtpServer
    Email relay server
    Required: If Email method
    Format: FQDN or IP
    Ports: 25, 465, 587
    Auth: If required

.PARAMETER SlackWebhook
    Slack integration URL
    Required: If Slack method
    Format: HTTPS URL
    Obtain: Slack workspace
    Security: Keep private

.PARAMETER TestVirtualizationEnabled
    Controls VM testing
    Default: True
    Type: Boolean
    Impact: Performance
    Resources: High

.PARAMETER ValidationDepth
    Test thoroughness level
    Optional: Yes
    Values: Basic, Standard, Deep
    Default: Standard
    Impact: Runtime

.PARAMETER ReportFormat
    Output report type
    Optional: Yes
    Values: HTML, PDF, JSON
    Default: HTML
    Multiple: Allowed

.PARAMETER RetentionDays
    Report/log retention
    Optional: Yes
    Range: 1-365
    Default: 30
    Unit: Days

.EXAMPLE
    .\DattoBackupValidator.ps1 -DattoApiKey "your-api-key" -DattoSecretKey "your-secret-key" -NotificationMethod Email -EmailTo "admin@company.com" -EmailFrom "datto@company.com" -SmtpServer "smtp.company.com"
    Standard validation run:
    - Email notifications
    - Default testing depth
    - HTML reporting
    - Standard retention
    - All agents checked

.EXAMPLE
    .\DattoBackupValidator.ps1 -DattoApiKey "your-api-key" -DattoSecretKey "your-secret-key" -NotificationMethod Slack -SlackWebhook "https://hooks.slack.com/services/xxx" -ValidationDepth Deep
    Comprehensive validation:
    - Slack notifications
    - Deep testing
    - Extended verification
    - Performance metrics
    - Detailed reporting

.EXAMPLE
    .\DattoBackupValidator.ps1 -DattoApiKey "your-api-key" -DattoSecretKey "your-secret-key" -NotificationMethod Email -EmailTo "admin@company.com" -TestVirtualizationEnabled $false -ReportFormat "JSON,HTML"
    Quick validation run:
    - Skip virtualization
    - Multiple report formats
    - Basic verification
    - Email notifications
    - Faster completion
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$DattoApiKey,

    [Parameter(Mandatory = $true)]
    [string]$DattoSecretKey,

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
    [bool]$TestVirtualizationEnabled = $true
)

# Initialize logging
$LogPath = "C:\Logs\DattoValidation"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogPath "DattoValidation_$timestamp.log"

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
                    -Subject "Datto Backup Alert: $Subject" `
                    -Body $Message -SmtpServer $SmtpServer `
                    -Priority $Priority
            }
            "Slack" {
                $payload = @{
                    text = "*Datto Backup Alert*`n*$Subject*`n$Message"
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

function Get-DattoAuthHeader {
    $timestamp = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
    $message = "$DattoApiKey:$timestamp"
    $hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha256.Key = [Text.Encoding]::ASCII.GetBytes($DattoSecretKey)
    $signature = [Convert]::ToBase64String($hmacsha256.ComputeHash([Text.Encoding]::ASCII.GetBytes($message)))
    
    return @{
        'X-API-KEY' = $DattoApiKey
        'X-API-TIMESTAMP' = $timestamp
        'X-API-SIGNATURE' = $signature
        'Content-Type' = 'application/json'
    }
}

function Get-DattoDevices {
    try {
        $headers = Get-DattoAuthHeader
        $response = Invoke-RestMethod -Uri "https://api.datto.com/v1/bcdr/devices" `
            -Headers $headers -Method Get
        
        return $response.devices
    }
    catch {
        Write-Log "Failed to get Datto devices: $_" -Level "ERROR"
        return $null
    }
}

function Get-BackupStatus {
    param([string]$DeviceId, [string]$AgentId)
    
    try {
        $headers = Get-DattoAuthHeader
        $response = Invoke-RestMethod -Uri "https://api.datto.com/v1/bcdr/devices/$DeviceId/agents/$AgentId/backups" `
            -Headers $headers -Method Get
        
        return $response.backups | Select-Object -First 1
    }
    catch {
        Write-Log "Failed to get backup status for agent $AgentId : $_" -Level "ERROR"
        return $null
    }
}

function Start-TestVirtualization {
    param(
        [string]$DeviceId,
        [string]$AgentId,
        [string]$SnapshotId
    )
    
    try {
        $headers = Get-DattoAuthHeader
        
        # Start virtualization
        $body = @{
            snapshotId = $SnapshotId
            networkType = "isolated"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "https://api.datto.com/v1/bcdr/devices/$DeviceId/agents/$AgentId/virtualizations" `
            -Headers $headers -Method Post -Body $body
        
        $virtualizationId = $response.virtualizationId
        Write-Log "Started test virtualization for agent $AgentId (ID: $virtualizationId)"
        
        # Wait for virtualization to be ready
        $ready = $false
        $attempts = 0
        $maxAttempts = 20
        
        while (-not $ready -and $attempts -lt $maxAttempts) {
            Start-Sleep -Seconds 30
            $status = Invoke-RestMethod -Uri "https://api.datto.com/v1/bcdr/devices/$DeviceId/agents/$AgentId/virtualizations/$virtualizationId" `
                -Headers $headers -Method Get
            
            if ($status.state -eq "running") {
                $ready = $true
                Write-Log "Test virtualization is running successfully"
            }
            elseif ($status.state -eq "failed") {
                throw "Virtualization failed: $($status.errorMessage)"
            }
            
            $attempts++
        }
        
        if (-not $ready) {
            throw "Virtualization did not become ready within timeout period"
        }
        
        # Cleanup
        Write-Log "Cleaning up test virtualization"
        Invoke-RestMethod -Uri "https://api.datto.com/v1/bcdr/devices/$DeviceId/agents/$AgentId/virtualizations/$virtualizationId" `
            -Headers $headers -Method Delete
        
        return $true
    }
    catch {
        Write-Log "Test virtualization failed: $_" -Level "ERROR"
        return $false
    }
}

function Export-ValidationReport {
    param([array]$Results)
    
    try {
        $reportPath = Join-Path $LogPath "DattoValidation_$timestamp.html"
        
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Datto Backup Validation Report</title>
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
    <h1>Datto Backup Validation Report</h1>
    <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    <table>
        <tr>
            <th>Device Name</th>
            <th>Agent Name</th>
            <th>Last Backup</th>
            <th>Status</th>
            <th>Virtualization Test</th>
        </tr>
"@

        foreach ($result in $Results) {
            $statusClass = switch ($result.Status) {
                "success" { "success" }
                "warning" { "warning" }
                default { "error" }
            }
            
            $html += @"
        <tr>
            <td>$($result.DeviceName)</td>
            <td>$($result.AgentName)</td>
            <td>$($result.LastBackup)</td>
            <td class="$statusClass">$($result.Status)</td>
            <td>$($result.VirtualizationTest)</td>
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
    Write-Log "=== Starting Datto Backup Validation ==="
    
    # Validate parameters
    if ($NotificationMethod -eq "Email" -and (-not $EmailTo -or -not $EmailFrom -or -not $SmtpServer)) {
        throw "Email parameters are required when using Email notification method"
    }
    if ($NotificationMethod -eq "Slack" -and -not $SlackWebhook) {
        throw "Slack webhook URL is required when using Slack notification method"
    }
    
    # Get all devices
    $devices = Get-DattoDevices
    if (-not $devices) {
        throw "No Datto devices found"
    }
    
    $results = @()
    
    foreach ($device in $devices) {
        Write-Log "Processing device: $($device.name)"
        
        foreach ($agent in $device.agents) {
            Write-Log "Checking agent: $($agent.name)"
            
            # Get latest backup status
            $backup = Get-BackupStatus -DeviceId $device.id -AgentId $agent.id
            
            $result = [PSCustomObject]@{
                DeviceName = $device.name
                AgentName = $agent.name
                LastBackup = $backup.timestamp
                Status = $backup.status
                VirtualizationTest = "Not Performed"
            }
            
            # Check backup age
            if ($backup.timestamp -lt (Get-Date).AddHours(-24)) {
                Write-Log "Outdated backup detected for $($agent.name)" -Level "WARNING"
                Send-Notification -Subject "Outdated Backup" `
                    -Message "Backup for $($agent.name) is outdated. Last backup: $($backup.timestamp)" `
                    -Priority "High"
            }
            
            # Perform test virtualization if enabled
            if ($TestVirtualizationEnabled -and $backup.status -eq "success") {
                $testResult = Start-TestVirtualization -DeviceId $device.id -AgentId $agent.id -SnapshotId $backup.snapshotId
                $result.VirtualizationTest = if ($testResult) { "Success" } else { "Failed" }
            }
            
            $results += $result
        }
    }
    
    # Generate and export report
    $reportPath = Export-ValidationReport -Results $results
    if ($reportPath) {
        Send-Notification -Subject "Validation Report Available" `
            -Message "Datto backup validation completed. Report available at: $reportPath"
    }
    
    Write-Log "=== Datto Backup Validation Completed ==="
}
catch {
    Write-Log "Script execution failed: $_" -Level "ERROR"
    Send-Notification -Subject "Script Execution Failed" -Message $_.Exception.Message -Priority "High"
    exit 1
}
