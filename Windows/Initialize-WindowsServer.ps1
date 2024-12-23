<#
.SYNOPSIS
    Automates the initial setup of a new Windows Server.

.DESCRIPTION
    - Sets server hostname.
    - Configures static IP, DNS, and gateway (if desired).
    - Installs common roles/features (e.g., File Server, .NET Framework).
    - Creates or updates a local admin user.

.NOTES
    Compatible with: Windows Server 2016, 2019, 2022
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
