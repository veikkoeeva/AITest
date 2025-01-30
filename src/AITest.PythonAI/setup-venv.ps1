<#
.SYNOPSIS
    Creates and configures a Python virtual environment with Jupyter support.

.DESCRIPTION
    This script creates a Python 3.12 virtual environment, installs required packages,
    and configures Jupyter notebook support. It performs the following tasks:
    - Verifies Python 3.12 installation.
    - Creates a virtual environment if it doesn't exist.
    - Activates the virtual environment.
    - Upgrades pip, setuptools, and wheel.
    - Installs and configures IPyKernel for Jupyter support.

.PARAMETER VenvPath
    The path where the virtual environment will be created. Defaults to ".\venv".

.EXAMPLE
    .\Setup-PythonVenv.ps1
    Creates a virtual environment in the default location (.\venv)

.EXAMPLE
    .\Setup-PythonVenv.ps1 -VenvPath "C:\Projects\MyProject\venv"
    Creates a virtual environment in the specified location.

.NOTES
    File Name      : Setup-PythonVenv.ps1
    Author         : Veikko Eeva
    Prerequisite   : PowerShell 5.1 or later
    Requirements   : Python 3.12
    Version        : 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$VenvPath = ".\.venv"
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-PythonInstallation {
    <#
    .SYNOPSIS
        Verifies that Python 3.12 is installed and accessible.
    #>
    try {
        $pythonInfo = Get-Command "python" -ErrorAction Stop
        $version = py -3.12 --version 2>&1
        if ($version -notmatch "Python 3\.12") {
            throw "Python 3.12 is required but found: $version"
        }
        Write-Verbose "Found $version at $($pythonInfo.Path)"
        return $true
    }
    catch {
        Write-Error "Python 3.12 is not properly installed: $_"
        return $false
    }
}

function New-VirtualEnvironment {
    <#
    .SYNOPSIS
        Creates a new Python virtual environment if it doesn't exist.
    #>
    param (
        [string]$Path
    )
    if (!(Test-Path $Path)) {
        Write-Host "Creating Python virtual environment at: $Path" -ForegroundColor Cyan
        try {
            py -3.12 -m venv $Path
        }
        catch {
            Write-Error "Failed to create virtual environment: $_"
            exit 1
        }
    }
    else {
        Write-Host "Virtual environment already exists at: $Path" -ForegroundColor Yellow
    }
}

function Install-RequiredPackages {
    <#
    .SYNOPSIS
        Installs and upgrades required Python packages in the virtual environment.
    #>    
    try {
        Write-Host "Upgrading pip, setuptools, and wheel..." -ForegroundColor Cyan
        py -3.12 -m pip install --upgrade pip setuptools wheel

        Write-Host "Intalling IPyKernel..." -ForegroundColor Cyan
        py -3.12 -m pip install ipykernel

        Write-Host "Intalling pyproject.toml dependencies..." -ForegroundColor Cyan
        py -3.12 -m pip install . --verbose
    }
    catch {
        Write-Error "Failed to install required packages: $_"
        exit 1
    }
}

function Register-JupyterKernel {
    <#
    .SYNOPSIS
        Registers the virtual environment as a Jupyter kernel.
    #>
    Write-Host "Registering Jupyter kernel..." -ForegroundColor Cyan
    try {
        py -3.12 -m ipykernel install --user --name=venv --display-name "Python 3.12 (venv)"
    }
    catch {
        Write-Error "Failed to register Jupyter kernel: $_"
        exit 1
    }
}


try {
    Write-Host "Starting Python virtual environment setup..." -ForegroundColor Green

    # Verify Python installation
    if (-not (Test-PythonInstallation)) {
        exit 1
    }
    
    New-VirtualEnvironment -Path $VenvPath
    
    Write-Host "Activating virtual environment..." -ForegroundColor Cyan
    $activateScript = Join-Path $VenvPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        & $activateScript
    }
    else {
        throw "Activation script not found at: $activateScript"
    }
    
    Install-RequiredPackages
    Register-JupyterKernel

    # List installed packages to make it easier to verify installation visually.
    Write-Host "Installed packages:" -ForegroundColor Cyan
    py -3.12 -m pip list

    Write-Host "Virtual environment setup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during setup: $_"
    exit 1
}
finally {
    # Reset error action preference to default.
    $ErrorActionPreference = "Continue"
}