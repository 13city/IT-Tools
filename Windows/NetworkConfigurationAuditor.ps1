#Requires -Version 5.1
#Requires -Modules Posh-SSH

<#
.SYNOPSIS
    Audits Cisco network device configurations against best practices.
.DESCRIPTION
    This script connects to Cisco network devices via SSH to gather interface statuses,
    VLAN assignments, and routing tables, then compares them against best practices
    templates to identify discrepancies.
.PARAMETER DeviceList
    Path to CSV file containing device information (IP, Type, Credentials)
.PARAMETER TemplateFile
    Path to JSON file containing best practices templates
.EXAMPLE
    .\NetworkConfigurationAuditor.ps1 -DeviceList "devices.csv" -TemplateFile "best_practices.json"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$DeviceList,
    
    [Parameter(Mandatory = $true)]
    [string]$TemplateFile
)

# Default best practices if template file not found
$defaultBestPractices = @{
    VLANs = @{
        Management = 1
        Native = 1
        Voice = "100-110"
        Data = "111-999"
        Reserved = "1000-4094"
    }
    Interfaces = @{
        TrunkPorts = @{
            AllowedVlans = "1-999"
            Mode = "trunk"
            NativeVlan = 1
        }
        AccessPorts = @{
            Mode = "access"
            PortSecurity = $true
            StormControl = $true
        }
    }
    ACLs = @{
        InboundRules = @(
            "permit tcp any any established"
            "deny ip any any log"
        )
        OutboundRules = @(
            "permit ip any any"
        )
    }
}

# Function to establish SSH connection
function Connect-NetworkDevice {
    param (
        [string]$IpAddress,
        [string]$Username,
        [string]$Password
    )
    
    try {
        $sshSession = New-SSHSession -ComputerName $IpAddress -Credential (
            New-Object System.Management.Automation.PSCredential(
                $Username, (ConvertTo-SecureString $Password -AsPlainText -Force)
            )
        ) -AcceptKey
        
        return $sshSession
    }
    catch {
        Write-Error "Failed to connect to $IpAddress : $_"
        return $null
    }
}

# Function to execute command and get output
function Invoke-NetworkCommand {
    param (
        [object]$Session,
        [string]$Command
    )
    
    try {
        $result = Invoke-SSHCommand -SSHSession $Session -Command $Command
        return $result.Output
    }
    catch {
        Write-Error "Failed to execute command '$Command': $_"
        return $null
    }
}

# Function to get interface status
function Get-InterfaceStatus {
    param (
        [object]$Session
    )
    
    $output = Invoke-NetworkCommand -Session $Session -Command "show interfaces status"
    $interfaces = @{}
    
    foreach ($line in $output) {
        if ($line -match "^(\S+)\s+(.+?)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(.+)$") {
            $interfaces[$matches[1]] = @{
                Status = $matches[3]
                Vlan = $matches[4]
                Duplex = $matches[5]
                Speed = $matches[6]
                Type = $matches[7]
            }
        }
    }
    
    return $interfaces
}

# Function to get VLAN information
function Get-VlanInfo {
    param (
        [object]$Session
    )
    
    $output = Invoke-NetworkCommand -Session $Session -Command "show vlan brief"
    $vlans = @{}
    
    foreach ($line in $output) {
        if ($line -match "^(\d+)\s+(\S+)\s+(\w+)\s+(.*)$") {
            $vlans[$matches[1]] = @{
                Name = $matches[2]
                Status = $matches[3]
                Ports = $matches[4] -split ","
            }
        }
    }
    
    return $vlans
}

# Function to get routing table
function Get-RoutingTable {
    param (
        [object]$Session
    )
    
    $output = Invoke-NetworkCommand -Session $Session -Command "show ip route"
    $routes = @{}
    
    foreach ($line in $output) {
        if ($line -match "^([A-Z*])\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})\s+.*$") {
            $routes[$matches[2]] = @{
                Type = $matches[1]
                Prefix = $matches[3]
            }
        }
    }
    
    return $routes
}

