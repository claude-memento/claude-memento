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
    $installed = $false
    $installationFound = @()
    
    # Check 1: CLAUDE.md marker
    if (Test-Path "$ClaudeDir\CLAUDE.md") {
        $content = Get-Content "$ClaudeDir\CLAUDE.md" -Raw -ErrorAction SilentlyContinue
        if ($content -match [regex]::Escape($BeginMarker)) {
            $installed = $true
            $installationFound += "CLAUDE.md marker"
        }
    }
    
    # Check 2: Memento directory exists
    if (Test-Path $MementoDir) {
        $installed = $true
        $installationFound += "memento directory"
    }
    
    # Check 3: Core CLI script exists
    if (Test-Path "$MementoDir\src\cli.sh") {
        $installed = $true
        $installationFound += "core CLI script"
    }
    
    # Check 4: Command directory exists
    if ((Test-Path $CMCommandsDir) -and (Get-ChildItem $CMCommandsDir -ErrorAction SilentlyContinue)) {
        $installed = $true
        $installationFound += "command files"
    }
    
    # Check 5: Wrapper scripts exist
    if (Get-ChildItem "$CommandsDir\cm-*.sh" -ErrorAction SilentlyContinue) {
        $installed = $true
        $installationFound += "wrapper scripts"
    }
    
    if ($installed) {
        Write-Host "Found existing installation components:" -ForegroundColor Yellow
        foreach ($component in $installationFound) {
            Write-Host "  - $component"
        }
        return $true
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

# Copy core files with proper structure
Write-Host "Installing core files..." -ForegroundColor Yellow
Copy-Item -Path "$ScriptDir\src" -Destination $MementoDir -Recurse -Force

# Create chunks directory for auto-chunking system
New-Item -ItemType Directory -Force -Path "$MementoDir\chunks" | Out-Null

# Copy default settings for new features
if (Test-Path "$ScriptDir\src\config\default-settings.json") {
    Copy-Item -Path "$ScriptDir\src\config\default-settings.json" -Destination "$MementoDir\config\settings.json" -Force
}

# Copy command documentation to Claude's command directory
if (Test-Path "$ScriptDir\commands\cm") {
    Write-Host "Installing command documentation..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\commands\cm" | Out-Null
    
    # Copy all .md files
    Get-ChildItem -Path "$ScriptDir\commands\cm\*.md" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination "$env:USERPROFILE\.claude\commands\cm\" -Force
        Write-Host "  ✓ Installed: $($_.Name)" -ForegroundColor Green
    }
}

# Copy markdown commands to cm namespace directory for Claude Code integration
Write-Host "Installing Claude Code integration commands..." -ForegroundColor Yellow
if (Test-Path "$ScriptDir\commands\*.md") {
    Copy-Item -Path "$ScriptDir\commands\*.md" -Destination $CMCommandsDir -Force
}

# Copy wrapper scripts to commands directory
Write-Host "Installing wrapper scripts..." -ForegroundColor Yellow
Get-ChildItem -Path "$ScriptDir\commands\cm-*.sh" -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $CommandsDir -Force
    Write-Host "  ✓ Installed: $($_.Name)" -ForegroundColor Green
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

# Function to safely remove existing Claude Memento sections
function Remove-ExistingMementoSections {
    $tempFile = "$ClaudeDir\CLAUDE.md.install.tmp"
    $removedCount = 0
    
    # Remove all existing Claude Memento sections (could be multiple due to previous issues)
    while ((Get-Content "$ClaudeDir\CLAUDE.md" -Raw -ErrorAction SilentlyContinue) -match [regex]::Escape($BeginMarker)) {
        $content = Get-Content "$ClaudeDir\CLAUDE.md" -Raw
        
        # Remove section between markers including the blank line before
        $pattern = "(?:\r?\n)?\r?\n$([regex]::Escape($BeginMarker))[\s\S]*?$([regex]::Escape($EndMarker))"
        $newContent = $content -replace $pattern, ""
        
        $newContent | Out-File -FilePath "$ClaudeDir\CLAUDE.md" -Encoding UTF8 -NoNewline
        $removedCount++
        
        # Safety check to prevent infinite loop
        if ($removedCount -gt 10) {
            Write-Host "Warning: Removed $removedCount Claude Memento sections. Stopping to prevent infinite loop." -ForegroundColor Red
            break
        }
    }
    
    if ($removedCount -gt 0) {
        Write-Host "✓ Removed $removedCount existing Claude Memento section(s)" -ForegroundColor Yellow
    }
}

