# 🛠️ Enterprise IT Administration Scripts

A comprehensive collection of advanced IT administration scripts for Windows and Linux environments, providing enterprise-grade automation, security, and management capabilities.

## 🌟 Overview

This repository contains a powerful suite of scripts designed for IT professionals, system administrators, and DevOps engineers. Each script is crafted to address specific enterprise IT needs, from security hardening to database management and comprehensive system monitoring.

## 🎯 Script Categories

### 📋 Microsoft 365 Troubleshooting Guides
- **[L1 Troubleshooting Guide](L1_M365_Troubleshooting_Guide/)** - First-line support guide
  - Comprehensive client question sets for accurate problem identification
  - Common issues and solutions for basic M365 problems
  - Step-by-step diagnostic procedures
  - Service-specific troubleshooting workflows
  - Clear escalation paths
- **[L2 Troubleshooting Guide](L2_M365_Troubleshooting_Guide/)** - Advanced support guide
  - Complex scenario resolution
  - PowerShell diagnostic commands
  - Advanced network troubleshooting
  - Performance optimization techniques
  - Detailed technical analysis
- **[L3 Troubleshooting Guide](L3_M365_Troubleshooting_Guide/)** - Enterprise-level support guide
  - Enterprise architecture troubleshooting
  - Complex hybrid scenarios
  - Advanced identity federation
  - Cross-forest Exchange issues
  - Performance at scale solutions
  - Custom solution development

### 📊 Automated Monitoring
- **[M365Monitor](AutomatedMonitoring/M365Monitor/)** - Advanced Microsoft 365 monitoring solution
  - Exchange Online monitoring
  - SharePoint Online monitoring
  - Teams service monitoring
- **[NetworkMonitor](AutomatedMonitoring/NetworkMonitor/)** - Enterprise network monitoring system
  - Real-time metrics collection
  - Topology mapping
  - Alert management
  - Multi-platform notification integration

### 📚 Enterprise IT Playbook
- **[EnterpriseITPlaybook](EnterpriseITPlaybook/)** - Comprehensive diagnostic and troubleshooting framework for Tier 2/3 support

### 🔒 Security & Compliance

#### Windows Security
- **[WinServerSecurityCheck.ps1](Windows/WinServerSecurityCheck.ps1)** - Comprehensive Windows Server security assessment
- **[AzureWindowsSecurityCheck.ps1](Windows/AzureWindowsSecurityCheck.ps1)** - Azure-specific Windows security validation
- **[WinDesktopSecurityCheck.ps1](Windows/WinDesktopSecurityCheck.ps1)** - Windows desktop security analysis
- **[AdvancedADDCSecurityChecks.ps1](Windows/AdvancedADDCSecurityChecks.ps1)** - Advanced Active Directory Domain Controller security
- **[FirewallLogAggregation.ps1](Windows/FirewallLogAggregation.ps1)** - Windows Firewall log analysis

#### Linux Security
- **[linux_server_security_check.sh](Linux/linux_server_security_check.sh)** - Linux server security auditing
- **[linux_desktop_security_check.sh](Linux/linux_desktop_security_check.sh)** - Linux desktop security validation
- **[cloud_linux_security_check.sh](Linux/cloud_linux_security_check.sh)** - Cloud-hosted Linux security
- **[container_security_check.sh](Linux/container_security_check.sh)** - Container environment security
- **[vault_secret_scanner.sh](Linux/vault_secret_scanner.sh)** - HashiCorp Vault security scanning

### 💾 Database Management

#### SQL Server Tools
- **[SqlServerDatabaseManager.ps1](Windows/SqlServerDatabaseManager.ps1)** - SQL Server administration
- **[AdvancedSqlTDE.ps1](Windows/AdvancedSqlTDE.ps1)** - SQL Server Transparent Data Encryption
- **[SQLBackupValidation.ps1](Windows/SQLBackupValidation.ps1)** - SQL backup integrity
- **[SQL-DatabaseHealthManager.ps1](Windows/SQL-DatabaseHealthManager.ps1)** - Database health monitoring
- **[SQL-PerformanceMonitor.ps1](Windows/SQL-PerformanceMonitor.ps1)** - SQL performance analysis

#### NoSQL & Open Source
- **[MongoDbManager.ps1](Windows/MongoDbManager.ps1)** - MongoDB for Windows
- **[mongo_db_manager.sh](Linux/mongo_db_manager.sh)** - MongoDB for Linux
- **[mysql_database_manager.sh](Linux/mysql_database_manager.sh)** - MySQL/MariaDB management
- **[pg_database_manager.sh](Linux/pg_database_manager.sh)** - PostgreSQL administration

### ☁️ Cloud & Infrastructure

#### Azure & Office 365
- **[azure_resource_compliance_check.sh](Windows/azure_resource_compliance_check.sh)** - Azure compliance
- **[O365MailboxPermissionAudit.ps1](Windows/O365MailboxPermissionAudit.ps1)** - O365 mailbox security
- **[IntuneWindowsStateManagement.ps1](Windows/IntuneWindowsStateManagement.ps1)** - Intune management

