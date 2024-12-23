<#
.SYNOPSIS
    Creates or rebuilds a SQL Server database with optional table scripts.

.DESCRIPTION
    - Connects to a specified SQL Server instance.
    - Creates a new database if it doesn't exist, or drops & recreates if -Rebuild is used.
    - Optionally runs .sql files to build tables/stored procedures.

.NOTES
    Requires: PowerShell Invoke-Sqlcmd (SQLPS or SqlServer module)
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
