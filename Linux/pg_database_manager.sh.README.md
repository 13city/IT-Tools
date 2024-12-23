# pg_database_manager.sh

### Purpose
Automates PostgreSQL database management tasks including backup, restoration, maintenance, and monitoring. This script provides comprehensive database administration capabilities for PostgreSQL installations.

### Features
- Automated database backups
- Point-in-time recovery
- Database maintenance operations
- Performance monitoring
- User management
- Replication management
- Vacuum and analyze automation
- Database statistics collection

### Requirements
- PostgreSQL server installed
- psql client utilities
- Sufficient disk space for backups
- PostgreSQL superuser privileges
- pg_dump and pg_restore utilities
- System backup directory access

### Usage
```bash
./pg_database_manager.sh [operation] [options]

Operations:
  backup     Create database backup
  restore    Restore from backup
  maintain   Run maintenance tasks
  monitor    Show database statistics
  vacuum     Perform vacuum analysis
  users      Manage database users
```

### Common Operations

1. **Backup Management**
   ```bash
   # Full database backup
   ./pg_database_manager.sh backup --full
   
   # Single database backup
   ./pg_database_manager.sh backup --db dbname
   
   # Incremental backup
   ./pg_database_manager.sh backup --incremental
   ```

2. **Restore Operations**
   ```bash
   # Full restore
   ./pg_database_manager.sh restore --backup-file backup.sql
   
   # Point-in-time recovery
   ./pg_database_manager.sh restore --timestamp "2024-01-15 14:30:00"
   ```

3. **Maintenance Tasks**
   ```bash
   # Run all maintenance tasks
   ./pg_database_manager.sh maintain --all
   
   # Specific maintenance
   ./pg_database_manager.sh maintain --reindex
   ```

### Configuration
The script uses a configuration file for database connection and backup settings:
```bash
# /etc/pg_database_manager.conf
PG_HOST="localhost"
PG_PORT="5432"
PG_USER="postgres"
BACKUP_DIR="/var/lib/postgresql/backups"
RETENTION_DAYS=30
ENABLE_COMPRESSION=true
```

### Monitoring Features
- Database size tracking
- Connection statistics
- Query performance metrics
- Lock monitoring
- Replication lag tracking
- Table/index statistics
- Cache hit ratios

### Error Handling
- Validates database connectivity
- Checks backup space availability
- Verifies backup integrity
- Handles interrupted operations
- Provides detailed error logging
- Implements retry mechanisms

### Log File
The script maintains logs at `/var/log/pg_database_manager.log` containing:
- Operation timestamps
- Backup/restore status
- Maintenance activities
- Error messages
- Performance metrics
- User management changes

### Security Features
- Encrypted backups support
- Secure password handling
- Role-based access control
- SSL connection support
- Audit logging
- Backup verification

### Best Practices
- Regular backup verification
- Maintain backup retention policy
- Monitor backup size growth
- Regular maintenance scheduling
- Keep logs rotated
- Test restore procedures
- Monitor performance metrics
- Regular security audits
