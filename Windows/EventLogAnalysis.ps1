<# 
.SYNOPSIS
    Enhanced Windows Event Log analyzer with pattern detection and comprehensive reporting.

.DESCRIPTION
    This script:
    - Analyzes Windows Event Logs across multiple sources
    - Detects critical event patterns and correlations
    - Filters events by configurable time ranges
    - Provides severity-based event filtering
    - Generates detailed HTML reports with insights
    - Supports multiple log sources (System, Application, Security, etc.)
    - Identifies common issue patterns (Service failures, crashes, etc.)
    - Provides actionable summaries and recommendations

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022, Windows 10/11
    Requirements:
    - Administrative privileges
    - Access to Windows Event Logs
    - Sufficient disk space for logs and reports

.PARAMETER LogPath
    Path where logs and reports will be stored
    Default: C:\Logs\EventAnalysis

.PARAMETER TimeRange
    Number of hours to look back for events
    Default: 24

.PARAMETER SeverityLevel
    Minimum severity level to include (1-Critical, 2-Error, 3-Warning)
    Default: 2 (Error)

.PARAMETER GenerateHTML
    Switch to generate HTML report
    Default: $true

.EXAMPLE
    .\EventLogAnalysis.ps1
    Analyzes last 24 hours of events with default settings

.EXAMPLE
    .\EventLogAnalysis.ps1 -TimeRange 48 -SeverityLevel 1
    Analyzes last 48 hours of events, critical events only

.EXAMPLE
    .\EventLogAnalysis.ps1 -LogPath "D:\CustomLogs" -GenerateHTML:$false
    Analyzes events and stores logs in custom location without HTML report
#>

param (
    [string]$LogPath = "C:\Logs\EventAnalysis",
    [int]$TimeRange = 24,
    [ValidateRange(1,3)]
    [int]$SeverityLevel = 2,
    [switch]$GenerateHTML = $true
)

# Initialize logging
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$scriptName = "EventLogAnalysis"
$timeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $LogPath "$scriptName-$timeStamp.log"
$htmlReport = Join-Path $LogPath "$scriptName-$timeStamp.html"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error')]
        [string]$Level = 'Info'
    )
    $logEntry = "[{0}] [{1}] {2}" -f (Get-Date), $Level, $Message
    Add-Content -Path $logFile -Value $logEntry
    
    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error' { Write-Error $Message }
        default { Write-Host $Message }
    }
}

# Define critical event patterns
$criticalPatterns = @{
    'Service Failure' = @(7000, 7001, 7022, 7023, 7024, 7026, 7031, 7032, 7034)
    'System Crash' = @(1001, 1002, 1018, 1019)
    'Disk Issues' = @(7, 9, 11, 15, 55)
    'Security Issues' = @(4625, 4648, 4719, 4765, 4766, 4794, 4897, 4964)
    'AD Issues' = @(1000, 1084, 1088, 1168, 2887)
    'DNS Issues' = @(409, 411, 412, 501, 708)
}

# Enhanced log sources
$logSources = @(
    @{Name='System'; Required=$true},
    @{Name='Application'; Required=$true},
    @{Name='Security'; Required=$true},
    @{Name='Microsoft-Windows-PowerShell/Operational'; Required=$false},
    @{Name='Microsoft-Windows-TaskScheduler/Operational'; Required=$false},
    @{Name='Microsoft-Windows-DNS-Client/Operational'; Required=$false},
    @{Name='Microsoft-Windows-GroupPolicy/Operational'; Required=$false}
)

function Get-EventLogSummary {
    param (
        [string]$LogName,
        [datetime]$StartTime,
        [int]$MinSeverity
    )
    
    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName = $LogName
            StartTime = $StartTime
            Level = 1..$MinSeverity
        } -ErrorAction SilentlyContinue
        
        if ($events) {
            $patternMatches = @{}
            foreach ($pattern in $criticalPatterns.GetEnumerator()) {
                $matches = $events | Where-Object { $pattern.Value -contains $_.Id }
                if ($matches) {
                    $patternMatches[$pattern.Key] = @{
                        Count = $matches.Count
                        Events = $matches
                    }
                }
            }
            
            return @{
                LogName = $LogName
                TotalEvents = $events.Count
                CriticalCount = ($events | Where-Object Level -eq 1).Count
                ErrorCount = ($events | Where-Object Level -eq 2).Count
                WarningCount = ($events | Where-Object Level -eq 3).Count
                PatternMatches = $patternMatches
                Events = $events
            }
        }
        return $null
    }
    catch {
        Write-Log "Error processing $LogName : $_" -Level Error
        return $null
    }
}

