<# 
.SYNOPSIS
  Aggregates and parses firewall logs for security events or blocked traffic.

.DESCRIPTION
  - Collects logs from a specified directory (e.g., syslog server).
  - Searches for blocked traffic or intrusion events.
  - Outputs summarized CSV for easy review.
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
