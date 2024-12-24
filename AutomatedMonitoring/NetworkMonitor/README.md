4# Network Monitoring System

A comprehensive network monitoring solution that provides real-time monitoring, alerting, and reporting for network devices and services.

## Features

- **Device Monitoring**
  - Automatic device discovery
  - Multi-vendor support (Cisco, Juniper, HP/Aruba, etc.)
  - Layer 2 and Layer 3 topology mapping
  - Hardware health monitoring

- **Network Services Monitoring**
  - DNS health and response times
  - DHCP lease status
  - Active Directory replication
  - Load balancer status

- **Performance Monitoring**
  - Bandwidth utilization
  - Packet loss rates
  - Latency measurements
  - QoS metrics
  - Interface errors and discards

- **Security Monitoring**
  - Unusual traffic patterns
  - Port security violations
  - ACL violations
  - Authentication failures

- **Smart Alerting**
  - Multi-tier alerting (Critical, Warning, Info)
  - Alert correlation and deduplication
  - Business impact assessment
  - Rich context in notifications
  - Customizable escalation paths

- **Reporting**
  - Daily health summaries
  - Weekly trend analysis
  - Monthly capacity planning
  - Custom report generation

## Prerequisites

- Python 3.8 or higher
- Network access to monitored devices
- SNMP access configured on network devices
- SSH access for configuration verification
- Required Python packages:
  ```
  networkx>=2.5
  requests>=2.25.1
  jinja2>=2.11.3
  pysnmp>=4.4.12
  scapy>=2.4.4
  dnspython>=2.1.0
  python-ldap>=3.3.1
  ```

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/network-monitor.git
   cd network-monitor
   ```

2. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   # or
   .\venv\Scripts\activate  # Windows
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Create configuration file:
   ```bash
   cp config/config.example.json config/config.json
   ```

5. Update configuration with your environment details:
   - Network ranges for device discovery
   - Device credentials
   - SMTP settings for email alerts
   - Slack webhook URL for Slack notifications
   - Business service definitions

## Configuration

### Basic Configuration

1. Set up device discovery:
   ```json
   {
     "devices": {
       "enable_discovery": true,
       "discovery_networks": [
         "192.168.1.0/24",
         "10.0.0.0/24"
       ]
     }
   }
   ```

2. Configure credentials:
   ```json
   {
     "devices": {
       "credentials": {
         "cisco_devices": {
           "username": "admin",
           "password": "{{ CISCO_PASSWORD }}",
           "enable_password": "{{ CISCO_ENABLE }}"
         }
       }
     }
   }
   ```

3. Set up notifications:
   ```json
   {
     "alerting": {
       "notifications": {
         "slack_enabled": true,
         "slack_webhook_url": "{{ SLACK_WEBHOOK_URL }}",
         "email_enabled": true,
         "smtp": {
           "server": "smtp.company.com",
           "port": 587
         }
       }
     }
   }
   ```

### Advanced Configuration

1. Custom monitoring thresholds:
   ```json
   {
     "metrics": {
       "thresholds": {
         "network_performance": {
           "bandwidth_utilization": {
             "warning": 70,
             "critical": 85
           }
         }
       }
     }
   }
   ```

2. Business service definitions:
   ```json
   {
     "alerting": {
       "business_services": [
         {
           "name": "Core Network",
           "priority": 1,
           "dependencies": ["192.168.1.1"]
         }
       ]
     }
   }
   ```

## Usage

### Starting the Monitor

1. Basic monitoring:
   ```bash
   python network_monitor.py
   ```

2. With debug logging:
   ```bash
   python network_monitor.py --debug
   ```

3. With custom config:
   ```bash
   python network_monitor.py --config /path/to/config.json
   ```

### Common Operations

1. Force topology refresh:
   ```bash
   python network_monitor.py --refresh-topology
   ```

2. Generate reports:
   ```bash
   python network_monitor.py --generate-report daily
   python network_monitor.py --generate-report weekly
   ```

3. Test notifications:
   ```bash
   python network_monitor.py --test-notifications
   ```

## Alert Levels

1. **Critical Alerts**
   - Immediate action required
   - Service-affecting issues
   - Security incidents
   - Hardware failures

2. **Warning Alerts**
   - Performance degradation
   - Capacity thresholds
   - Configuration issues
   - Trending towards critical

3. **Info Alerts**
   - System changes
   - Performance statistics
   - Routine events
   - Baseline updates

## Troubleshooting

### Common Issues

1. **Device Discovery Failures**
   - Verify network connectivity
   - Check SNMP credentials
   - Confirm firewall rules
   - Validate IP ranges

2. **Alert Notification Issues**
   - Verify SMTP settings
   - Check Slack webhook URL
   - Confirm recipient addresses
   - Review notification logs

3. **Performance Issues**
   - Adjust polling intervals
   - Optimize SNMP queries
   - Review batch sizes
   - Check resource usage

### Logging

Logs are stored in the `logs` directory:
- `network_monitor.log`: Main application log
- `alert_manager.log`: Alert processing log
- `device_discovery.log`: Device discovery log
- `metrics_collection.log`: Metrics collection log

### Debug Mode

Enable debug logging for detailed information:
```bash
python network_monitor.py --debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support:
- Open an issue on GitHub
- Contact: support@company.com
- Documentation: https://docs.company.com/network-monitor
