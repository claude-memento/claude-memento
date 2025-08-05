# Claude Memento PowerShell Uninstall Script
# Safe removal with data preservation options

param(
    [switch]$KeepData
)

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
        Write-Host "Removing Claude Memento section from CLAUDE.md..." -ForegroundColor Yellow
        
        # Create backup before modification
        Copy-Item -Path "$ClaudeDir\CLAUDE.md" -Destination "$ClaudeDir\CLAUDE.md.uninstall.backup" -Force
        
        # Read content and remove Claude Memento section
        $content = Get-Content "$ClaudeDir\CLAUDE.md" -Raw
        
        # Remove section between markers including the blank line before
        $pattern = "(?:\r?\n)?\r?\n$([regex]::Escape($BeginMarker))[\s\S]*?$([regex]::Escape($EndMarker))"
        $newContent = $content -replace $pattern, ""
        
        # Save the modified content
        $newContent | Out-File -FilePath "$ClaudeDir\CLAUDE.md" -Encoding UTF8 -NoNewline
        
        Write-Host "✓ Removed Claude Memento section from CLAUDE.md" -ForegroundColor Green
    }
}

# Function to preserve data
function Backup-Data {
    if ((Test-Path "$MementoDir\checkpoints") -and (Get-ChildItem "$MementoDir\checkpoints" -ErrorAction SilentlyContinue)) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupDir = "$env:USERPROFILE\claude-memento-backup-$timestamp"
        Write-Host "Preserving checkpoint data..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        Copy-Item -Path "$MementoDir\checkpoints" -Destination $backupDir -Recurse -Force
        Write-Host "✓ Checkpoint data backed up to: $backupDir" -ForegroundColor Green
        $script:CheckpointBackupDir = $backupDir
    }
}

# Check if installed
if (-not (Test-Installation)) {
    Write-Host "Error: Claude Memento is not installed!" -ForegroundColor Red
    exit 1
}

# Confirm uninstallation
Write-Host "This will uninstall Claude Memento." -ForegroundColor Yellow
if ($KeepData) {
    Write-Host "Checkpoint data will be preserved."
} else {
    Write-Host "⚠️  All checkpoint data will be deleted!" -ForegroundColor Red
    Write-Host "Use '-KeepData' to preserve checkpoints."
}
Write-Host ""

$response = Read-Host "Continue? (y/N)"
if ($response -ne 'y' -and $response -ne 'Y') {
    Write-Host "Uninstall cancelled."
    exit 0
}

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

# Remove main installation
Write-Host "Removing Claude Memento files..." -ForegroundColor Yellow
if (Test-Path $MementoDir) {
    if ($KeepData) {
        # Remove everything except checkpoints
        Get-ChildItem -Path $MementoDir -Exclude "checkpoints" | Remove-Item -Recurse -Force
        # If checkpoints is empty, remove it too
        if (-not (Get-ChildItem "$MementoDir\checkpoints" -ErrorAction SilentlyContinue)) {
            Remove-Item -Path $MementoDir -Recurse -Force
        } else {
            Write-Host "ℹ️  Checkpoint data preserved in: $MementoDir\checkpoints" -ForegroundColor Yellow
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