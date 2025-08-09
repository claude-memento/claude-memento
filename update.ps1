# Claude Memento Update Script for PowerShell
# Updates Claude Memento to the latest version while preserving user data
# Principle: "Move Nothing, Replace Only" - User data stays in place, only system files are updated

[CmdletBinding()]
param(
    [Parameter(HelpMessage="Show what would be updated without making changes")]
    [switch]$DryRun,
    
    [Parameter(HelpMessage="Force update even if already on latest version")]
    [switch]$Force,
    
    [Parameter(HelpMessage="Show detailed output")]
    [switch]$Verbose,
    
    [Parameter(HelpMessage="Only create backup without updating")]
    [switch]$BackupOnly,
    
    [Parameter(HelpMessage="Restore from previous backup")]
    [switch]$Restore,
    
    [Parameter(HelpMessage="Only check version without updating")]
    [switch]$CheckVersion,
    
    [Parameter(HelpMessage="Skip backup creation (not recommended)")]
    [switch]$SkipBackup,
    
    [Parameter(HelpMessage="Path to new version source")]
    [string]$SourcePath = $PSScriptRoot,
    
    [Parameter(HelpMessage="Update only specific items (comma-separated)")]
    [string]$Selective = "",
    
    [Parameter(HelpMessage="Skip specific items during update (comma-separated)")]
    [string]$Skip = "",
    
    [Parameter(HelpMessage="Show help message")]
    [switch]$Help
)

# Script configuration
$ErrorActionPreference = "Stop"
$Script:ScriptName = "Claude Memento Update"
$Script:ScriptVersion = "1.0.0"

# Source version management functions
$VersionScript = Join-Path $PSScriptRoot "src\version.ps1"
if (Test-Path $VersionScript) {
    . $VersionScript
    $Script:VersionManagementAvailable = $true
} else {
    $Script:VersionManagementAvailable = $false
}

# System directories
$Script:ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$Script:MementoDir = Join-Path $Script:ClaudeDir "memento"
$Script:BackupDir = Join-Path $Script:MementoDir ".backup"
$Script:UpdateLog = Join-Path $Script:MementoDir "update.log"

# User data directories (preserve these)
$Script:UserDataDirs = @(
    "checkpoints",
    "chunks",
    "settings"
)

# System directories (replace these)
$Script:SystemDirs = @(
    "src",
    "commands",
    "templates"
)

# System files (replace these)
$Script:SystemFiles = @(
    "cm.ps1",
    "claude-memento.ps1"
)

# Function: Write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [ConsoleColor]$Color = "White",
        [switch]$NoNewline
    )
    
    $previousColor = [Console]::ForegroundColor
    [Console]::ForegroundColor = $Color
    if ($NoNewline) {
        Write-Host $Message -NoNewline
    } else {
        Write-Host $Message
    }
    [Console]::ForegroundColor = $previousColor
    
    # Also write to log
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $Script:UpdateLog -Value "$timestamp - $Message" -ErrorAction SilentlyContinue
}

# Function: Print error and exit
function Write-ErrorAndExit {
    param([string]$Message)
    
    Write-ColorOutput "❌ Error: $Message" -Color Red
    exit 1
}

# Function: Print warning
function Write-Warning {
    param([string]$Message)
    
    Write-ColorOutput "⚠️  Warning: $Message" -Color Yellow
}

# Function: Print info
function Write-Info {
    param([string]$Message)
    
    Write-ColorOutput "ℹ️  $Message" -Color Cyan
}

# Function: Print success
function Write-Success {
    param([string]$Message)
    
    Write-ColorOutput "✅ $Message" -Color Green
}

# Function: Show usage
function Show-Usage {
    $usage = @"
Usage: .\update.ps1 [OPTIONS]

Updates Claude Memento to the latest version while preserving user data.

OPTIONS:
    -Help               Show this help message
    -DryRun             Show what would be updated without making changes
    -Force              Force update even if already on latest version
    -Verbose            Show detailed output
    -BackupOnly         Only create backup without updating
    -Restore            Restore from previous backup
    -CheckVersion       Only check version without updating
    -SkipBackup         Skip backup creation (not recommended)
    -SourcePath PATH    Path to new version source (default: current directory)
    -Selective ITEMS    Update only specific items (comma-separated)
                       Available: src,commands,templates,wrappers,claude-md
    -Skip ITEMS        Skip specific items during update (comma-separated)

EXAMPLES:
    .\update.ps1                         # Normal update with backup (all components)
    .\update.ps1 -DryRun                 # Preview what would be updated
    .\update.ps1 -Selective "src,commands"  # Update only src and commands directories
    .\update.ps1 -Skip "claude-md"       # Update everything except CLAUDE.md
    .\update.ps1 -Force                  # Force update even if on latest version
    .\update.ps1 -Restore                # Restore from previous backup

"@
    Write-Host $usage
}

# Function: Check if Claude Memento is installed
function Test-Installation {
    if (-not (Test-Path $Script:MementoDir)) {
        Write-ErrorAndExit "Claude Memento is not installed. Please run install.ps1 first."
    }
    
    if (-not (Test-Path (Join-Path $Script:MementoDir "cm.ps1"))) {
        Write-ErrorAndExit "Claude Memento installation appears to be corrupted. Missing cm.ps1"
    }
}

