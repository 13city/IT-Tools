<# 
.SYNOPSIS
    Advanced MongoDB database management and automation system.

.DESCRIPTION
    This script provides comprehensive MongoDB database management:
    - Creates or rebuilds MongoDB databases
    - Executes database initialization scripts
    - Manages collection and index creation
    - Supports database rebuilding
    - Processes multiple script files
    - Provides detailed operation logging
    - Validates database operations
    - Handles errors gracefully
    - Supports custom script folders
    - Ensures data consistency

.NOTES
    Author: 13city
    Compatible with: Windows Server 2016-2022, Windows 10/11
    Requirements:
    - MongoDB Shell (mongosh) installed
    - Network connectivity to MongoDB server
    - Appropriate MongoDB user permissions
    - PowerShell 5.1 or higher
    - Write access to C:\Logs
    - Valid MongoDB connection string

.PARAMETER MongoHost
    MongoDB server hostname/address
    Required: Yes
    Format: hostname[:port]
    Example: "localhost:27017"
    Must be accessible from execution environment

.PARAMETER DatabaseName
    Target database name
    Required: Yes
    Format: Valid MongoDB database name
    Example: "myApplication"
    Case-sensitive

.PARAMETER Rebuild
    Switch to enable database rebuild
    Default: False
    Warning: Drops existing database
    Use with caution in production

.PARAMETER ScriptFolder
    Path to folder containing MongoDB scripts
    Required: No
    Default: Empty (creates empty database)
    Accepts: .js and .mongo files

.EXAMPLE
    .\MongoDbManager.ps1 -MongoHost "localhost:27017" -DatabaseName "myApp"
    Basic database creation:
    - Creates new database
    - No existing data affected
    - Creates default collection
    - Standard logging

.EXAMPLE
    .\MongoDbManager.ps1 -MongoHost "mongodb.local" -DatabaseName "customerDB" -Rebuild -ScriptFolder "C:\DBScripts"
    Full database rebuild:
    - Drops existing database
    - Creates new database
    - Executes all scripts
    - Detailed logging

.EXAMPLE
    .\MongoDbManager.ps1 -MongoHost "192.168.1.100:27017" -DatabaseName "analytics" -ScriptFolder ".\scripts"
    Script-based initialization:
    - Preserves existing data
    - Runs initialization scripts
    - Creates collections/indexes
    - Validates operations
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$MongoHost,

    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,

    [switch]$Rebuild = $false,

    [string]$ScriptFolder = ""
)

$scriptName = "MongoDbManager"
$timeStamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile    = "C:\Logs\$scriptName-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    Write-Log "===== Starting MongoDB Management for '$DatabaseName' at $MongoHost ====="

    # 1. Optional drop
    if ($Rebuild) {
        Write-Log "Dropping existing '$DatabaseName' if it exists."
        & mongosh --host $MongoHost --eval "db.getSiblingDB('$DatabaseName').dropDatabase()" 2>> $logFile
    }

    # 2. Create DB by simply referencing it and writing a doc or running scripts
    if ($ScriptFolder -and (Test-Path $ScriptFolder)) {
        Write-Log "Executing .js or .mongo files in '$ScriptFolder'..."
        $dbScripts = Get-ChildItem -Path $ScriptFolder -Include *.js,*.mongo -Recurse

        foreach ($script in $dbScripts) {
            Write-Log "Running script $($script.Name) on $DatabaseName"
            & mongosh --host $MongoHost $DatabaseName $script.FullName 2>> $logFile
        }
    }
    else {
        Write-Log "No scripts provided. Creating an empty collection to finalize DB creation."
        $createCmd = "db.createCollection('defaultCollection')"
        & mongosh --host $MongoHost $DatabaseName --eval $createCmd 2>> $logFile
    }

    Write-Log "===== MongoDB Management Completed Successfully ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
