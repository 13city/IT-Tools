# New Employee Onboarding Automation Script
# Requires PowerShell 5.1 or higher and appropriate admin rights
# Required modules: AzureAD, MSOnline, ExchangeOnlineManagement, Microsoft.Graph
# .\New-EmployeeOnboarding.ps1 -FirstName "John" -LastName "Doe" -Department "Sales" -Title "Account Executive" -Manager "Jane Smith"

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
    'AzureAD',
    'MSOnline',
    'ExchangeOnlineManagement'
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
        foreach ($group in $DepartmentConfig.SecurityGroups) {
            Add-ADGroupMember -Identity $group -Members $Username
            Write-Log "Added user to security group: $group"
        }
        
        foreach ($group in $DepartmentConfig.DistributionGroups) {
            Add-DistributionGroupMember -Identity $group -Member "$Username@yourdomain.com"
            Write-Log "Added user to distribution group: $group"
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
        # Create Exchange Online mailbox
        Enable-RemoteMailbox -Identity $Username -RemoteRoutingAddress "$Username@yourdomain.mail.onmicrosoft.com"
        
        # Set mailbox settings
        Set-MailboxRegionalConfiguration -Identity $Username -Language $DepartmentConfig.MailboxLanguage -TimeZone $DepartmentConfig.TimeZone
        
        # Set auto-reply template if specified
        if ($DepartmentConfig.AutoReplyTemplate) {
            Set-MailboxAutoReplyConfiguration -Identity $Username -AutoReplyState Enabled -InternalMessage $DepartmentConfig.AutoReplyTemplate -ExternalMessage $DepartmentConfig.AutoReplyTemplate
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
        # Provision OneDrive
        Request-SPOPersonalSite -UserEmails "$Username@yourdomain.com"
        
        # Set quota
        Set-SPOSite -Identity "https://yourdomain-my.sharepoint.com/personal/$Username" -StorageQuota $DepartmentConfig.OneDriveQuota
    } catch {
        Write-Log "ERROR: Failed to configure OneDrive: $_"
        throw
    }
}

function Install-RequiredSoftware {
    param(
        $ComputerName,
        $DepartmentConfig
    )
    
    try {
        foreach ($software in $DepartmentConfig.RequiredSoftware) {
            $installerPath = "\\server\software\$($software.InstallerPath)"
            $arguments = $software.InstallArguments
            
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                Start-Process -FilePath $using:installerPath -ArgumentList $using:arguments -Wait
            }
            Write-Log "Installed software: $($software.Name)"
        }
    } catch {
        Write-Log "ERROR: Failed to install software: $_"
        throw
    }
}

function Set-SecurityPolicies {
    param(
        $Username,
        $DepartmentConfig
    )
    
    try {
        # Apply security policies
        foreach ($policy in $DepartmentConfig.SecurityPolicies) {
            Set-ADUser -Identity $Username -Replace @{
                "msDS-UserAllowedToAuthenticateFrom" = $policy.AllowedAuthLocations
                "msDS-UserAuthenticationPolicy" = $policy.AuthenticationPolicy
            }
        }
        
        # Enable MFA if required
        if ($DepartmentConfig.RequireMFA) {
            $st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
            $st.RelyingParty = "*"
            $st.State = "Enabled"
            $sta = @($st)
            Set-MsolUser -UserPrincipalName "$Username@yourdomain.com" -StrongAuthenticationRequirements $sta
        }
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
        $emailParams = @{
            To = $Manager
            From = "it@yourdomain.com"
            Subject = "New Employee Account Details"
            Body = @"
New employee account has been created:

Username: $($UserInfo.Username)
Email: $($UserInfo.Email)
Temporary Password: $($UserInfo.Password)

Please provide these credentials to the new employee securely.
The user will be prompted to change their password at first login.

Additional setup instructions and company policies can be found at: $($DepartmentConfig.WelcomeGuideURL)
"@
        }
        
        Send-MailMessage @emailParams
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
} catch {
    Write-Log "ERROR: Onboarding process failed: $_"
    exit 1
}