# Function: Get current version (uses version.ps1 if available)
function Get-CurrentVersion {
    if ($Script:VersionManagementAvailable -and (Get-Command Get-InstalledVersion -ErrorAction SilentlyContinue)) {
        Get-InstalledVersion
    } else {
        $versionFile = Join-Path $Script:MementoDir "VERSION"
        if (Test-Path $versionFile) {
            Get-Content $versionFile -Raw | ForEach-Object { $_.Trim() }
        } elseif (Test-Path "$Script:MementoDir\.install.log") {
            $log = Get-Content "$Script:MementoDir\.install.log"
            $versionLine = $log | Where-Object { $_ -match "^Version:" }
            if ($versionLine) {
                ($versionLine -split ' ')[1]
            } else {
                "unknown"
            }
        } else {
            "unknown"
        }
    }
}

# Function: Get new version
function Get-NewVersion {
    $versionFile = Join-Path $SourcePath "VERSION"
    if (Test-Path $versionFile) {
        Get-Content $versionFile -Raw | ForEach-Object { $_.Trim() }
    } else {
        "unknown"
    }
}

# Function: Compare versions
function Compare-Versions {
    param(
        [string]$Current,
        [string]$New
    )
    
    # If either version is unknown, recommend update
    if ($Current -eq "unknown" -or $New -eq "unknown") {
        return $false
    }
    
    # Simple string comparison for now
    # TODO: Implement proper semantic versioning comparison
    return $Current -eq $New
}

# Function: Create backup
function New-Backup {
    Write-Info "Creating backup of current installation..."
    
    # Create backup directory with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $Script:BackupDir $timestamp
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would create backup at: $backupPath"
        return
    }
    
    # Create backup directory structure
    try {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    } catch {
        Write-ErrorAndExit "Failed to create backup directory: $_"
    }
    
    # Backup system directories
    foreach ($dir in $Script:SystemDirs) {
        $sourceDir = Join-Path $Script:MementoDir $dir
        if (Test-Path $sourceDir) {
            if ($Verbose) { Write-Info "Backing up $dir..." }
            try {
                Copy-Item -Path $sourceDir -Destination $backupPath -Recurse -Force
            } catch {
                Write-ErrorAndExit "Failed to backup ${dir}: $_"
            }
        }
    }
    
    # Backup system files
    foreach ($file in $Script:SystemFiles) {
        $sourceFile = Join-Path $Script:MementoDir $file
        if (Test-Path $sourceFile) {
            if ($Verbose) { Write-Info "Backing up $file..." }
            try {
                Copy-Item -Path $sourceFile -Destination $backupPath -Force
            } catch {
                Write-ErrorAndExit "Failed to backup ${file}: $_"
            }
        }
    }
    
    # Backup VERSION file if exists
    $versionFile = Join-Path $Script:MementoDir "VERSION"
    if (Test-Path $versionFile) {
        try {
            Copy-Item -Path $versionFile -Destination $backupPath -Force
        } catch {
            Write-Warning "Failed to backup VERSION file: $_"
        }
    }
    
    # Create backup metadata
    $metadata = @{
        timestamp = $timestamp
        date = (Get-Date -Format "o")
        version = Get-CurrentVersion
        directories = $Script:SystemDirs
        files = $Script:SystemFiles
        backup_size = (Get-ChildItem -Path $backupPath -Recurse | Measure-Object -Property Length -Sum).Sum
    }
    
    $metadataPath = Join-Path $backupPath "metadata.json"
    $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path $metadataPath
    
    # Clean up old backups (keep only last 5)
    Remove-OldBackups
    
    # Store current backup path for potential rollback
    $Script:CurrentBackup = $backupPath
    
    Write-Success "Backup created at: $backupPath"
}

# Function: Clean up old backups
function Remove-OldBackups {
    $maxBackups = 5
    
    if (-not (Test-Path $Script:BackupDir)) {
        return
    }
    
    # Get list of backups sorted by date (oldest first)
    $backups = Get-ChildItem -Path $Script:BackupDir -Directory |
        Where-Object { $_.Name -match '^\d{8}_\d{6}$' } |
        Sort-Object Name
    
    $backupCount = $backups.Count
    
    if ($backupCount -gt $maxBackups) {
        $removeCount = $backupCount - $maxBackups
        if ($Verbose) { Write-Info "Removing $removeCount old backup(s)..." }
        
        for ($i = 0; $i -lt $removeCount; $i++) {
            $oldBackup = $backups[$i]
            if ($DryRun) {
                Write-Info "[DRY RUN] Would remove old backup: $($oldBackup.Name)"
            } else {
                try {
                    Remove-Item -Path $oldBackup.FullName -Recurse -Force
                    if ($Verbose) { Write-Info "Removed: $($oldBackup.Name)" }
                } catch {
                    Write-Warning "Failed to remove old backup: $_"
                }
            }
        }
    }
}

