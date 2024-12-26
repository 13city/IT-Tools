# Automated Monitoring Solutions

Enterprise-grade monitoring solutions for Microsoft 365 and network infrastructure.

## 📊 Components

### [M365Monitor](M365Monitor/)
Advanced Microsoft 365 monitoring solution providing comprehensive service health tracking and alerting.

#### Features
- Exchange Online monitoring
- SharePoint Online monitoring
- Teams service monitoring
- License usage tracking
- Security alerts
- Performance metrics

#### Structure
```
M365Monitor/
├── README.md
├── config/
│   └── config.json         # Configuration settings
├── docs/                   # Documentation
├── lib/                    # Shared libraries
├── src/
│   ├── Monitor-M365.ps1   # Main monitoring script
│   ├── core/              # Core functionality
│   └── monitors/          # Individual service monitors
└── tests/                 # Test suites
```

### [NetworkMonitor](NetworkMonitor/)
Enterprise network monitoring system with real-time metrics collection and alerting.

#### Features
- Real-time metrics collection
- Network topology mapping
- Alert management
- Multi-platform notifications
- Performance tracking
- Device management

#### Structure
```
NetworkMonitor/
├── README.md
├── config/
│   └── config.json        # Configuration settings
├── docs/                  # Documentation
├── logs/                  # Log files
├── modules/
│   ├── alert_manager.py   # Alert handling
│   ├── device_manager.py  # Device management
│   ├── metrics_manager.py # Metrics collection
│   └── topology_manager.py # Network mapping
├── templates/             # Notification templates
│   ├── email_*.j2
│   └── slack_*.j2
├── network_monitor.py     # Main monitoring script
├── requirements.txt       # Python dependencies
└── setup.py              # Installation script
```

## 🚀 Quick Start

### M365 Monitoring
1. Configure settings in `M365Monitor/config/config.json`
2. Set up required Microsoft 365 permissions
3. Run `Monitor-M365.ps1` to start monitoring

### Network Monitoring
1. Install dependencies: `pip install -r requirements.txt`
2. Configure settings in `NetworkMonitor/config/config.json`
3. Run `python network_monitor.py` to start monitoring

## 📋 Prerequisites

### M365Monitor
- PowerShell 5.1 or higher
- Microsoft 365 admin credentials
- Exchange Online PowerShell module
- Microsoft Teams PowerShell module
- SharePoint Online PowerShell module

### NetworkMonitor
- Python 3.8 or higher
- Network access to monitored devices
- SNMP access (if required)
- API credentials for notification services

## 🔧 Configuration

### M365Monitor Configuration
```json
{
  "monitoring": {
    "interval": 300,
    "services": ["Exchange", "SharePoint", "Teams"],
    "alerting": {
      "email": true,
      "teams": true
    }
  }
}
```

### NetworkMonitor Configuration
```json
{
  "monitoring": {
    "interval": 60,
    "devices": ["switches", "routers", "firewalls"],
    "metrics": ["bandwidth", "errors", "latency"],
    "alerts": {
      "email": true,
      "slack": true
    }
  }
}
```

## 📈 Features

### M365 Monitoring
- Service health tracking
- License management
- Security compliance
- Performance metrics
- Custom alert thresholds
- Detailed reporting

### Network Monitoring
- Device discovery
- Performance tracking
- Topology mapping
- Alert management
- Trend analysis
- Capacity planning

## 🔔 Alerting

Both monitoring solutions support multiple notification channels:
- Email notifications
- Teams messages
- Slack integration
- SMS alerts (configurable)
- Custom webhook support

## 📊 Reporting

### M365Monitor Reports
- Service availability
- License utilization
- Security status
- Performance trends
- User activity

### NetworkMonitor Reports
- Network performance
- Device health
- Bandwidth utilization
- Error rates
- Capacity trends

## 🛠️ Troubleshooting

Common issues and solutions are documented in each component's docs directory:
- `M365Monitor/docs/troubleshooting.md`
- `NetworkMonitor/docs/troubleshooting.md`

## 🔒 Security

- Encrypted configuration storage
- Secure credential management
- Role-based access control
- Audit logging
- Compliance reporting

## 📚 Documentation

Detailed documentation is available in the respective docs directories:
- M365Monitor documentation: `M365Monitor/docs/`
- NetworkMonitor documentation: `NetworkMonitor/docs/`
