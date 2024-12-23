# Hyper-V Migration and Replication Manager

This PowerShell script provides comprehensive functionality for managing VM migrations and replication between Hyper-V hosts. It supports both live migration and replication scenarios with detailed logging and status monitoring.

## Features

- Live VM migration between Hyper-V hosts
- VM replication setup and monitoring
- Pre-migration validation checks
- Storage space verification
- Detailed logging of all operations
- Support for batch operations on multiple VMs
- Real-time replication status monitoring

## Prerequisites

- Windows Server with Hyper-V role installed
- PowerShell 5.1 or higher
- Administrative privileges on both source and destination hosts
- Network connectivity between hosts
- Proper DNS resolution between hosts
- Kerberos authentication configured

## Parameters

- `SourceHost`: Source Hyper-V host (default: local computer)
- `DestinationHost`: Target Hyper-V host for migration/replication
- `VMNames`: Array of VM names to process (optional)
- `LogPath`: Path for operation logs (default: Desktop)
- `EnableReplication`: Switch to enable replication instead of migration
- `ReplicationFrequencySeconds`: Replication frequency in seconds (default: 300)

## Usage Examples

```powershell
# Perform live migration of specific VMs
.\HyperV-MigrationManager.ps1 -SourceHost "HV-Source" -DestinationHost "HV-Dest" -VMNames "VM1","VM2"

# Enable replication for all VMs
.\HyperV-MigrationManager.ps1 -SourceHost "HV-Source" -DestinationHost "HV-Dest" -EnableReplication

# Custom replication frequency
.\HyperV-MigrationManager.ps1 -SourceHost "HV-Source" -DestinationHost "HV-Dest" -EnableReplication -ReplicationFrequencySeconds 600
```

## Functions

### Test-HyperVHost
- Validates Hyper-V host configuration
- Checks for Hyper-V role installation
- Verifies remote PowerShell connectivity

### Get-VMDetails
- Retrieves VM information from specified host
- Supports filtering by VM names
- Handles both single and multiple VM scenarios

### Test-StorageSpace
- Verifies available storage on destination
- Ensures sufficient space for VM migration
- Prevents failed migrations due to space issues

### Enable-VMReplication
- Configures VM replication between hosts
- Sets up authentication and compression
- Initiates initial replication process

### Get-ReplicationStatus
- Monitors replication progress
- Provides detailed status information
- Tracks replication health and performance

### Start-LiveMigration
- Performs live migration of running VMs
- Includes storage migration
- Maintains VM state during migration

### Write-MigrationLog
- Maintains detailed operation logs
- Timestamps all entries
- Provides both console and file output

## Error Handling

The script includes comprehensive error handling:
- Pre-validation of all requirements
- Detailed error messages
- Operation logging
- Graceful failure handling
- Status monitoring and reporting

## Best Practices

1. **Pre-Migration**
   - Verify network connectivity
   - Check available storage space
   - Ensure VM health status
   - Validate permissions

2. **During Migration**
   - Monitor network bandwidth
   - Check event logs
   - Monitor VM performance
   - Verify replication status

3. **Post-Migration**
   - Validate VM functionality
   - Check network connectivity
   - Verify application operation
   - Review migration logs

## Troubleshooting

Common issues and solutions:

1. **Authentication Failures**
   - Verify Kerberos configuration
   - Check domain trust relationships
   - Ensure proper DNS resolution
   - Validate service accounts

2. **Network Issues**
   - Check firewall rules
   - Verify network bandwidth
   - Test host connectivity
   - Validate DNS settings

3. **Storage Problems**
   - Verify available space
   - Check storage permissions
   - Validate storage paths
   - Monitor disk performance

## Logging

The script generates detailed logs including:
- Operation timestamps
- Success/failure status
- Error messages
- Performance metrics
- Replication status

## Security Considerations

- Uses Kerberos authentication
- Requires administrative privileges
- Supports secure communication
- Logs security-related events

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit pull request with:
   - Clear description
   - Test results
   - Documentation updates

## License

This script is released under the MIT License.

## Version History

- 1.0.0 (2024-01-20)
  - Initial release
  - Basic migration and replication support
  - Logging and monitoring features

## Acknowledgments

- Microsoft Hyper-V Team
- PowerShell Community
- Contributors and testers
