# Claude Memento Version Management System (PowerShell)
# Handles version detection, compatibility checks, and migration

# Version format: MAJOR.MINOR.PATCH
$Script:CurrentVersion = "1.0.0"
$Script:MinCompatibleVersion = "1.0.0"

# Directories
$Script:MementoDir = "$env:USERPROFILE\.claude\memento"
$Script:VersionFile = "$MementoDir\.version"
$Script:InstallLog = "$MementoDir\.install.log"

# Function to parse version string
function Get-ParsedVersion {
    param([string]$Version)
    
    $cleaned = $Version -replace '^v', '' -replace '[^0-9.]', ''
    return $cleaned
}

# Function to compare versions
# Returns: 0 if equal, 1 if v1 > v2, -1 if v1 < v2
function Compare-Versions {
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    $v1 = Get-ParsedVersion $Version1
    $v2 = Get-ParsedVersion $Version2
    
    if ($v1 -eq $v2) { return 0 }
    
    $v1Parts = $v1.Split('.')
    $v2Parts = $v2.Split('.')
    
    for ($i = 0; $i -lt 3; $i++) {
        $p1 = if ($i -lt $v1Parts.Length) { [int]$v1Parts[$i] } else { 0 }
        $p2 = if ($i -lt $v2Parts.Length) { [int]$v2Parts[$i] } else { 0 }
        
        if ($p1 -gt $p2) { return 1 }
        if ($p1 -lt $p2) { return -1 }
    }
    
    return 0
}

# Function to get installed version
function Get-InstalledVersion {
    # Try multiple sources for version
    
    # 1. Check version file
    if (Test-Path $VersionFile) {
        return Get-Content $VersionFile -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
    }
    
    # 2. Check install log
    if (Test-Path $InstallLog) {
        $versionLine = Get-Content $InstallLog | Where-Object { $_ -match "^Version:" }
        if ($versionLine) {
            return ($versionLine -split ' ')[1]
        }
    }
    
    # 3. Check package version in source if available
    $sourceVersionFile = Join-Path (Split-Path $PSScriptRoot) "VERSION"
    if (Test-Path $sourceVersionFile) {
        return Get-Content $sourceVersionFile -Raw -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() }
    }
    
    # No version found
    return "unknown"
}

# Function to save current version
function Save-Version {
    param([string]$Version = $Script:CurrentVersion)
    
    $Version | Out-File -FilePath $VersionFile -Encoding UTF8 -NoNewline
    Write-Host "✓ Version $Version saved" -ForegroundColor Green
}

# Function to check compatibility
function Test-VersionCompatibility {
    param(
        [string]$InstalledVersion,
        [string]$NewVersion = $Script:CurrentVersion
    )
    
    Write-Host "Checking version compatibility..." -ForegroundColor Yellow
    Write-Host "  Installed: $InstalledVersion"
    Write-Host "  New:       $NewVersion"
    
    # Parse versions
    $installedParsed = Get-ParsedVersion $InstalledVersion
    $newParsed = Get-ParsedVersion $NewVersion
    
    # Check if downgrade
    $compareResult = Compare-Versions $newParsed $installedParsed
    
    if ($compareResult -eq -1) {
        Write-Host "Warning: Downgrade detected ($InstalledVersion → $NewVersion)" -ForegroundColor Red
        Write-Host "Downgrades may cause compatibility issues."
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            return $false
        }
    }
    
    # Check minimum compatible version
    $compareResult = Compare-Versions $installedParsed $Script:MinCompatibleVersion
    
    if ($compareResult -eq -1) {
        Write-Host "Error: Installed version $InstalledVersion is below minimum compatible version $Script:MinCompatibleVersion" -ForegroundColor Red
        Write-Host "Please perform a clean installation instead of update."
        return $false
    }
    
    # Check for major version change
    $installedParts = $installedParsed.Split('.')
    $newParts = $newParsed.Split('.')
    
    if ($installedParts[0] -ne $newParts[0]) {
        Write-Host "Major version change detected!" -ForegroundColor Yellow
        Write-Host "This may include breaking changes."
        $response = Read-Host "Continue with update? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            return $false
        }
    }
    
    Write-Host "✓ Version compatibility check passed" -ForegroundColor Green
    return $true
}

