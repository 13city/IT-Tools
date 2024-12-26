#Requires -RunAsAdministrator
<# 
.SYNOPSIS
    Comprehensive IT diagnostics tool for dental office environments.

.DESCRIPTION
    This script:
    - Checks printer connectivity and driver status
    - Monitors print spooler service
    - Tests dental software services (Dentrix, Eaglesoft, DEXIS)
    - Validates network connectivity
    - Checks mapped network drives
    - Analyzes software logs for errors
    - Provides detailed diagnostic reporting

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022, Windows 10/11
    Requirements:
    - Administrative privileges
    - PowerShell 5.1 or higher
    - Network access to printers and shared drives
    - Dental software installations (Dentrix/Eaglesoft/DEXIS)
    - Print Spooler service access
    - Write access to ProgramData directory
    - Network connectivity for diagnostics

.PARAMETER LogPath
    Directory where diagnostic logs will be written
    Creates timestamped log files with detailed results
    Automatically creates directory if it doesn't exist
    Default: $env:ProgramData\DentalITDiagnostics

.PARAMETER Detailed
    Switch to enable detailed diagnostic logging
    Includes extended error messages and stack traces
    Useful for troubleshooting complex issues
    Default: False

.PARAMETER FixIssues
    Switch to automatically attempt repair of identified issues
    Includes restarting services and reconnecting drives
    Use with caution in production environments
    Default: False

.EXAMPLE
    .\DentalITDiagnostics.ps1
    Runs basic diagnostic scan with default settings:
    - Checks printer and service status
    - Tests network connectivity
    - Validates dental software installations
    - Generates standard log file

.EXAMPLE
    .\DentalITDiagnostics.ps1 -Detailed -FixIssues
    Runs comprehensive diagnostic scan with automatic repairs:
    - Performs detailed error logging
    - Attempts to fix identified issues
    - Restarts problematic services
    - Reconnects mapped drives
    - Generates detailed report

.EXAMPLE
    .\DentalITDiagnostics.ps1 -LogPath "D:\Logs\DentalIT"
    Runs diagnostics with custom log location:
    - Saves all logs to specified directory
    - Creates directory if it doesn't exist
    - Maintains standard naming convention
#>


param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:ProgramData\DentalITDiagnostics",

    [Parameter(Mandatory=$false)]
    [switch]$Detailed,

    [Parameter(Mandatory=$false)]
    [switch]$FixIssues
)

# Initialize Logging
$LogFile = "$LogPath\DentalITDiagnostics_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error','Debug')]
        [string]$Level = 'Info',
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Add error details if present and Detailed is enabled
    if ($Detailed -and $ErrorRecord) {
        $LogMessage += "`nError Details:"
        $LogMessage += "`n  Type: $($ErrorRecord.Exception.GetType().FullName)"
        $LogMessage += "`n  Message: $($ErrorRecord.Exception.Message)"
        $LogMessage += "`n  Script: $($ErrorRecord.InvocationInfo.ScriptName)"
        $LogMessage += "`n  Line: $($ErrorRecord.InvocationInfo.ScriptLineNumber)"
        $LogMessage += "`n  Position: $($ErrorRecord.InvocationInfo.PositionMessage)"
        $LogMessage += "`n  Stack Trace: $($ErrorRecord.ScriptStackTrace)"
    }
    
    Add-Content -Path $LogFile -Value $LogMessage
    
    switch ($Level) {
        'Info'    { Write-Host $LogMessage -ForegroundColor Green }
        'Warning' { Write-Host $LogMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $LogMessage -ForegroundColor Red }
        'Debug'   { 
            if ($Detailed) {
                Write-Host $LogMessage -ForegroundColor Cyan
            }
        }
    }
}

