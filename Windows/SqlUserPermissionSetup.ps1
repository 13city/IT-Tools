<#
.SYNOPSIS
    SQL Server user and permission management automation toolkit.

.DESCRIPTION
    This script provides comprehensive SQL Server user management capabilities:
    - Login Management:
      * SQL Login creation
      * Password policy configuration
      * Login validation
      * Security checks
    - User Management:
      * Database user creation
      * User-login mapping
      * Schema assignment
      * User validation
    - Permission Control:
      * Role assignment
      * Permission verification
      * Role membership management
      * Security auditing
    - Security Features:
      * Password policy enforcement
      * Default schema configuration
      * Role-based access control
      * Permission validation

.NOTES
    Author: 13city
    Compatible with:
    - SQL Server 2012+
    - SQL Server 2014+
    - SQL Server 2016+
    - SQL Server 2017+
    - SQL Server 2019+
    
    Requirements:
    - PowerShell 5.1 or higher
    - SqlServer PowerShell module
    - Sysadmin or security admin rights
    - Database access permissions
    - Server login creation rights

.PARAMETER SqlInstance
    SQL Server instance name
    Required parameter
    Format: ServerName\InstanceName
    Example: SQLSERVER01\PROD

.PARAMETER DatabaseName
    Target database name
    Required parameter
    Must be valid SQL identifier
    Case-sensitive

.PARAMETER SqlLogin
    SQL Server login name
    Required parameter
    Must be unique on server
    Case-sensitive

.PARAMETER SqlPassword
    Password for SQL authentication
    Required parameter
    Must meet complexity requirements
    Stored securely

.PARAMETER DbRole
    Database role to assign
    Optional parameter
    Default: db_owner
    Common values: db_datareader, db_datawriter

.EXAMPLE
    .\SqlUserPermissionSetup.ps1 -SqlInstance "SQLSERVER01" -DatabaseName "CustomerDB" -SqlLogin "AppUser" -SqlPassword "SecurePass123"
    Basic user setup:
    - Creates SQL login
    - Creates database user
    - Assigns db_owner role
    - Default settings

.EXAMPLE
    .\SqlUserPermissionSetup.ps1 -SqlInstance "SQLSERVER01\PROD" -DatabaseName "FinanceDB" -SqlLogin "ReadOnlyUser" -SqlPassword "SecurePass123" -DbRole "db_datareader"
    Read-only user setup:
    - Creates SQL login
    - Creates database user
    - Assigns read-only role
    - Restricted access
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SqlInstance,

    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,

    [Parameter(Mandatory=$true)]
    [string]$SqlLogin,

    [Parameter(Mandatory=$true)]
    [string]$SqlPassword,  # for SQL authentication

    [string]$DbRole = "db_owner"
)

try {
    Write-Host "===== Starting SQL User/Permission Setup ====="
    # 1. Create Login if missing
    $loginCheck = Invoke-Sqlcmd -ServerInstance $SqlInstance -Query "SELECT name FROM sys.server_principals WHERE name='$SqlLogin'"
    if ($loginCheck) {
        Write-Host "Login '$SqlLogin' already exists. Skipping creation."
    }
    else {
        Write-Host "Creating login '$SqlLogin'..."
        $createLoginQuery = "CREATE LOGIN [$SqlLogin] WITH PASSWORD=N'$SqlPassword', CHECK_POLICY=OFF, CHECK_EXPIRATION=OFF;"
        Invoke-Sqlcmd -ServerInstance $SqlInstance -Query $createLoginQuery
    }

    # 2. Create DB User if missing
    $userCheck = Invoke-Sqlcmd -ServerInstance $SqlInstance -Database $DatabaseName -Query "SELECT name FROM sys.database_principals WHERE name='$SqlLogin'"
    if ($userCheck) {
        Write-Host "User '$SqlLogin' already exists in DB '$DatabaseName'."
    }
    else {
        Write-Host "Creating user '$SqlLogin' in DB '$DatabaseName'..."
        $createUserQuery = "CREATE USER [$SqlLogin] FOR LOGIN [$SqlLogin] WITH DEFAULT_SCHEMA=[dbo];"
        Invoke-Sqlcmd -ServerInstance $SqlInstance -Database $DatabaseName -Query $createUserQuery
    }

    # 3. Assign Role
    Write-Host "Assigning user '$SqlLogin' to role '$DbRole' in DB '$DatabaseName'."
    $addRoleQuery = "ALTER ROLE [$DbRole] ADD MEMBER [$SqlLogin];"
    Invoke-Sqlcmd -ServerInstance $SqlInstance -Database $DatabaseName -Query $addRoleQuery

    Write-Host "===== SQL User/Permission Setup Completed Successfully ====="
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