# Function: List available backups
function Get-Backups {
    if (-not (Test-Path $Script:BackupDir)) {
        Write-Info "No backups found"
        return $null
    }
    
    $backups = Get-ChildItem -Path $Script:BackupDir -Directory |
        Where-Object { $_.Name -match '^\d{8}_\d{6}$' } |
        Sort-Object Name -Descending
    
    if ($backups.Count -eq 0) {
        Write-Info "No backups found"
        return $null
    }
    
    Write-Info "Available backups:"
    foreach ($backup in $backups) {
        $metadataFile = Join-Path $backup.FullName "metadata.json"
        
        if (Test-Path $metadataFile) {
            try {
                $metadata = Get-Content $metadataFile -Raw | ConvertFrom-Json
                $size = [math]::Round($metadata.backup_size / 1MB, 2)
                Write-Host "  - $($backup.Name) (v$($metadata.version), ${size}MB)"
            } catch {
                Write-Host "  - $($backup.Name)"
            }
        } else {
            Write-Host "  - $($backup.Name)"
        }
    }
    
    return $backups
}

# Function: Get latest backup
function Get-LatestBackup {
    if (-not (Test-Path $Script:BackupDir)) {
        return $null
    }
    
    $latest = Get-ChildItem -Path $Script:BackupDir -Directory |
        Where-Object { $_.Name -match '^\d{8}_\d{6}$' } |
        Sort-Object Name -Descending |
        Select-Object -First 1
    
    if ($latest) {
        return $latest.FullName
    }
    
    return $null
}

