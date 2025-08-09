# Claude Memento Update System - Utility Functions (PowerShell)
# Provides common utility functions for the update system

# Color codes for output
$script:Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Cyan"
    NC = "White"
}

# Ensure UPDATE_LOG is set
if (-not $env:UPDATE_LOG) {
    $env:UPDATE_LOG = "$env:USERPROFILE\.claude\memento\update.log"
}

# Function: Print colored output
function Write-ColorOutput {
    param(
        [string]$Color,
        [string]$Message
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function: Print error and exit
function Write-ErrorAndExit {
    param(
        [string]$Message
    )
    Write-ColorOutput -Color $Colors.Red -Message "❌ Error: $Message"
    Add-Content -Path $env:UPDATE_LOG -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - ERROR: $Message"
    exit 1
}

# Function: Print warning
function Write-Warning {
    param(
        [string]$Message
    )
    Write-ColorOutput -Color $Colors.Yellow -Message "⚠️  Warning: $Message"
    Add-Content -Path $env:UPDATE_LOG -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - WARNING: $Message"
}

# Function: Print info
function Write-Info {
    param(
        [string]$Message
    )
    Write-ColorOutput -Color $Colors.Blue -Message "ℹ️  $Message"
    Add-Content -Path $env:UPDATE_LOG -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - INFO: $Message"
}

# Function: Print success
function Write-Success {
    param(
        [string]$Message
    )
    Write-ColorOutput -Color $Colors.Green -Message "✅ $Message"
    Add-Content -Path $env:UPDATE_LOG -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - SUCCESS: $Message"
}

# Function: Print verbose message (only if VERBOSE is true)
function Write-Verbose {
    param(
        [string]$Message
    )
    if ($script:VERBOSE) {
        Write-Info -Message $Message
    }
}

# Function: Ensure directory exists
function Ensure-Directory {
    param(
        [string]$Path
    )
    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        if (-not $?) {
            Write-ErrorAndExit -Message "Failed to create directory: $Path"
        }
    }
}

# Function: Safe copy with error handling
function Copy-SafeItem {
    param(
        [string]$Source,
        [string]$Destination
    )
    
    if (-not (Test-Path -Path $Source)) {
        Write-ErrorAndExit -Message "Source does not exist: $Source"
    }
    
    Copy-Item -Path $Source -Destination $Destination -Recurse -Force -ErrorAction Stop
    if (-not $?) {
        Write-ErrorAndExit -Message "Failed to copy $Source to $Destination"
    }
}

# Function: Check if running in dry-run mode
function Test-DryRun {
    return $script:DRY_RUN -eq $true
}

# Function: Execute command with dry-run support
function Invoke-Command {
    param(
        [scriptblock]$Command,
        [string]$Description
    )
    
    if (Test-DryRun) {
        Write-Info -Message "[DRY RUN] Would execute: $Description"
        return $true
    } else {
        Write-Verbose -Message "Executing: $Description"
        & $Command
        return $?
    }
}

# Function: Get timestamp
function Get-Timestamp {
    return Get-Date -Format "yyyyMMdd_HHmmss"
}

# Function: Get ISO timestamp
function Get-ISOTimestamp {
    return Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
}

# Function: Calculate directory size
function Get-DirectorySize {
    param(
        [string]$Path
    )
    
    if (Test-Path -Path $Path) {
        $size = (Get-ChildItem -Path $Path -Recurse | Measure-Object -Property Length -Sum).Sum
        if ($size -gt 1GB) {
            return "{0:N2} GB" -f ($size / 1GB)
        } elseif ($size -gt 1MB) {
            return "{0:N2} MB" -f ($size / 1MB)
        } elseif ($size -gt 1KB) {
            return "{0:N2} KB" -f ($size / 1KB)
        } else {
            return "$size B"
        }
    } else {
        return "0"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Write-ColorOutput',
    'Write-ErrorAndExit',
    'Write-Warning',
    'Write-Info',
    'Write-Success',
    'Write-Verbose',
    'Ensure-Directory',
    'Copy-SafeItem',
    'Test-DryRun',
    'Invoke-Command',
    'Get-Timestamp',
    'Get-ISOTimestamp',
    'Get-DirectorySize'
)