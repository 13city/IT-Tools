#!/usr/bin/env python3

import logging
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import time
from enum import Enum
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import json
import requests
from jinja2 import Template

logger = logging.getLogger('NetworkMonitor.AlertManager')

class AlertSeverity(Enum):
    CRITICAL = "critical"
    WARNING = "warning"
    INFO = "info"

class AlertStatus(Enum):
    NEW = "new"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    ESCALATED = "escalated"

@dataclass
class BusinessService:
    name: str
    description: str
    priority: int
    dependencies: List[str]
    contacts: List[str]

@dataclass
class Alert:
    id: str
    severity: AlertSeverity
    status: AlertStatus
    device_ip: str
    device_name: str
    metric_name: str
    metric_value: Any
    threshold: float
    timestamp: float
    description: str
    affected_services: List[BusinessService] = None
    correlation_id: Optional[str] = None
    previous_occurrences: List[float] = None
    resolution_steps: List[str] = None
    escalation_path: List[str] = None

class AlertManager:
    def __init__(self, config: Dict[str, Any]):
        """Initialize the Alert Manager."""
        self.config = config
        self.active_alerts: Dict[str, Alert] = {}
        self.alert_history: List[Alert] = []
        self.business_services = self._load_business_services()
        self.notification_config = config.get('notifications', {})
        self.templates = self._load_alert_templates()
        self.correlation_window = config.get('correlation_window', 3600)  # 1 hour default

    def _load_business_services(self) -> Dict[str, BusinessService]:
        """Load business service definitions."""
        services = {}
        for service_config in self.config.get('business_services', []):
            service = BusinessService(
                name=service_config['name'],
                description=service_config['description'],
                priority=service_config['priority'],
                dependencies=service_config.get('dependencies', []),
                contacts=service_config.get('contacts', [])
            )
            services[service.name] = service
        return services

    def _load_alert_templates(self) -> Dict[str, Template]:
        """Load Jinja2 templates for alert notifications."""
        templates = {}
        template_dir = self.config.get('template_dir', 'templates')
        
        # Load email templates
        with open(f"{template_dir}/email_critical.j2") as f:
            templates['email_critical'] = Template(f.read())
        with open(f"{template_dir}/email_warning.j2") as f:
            templates['email_warning'] = Template(f.read())
        with open(f"{template_dir}/email_info.j2") as f:
            templates['email_info'] = Template(f.read())
            
        # Load Slack templates
        with open(f"{template_dir}/slack_critical.j2") as f:
            templates['slack_critical'] = Template(f.read())
        with open(f"{template_dir}/slack_warning.j2") as f:
            templates['slack_warning'] = Template(f.read())
        with open(f"{template_dir}/slack_info.j2") as f:
            templates['slack_info'] = Template(f.read())
            
        return templates

    def process_metrics(self, device: 'Device', metrics: List['Metric']) -> List[Alert]:
        """Process metrics and generate alerts based on thresholds."""
        alerts = []
        for metric in metrics:
            if self._should_alert(metric):
                alert = self._create_alert(device, metric)
                if alert:
                    alerts.append(alert)
        return alerts

    def _should_alert(self, metric: 'Metric') -> bool:
        """Determine if a metric should trigger an alert."""
        if metric.threshold_critical is not None and metric.value >= metric.threshold_critical:
            return True
        if metric.threshold_warning is not None and metric.value >= metric.threshold_warning:
            return True
        return False

    def _create_alert(self, device: 'Device', metric: 'Metric') -> Optional[Alert]:
        """Create an alert from a metric."""
        try:
            # Determine severity
            severity = self._determine_severity(metric)
            
            # Generate alert ID
            alert_id = f"{device.ip}_{metric.name}_{int(time.time())}"
            
            # Check for correlation with existing alerts
            correlation_id = self._check_correlation(device.ip, metric.name)
            
            # Create alert object
            alert = Alert(
                id=alert_id,
                severity=severity,
                status=AlertStatus.NEW,
                device_ip=device.ip,
                device_name=device.hostname,
                metric_name=metric.name,
                metric_value=metric.value,
                threshold=metric.threshold_critical or metric.threshold_warning,
                timestamp=time.time(),
                description=self._generate_alert_description(device, metric),
                affected_services=self._determine_affected_services(device, metric),
                correlation_id=correlation_id,
                resolution_steps=self._get_resolution_steps(device, metric),
                escalation_path=self._get_escalation_path(severity)
            )
            
            # Store alert
            self.active_alerts[alert.id] = alert
            self.alert_history.append(alert)
            
            return alert
            
        except Exception as e:
            logger.error(f"Error creating alert: {e}")
            return None

    def _determine_severity(self, metric: 'Metric') -> AlertSeverity:
        """Determine alert severity based on metric values and thresholds."""
        if metric.threshold_critical is not None and metric.value >= metric.threshold_critical:
            return AlertSeverity.CRITICAL
        if metric.threshold_warning is not None and metric.value >= metric.threshold_warning:
            return AlertSeverity.WARNING
        return AlertSeverity.INFO

    def _check_correlation(self, device_ip: str, metric_name: str) -> Optional[str]:
        """Check for correlation with existing alerts."""
        current_time = time.time()
        for alert in self.active_alerts.values():
            if (alert.device_ip == device_ip and 
                alert.metric_name == metric_name and 
                current_time - alert.timestamp < self.correlation_window):
                return alert.correlation_id or alert.id
        return None

    def _determine_affected_services(self, device: 'Device', 
                                   metric: 'Metric') -> List[BusinessService]:
        """Determine which business services are affected by this alert."""
        affected_services = []
        for service in self.business_services.values():
            if device.ip in service.dependencies:
                affected_services.append(service)
        return affected_services

    def _generate_alert_description(self, device: 'Device', 
                                  metric: 'Metric') -> str:
        """Generate a detailed description of the alert."""
        return (f"Alert: {metric.name} on {device.hostname} ({device.ip}) "
                f"exceeded threshold. Current value: {metric.value}{metric.unit}")

    def _get_resolution_steps(self, device: 'Device', 
                            metric: 'Metric') -> List[str]:
        """Get resolution steps based on the type of alert."""
        # Load resolution steps from configuration based on metric type
        resolution_config = self.config.get('resolution_steps', {})
        return resolution_config.get(f"{device.device_type}_{metric.name}", [
            "1. Verify alert conditions",
            "2. Check device status",
            "3. Review logs",
            "4. Contact system administrator if issue persists"
        ])

    def _get_escalation_path(self, severity: AlertSeverity) -> List[str]:
        """Get escalation path based on severity."""
        escalation_config = self.config.get('escalation_paths', {})
        return escalation_config.get(severity.value, [
            "Level 1 Support",
            "Level 2 Support",
            "System Administrator",
            "IT Manager"
        ])

    def send_notifications(self, alerts: List[Alert]):
        """Send notifications for alerts via configured channels."""
        for alert in alerts:
            try:
                # Send Slack notification
                if self.notification_config.get('slack_enabled', False):
                    self._send_slack_notification(alert)
                
                # Send email notification
                if self.notification_config.get('email_enabled', False):
                    self._send_email_notification(alert)
                
            except Exception as e:
                logger.error(f"Error sending notifications for alert {alert.id}: {e}")

    def _send_slack_notification(self, alert: Alert):
        """Send notification to Slack."""
        try:
            webhook_url = self.notification_config['slack_webhook_url']
            template_name = f"slack_{alert.severity.value}"
            
            # Render the Slack message using template
            message = self.templates[template_name].render(
                alert=alert,
                business_services=self.business_services
            )
            
            # Send to Slack
            response = requests.post(
                webhook_url,
                json={"text": message},
                headers={"Content-Type": "application/json"}
            )
            response.raise_for_status()
            
        except Exception as e:
            logger.error(f"Error sending Slack notification: {e}")

    def _send_email_notification(self, alert: Alert):
        """Send notification via email."""
        try:
            smtp_config = self.notification_config['smtp']
            template_name = f"email_{alert.severity.value}"
            
            # Render the email content using template
            content = self.templates[template_name].render(
                alert=alert,
                business_services=self.business_services
            )
            
            # Create email message
            msg = MIMEMultipart()
            msg['Subject'] = f"Network Alert: {alert.severity.value.upper()} - {alert.metric_name}"
            msg['From'] = smtp_config['from_address']
            msg['To'] = ", ".join(self._get_notification_recipients(alert))
            msg.attach(MIMEText(content, 'html'))
            
            # Send email
            with smtplib.SMTP(smtp_config['server'], smtp_config['port']) as server:
                if smtp_config.get('use_tls', True):
                    server.starttls()
                if smtp_config.get('username'):
                    server.login(smtp_config['username'], smtp_config['password'])
                server.send_message(msg)
                
        except Exception as e:
            logger.error(f"Error sending email notification: {e}")

    def _get_notification_recipients(self, alert: Alert) -> List[str]:
        """Get list of notification recipients based on alert and affected services."""
        recipients = set()
        
        # Add service-specific contacts
        if alert.affected_services:
            for service in alert.affected_services:
                recipients.update(service.contacts)
        
        # Add severity-specific contacts
        severity_contacts = self.notification_config.get('severity_contacts', {})
        recipients.update(severity_contacts.get(alert.severity.value, []))
        
        return list(recipients)

    def acknowledge_alert(self, alert_id: str, user: str):
        """Acknowledge an alert."""
        if alert_id in self.active_alerts:
            self.active_alerts[alert_id].status = AlertStatus.ACKNOWLEDGED

    def resolve_alert(self, alert_id: str, resolution_notes: str):
        """Resolve an alert."""
        if alert_id in self.active_alerts:
            self.active_alerts[alert_id].status = AlertStatus.RESOLVED
            # Archive the alert
            self.alert_history.append(self.active_alerts[alert_id])
            del self.active_alerts[alert_id]

    def get_active_alerts(self) -> List[Alert]:
        """Get list of active alerts."""
        return list(self.active_alerts.values())

    def get_alert_history(self, start_time: float, end_time: float) -> List[Alert]:
        """Get historical alerts within the specified time range."""
        return [
            alert for alert in self.alert_history
            if start_time <= alert.timestamp <= end_time
        ]
