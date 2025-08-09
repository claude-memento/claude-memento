# Claude Memento PowerShell Uninstall Script
# Safe removal with data preservation options

param(
    [switch]$KeepData,
    [switch]$Force,
    [switch]$Verbose
)

# Show help if requested
if ($args -contains "--help" -or $args -contains "-h") {
    Write-Host "Claude Memento PowerShell Uninstaller" -ForegroundColor Blue
    Write-Host "Usage: .\uninstall.ps1 [OPTIONS]" 
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -KeepData      Preserve checkpoint and chunk data"
    Write-Host "  -Force         Skip confirmation prompts"
    Write-Host "  -Verbose       Enable verbose output"
    Write-Host "  --help, -h     Show this help message"
    Write-Host ""
    exit 0
}

$ErrorActionPreference = "Stop"

# Define directories
$ClaudeDir = "$env:USERPROFILE\.claude"
$MementoDir = "$ClaudeDir\memento"
$CommandsDir = "$ClaudeDir\commands"
$CMCommandsDir = "$CommandsDir\cm"

# Markers for CLAUDE.md integration
$BeginMarker = "<!-- BEGIN_CLAUDE_MEMENTO -->"
$EndMarker = "<!-- END_CLAUDE_MEMENTO -->"

Write-Host "🧠 Claude Memento Uninstaller (PowerShell)" -ForegroundColor Blue
Write-Host "=========================================="

# Function to check if installed
function Test-Installation {
    if ((Test-Path "$ClaudeDir\CLAUDE.md") -and (Get-Content "$ClaudeDir\CLAUDE.md" -Raw) -match [regex]::Escape($BeginMarker)) {
        return $true
    }
    if (Test-Path $MementoDir) {
        return $true
    }
    return $false
}

# Function to remove from CLAUDE.md
function Remove-FromClaudeMd {
    if (Test-Path "$ClaudeDir\CLAUDE.md") {
        Write-Host "Removing Claude Memento section(s) from CLAUDE.md..." -ForegroundColor Yellow
        
        # Create backup before modification
        Copy-Item -Path "$ClaudeDir\CLAUDE.md" -Destination "$ClaudeDir\CLAUDE.md.uninstall.backup" -Force
        
        $removedCount = 0
        
        # Remove ALL existing Claude Memento sections (handle multiple sections)
        while ((Get-Content "$ClaudeDir\CLAUDE.md" -Raw -ErrorAction SilentlyContinue) -match [regex]::Escape($BeginMarker)) {
            $content = Get-Content "$ClaudeDir\CLAUDE.md" -Raw
            
            # Remove section between markers including the blank line before
            $pattern = "(?:\r?\n)?\r?\n$([regex]::Escape($BeginMarker))[\s\S]*?$([regex]::Escape($EndMarker))"
            $newContent = $content -replace $pattern, ""
            
            # Save the modified content
            $newContent | Out-File -FilePath "$ClaudeDir\CLAUDE.md" -Encoding UTF8 -NoNewline
            $removedCount++
            
            # Safety check to prevent infinite loop
            if ($removedCount -gt 20) {
                Write-Host "Warning: Removed $removedCount Claude Memento sections. Stopping to prevent infinite loop." -ForegroundColor Red
                break
            }
        }
        
        if ($removedCount -gt 0) {
            Write-Host "✓ Removed $removedCount Claude Memento section(s) from CLAUDE.md" -ForegroundColor Green
        } else {
            Write-Host "ℹ️  No Claude Memento sections found in CLAUDE.md" -ForegroundColor Yellow
        }
    }
}

# Function to preserve data
function Backup-Data {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "$env:USERPROFILE\claude-memento-backup-$timestamp"
    $hasData = $false
    
    # Check for checkpoints
    if ((Test-Path "$MementoDir\checkpoints") -and (Get-ChildItem "$MementoDir\checkpoints" -ErrorAction SilentlyContinue)) {
        $hasData = $true
    }
    
    # Check for chunks
    if ((Test-Path "$MementoDir\chunks") -and (Get-ChildItem "$MementoDir\chunks" -ErrorAction SilentlyContinue)) {
        $hasData = $true
    }
    
    if ($hasData) {
        Write-Host "Preserving data..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        
        # Copy checkpoints if exist
        if ((Test-Path "$MementoDir\checkpoints") -and (Get-ChildItem "$MementoDir\checkpoints" -ErrorAction SilentlyContinue)) {
            Copy-Item -Path "$MementoDir\checkpoints" -Destination $backupDir -Recurse -Force
            Write-Host "✓ Checkpoints backed up" -ForegroundColor Green
        }
        
        # Copy chunks if exist
        if ((Test-Path "$MementoDir\chunks") -and (Get-ChildItem "$MementoDir\chunks" -ErrorAction SilentlyContinue)) {
            Copy-Item -Path "$MementoDir\chunks" -Destination $backupDir -Recurse -Force
            Write-Host "✓ Chunks backed up" -ForegroundColor Green
        }
        
        # Copy configuration files
        if (Test-Path "$MementoDir\config\settings.json") {
            New-Item -ItemType Directory -Force -Path "$backupDir\config" | Out-Null
            Copy-Item -Path "$MementoDir\config\settings.json" -Destination "$backupDir\config\" -Force
            Write-Host "✓ Configuration backed up" -ForegroundColor Green
        }
        
        # Copy active context if exists
        if (Test-Path "$MementoDir\claude-memento.md") {
            Copy-Item -Path "$MementoDir\claude-memento.md" -Destination "$backupDir\" -Force
            Write-Host "✓ Active context backed up" -ForegroundColor Green
        }
        
        Write-Host "✓ Data backed up to: $backupDir" -ForegroundColor Green
        $script:CheckpointBackupDir = $backupDir
    }
}