function Test-PrintSpooler {
    Write-Log "Checking Print Spooler service status..."
    
    $spooler = Get-Service -Name "Spooler"
    if ($spooler.Status -ne "Running") {
        Write-Log "Print Spooler is not running. Attempting to start..." -Level Warning
        try {
            Start-Service -Name "Spooler"
            Write-Log "Print Spooler service started successfully"
        }
        catch {
            Write-Log "Failed to start Print Spooler: $_" -Level Error
            return $false
        }
    }
    else {
        Write-Log "Print Spooler service is running properly"
    }
    return $true
}

function Test-NetworkPrinters {
    Write-Log "Checking network printers..."
    
    $printers = Get-Printer | Where-Object { $_.Type -eq "Connection" }
    foreach ($printer in $printers) {
        try {
            $pingResult = Test-Connection -ComputerName $printer.ComputerName -Count 1 -Quiet
            if ($pingResult) {
                Write-Log "Printer '$($printer.Name)' is accessible"
            }
            else {
                Write-Log "Printer '$($printer.Name)' is not responding" -Level Warning
            }
        }
        catch {
            Write-Log "Error testing printer '$($printer.Name)': $_" -Level Error
        }
    }
}

function Test-PrinterDrivers {
    Write-Log "Checking printer drivers..."
    
    $drivers = Get-PrinterDriver
    foreach ($driver in $drivers) {
        try {
            $driverPath = Join-Path $env:SystemRoot "System32\spool\drivers\w32x86\3\$($driver.Name).dll"
            if (Test-Path $driverPath) {
                Write-Log "Driver '$($driver.Name)' files present"
            }
            else {
                Write-Log "Driver '$($driver.Name)' files may be missing" -Level Warning
            }
        }
        catch {
            Write-Log "Error checking driver '$($driver.Name)': $_" -Level Error
        }
    }
}

function Test-DentalSoftware {
    Write-Log "Checking dental software services and connectivity..."
    
    # Common dental software services
    $dentalServices = @(
        "DEXIS Service",
        "DentrixService",
        "EagleSoftService"
    )
    
    foreach ($service in $dentalServices) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc) {
                if ($svc.Status -eq "Running") {
                    Write-Log "Service '$service' is running"
                }
                else {
                    Write-Log "Service '$service' is not running" -Level Warning
                    try {
                        Start-Service -Name $service
                        Write-Log "Successfully started '$service'"
                    }
                    catch {
                        Write-Log "Failed to start '$service': $_" -Level Error
                    }
                }
            }
        }
        catch {
            Write-Log "Error checking service '$service': $_" -Level Error
        }
    }
    
    # Check common dental software paths
    $softwarePaths = @{
        "Dentrix" = "C:\Program Files\Dentrix"
        "Eaglesoft" = "C:\Program Files\Patterson\Eaglesoft"
        "DEXIS" = "C:\Program Files\DEXIS"
    }
    
    foreach ($software in $softwarePaths.Keys) {
        if (Test-Path $softwarePaths[$software]) {
            Write-Log "$software installation found at $($softwarePaths[$software])"
            
            # Check log files for errors
            $logPath = Join-Path $softwarePaths[$software] "Logs"
            if (Test-Path $logPath) {
                $recentLogs = Get-ChildItem $logPath -Filter "*.log" | 
                             Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) }
                
                foreach ($log in $recentLogs) {
                    $errorCount = (Select-String -Path $log.FullName -Pattern "error|exception|failed" -CaseSensitive:$false).Count
                    if ($errorCount -gt 0) {
                        Write-Log "Found $errorCount potential errors in $($log.Name)" -Level Warning
                    }
                }
            }
        }
        else {
            Write-Log "$software installation not found at expected location" -Level Warning
        }
    }
}

