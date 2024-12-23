<#
.SYNOPSIS
    Automates user account migration between two AD forests.

.DESCRIPTION
    - Connects to source and target forests.
    - Copies user objects, groups, and some essential attributes.
    - Optionally merges existing accounts if found in target forest.
    - Logs operations for auditing.

.NOTES
    Requires: ActiveDirectory PowerShell Module, trust/credential with both forests
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceDomainController,

    [Parameter(Mandatory=$true)]
    [string]$TargetDomainController,

    [Parameter(Mandatory=$true)]
    [string]$SourceFQDN,

    [Parameter(Mandatory=$true)]
    [string]$TargetFQDN,

    [Parameter(Mandatory=$true)]
    [string]$SourceCredentialsFile,  # PSCredential in secure file

    [Parameter(Mandatory=$true)]
    [string]$TargetCredentialsFile,  # PSCredential in secure file

    [switch]$MergeExisting = $false
)

$scriptName = "CrossForestUserMigration"
$timeStamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile    = "C:\Logs\$scriptName-$timeStamp.log"

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date), $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

try {
    # Load Credentials
    $srcCred = Import-Clixml -Path $SourceCredentialsFile
    $tgtCred = Import-Clixml -Path $TargetCredentialsFile

    Write-Log "===== Starting Cross-Forest AD User Migration ====="
    Write-Log "Source: $SourceFQDN ($SourceDomainController) => Target: $TargetFQDN ($TargetDomainController)"

    # 1. Connect to Source & Target
    Import-Module ActiveDirectory

    # Example: Get user objects from Source
    $sourceUsers = Get-ADUser -Filter * -Server $SourceDomainController -Credential $srcCred -SearchBase "DC=$($SourceFQDN -replace '\.','\,DC=')" -Properties memberOf

    Write-Log "Retrieved $($sourceUsers.Count) users from Source domain."

    foreach ($user in $sourceUsers) {
        # Check if user exists in Target
        $targetUser = Get-ADUser -Filter { SamAccountName -eq $($user.SamAccountName) } -Server $TargetDomainController -Credential $tgtCred -ErrorAction SilentlyContinue

        if ($targetUser -and !$MergeExisting) {
            Write-Log "User $($user.SamAccountName) already exists in Target. Skipping."
            continue
        }

        if ($MergeExisting -and $targetUser) {
            Write-Log "Merging existing user $($user.SamAccountName)..."
            # Example: Update missing attributes
            Set-ADUser -Identity $targetUser.DistinguishedName -Server $TargetDomainController -Credential $tgtCred `
                -DisplayName $user.DisplayName -EmailAddress $user.EmailAddress
            continue
        }

        # 2. Create user in Target
        Write-Log "Creating user $($user.SamAccountName) in Target."
        $newUserParams = @{
            'Name'              = $user.Name
            'SamAccountName'    = $user.SamAccountName
            'UserPrincipalName' = $user.UserPrincipalName
            'Path'              = "OU=Users,DC=$($TargetFQDN -replace '\.','\,DC=')"
            'Server'            = $TargetDomainController
            'Credential'        = $tgtCred
        }
        New-ADUser @newUserParams

        # Add to groups or copy attributes as needed
        # For brevity, we'll only show a simplified approach
    }

    Write-Log "===== Cross-Forest Migration Completed Successfully ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
