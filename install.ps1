# Claude Memento PowerShell Installation Script
# Non-destructive installation as independent extension

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = $PSScriptRoot

# Define directories
$ClaudeDir = "$env:USERPROFILE\.claude"
$MementoDir = "$ClaudeDir\memento"
$CommandsDir = "$ClaudeDir\commands"
$CMCommandsDir = "$CommandsDir\cm"

# Markers for CLAUDE.md integration
$BeginMarker = "<!-- BEGIN_CLAUDE_MEMENTO -->"
$EndMarker = "<!-- END_CLAUDE_MEMENTO -->"

Write-Host "🧠 Claude Memento Installer (PowerShell)" -ForegroundColor Blue
Write-Host "========================================"

# Function to check if already installed
function Test-Installation {
    if (Test-Path "$ClaudeDir\CLAUDE.md") {
        $content = Get-Content "$ClaudeDir\CLAUDE.md" -Raw
        if ($content -match [regex]::Escape($BeginMarker)) {
            return $true
        }
    }
    return $false
}

# Function to backup entire .claude directory
function Backup-ClaudeDirectory {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "$env:USERPROFILE\.claude_backup_$timestamp"
    
    Write-Host "Creating full backup of .claude directory..." -ForegroundColor Yellow
    
    # Create backup directory
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    
    # Copy entire .claude directory if it exists
    if (Test-Path $ClaudeDir) {
        Write-Host "Copying files..." -ForegroundColor Yellow
        Copy-Item -Path "$ClaudeDir\*" -Destination $backupDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Create metadata file
    $metadata = @"
Backup created by: Claude Memento
Backup date: $(Get-Date)
Backup type: Full directory backup
Original location: $ClaudeDir
Claude Memento version: 1.0.0
Reason: Pre-installation backup
"@
    $metadata | Out-File -FilePath "$backupDir\.backup_metadata" -Encoding UTF8
    
    # Create restore script
    $restoreScript = @'
# Claude Memento Backup Restore Script (PowerShell)

$BackupDir = $PSScriptRoot
$ClaudeDir = "$env:USERPROFILE\.claude"

Write-Host "🔄 Claude Memento Backup Restore" -ForegroundColor Blue
Write-Host "================================"
Write-Host "This will restore .claude from: $BackupDir"
Write-Host "To: $ClaudeDir"
Write-Host ""

$response = Read-Host "Continue? (y/N)"

if ($response -eq 'y' -or $response -eq 'Y') {
    # Backup current state before restore
    if (Test-Path $ClaudeDir) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        Move-Item -Path $ClaudeDir -Destination "$ClaudeDir.before_restore.$timestamp" -Force
    }
    
    # Restore backup
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
    Copy-Item -Path "$BackupDir\*" -Destination $ClaudeDir -Recurse -Force -Exclude @(".backup_metadata", "restore.ps1")
    
    Write-Host "✅ Restore completed!" -ForegroundColor Green
} else {
    Write-Host "❌ Restore cancelled." -ForegroundColor Red
}
'@
    $restoreScript | Out-File -FilePath "$backupDir\restore.ps1" -Encoding UTF8
    
    Write-Host "✓ Full backup created at: $backupDir" -ForegroundColor Green
    Write-Host "  To restore, run: $backupDir\restore.ps1" -ForegroundColor Blue
    
    # Store backup location for installation log
    $script:FullBackupPath = $backupDir
}

# Function to backup CLAUDE.md
function Backup-ClaudeMd {
    if (Test-Path "$ClaudeDir\CLAUDE.md") {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = "$ClaudeDir\CLAUDE.md.backup.$timestamp"
        Copy-Item -Path "$ClaudeDir\CLAUDE.md" -Destination $backupFile -Force
        Write-Host "✓ Backed up CLAUDE.md to: $backupFile" -ForegroundColor Green
    }
}

# Function to create minimal CLAUDE.md
function New-MinimalClaudeMd {
    New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
    Copy-Item -Path "$ScriptDir\templates\minimal-claude.md" -Destination "$ClaudeDir\CLAUDE.md" -Force
    Write-Host "✓ Created new CLAUDE.md" -ForegroundColor Green
}

# Check if already installed
if (Test-Installation) {
    Write-Host "Error: Claude Memento is already installed!" -ForegroundColor Red
    Write-Host "Use '.\uninstall.ps1' first if you want to reinstall."
    exit 1
}

# Create full backup first
Backup-ClaudeDirectory

