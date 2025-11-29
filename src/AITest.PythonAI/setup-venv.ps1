<#
.SYNOPSIS
    Creates and configures a Python virtual environment with Jupyter support using uv.

.DESCRIPTION
    This script uses uv to create a Python virtual environment and install dependencies.
    uv is 10-100x faster than pip for package installation.

.PARAMETER VenvPath
    The path where the virtual environment will be created. Defaults to ".\.venv".

.PARAMETER PythonVersion
    The Python version to use. Defaults to 3.13.

.EXAMPLE
    .\setup-venv.ps1

.EXAMPLE
    .\setup-venv.ps1 -PythonVersion 3.12

.NOTES
    File Name      : setup-venv.ps1
    Prerequisite   : uv must be installed (https://docs.astral.sh/uv/getting-started/installation/)
    Version        : 3.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VenvPath = ".\.venv",

    [Parameter(Mandatory = $false)]
    [string]$PythonVersion = "3.13"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-UvInstalled {
    try {
        $null = Get-Command "uv" -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Install-Uv {
    Write-Host "Installing uv..." -ForegroundColor Cyan
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    
    # Add to PATH for current session (installer only updates permanent PATH)
    $uvPath = "$env:USERPROFILE\.local\bin"
    if (Test-Path $uvPath) {
        $env:Path = "$uvPath;$env:Path"
    }
}

try {
    Write-Host "Starting Python virtual environment setup with uv..." -ForegroundColor Green

    # 1. Ensure uv is installed
    if (-not (Test-UvInstalled)) {
        Install-Uv
    }

    $uvVersion = uv --version
    Write-Host "Using $uvVersion" -ForegroundColor Cyan

    # 2. Create venv with specified Python version (uv downloads Python if needed)
    Write-Host "Creating virtual environment at: $VenvPath" -ForegroundColor Cyan
    uv venv $VenvPath --python $PythonVersion

    # 3. Install project dependencies (reads pyproject.toml automatically)
    Write-Host "Installing project dependencies..." -ForegroundColor Cyan
    uv sync --extra dev

    # 4. Install ipykernel for Jupyter support
    Write-Host "Installing ipykernel..." -ForegroundColor Cyan
    uv pip install ipykernel

    # 5. Register Jupyter kernel
    $venvPython = Join-Path $VenvPath "Scripts\python.exe"
    $kernelName = Split-Path -Leaf $VenvPath
    if (-not $kernelName) { $kernelName = "venv" }
    
    $displayName = "Python $PythonVersion ($kernelName)"
    Write-Host "Registering Jupyter kernel '$kernelName'..." -ForegroundColor Cyan
    & $venvPython -m ipykernel install --user --name $kernelName --display-name $displayName

    # 6. Show installed packages
    Write-Host "`nInstalled packages:" -ForegroundColor Cyan
    uv pip list

    # 7. Activation hint
    Write-Host ""
    Write-Host "To activate this virtual environment:" -ForegroundColor Cyan
    Write-Host "  . `"$VenvPath\Scripts\Activate.ps1`"" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "Or use uv run to run commands directly:" -ForegroundColor Cyan
    Write-Host "  uv run python your_script.py" -ForegroundColor DarkCyan
    Write-Host "  uv run pytest" -ForegroundColor DarkCyan

    Write-Host ""
    Write-Host "Setup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during setup: $_"
    exit 1
}