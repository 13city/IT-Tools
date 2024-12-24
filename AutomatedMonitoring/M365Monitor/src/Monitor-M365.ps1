#Requires -Version 7.0
#Requires -Modules @{ModuleName='Microsoft.Graph.Authentication'; ModuleVersion='2.0.0'},
                  @{ModuleName='ExchangeOnlineManagement'; ModuleVersion='3.0.0'},
                  @{ModuleName='MicrosoftTeams'; ModuleVersion='5.0.0'},
                  @{ModuleName='PnP.PowerShell'; ModuleVersion='2.0.0'}

using module '.\core\MonitoringEngine.ps1'
using module '.\monitors\ExchangeMonitor.ps1'
using module '.\monitors\SharePointMonitor.ps1'
using module '.\monitors\TeamsMonitor.ps1'

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ConfigPath = "..\config\config.json",

    [Parameter()]
    [switch]$ValidateOnly
)

# Initialize logging
$logPath = Join-Path $PSScriptRoot "..\logs"
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath | Out-Null
}

$logFile = Join-Path $logPath "monitor-$(Get-Date -Format 'yyyyMMdd').log"
Start-Transcript -Path $logFile -Append

try {
    Write-Host "Initializing M365 Monitoring Solution..."
    
    # Load and validate configuration
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found at: $ConfigPath"
    }

    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        Write-Host "Configuration loaded successfully"
    }
    catch {
        throw "Failed to parse configuration file: $_"
    }

    # Validate required configuration
    $requiredSettings = @(
        @{ Path = 'authentication.clientId'; Name = 'Client ID' }
        @{ Path = 'authentication.tenantId'; Name = 'Tenant ID' }
        @{ Path = 'authentication.certificateThumbprint'; Name = 'Certificate Thumbprint' }
        @{ Path = 'slack.webhookUrl'; Name = 'Slack Webhook URL' }
    )

    $missingSettings = $requiredSettings | Where-Object {
        $value = $config
        $_.Path.Split('.') | ForEach-Object {
            $value = $value.$_
        }
        [string]::IsNullOrWhiteSpace($value)
    }

    if ($missingSettings) {
        $missing = $missingSettings.Name -join ', '
        throw "Missing required configuration: $missing"
    }

    if ($ValidateOnly) {
        Write-Host "Configuration validation successful"
        return
    }

    # Initialize monitoring engine
    try {
        $engine = [MonitoringEngine]::new($ConfigPath)
        Write-Host "Monitoring engine initialized successfully"
    }
    catch {
        throw "Failed to initialize monitoring engine: $_"
    }

    # Initialize service monitors
    try {
        $exchangeMonitor = [ExchangeMonitor]::new($engine)
        $sharePointMonitor = [SharePointMonitor]::new($engine)
        $teamsMonitor = [TeamsMonitor]::new($engine)
        Write-Host "Service monitors initialized successfully"
    }
    catch {
        throw "Failed to initialize service monitors: $_"
    }

    # Register cleanup handler
    $cleanupBlock = {
        Write-Host "Stopping monitoring engine..."
        $engine.Stop()
        Stop-Transcript
    }
    
    trap {
        & $cleanupBlock
        throw $_
    }

    # Start monitoring loop
    Write-Host "Starting monitoring loop..."
    while ($true) {
        try {
            # Run service checks
            $exchangeMonitor.RunChecks()
            $sharePointMonitor.RunChecks()
            $teamsMonitor.RunChecks()

            # Process engine queue
            $engine.Start()

            # Rate limiting pause
            Start-Sleep -Seconds 1
        }
        catch {
            Write-Error "Error in monitoring loop: $_"
            # Continue running despite errors
            Start-Sleep -Seconds 30
        }
    }
}
catch {
    Write-Error "Fatal error: $_"
    throw
}
finally {
    & $cleanupBlock
}
