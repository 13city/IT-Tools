<# 
.SYNOPSIS
  Analyzes Windows Event Logs for critical or error events in the last 24 hours.

.DESCRIPTION
  This script scans critical Windows logs (System, Application) 
  for Error or Critical level events. It logs findings to a text file.

#>

param (
    [string]$LogPath = "C:\Logs"
)

if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath | Out-Null
}

$scriptName = "EventLogAnalysis"
$timeStamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile    = Join-Path $LogPath "$scriptName-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $logEntry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

try {
    Write-Log "===== Starting Event Log Analysis ====="
    $endTime   = Get-Date
    $startTime = (Get-Date).AddHours(-24)

    $logsToCheck = @("System","Application")
    foreach ($evtLog in $logsToCheck) {
        Write-Log "Checking $evtLog log for errors in last 24 hours."
        $events = Get-WinEvent -LogName $evtLog -ErrorAction SilentlyContinue |
                  Where-Object { $_.LevelDisplayName -in 'Error','Critical' -and $_.TimeCreated -ge $startTime }
        
        if ($events) {
            Write-Log "Found $($events.Count) error/critical events in $evtLog."
            foreach ($evt in $events) {
                Write-Log ">> Time: $($evt.TimeCreated) EventID: $($evt.Id) Source: $($evt.ProviderName) - $($evt.Message.Substring(0,100))..."
            }
        } else {
            Write-Log "No error/critical events found in $evtLog."
        }
    }

    Write-Log "===== Event Log Analysis Completed ====="
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
finally {
    exit 0
}