function Test-NetworkConnectivity {
    Write-Log "Testing network connectivity..."
    
    # Test basic internet connectivity
    $internetTests = @(
        "8.8.8.8",  # Google DNS
        "208.67.222.222"  # OpenDNS
    )
    
    foreach ($ip in $internetTests) {
        try {
            if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
                Write-Log "Successfully pinged $ip"
            }
            else {
                Write-Log "Failed to ping $ip" -Level Warning
            }
        }
        catch {
            Write-Log "Error testing connection to $ip: $_" -Level Error
        }
    }
    
    # Test DNS resolution
    try {
        $dns = Resolve-DnsName "www.google.com" -ErrorAction Stop
        Write-Log "DNS resolution working properly"
    }
    catch {
        Write-Log "DNS resolution failed: $_" -Level Error
    }
    
    # Check network adapters
    Get-NetAdapter | ForEach-Object {
        Write-Log "Network adapter '$($_.Name)' is $($_.Status) (Speed: $($_.LinkSpeed))"
        if ($_.Status -ne "Up") {
            Write-Log "Network adapter '$($_.Name)' is not functioning properly" -Level Warning
        }
    }
}

function Test-SharedDrives {
    Write-Log "Checking mapped network drives..."
    
    Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot } | ForEach-Object {
        try {
            if (Test-Path $_.Root) {
                Write-Log "Mapped drive $($_.Name) ($($_.DisplayRoot)) is accessible"
            }
            else {
                Write-Log "Mapped drive $($_.Name) ($($_.DisplayRoot)) is not accessible" -Level Warning
            }
        }
        catch {
            Write-Log "Error checking mapped drive $($_.Name): $_" -Level Error
        }
    }
}

# Main diagnostic routine
function Start-DentalITDiagnostics {
    Write-Log "Starting Dental IT Diagnostics..."
    Write-Log "----------------------------------------"
    
    if ($Detailed) {
        Write-Log "Running in detailed diagnostic mode" -Level Debug
        Write-Log "Script Parameters:" -Level Debug
        Write-Log "  LogPath: $LogPath" -Level Debug
        Write-Log "  Detailed: $Detailed" -Level Debug
        Write-Log "  FixIssues: $FixIssues" -Level Debug
    }
    
    # Run all diagnostic tests
    $issues = @()
    
    # Check Print Spooler
    $spoolerOk = Test-PrintSpooler
    if ($spoolerOk) {
        if ($Detailed) {
            Write-Log "Print Spooler check passed, proceeding with printer diagnostics" -Level Debug
        }
        Test-NetworkPrinters
        Test-PrinterDrivers
    }
    else {
        $issues += "Print Spooler Service"
    }
    
    # Run remaining tests
    Test-DentalSoftware
    Test-NetworkConnectivity
    Test-SharedDrives
    
    # Handle identified issues
    if ($issues.Count -gt 0 -and $FixIssues) {
        Write-Log "Attempting to fix identified issues..." -Level Warning
        foreach ($issue in $issues) {
            Write-Log "Fixing: $issue" -Level Warning
            switch ($issue) {
                "Print Spooler Service" {
                    try {
                        Restart-Service -Name Spooler -Force
                        Write-Log "Print Spooler Service restarted successfully" -Level Info
                    }
                    catch {
                        Write-Log "Failed to restart Print Spooler Service" -Level Error -ErrorRecord $_
                    }
                }
                # Add more issue resolution cases as needed
            }
        }
    }
    elseif ($issues.Count -gt 0) {
        Write-Log "Issues were found but automatic fixing is disabled. Use -FixIssues to enable automatic repairs." -Level Warning
    }
    
    if ($Detailed) {
        Write-Log "Diagnostic scan summary:" -Level Debug
        Write-Log "  Total issues found: $($issues.Count)" -Level Debug
        Write-Log "  Automatic fixes attempted: $($FixIssues)" -Level Debug
    }
    
    Write-Log "----------------------------------------"
    Write-Log "Diagnostic scan complete. Log file saved to: $LogFile"
    
    # Return results object if needed for further processing
    return @{
        Issues = $issues
        LogFile = $LogFile
        FixesAttempted = $FixIssues
    }
}

# Execute diagnostics
try {
    $results = Start-DentalITDiagnostics
    if ($Detailed) {
        Write-Log "Results object available for further processing" -Level Debug
    }
}
catch {
    Write-Log "Critical error during diagnostics" -Level Error -ErrorRecord $_
    throw
}