# Function: Restore from backup
function Restore-Backup {
    param(
        [string]$BackupPath = ""
    )
    
    Write-Info "Restoring from backup..."
    
    # Get backup to restore
    if ($BackupPath -eq "") {
        # Use latest backup
        $BackupPath = Get-LatestBackup
        if (-not $BackupPath) {
            Write-ErrorAndExit "No backups available to restore"
        }
    }
    
    if (-not (Test-Path $BackupPath)) {
        Write-ErrorAndExit "Backup not found: $BackupPath"
    }
    
    Write-Info "Restoring from: $(Split-Path $BackupPath -Leaf)"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would restore from: $BackupPath"
        return
    }
    
    # Verify backup integrity
    $metadataFile = Join-Path $BackupPath "metadata.json"
    if (-not (Test-Path $metadataFile)) {
        Write-Warning "Backup metadata not found, proceeding with caution..."
    }
    
    # Create temporary backup of current state (for rollback if restore fails)
    $tempBackup = Join-Path $Script:BackupDir ".temp_restore_$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-Item -ItemType Directory -Path $tempBackup -Force | Out-Null
    
    # Backup current system files before restore
    foreach ($dir in $Script:SystemDirs) {
        $currentDir = Join-Path $Script:MementoDir $dir
        if (Test-Path $currentDir) {
            Copy-Item -Path $currentDir -Destination $tempBackup -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    foreach ($file in $Script:SystemFiles) {
        $currentFile = Join-Path $Script:MementoDir $file
        if (Test-Path $currentFile) {
            Copy-Item -Path $currentFile -Destination $tempBackup -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Restore from backup
    $restoreFailed = $false
    
    # Restore system directories
    foreach ($dir in $Script:SystemDirs) {
        $backupDir = Join-Path $BackupPath $dir
        if (Test-Path $backupDir) {
            if ($Verbose) { Write-Info "Restoring $dir..." }
            try {
                $targetDir = Join-Path $Script:MementoDir $dir
                if (Test-Path $targetDir) {
                    Remove-Item -Path $targetDir -Recurse -Force
                }
                Copy-Item -Path $backupDir -Destination $Script:MementoDir -Recurse -Force
            } catch {
                Write-Warning "Failed to restore ${dir}: $_"
                $restoreFailed = $true
            }
        }
    }
    
    # Restore system files
    foreach ($file in $Script:SystemFiles) {
        $backupFile = Join-Path $BackupPath $file
        if (Test-Path $backupFile) {
            if ($Verbose) { Write-Info "Restoring $file..." }
            try {
                Copy-Item -Path $backupFile -Destination $Script:MementoDir -Force
            } catch {
                Write-Warning "Failed to restore ${file}: $_"
                $restoreFailed = $true
            }
        }
    }
    
    # Restore VERSION file if exists
    $backupVersion = Join-Path $BackupPath "VERSION"
    if (Test-Path $backupVersion) {
        try {
            Copy-Item -Path $backupVersion -Destination $Script:MementoDir -Force
        } catch {
            Write-Warning "Failed to restore VERSION file: $_"
        }
    }
    
    # Check if restore failed
    if ($restoreFailed) {
        Write-Warning "Restore encountered errors, attempting rollback..."
        
        # Rollback from temp backup
        foreach ($dir in $Script:SystemDirs) {
            $tempDir = Join-Path $tempBackup $dir
            if (Test-Path $tempDir) {
                $targetDir = Join-Path $Script:MementoDir $dir
                if (Test-Path $targetDir) {
                    Remove-Item -Path $targetDir -Recurse -Force -ErrorAction SilentlyContinue
                }
                Copy-Item -Path $tempDir -Destination $Script:MementoDir -Recurse -Force
            }
        }
        
        foreach ($file in $Script:SystemFiles) {
            $tempFile = Join-Path $tempBackup $file
            if (Test-Path $tempFile) {
                Copy-Item -Path $tempFile -Destination $Script:MementoDir -Force
            }
        }
        
        Remove-Item -Path $tempBackup -Recurse -Force
        Write-ErrorAndExit "Restore failed and was rolled back"
    }
    
    # Clean up temp backup
    Remove-Item -Path $tempBackup -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Success "Backup restored successfully"
}

# Function: Check if item should be updated
function Test-ShouldUpdate {
    param([string]$Item)
    
    # Check if item is in skip list
    if ($Skip -ne "") {
        $skipList = $Skip -split ','
        if ($skipList -contains $Item) {
            return $false
        }
    }
    
    # Check selective update list
    if ($Selective -ne "") {
        $selectiveList = $Selective -split ','
        if ($selectiveList -contains $Item) {
            return $true
        } else {
            return $false
        }
    }
    
    return $true
}

# Function: Update system files
function Update-SystemFiles {
    Write-Info "Updating system files..."
    
    $sourceDir = $SourcePath
    $updateFailed = $false
    $updatedItems = @()
    $skippedItems = @()
    
    if (-not (Test-Path $sourceDir)) {
        Write-ErrorAndExit "Source directory not found: $sourceDir"
    }
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would update files from: $sourceDir"
    }
    
    # Show update mode
    if ($Selective -ne "") {
        Write-Info "Selective update mode: $Selective"
    } elseif ($Skip -ne "") {
        Write-Info "Skipping items: $Skip"
    } else {
        Write-Info "Full update mode: all components"
    }
    
    # Update system directories
    foreach ($dir in $Script:SystemDirs) {
        if (-not (Test-ShouldUpdate -Item $dir)) {
            if ($Verbose) { Write-Info "Skipping $dir (excluded by user)" }
            $skippedItems += $dir
            continue
        }
        $source = Join-Path $sourceDir $dir
        $target = Join-Path $Script:MementoDir $dir
        
        if (Test-Path $source) {
            if ($Verbose) { Write-Info "Updating $dir..." }
            
            if ($DryRun) {
                Write-Info "[DRY RUN] Would update: $dir"
            } else {
                # Remove old directory and copy new one
                if (Test-Path $target) {
                    try {
                        Remove-Item -Path $target -Recurse -Force
                    } catch {
                        Write-Warning "Failed to remove old ${dir}: $_"
                        $updateFailed = $true
                        continue
                    }
                }
                
                try {
                    Copy-Item -Path $source -Destination $Script:MementoDir -Recurse -Force
                    $updatedItems += $dir
                } catch {
                    Write-Warning "Failed to update ${dir}: $_"
                    $updateFailed = $true
                    continue
                }
            }
        } else {
            if ($Verbose) { Write-Info "Skipping $dir (not found in source)" }
        }
    }
    
    # Update system files
    foreach ($file in $Script:SystemFiles) {
        $source = Join-Path $sourceDir $file
        $target = Join-Path $Script:MementoDir $file
        
        if (Test-Path $source) {
            if ($Verbose) { Write-Info "Updating $file..." }
            
            if ($DryRun) {
                Write-Info "[DRY RUN] Would update: $file"
            } else {
                try {
                    Copy-Item -Path $source -Destination $Script:MementoDir -Force
                    $updatedItems += $file
                } catch {
                    Write-Warning "Failed to update ${file}: $_"
                    $updateFailed = $true
                    continue
                }
            }
        } else {
            if ($Verbose) { Write-Info "Skipping $file (not found in source)" }
        }
    }
    
    # Update VERSION file
    $versionSource = Join-Path $sourceDir "VERSION"
    if (Test-Path $versionSource) {
        if ($DryRun) {
            Write-Info "[DRY RUN] Would update: VERSION"
        } else {
            try {
                Copy-Item -Path $versionSource -Destination $Script:MementoDir -Force
                $updatedItems += "VERSION"
            } catch {
                Write-Warning "Failed to update VERSION file: $_"
            }
        }
    }
    
    # Update wrapper scripts in parent directory
    if (Test-ShouldUpdate -Item "wrappers") {
        Update-WrapperScripts -SourceDir $sourceDir
    } else {
        if ($Verbose) { Write-Info "Skipping wrapper scripts (excluded by user)" }
        $skippedItems += "wrappers"
    }
    
    # Update agent files
    if (Test-ShouldUpdate -Item "agents") {
        Update-AgentFiles -SourceDir $sourceDir
        $updatedItems += "agents"
    } else {
        if ($Verbose) { Write-Info "Skipping agent files (excluded by user)" }
        $skippedItems += "agents"
    }
    
    # Report results
    if ($updatedItems.Count -gt 0) {
        Write-Info "Updated items: $($updatedItems -join ', ')"
    }
    
    if ($skippedItems.Count -gt 0) {
        Write-Info "Skipped items: $($skippedItems -join ', ')"
    }
    
    if ($updateFailed) {
        Write-Warning "Some files failed to update. Check the log for details."
        return $false
    }
    
    Write-Success "System files updated successfully"
    return $true
}

# Function: Update wrapper scripts
function Update-WrapperScripts {
    param(
        [string]$SourceDir
    )
    
    # List of wrapper scripts that should be in ~/.claude/
    $wrapperScripts = @(
        "cm",
        "claude-memento"
    )
    
    foreach ($script in $wrapperScripts) {
        $sourceFile = Join-Path $SourceDir "wrappers" "${script}.ps1"
        $targetFile = Join-Path $Script:ClaudeDir $script
        
        # If source doesn't have wrappers dir, check root
        if (-not (Test-Path $sourceFile)) {
            $sourceFile = Join-Path $SourceDir "${script}.ps1"
        }
        
        if (Test-Path $sourceFile) {
            if ($DryRun) {
                Write-Info "[DRY RUN] Would update wrapper: $script"
            } else {
                if ($Verbose) { Write-Info "Updating wrapper script: $script" }
                try {
                    Copy-Item -Path $sourceFile -Destination $targetFile -Force
                } catch {
                    Write-Warning "Failed to update wrapper script ${script}: $_"
                }
            }
        }
    }
}

# Function: Update agent files
function Update-AgentFiles {
    param(
        [string]$SourceDir
    )
    
    $agentsSourceDir = Join-Path $SourceDir ".claude\agents"
    
    if (-not (Test-Path $agentsSourceDir)) {
        if ($Verbose) { Write-Info "No agents directory found in source, skipping agent files update" }
        return
    }
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would update agent files"
    } else {
        Write-Info "Updating agent files..."
        if (-not (Test-Path "$Script:ClaudeDir\agents")) {
            New-Item -Path "$Script:ClaudeDir\agents" -ItemType Directory -Force | Out-Null
        }
    }
    
    Get-ChildItem -Path "$agentsSourceDir\*.md" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $agentName = $_.Name
        $targetFile = Join-Path "$Script:ClaudeDir\agents" $agentName
        
        if ($DryRun) {
            Write-Info "[DRY RUN] Would update agent: $agentName"
        } else {
            if ($Verbose) { Write-Info "Updating agent file: $agentName" }
            try {
                Copy-Item -Path $_.FullName -Destination $targetFile -Force
            } catch {
                Write-Warning "Failed to update agent file ${agentName}: $_"
            }
        }
    }
}

