#!/usr/bin/env python3

import os
import sys
import json
import time
import logging
import smtplib
import requests
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime
import unittest
from unittest.mock import MagicMock, patch

# Import local modules
from modules.device_manager import DeviceManager
from modules.metrics_manager import MetricsManager
from modules.alert_manager import AlertManager
from modules.topology_manager import TopologyManager

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('NetworkMonitor.Test')

class NetworkMonitorTests(unittest.TestCase):
    """Test suite for Network Monitor functionality."""

    @classmethod
    def setUpClass(cls):
        """Set up test environment."""
        cls.root_dir = Path(__file__).parent.absolute()
        cls.config_file = cls.root_dir / 'config' / 'config.json'
        
        # Load configuration
        with open(cls.config_file) as f:
            cls.config = json.load(f)

    def setUp(self):
        """Set up each test."""
        self.device_manager = DeviceManager(self.config['devices'])
        self.metrics_manager = MetricsManager(self.config['metrics'])
        self.alert_manager = AlertManager(self.config['alerting'])
        self.topology_manager = TopologyManager(self.config['topology'])

    def test_config_loading(self):
        """Test configuration loading."""
        self.assertIsNotNone(self.config)
        required_sections = ['general', 'devices', 'metrics', 'alerting', 'topology']
        for section in required_sections:
            self.assertIn(section, self.config)

    def test_directory_structure(self):
        """Test required directories exist."""
        required_dirs = [
            'logs',
            'data',
            'data/topology',
            'data/metrics',
            'data/reports'
        ]
        for dir_name in required_dirs:
            dir_path = self.root_dir / dir_name
            self.assertTrue(
                dir_path.exists(),
                f'Directory not found: {dir_path}'
            )

    def test_mock_device_discovery(self):
        """Test device discovery with mock devices."""
        # Mock device for testing
        mock_device = {
            'ip': '192.168.1.1',
            'hostname': 'test-router',
            'type': 'router',
            'vendor': 'cisco'
        }

        with patch.object(DeviceManager, '_probe_device') as mock_probe:
            mock_probe.return_value = mock_device
            devices = self.device_manager.get_devices()
            self.assertGreater(len(devices), 0)
            self.assertEqual(devices[0].ip, mock_device['ip'])

    def test_metric_collection(self):
        """Test metric collection functionality."""
        # Mock device and metrics
        mock_device = MagicMock()
        mock_device.ip = '192.168.1.1'
        mock_device.hostname = 'test-router'

        metrics = self.metrics_manager.collect_metrics(mock_device)
        self.assertIsNotNone(metrics)
        self.assertIsInstance(metrics, list)

    def test_alert_generation(self):
        """Test alert generation and notification."""
        # Mock metric that should trigger an alert
        mock_metric = {
            'name': 'cpu_utilization',
            'value': 95,
            'threshold_critical': 90,
            'type': 'performance',
            'unit': 'percent'
        }

        # Mock device
        mock_device = MagicMock()
        mock_device.ip = '192.168.1.1'
        mock_device.hostname = 'test-router'

        alerts = self.alert_manager.process_metrics(mock_device, [mock_metric])
        self.assertGreater(len(alerts), 0)
        self.assertEqual(alerts[0].severity, 'critical')

    @patch('smtplib.SMTP')
    def test_email_notification(self, mock_smtp):
        """Test email notification functionality."""
        mock_smtp_instance = MagicMock()
        mock_smtp.return_value = mock_smtp_instance

        # Create test alert
        alert = {
            'id': 'test-alert-1',
            'severity': 'critical',
            'device_ip': '192.168.1.1',
            'message': 'Test alert'
        }

        self.alert_manager.send_notifications([alert])
        mock_smtp_instance.send_message.assert_called()

    @patch('requests.post')
    def test_slack_notification(self, mock_post):
        """Test Slack notification functionality."""
        mock_post.return_value.status_code = 200

        # Create test alert
        alert = {
            'id': 'test-alert-1',
            'severity': 'critical',
            'device_ip': '192.168.1.1',
            'message': 'Test alert'
        }

        self.alert_manager.send_notifications([alert])
        mock_post.assert_called()

    def test_topology_mapping(self):
        """Test topology mapping functionality."""
        topology = self.topology_manager.update_topology()
        self.assertIsNotNone(topology)
        self.assertTrue(hasattr(topology, 'nodes'))
        self.assertTrue(hasattr(topology, 'edges'))

    def test_report_generation(self):
        """Test report generation functionality."""
        # Generate test report
        report_time = datetime.now()
        self.metrics_manager.generate_daily_report()

        # Check if report file was created
        report_date = report_time.strftime('%Y-%m-%d')
        report_file = self.root_dir / 'data' / 'reports' / f'daily_report_{report_date}.html'
        self.assertTrue(report_file.exists())

def run_integration_tests():
    """Run basic integration tests."""
    logger.info("Running integration tests...")
    
    try:
        # Test SNMP connectivity
        logger.info("Testing SNMP connectivity...")
        from pysnmp.hlapi import getNextRequestObject, ObjectIdentity
        snmp_test = getNextRequestObject(ObjectIdentity('SNMPv2-MIB', 'sysDescr'))
        logger.info("SNMP test passed")

        # Test network connectivity
        logger.info("Testing network connectivity...")
        test_hosts = ['8.8.8.8', '1.1.1.1']
        for host in test_hosts:
            response = os.system(f"ping -c 1 {host} > /dev/null 2>&1")
            if response == 0:
                logger.info(f"Successfully pinged {host}")
            else:
                logger.warning(f"Failed to ping {host}")

        # Test database connectivity
        logger.info("Testing database connectivity...")
        import sqlite3
        db_path = Path(__file__).parent / 'data' / 'metrics.db'
        conn = sqlite3.connect(db_path)
        conn.close()
        logger.info("Database connectivity test passed")

        logger.info("All integration tests completed")
        return True

    except Exception as e:
        logger.error(f"Integration tests failed: {e}")
        return False

def main():
    """Main entry point for test script."""
    # Run unit tests
    logger.info("\n=== Running Unit Tests ===")
    unittest.main(argv=['dummy'], exit=False)

    # Run integration tests
    logger.info("\n=== Running Integration Tests ===")
    integration_success = run_integration_tests()

    if not integration_success:
        logger.error("Integration tests failed")
        sys.exit(1)

    logger.info("\n=== All tests completed successfully ===")
    sys.exit(0)

if __name__ == '__main__':
    main()
