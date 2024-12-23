<#
.SYNOPSIS
    Creates SQL Logins, DB Users, and assigns permissions in a newly created database.

.DESCRIPTION
    - Connects to a SQL instance.
    - Checks if login exists, creates if missing.
    - Creates corresponding DB user and assigns roles (db_owner, etc.).
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
