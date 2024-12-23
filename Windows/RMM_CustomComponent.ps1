<# 
.SYNOPSIS
  Datto RMM Custom Script that performs system checks and returns structured output.

.DESCRIPTION
  - Gathers CPU, Memory, OS details.
  - Checks service status (e.g., MSSQLSERVER).
  - Outputs JSON for RMM ingestion.



# Datto RMM Custom Script

## Overview
A PowerShell script to collect system details (OS, CPU, Memory) and check a critical service (MSSQLSERVER). Outputs JSON that can be parsed by Datto RMM.

## Instructions
1. Upload this script to Datto RMM as a custom component.
2. Assign it to a policy or run on demand to gather system info.
3. The script returns 0 on success, 1 on failure. 
4. Standard output will be JSON for easy ingestion.

## Log File
- A local log file is created in C:\Logs for auditing.
- Contains script run info and system details.

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
