#!/usr/bin/env python3

import logging
from typing import Dict, List, Any
import ipaddress
import socket
from concurrent.futures import ThreadPoolExecutor
import time
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger('NetworkMonitor.DeviceManager')

class DeviceType(Enum):
    ROUTER = "router"
    SWITCH = "switch"
    FIREWALL = "firewall"
    SERVER = "server"
    ACCESS_POINT = "access_point"
    LOAD_BALANCER = "load_balancer"
    OTHER = "other"

@dataclass
class DeviceCredentials:
    username: str
    password: str
    enable_password: str = None
    snmp_community: str = None
    snmp_version: str = "v2c"
    ssh_key_file: str = None

@dataclass
class Device:
    ip: str
    hostname: str
    device_type: DeviceType
    vendor: str
    model: str = None
    os_version: str = None
    credentials: DeviceCredentials = None
    last_seen: float = None
    status: str = "unknown"
    interfaces: Dict[str, Dict] = None
    location: str = None
    
class DeviceManager:
    def __init__(self, config: Dict[str, Any]):
        """Initialize the Device Manager."""
        self.config = config
        self.devices: Dict[str, Device] = {}
        self.credentials = self._process_credentials(config.get('credentials', {}))
        self.discovery_interval = config.get('discovery_interval', 3600)  # 1 hour default
        self.last_discovery = 0
        self._discover_devices()

    def _process_credentials(self, cred_config: Dict) -> Dict[str, DeviceCredentials]:
        """Process and validate credential configurations."""
        processed_creds = {}
        for cred_name, cred_data in cred_config.items():
            try:
                processed_creds[cred_name] = DeviceCredentials(
                    username=cred_data.get('username'),
                    password=cred_data.get('password'),
                    enable_password=cred_data.get('enable_password'),
                    snmp_community=cred_data.get('snmp_community'),
                    snmp_version=cred_data.get('snmp_version', 'v2c'),
                    ssh_key_file=cred_data.get('ssh_key_file')
                )
            except Exception as e:
                logger.error(f"Error processing credentials {cred_name}: {e}")
        return processed_creds

    def _discover_devices(self):
        """Discover network devices based on configuration."""
        try:
            # Process static device list
            static_devices = self.config.get('static_devices', [])
            for device_config in static_devices:
                self._add_static_device(device_config)

            # Perform network discovery if enabled
            if self.config.get('enable_discovery', False):
                self._auto_discover_devices()

            logger.info(f"Discovered {len(self.devices)} devices")
            self.last_discovery = time.time()
        except Exception as e:
            logger.error(f"Error during device discovery: {e}")

    def _add_static_device(self, device_config: Dict):
        """Add a statically configured device."""
        try:
            device = Device(
                ip=device_config['ip'],
                hostname=device_config.get('hostname', device_config['ip']),
                device_type=DeviceType(device_config.get('type', 'other')),
                vendor=device_config.get('vendor', 'unknown'),
                model=device_config.get('model'),
                credentials=self.credentials.get(device_config.get('credentials_group', 'default')),
                location=device_config.get('location')
            )
            self.devices[device.ip] = device
        except Exception as e:
            logger.error(f"Error adding static device {device_config.get('ip')}: {e}")

    def _auto_discover_devices(self):
        """Automatically discover devices in the network."""
        networks = self.config.get('discovery_networks', [])
        
        with ThreadPoolExecutor(max_workers=10) as executor:
            for network in networks:
                try:
                    network_obj = ipaddress.ip_network(network)
                    futures = [
                        executor.submit(self._probe_device, str(ip))
                        for ip in network_obj.hosts()
                    ]
                    for future in futures:
                        try:
                            result = future.result(timeout=2)
                            if result:
                                self._process_discovered_device(result)
                        except Exception as e:
                            logger.debug(f"Error processing discovery result: {e}")
                except Exception as e:
                    logger.error(f"Error discovering network {network}: {e}")

    def _probe_device(self, ip: str) -> Dict[str, Any]:
        """Probe a single IP address for device discovery."""
        try:
            # Try basic TCP port scan first
            common_ports = [22, 23, 80, 443, 161]  # SSH, Telnet, HTTP, HTTPS, SNMP
            for port in common_ports:
                try:
                    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                        s.settimeout(1)
                        if s.connect_ex((ip, port)) == 0:
                            # Device responds to at least one port
                            hostname = self._get_hostname(ip)
                            device_info = self._get_device_info(ip)
                            return {
                                'ip': ip,
                                'hostname': hostname,
                                'open_ports': port,
                                **device_info
                            }
                except Exception:
                    continue
        except Exception as e:
            logger.debug(f"Error probing device {ip}: {e}")
        return None

    def _get_hostname(self, ip: str) -> str:
        """Attempt to resolve hostname for an IP."""
        try:
            return socket.gethostbyaddr(ip)[0]
        except Exception:
            return ip

    def _get_device_info(self, ip: str) -> Dict[str, Any]:
        """Attempt to gather device information using SNMP."""
        # This would typically use SNMP to gather device information
        # For now, return placeholder data
        return {
            'vendor': 'unknown',
            'model': 'unknown',
            'type': DeviceType.OTHER
        }

    def _process_discovered_device(self, device_info: Dict[str, Any]):
        """Process and add a discovered device."""
        if device_info['ip'] not in self.devices:
            try:
                device = Device(
                    ip=device_info['ip'],
                    hostname=device_info['hostname'],
                    device_type=device_info.get('type', DeviceType.OTHER),
                    vendor=device_info.get('vendor', 'unknown'),
                    model=device_info.get('model', 'unknown'),
                    credentials=self.credentials.get('default'),
                    last_seen=time.time(),
                    status='up'
                )
                self.devices[device.ip] = device
                logger.info(f"Added discovered device: {device.ip} ({device.hostname})")
            except Exception as e:
                logger.error(f"Error processing discovered device {device_info['ip']}: {e}")

    def get_devices(self) -> List[Device]:
        """Get list of all managed devices."""
        # Check if we need to run discovery again
        if time.time() - self.last_discovery > self.discovery_interval:
            self._discover_devices()
        return list(self.devices.values())

    def get_device(self, ip: str) -> Device:
        """Get a specific device by IP."""
        return self.devices.get(ip)

    def update_device_status(self, ip: str, status: str):
        """Update the status of a device."""
        if ip in self.devices:
            self.devices[ip].status = status
            self.devices[ip].last_seen = time.time()

    def get_devices_by_type(self, device_type: DeviceType) -> List[Device]:
        """Get all devices of a specific type."""
        return [d for d in self.devices.values() if d.device_type == device_type]

    def get_devices_by_vendor(self, vendor: str) -> List[Device]:
        """Get all devices from a specific vendor."""
        return [d for d in self.devices.values() if d.vendor.lower() == vendor.lower()]
