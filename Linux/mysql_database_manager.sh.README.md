# mysql_database_manager.sh

### Purpose
Automates MySQL/MariaDB database management tasks including backup, restoration, maintenance, and monitoring. This script provides comprehensive database administration capabilities for MySQL deployments.

### Features
- Automated database backups
- Database restoration
- Table maintenance
- Performance monitoring
- User management
- Replication management
- Storage optimization
- Database statistics collection
- Query optimization

### Requirements
- MySQL/MariaDB server installed
- MySQL client utilities
- mysqldump utility
- Sufficient disk space for backups
- MySQL root or admin privileges
- System backup directory access

### Usage
```bash
./mysql_database_manager.sh [operation] [options]

Operations:
  backup     Create database backup
  restore    Restore from backup
  maintain   Run maintenance tasks
  monitor    Show database statistics
  optimize   Optimize tables
  users      Manage database users
  replica    Manage replication
```

### Common Operations

1. **Backup Management**
   ```bash
   # Full database backup
   ./mysql_database_manager.sh backup --all
   
   # Single database backup
   ./mysql_database_manager.sh backup --db dbname
   
   # Table backup
   ./mysql_database_manager.sh backup --db dbname --table tablename
   ```

2. **Restore Operations**
   ```bash
   # Full restore
   ./mysql_database_manager.sh restore --file backup.sql
   
   # Single database restore
   ./mysql_database_manager.sh restore --db dbname --file backup.sql
   ```

3. **Maintenance Tasks**
   ```bash
   # Optimize tables
   ./mysql_database_manager.sh maintain --optimize
   
   # Check and repair tables
   ./mysql_database_manager.sh maintain --repair
   ```

### Configuration
The script uses a configuration file for database connection and backup settings:
```bash
# /etc/mysql_database_manager.conf
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="root"
BACKUP_DIR="/var/lib/mysql/backups"
RETENTION_DAYS=30
ENABLE_COMPRESSION=true
USE_SSL=false
```

### Monitoring Features
- Database size monitoring
- Connection statistics
- Query performance metrics
- Replication status
- Table statistics
- Index usage
- Memory usage
- Slow query logging
- Buffer pool statistics

### Error Handling
- Validates database connectivity
- Checks backup space availability
- Verifies backup integrity
- Handles interrupted operations
- Provides detailed error logging
- Implements retry mechanisms

### Log File
The script maintains logs at `/var/log/mysql_database_manager.log` containing:
- Operation timestamps
- Backup/restore status
- Maintenance activities
- Error messages
- Performance metrics
- User management changes

### Security Features
- SSL/TLS support
- Password encryption
- User privilege management
- Encrypted backups
- Audit logging
- Backup verification

### Best Practices
- Regular backup verification
- Maintain backup retention policy
- Monitor backup size growth
- Regular table optimization
- Keep logs rotated
- Test restore procedures
- Monitor replication lag
- Regular security audits
- Check index usage
- Analyze slow queries
- Monitor binary logs
- Regular ANALYZE TABLE operations
