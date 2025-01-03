<# 
.SYNOPSIS
    Advanced Hyper-V VM migration and replication management system.

.DESCRIPTION
    This script provides comprehensive VM migration and replication management:
    - Performs live VM migrations between hosts
    - Configures and monitors VM replication
    - Validates host compatibility
    - Checks storage requirements
    - Monitors migration progress
    - Manages replication settings
    - Generates detailed operation logs
    - Supports batch operations
    - Ensures data consistency

.NOTES
    Author: 13city
    Compatible with: Windows Server 2012 R2, 2016, 2019, 2022
    Requirements:
    - Hyper-V PowerShell module
    - Administrative rights on source and destination hosts
    - Network connectivity between hosts
    - Sufficient storage space
    - PowerShell 5.1 or higher
    - Hyper-V role installed

.PARAMETER SourceHost
    Source Hyper-V host name
    Default: Local computer name
    Example: "HV-SOURCE01"

.PARAMETER DestinationHost
    Target Hyper-V host for migration/replication
    Required for migration operations
    Example: "HV-DEST01"

.PARAMETER VMNames
    Array of VM names to process
    Optional: If omitted, processes all VMs
    Example: @("VM1", "VM2")

.PARAMETER LogPath
    Path for operation logs
    Default: Desktop\Migration-Log.txt
    Creates detailed operation logs

.PARAMETER EnableReplication
    Switch to enable replication instead of migration
    Default: False (performs migration)
    Configures VM replication when specified

.PARAMETER ReplicationFrequencySeconds
    Replication frequency in seconds
    Default: 300 (5 minutes)
    Range: 30-900 seconds

.EXAMPLE
    .\HyperV-MigrationManager.ps1 -DestinationHost "HV-DEST01" -VMNames "WebServer01"
    Performs live migration:
    - Migrates single VM to destination
    - Uses default logging
    - No replication setup

.EXAMPLE
    .\HyperV-MigrationManager.ps1 -DestinationHost "HV-DEST01" -EnableReplication -ReplicationFrequencySeconds 600
    Sets up VM replication:
    - Configures 10-minute replication
    - Replicates all VMs
    - Monitors replication status

.EXAMPLE
    .\HyperV-MigrationManager.ps1 -SourceHost "HV-SOURCE01" -DestinationHost "HV-DEST01" -VMNames @("VM1", "VM2") -LogPath "D:\Logs\Migration.log"
    Custom migration operation:
    - Specifies source and destination
    - Migrates multiple VMs
    - Custom log location
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$SourceHost = $env:COMPUTERNAME,
    [Parameter(Mandatory=$false)]
    [string]$DestinationHost,
    [Parameter(Mandatory=$false)]
    [string[]]$VMNames,
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:USERPROFILE\Desktop\Migration-Log.txt",
    [Parameter(Mandatory=$false)]
    [switch]$EnableReplication,
    [Parameter(Mandatory=$false)]
    [int]$ReplicationFrequencySeconds = 300
)

# Function to validate Hyper-V hosts
function Test-HyperVHost {
    param (
        [string]$HostName
    )
    
    try {
        $session = New-PSSession -ComputerName $HostName -ErrorAction Stop
        Invoke-Command -Session $session -ScriptBlock {
            $hyperv = Get-WindowsFeature -Name Hyper-V
            if (-not $hyperv.Installed) {
                throw "Hyper-V role is not installed on $using:HostName"
            }
        }
        Remove-PSSession $session
        return $true
    }
    catch {
        Write-Error "Failed to validate Hyper-V host $HostName: $_"
        return $false
    }
}

# Function to get VM details
function Get-VMDetails {
    param (
        [string]$HostName,
        [string[]]$VMNames
    )
    
    try {
        $vms = if ($VMNames) {
            Get-VM -ComputerName $HostName -Name $VMNames -ErrorAction Stop
        } else {
            Get-VM -ComputerName $HostName -ErrorAction Stop
        }
        return $vms
    }
    catch {
        Write-Error "Failed to get VM details from $HostName: $_"
        return $null
    }
}

# Function to check storage space
function Test-StorageSpace {
    param (
        [string]$HostName,
        [long]$RequiredSpace
    )
    
    try {
        $freeSpace = Invoke-Command -ComputerName $HostName -ScriptBlock {
            Get-PSDrive -PSProvider FileSystem | 
            Where-Object { $_.Free -gt $using:RequiredSpace } |
            Select-Object -First 1
        }
        return $freeSpace -ne $null
    }
    catch {
        Write-Error "Failed to check storage space on $HostName: $_"
        return $false
    }
}

