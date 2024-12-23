#Requires -RunAsAdministrator
<#
.SYNOPSIS
    IT environment diagnostics tool.
.DESCRIPTION
    Comprehensive diagnostic script for dental office IT environments, focusing on printer issues
    and dental software (Dentrix, Eaglesoft) connectivity problems.

#>

# Initialize Logging
$LogPath = "$env:ProgramData\DentalITDiagnostics"
$LogFile = "$LogPath\DentalITDiagnostics_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

function Write-Log {
    param($Message, [ValidateSet('Info','Warning','Error')]$Level = 'Info')
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    
    switch ($Level) {
        'Info'    { Write-Host $LogMessage -ForegroundColor Green }
        'Warning' { Write-Host $LogMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $LogMessage -ForegroundColor Red }
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
    
    # Run all diagnostic tests
    $spoolerOk = Test-PrintSpooler
    if ($spoolerOk) {
        Test-NetworkPrinters
        Test-PrinterDrivers
    }
    
    Test-DentalSoftware
    Test-NetworkConnectivity
    Test-SharedDrives
    
    Write-Log "----------------------------------------"
    Write-Log "Diagnostic scan complete. Log file saved to: $LogFile"
}

# Execute diagnostics
Start-DentalITDiagnostics
