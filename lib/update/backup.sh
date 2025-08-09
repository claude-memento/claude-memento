#!/bin/bash

# Claude Memento Update System - Backup Functions
# Handles backup creation, restoration, and management

# Source utility functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/utils.sh" 2>/dev/null || true

# Default configuration
BACKUP_DIR="${BACKUP_DIR:-$HOME/.claude/memento/.backup}"
MAX_BACKUPS="${MAX_BACKUPS:-5}"

# Function: Create backup
create_backup() {
    info "Creating backup of current installation..."
    
    # Create backup directory with timestamp
    local timestamp=$(get_timestamp)
    local backup_path="$BACKUP_DIR/$timestamp"
    
    if is_dry_run; then
        info "[DRY RUN] Would create backup at: $backup_path"
        return 0
    fi
    
    # Create backup directory structure
    ensure_dir "$backup_path"
    
    # Backup system directories
    for dir in "${SYSTEM_DIRS[@]}"; do
        local source_dir="$MEMENTO_DIR/$dir"
        if [ -d "$source_dir" ]; then
            verbose "Backing up $dir..."
            safe_copy "$source_dir" "$backup_path/" || error_exit "Failed to backup $dir"
        fi
    done
    
    # Backup system files
    for file in "${SYSTEM_FILES[@]}"; do
        local source_file="$MEMENTO_DIR/$file"
        if [ -f "$source_file" ]; then
            verbose "Backing up $file..."
            safe_copy "$source_file" "$backup_path/" || error_exit "Failed to backup $file"
        fi
    done
    
    # Backup VERSION file if exists
    if [ -f "$MEMENTO_DIR/VERSION" ]; then
        cp "$MEMENTO_DIR/VERSION" "$backup_path/" || warn "Failed to backup VERSION file"
    fi
    
    # Create backup metadata
    create_backup_metadata "$backup_path" "$timestamp"
    
    # Clean up old backups (keep only last N)
    cleanup_old_backups
    
    # Store current backup path for potential rollback
    export CURRENT_BACKUP="$backup_path"
    
    success "Backup created at: $backup_path"
}

# Function: Create backup metadata
create_backup_metadata() {
    local backup_path="$1"
    local timestamp="$2"
    
    cat > "$backup_path/metadata.json" << EOF
{
    "timestamp": "$timestamp",
    "date": "$(get_iso_timestamp)",
    "version": "$(get_current_version)",
    "directories": [$(printf '"%s",' "${SYSTEM_DIRS[@]}" | sed 's/,$//')],
    "files": [$(printf '"%s",' "${SYSTEM_FILES[@]}" | sed 's/,$//')],
    "backup_size": "$(get_dir_size "$backup_path")"
}
EOF
}

# Function: Clean up old backups
cleanup_old_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        return 0
    fi
    
    # Get list of backups sorted by date (oldest first)
    local backups=($(ls -1d "$BACKUP_DIR"/[0-9]*_[0-9]* 2>/dev/null | sort))
    local backup_count=${#backups[@]}
    
    if [ $backup_count -gt $MAX_BACKUPS ]; then
        local remove_count=$((backup_count - MAX_BACKUPS))
        verbose "Removing $remove_count old backup(s)..."
        
        for ((i=0; i<$remove_count; i++)); do
            local old_backup="${backups[$i]}"
            if is_dry_run; then
                info "[DRY RUN] Would remove old backup: $old_backup"
            else
                rm -rf "$old_backup" && verbose "Removed: $(basename "$old_backup")"
            fi
        done
    fi
}