# Function: Verify update integrity
function Test-UpdateIntegrity {
    Write-Info "Verifying update integrity..."
    
    $verificationFailed = $false
    
    # Check system directories exist
    foreach ($dir in $Script:SystemDirs) {
        $dirPath = Join-Path $Script:MementoDir $dir
        if (-not (Test-Path $dirPath)) {
            Write-Warning "Missing directory after update: $dir"
            $verificationFailed = $true
        }
    }
    
    # Check system files exist
    foreach ($file in $Script:SystemFiles) {
        $filePath = Join-Path $Script:MementoDir $file
        if (-not (Test-Path $filePath)) {
            Write-Warning "Missing file after update: $file"
            $verificationFailed = $true
        }
    }
    
    # Check wrapper scripts
    $cmWrapper = Join-Path $Script:ClaudeDir "cm"
    if (-not (Test-Path $cmWrapper)) {
        Write-Warning "Wrapper script 'cm' is missing"
        $verificationFailed = $true
    }
    
    if ($verificationFailed) {
        return $false
    }
    
    Write-Success "Update verification passed"
    return $true
}

# Function: Update CLAUDE.md
function Update-ClaudeMd {
    Write-Info "Updating CLAUDE.md integration..."
    
    if (-not (Test-ShouldUpdate -Item "claude-md")) {
        if ($Verbose) { Write-Info "Skipping CLAUDE.md update (excluded by user)" }
        return $true
    }
    
    $claudeMd = Join-Path $Script:ClaudeDir "CLAUDE.md"
    $sourceTemplate = Join-Path $SourcePath "templates" "claude-memento-section.md"
    $beginMarker = "<!-- Claude Memento Integration -->"
    $endMarker = "<!-- End Claude Memento Integration -->"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would update CLAUDE.md integration"
        return $true
    }
    
    # Check if CLAUDE.md exists
    if (-not (Test-Path $claudeMd)) {
        Write-Warning "CLAUDE.md not found, skipping update"
        return $true
    }
    
    # Check if new template exists
    if (-not (Test-Path $sourceTemplate)) {
        if ($Verbose) { Write-Info "No new CLAUDE.md template found" }
        return $true
    }
    
    # Backup CLAUDE.md before modification
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "${claudeMd}.backup.$timestamp"
    try {
        Copy-Item -Path $claudeMd -Destination $backupFile -Force
        if ($Verbose) { Write-Info "Backed up CLAUDE.md to: $backupFile" }
    } catch {
        Write-Warning "Failed to backup CLAUDE.md: $_"
        return $false
    }
    
    try {
        # Read current CLAUDE.md content
        $content = Get-Content $claudeMd -Raw
        $removedCount = 0
        
        # Remove ALL existing Claude Memento sections (handle duplicates)
        while ($content -match [regex]::Escape($beginMarker)) {
            $pattern = "(?ms)" + [regex]::Escape($beginMarker) + ".*?" + [regex]::Escape($endMarker)
            $content = $content -replace $pattern, ""
            $removedCount++
            
            # Safety check to prevent infinite loop
            if ($removedCount -gt 20) {
                Write-Warning "Removed $removedCount Claude Memento sections. Stopping to prevent infinite loop."
                break
            }
        }
        
        if ($removedCount -gt 0) {
            if ($Verbose) { Write-Info "Removed $removedCount existing Claude Memento section(s)" }
        }
        
        # Clean up any extra blank lines
        $content = $content -replace "\n{3,}", "`n`n"
        $content = $content.TrimEnd()
        
        # Read new template
        $newSection = Get-Content $sourceTemplate -Raw
        
        # Add new Claude Memento section
        $updatedContent = @"
$content

$beginMarker
$newSection
$endMarker
"@
        
        # Write updated content
        Set-Content -Path $claudeMd -Value $updatedContent -NoNewline
        
        Write-Success "CLAUDE.md updated successfully"
    } catch {
        # Restore from backup on failure
        Write-Warning "Failed to update CLAUDE.md, restoring from backup: $_"
        try {
            Move-Item -Path $backupFile -Destination $claudeMd -Force
        } catch {
            Write-Warning "Failed to restore backup: $_"
        }
        return $false
    }
    
    # Clean up old backups (keep only last 5)
    Remove-OldClaudeMdBackups
    
    return $true
}

