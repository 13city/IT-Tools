#Requires -Version 5.1

<#
.SYNOPSIS
    Validates Datto backup jobs and performs test restores using Datto API.

.DESCRIPTION
    This script:
    - Connects to Datto API
    - Verifies backup status for all protected systems
    - Performs test virtualizations
    - Validates backup integrity
    - Sends notifications via email or Slack
    - Generates detailed validation reports

.PARAMETER DattoApiKey
    Datto API key for authentication

.PARAMETER DattoSecretKey
    Datto API secret key

.PARAMETER NotificationMethod
    Email or Slack for notifications

.PARAMETER EmailTo
    Email recipients for notifications

.PARAMETER EmailFrom
    From address for email notifications

.PARAMETER SmtpServer
    SMTP server for email notifications

.PARAMETER SlackWebhook
    Slack webhook URL for notifications

.PARAMETER TestVirtualizationEnabled
    Enable/disable test virtualization functionalityComplex Network Print Environments & Dental-Specific Software
Prompt:
"Generate a troubleshooting script for a Windows environment that diagnoses issues with networked printers and common dental office software (e.g., Dentrix, Eaglesoft). The script should check printer drivers, spooler service status, connectivity to shared drives or databases, and parse logs for known software-related errors."

Why it works:

Targets dental-specific IT challenges like Dentrix or Eaglesoft.
Demonstrates advanced printing and software troubleshooting.

.EXAMPLE
    .\DattoBackupValidator.ps1 -DattoApiKey "your-api-key" -DattoSecretKey "your-secret-key" -NotificationMethod Email -EmailTo "admin@company.com"
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