function New-HTMLReport {
    param (
        [array]$LogSummaries
    )
    
    $css = @"
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .critical { background-color: #ffebee; }
        .error { background-color: #fff3e0; }
        .warning { background-color: #fff8e1; }
        .pattern { background-color: #e8f5e9; }
        h2 { color: #2e7d32; }
        .summary { margin: 20px 0; padding: 10px; background-color: #e8f5e9; }
    </style>
"@

    $html = @"
    <!DOCTYPE html>
    <html>
    <head>
        <title>Event Log Analysis Report - $timeStamp</title>
        $css
    </head>
    <body>
        <h1>Event Log Analysis Report</h1>
        <div class="summary">
            <h2>Analysis Summary</h2>
            <p>Time Range: Last $TimeRange hours</p>
            <p>Generated: $(Get-Date)</p>
        </div>
"@

    foreach ($summary in $LogSummaries) {
        if ($summary) {
            $html += @"
            <h2>$($summary.LogName) Log Summary</h2>
            <table>
                <tr>
                    <th>Severity</th>
                    <th>Count</th>
                </tr>
                <tr class="critical">
                    <td>Critical</td>
                    <td>$($summary.CriticalCount)</td>
                </tr>
                <tr class="error">
                    <td>Error</td>
                    <td>$($summary.ErrorCount)</td>
                </tr>
                <tr class="warning">
                    <td>Warning</td>
                    <td>$($summary.WarningCount)</td>
                </tr>
            </table>
"@

            if ($summary.PatternMatches.Count -gt 0) {
                $html += @"
                <h3>Detected Patterns</h3>
                <table>
                    <tr>
                        <th>Pattern</th>
                        <th>Count</th>
                        <th>Sample Events</th>
                    </tr>
"@
                foreach ($pattern in $summary.PatternMatches.GetEnumerator()) {
                    $sampleEvents = ($pattern.Value.Events | Select-Object -First 3 | ForEach-Object {
                        "ID $($_.Id): $($_.Message.Substring(0, [Math]::Min(100, $_.Message.Length)))..."
                    }) -join "<br/>"
                    
                    $html += @"
                    <tr class="pattern">
                        <td>$($pattern.Key)</td>
                        <td>$($pattern.Value.Count)</td>
                        <td>$sampleEvents</td>
                    </tr>
"@
                }
                $html += "</table>"
            }

            $html += @"
            <h3>Recent Events</h3>
            <table>
                <tr>
                    <th>Time</th>
                    <th>ID</th>
                    <th>Level</th>
                    <th>Source</th>
                    <th>Message</th>
                </tr>
"@
            foreach ($event in ($summary.Events | Select-Object -First 50)) {
                $cssClass = switch ($event.Level) {
                    1 { "critical" }
                    2 { "error" }
                    3 { "warning" }
                    default { "" }
                }
                $html += @"
                <tr class="$cssClass">
                    <td>$($event.TimeCreated)</td>
                    <td>$($event.Id)</td>
                    <td>$($event.LevelDisplayName)</td>
                    <td>$($event.ProviderName)</td>
                    <td>$($event.Message.Substring(0, [Math]::Min(200, $event.Message.Length)))...</td>
                </tr>
"@
            }
            $html += "</table>"
        }
    }

    $html += @"
    </body>
    </html>
"@

    return $html
}

try {
    Write-Log "Starting Enhanced Event Log Analysis"
    Write-Log "Time Range: $TimeRange hours, Minimum Severity: $SeverityLevel"
    
    $startTime = (Get-Date).AddHours(-$TimeRange)
    $summaries = @()
    
    foreach ($source in $logSources) {
        Write-Log "Processing $($source.Name) log"
        $summary = Get-EventLogSummary -LogName $source.Name -StartTime $startTime -MinSeverity $SeverityLevel
        
        if ($summary) {
            $summaries += $summary
            Write-Log "Found $($summary.TotalEvents) events in $($source.Name)"
            
            if ($summary.CriticalCount -gt 0) {
                Write-Log "$($summary.CriticalCount) critical events found in $($source.Name)" -Level Warning
            }
            
            foreach ($pattern in $summary.PatternMatches.GetEnumerator()) {
                Write-Log "Pattern '$($pattern.Key)' matched $($pattern.Value.Count) times in $($source.Name)" -Level Warning
            }
        }
        elseif ($source.Required) {
            Write-Log "No events found in required log $($source.Name)" -Level Warning
        }
    }
    
    if ($GenerateHTML) {
        Write-Log "Generating HTML report"
        $report = New-HTMLReport -LogSummaries $summaries
        $report | Out-File -FilePath $htmlReport -Encoding UTF8
        Write-Log "HTML report saved to: $htmlReport"
    }
    
    Write-Log "Event Log Analysis completed successfully"
}
catch {
    Write-Log "Error during analysis: $_" -Level Error
    exit 1
}
finally {
    if ($summaries.Count -gt 0) {
        $criticalTotal = ($summaries | Measure-Object -Property CriticalCount -Sum).Sum
        $errorTotal = ($summaries | Measure-Object -Property ErrorCount -Sum).Sum
        
        if ($criticalTotal -gt 0 -or $errorTotal -gt 0) {
            Write-Log "Analysis completed with $criticalTotal critical and $errorTotal error events" -Level Warning
            exit 2
        }
    }
    exit 0
}
