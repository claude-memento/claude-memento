#!/bin/bash

# Claude Memento Update System - Rollback Functions
# Handles rollback operations and error recovery

# Source utility functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/utils.sh" 2>/dev/null || true

# Rollback state variables
ROLLBACK_ENABLED="${ROLLBACK_ENABLED:-false}"
ROLLBACK_POINT="${ROLLBACK_POINT:-none}"
UPDATE_STAGE="${UPDATE_STAGE:-initialized}"

# Function: Initialize rollback system
init_rollback() {
    ROLLBACK_ENABLED=true
    ROLLBACK_POINT="${CURRENT_BACKUP:-none}"
    UPDATE_STAGE="initialized"
    
    verbose "Rollback system initialized"
}

# Function: Handle update error
handle_update_error() {
    local exit_code=$?
    local line_no=${BASH_LINENO[0]}
    
    warn "Error occurred at line $line_no (exit code: $exit_code)"
    
    if [ "$ROLLBACK_ENABLED" = true ]; then
        trigger_rollback "Unexpected error at line $line_no"
    fi
    
    exit $exit_code
}

# Function: Trigger rollback
trigger_rollback() {
    local reason="${1:-Unknown reason}"
    
    warn "Triggering rollback: $reason"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ROLLBACK: $reason" >> "$UPDATE_LOG"
    
    if is_dry_run; then
        info "[DRY RUN] Would perform rollback"
        return 0
    fi
    
    # Perform rollback based on update stage
    case "$UPDATE_STAGE" in
        "system_files")
            rollback_system_files
            ;;
        "claude_md")
            rollback_system_files
            rollback_claude_md
            ;;
        "config")
            rollback_system_files
            rollback_claude_md
            rollback_config
            ;;
        *)
            info "Rolling back to backup: $ROLLBACK_POINT"
            if [ "$ROLLBACK_POINT" != "none" ] && [ -d "$ROLLBACK_POINT" ]; then
                restore_from_backup "$ROLLBACK_POINT"
            fi
            ;;
    esac
    
    warn "Rollback completed. Update aborted."
}

# Function: Rollback system files
rollback_system_files() {
    info "Rolling back system files..."
    
    if [ -n "$CURRENT_BACKUP" ] && [ -d "$CURRENT_BACKUP" ]; then
        # Restore system directories
        for dir in "${SYSTEM_DIRS[@]}"; do
            local backup_dir="$CURRENT_BACKUP/$dir"
            if [ -d "$backup_dir" ]; then
                rm -rf "$MEMENTO_DIR/$dir" 2>/dev/null
                cp -r "$backup_dir" "$MEMENTO_DIR/"
            fi
        done
        
        # Restore system files
        for file in "${SYSTEM_FILES[@]}"; do
            local backup_file="$CURRENT_BACKUP/$file"
            if [ -f "$backup_file" ]; then
                cp "$backup_file" "$MEMENTO_DIR/"
            fi
        done
        
        success "System files rolled back"
    else
        warn "No backup available for system files rollback"
    fi
}

# Function: Rollback CLAUDE.md
rollback_claude_md() {
    info "Rolling back CLAUDE.md..."
    
    # Find most recent CLAUDE.md backup
    local latest_backup=$(ls -1t "$CLAUDE_DIR"/CLAUDE.md.backup.* 2>/dev/null | head -n1)
    
    if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
        cp "$latest_backup" "$CLAUDE_DIR/CLAUDE.md"
        success "CLAUDE.md rolled back from: $(basename "$latest_backup")"
    else
        warn "No CLAUDE.md backup available for rollback"
    fi
}

# Function: Rollback configuration
rollback_config() {
    info "Rolling back configuration..."
    
    local settings_dir="$MEMENTO_DIR/settings"
    
    # Find and restore .backup files
    for backup_file in "$settings_dir"/*.json.backup; do
        if [ -f "$backup_file" ]; then
            local original_file="${backup_file%.backup}"
            mv "$backup_file" "$original_file"
            verbose "Restored: $(basename "$original_file")"
        fi
    done
    
    success "Configuration rolled back"
}

# Function: Commit update (mark as successful)
commit_update() {
    ROLLBACK_ENABLED=false
    UPDATE_STAGE="completed"
    
    # Clean up temporary files
    rm -f "$MEMENTO_DIR"/*.tmp 2>/dev/null
    rm -f "$CLAUDE_DIR"/*.tmp 2>/dev/null
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Update completed successfully" >> "$UPDATE_LOG"
    
    verbose "Update committed successfully"
}

# Function: Restore from backup point
restore_from_backup() {
    local backup_path="$1"
    
    if [ ! -d "$backup_path" ]; then
        error_exit "Backup not found: $backup_path"
    fi
    
    info "Restoring from backup: $(basename "$backup_path")"
    
    # Restore system directories
    for dir in "${SYSTEM_DIRS[@]}"; do
        local backup_dir="$backup_path/$dir"
        if [ -d "$backup_dir" ]; then
            rm -rf "$MEMENTO_DIR/$dir" 2>/dev/null
            cp -r "$backup_dir" "$MEMENTO_DIR/" || warn "Failed to restore $dir"
        fi
    done
    
    # Restore system files
    for file in "${SYSTEM_FILES[@]}"; do
        local backup_file="$backup_path/$file"
        if [ -f "$backup_file" ]; then
            cp "$backup_file" "$MEMENTO_DIR/" || warn "Failed to restore $file"
        fi
    done
    
    # Restore VERSION file if exists
    if [ -f "$backup_path/VERSION" ]; then
        cp "$backup_path/VERSION" "$MEMENTO_DIR/" || warn "Failed to restore VERSION file"
    fi
    
    success "Restored from backup successfully"
}

# Function: Set update stage
set_update_stage() {
    UPDATE_STAGE="$1"
    verbose "Update stage: $UPDATE_STAGE"
}

# Function: Check if rollback is enabled
is_rollback_enabled() {
    [ "$ROLLBACK_ENABLED" = true ]
}

# Export functions and variables
export ROLLBACK_ENABLED ROLLBACK_POINT UPDATE_STAGE
export -f init_rollback handle_update_error trigger_rollback
export -f rollback_system_files rollback_claude_md rollback_config
export -f commit_update restore_from_backup set_update_stage is_rollback_enabled