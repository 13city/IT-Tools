# Dental IT Diagnostics Script

## Overview
A comprehensive PowerShell diagnostic tool designed specifically for dental office IT environments. This script automates the troubleshooting of common issues related to networked printers and dental practice management software.

## Features

### Print System Diagnostics
- Print Spooler service monitoring and automatic recovery
- Network printer connectivity testing
- Printer driver validation
- Print queue status checks

### Dental Software Diagnostics
- Service status monitoring for common dental software (Dentrix, Eaglesoft, DEXIS)
- Installation path verification
- Error log analysis
- Automatic service recovery attempts

### Network Diagnostics
- Basic network connectivity testing
- DNS resolution verification
- Network adapter status monitoring
- Shared drive accessibility testing

### Logging
- Detailed logging with timestamp and severity levels
- Color-coded console output for better visibility
- Persistent logs stored in ProgramData directory

## Requirements
- Windows PowerShell 5.1 or later
- Administrative privileges
- Windows 8.1/Server 2012 R2 or later

## Installation
1. Copy the script to your preferred location
2. Ensure execution policy allows script running:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage
Run the script with administrative privileges:
```powershell
.\DentalITDiagnostics.ps1
```

## Log Location
Logs are stored in:
```
C:\ProgramData\DentalITDiagnostics\
```

## Output Format
The script provides:
- Real-time console output with color coding:
  - Green: Information messages
  - Yellow: Warning messages
  - Red: Error messages
- Detailed log files with timestamps

## Troubleshooting
Common issues the script addresses:
1. Print spooler service failures
2. Network printer connectivity problems
3. Dental software service interruptions
4. Network drive mapping issues
5. Basic network connectivity problems

## Customization
The script can be customized by modifying:
- Dental software service names in the `$dentalServices` array
- Software installation paths in the `$softwarePaths` hashtable
- Network connectivity test targets in the `$internetTests` array

## Best Practices
1. Run the script during off-hours or low-activity periods
2. Review logs regularly for recurring issues
3. Keep a backup of previous diagnostic logs
4. Update software paths if dental software is installed in non-default locations
