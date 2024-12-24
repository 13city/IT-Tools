#!/usr/bin/env python3

import os
import sys
import shutil
import subprocess
import platform
import socket
import json
import logging
from pathlib import Path
from typing import List, Dict, Any
import pkg_resources
from dotenv import load_dotenv

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('NetworkMonitor.Setup')

class SetupManager:
    def __init__(self):
        """Initialize the setup manager."""
        self.root_dir = Path(__file__).parent.absolute()
        self.required_dirs = [
            'logs',
            'data',
            'data/topology',
            'data/metrics',
            'data/reports',
            'data/backups',
            'data/exports',
            'data/cache'
        ]
        self.required_python_version = (3, 8)
        self.load_environment()

    def load_environment(self):
        """Load environment variables."""
        env_file = self.root_dir / '.env'
        env_example = self.root_dir / '.env.example'

        if not env_file.exists():
            if env_example.exists():
                logger.warning('.env file not found, creating from .env.example')
                shutil.copy(env_example, env_file)
            else:
                logger.error('.env.example file not found')
                sys.exit(1)

        load_dotenv(env_file)

    def check_python_version(self) -> bool:
        """Check if Python version meets requirements."""
        current_version = sys.version_info[:2]
        if current_version < self.required_python_version:
            logger.error(
                f'Python {self.required_python_version[0]}.{self.required_python_version[1]} '
                f'or higher is required. Current version: {current_version[0]}.{current_version[1]}'
            )
            return False
        logger.info(f'Python version check passed: {sys.version}')
        return True

    def create_directories(self) -> bool:
        """Create required directories if they don't exist."""
        try:
            for dir_name in self.required_dirs:
                dir_path = self.root_dir / dir_name
                dir_path.mkdir(parents=True, exist_ok=True)
                logger.info(f'Created directory: {dir_path}')
            return True
        except Exception as e:
            logger.error(f'Error creating directories: {e}')
            return False

    def check_dependencies(self) -> bool:
        """Check if all required packages are installed."""
        requirements_file = self.root_dir / 'requirements.txt'
        if not requirements_file.exists():
            logger.error('requirements.txt not found')
            return False

        try:
            # Read requirements file
            with open(requirements_file) as f:
                required = [
                    line.strip()
                    for line in f
                    if line.strip() and not line.startswith('#')
                ]

            # Check each requirement
            missing = []
            for req in required:
                try:
                    pkg_resources.require(req)
                except pkg_resources.DistributionNotFound:
                    missing.append(req)

            if missing:
                logger.error(f'Missing dependencies: {", ".join(missing)}')
                logger.info('Install missing dependencies with: pip install -r requirements.txt')
                return False

            logger.info('All dependencies are installed')
            return True

        except Exception as e:
            logger.error(f'Error checking dependencies: {e}')
            return False

    def validate_config(self) -> bool:
        """Validate configuration file."""
        config_file = self.root_dir / 'config' / 'config.json'
        if not config_file.exists():
            logger.error('config.json not found')
            return False

        try:
            with open(config_file) as f:
                config = json.load(f)

            # Validate required sections
            required_sections = [
                'general', 'devices', 'metrics', 'alerting',
                'topology', 'reporting'
            ]
            missing_sections = [
                section for section in required_sections
                if section not in config
            ]

            if missing_sections:
                logger.error(f'Missing config sections: {", ".join(missing_sections)}')
                return False

            logger.info('Configuration validation passed')
            return True

        except json.JSONDecodeError as e:
            logger.error(f'Invalid JSON in config file: {e}')
            return False
        except Exception as e:
            logger.error(f'Error validating config: {e}')
            return False

    def check_network_access(self) -> bool:
        """Check network connectivity to required services."""
        services = [
            ('smtp.company.com', 587),  # SMTP
            ('slack.com', 443),         # Slack
            ('dc.company.com', 389)     # LDAP
        ]

        failed = []
        for host, port in services:
            try:
                socket.create_connection((host, port), timeout=5)
                logger.info(f'Successfully connected to {host}:{port}')
            except Exception as e:
                failed.append(f'{host}:{port} ({str(e)})')

        if failed:
            logger.warning(f'Failed to connect to services: {", ".join(failed)}')
            return False

        logger.info('Network connectivity check passed')
        return True

    def setup_logging(self) -> bool:
        """Set up logging configuration."""
        try:
            log_dir = self.root_dir / 'logs'
            log_dir.mkdir(exist_ok=True)

            # Create log files
            log_files = [
                'network_monitor.log',
                'alert_manager.log',
                'device_discovery.log',
                'metrics_collection.log'
            ]

            for log_file in log_files:
                log_path = log_dir / log_file
                if not log_path.exists():
                    log_path.touch()
                logger.info(f'Created log file: {log_path}')

            logger.info('Logging setup completed')
            return True

        except Exception as e:
            logger.error(f'Error setting up logging: {e}')
            return False

    def generate_secrets(self) -> bool:
        """Generate secure secrets for the application."""
        try:
            import secrets
            env_file = self.root_dir / '.env'
            
            # Read current env file
            with open(env_file) as f:
                env_content = f.read()

            # Generate and replace secrets
            secrets_to_generate = {
                'JWT_SECRET': secrets.token_hex(32),
                'SESSION_SECRET': secrets.token_hex(32),
                'ENCRYPTION_KEY': secrets.token_hex(32)
            }

            for key, value in secrets_to_generate.items():
                if f'{key}=your_{key.lower()}' in env_content:
                    env_content = env_content.replace(
                        f'{key}=your_{key.lower()}',
                        f'{key}={value}'
                    )

            # Write updated content
            with open(env_file, 'w') as f:
                f.write(env_content)

            logger.info('Generated secure secrets')
            return True

        except Exception as e:
            logger.error(f'Error generating secrets: {e}')
            return False

    def run_setup(self) -> bool:
        """Run the complete setup process."""
        steps = [
            (self.check_python_version, 'Checking Python version'),
            (self.create_directories, 'Creating directories'),
            (self.check_dependencies, 'Checking dependencies'),
            (self.validate_config, 'Validating configuration'),
            (self.setup_logging, 'Setting up logging'),
            (self.generate_secrets, 'Generating secrets'),
            (self.check_network_access, 'Checking network access')
        ]

        success = True
        for step_func, step_name in steps:
            logger.info(f'\n=== {step_name} ===')
            if not step_func():
                success = False
                logger.error(f'{step_name} failed')
                break
            logger.info(f'{step_name} completed successfully')

        if success:
            logger.info('\n=== Setup completed successfully ===')
            logger.info('You can now start the network monitor with: python network_monitor.py')
        else:
            logger.error('\n=== Setup failed ===')
            logger.error('Please fix the reported issues and try again')

        return success

def main():
    """Main entry point for setup script."""
    setup = SetupManager()
    success = setup.run_setup()
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
