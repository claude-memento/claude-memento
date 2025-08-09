# Claude Memento Update System - Core Update Functions (PowerShell)
# Handles core update operations for system files and directories

# Import utility functions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\Utils.ps1"

# Function: Check if item should be updated
function Test-UpdateItem {
    param(
        [string]$Item
    )
    
    # Check if item is in skip list
    if ($script:SKIP_ITEMS) {
        if (",$($script:SKIP_ITEMS)," -match ",$Item,") {
            return $false
        }
    }
    
    # Check selective update list
    if (-not $script:UPDATE_ALL -and $script:SELECTIVE_UPDATE) {
        if (",$($script:SELECTIVE_UPDATE)," -match ",$Item,") {
            return $true
        } else {
            return $false
        }
    }
    
    return $true
}

# Function: Update system files
function Update-SystemFiles {
    Write-Info -Message "Updating system files..."
    
    $sourceDir = if ($script:SOURCE_DIR) { $script:SOURCE_DIR } else { $script:SCRIPT_DIR }
    $updateFailed = $false
    $updatedItems = @()
    $skippedItems = @()
    
    if (-not (Test-Path -Path $sourceDir)) {
        Write-ErrorAndExit -Message "Source directory not found: $sourceDir"
    }
    
    if (Test-DryRun) {
        Write-Info -Message "[DRY RUN] Would update files from: $sourceDir"
    }
    
    # Show update mode
    if (-not $script:UPDATE_ALL) {
        Write-Info -Message "Selective update mode: $($script:SELECTIVE_UPDATE)"
    } elseif ($script:SKIP_ITEMS) {
        Write-Info -Message "Skipping items: $($script:SKIP_ITEMS)"
    } else {
        Write-Info -Message "Full update mode: all components"
    }
    
    # Update system directories
    foreach ($dir in $script:SYSTEM_DIRS) {
        if (-not (Test-UpdateItem -Item $dir)) {
            Write-Verbose -Message "Skipping $dir (excluded by user)"
            $skippedItems += $dir
            continue
        }
        
        $source = Join-Path $sourceDir $dir
        $target = Join-Path $script:MEMENTO_DIR $dir
        
        if (Test-Path -Path $source) {
            Write-Verbose -Message "Updating $dir..."
            
            if (Test-DryRun) {
                Write-Info -Message "[DRY RUN] Would update: $dir"
            } else {
                # Remove old directory and copy new one
                if (Test-Path -Path $target) {
                    Remove-Item -Path $target -Recurse -Force -ErrorAction SilentlyContinue
                    if (-not $?) {
                        Write-Warning -Message "Failed to remove old $dir"
                        $updateFailed = $true
                        continue
                    }
                }
                
                Copy-Item -Path $source -Destination $script:MEMENTO_DIR -Recurse -Force
                if (-not $?) {
                    Write-Warning -Message "Failed to update $dir"
                    $updateFailed = $true
                    continue
                }
                
                $updatedItems += $dir
            }
        } else {
            Write-Verbose -Message "Skipping $dir (not found in source)"
        }
    }
    
    # Update system files
    foreach ($file in $script:SYSTEM_FILES) {
        $source = Join-Path $sourceDir $file
        $target = Join-Path $script:MEMENTO_DIR $file
        
        if (Test-Path -Path $source) {
            Write-Verbose -Message "Updating $file..."
            
            if (Test-DryRun) {
                Write-Info -Message "[DRY RUN] Would update: $file"
            } else {
                Copy-Item -Path $source -Destination $script:MEMENTO_DIR -Force
                if (-not $?) {
                    Write-Warning -Message "Failed to update $file"
                    $updateFailed = $true
                    continue
                }
                
                $updatedItems += $file
            }
        } else {
            Write-Verbose -Message "Skipping $file (not found in source)"
        }
    }
    
    # Update VERSION file
    $versionFile = Join-Path $sourceDir "VERSION"
    if (Test-Path -Path $versionFile) {
        if (Test-DryRun) {
            Write-Info -Message "[DRY RUN] Would update: VERSION"
        } else {
            Copy-Item -Path $versionFile -Destination $script:MEMENTO_DIR -Force
            $updatedItems += "VERSION"
        }
    }
    
    # Update wrapper scripts in parent directory
    if (Test-UpdateItem -Item "wrappers") {
        Update-WrapperScripts -SourceDir $sourceDir
    } else {
        Write-Verbose -Message "Skipping wrapper scripts (excluded by user)"
        $skippedItems += "wrappers"
    }
    
    # Report results
    if ($updatedItems.Count -gt 0) {
        Write-Info -Message "Updated items: $($updatedItems -join ', ')"
    }
    
    if ($skippedItems.Count -gt 0) {
        Write-Info -Message "Skipped items: $($skippedItems -join ', ')"
    }
    
    if ($updateFailed) {
        Write-Warning -Message "Some files failed to update. Check the log for details."
        return $false
    }
    
    Write-Success -Message "System files updated successfully"
    return $true
}