# Function: Clean up old CLAUDE.md backups
function Remove-OldClaudeMdBackups {
    $maxBackups = 5
    
    # Get list of CLAUDE.md backups sorted by date (oldest first)
    $backups = Get-ChildItem -Path $Script:ClaudeDir -Filter "CLAUDE.md.backup.*" -File |
        Sort-Object Name
    
    $backupCount = $backups.Count
    
    if ($backupCount -gt $maxBackups) {
        $removeCount = $backupCount - $maxBackups
        if ($Verbose) { Write-Info "Removing $removeCount old CLAUDE.md backup(s)..." }
        
        for ($i = 0; $i -lt $removeCount; $i++) {
            $oldBackup = $backups[$i]
            try {
                Remove-Item -Path $oldBackup.FullName -Force
                if ($Verbose) { Write-Info "Removed: $($oldBackup.Name)" }
            } catch {
                Write-Warning "Failed to remove old backup: $_"
            }
        }
    }
}

# Function: Merge configuration
function Merge-Configuration {
    Write-Info "Merging configuration..."
    
    if (-not (Test-ShouldUpdate -Item "settings")) {
        if ($Verbose) { Write-Info "Skipping configuration merge (excluded by user)" }
        return $true
    }
    
    $settingsDir = Join-Path $Script:MementoDir "settings"
    $sourceSettings = Join-Path $SourcePath "settings"
    $mergeFailed = $false
    
    # Ensure settings directory exists
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would merge configuration files"
        return $true
    }
    
    # List of config files to merge
    $configFiles = @(
        "config.json",
        "preferences.json",
        "user-settings.json"
    )
    
    foreach ($configFile in $configFiles) {
        $userConfig = Join-Path $settingsDir $configFile
        $newConfig = Join-Path $sourceSettings $configFile
        $defaultConfig = Join-Path $sourceSettings "${configFile}.default"
        
        # Skip if no new config available
        if (-not (Test-Path $newConfig) -and -not (Test-Path $defaultConfig)) {
            if ($Verbose) { Write-Info "No new config for $configFile" }
            continue
        }
        
        # Use default config if main config doesn't exist
        if (-not (Test-Path $newConfig) -and (Test-Path $defaultConfig)) {
            $newConfig = $defaultConfig
        }
        
        # If user config doesn't exist, copy new config
        if (-not (Test-Path $userConfig)) {
            if ($Verbose) { Write-Info "Creating new config: $configFile" }
            try {
                Copy-Item -Path $newConfig -Destination $userConfig -Force
            } catch {
                Write-Warning "Failed to create ${configFile}: $_"
                $mergeFailed = $true
                continue
            }
        } else {
            # Merge configurations
            if ($Verbose) { Write-Info "Merging config: $configFile" }
            
            # Create backup of user config
            try {
                Copy-Item -Path $userConfig -Destination "${userConfig}.backup" -Force
            } catch {
                Write-Warning "Failed to backup ${configFile}: $_"
            }
            
            # Perform merge (user settings take priority)
            try {
                $mergedConfig = Merge-JsonConfig -NewConfig $newConfig -UserConfig $userConfig
                $mergedConfig | Set-Content -Path "${userConfig}.tmp"
                
                if (Test-Path "${userConfig}.tmp") {
                    Move-Item -Path "${userConfig}.tmp" -Destination $userConfig -Force
                } else {
                    throw "Failed to create temp file"
                }
            } catch {
                Write-Warning "Failed to merge ${configFile}: $_"
                $mergeFailed = $true
                
                # Restore from backup
                if (Test-Path "${userConfig}.backup") {
                    Move-Item -Path "${userConfig}.backup" -Destination $userConfig -Force
                }
            }
            
            # Clean up backup if merge succeeded
            if (Test-Path "${userConfig}.backup") {
                Remove-Item -Path "${userConfig}.backup" -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    if ($mergeFailed) {
        Write-Warning "Some configuration files failed to merge"
        return $false
    }
    
    Write-Success "Configuration merged successfully"
    return $true
}

# Function: Merge JSON configurations
function Merge-JsonConfig {
    param(
        [string]$NewConfig,
        [string]$UserConfig
    )
    
    try {
        # Load JSON files
        $new = Get-Content $NewConfig -Raw | ConvertFrom-Json
        $user = Get-Content $UserConfig -Raw | ConvertFrom-Json
        
        # Convert to hashtables for easier merging
        $newHash = ConvertTo-HashtableFromPSObject -Object $new
        $userHash = ConvertTo-HashtableFromPSObject -Object $user
        
        # Merge with user config taking priority
        $merged = Merge-Hashtables -Base $newHash -Override $userHash
        
        # Convert back to JSON
        return $merged | ConvertTo-Json -Depth 10
    } catch {
        # Fallback: just return user config as-is
        if ($Verbose) { Write-Info "Using simple merge strategy (user config preserved)" }
        return Get-Content $UserConfig -Raw
    }
}

# Function: Convert PSObject to Hashtable
function ConvertTo-HashtableFromPSObject {
    param([PSObject]$Object)
    
    $hash = @{}
    if ($null -eq $Object) {
        return $hash
    }
    
    $Object.PSObject.Properties | ForEach-Object {
        $key = $_.Name
        $value = $_.Value
        
        if ($value -is [PSObject]) {
            $hash[$key] = ConvertTo-HashtableFromPSObject -Object $value
        } elseif ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
            $hash[$key] = @($value | ForEach-Object {
                if ($_ -is [PSObject]) {
                    ConvertTo-HashtableFromPSObject -Object $_
                } else {
                    $_
                }
            })
        } else {
            $hash[$key] = $value
        }
    }
    
    return $hash
}

# Function: Merge two hashtables
function Merge-Hashtables {
    param(
        [hashtable]$Base,
        [hashtable]$Override
    )
    
    $result = $Base.Clone()
    
    foreach ($key in $Override.Keys) {
        if ($Override[$key] -is [hashtable] -and $result[$key] -is [hashtable]) {
            # Recursive merge for nested objects
            $result[$key] = Merge-Hashtables -Base $result[$key] -Override $Override[$key]
        } else {
            # Override value takes priority
            $result[$key] = $Override[$key]
        }
    }
    
    return $result
}

# Function: Validate update
function Test-Update {
    Write-Info "Validating update..."
    
    # Verify file integrity
    if (-not (Test-UpdateIntegrity)) {
        Write-ErrorAndExit "Update validation failed. Files are missing or corrupted."
    }
    
    # Test basic functionality
    $cmScript = Join-Path $Script:MementoDir "cm.ps1"
    if (Test-Path $cmScript) {
        try {
            $null = Test-Path $cmScript -ErrorAction Stop
        } catch {
            Write-Warning "Error detected in cm.ps1: $_"
            return $false
        }
    }
    
    Write-Success "Update validated successfully"
    return $true
}

# Function: Main update process
function Start-Update {
    $currentVersion = Get-CurrentVersion
    $newVersion = Get-NewVersion
    
    Write-Info "Current version: $currentVersion"
    Write-Info "New version: $newVersion"
    
    # Use enhanced version checking if available
    if ($Script:VersionManagementAvailable -and (Get-Command Test-VersionCompatibility -ErrorAction SilentlyContinue)) {
        if (-not (Test-VersionCompatibility $currentVersion $newVersion)) {
            if (-not $Force) {
                Write-ErrorAndExit "Version compatibility check failed. Use -Force to override."
            } else {
                Write-Warning "Forcing update despite compatibility warnings"
            }
        }
    } elseif ((Compare-Versions -Current $currentVersion -New $newVersion) -and -not $Force) {
        Write-Info "Already on the latest version"
        return
    }
    
    if ($DryRun) {
        Write-Info "DRY RUN MODE - No changes will be made"
    }
    
    # Initialize rollback system
    Initialize-Rollback
    
    # Create backup unless skipped
    if (-not $SkipBackup) {
        if (-not (New-Backup)) {
            Write-ErrorAndExit "Backup creation failed. Aborting update."
        }
    }
    
    try {
        # Update system files
        $Script:UpdateStage = "system_files"
        if (-not (Update-SystemFiles)) {
            Write-Warning "System files update failed"
            Invoke-Rollback -Reason "System files update failed"
            return
        }
        
        # Perform version migrations if available
        if ($Script:VersionManagementAvailable -and (Get-Command Invoke-VersionMigration -ErrorAction SilentlyContinue)) {
            Write-Info "Checking for version migrations..."
            Invoke-VersionMigration $currentVersion $newVersion
        }
        
        # Save new version
        if ($Script:VersionManagementAvailable -and (Get-Command Save-Version -ErrorAction SilentlyContinue)) {
            Save-Version $newVersion
        }
        
        # Update CLAUDE.md
        $Script:UpdateStage = "claude_md"
        if (-not (Update-ClaudeMd)) {
            Write-Warning "CLAUDE.md update failed"
            Invoke-Rollback -Reason "CLAUDE.md update failed"
            return
        }
        
        # Merge configuration
        $Script:UpdateStage = "config"
        if (-not (Merge-Configuration)) {
            Write-Warning "Configuration merge failed"
            Invoke-Rollback -Reason "Configuration merge failed"
            return
        }
        
        # Validate update
        if (-not (Test-Update)) {
            Write-Warning "Update validation failed"
            Invoke-Rollback -Reason "Update validation failed"
            return
        }
        
        # Commit update (mark as successful)
        Complete-Update
        
        Write-Success "Update completed successfully!"
    } catch {
        Write-Warning "Error during update: $_"
        Invoke-Rollback -Reason "Unexpected error: $_"
        throw
    }
}

# Function: Initialize rollback system
function Initialize-Rollback {
    $Script:RollbackEnabled = $true
    $Script:RollbackPoint = $Script:CurrentBackup
    $Script:UpdateStage = "initialized"
    
    if ($Verbose) { Write-Info "Rollback system initialized" }
}

# Function: Invoke rollback
function Invoke-Rollback {
    param(
        [string]$Reason = "Unknown reason"
    )
    
    Write-Warning "Triggering rollback: $Reason"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $Script:UpdateLog -Value "$timestamp - ROLLBACK: $Reason"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would perform rollback"
        return
    }
    
    # Perform rollback based on update stage
    switch ($Script:UpdateStage) {
        "system_files" {
            Restore-SystemFiles
        }
        "claude_md" {
            Restore-SystemFiles
            Restore-ClaudeMd
        }
        "config" {
            Restore-SystemFiles
            Restore-ClaudeMd
            Restore-Configuration
        }
        default {
            Write-Info "Rolling back to backup: $($Script:RollbackPoint)"
            if ($Script:RollbackPoint -and (Test-Path $Script:RollbackPoint)) {
                Restore-Backup -BackupPath $Script:RollbackPoint
            }
        }
    }
    
    Write-Warning "Rollback completed. Update aborted."
}