# Function to stop running processes with enhanced safety
function Stop-Processes {
    $stopped = $false
    $timeout = 10
    
    Write-Host "Checking for running processes..." -ForegroundColor Yellow
    
    # Check for auto-save daemon (PID file) with graceful shutdown
    $pidFile = "$MementoDir\.auto-save.pid"
    if (Test-Path $pidFile) {
        $pid = Get-Content $pidFile -ErrorAction SilentlyContinue
        if ($pid -and $pid -match '^\d+$') {
            try {
                $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
                if ($process) {
                    Write-Host "Stopping auto-save daemon (PID: $pid)..." -ForegroundColor Yellow
                    
                    # Try graceful shutdown first
                    try {
                        $process.CloseMainWindow()
                        $process.WaitForExit(5000) # Wait 5 seconds
                    } catch {
                        # Fallback to force kill
                    }
                    
                    # Force kill if still running
                    $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
                    if ($process) {
                        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                    }
                    
                    Write-Host "✓ Auto-save daemon stopped" -ForegroundColor Green
                    $stopped = $true
                }
            } catch {
                if ($Verbose) {
                    Write-Host "Process $pid not found or already stopped" -ForegroundColor Gray
                }
            }
            Remove-Item -Path $pidFile -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Check for any Claude Memento related processes
    # Look for bash/sh processes running memento scripts
    $mementoProcesses = Get-Process | Where-Object {
        $_.ProcessName -match "bash|sh|node" -and 
        $_.CommandLine -match "claude-memento|/memento/"
    } -ErrorAction SilentlyContinue
    
    if ($mementoProcesses) {
        Write-Host "Found Claude Memento processes..." -ForegroundColor Yellow
        foreach ($proc in $mementoProcesses) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Host "✓ Stopped process $($proc.Id)" -ForegroundColor Green
                $stopped = $true
            } catch {
                # Process may have already ended
            }
        }
    }
    
    # Alternative method using WMI for better command line detection
    try {
        $wmiProcesses = Get-WmiObject Win32_Process | Where-Object {
            $_.CommandLine -match "claude-memento|memento"
        }
        foreach ($proc in $wmiProcesses) {
            try {
                Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
                Write-Host "✓ Stopped process $($proc.ProcessId)" -ForegroundColor Green
                $stopped = $true
            } catch {
                # Process may have already ended
            }
        }
    } catch {
        # WMI might not be available or accessible
    }
    
    if (-not $stopped) {
        Write-Host "✓ No running processes found" -ForegroundColor Green
    }
    
    # Clean up any PID files and temporary files
    Get-ChildItem -Path $MementoDir -Filter ".*.pid" -ErrorAction SilentlyContinue | Remove-Item -Force
    
    # Clean up temporary files
    if (Test-Path "$MementoDir\tmp") {
        Remove-Item -Path "$MementoDir\tmp\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
    
    # Clean up system temp files
    Get-ChildItem -Path $env:TEMP -Filter "claude-memento-*" -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse
}

# Check if installed
if (-not (Test-Installation)) {
    Write-Host "Error: Claude Memento is not installed!" -ForegroundColor Red
    exit 1
}

# Confirm uninstallation with enhanced safety
if (-not $Force) {
    Write-Host "This will uninstall Claude Memento." -ForegroundColor Yellow
    if ($KeepData) {
        Write-Host "Checkpoint data will be preserved and backed up."
    } else {
        Write-Host "⚠️  All checkpoint data will be PERMANENTLY deleted!" -ForegroundColor Red
        Write-Host "Use '-KeepData' to preserve checkpoints."
    }
    Write-Host ""
    Write-Host "This action will:"
    Write-Host "  - Stop all running Claude Memento processes"
    Write-Host "  - Remove Claude Memento section from CLAUDE.md"
    Write-Host "  - Delete all installation files and scripts"
    if (-not $KeepData) {
        Write-Host "  - DELETE all saved checkpoints and chunks" -ForegroundColor Red
    }
    Write-Host ""
    
    $response = Read-Host "Are you sure you want to continue? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Uninstall cancelled."
        exit 0
    }
} else {
    Write-Host "Force removal mode - skipping confirmation" -ForegroundColor Yellow
}

# Stop running processes first
Stop-Processes