#### Virtualization
- **[HyperVAutoSnapshot.ps1](Windows/HyperVAutoSnapshot.ps1)** - Automated VM snapshots
- **[HyperV-HealthCheck.ps1](Windows/HyperV-HealthCheck.ps1)** - Hyper-V health monitoring
- **[HyperV-MigrationManager.ps1](Windows/HyperV-MigrationManager.ps1)** - VM migration management
- **[HyperV-ResourceMonitor.ps1](Windows/HyperV-ResourceMonitor.ps1)** - Resource utilization tracking
- **[Check-HyperVHealth.ps1](Windows/Check-HyperVHealth.ps1)** - Core health metrics monitoring
- **[EnhancedHyperVHealth.ps1](Windows/EnhancedHyperVHealth.ps1)** - Advanced health monitoring

### 🔄 System Administration

#### Windows Administration
- **[Initialize-WindowsServer.ps1](Windows/Initialize-WindowsServer.ps1)** - Server initialization
- **[SystemCleanupAndMaintenance.ps1](Windows/SystemCleanupAndMaintenance.ps1)** - System optimization
- **[EventLogAnalysis.ps1](Windows/EventLogAnalysis.ps1)** - Event log analysis
- **[HotfixComplianceChecker.ps1](Windows/HotfixComplianceChecker.ps1)** - Update compliance
- **[ServerPerformanceOptimizer.ps1](Windows/ServerPerformanceOptimizer.ps1)** - Performance optimization
- **[AD-HealthMonitor.ps1](Windows/AD-HealthMonitor.ps1)** - Active Directory health
- **[UserSettingMigration.ps1](Windows/UserSettingMigration.ps1)** - User profile migration
- **[NewEmployeeOnboarding.ps1](Windows/NewEmployeeOnboarding.ps1)** - Employee onboarding automation
- **[ComprehensiveHealthMonitoring.ps1](Windows/ComprehensiveHealthMonitoring.ps1)** - Enterprise-wide monitoring

#### Linux Administration
- **[initialize_linux.sh](Linux/initialize_linux.sh)** - System initialization
- **[auto_provision.sh](Linux/auto_provision.sh)** - System provisioning
- **[analyze_iptables_logs.sh](Linux/analyze_iptables_logs.sh)** - IPTables analysis
- **[ssl_renew.sh](Linux/ssl_renew.sh)** - SSL certificate management

### 🔗 Network & Security

#### Network Management
- **[NetworkDiagnostic.ps1](Windows/NetworkDiagnostic.ps1)** - Network diagnostics
- **[NetworkConfigurationAuditor.ps1](Windows/NetworkConfigurationAuditor.ps1)** - Network auditing
- **[RMM_CustomComponent.ps1](Windows/RMM_CustomComponent.ps1)** - RMM integration

#### Firewall Management
- **[MerakiFirewallAuditor.ps1](Windows/MerakiFirewallAuditor.ps1)** - Meraki firewall auditing
- **[SonicWallFirewallAuditor.ps1](Windows/SonicWallFirewallAuditor.ps1)** - SonicWall auditing

### 🔐 Backup & Recovery
- **[VeeamBackupValidator.ps1](Windows/VeeamBackupValidator.ps1)** - Veeam backup validation
- **[DattoBackupValidator.ps1](Windows/DattoBackupValidator.ps1)** - Datto backup validation
- **[WindowsServerBackupValidator.ps1](Windows/WindowsServerBackupValidator.ps1)** - Windows backup validation

### 🏥 Industry-Specific Tools
- **[DentalITDiagnostics.ps1](Windows/DentalITDiagnostics.ps1)** - Dental practice IT diagnostics

### 🔑 Security & Access Management
- **[CrossForestUserMigration.ps1](Windows/CrossForestUserMigration.ps1)** - AD forest migration
- **[SqlUserPermissionSetup.ps1](Windows/SqlUserPermissionSetup.ps1)** - SQL permissions

## 🚀 Features

- **Enterprise-Grade Security**: Advanced security checks and compliance validation
- **Automated Management**: Streamlined system administration and maintenance
- **Cross-Platform Support**: Comprehensive coverage for both Windows and Linux
- **Cloud Integration**: Native support for major cloud platforms
- **Detailed Reporting**: Advanced logging and reporting capabilities
- **Performance Optimization**: System performance monitoring and optimization
- **Best Practices**: Implementation of industry standards and best practices

## 💻 Technologies Supported

### Operating Systems
- Windows Server (2012 R2 through 2022)
- Windows Desktop (10, 11)
- Linux (RHEL, Ubuntu, CentOS, Debian)
- Container Platforms (Docker, Kubernetes)

### Cloud Platforms
- Microsoft Azure
- Microsoft 365 (Exchange Online, SharePoint, Teams)
- AWS
- Google Cloud Platform

### Virtualization
- Hyper-V
- VMware
- Azure Virtual Machines
- AWS EC2

### Databases
- Microsoft SQL Server
- MySQL/MariaDB
- PostgreSQL
- MongoDB

### Network & Security
- Cisco Meraki
- SonicWall
- Windows Firewall
- iptables
- HashiCorp Vault

### Backup Solutions
- Veeam
- Datto
- Windows Server Backup
- Azure Backup

### Monitoring & Management
- Active Directory
- Microsoft Intune
- RMM Platforms
- SNMP
- Network Protocols (DNS, DHCP, etc.)

## 📊 Repository Statistics

- **Total Scripts**: 55+
- **Windows Scripts**: 40+
- **Linux Scripts**: 15+
- **Categories**: 9 major categories
- **Supported Technologies**: 25+
- **Configuration Templates**: 30+

