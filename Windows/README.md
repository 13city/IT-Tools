# Windows Administration Scripts

A collection of PowerShell scripts for Windows Server and Desktop administration.

## 📋 Script Index

| Script Name | Description | Config Required | Notes |
|------------|-------------|-----------------|-------|
| **Security & Compliance** ||||
| WinServerSecurityCheck.ps1 | Comprehensive Windows Server security assessment | Yes | Supports Server 2012-2022 |
| AzureWindowsSecurityCheck.ps1 | Azure-specific Windows security validation | Yes | Requires Azure modules |
| WinDesktopSecurityCheck.ps1 | Windows desktop security analysis | No | Windows 10/11 compatible |
| AdvancedADDCSecurityChecks.ps1 | Advanced AD DC security validation | Yes | Domain Controller specific |
| **Database Management** ||||
| SqlServerDatabaseManager.ps1 | SQL Server administration and management | Yes | Supports SQL 2016+ |
| AdvancedSqlTDE.ps1 | SQL Server Transparent Data Encryption | Yes | Enterprise features |
| SQLBackupValidation.ps1 | SQL backup integrity checking | Yes | - |
| SQL-DatabaseHealthManager.ps1 | Database health monitoring | Yes | Includes performance metrics |
| SQL-PerformanceMonitor.ps1 | SQL performance analysis and optimization | Yes | - |
| **Virtualization** ||||
| HyperVAutoSnapshot.ps1 | Automated VM snapshots | Yes | Configurable schedule |
| HyperV-HealthCheck.ps1 | Hyper-V health monitoring | No | Basic health checks |
| HyperV-MigrationManager.ps1 | VM migration management | Yes | Supports live migration |
| HyperV-ResourceMonitor.ps1 | Resource utilization tracking | No | Real-time monitoring |
| EnhancedHyperVHealth.ps1 | Advanced health monitoring | Yes | Extended metrics |
| **Active Directory** ||||
| AD-HealthMonitor.ps1 | Active Directory health monitoring | Yes | Comprehensive checks |
| CrossForestUserMigration.ps1 | AD forest migration tool | Yes | Multi-forest support |
| NewEmployeeOnboarding.ps1 | Employee onboarding automation | Yes | Customizable workflow |
| **System Administration** ||||
| Initialize-WindowsServer.ps1 | Server initialization and setup | Yes | Post-deployment config |
| SystemCleanupAndMaintenance.ps1 | System optimization and cleanup | No | Automated maintenance |
| ServerPerformanceOptimizer.ps1 | Performance optimization | Yes | Tuning parameters |
| UserSettingMigration.ps1 | User profile migration | No | Profile backup/restore |
| **Network Management** ||||
| NetworkDiagnostic.ps1 | Network diagnostics and troubleshooting | No | Comprehensive tests |
| NetworkConfigurationAuditor.ps1 | Network configuration auditing | Yes | Compliance checks |
| MerakiFirewallAuditor.ps1 | Meraki firewall auditing | Yes | API integration |
| SonicWallFirewallAuditor.ps1 | SonicWall firewall auditing | Yes | API integration |
| **Backup & Recovery** ||||
| VeeamBackupValidator.ps1 | Veeam backup validation | Yes | Requires Veeam |
| DattoBackupValidator.ps1 | Datto backup validation | Yes | Requires Datto |
| WindowsServerBackupValidator.ps1 | Windows Server Backup validation | No | Native backup |
| **Cloud & Microsoft 365** ||||
| IntuneWindowsStateManagement.ps1 | Intune state management | Yes | Graph API integration |
| M365MailboxPermissionAudit.ps1 | O365 mailbox permission auditing | Yes | Exchange Online |
| **Specialized Tools** ||||
| DentalITDiagnostics.ps1 | Dental practice IT diagnostics | Yes | Industry specific |

## 📂 Directory Structure

Scripts are organized by function and include associated README files with detailed documentation:

```
Windows/
├── README.md                   # This file
├── Security/                   # Security and compliance scripts
├── Database/                   # Database management scripts
├── Virtualization/            # Hyper-V management scripts
├── ActiveDirectory/           # AD management scripts
├── System/                    # System administration scripts
├── Network/                   # Network management scripts
├── Backup/                    # Backup validation scripts
├── Cloud/                     # Cloud and M365 scripts
└── Specialized/              # Industry-specific tools
```

## 🔧 Prerequisites

- Windows PowerShell 5.1 or PowerShell Core 7.x
- Appropriate administrative privileges
- Required PowerShell modules (script-specific)
- Necessary API access for cloud services

## 📚 Usage

Each script includes detailed documentation in its associated README.md file. The documentation covers:

- Required permissions and dependencies
- Configuration file setup
- Common usage examples
- Troubleshooting guides
- Best practices

## 🔒 Security Note

Many scripts require elevated privileges. Always review scripts and their documentation before execution in your environment.
