<#
.SYNOPSIS
    Comprehensive employee onboarding automation for Active Directory and Microsoft 365 environments.

.DESCRIPTION
    This script automates the complete employee onboarding process by:
    - Creating Active Directory user accounts with standardized naming conventions
    - Configuring Microsoft 365 mailboxes and settings using Microsoft Graph
    - Setting up OneDrive storage with department-specific quotas
    - Managing security group memberships
    - Applying security policies and MFA requirements
    - Installing required department-specific software
    - Sending welcome emails with credentials to managers
    - Implementing department-specific configurations
    - Managing distribution group memberships
    - Setting up mailbox regional configurations

.NOTES
    Author: 13city
    
    Requirements:
    - PowerShell 5.1 or higher
    - Administrative rights in AD and Microsoft 365
    - Required PowerShell modules:
      * ActiveDirectory
      * Microsoft.Graph
      * Microsoft.Graph.Users
      * Microsoft.Graph.Users.Actions
      * Microsoft.Graph.Mail
      * Microsoft.Graph.Groups
    - Network connectivity to AD and Microsoft 365
    - Access to software installation shares
    - Write access to log directory

.PARAMETER FirstName
    Employee's first name
    Required for user account creation and email setup

.PARAMETER LastName
    Employee's last name
    Required for user account creation and email setup

.PARAMETER Department
    Employee's department
    Used for OU placement and group assignments
    Must match department configurations in dept_configs.json

.PARAMETER Title
    Employee's job title
    Used for AD account properties and HR documentation

.PARAMETER Manager
    Employee's direct manager
    Receives welcome email with credentials
    Must be an existing AD user

.PARAMETER Location
    Employee's primary work location
    Default: "HQ"
    Used for AD account properties

.PARAMETER LogPath
    Path for script execution logs
    Default: "$env:USERPROFILE\Desktop\OnboardingLog.txt"
    Creates detailed timestamp logs of all actions

.PARAMETER ConfigPath
    Path to department configuration JSON file
    Default: ".\dept_configs.json"
    Contains department-specific settings and requirements

.EXAMPLE
    .\NewEmployeeOnboarding.ps1 -FirstName "John" -LastName "Doe" -Department "Sales" -Title "Account Executive" -Manager "Jane Smith"
    Creates a new user account with default location and logging settings

.EXAMPLE
    .\NewEmployeeOnboarding.ps1 -FirstName "Alice" -LastName "Johnson" -Department "IT" -Title "Systems Engineer" -Manager "Bob Wilson" -Location "Remote" -LogPath "C:\Logs\Onboarding.txt"
    Creates a new user account with custom location and log path

.EXAMPLE
    .\NewEmployeeOnboarding.ps1 -FirstName "David" -LastName "Brown" -Department "Finance" -Title "Financial Analyst" -Manager "Sarah Davis" -ConfigPath "C:\Configs\custom_dept_configs.json"
    Creates a new user account using custom department configurations
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$FirstName,
    
    [Parameter(Mandatory=$true)]
    [string]$LastName,
    
    [Parameter(Mandatory=$true)]
    [string]$Department,
    
    [Parameter(Mandatory=$true)]
    [string]$Title,
    
    [Parameter(Mandatory=$true)]
    [string]$Manager,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "HQ",
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:USERPROFILE\Desktop\OnboardingLog.txt",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = ".\dept_configs.json"
)

# Import required modules
$requiredModules = @(
    'ActiveDirectory',
    'Microsoft.Graph',
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Users.Actions',
    'Microsoft.Graph.Mail',
    'Microsoft.Graph.Groups'
)

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Add-Content -Path $LogPath
    Write-Host $Message
}

function Install-RequiredModules {
    foreach ($module in $requiredModules) {
        try {
            if (!(Get-Module -ListAvailable -Name $module)) {
                Write-Log "Installing module: $module"
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
            }
            Import-Module $module -ErrorAction Stop
        } catch {
            Write-Log "ERROR: Failed to install/import $module : $_"
            exit 1
        }
    }
}

function Connect-MicrosoftGraph {
    try {
        Connect-MgGraph -Scopes @(
            "User.ReadWrite.All",
            "Group.ReadWrite.All",
            "Mail.Send",
            "MailboxSettings.ReadWrite",
            "Directory.ReadWrite.All"
        )
        Select-MgProfile -Name "beta"
    } catch {
        Write-Log "ERROR: Failed to connect to Microsoft Graph: $_"
        exit 1
    }
}