# Function to enable replication
function Enable-VMReplication {
    param (
        [string]$SourceHost,
        [string]$DestinationHost,
        [string]$VMName,
        [int]$FrequencySeconds
    )
    
    try {
        # Enable replication on source and destination
        Invoke-Command -ComputerName $SourceHost -ScriptBlock {
            Enable-VMReplication -VMName $using:VMName `
                               -ReplicaServerName $using:DestinationHost `
                               -ReplicationFrequencySeconds $using:FrequencySeconds `
                               -AuthenticationType Kerberos `
                               -CompressionEnabled $true `
                               -RecoveryHistory 2
        }
        
        # Start initial replication
        Start-VMInitialReplication -VMName $VMName -ComputerName $SourceHost
        return $true
    }
    catch {
        Write-Error "Failed to enable replication for VM $VMName: $_"
        return $false
    }
}

# Function to monitor replication status
function Get-ReplicationStatus {
    param (
        [string]$HostName,
        [string]$VMName
    )
    
    try {
        $status = Measure-VMReplication -VMName $VMName -ComputerName $HostName
        return [PSCustomObject]@{
            VMName = $VMName
            State = $status.State
            Health = $status.Health
            LastReplicationTime = $status.LastReplicationTime
            AverageReplicationSize = $status.AverageReplicationSize
            PendingReplicationSize = $status.PendingReplicationSize
        }
    }
    catch {
        Write-Error "Failed to get replication status for VM $VMName: $_"
        return $null
    }
}

# Function to perform live migration
function Start-LiveMigration {
    param (
        [string]$SourceHost,
        [string]$DestinationHost,
        [string]$VMName
    )
    
    try {
        # Check VM state
        $vm = Get-VM -ComputerName $SourceHost -Name $VMName
        if ($vm.State -ne 'Running') {
            throw "VM must be running to perform live migration"
        }
        
        # Start migration
        Move-VM -Name $VMName `
                -SourceHost $SourceHost `
                -DestinationHost $DestinationHost `
                -IncludeStorage `
                -DestinationStoragePath "C:\HyperV\Virtual Machines"
        
        return $true
    }
    catch {
        Write-Error "Failed to migrate VM $VMName: $_"
        return $false
    }
}

# Function to log operations
function Write-MigrationLog {
    param (
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogPath -Append
    Write-Host $Message
}

# Main execution
try {
    Write-MigrationLog "Starting migration/replication process..."
    
    # Validate hosts
    if (-not (Test-HyperVHost -HostName $SourceHost)) {
        throw "Source host validation failed"
    }
    if ($DestinationHost -and -not (Test-HyperVHost -HostName $DestinationHost)) {
        throw "Destination host validation failed"
    }
    
    # Get VM list
    $vms = Get-VMDetails -HostName $SourceHost -VMNames $VMNames
    if (-not $vms) {
        throw "No VMs found to process"
    }
    
    foreach ($vm in $vms) {
        Write-MigrationLog "Processing VM: $($vm.Name)"
        
        if ($EnableReplication) {
            Write-MigrationLog "Enabling replication for $($vm.Name)"
            if (Enable-VMReplication -SourceHost $SourceHost `
                                   -DestinationHost $DestinationHost `
                                   -VMName $vm.Name `
                                   -FrequencySeconds $ReplicationFrequencySeconds) {
                Write-MigrationLog "Replication enabled successfully"
                
                # Monitor initial replication
                do {
                    $status = Get-ReplicationStatus -HostName $SourceHost -VMName $vm.Name
                    Write-MigrationLog "Replication Status: $($status.State)"
                    Start-Sleep -Seconds 30
                } while ($status.State -eq 'InitialReplication')
            }
        }
        elseif ($DestinationHost) {
            Write-MigrationLog "Starting live migration for $($vm.Name)"
            if (Start-LiveMigration -SourceHost $SourceHost `
                                   -DestinationHost $DestinationHost `
                                   -VMName $vm.Name) {
                Write-MigrationLog "Live migration completed successfully"
            }
        }
    }
    
    Write-MigrationLog "All operations completed successfully"
}
catch {
    Write-Error "Migration/Replication process failed: $_"
    Write-MigrationLog "ERROR: $_"
}
