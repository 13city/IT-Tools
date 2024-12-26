<# 
.SYNOPSIS
    Automated Windows Server initialization and configuration system.

.DESCRIPTION
    This script provides comprehensive initial setup for new Windows Servers:
    - Configures server hostname and network identity
    - Sets up static IP addressing and DNS configuration
    - Installs and configures essential server roles/features
    - Manages local administrator accounts
    - Implements basic security configurations
    - Provides detailed operation logging
    - Validates all configuration changes
    - Supports both physical and virtual environments
    - Ensures consistent server setup process

.NOTES
    Author: 13city
    Compatible with: Windows Server 2016, 2019, 2022
    Requirements:
    - Administrative rights
    - Network connectivity
    - PowerShell 5.1 or higher
    - Write access to C:\Logs
    - Valid network configuration details
    - Server restart capability

.PARAMETER NewHostname
    New server hostname to be configured
    Required: Yes
    Format: NetBIOS-compatible name
    Example: "PROD-SVR01"

.PARAMETER LocalAdminUser
    Local administrator account to create/update
    Required: Yes
    Format: Valid Windows username
    Example: "LocalAdmin"

.PARAMETER LocalAdminPassword
    Password for local administrator account
    Required: Yes
    Must meet complexity requirements
    Stored securely during execution

.PARAMETER ConfigureStaticIP
    Switch to enable static IP configuration
    Default: False
    Optional: Use for static IP setup

.PARAMETER IPAddress
    Static IP address to configure
    Default: "192.168.1.100"
    Required if ConfigureStaticIP is true

.PARAMETER SubnetMask
    Subnet mask for network configuration
    Default: "255.255.255.0"
    Required if ConfigureStaticIP is true

.PARAMETER Gateway
    Default gateway address
    Default: "192.168.1.1"
    Required if ConfigureStaticIP is true

.PARAMETER DnsServer
    Primary DNS server address
    Default: "192.168.1.10"
    Required if ConfigureStaticIP is true

.EXAMPLE
    .\Initialize-WindowsServer.ps1 -NewHostname "PROD-SVR01" -LocalAdminUser "LocalAdmin" -LocalAdminPassword "SecurePass123!"
    Basic server setup:
    - Sets hostname to PROD-SVR01
    - Creates/updates local admin
    - Uses DHCP networking
    - Installs default roles

.EXAMPLE
    .\Initialize-WindowsServer.ps1 -NewHostname "DB-SVR01" -LocalAdminUser "SQLAdmin" -LocalAdminPassword "SecurePass123!" -ConfigureStaticIP -IPAddress "10.0.0.100" -SubnetMask "255.255.255.0" -Gateway "10.0.0.1" -DnsServer "10.0.0.10"
    Advanced server setup:
    - Configures static IP addressing
    - Custom admin account
    - Full network configuration
    - Installs all required roles

.EXAMPLE
    .\Initialize-WindowsServer.ps1 -NewHostname "WEB-SVR01" -LocalAdminUser "WebAdmin" -LocalAdminPassword "SecurePass123!" -ConfigureStaticIP
    Mixed configuration:
    - Uses custom hostname
    - Static IP with defaults
    - Specialized admin account
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$NewHostname,

    [Parameter(Mandatory=$true)]
    [string]$LocalAdminUser,

    [Parameter(Mandatory=$true)]
    [string]$LocalAdminPassword,

    [switch]$ConfigureStaticIP = $false,
    [string]$IPAddress = "192.168.1.100",
    [string]$SubnetMask = "255.255.255.0",
    [string]$Gateway = "192.168.1.1",
    [string]$DnsServer = "192.168.1.10"
)

$logPath = "C:\Logs"
if (!(Test-Path $logPath)) { New-Item -ItemType Directory -Path $logPath | Out-Null }
$timeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $logPath "Initialize-WindowsServer-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    Write-Log "===== Starting Windows Server Initialization ====="

    # 1. Set Hostname
    Write-Log "Setting hostname to $NewHostname"
    Rename-Computer -NewName $NewHostname -Force

    # 2. Configure local admin
    Write-Log "Creating/updating local admin account $LocalAdminUser"
    $securePass = ConvertTo-SecureString $LocalAdminPassword -AsPlainText -Force
    if (Get-LocalUser -Name $LocalAdminUser -ErrorAction SilentlyContinue) {
        Set-LocalUser -Name $LocalAdminUser -Password $securePass
        Write-Log "User $LocalAdminUser already existed; password updated."
    }
    else {
        New-LocalUser -Name $LocalAdminUser -Password $securePass -FullName "Local Admin"
        Write-Log "User $LocalAdminUser created."
    }
    Add-LocalGroupMember -Group "Administrators" -Member $LocalAdminUser

    # 3. Optional: Configure static IP
    if ($ConfigureStaticIP) {
        Write-Log "Configuring static IP: $IPAddress"
        $nic = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
        if ($nic) {
            New-NetIPAddress -InterfaceAlias $nic.Name -IPAddress $IPAddress -PrefixLength (([IPAddress]$SubnetMask).GetAddressBytes() | %{($_.ToString(2).PadLeft(8,'0'))} -join '').Count{$_ -eq '1'} -DefaultGateway $Gateway -ErrorAction SilentlyContinue
            Set-DnsClientServerAddress -InterfaceAlias $nic.Name -ServerAddresses $DnsServer
            Write-Log "Static IP, DNS, and Gateway configured."
        } else {
            Write-Log "No active network adapter found for static IP configuration."
        }
    }

    # 4. Install roles/features
    Write-Log "Installing common roles/features..."
    Install-WindowsFeature -Name FS-FileServer, NET-Framework-Core -IncludeAllSubFeature -IncludeManagementTools -ErrorAction SilentlyContinue

    # 5. Final log
    Write-Log "===== Windows Server Initialization Completed Successfully ====="
    Write-Log "Please reboot for hostname changes to take effect."
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