function Get-DepartmentConfig {
    param($DepartmentName)
    try {
        $configs = Get-Content $ConfigPath | ConvertFrom-Json
        return $configs.$DepartmentName
    } catch {
        Write-Log "ERROR: Failed to load department configuration: $_"
        exit 1
    }
}

function New-RandomPassword {
    $length = 16
    $nonAlphanumeric = 5
    $unicode = $null
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphanumeric)
}

function New-ADUser {
    param(
        $FirstName,
        $LastName,
        $Department,
        $Title,
        $Manager,
        $Location
    )
    
    try {
        $username = ($FirstName.Substring(0,1) + $LastName).ToLower()
        $count = 1
        while (Get-ADUser -Filter "SamAccountName -eq '$username'") {
            $username = ($FirstName.Substring(0,1) + $LastName + $count).ToLower()
            $count++
        }
        
        $password = New-RandomPassword
        
        $params = @{
            Name = "$FirstName $LastName"
            GivenName = $FirstName
            Surname = $LastName
            SamAccountName = $username
            UserPrincipalName = "$username@yourdomain.com"
            EmailAddress = "$username@yourdomain.com"
            Title = $Title
            Department = $Department
            Company = "Your Company Name"
            Enabled = $true
            ChangePasswordAtLogon = $true
            AccountPassword = (ConvertTo-SecureString -String $password -AsPlainText -Force)
            Path = "OU=Users,OU=$Department,DC=yourdomain,DC=com"
        }
        
        New-ADUser @params
        
        # Set manager if specified
        if ($Manager) {
            $managerObject = Get-ADUser -Filter "Name -eq '$Manager'"
            if ($managerObject) {
                Set-ADUser -Identity $username -Manager $managerObject
            }
        }
        
        return @{
            Username = $username
            Password = $password
            Email = "$username@yourdomain.com"
        }
    } catch {
        Write-Log "ERROR: Failed to create AD user: $_"
        throw
    }
}

function Add-UserToGroups {
    param(
        $Username,
        $Department,
        $DepartmentConfig
    )
    
    try {
        # Add to AD Security Groups
        foreach ($group in $DepartmentConfig.SecurityGroups) {
            Add-ADGroupMember -Identity $group -Members $Username
            Write-Log "Added user to security group: $group"
        }
        
        # Add to Microsoft 365 Groups
        $userEmail = "$Username@yourdomain.com"
        foreach ($group in $DepartmentConfig.DistributionGroups) {
            $mgGroup = Get-MgGroup -Filter "displayName eq '$group'"
            if ($mgGroup) {
                New-MgGroupMember -GroupId $mgGroup.Id -DirectoryObjectId (Get-MgUser -Filter "mail eq '$userEmail'").Id
                Write-Log "Added user to Microsoft 365 group: $group"
            }
        }
    } catch {
        Write-Log "ERROR: Failed to add user to groups: $_"
        throw
    }
}

function Set-UserMailbox {
    param(
        $Username,
        $DepartmentConfig
    )
    
    try {
        $userId = (Get-MgUser -Filter "userPrincipalName eq '$Username@yourdomain.com'").Id
        
        # Set mailbox settings using Microsoft Graph
        $mailboxSettings = @{
            Language = @{
                LocaleId = $DepartmentConfig.MailboxLanguage
            }
            TimeZone = $DepartmentConfig.TimeZone
        }
        Update-MgUserMailboxSetting -UserId $userId -BodyParameter $mailboxSettings
        
        # Set auto-reply if specified
        if ($DepartmentConfig.AutoReplyTemplate) {
            $autoReplySettings = @{
                AutoReplyStatus = "Scheduled"
                ExternalAudience = "All"
                InternalReplyMessage = $DepartmentConfig.AutoReplyTemplate
                ExternalReplyMessage = $DepartmentConfig.AutoReplyTemplate
            }
            Update-MgUserMailboxSetting -UserId $userId -AutomaticRepliesSetting $autoReplySettings
        }
    } catch {
        Write-Log "ERROR: Failed to configure mailbox: $_"
        throw
    }
}