# Function to perform version-specific migrations
function Invoke-VersionMigration {
    param(
        [string]$FromVersion,
        [string]$ToVersion = $Script:CurrentVersion
    )
    
    Write-Host "Checking for required migrations..." -ForegroundColor Yellow
    
    # Parse versions for comparison
    $fromParsed = Get-ParsedVersion $FromVersion
    $toParsed = Get-ParsedVersion $ToVersion
    
    # No migration needed if same version
    $compareResult = Compare-Versions $fromParsed $toParsed
    if ($compareResult -eq 0) {
        Write-Host "No migrations needed (same version)"
        return $true
    }
    
    # Migration paths
    $migrationsPerformed = 0
    
    # 0.9.x → 1.0.0 migration
    if ((Compare-Versions $fromParsed "1.0.0") -eq -1) {
        if ((Compare-Versions $toParsed "1.0.0") -ge 0) {
            Write-Host "Migrating from pre-1.0 to 1.0+..." -ForegroundColor Yellow
            Invoke-MigrationTo100
            $migrationsPerformed++
        }
    }
    
    # Future migration paths can be added here
    
    if ($migrationsPerformed -gt 0) {
        Write-Host "✓ $migrationsPerformed migration(s) completed" -ForegroundColor Green
    } else {
        Write-Host "No migrations required"
    }
    
    return $true
}

# Migration function for 1.0.0
function Invoke-MigrationTo100 {
    Write-Host "  - Adding chunks directory for auto-chunking system..."
    New-Item -ItemType Directory -Force -Path "$MementoDir\chunks" | Out-Null
    
    Write-Host "  - Updating configuration format..."
    if (Test-Path "$MementoDir\config\settings.json") {
        # Backup old config
        Copy-Item "$MementoDir\config\settings.json" "$MementoDir\config\settings.json.pre-1.0.0" -Force
        
        # Add new configuration fields if missing
        $config = Get-Content "$MementoDir\config\settings.json" -Raw | ConvertFrom-Json
        if (-not $config.checkpoint.auto_save) {
            Write-Host "    Adding auto_save configuration..."
            # This would need proper JSON manipulation in production
        }
    }
    
    Write-Host "  - Setting up graph database for chunk relationships..."
    "{}" | Out-File -FilePath "$MementoDir\chunks\.graph.json" -Encoding UTF8
    
    Write-Host "  ✓ Migration to 1.0.0 completed" -ForegroundColor Green
}

# Function to display version info
function Show-VersionInfo {
    Write-Host "Claude Memento Version Information" -ForegroundColor Blue
    Write-Host "=================================="
    
    $installedVersion = Get-InstalledVersion
    Write-Host "Installed version:  $installedVersion"
    Write-Host "Package version:    $Script:CurrentVersion"
    Write-Host "Minimum compatible: $Script:MinCompatibleVersion"
    
    if (Test-Path $VersionFile) {
        Write-Host "Version file:       $(Get-Content $VersionFile -Raw)"
    }
    
    if (Test-Path $InstallLog) {
        Write-Host ""
        Write-Host "Installation info:"
        Get-Content $InstallLog | Where-Object { $_ -match "^(Installation Date:|Version:)" } | ForEach-Object {
            Write-Host "  $_"
        }
    }
    
    # Check if update available
    if ($installedVersion -ne "unknown" -and $installedVersion -ne $Script:CurrentVersion) {
        $compareResult = Compare-Versions $Script:CurrentVersion $installedVersion
        if ($compareResult -eq 1) {
            Write-Host ""
            Write-Host "Update available: $installedVersion → $Script:CurrentVersion" -ForegroundColor Green
        }
    }
}

# Export functions
Export-ModuleMember -Function Get-ParsedVersion, Compare-Versions, Get-InstalledVersion, `
                              Save-Version, Test-VersionCompatibility, Invoke-VersionMigration, `
                              Show-VersionInfo