@echo off
setlocal enabledelayedexpansion

:: Network Monitor Installation Script for Windows
:: This script performs a complete installation and testing of the Network Monitor system

:: Color codes for Windows console
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "NC=[0m"

:: Function to print headers
:print_header
echo.
echo %YELLOW%=== %~1 ===%NC%
echo.
goto :eof

:: Main installation process
:main
call :print_header "Starting Network Monitor Installation"

:: Check Python version
call :print_header "Checking Python Version"
python --version > nul 2>&1
if errorlevel 1 (
    echo %RED%Python is not installed or not in PATH%NC%
    exit /b 1
)

python -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)"
if errorlevel 1 (
    echo %RED%Python 3.8 or higher is required%NC%
    exit /b 1
)
echo %GREEN%Python version check passed%NC%

:: Check system requirements
call :print_header "Checking System Requirements"

:: Check Git installation
git --version > nul 2>&1
if errorlevel 1 (
    echo %RED%Git is not installed or not in PATH%NC%
    exit /b 1
)
echo %GREEN%Git is installed%NC%

:: Create virtual environment
call :print_header "Setting up Virtual Environment"
if not exist venv (
    python -m venv venv
    if errorlevel 1 (
        echo %RED%Failed to create virtual environment%NC%
        exit /b 1
    )
    echo %GREEN%Virtual environment created%NC%
) else (
    echo %GREEN%Virtual environment already exists%NC%
)

:: Activate virtual environment
call venv\Scripts\activate.bat
if errorlevel 1 (
    echo %RED%Failed to activate virtual environment%NC%
    exit /b 1
)
echo %GREEN%Virtual environment activated%NC%

:: Upgrade pip
call :print_header "Upgrading pip"
python -m pip install --upgrade pip
if errorlevel 1 (
    echo %RED%Failed to upgrade pip%NC%
    exit /b 1
)
echo %GREEN%Pip upgraded successfully%NC%

:: Install dependencies
call :print_header "Installing Dependencies"
pip install -r requirements.txt
if errorlevel 1 (
    echo %RED%Failed to install dependencies%NC%
    exit /b 1
)
echo %GREEN%Dependencies installed successfully%NC%

:: Set up environment file
call :print_header "Setting up Environment"
if not exist .env (
    copy .env.example .env
    if errorlevel 1 (
        echo %RED%Failed to create environment file%NC%
        exit /b 1
    )
    echo %YELLOW%Please update .env file with your configuration%NC%
) else (
    echo %GREEN%Environment file already exists%NC%
)

:: Run setup script
call :print_header "Running Setup Script"
python setup.py
if errorlevel 1 (
    echo %RED%Setup script failed%NC%
    exit /b 1
)
echo %GREEN%Setup completed successfully%NC%

:: Run tests
call :print_header "Running Tests"
python test_setup.py
if errorlevel 1 (
    echo %RED%Tests failed%NC%
    exit /b 1
)
echo %GREEN%Tests completed successfully%NC%

:: Verify installation
call :print_header "Verifying Installation"
set "required_files=config\config.json modules\device_manager.py modules\metrics_manager.py modules\alert_manager.py modules\topology_manager.py"
for %%f in (%required_files%) do (
    if not exist %%f (
        echo %RED%Missing required file: %%f%NC%
        exit /b 1
    )
    echo %GREEN%Found required file: %%f%NC%
)

:: Installation complete
call :print_header "Installation Complete"
echo %GREEN%Network Monitor has been successfully installed!%NC%
echo.
echo To start monitoring, run:
echo %YELLOW%venv\Scripts\activate.bat%NC%
echo %YELLOW%python network_monitor.py%NC%

:: Deactivate virtual environment
deactivate

endlocal
exit /b 0
