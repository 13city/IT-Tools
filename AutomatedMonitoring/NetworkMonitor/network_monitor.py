#!/usr/bin/env python3
"""
Network Monitoring System
Author: 13city

A comprehensive network monitoring system that tracks device health,
performance metrics, and security events.
"""

import os
import sys
import json
import time
import logging
import argparse
from datetime import datetime
from typing import Dict, List, Any

# Initialize logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/network_monitor.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger('NetworkMonitor')

class NetworkMonitor:
    def __init__(self, config_path: str = 'config/config.json'):
        """Initialize the Network Monitor with configuration."""
        self.config = self._load_config(config_path)
        self.alert_manager = None
        self.device_manager = None
        self.metrics_manager = None
        self.topology_manager = None
        self._initialize_components()

    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from JSON file."""
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load configuration: {e}")
            sys.exit(1)

    def _initialize_components(self):
        """Initialize all monitoring components."""
        # Import components dynamically to avoid circular imports
        from modules.alert_manager import AlertManager
        from modules.device_manager import DeviceManager
        from modules.metrics_manager import MetricsManager
        from modules.topology_manager import TopologyManager

        try:
            self.alert_manager = AlertManager(self.config['alerting'])
            self.device_manager = DeviceManager(self.config['devices'])
            self.metrics_manager = MetricsManager(self.config['metrics'])
            self.topology_manager = TopologyManager(self.config['topology'])
        except Exception as e:
            logger.error(f"Failed to initialize components: {e}")
            sys.exit(1)

    def start_monitoring(self):
        """Start the main monitoring loop."""
        logger.info("Starting network monitoring...")
        
        while True:
            try:
                # Update network topology
                topology = self.topology_manager.update_topology()

                # Monitor all devices
                for device in self.device_manager.get_devices():
                    # Collect metrics
                    metrics = self.metrics_manager.collect_metrics(device)
                    
                    # Process security events
                    security_events = self.metrics_manager.check_security(device)
                    
                    # Check thresholds and generate alerts
                    alerts = self.alert_manager.process_metrics(device, metrics)
                    
                    # Process security alerts
                    security_alerts = self.alert_manager.process_security_events(security_events)
                    
                    # Send notifications if needed
                    if alerts or security_alerts:
                        self.alert_manager.send_notifications(alerts + security_alerts)

                # Generate periodic reports
                self._generate_reports()
                
                # Sleep for the configured interval
                time.sleep(self.config.get('polling_interval', 300))  # Default 5 minutes

            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                time.sleep(60)  # Wait before retrying

    def _generate_reports(self):
        """Generate periodic reports."""
        try:
            current_time = datetime.now()
            
            # Generate reports based on configured schedules
            if self._should_generate_daily_report(current_time):
                self.metrics_manager.generate_daily_report()
            
            if self._should_generate_weekly_report(current_time):
                self.metrics_manager.generate_weekly_report()
            
            if self._should_generate_monthly_report(current_time):
                self.metrics_manager.generate_monthly_report()
                
        except Exception as e:
            logger.error(f"Error generating reports: {e}")

    def _should_generate_daily_report(self, current_time: datetime) -> bool:
        """Check if daily report should be generated."""
        return current_time.hour == 0 and current_time.minute < 5

    def _should_generate_weekly_report(self, current_time: datetime) -> bool:
        """Check if weekly report should be generated."""
        return current_time.weekday() == 0 and current_time.hour == 1 and current_time.minute < 5

    def _should_generate_monthly_report(self, current_time: datetime) -> bool:
        """Check if monthly report should be generated."""
        return current_time.day == 1 and current_time.hour == 2 and current_time.minute < 5

def main():
    """Main entry point for the network monitoring system."""
    parser = argparse.ArgumentParser(description='Network Monitoring System')
    parser.add_argument('--config', default='config/config.json',
                      help='Path to configuration file')
    parser.add_argument('--debug', action='store_true',
                      help='Enable debug logging')
    args = parser.parse_args()

    if args.debug:
        logger.setLevel(logging.DEBUG)

    monitor = NetworkMonitor(args.config)
    monitor.start_monitoring()

if __name__ == '__main__':
    main()