# Function to compare configuration with best practices
function Compare-Configuration {
    param (
        [hashtable]$CurrentConfig,
        [hashtable]$BestPractices
    )
    
    $discrepancies = @{
        VLANs = @()
        Interfaces = @()
        ACLs = @()
    }
    
    # Compare VLANs
    foreach ($vlan in $CurrentConfig.VLANs.Keys) {
        $vlanNum = [int]$vlan
        
        # Check if VLAN is in allowed ranges
        $inRange = $false
        foreach ($range in $BestPractices.VLANs.Values) {
            if ($range -match "(\d+)-(\d+)") {
                $start = [int]$matches[1]
                $end = [int]$matches[2]
                if ($vlanNum -ge $start -and $vlanNum -le $end) {
                    $inRange = $true
                    break
                }
            }
            elseif ($range -eq $vlanNum) {
                $inRange = $true
                break
            }
        }
        
        if (-not $inRange) {
            $discrepancies.VLANs += "VLAN $vlan is outside recommended ranges"
        }
    }
    
    # Compare Interface configurations
    foreach ($interface in $CurrentConfig.Interfaces.Keys) {
        $config = $CurrentConfig.Interfaces[$interface]
        
        if ($config.Mode -eq "trunk") {
            # Check trunk port configuration
            if ($config.AllowedVlans -ne $BestPractices.Interfaces.TrunkPorts.AllowedVlans) {
                $discrepancies.Interfaces += "Interface $interface: Allowed VLANs mismatch"
            }
            if ($config.NativeVlan -ne $BestPractices.Interfaces.TrunkPorts.NativeVlan) {
                $discrepancies.Interfaces += "Interface $interface: Native VLAN mismatch"
            }
        }
        else {
            # Check access port configuration
            if (-not $config.PortSecurity) {
                $discrepancies.Interfaces += "Interface $interface: Port security not enabled"
            }
            if (-not $config.StormControl) {
                $discrepancies.Interfaces += "Interface $interface: Storm control not configured"
            }
        }
    }
    
    return $discrepancies
}

# Main execution block
try {
    # Load best practices template
    $bestPractices = if (Test-Path $TemplateFile) {
        Get-Content $TemplateFile | ConvertFrom-Json -AsHashtable
    }
    else {
        Write-Warning "Template file not found. Using default best practices."
        $defaultBestPractices
    }
    
    # Load device list
    $devices = Import-Csv $DeviceList
    
    foreach ($device in $devices) {
        Write-Host "`nAuditing device: $($device.IPAddress)" -ForegroundColor Cyan
        
        # Connect to device
        $session = Connect-NetworkDevice -IpAddress $device.IPAddress -Username $device.Username -Password $device.Password
        
        if ($session) {
            try {
                # Gather configuration
                $currentConfig = @{
                    Interfaces = Get-InterfaceStatus -Session $session
                    VLANs = Get-VlanInfo -Session $session
                    Routes = Get-RoutingTable -Session $session
                }
                
                # Compare with best practices
                $discrepancies = Compare-Configuration -CurrentConfig $currentConfig -BestPractices $bestPractices
                
                # Report findings
                if ($discrepancies.VLANs.Count -eq 0 -and 
                    $discrepancies.Interfaces.Count -eq 0 -and 
                    $discrepancies.ACLs.Count -eq 0) {
                    Write-Host "No discrepancies found." -ForegroundColor Green
                }
                else {
                    Write-Host "Discrepancies found:" -ForegroundColor Yellow
                    
                    if ($discrepancies.VLANs.Count -gt 0) {
                        Write-Host "`nVLAN Issues:" -ForegroundColor Yellow
                        $discrepancies.VLANs | ForEach-Object { Write-Host "- $_" }
                    }
                    
                    if ($discrepancies.Interfaces.Count -gt 0) {
                        Write-Host "`nInterface Issues:" -ForegroundColor Yellow
                        $discrepancies.Interfaces | ForEach-Object { Write-Host "- $_" }
                    }
                    
                    if ($discrepancies.ACLs.Count -gt 0) {
                        Write-Host "`nACL Issues:" -ForegroundColor Yellow
                        $discrepancies.ACLs | ForEach-Object { Write-Host "- $_" }
                    }
                }
                
                # Export results to file
                $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "NetworkAudit_$($device.IPAddress)_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                @{
                    DeviceIP = $device.IPAddress
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Configuration = $currentConfig
                    Discrepancies = $discrepancies
                } | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath
                
                Write-Host "`nDetailed report saved to: $reportPath" -ForegroundColor Cyan
            }
            finally {
                # Cleanup
                Remove-SSHSession -SSHSession $session | Out-Null
            }
        }
    }
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