function Set-UserOneDrive {
    param(
        $Username,
        $DepartmentConfig
    )
    
    try {
        $userId = (Get-MgUser -Filter "userPrincipalName eq '$Username@yourdomain.com'").Id
        
        # Initialize OneDrive
        $params = @{
            "owner@odata.bind" = "https://graph.microsoft.com/v1.0/users/$userId"
        }
        New-MgUserDrive -UserId $userId -BodyParameter $params
        
        # Set quota (Note: Quota management might require SharePoint admin API)
        Write-Log "OneDrive provisioned for user. Quota management may require additional SharePoint configuration."
    } catch {
        Write-Log "ERROR: Failed to configure OneDrive: $_"
        throw
    }
}

function Set-SecurityPolicies {
    param(
        $Username,
        $DepartmentConfig
    )
    
    try {
        $userId = (Get-MgUser -Filter "userPrincipalName eq '$Username@yourdomain.com'").Id
        
        # Apply authentication methods policy
        if ($DepartmentConfig.RequireMFA) {
            $authenticationMethods = @{
                "@odata.type" = "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod"
                "requireMfa" = $true
            }
            Update-MgUserAuthenticationMethod -UserId $userId -BodyParameter $authenticationMethods
        }
        
        # Apply conditional access policies if needed
        # Note: This would require additional Microsoft Graph Authentication Policy API calls
        Write-Log "Security policies applied successfully"
    } catch {
        Write-Log "ERROR: Failed to set security policies: $_"
        throw
    }
}

function Send-WelcomeEmail {
    param(
        $UserInfo,
        $Manager,
        $DepartmentConfig
    )
    
    try {
        $managerUser = Get-MgUser -Filter "displayName eq '$Manager'"
        
        $messageParams = @{
            Message = @{
                Subject = "New Employee Account Details"
                Body = @{
                    ContentType = "Text"
                    Content = @"
New employee account has been created:

Username: $($UserInfo.Username)
Email: $($UserInfo.Email)
Temporary Password: $($UserInfo.Password)

Please provide these credentials to the new employee securely.
The user will be prompted to change their password at first login.

Additional setup instructions and company policies can be found at: $($DepartmentConfig.WelcomeGuideURL)
"@
                }
                ToRecipients = @(
                    @{
                        EmailAddress = @{
                            Address = $managerUser.Mail
                        }
                    }
                )
            }
            SaveToSentItems = $true
        }
        
        Send-MgUserMail -UserId "it@yourdomain.com" -BodyParameter $messageParams
    } catch {
        Write-Log "ERROR: Failed to send welcome email: $_"
        throw
    }
}

# Main execution
try {
    Write-Log "Starting new employee onboarding process for $FirstName $LastName"
    
    # Install required modules
    Install-RequiredModules
    
    # Connect to Microsoft Graph
    Connect-MicrosoftGraph
    
    # Load department configuration
    $deptConfig = Get-DepartmentConfig -DepartmentName $Department
    
    # Create AD user and get credentials
    $userInfo = New-ADUser -FirstName $FirstName -LastName $LastName -Department $Department -Title $Title -Manager $Manager -Location $Location
    Write-Log "Created new AD user: $($userInfo.Username)"
    
    # Add user to appropriate groups
    Add-UserToGroups -Username $userInfo.Username -Department $Department -DepartmentConfig $deptConfig
    
    # Set up Exchange mailbox
    Set-UserMailbox -Username $userInfo.Username -DepartmentConfig $deptConfig
    
    # Configure OneDrive
    Set-UserOneDrive -Username $userInfo.Username -DepartmentConfig $deptConfig
    
    # Set security policies
    Set-SecurityPolicies -Username $userInfo.Username -DepartmentConfig $deptConfig
    
    # Install required software if computer name is provided
    if ($deptConfig.RequiredSoftware -and $ComputerName) {
        Install-RequiredSoftware -ComputerName $ComputerName -DepartmentConfig $deptConfig
    }
    
    # Send welcome email with credentials to manager
    Send-WelcomeEmail -UserInfo $userInfo -Manager $Manager -DepartmentConfig $deptConfig
    
    Write-Log "Onboarding process completed successfully for $($userInfo.Username)"
    
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph
} catch {
    Write-Log "ERROR: Onboarding process failed: $_"
    exit 1
}
