# Network Monitor Installation Script for PowerShell
# This script performs a complete installation and testing of the Network Monitor system

# Ensure script is running with administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator"
    exit 1
}

# Function to write colored output
function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$Color = "White"
    )
    
    $prevColor = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $Color
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $prevColor
}

# Function to print section headers
function Write-Header {
    param([string]$Title)
    
    Write-Output ""
    Write-ColorOutput "=== $Title ===" "Yellow"
    Write-Output ""
}

# Function to check command existence
function Test-Command {
    param([string]$Command)
    
    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

# Function to check Python version
function Test-PythonVersion {
    try {
        $pythonVersion = python -c "import sys; print('.'.join(map(str, sys.version_info[:2])))"
        $version = [version]$pythonVersion
        $minVersion = [version]"3.8"
        
        if ($version -ge $minVersion) {
            Write-ColorOutput "✓ Python $pythonVersion meets minimum requirement (3.8)" "Green"
            return $true
        } else {
            Write-ColorOutput "✗ Python $pythonVersion is below minimum requirement (3.8)" "Red"
            return $false
        }
    } catch {
        Write-ColorOutput "✗ Failed to check Python version: $_" "Red"
        return $false
    }
}

# Main installation process
try {
    Write-Header "Starting Network Monitor Installation"
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"
    
    # Check Python installation
    Write-Header "Checking Python Installation"
    if (-not (Test-Command "python")) {
        throw "Python is not installed or not in PATH"
    }
    if (-not (Test-PythonVersion)) {
        throw "Python version requirement not met"
    }
    
    # Check Git installation
    Write-Header "Checking Git Installation"
    if (-not (Test-Command "git")) {
        throw "Git is not installed or not in PATH"
    }
    Write-ColorOutput "✓ Git is installed" "Green"
    
    # Create and activate virtual environment
    Write-Header "Setting up Virtual Environment"
    $venvPath = "venv"
    if (-not (Test-Path $venvPath)) {
        Write-Progress -Activity "Creating virtual environment" -Status "Running..." -PercentComplete 0
        python -m venv $venvPath
        Write-ColorOutput "✓ Virtual environment created" "Green"
    } else {
        Write-ColorOutput "✓ Virtual environment already exists" "Green"
    }
    
    # Activate virtual environment
    Write-Progress -Activity "Activating virtual environment" -Status "Running..." -PercentComplete 20
    & "$venvPath\Scripts\Activate.ps1"
    Write-ColorOutput "✓ Virtual environment activated" "Green"
    
    # Upgrade pip
    Write-Header "Upgrading pip"
    Write-Progress -Activity "Upgrading pip" -Status "Running..." -PercentComplete 40
    python -m pip install --upgrade pip
    Write-ColorOutput "✓ Pip upgraded successfully" "Green"
    
    # Install dependencies
    Write-Header "Installing Dependencies"
    Write-Progress -Activity "Installing dependencies" -Status "Running..." -PercentComplete 60
    pip install -r requirements.txt
    Write-ColorOutput "✓ Dependencies installed successfully" "Green"
    
    # Set up environment file
    Write-Header "Setting up Environment"
    if (-not (Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-ColorOutput "✓ Environment file created" "Green"
        Write-ColorOutput "! Please update .env file with your configuration" "Yellow"
    } else {
        Write-ColorOutput "✓ Environment file already exists" "Green"
    }
    
    # Run setup script
    Write-Header "Running Setup Script"
    Write-Progress -Activity "Running setup script" -Status "Running..." -PercentComplete 80
    python setup.py
    Write-ColorOutput "✓ Setup completed successfully" "Green"
    
    # Run tests
    Write-Header "Running Tests"
    Write-Progress -Activity "Running tests" -Status "Running..." -PercentComplete 90
    python test_setup.py
    Write-ColorOutput "✓ Tests completed successfully" "Green"
    
    # Verify installation
    Write-Header "Verifying Installation"
    Write-Progress -Activity "Verifying installation" -Status "Running..." -PercentComplete 95
    $requiredFiles = @(
        "config\config.json",
        "modules\device_manager.py",
        "modules\metrics_manager.py",
        "modules\alert_manager.py",
        "modules\topology_manager.py"
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            throw "Missing required file: $file"
        }
        Write-ColorOutput "✓ Found required file: $file" "Green"
    }
    
    # Installation complete
    Write-Progress -Activity "Installation" -Status "Complete" -PercentComplete 100
    Write-Header "Installation Complete"
    Write-ColorOutput "Network Monitor has been successfully installed!" "Green"
    Write-Output ""
    Write-ColorOutput "To start monitoring, run:" "Yellow"
    Write-ColorOutput ".\venv\Scripts\Activate.ps1" "Yellow"
    Write-ColorOutput "python network_monitor.py" "Yellow"
    
} catch {
    Write-ColorOutput "Installation failed: $_" "Red"
    exit 1
} finally {
    # Deactivate virtual environment if active
    if ($env:VIRTUAL_ENV) {
        deactivate
    }
    
    # Reset progress bar preference
    $ProgressPreference = "Continue"
}