# Function: Restore system files
function Restore-SystemFiles {
    Write-Info "Rolling back system files..."
    
    if ($Script:CurrentBackup -and (Test-Path $Script:CurrentBackup)) {
        # Restore system directories
        foreach ($dir in $Script:SystemDirs) {
            $backupDir = Join-Path $Script:CurrentBackup $dir
            if (Test-Path $backupDir) {
                $targetDir = Join-Path $Script:MementoDir $dir
                if (Test-Path $targetDir) {
                    Remove-Item -Path $targetDir -Recurse -Force -ErrorAction SilentlyContinue
                }
                Copy-Item -Path $backupDir -Destination $Script:MementoDir -Recurse -Force
            }
        }
        
        # Restore system files
        foreach ($file in $Script:SystemFiles) {
            $backupFile = Join-Path $Script:CurrentBackup $file
            if (Test-Path $backupFile) {
                Copy-Item -Path $backupFile -Destination $Script:MementoDir -Force
            }
        }
        
        Write-Success "System files rolled back"
    } else {
        Write-Warning "No backup available for system files rollback"
    }
}

# Function: Restore CLAUDE.md
function Restore-ClaudeMd {
    Write-Info "Rolling back CLAUDE.md..."
    
    # Find most recent CLAUDE.md backup
    $latestBackup = Get-ChildItem -Path $Script:ClaudeDir -Filter "CLAUDE.md.backup.*" -File |
        Sort-Object Name -Descending |
        Select-Object -First 1
    
    if ($latestBackup) {
        Copy-Item -Path $latestBackup.FullName -Destination (Join-Path $Script:ClaudeDir "CLAUDE.md") -Force
        Write-Success "CLAUDE.md rolled back from: $($latestBackup.Name)"
    } else {
        Write-Warning "No CLAUDE.md backup available for rollback"
    }
}

