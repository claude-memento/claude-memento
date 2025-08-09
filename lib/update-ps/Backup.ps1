# Claude Memento Update System - Backup Functions (PowerShell)
# Handles backup creation, restoration, and management

# Import utility functions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\Utils.ps1"

# Default configuration
if (-not $script:BACKUP_DIR) {
    $script:BACKUP_DIR = "$env:USERPROFILE\.claude\memento\.backup"
}
if (-not $script:MAX_BACKUPS) {
    $script:MAX_BACKUPS = 5
}

# Function: Create backup
function New-Backup {
    Write-Info -Message "Creating backup of current installation..."
    
    # Create backup directory with timestamp
    $timestamp = Get-Timestamp
    $backupPath = Join-Path $script:BACKUP_DIR $timestamp
    
    if (Test-DryRun) {
        Write-Info -Message "[DRY RUN] Would create backup at: $backupPath"
        return
    }
    
    # Create backup directory structure
    Ensure-Directory -Path $backupPath
    
    # Backup system directories
    foreach ($dir in $script:SYSTEM_DIRS) {
        $sourceDir = Join-Path $script:MEMENTO_DIR $dir
        if (Test-Path -Path $sourceDir) {
            Write-Verbose -Message "Backing up $dir..."
            Copy-SafeItem -Source $sourceDir -Destination $backupPath
        }
    }
    
    # Backup system files
    foreach ($file in $script:SYSTEM_FILES) {
        $sourceFile = Join-Path $script:MEMENTO_DIR $file
        if (Test-Path -Path $sourceFile) {
            Write-Verbose -Message "Backing up $file..."
            Copy-Item -Path $sourceFile -Destination $backupPath -Force
        }
    }
    
    # Backup VERSION file if exists
    $versionFile = Join-Path $script:MEMENTO_DIR "VERSION"
    if (Test-Path -Path $versionFile) {
        Copy-Item -Path $versionFile -Destination $backupPath -Force
    }
    
    # Create backup metadata
    New-BackupMetadata -BackupPath $backupPath -Timestamp $timestamp
    
    # Clean up old backups (keep only last N)
    Remove-OldBackups
    
    # Store current backup path for potential rollback
    $script:CURRENT_BACKUP = $backupPath
    
    Write-Success -Message "Backup created at: $backupPath"
}

# Function: Create backup metadata
function New-BackupMetadata {
    param(
        [string]$BackupPath,
        [string]$Timestamp
    )
    
    $metadata = @{
        timestamp = $Timestamp
        date = Get-ISOTimestamp
        version = Get-CurrentVersion
        directories = $script:SYSTEM_DIRS
        files = $script:SYSTEM_FILES
        backup_size = Get-DirectorySize -Path $BackupPath
    }
    
    $metadataJson = $metadata | ConvertTo-Json -Depth 10
    $metadataFile = Join-Path $BackupPath "metadata.json"
    Set-Content -Path $metadataFile -Value $metadataJson
}

# Function: Clean up old backups
function Remove-OldBackups {
    if (-not (Test-Path -Path $script:BACKUP_DIR)) {
        return
    }
    
    # Get list of backups sorted by date (oldest first)
    $backups = Get-ChildItem -Path $script:BACKUP_DIR -Directory | 
        Where-Object { $_.Name -match '^\d{8}_\d{6}$' } | 
        Sort-Object Name
    
    $backupCount = $backups.Count
    
    if ($backupCount -gt $script:MAX_BACKUPS) {
        $removeCount = $backupCount - $script:MAX_BACKUPS
        Write-Verbose -Message "Removing $removeCount old backup(s)..."
        
        for ($i = 0; $i -lt $removeCount; $i++) {
            $oldBackup = $backups[$i]
            if (Test-DryRun) {
                Write-Info -Message "[DRY RUN] Would remove old backup: $($oldBackup.Name)"
            } else {
                Remove-Item -Path $oldBackup.FullName -Recurse -Force
                Write-Verbose -Message "Removed: $($oldBackup.Name)"
            }
        }
    }
}

# Function: List available backups
function Get-BackupList {
    if (-not (Test-Path -Path $script:BACKUP_DIR)) {
        Write-Info -Message "No backups found"
        return $false
    }
    
    $backups = Get-ChildItem -Path $script:BACKUP_DIR -Directory | 
        Where-Object { $_.Name -match '^\d{8}_\d{6}$' } | 
        Sort-Object Name -Descending
    
    if ($backups.Count -eq 0) {
        Write-Info -Message "No backups found"
        return $false
    }
    
    Write-Info -Message "Available backups:"
    foreach ($backup in $backups) {
        $backupName = $backup.Name
        $metadataFile = Join-Path $backup.FullName "metadata.json"
        
        if (Test-Path -Path $metadataFile) {
            $metadata = Get-Content -Path $metadataFile | ConvertFrom-Json
            Write-Host "  - $backupName (v$($metadata.version), $($metadata.backup_size))"
        } else {
            Write-Host "  - $backupName"
        }
    }
    
    return $true
}

