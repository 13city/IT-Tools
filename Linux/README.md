# Linux Administration Scripts

A collection of shell scripts for Linux server and container management.

## 📋 Script Index

| Script Name | Description | Config Required | Notes |
|------------|-------------|-----------------|-------|
| **Security & Hardening** ||||
| linux_server_security_check.sh | Server security auditing and hardening | Yes | RHEL/Ubuntu/CentOS |
| linux_desktop_security_check.sh | Desktop security validation | No | Major distros support |
| cloud_linux_security_check.sh | Cloud-hosted Linux security | Yes | AWS/Azure/GCP |
| container_security_check.sh | Container environment security | Yes | Docker/Kubernetes |
| vault_secret_scanner.sh | HashiCorp Vault security scanning | Yes | Vault integration |
| **Database Management** ||||
| mongo_db_manager.sh | MongoDB administration | Yes | Includes backup/restore |
| mysql_database_manager.sh | MySQL/MariaDB management | Yes | Performance tuning |
| pg_database_manager.sh | PostgreSQL administration | Yes | Maintenance tasks |
| **System Administration** ||||
| initialize_linux.sh | System initialization and setup | Yes | Post-install config |
| auto_provision.sh | Automated system provisioning | Yes | Cloud-ready |
| **Network Analysis** ||||
| analyze_iptables_logs.sh | IPTables log analysis | No | Security insights |
| **SSL Management** ||||
| ssl_renew.sh | SSL certificate management | Yes | Let's Encrypt support |

## 📂 Directory Structure

Scripts are organized by function and include associated README files with detailed documentation:

```
Linux/
├── README.md                    # This file
├── Security/                    # Security and hardening scripts
├── Database/                    # Database management scripts
├── System/                     # System administration scripts
├── Network/                    # Network analysis scripts
└── SSL/                       # SSL management scripts
```

## 🔧 Prerequisites

- Bash shell environment
- Root or sudo privileges
- Required system packages (script-specific)
- Appropriate API access for cloud services

## 📚 Usage

Each script includes detailed documentation in its associated README.md file. The documentation covers:

- Required permissions and dependencies
- Configuration file setup
- Common usage examples
- Troubleshooting guides
- Best practices

## 🔒 Security Note

Many scripts require root privileges. Always review scripts and their documentation before execution in your environment.

## 🔧 Common Dependencies

- curl
- jq (JSON processor)
- openssl
- Python 3.x
- Docker (for container scripts)
- Database clients (as needed)

## 📋 Script Categories

### Security & Hardening
- System hardening according to industry standards
- Security auditing and compliance checking
- Container and cloud security validation
- Vault secret management

### Database Management
- Database administration and maintenance
- Backup and recovery procedures
- Performance monitoring and optimization
- User and permission management

### System Administration
- System initialization and configuration
- Automated provisioning
- Performance optimization
- Maintenance tasks

### Network Analysis
- Firewall log analysis
- Network security monitoring
- Traffic analysis
- Security event detection

### SSL Management
- Certificate renewal automation
- SSL configuration
- Certificate deployment
- Security validation

## 🚀 Features

- **Automation**: Reduce manual intervention in routine tasks
- **Security**: Follow security best practices
- **Flexibility**: Support for major Linux distributions
- **Scalability**: Suitable for both single-server and enterprise deployments
- **Monitoring**: Comprehensive system and security monitoring
- **Documentation**: Detailed guides and examples

## 💡 Best Practices

1. Always test scripts in a non-production environment first
2. Maintain proper backup procedures
3. Review security implications before deployment
4. Keep scripts and dependencies updated
5. Monitor script execution and maintain logs
6. Follow the principle of least privilege
