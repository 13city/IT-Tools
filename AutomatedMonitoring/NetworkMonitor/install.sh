#!/bin/bash

# Network Monitor Installation Script
# This script performs a complete installation and testing of the Network Monitor system

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${YELLOW}=== $1 ===${NC}\n"
}

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 successful${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Function to check Python version
check_python_version() {
    print_header "Checking Python Version"
    required_version="3.8"
    python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    
    if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" = "$required_version" ]; then 
        echo -e "${GREEN}✓ Python version $python_version meets minimum requirement ($required_version)${NC}"
    else
        echo -e "${RED}✗ Python version $python_version is below minimum requirement ($required_version)${NC}"
        exit 1
    fi
}

# Function to check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    
    # Check for required system packages
    required_packages=("git" "python3-pip" "python3-venv" "ping")
    
    for package in "${required_packages[@]}"; do
        if command -v $package >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $package is installed${NC}"
        else
            echo -e "${RED}✗ $package is not installed${NC}"
            exit 1
        fi
    done
}

# Function to set up Python virtual environment
setup_virtual_environment() {
    print_header "Setting up Virtual Environment"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        check_status "Virtual environment creation"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    check_status "Virtual environment activation"
    
    # Upgrade pip
    pip install --upgrade pip
    check_status "Pip upgrade"
}

# Function to install dependencies
install_dependencies() {
    print_header "Installing Dependencies"
    
    # Install required packages
    pip install -r requirements.txt
    check_status "Package installation"
}

# Function to run setup script
run_setup() {
    print_header "Running Setup Script"
    
    python setup.py
    check_status "Setup script execution"
}

# Function to run tests
run_tests() {
    print_header "Running Tests"
    
    python test_setup.py
    check_status "Test execution"
}

# Function to verify installation
verify_installation() {
    print_header "Verifying Installation"
    
    # Check if all required files exist
    required_files=(
        "config/config.json"
        "modules/device_manager.py"
        "modules/metrics_manager.py"
        "modules/alert_manager.py"
        "modules/topology_manager.py"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓ $file exists${NC}"
        else
            echo -e "${RED}✗ $file is missing${NC}"
            exit 1
        fi
    done
}

# Function to create environment file
setup_environment() {
    print_header "Setting up Environment"
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        check_status "Environment file creation"
        echo -e "${YELLOW}Please update .env file with your configuration${NC}"
    else
        echo -e "${GREEN}✓ Environment file already exists${NC}"
    fi
}

# Main installation process
main() {
    print_header "Starting Network Monitor Installation"
    
    # Change to script directory
    cd "$(dirname "$0")"
    
    # Run installation steps
    check_python_version
    check_system_requirements
    setup_virtual_environment
    install_dependencies
    setup_environment
    run_setup
    run_tests
    verify_installation
    
    print_header "Installation Complete"
    echo -e "${GREEN}Network Monitor has been successfully installed!${NC}"
    echo -e "\nTo start monitoring, run:"
    echo -e "${YELLOW}source venv/bin/activate${NC}"
    echo -e "${YELLOW}python network_monitor.py${NC}"
}

# Run main installation
main