# Function: Get latest backup
function Get-LatestBackup {
    if (-not (Test-Path -Path $script:BACKUP_DIR)) {
        return $null
    }
    
    $latest = Get-ChildItem -Path $script:BACKUP_DIR -Directory | 
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
        [string]$BackupPath
    )
    
    Write-Info -Message "Restoring from backup..."
    
    # Get backup to restore
    if (-not $BackupPath) {
        # Use latest backup
        $BackupPath = Get-LatestBackup
        if (-not $BackupPath) {
            Write-ErrorAndExit -Message "No backups available to restore"
        }
    }
    
    if (-not (Test-Path -Path $BackupPath)) {
        Write-ErrorAndExit -Message "Backup not found: $BackupPath"
    }
    
    Write-Info -Message "Restoring from: $(Split-Path -Leaf $BackupPath)"
    
    if (Test-DryRun) {
        Write-Info -Message "[DRY RUN] Would restore from: $BackupPath"
        return
    }
    
    # Verify backup integrity
    $metadataFile = Join-Path $BackupPath "metadata.json"
    if (-not (Test-Path -Path $metadataFile)) {
        Write-Warning -Message "Backup metadata not found, proceeding with caution..."
    }
    
    # Create temporary backup of current state (for rollback if restore fails)
    $tempBackup = Join-Path $script:BACKUP_DIR ".temp_restore_$(Get-Date -Format 'yyyyMMddHHmmss')"
    Ensure-Directory -Path $tempBackup
    
    # Backup current system files before restore
    foreach ($dir in $script:SYSTEM_DIRS) {
        $currentDir = Join-Path $script:MEMENTO_DIR $dir
        if (Test-Path -Path $currentDir) {
            Copy-Item -Path $currentDir -Destination $tempBackup -Recurse -Force
        }
    }
    
    foreach ($file in $script:SYSTEM_FILES) {
        $currentFile = Join-Path $script:MEMENTO_DIR $file
        if (Test-Path -Path $currentFile) {
            Copy-Item -Path $currentFile -Destination $tempBackup -Force
        }
    }
    
    # Restore from backup
    $restoreFailed = $false
    
    # Restore system directories
    foreach ($dir in $script:SYSTEM_DIRS) {
        $backupDir = Join-Path $BackupPath $dir
        if (Test-Path -Path $backupDir) {
            Write-Verbose -Message "Restoring $dir..."
            $targetDir = Join-Path $script:MEMENTO_DIR $dir
            if (Test-Path -Path $targetDir) {
                Remove-Item -Path $targetDir -Recurse -Force
            }
            Copy-Item -Path $backupDir -Destination $script:MEMENTO_DIR -Recurse -Force
            if (-not $?) { $restoreFailed = $true }
        }
    }
    
    # Restore system files
    foreach ($file in $script:SYSTEM_FILES) {
        $backupFile = Join-Path $BackupPath $file
        if (Test-Path -Path $backupFile) {
            Write-Verbose -Message "Restoring $file..."
            Copy-Item -Path $backupFile -Destination $script:MEMENTO_DIR -Force
            if (-not $?) { $restoreFailed = $true }
        }
    }
    
    # Restore VERSION file if exists
    $versionFile = Join-Path $BackupPath "VERSION"
    if (Test-Path -Path $versionFile) {
        Copy-Item -Path $versionFile -Destination $script:MEMENTO_DIR -Force
    }
    
    # Check if restore failed
    if ($restoreFailed) {
        Write-Warning -Message "Restore encountered errors, attempting rollback..."
        
        # Rollback from temp backup
        foreach ($dir in $script:SYSTEM_DIRS) {
            $tempDir = Join-Path $tempBackup $dir
            if (Test-Path -Path $tempDir) {
                $targetDir = Join-Path $script:MEMENTO_DIR $dir
                if (Test-Path -Path $targetDir) {
                    Remove-Item -Path $targetDir -Recurse -Force
                }
                Copy-Item -Path $tempDir -Destination $script:MEMENTO_DIR -Recurse -Force
            }
        }
        
        foreach ($file in $script:SYSTEM_FILES) {
            $tempFile = Join-Path $tempBackup $file
            if (Test-Path -Path $tempFile) {
                Copy-Item -Path $tempFile -Destination $script:MEMENTO_DIR -Force
            }
        }
        
        Remove-Item -Path $tempBackup -Recurse -Force
        Write-ErrorAndExit -Message "Restore failed and was rolled back"
    }
    
    # Clean up temp backup
    Remove-Item -Path $tempBackup -Recurse -Force
    
    Write-Success -Message "Backup restored successfully"
}

# Function: Get current version (for metadata)
function Get-CurrentVersion {
    $versionFile = Join-Path $script:MEMENTO_DIR "VERSION"
    if (Test-Path -Path $versionFile) {
        return Get-Content -Path $versionFile
    }
    
    $installLog = Join-Path $script:MEMENTO_DIR ".install.log"
    if (Test-Path -Path $installLog) {
        $versionLine = Select-String -Path $installLog -Pattern "Version:" | Select-Object -First 1
        if ($versionLine) {
            return $versionLine.Line.Split(' ')[1]
        }
    }
    
    return "unknown"
}

# Export functions
Export-ModuleMember -Function @(
    'New-Backup',
    'Remove-OldBackups',
    'Get-BackupList',
    'Get-LatestBackup',
    'Restore-Backup',
    'New-BackupMetadata'
)