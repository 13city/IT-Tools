<#
.SYNOPSIS
    Automates creation or rebuilding of a MongoDB "database" (logical namespace).

.DESCRIPTION
    - Connects to MongoDB using mongosh.
    - Optionally drops existing DB if -Rebuild is used.
    - Runs .js or .mongo files containing collection creation or index creation.
    - Requires Mongo shell (mongosh) to be installed.

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