# Handle CLAUDE.md
Write-Host "Checking CLAUDE.md..." -ForegroundColor Yellow
if (Test-Path "$ClaudeDir\CLAUDE.md") {
    Backup-ClaudeMd
} else {
    Write-Host "CLAUDE.md not found. Creating minimal version..." -ForegroundColor Yellow
    New-MinimalClaudeMd
}

# Create memento directories
Write-Host "Creating directories..." -ForegroundColor Yellow
@("$MementoDir\checkpoints", "$MementoDir\config", "$MementoDir\logs", $CommandsDir, $CMCommandsDir) | ForEach-Object {
    New-Item -ItemType Directory -Force -Path $_ | Out-Null
}

# Copy core files
Write-Host "Installing core files..." -ForegroundColor Yellow
Copy-Item -Path "$ScriptDir\src\*" -Destination $MementoDir -Recurse -Force

# Copy markdown commands to cm namespace directory
Write-Host "Installing Claude Code integration commands..." -ForegroundColor Yellow
if (Test-Path "$ScriptDir\commands\*.md") {
    Copy-Item -Path "$ScriptDir\commands\*.md" -Destination $CMCommandsDir -Force
}

# Copy template files as memento reference files
Write-Host "Installing reference documentation..." -ForegroundColor Yellow
@("MEMENTO.md", "COMMANDS.md", "PRINCIPLES.md", "RULES.md", "HOOKS.md") | ForEach-Object {
    Copy-Item -Path "$ScriptDir\templates\$_" -Destination "$MementoDir\$_" -Force
}

# Create default configuration
Write-Host "Creating default configuration..." -ForegroundColor Yellow
$config = @'
{
  "checkpoint": {
    "retention": 10,
    "auto_save": true,
    "interval": 900,
    "strategy": "full"
  },
  "memory": {
    "max_size": "10MB",
    "compression": true,
    "format": "markdown"
  },
  "session": {
    "timeout": 300,
    "auto_restore": true
  },
  "integration": {
    "superclaude": true,
    "command_prefix": "cm:"
  }
}
'@
$config | Out-File -FilePath "$MementoDir\config\default.json" -Encoding UTF8

# Add Claude Memento section to CLAUDE.md
Write-Host "Updating CLAUDE.md..." -ForegroundColor Yellow
Add-Content -Path "$ClaudeDir\CLAUDE.md" -Value ""
Get-Content -Path "$ScriptDir\templates\claude-section.md" | Add-Content -Path "$ClaudeDir\CLAUDE.md"

# Create hooks configuration
Write-Host "Creating hooks configuration..." -ForegroundColor Yellow
$hooks = @'
{
  "pre-save": [],
  "post-save": [],
  "pre-load": [],
  "post-load": [],
  "pre-delete": []
}
'@
$hooks | Out-File -FilePath "$MementoDir\config\hooks.json" -Encoding UTF8

# Create batch wrapper
Write-Host "Creating Windows wrapper..." -ForegroundColor Yellow
$wrapper = @"
@echo off
bash "$MementoDir\cli.sh" %*
"@
$wrapper | Out-File -FilePath "$env:USERPROFILE\claude-memento.bat" -Encoding ASCII

# Create installation log
Write-Host "Creating installation log..." -ForegroundColor Yellow
$installLog = @"
Installation Date: $(Get-Date)
Version: 1.0.0
Install Directory: $MementoDir
Command Directory: $CMCommandsDir
Marker: $BeginMarker
Full Backup: $FullBackupPath
CLAUDE.md Backup: $(Get-ChildItem "$ClaudeDir\CLAUDE.md.backup.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName)
"@
$installLog | Out-File -FilePath "$MementoDir\.install.log" -Encoding UTF8

Write-Host "🎉 Claude Memento installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Full backup created:" -ForegroundColor Blue
Write-Host "   $FullBackupPath"
Write-Host ""
Write-Host "Available commands:"
Write-Host "  /cm:save    - Create a checkpoint"
Write-Host "  /cm:load    - Load context from memory"
Write-Host "  /cm:status  - Show memory status"
Write-Host "  /cm:last    - Show last checkpoint"
Write-Host "  /cm:list    - List all checkpoints"
Write-Host "  /cm:config  - Manage configuration"
Write-Host "  /cm:hooks   - Manage hooks"
Write-Host ""
Write-Host "Configuration: $MementoDir\config\"
Write-Host "Checkpoints:  $MementoDir\checkpoints\"
Write-Host "Reference:    $MementoDir\MEMENTO.md"
Write-Host ""
Write-Host "To uninstall: .\uninstall.ps1"
Write-Host "To uninstall and keep data: .\uninstall.ps1 -KeepData"