# YouTrack Docker - Permission Setup for Windows
# Run this script in PowerShell with Administrator privileges

param(
    [switch]$Help
)

if ($Help) {
    Write-Host @"
YouTrack Docker - Permission Setup Script for Windows

USAGE:
    .\setup-permissions.ps1

DESCRIPTION:
    This script prepares directories for YouTrack Docker on Windows.
    It creates the required directories if they don't exist.

NOTE:
    - Run PowerShell as Administrator
    - On Windows with Docker Desktop, permissions are handled differently
    - Docker Desktop uses the VM's filesystem, so ownership is managed automatically
    - This script primarily ensures directories exist

EXAMPLES:
    .\setup-permissions.ps1
"@
    exit 0
}

Write-Host "=== YouTrack Docker - Permission Setup for Windows ===" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Warning: Not running as Administrator. Some operations may fail." -ForegroundColor Yellow
    Write-Host "Please run PowerShell as Administrator for best results." -ForegroundColor Yellow
    Write-Host ""
}

# Load environment variables from stack.env if it exists
$envFile = "stack.env"
if (Test-Path $envFile) {
    Write-Host "Loading configuration from stack.env..." -ForegroundColor Yellow
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

# Get paths from environment or use defaults
$dataPath = $env:YOUTRACK_DATA
$confPath = $env:YOUTRACK_CONF
$logsPath = $env:YOUTRACK_LOGS
$backupsPath = $env:YOUTRACK_BACKUPS

function Test-IsBindMount {
    param([string]$path)
    return $path -match '^(\.\\|\.\/|\\|\/|[A-Za-z]:)'
}

function Setup-Directory {
    param(
        [string]$path,
        [string]$name
    )
    
    if ([string]::IsNullOrEmpty($path)) {
        Write-Host "✓ $name Using Docker named volume (no setup needed)" -ForegroundColor Yellow
        return $true
    }
    
    if (-not (Test-IsBindMount $path)) {
        Write-Host "✓ $name Using Docker named volume '$path' (no setup needed)" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "Setting up $name $path" -ForegroundColor Green
    
    # Create directory if it doesn't exist
    if (-not (Test-Path $path)) {
        Write-Host "  - Creating directory..." -ForegroundColor Gray
        try {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "  - Directory created successfully" -ForegroundColor Gray
        }
        catch {
            Write-Host "  - Error creating directory: $_" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "  - Directory already exists" -ForegroundColor Gray
    }
    
    Write-Host "  ✓ $name configured successfully" -ForegroundColor Green
    Write-Host ""
    return $true
}

Write-Host "Note: On Windows with Docker Desktop, volume permissions are managed automatically." -ForegroundColor Yellow
Write-Host "This script ensures directories exist for bind mounts." -ForegroundColor Yellow
Write-Host ""

Write-Host "Configuring directories..." -ForegroundColor Green
Write-Host ""

$failed = 0
if (-not (Setup-Directory $dataPath "Data directory:")) { $failed++ }
if (-not (Setup-Directory $confPath "Config directory:")) { $failed++ }
if (-not (Setup-Directory $logsPath "Logs directory:")) { $failed++ }
if (-not (Setup-Directory $backupsPath "Backups directory:")) { $failed++ }

Write-Host ""
Write-Host "=== Setup Summary ===" -ForegroundColor Green

if ($failed -eq 0) {
    Write-Host "✓ All directories configured successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now start YouTrack with:" -ForegroundColor White
    Write-Host "  docker-compose up -d" -ForegroundColor Green
    Write-Host ""
    exit 0
}
else {
    Write-Host "⚠ Some directories could not be configured." -ForegroundColor Yellow
    Write-Host "Please check the errors above and try again." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
