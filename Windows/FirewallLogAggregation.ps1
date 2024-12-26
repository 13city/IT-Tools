<# 
.SYNOPSIS
  Aggregates and parses firewall logs for security events or blocked traffic.

.DESCRIPTION
  This script:
  - Collects firewall logs from a specified network directory
  - Parses logs for security-relevant events including:
    * Blocked traffic attempts
    * Potential intrusion events
    * Access denials
  - Aggregates findings into a structured CSV report
  - Provides detailed logging of the aggregation process
  - Handles large log files efficiently
  - Supports recursive directory scanning

.NOTES
  Author: 13city
  Compatible with: Windows Server 2012 R2+, Windows 10/11
  Requirements: Network access to syslog server, Write access to output directory

.PARAMETER LogDirectory
  Network path to directory containing firewall logs
  Default: \\SyslogServer\Logs\SonicWALL

.PARAMETER OutputCsv
  Path where the aggregated CSV report will be saved
  Default: C:\Logs\FirewallLogsSummary.csv

.EXAMPLE
  .\FirewallLogAggregation.ps1
  Processes logs from default directory

.EXAMPLE
  .\FirewallLogAggregation.ps1 -LogDirectory "\\Server\Logs\Firewall" -OutputCsv "D:\Reports\Firewall.csv"
  Processes logs from custom directory with custom output location
#>

param(
    [string]$LogDirectory = "\\SyslogServer\Logs\SonicWALL",
    [string]$OutputCsv    = "C:\Logs\FirewallLogsSummary.csv"
)

try {
    $timeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $scriptName = "FirewallLogAggregation"
    $logFile = "C:\Logs\$scriptName-$timeStamp.log"

    function Write-Log {
        param([string]$Message)
        $entry = "[{0}] {1}" -f (Get-Date), $Message
        Add-Content -Path $logFile -Value $entry
        Write-Host $entry
    }

    Write-Log "===== Starting Firewall Log Aggregation ====="

    if (!(Test-Path $LogDirectory)) {
        Write-Log "Log directory not found: $LogDirectory"
        exit 1
    }

    $files = Get-ChildItem -Path $LogDirectory -Filter "*.log" -Recurse -ErrorAction SilentlyContinue
    if (!$files) {
        Write-Log "No log files found."
        exit 0
    }

    $results = @()
    foreach ($file in $files) {
        Write-Log "Parsing file: $($file.FullName)"
        $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            # Example pattern for blocked traffic
            if ($line -match "Blocked|Intrusion|Denied") {
                $time = $line.Substring(0,19)
                $message = $line
                $results += [PSCustomObject]@{
                    Timestamp = $time
                    LogFile   = $file.Name
                    Message   = $message
                }
            }
        }
    }

    if ($results.Count -gt 0) {
        $results | Export-Csv -Path $OutputCsv -NoTypeInformation
        Write-Log "Exported $($results.Count) matching entries to $OutputCsv"
    } else {
        Write-Log "No blocked or intrusion entries found."
    }

    Write-Log "===== Firewall Log Aggregation Completed ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