# Remove from CLAUDE.md
Remove-FromClaudeMd

# Handle data preservation
if ($KeepData) {
    Backup-Data
}

# Remove command files
Write-Host "Removing command files..." -ForegroundColor Yellow
if (Test-Path $CMCommandsDir) {
    Remove-Item -Path $CMCommandsDir -Recurse -Force
    Write-Host "✓ Removed command files" -ForegroundColor Green
}

# Remove cm-*.sh wrapper scripts
Write-Host "Removing wrapper scripts..." -ForegroundColor Yellow
Get-ChildItem -Path "$CommandsDir\cm-*.sh" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -Path $_.FullName -Force
}
Write-Host "✓ Removed wrapper scripts" -ForegroundColor Green

# Remove claude-memento.md if exists
if (Test-Path "$MementoDir\claude-memento.md") {
    Write-Host "Removing active context tracker..." -ForegroundColor Yellow
    if ($KeepData -and $script:CheckpointBackupDir) {
        Copy-Item -Path "$MementoDir\claude-memento.md" -Destination "$script:CheckpointBackupDir\claude-memento.md" -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Active context backed up" -ForegroundColor Green
    }
    Remove-Item -Path "$MementoDir\claude-memento.md" -Force
    Write-Host "✓ Removed active context tracker" -ForegroundColor Green
}

# Remove main installation
Write-Host "Removing Claude Memento files..." -ForegroundColor Yellow
if (Test-Path $MementoDir) {
    if ($KeepData) {
        # Remove everything except checkpoints and chunks
        Get-ChildItem -Path $MementoDir -Exclude "checkpoints", "chunks" | Remove-Item -Recurse -Force
        # If checkpoints and chunks are empty, remove them too
        $hasCheckpoints = Get-ChildItem "$MementoDir\checkpoints" -ErrorAction SilentlyContinue
        $hasChunks = Get-ChildItem "$MementoDir\chunks" -ErrorAction SilentlyContinue
        
        if (-not $hasCheckpoints -and -not $hasChunks) {
            Remove-Item -Path $MementoDir -Recurse -Force
        } else {
            Write-Host "ℹ️  Data preserved in: $MementoDir" -ForegroundColor Yellow
            if ($hasCheckpoints) {
                Write-Host "     - Checkpoints: $MementoDir\checkpoints" -ForegroundColor Yellow
            }
            if ($hasChunks) {
                Write-Host "     - Chunks: $MementoDir\chunks" -ForegroundColor Yellow
            }
        }
    } else {
        Remove-Item -Path $MementoDir -Recurse -Force
    }
    Write-Host "✓ Removed Claude Memento files" -ForegroundColor Green
}

# Remove batch wrapper
if (Test-Path "$env:USERPROFILE\claude-memento.bat") {
    Remove-Item -Path "$env:USERPROFILE\claude-memento.bat" -Force
    Write-Host "✓ Removed Windows wrapper" -ForegroundColor Green
}

# Clean up empty directories
if ((Test-Path $CommandsDir) -and -not (Get-ChildItem $CommandsDir)) {
    Remove-Item -Path $CommandsDir -Force
}

# Show summary
Write-Host ""
Write-Host "✅ Claude Memento uninstalled successfully!" -ForegroundColor Green
Write-Host ""

# Show backup locations if applicable
if (Test-Path "$ClaudeDir\CLAUDE.md.uninstall.backup") {
    Write-Host "CLAUDE.md backup: $ClaudeDir\CLAUDE.md.uninstall.backup"
}

if ($KeepData -and $CheckpointBackupDir) {
    Write-Host "Checkpoint backup: $CheckpointBackupDir"
}

# Check for installation backups
Write-Host ""
Write-Host "📦 Installation backups:" -ForegroundColor Blue
$backups = Get-ChildItem -Path "$env:USERPROFILE" -Filter ".claude_backup_*" -Directory -ErrorAction SilentlyContinue

if ($backups) {
    foreach ($backup in $backups) {
        $metadataPath = Join-Path $backup.FullName ".backup_metadata"
        if (Test-Path $metadataPath) {
            Write-Host "   $($backup.FullName)" -ForegroundColor Green
            $metadata = Get-Content $metadataPath
            $backupDate = $metadata | Select-String "Backup date:" | ForEach-Object { $_.Line }
            if ($backupDate) {
                Write-Host "      $backupDate"
            }
            $restoreScript = Join-Path $backup.FullName "restore.ps1"
            if (Test-Path $restoreScript) {
                Write-Host "      Restore command: $restoreScript"
            }
        }
    }
} else {
    Write-Host "   No installation backups found"
}

Write-Host ""
Write-Host "Thank you for using Claude Memento!"
Write-Host ""
Write-Host "📦 For support or to reinstall:" -ForegroundColor Blue
Write-Host "  - Documentation: https://github.com/user/claude-memento"
Write-Host "  - Reinstall: .\install.ps1"
if ($KeepData) {
    Write-Host "  - Your data backups are preserved and can be restored"
}