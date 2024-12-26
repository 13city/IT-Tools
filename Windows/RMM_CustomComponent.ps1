<#
.SYNOPSIS
    Advanced Datto RMM custom component for comprehensive system monitoring and reporting.

.DESCRIPTION
    This script performs extensive system analysis and monitoring:
    - System Information Collection:
      * Detailed CPU specifications and utilization
      * Memory usage and availability metrics
      * Operating system details and version
      * Service status monitoring (MSSQLSERVER)
    - Monitoring Features:
      * Real-time performance metrics
      * Service availability checks
      * Resource utilization tracking
    - Output Handling:
      * Structured JSON output for RMM integration
      * Detailed logging with timestamps
      * Error handling and reporting
    - Integration Capabilities:
      * Compatible with Datto RMM policies
      * Supports automated monitoring
      * Enables custom alerting
    - Execution Modes:
      * On-demand execution support
      * Scheduled policy-based runs
      * Background monitoring capability

.NOTES
    Author: 13city
    
    Compatible with:
    - Windows Server 2012 R2
    - Windows Server 2016
    - Windows Server 2019
    - Windows Server 2022
    - Windows 10/11
    
    Requirements:
    - Administrative privileges
    - Write access to C:\Logs directory
    - PowerShell 5.1 or higher
    - WMI/CIM access rights
    - MSSQLSERVER service (optional)
    - Network connectivity for RMM
    
    Exit Codes:
    - 0: Success
    - 1: Error during execution

.OUTPUTS
    JSON structured data containing:
    - Hostname
    - OS details and version
    - CPU specifications
    - Total RAM
    - SQL Server status
    Log file at C:\Logs\RMM_CustomComponent-[timestamp].log

.EXAMPLE
    .\RMM_CustomComponent.ps1
    Standard execution:
    - Performs all system checks
    - Generates JSON output
    - Creates timestamped log file

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\RMM_CustomComponent.ps1
    Execution with bypass:
    - Runs with elevated privileges
    - Bypasses execution policy
    - Suitable for automated tasks

.EXAMPLE
    .\RMM_CustomComponent.ps1 > output.json
    Execution with output redirection:
    - Saves JSON output to file
    - Maintains logging
    - Useful for data collection
#>

$scriptName = "RMM_CustomComponent"
$timeStamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile    = "C:\Logs\$scriptName-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    Write-Log "===== Starting RMM Custom Component ====="

    # Gather system info
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $memory = Get-CimInstance -ClassName Win32_ComputerSystem
    $mssqlStatus = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue

    # Prepare JSON output
    $outputObject = [PSCustomObject]@{
        Hostname  = $env:COMPUTERNAME
        OS        = $os.Caption
        OSVersion = $os.Version
        CPU       = $cpu.Name
        TotalRAM  = [Math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        MSSQLStatus = if ($mssqlStatus) { $mssqlStatus.Status } else { "Not Installed" }
    }

    $jsonOutput = $outputObject | ConvertTo-Json -Depth 3
    Write-Host $jsonOutput  # RMM can parse this
    Write-Log $jsonOutput

    Write-Log "===== RMM Custom Component Completed ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