# Function: List available backups
list_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        info "No backups found"
        return 1
    fi
    
    local backups=($(ls -1d "$BACKUP_DIR"/[0-9]*_[0-9]* 2>/dev/null | sort -r))
    
    if [ ${#backups[@]} -eq 0 ]; then
        info "No backups found"
        return 1
    fi
    
    info "Available backups:"
    for backup in "${backups[@]}"; do
        local backup_name=$(basename "$backup")
        local metadata_file="$backup/metadata.json"
        
        if [ -f "$metadata_file" ]; then
            local version=$(grep '"version"' "$metadata_file" | sed 's/.*"version": "\([^"]*\)".*/\1/')
            local size=$(grep '"backup_size"' "$metadata_file" | sed 's/.*"backup_size": "\([^"]*\)".*/\1/')
            echo "  - $backup_name (v$version, $size)"
        else
            echo "  - $backup_name"
        fi
    done
    
    return 0
}

# Function: Get latest backup
get_latest_backup() {
    if [ ! -d "$BACKUP_DIR" ]; then
        return 1
    fi
    
    local latest=$(ls -1d "$BACKUP_DIR"/[0-9]*_[0-9]* 2>/dev/null | sort -r | head -n1)
    
    if [ -n "$latest" ] && [ -d "$latest" ]; then
        echo "$latest"
        return 0
    fi
    
    return 1
}

# Function: Restore from backup
restore_backup() {
    info "Restoring from backup..."
    
    # Get backup to restore
    local backup_path=""
    
    if [ -n "$1" ]; then
        # Specific backup provided
        backup_path="$1"
    else
        # Use latest backup
        backup_path=$(get_latest_backup)
        if [ $? -ne 0 ]; then
            error_exit "No backups available to restore"
        fi
    fi
    
    if [ ! -d "$backup_path" ]; then
        error_exit "Backup not found: $backup_path"
    fi
    
    info "Restoring from: $(basename "$backup_path")"
    
    if is_dry_run; then
        info "[DRY RUN] Would restore from: $backup_path"
        return 0
    fi
    
    # Verify backup integrity
    if [ ! -f "$backup_path/metadata.json" ]; then
        warn "Backup metadata not found, proceeding with caution..."
    fi
    
    # Create temporary backup of current state (for rollback if restore fails)
    local temp_backup="$BACKUP_DIR/.temp_restore_$(date +%s)"
    ensure_dir "$temp_backup"
    
    # Backup current system files before restore
    for dir in "${SYSTEM_DIRS[@]}"; do
        if [ -d "$MEMENTO_DIR/$dir" ]; then
            cp -r "$MEMENTO_DIR/$dir" "$temp_backup/" 2>/dev/null
        fi
    done
    
    for file in "${SYSTEM_FILES[@]}"; do
        if [ -f "$MEMENTO_DIR/$file" ]; then
            cp "$MEMENTO_DIR/$file" "$temp_backup/" 2>/dev/null
        fi
    done
    
    # Restore from backup
    local restore_failed=false
    
    # Restore system directories
    for dir in "${SYSTEM_DIRS[@]}"; do
        local backup_dir="$backup_path/$dir"
        if [ -d "$backup_dir" ]; then
            verbose "Restoring $dir..."
            rm -rf "$MEMENTO_DIR/$dir" 2>/dev/null
            cp -r "$backup_dir" "$MEMENTO_DIR/" || restore_failed=true
        fi
    done
    
    # Restore system files
    for file in "${SYSTEM_FILES[@]}"; do
        local backup_file="$backup_path/$file"
        if [ -f "$backup_file" ]; then
            verbose "Restoring $file..."
            cp "$backup_file" "$MEMENTO_DIR/" || restore_failed=true
        fi
    done
    
    # Restore VERSION file if exists
    if [ -f "$backup_path/VERSION" ]; then
        cp "$backup_path/VERSION" "$MEMENTO_DIR/" || warn "Failed to restore VERSION file"
    fi
    
    # Check if restore failed
    if [ "$restore_failed" = true ]; then
        warn "Restore encountered errors, attempting rollback..."
        
        # Rollback from temp backup
        for dir in "${SYSTEM_DIRS[@]}"; do
            if [ -d "$temp_backup/$dir" ]; then
                rm -rf "$MEMENTO_DIR/$dir" 2>/dev/null
                cp -r "$temp_backup/$dir" "$MEMENTO_DIR/"
            fi
        done
        
        for file in "${SYSTEM_FILES[@]}"; do
            if [ -f "$temp_backup/$file" ]; then
                cp "$temp_backup/$file" "$MEMENTO_DIR/"
            fi
        done
        
        rm -rf "$temp_backup"
        error_exit "Restore failed and was rolled back"
    fi
    
    # Clean up temp backup
    rm -rf "$temp_backup"
    
    success "Backup restored successfully"
}

# Function: Get current version (for metadata)
get_current_version() {
    local version_file="$MEMENTO_DIR/VERSION"
    if [ -f "$version_file" ]; then
        cat "$version_file"
    elif [ -f "$MEMENTO_DIR/.install.log" ]; then
        grep "Version:" "$MEMENTO_DIR/.install.log" | cut -d' ' -f2
    else
        echo "unknown"
    fi
}

# Export functions
export -f create_backup cleanup_old_backups list_backups
export -f get_latest_backup restore_backup create_backup_metadata