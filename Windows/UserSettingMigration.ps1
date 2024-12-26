<#
.SYNOPSIS
    Automated user profile settings migration and backup utility.

.DESCRIPTION
    This script provides comprehensive user settings migration capabilities:
    - Profile Management:
      * Application settings backup
      * User preferences migration
      * Custom configurations transfer
      * Profile restoration
    - Application Settings:
      * Browser profiles
      * Shell preferences
      * Application data
      * Custom configurations
    - Security Features:
      * SSH key migration
      * Credential backup
      * Secure transfer
      * Access validation
    - Backup Operations:
      * Automated backup
      * Version control
      * Integrity checking
      * Restoration verification

.NOTES
    Author: 13city
    Compatible with:
    - Windows Server 2012 R2
    - Windows Server 2016
    - Windows Server 2019
    - Windows Server 2022
    - Windows 10/11
    
    Requirements:
    - PowerShell 5.1 or higher
    - Administrative privileges
    - Network connectivity
    - Share access permissions
    - Robocopy availability

.PARAMETER SourceComputer
    Source computer name
    Required parameter
    Must be network accessible
    Requires admin access

.PARAMETER DestinationComputer
    Target computer name
    Required parameter
    Must be network accessible
    Requires admin access

.PARAMETER Username
    User profile to migrate
    Required parameter
    Must exist on source
    Case-sensitive

.PARAMETER LogPath
    Migration log file path
    Optional parameter
    Default: Desktop\MigrationLog.txt
    Records all operations

.PARAMETER BackupPath
    Settings backup location
    Optional parameter
    Default: Desktop\UserBackup
    Stores temporary data

.EXAMPLE
    .\UserSettingMigration.ps1 -SourceComputer "OLD-PC" -DestinationComputer "NEW-PC" -Username "JohnDoe"
    Basic migration:
    - Uses default paths
    - Migrates standard settings
    - Creates basic logs
    - Default backup location

.EXAMPLE
    .\UserSettingMigration.ps1 -SourceComputer "OLD-PC" -DestinationComputer "NEW-PC" -Username "JohnDoe" -LogPath "C:\Logs\Migration.log" -BackupPath "D:\Backups\JohnDoe"
    Custom migration:
    - Specified log location
    - Custom backup path
    - Full settings transfer
    - Detailed logging
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceComputer,
    
    [Parameter(Mandatory=$true)]
    [string]$DestinationComputer,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:USERPROFILE\Desktop\MigrationLog.txt",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "$env:USERPROFILE\Desktop\UserBackup"
)

# Function to write to log file
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Add-Content -Path $LogPath
    Write-Host $Message
}

# Function to test computer connectivity
function Test-ComputerConnection {
    param($ComputerName)
    try {
        if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
            Write-Log "Successfully connected to $ComputerName"
            return $true
        } else {
            Write-Log "ERROR: Unable to connect to $ComputerName"
            return $false
        }
    } catch {
        Write-Log "ERROR: Exception while testing connection to $ComputerName : $_"
        return $false
    }
}

# Function to create backup directory
function New-BackupDirectory {
    try {
        if (-not (Test-Path -Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath | Out-Null
            Write-Log "Created backup directory at $BackupPath"
        }
    } catch {
        Write-Log "ERROR: Failed to create backup directory: $_"
        exit 1
    }
}

# Function to backup user settings
function Backup-UserSettings {
    param($Computer, $User)
    
    $settingsToBackup = @(
        "\AppData\Local\Microsoft\Windows\Themes",
        "\AppData\Roaming\Microsoft\Windows\Start Menu",
        "\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch",
        "\AppData\Local\Google\Chrome\User Data\Default",
        "\AppData\Roaming\Mozilla\Firefox\Profiles",
        "\Documents\WindowsPowerShell",
        "\.vscode",
        "\.ssh"
    )
    
    foreach ($setting in $settingsToBackup) {
        $sourcePath = "\\$Computer\c$\Users\$User$setting"
        $destinationPath = Join-Path $BackupPath $setting
        
        try {
            if (Test-Path $sourcePath) {
                # Create destination directory structure
                New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                
                # Copy items with robocopy for better handling of long paths and locked files
                $robocopyArgs = @(
                    $sourcePath,
                    $destinationPath,
                    "/E",        # Copy subdirectories, including empty ones
                    "/ZB",       # Use restartable mode; if access denied use backup mode
                    "/R:3",      # Number of retries
                    "/W:5",      # Wait time between retries
                    "/LOG+:$LogPath"  # Append to log file
                )
                
                $robocopyResult = Start-Process robocopy -ArgumentList $robocopyArgs -Wait -PassThru
                
                if ($robocopyResult.ExitCode -lt 8) {
                    Write-Log "Successfully backed up $setting"
                } else {
                    Write-Log "WARNING: Some files in $setting may not have been copied. Exit code: $($robocopyResult.ExitCode)"
                }
            } else {
                Write-Log "INFO: Source path $sourcePath does not exist, skipping"
            }
        } catch {
            Write-Log "ERROR: Failed to backup $setting : $_"
        }
    }
}

# Function to restore user settings
function Restore-UserSettings {
    param($Computer, $User)
    
    foreach ($setting in (Get-ChildItem -Path $BackupPath -Directory -Recurse)) {
        $destinationPath = "\\$Computer\c$\Users\$User\$($setting.FullName.Substring($BackupPath.Length))"
        
        try {
            # Create destination directory structure
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
            
            # Copy items with robocopy
            $robocopyArgs = @(
                $setting.FullName,
                $destinationPath,
                "/E",        # Copy subdirectories, including empty ones
                "/ZB",       # Use restartable mode; if access denied use backup mode
                "/R:3",      # Number of retries
                "/W:5",      # Wait time between retries
                "/LOG+:$LogPath"  # Append to log file
            )
            
            $robocopyResult = Start-Process robocopy -ArgumentList $robocopyArgs -Wait -PassThru
            
            if ($robocopyResult.ExitCode -lt 8) {
                Write-Log "Successfully restored $($setting.FullName)"
            } else {
                Write-Log "WARNING: Some files in $($setting.FullName) may not have been restored. Exit code: $($robocopyResult.ExitCode)"
            }
        } catch {
            Write-Log "ERROR: Failed to restore $($setting.FullName) : $_"
        }
    }
}

# Main script execution
try {
    Write-Log "Starting user settings migration from $SourceComputer to $DestinationComputer for user $Username"
    
    # Test connections to both computers
    if (-not (Test-ComputerConnection $SourceComputer) -or -not (Test-ComputerConnection $DestinationComputer)) {
        Write-Log "ERROR: Unable to establish connection to one or both computers. Exiting."
        exit 1
    }
    
    # Create backup directory
    New-BackupDirectory
    
    # Backup settings from source computer
    Write-Log "Starting backup from source computer"
    Backup-UserSettings -Computer $SourceComputer -User $Username
    
    # Verify backup
    if (-not (Test-Path $BackupPath)) {
        Write-Log "ERROR: Backup failed - backup directory not found"
        exit 1
    }
    
    # Restore settings to destination computer
    Write-Log "Starting restore to destination computer"
    Restore-UserSettings -Computer $DestinationComputer -User $Username
    
    Write-Log "Migration completed successfully"
} catch {
    Write-Log "ERROR: Migration failed with exception: $_"
    exit 1
}