# Function: Update wrapper scripts
function Update-WrapperScripts {
    param(
        [string]$SourceDir
    )
    
    # List of wrapper scripts that should be in ~/.claude/
    $wrapperScripts = @("cm", "claude-memento")
    
    foreach ($script in $wrapperScripts) {
        $sourceFile = Join-Path $SourceDir "wrappers\${script}.ps1"
        $targetFile = Join-Path $script:CLAUDE_DIR $script
        
        # If source doesn't have wrappers dir, check root
        if (-not (Test-Path -Path $sourceFile)) {
            $sourceFile = Join-Path $SourceDir "${script}.ps1"
        }
        
        if (Test-Path -Path $sourceFile) {
            if (Test-DryRun) {
                Write-Info -Message "[DRY RUN] Would update wrapper: $script"
            } else {
                Write-Verbose -Message "Updating wrapper script: $script"
                Copy-Item -Path $sourceFile -Destination $targetFile -Force
            }
        }
    }
}

# Function: Verify update integrity
function Test-UpdateIntegrity {
    Write-Info -Message "Verifying update integrity..."
    
    $verificationFailed = $false
    
    # Check system directories exist
    foreach ($dir in $script:SYSTEM_DIRS) {
        $dirPath = Join-Path $script:MEMENTO_DIR $dir
        if (-not (Test-Path -Path $dirPath)) {
            Write-Warning -Message "Missing directory after update: $dir"
            $verificationFailed = $true
        }
    }
    
    # Check system files exist
    foreach ($file in $script:SYSTEM_FILES) {
        $filePath = Join-Path $script:MEMENTO_DIR $file
        if (-not (Test-Path -Path $filePath)) {
            Write-Warning -Message "Missing file after update: $file"
            $verificationFailed = $true
        }
    }
    
    # Check wrapper scripts
    $cmPath = Join-Path $script:CLAUDE_DIR "cm"
    if (-not (Test-Path -Path $cmPath)) {
        Write-Warning -Message "Wrapper script 'cm' is missing"
        $verificationFailed = $true
    }
    
    if ($verificationFailed) {
        return $false
    }
    
    Write-Success -Message "Update verification passed"
    return $true
}

# Function: Update CLAUDE.md
function Update-ClaudeMd {
    Write-Info -Message "Updating CLAUDE.md integration..."
    
    if (-not (Test-UpdateItem -Item "claude-md")) {
        Write-Verbose -Message "Skipping CLAUDE.md update (excluded by user)"
        return $true
    }
    
    $claudeMd = Join-Path $script:CLAUDE_DIR "CLAUDE.md"
    $sourceTemplate = Join-Path (if ($script:SOURCE_DIR) { $script:SOURCE_DIR } else { $script:SCRIPT_DIR }) "templates\claude-memento-section.md"
    $beginMarker = "<!-- Claude Memento Integration -->"
    $endMarker = "<!-- End Claude Memento Integration -->"
    
    if (Test-DryRun) {
        Write-Info -Message "[DRY RUN] Would update CLAUDE.md integration"
        return $true
    }
    
    # Check if CLAUDE.md exists
    if (-not (Test-Path -Path $claudeMd)) {
        Write-Warning -Message "CLAUDE.md not found, skipping update"
        return $true
    }
    
    # Check if new template exists
    if (-not (Test-Path -Path $sourceTemplate)) {
        Write-Verbose -Message "No new CLAUDE.md template found"
        return $true
    }
    
    # Backup CLAUDE.md before modification
    $backupFile = "${claudeMd}.backup.$(Get-Timestamp)"
    Copy-Item -Path $claudeMd -Destination $backupFile -Force
    Write-Verbose -Message "Backed up CLAUDE.md to: $backupFile"
    
    # Read current content
    $content = Get-Content -Path $claudeMd -Raw
    
    # Remove ALL existing Claude Memento sections (handle duplicates)
    $removedCount = 0
    while ($content -match [regex]::Escape($beginMarker)) {
        $pattern = "(?ms)$([regex]::Escape($beginMarker)).*?$([regex]::Escape($endMarker))\r?\n?"
        $content = $content -replace $pattern, ""
        $removedCount++
        
        # Safety check to prevent infinite loop
        if ($removedCount -gt 20) {
            Write-Warning -Message "Removed $removedCount Claude Memento sections. Stopping to prevent infinite loop."
            break
        }
    }
    
    if ($removedCount -gt 0) {
        Write-Verbose -Message "Removed $removedCount existing Claude Memento section(s)"
    }
    
    # Add new Claude Memento section
    $newTemplate = Get-Content -Path $sourceTemplate -Raw
    $content = $content.TrimEnd() + "`n`n$beginMarker`n$newTemplate`n$endMarker"
    
    # Save updated content
    Set-Content -Path $claudeMd -Value $content -Force
    
    # Clean up old backups (keep only last 5)
    Remove-OldClaudeMdBackups
    
    Write-Success -Message "CLAUDE.md updated successfully"
    return $true
}

# Function: Clean up old CLAUDE.md backups
function Remove-OldClaudeMdBackups {
    $backupPattern = Join-Path $script:CLAUDE_DIR "CLAUDE.md.backup.*"
    $backups = Get-ChildItem -Path $backupPattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    $maxBackups = 5
    
    if ($backups.Count -gt $maxBackups) {
        for ($i = $maxBackups; $i -lt $backups.Count; $i++) {
            Remove-Item -Path $backups[$i].FullName -Force
            Write-Verbose -Message "Removed old CLAUDE.md backup: $($backups[$i].Name)"
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-UpdateItem',
    'Update-SystemFiles',
    'Update-WrapperScripts',
    'Test-UpdateIntegrity',
    'Update-ClaudeMd',
    'Remove-OldClaudeMdBackups'
)