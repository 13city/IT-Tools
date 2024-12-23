# Network Configuration Auditor

This PowerShell script automates the auditing of Cisco network device configurations by comparing them against best practices templates. It connects to network devices via SSH to gather interface statuses, VLAN assignments, and routing tables, then identifies any discrepancies from the defined best practices.

## Features

- SSH connectivity to Cisco network devices
- Retrieval of interface statuses
- VLAN assignment verification
- Routing table analysis
- Comparison against best practices templates
- Detailed discrepancy reporting
- JSON report generation

## Requirements

- PowerShell 5.1 or later
- Posh-SSH module
- Network access to target devices
- Valid device credentials

## Installation

1. Install the required Posh-SSH module:
```powershell
Install-Module -Name Posh-SSH -Scope CurrentUser
```

2. Place the script in your desired directory
3. Prepare the input files (see Input Files section below)

## Input Files

### Device List (CSV)
Create a CSV file with the following columns:
```csv
IPAddress,Username,Password
192.168.1.1,admin,password123
192.168.1.2,admin,password456
```

### Best Practices Template (JSON)
Create a JSON file with your desired best practices configuration. If not provided, the script will use default values:
```json
{
  "VLANs": {
    "Management": 1,
    "Native": 1,
    "Voice": "100-110",
    "Data": "111-999",
    "Reserved": "1000-4094"
  },
  "Interfaces": {
    "TrunkPorts": {
      "AllowedVlans": "1-999",
      "Mode": "trunk",
      "NativeVlan": 1
    },
    "AccessPorts": {
      "Mode": "access",
      "PortSecurity": true,
      "StormControl": true
    }
  },
  "ACLs": {
    "InboundRules": [
      "permit tcp any any established",
      "deny ip any any log"
    ],
    "OutboundRules": [
      "permit ip any any"
    ]
  }
}
```

## Usage

```powershell
.\NetworkConfigurationAuditor.ps1 -DeviceList "devices.csv" -TemplateFile "best_practices.json"
```

## Output

The script generates two types of output:

1. Console Output:
   - Real-time status of device connections
   - Discovered discrepancies with color coding
   - Error messages and warnings

2. JSON Report:
   - Detailed configuration data
   - List of all discrepancies
   - Timestamp and device information
   - Saved as "NetworkAudit_[IP]_[Timestamp].json"

## Error Handling

The script includes comprehensive error handling for:
- Failed SSH connections
- Invalid command execution
- File access issues
- Invalid configuration formats

## Security Considerations

- Credentials in the CSV file are stored in plain text. Consider using a secure credential store in production environments.
- SSH sessions are automatically closed after use.
- The script accepts SSH host keys automatically (-AcceptKey parameter).

## Best Practices Template Customization

The default best practices template includes common security and configuration standards. Customize the template JSON file to match your organization's specific requirements:

- VLAN ranges for different purposes (management, voice, data)
- Interface security settings (port security, storm control)
- ACL rules for inbound and outbound traffic

## Troubleshooting

1. SSH Connection Issues:
   - Verify network connectivity
   - Check credentials in CSV file
   - Ensure SSH is enabled on target devices

2. Command Execution Failures:
   - Verify user privileges on network devices
   - Check command syntax compatibility

3. Report Generation Issues:
   - Ensure write permissions in script directory
   - Check JSON file format if using custom template

## Contributing

Feel free to submit issues and enhancement requests. Follow these steps:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This script is released under the MIT License. See the LICENSE file for details.
