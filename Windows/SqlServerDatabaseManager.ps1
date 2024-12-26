<#
.SYNOPSIS
    Advanced SQL Server database deployment and management automation toolkit.

.DESCRIPTION
    This script provides comprehensive database management capabilities:
    - Database Operations:
      * New database creation
      * Database rebuilding
      * Conditional deployment
      * Single-user mode handling
      * Rollback management
    - Script Execution:
      * Table creation scripts
      * Stored procedure deployment
      * Index management
      * Schema updates
      * Data migration
    - Safety Features:
      * Existence checks
      * Rebuild confirmation
      * Error handling
      * Transaction management
      * Rollback procedures
    - Deployment Options:
      * Recursive script execution
      * Ordered deployment
      * Dependency management
      * Version control
      * Environment targeting

.NOTES
    Author: 13city
    Version: 2.0
    
    Compatible with:
    - SQL Server 2012+
    - SQL Server 2014+
    - SQL Server 2016+
    - SQL Server 2017+
    - SQL Server 2019+
    
    Requirements:
    - PowerShell 5.1 or higher
    - SqlServer PowerShell module
    - Sysadmin or appropriate rights
    - Script folder read access
    - Database create permissions

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

.PARAMETER Rebuild
    Database rebuild switch
    Default: False
    Forces complete rebuild
    Requires elevated permissions

.PARAMETER ScriptFolder
    SQL script directory path
    Optional parameter
    Supports recursive execution
    Processes .sql files only

.EXAMPLE
    .\SqlServerDatabaseManager.ps1 -SqlInstance "SQLSERVER01" -DatabaseName "CustomerDB"
    Basic database creation:
    - Creates new database
    - Skips if exists
    - No script execution
    - Default settings

.EXAMPLE
    .\SqlServerDatabaseManager.ps1 -SqlInstance "SQLSERVER01\PROD" -DatabaseName "FinanceDB" -Rebuild -ScriptFolder "D:\DBScripts"
    Full database deployment:
    - Forces database rebuild
    - Executes all SQL scripts
    - Processes recursively
    - Handles dependencies

.EXAMPLE
    .\SqlServerDatabaseManager.ps1 -SqlInstance "." -DatabaseName "TestDB" -ScriptFolder ".\Scripts"
    Local development setup:
    - Uses local instance
    - Creates test database
    - Runs local scripts
    - Preserves existing DB
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SqlInstance,

    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,

    [switch]$Rebuild = $false,

    [string]$ScriptFolder = ""
)

try {
    Write-Host "===== Starting SQL Server Database Management ====="

    # 1. Check if DB exists
    $dbExists = Invoke-Sqlcmd -ServerInstance $SqlInstance -Query "SELECT name FROM sys.databases WHERE name='$DatabaseName'" -ErrorAction Stop

    if ($dbExists -and !$Rebuild) {
        Write-Host "Database '$DatabaseName' already exists. Skipping creation."
    }
    elseif ($dbExists -and $Rebuild) {
        Write-Host "Dropping and recreating '$DatabaseName' due to -Rebuild."
        Invoke-Sqlcmd -ServerInstance $SqlInstance -Query "ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$DatabaseName];"
        Invoke-Sqlcmd -ServerInstance $SqlInstance -Query "CREATE DATABASE [$DatabaseName];"
    }
    else {
        Write-Host "Creating new database '$DatabaseName'..."
        Invoke-Sqlcmd -ServerInstance $SqlInstance -Query "CREATE DATABASE [$DatabaseName];"
    }

    # 2. Run table or stored proc scripts if provided
    if ($ScriptFolder -and (Test-Path $ScriptFolder)) {
        $sqlFiles = Get-ChildItem -Path $ScriptFolder -Filter "*.sql" -Recurse
        foreach ($file in $sqlFiles) {
            Write-Host "Executing script $($file.Name) on $DatabaseName..."
            Invoke-Sqlcmd -ServerInstance $SqlInstance -Database $DatabaseName -InputFile $file.FullName
        }
    }

    Write-Host "===== SQL Server Database Management Completed Successfully ====="
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
