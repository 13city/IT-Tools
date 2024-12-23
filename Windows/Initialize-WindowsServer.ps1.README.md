# Initialize-WindowsServer.ps1

### Purpose
Automates the initial setup and configuration of a new Windows Server, establishing baseline configurations, security settings, and essential features. This script provides a standardized foundation for Windows Server deployments.

### Features
- Windows Server role/feature installation
- Security baseline configuration
- Windows Update settings
- Network configuration
- Local security policies
- Service configuration
- Performance optimization
- Basic monitoring setup

### Requirements
- Windows Server 2016 or later
- PowerShell 5.1 or later
- Administrative privileges
- Internet connectivity (optional)
- Windows installation media (optional)

### Usage
```powershell
.\Initialize-WindowsServer.ps1 [-ConfigPath <path>] [-NoRestart]
```

### Parameters
- **ConfigPath**: Path to custom configuration XML file
- **NoRestart**: Prevents automatic restart after installation
- **LogPath**: Custom log file location
- **Verbose**: Enables detailed logging

### Operations Performed

1. **Pre-Installation Checks**
   - System requirements verification
   - Administrative privileges check
   - Network connectivity test
   - Disk space validation

2. **Server Roles and Features**
   - Installs common server roles
   - Configures role-specific settings
   - Validates feature dependencies
   - Handles installation prerequisites

3. **Security Configuration**
   - Configures Windows Firewall
   - Sets up Windows Defender
   - Implements security baselines
   - Configures audit policies

4. **Network Setup**
   - Configures network adapters
   - Sets up DNS settings
   - Configures IP addressing
   - Implements network security

### Configuration File
The script uses an XML configuration file for customization:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ServerConfig>
    <ComputerName>WIN-SERVER01</ComputerName>
    <WindowsFeatures>
        <Feature>Web-Server</Feature>
        <Feature>NET-Framework-45-Core</Feature>
    </WindowsFeatures>
    <NetworkConfig>
        <IPAddress>192.168.1.100</IPAddress>
        <SubnetMask>255.255.255.0</SubnetMask>
        <Gateway>192.168.1.1</Gateway>
    </NetworkConfig>
</ServerConfig>
```

### Log Files
The script maintains detailed logs in the following locations:
- Main log: `C:\Windows\Logs\ServerInitialize.log`
- Feature installation: `C:\Windows\Logs\Features.log`
- Security configuration: `C:\Windows\Logs\Security.log`

### Error Handling
- Validates all inputs before execution
- Creates system restore points
- Implements rollback procedures
- Detailed error reporting
- Exception handling for each phase
- Cleanup on failure

### Security Features
- BitLocker configuration
- Windows Defender setup
- Security policy implementation
- Network security hardening
- Audit policy configuration
- Local account security

### Best Practices
- Run in test environment first
- Review configuration file carefully
- Backup important data
- Document custom configurations
- Monitor installation progress
- Verify all features post-install
- Test security configurations
- Keep installation media available
- Review all logs after completion
- Perform post-installation testing