# Remove any existing Claude Memento sections first
$claudeMdContent = Get-Content "$ClaudeDir\CLAUDE.md" -Raw -ErrorAction SilentlyContinue
if ($claudeMdContent -match [regex]::Escape($BeginMarker)) {
    Write-Host "Removing existing Claude Memento sections..." -ForegroundColor Yellow
    Remove-ExistingMementoSections
}

# Add new Claude Memento section
Write-Host "Adding new Claude Memento section..." -ForegroundColor Yellow
Add-Content -Path "$ClaudeDir\CLAUDE.md" -Value ""
# Use the enhanced claude-memento-section.md if it exists, otherwise use basic
if (Test-Path "$ScriptDir\templates\claude-memento-section.md") {
    Get-Content -Path "$ScriptDir\templates\claude-memento-section.md" | Add-Content -Path "$ClaudeDir\CLAUDE.md"
} else {
    Get-Content -Path "$ScriptDir\templates\claude-section.md" | Add-Content -Path "$ClaudeDir\CLAUDE.md"
}
Write-Host "✓ CLAUDE.md updated with fresh Memento section" -ForegroundColor Green

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

# Create claude-memento.md for active context tracking
Write-Host "Creating active context tracker..." -ForegroundColor Yellow
if (-not (Test-Path "$MementoDir\claude-memento.md")) {
    # Try to copy template if it exists
    if (Test-Path "$ScriptDir\templates\claude-memento-template.md") {
        Copy-Item -Path "$ScriptDir\templates\claude-memento-template.md" -Destination "$MementoDir\claude-memento.md" -Force
    } else {
        # Create default content
        $activeContext = @"
# Claude Memento - Active Context

**Session ID**: $(Get-Date -Format 'yyyy-MM-dd-HHmm')  
**Started**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Last Update**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

---

## 📋 Current Tasks

## 🗂️ Working Files

## 💡 Key Decisions

## 🔄 Recent Context

## 📝 Session Notes

---

*This file is automatically updated by Claude Memento*
"@
        $activeContext | Out-File -FilePath "$MementoDir\claude-memento.md" -Encoding UTF8
    }
    Write-Host "✓ Active context tracker created" -ForegroundColor Green
}

# Set permissions for shell scripts (if using Git Bash)
Write-Host "Setting execute permissions..." -ForegroundColor Yellow
if (Get-Command bash -ErrorAction SilentlyContinue) {
    # Use bash to set permissions for all .sh files
    & bash -c "find '$MementoDir/src' -name '*.sh' -type f -exec chmod +x {} \; 2>/dev/null || true"
    & bash -c "chmod +x '$MementoDir/src/cli.sh' 2>/dev/null || true"
    & bash -c "chmod +x '$MementoDir/src/bridge/claude-code-bridge.sh' 2>/dev/null || true"
    & bash -c "chmod +x '$MementoDir/src/commands/chunk-wrapper.js' 2>/dev/null || true"
    & bash -c "chmod +x '$MementoDir/src/chunk/'*.js 2>/dev/null || true"
    & bash -c "chmod +x '$MementoDir/src/hooks/'*.sh 2>/dev/null || true"
    Write-Host "✓ Execute permissions set for shell scripts" -ForegroundColor Green
} else {
    Write-Host "⚠ Git Bash not found. You may need to manually set execute permissions." -ForegroundColor Yellow
}

# Create batch wrapper
Write-Host "Creating Windows wrapper..." -ForegroundColor Yellow
$wrapper = @"
@echo off
bash "$MementoDir\src\cli.sh" %*
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
Write-Host "  /cm:save      - Create a checkpoint (auto-chunks if >10KB)"
Write-Host "  /cm:load      - Load context (supports smart query loading)"
Write-Host "  /cm:status    - Show memory status"
Write-Host "  /cm:last      - Show last checkpoint"
Write-Host "  /cm:list      - List all checkpoints"
Write-Host "  /cm:config    - Manage configuration"
Write-Host "  /cm:hooks     - Manage hooks"
Write-Host "  /cm:chunk     - Chunk management commands"
Write-Host "  /cm:auto-save - Configure auto-save settings"
Write-Host ""
Write-Host "Configuration: $MementoDir\config\"
Write-Host "Checkpoints:  $MementoDir\checkpoints\"
Write-Host "Reference:    $MementoDir\MEMENTO.md"
Write-Host ""
Write-Host "New Features:"
Write-Host "  ✅ Auto-chunking for large contexts (>10KB)"
Write-Host "  ✅ Smart query-based loading"
Write-Host "  ✅ Auto-save on session end"
Write-Host "  ✅ Timer-based auto-save (configurable)"
Write-Host "  ✅ TF-IDF powered search"
Write-Host ""
Write-Host "To uninstall: .\uninstall.ps1"
Write-Host "To uninstall and keep data: .\uninstall.ps1 -KeepData"