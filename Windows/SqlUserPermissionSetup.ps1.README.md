# SqlUserPermissionSetup.ps1

### Purpose
Automates SQL Server user creation and permission management, providing a standardized approach to implementing role-based access control and security policies across SQL Server instances.

### Features
- User account creation and management
- Role assignment and management
- Permission grant/revoke operations
- Security policy implementation
- Cross-database permissions
- Bulk user operations
- Permission auditing
- Template-based deployments

### Requirements
- SQL Server 2016 or later
- PowerShell 5.1 or later
- SQL Server PowerShell module
- Sysadmin or SecurityAdmin role
- Active Directory integration (optional)
- SQL Server Management Studio (optional)

### Usage
```powershell
.\SqlUserPermissionSetup.ps1 -Operation <operation> [parameters]

Operations:
  CreateUser    Create new SQL user
  AssignRole    Assign role to user
  GrantPerm     Grant specific permissions
  RevokePerm    Revoke permissions
  AuditPerm     Audit user permissions
  BulkSetup     Process bulk user setup
```

### Common Operations

1. **User Management**
   ```powershell
   # Create SQL user
   .\SqlUserPermissionSetup.ps1 -Operation CreateUser -Username "NewUser" -Password "SecurePass123"
   
   # Create Windows authenticated user
   .\SqlUserPermissionSetup.ps1 -Operation CreateUser -WindowsAuth -Username "DOMAIN\User"
   ```

2. **Role Assignment**
   ```powershell
   # Assign database role
   .\SqlUserPermissionSetup.ps1 -Operation AssignRole -Username "User" -Role "db_datareader" -Database "Target"
   
   # Assign server role
   .\SqlUserPermissionSetup.ps1 -Operation AssignRole -Username "User" -ServerRole "dbcreator"
   ```

3. **Permission Management**
   ```powershell
   # Grant specific permissions
   .\SqlUserPermissionSetup.ps1 -Operation GrantPerm -Username "User" -Permission "SELECT" -Object "Schema.Table"
   
   # Revoke permissions
   .\SqlUserPermissionSetup.ps1 -Operation RevokePerm -Username "User" -Permission "EXECUTE" -Object "Schema.StoredProc"
   ```

### Configuration
The script uses a JSON configuration file for templates and policies:
```json
{
    "UserTemplates": {
        "ReadOnly": {
            "Roles": ["db_datareader"],
            "Permissions": ["SELECT"]
        },
        "Developer": {
            "Roles": ["db_datareader", "db_datawriter"],
            "Permissions": ["SELECT", "INSERT", "UPDATE", "DELETE"]
        }
    },
    "SecurityPolicies": {
        "PasswordPolicy": true,
        "MustChange": true,
        "ExpirationDays": 90
    }
}
```

### Permission Templates
Predefined permission sets for common scenarios:
- ReadOnly: SELECT permissions only
- Developer: Full data access, no schema changes
- Admin: Full database access
- Analyst: Read and execute permissions
- Support: Limited write access

### Audit Features
- Current permission reporting
- Historical permission tracking
- Change documentation
- Compliance reporting
- Access pattern analysis
- Security assessment

### Error Handling
- Permission validation
- User existence checks
- Role conflict detection
- Password policy enforcement
- Detailed error reporting
- Rollback capabilities

### Log Files
The script maintains detailed logs:
- Main log: `C:\SQLLogs\PermissionSetup.log`
- Audit log: `C:\SQLLogs\PermissionAudit.log`
- Change log: `C:\SQLLogs\PermissionChanges.log`

### Security Features
- Password policy enforcement
- Role separation enforcement
- Least privilege principle
- Permission inheritance tracking
- Access path analysis
- Security best practices

### Best Practices
- Use template-based assignments
- Regular permission audits
- Document custom permissions
- Implement role-based access
- Monitor permission changes
- Regular security reviews
- Maintain user inventory
- Test permission sets
- Review access patterns
- Keep audit logs
- Use Windows authentication
- Implement proper password policies
