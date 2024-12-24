# Microsoft 365 Apps (Office) Troubleshooting Guide

## 1. Installation Issues

### 1.1 Installation Failures
#### Symptoms
- Setup errors
- Download failures
- Installation hangs
- Configuration errors
- Prerequisite issues

#### Troubleshooting Steps
1. Check system requirements
2. Review setup logs
   ```powershell
   Get-Content "$env:TEMP\Microsoft Office Setup*.txt"
   ```
3. Verify installation account permissions
4. Check disk space
5. Test network connectivity

### 1.2 Common Installation Errors
- Error 30015-1039: Another installation is in progress
- Error 30068-39: Office installation failed
- Error 30175-4: Unable to install
- Error 30183-1039: Office couldn't be installed
- Error 30088-1039: Setup couldn't verify license

## 2. Activation Problems

### 2.1 License Issues
#### Symptoms
- Product not activated
- License errors
- Subscription expired
- Activation failed
- Shared computer activation issues

#### Troubleshooting Steps
1. Check license status
   ```powershell
   cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /dstatus
   ```
2. Verify subscription
   ```powershell
   Get-MsolUser -UserPrincipalName user@domain.com | Select-Object Licenses
   ```
3. Reset activation state
   ```powershell
   cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /rearm
   ```

### 2.2 Common Activation Errors
- 0x8004FC12: Internet connectivity required
- 0x80070005: Access denied
- 0xC004F074: Key not valid
- 0xC004B100: Activation server unavailable
- 0xC004F038: Software protection service not running

## 3. Application-Specific Issues

### 3.1 Outlook Problems
#### Symptoms
- Profile corruption
- PST/OST issues
- Search problems
- Add-in conflicts
- Performance issues

#### Resolution Steps
1. Create new profile
2. Repair OST/PST
3. Rebuild search index
4. Disable add-ins
5. Clear cache

### 3.2 Word/Excel/PowerPoint
#### Symptoms
- File corruption
- Template issues
- Add-in problems
- Recovery errors
- Performance degradation

#### Troubleshooting Steps
1. Safe mode testing
2. Repair documents
3. Reset user options
4. Clear temp files
5. Check file permissions

## 4. PowerShell Commands

### 4.1 Office Configuration
```powershell
# Get Office configuration
Get-OfficeConfiguration

# Check installation
Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE 'Microsoft Office%'"

# Review Click-to-Run configuration
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
```

### 4.2 License Management
```powershell
# Check Office activation
(Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object {$_.Name -like "*Office*"}).LicenseStatus

# View license details
Get-MsolAccountSku

# Check user license
Get-MsolUser -UserPrincipalName user@domain.com | Select-Object Licenses
```

## 5. Common Resolution Steps

### 5.1 Installation Issues
1. Run Office Repair
2. Clear Office cache
3. Uninstall/reinstall
4. Use offline installer
5. Check system requirements

### 5.2 Activation Problems
1. Reset license status
2. Verify credentials
3. Check connectivity
4. Update Office
5. Reactivate Office

### 5.3 Application Issues
1. Safe mode testing
2. Disable add-ins
3. Clear cache
4. Reset settings
5. Repair installation

## 6. Preventive Measures

### 6.1 Regular Maintenance
- Keep Office updated
- Monitor activation status
- Check disk space
- Review event logs
- Update add-ins

### 6.2 Best Practices
- Regular backups
- Document templates
- User training
- Add-in management
- Update policies

## 7. Advanced Troubleshooting

### 7.1 Registry Locations
```
HKEY_CURRENT_USER\Software\Microsoft\Office\16.0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Office\ClickToRun
HKEY_CURRENT_USER\Software\Microsoft\Office\Common
```

### 7.2 Log Files
- Setup logs: %temp%
- Click-to-Run logs: %windir%\System32\config\systemprofile\AppData\Local\Microsoft\Office\16.0\OfficeClickToRun
- Application logs: %appdata%\Microsoft\Office

## 8. Required Permissions

### 8.1 Admin Roles
- Global Administrator
- License Administrator
- User Management Administrator
- Office Apps Administrator
- Help Desk Administrator

### 8.2 Local Requirements
- Local Administrator (for installation)
- User account permissions
- Network access
- Internet connectivity
- Disk permissions

## 9. Documentation Requirements

### 9.1 Incident Documentation
- Issue description
- Application version
- Error messages
- Resolution steps
- Prevention measures

### 9.2 Change Documentation
- Change description
- Impact assessment
- Rollback plan
- Testing procedures
- Approval process

## 10. Escalation Process

### 10.1 When to Escalate
- Installation failures
- Activation issues
- Data corruption
- Performance problems
- Security concerns

### 10.2 Required Information
- Office version
- License details
- Error messages
- Log files
- System information

## 11. Group Policy Management

### 11.1 Policy Settings
- Installation options
- Update settings
- Security settings
- User configurations
- Application settings

### 11.2 Common Policies
```
Computer Configuration\Administrative Templates\Microsoft Office 2016 (Machine)
User Configuration\Administrative Templates\Microsoft Office 2016
```

## 12. Security and Updates

### 12.1 Security Features
- Protected View
- Trusted Locations
- Macro Security
- Document Encryption
- Digital Signatures

### 12.2 Update Management
- Update channels
- Deployment settings
- Version control
- Rollback options
- Network usage