# Function: Restore configuration
function Restore-Configuration {
    Write-Info "Rolling back configuration..."
    
    $settingsDir = Join-Path $Script:MementoDir "settings"
    
    # Find and restore .backup files
    $backupFiles = Get-ChildItem -Path $settingsDir -Filter "*.json.backup" -File -ErrorAction SilentlyContinue
    
    foreach ($backupFile in $backupFiles) {
        $originalFile = $backupFile.FullName -replace '\.backup$', ''
        Move-Item -Path $backupFile.FullName -Destination $originalFile -Force
        if ($Verbose) { Write-Info "Restored: $(Split-Path $originalFile -Leaf)" }
    }
    
    Write-Success "Configuration rolled back"
}

# Function: Complete update (mark as successful)
function Complete-Update {
    $Script:RollbackEnabled = $false
    $Script:UpdateStage = "completed"
    
    # Clean up temporary files
    Get-ChildItem -Path $Script:MementoDir -Filter "*.tmp" -File -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-ChildItem -Path $Script:ClaudeDir -Filter "*.tmp" -File -ErrorAction SilentlyContinue | Remove-Item -Force
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $Script:UpdateLog -Value "$timestamp - Update completed successfully"
    
    if ($Verbose) { Write-Info "Update committed successfully" }
}

# Main execution
function Main {
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" -Color Green
    Write-ColorOutput "     Claude Memento Update Script v$Script:ScriptVersion" -Color Green
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" -Color Green
    Write-Host ""
    
    # Show help if requested
    if ($Help) {
        Show-Usage
        return
    }
    
    # Initialize log file
    $logDir = Split-Path $Script:UpdateLog -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $Script:UpdateLog -Value "$timestamp - Update started"
    
    # Check installation
    Test-Installation
    
    # Handle different modes
    if ($CheckVersion) {
        Write-Info "Current version: $(Get-CurrentVersion)"
        Write-Info "Available version: $(Get-NewVersion)"
        return
    }
    
    if ($Restore) {
        Restore-Backup
        return
    }
    
    if ($BackupOnly) {
        New-Backup
        return
    }
    
    # Perform update
    Start-Update
    
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" -Color Green
    Write-ColorOutput "     Update Process Complete" -Color Green
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" -Color Green
}

# Run main function
try {
    Main
} catch {
    Write-ErrorAndExit $_.Exception.Message
}