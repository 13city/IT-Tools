<#
.SYNOPSIS
    Implements and validates Transparent Data Encryption (TDE) on a SQL Server database.

.DESCRIPTION
    - Checks if a database is already encrypted.
    - If not, creates a master key, certificate, and applies TDE.
    - Validates encryption state.
    - Logs findings.

.NOTES
    Requires: SqlServer module or SQLPS
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SqlInstance,

    [Parameter(Mandatory=$true)]
    [string]$DatabaseName,

    [string]$LogPath = "C:\Logs",
    [string]$EncryptionKeyBackupPath = "C:\EncryptionBackups"
)

if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath | Out-Null
}
if (!(Test-Path $EncryptionKeyBackupPath)) {
    New-Item -ItemType Directory -Path $EncryptionKeyBackupPath | Out-Null
}

$timeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile   = Join-Path $LogPath "AdvancedSqlTDE-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    Write-Log "===== Starting Advanced SQL TDE Implementation & Validation ====="

    Import-Module SqlServer -ErrorAction SilentlyContinue

    # 1. Check if TDE is already enabled
    $dbEncryptionStateQuery = "SELECT name, is_encrypted FROM sys.databases WHERE name = '$DatabaseName'"
    $dbState = Invoke-Sqlcmd -ServerInstance $SqlInstance -Query $dbEncryptionStateQuery
    if ($dbState.is_encrypted -eq 1) {
        Write-Log "Database '$DatabaseName' on instance '$SqlInstance' is already TDE encrypted."
        exit 0
    }

    # 2. Create database master key and certificate if not existing
    Write-Log "Enabling TDE for $DatabaseName..."
    # Usually master key is created at the master database level
    $checkMasterKey = "SELECT COUNT(*) as Cnt FROM master.sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##'"
    $masterKeyExists = Invoke-Sqlcmd -ServerInstance $SqlInstance -Database "master" -Query $checkMasterKey
    if ($masterKeyExists.Cnt -lt 1) {
        Write-Log "Creating master key in master DB..."
        Invoke-Sqlcmd -ServerInstance $SqlInstance -Database "master" -Query "
            CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'ComplexPass123!'
        "
    }

    # 3. Create server certificate if not existing
    $checkCertQuery = "SELECT COUNT(*) as Cnt FROM master.sys.certificates WHERE name = 'TDECert'"
    $certExists = Invoke-Sqlcmd -ServerInstance $SqlInstance -Database "master" -Query $checkCertQuery
    if ($certExists.Cnt -lt 1) {
        Write-Log "Creating TDE certificate 'TDECert' in master DB..."
        Invoke-Sqlcmd -ServerInstance $SqlInstance -Database "master" -Query "
            CREATE CERTIFICATE TDECert
            WITH SUBJECT = 'TDE Encryption Certificate'
        "
        # Backup the cert and private key
        $bakPath = Join-Path $EncryptionKeyBackupPath "TDECert_$timeStamp.bak"
        $pvkPath = Join-Path $EncryptionKeyBackupPath "TDECert_$timeStamp.pvk"
        Write-Log "Backing up TDE certificate to $bakPath and private key to $pvkPath..."
        Invoke-Sqlcmd -ServerInstance $SqlInstance -Database "master" -Query "
            BACKUP CERTIFICATE TDECert
            TO FILE = '$bakPath'
            WITH PRIVATE KEY
            (
                FILE = '$pvkPath',
                ENCRYPTION BY PASSWORD = 'PrivateKeyPass!123',
                DECRYPTION BY PASSWORD = 'ComplexPass123!'
            )
        "
    }

    # 4. Enable TDE on target DB
    Write-Log "Enabling TDE on database $DatabaseName..."
    Invoke-Sqlcmd -ServerInstance $SqlInstance -Query "
        USE [$DatabaseName];
        CREATE DATABASE ENCRYPTION KEY
            WITH ALGORITHM = AES_256
            ENCRYPTION BY SERVER CERTIFICATE TDECert;
        ALTER DATABASE [$DatabaseName]
        SET ENCRYPTION ON;
    "

    # 5. Validate encryption state
    Start-Sleep -Seconds 5
    $newState = Invoke-Sqlcmd -ServerInstance $SqlInstance -Query $dbEncryptionStateQuery
    if ($newState.is_encrypted -eq 1) {
        Write-Log "SUCCESS: TDE is now enabled for $DatabaseName."
    } else {
        Write-Log "WARNING: TDE enable operation did not reflect as encrypted yet."
    }

    Write-Log "===== Advanced SQL TDE Implementation & Validation Completed ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
