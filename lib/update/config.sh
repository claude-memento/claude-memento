#!/bin/bash

# Claude Memento Update System - Configuration Functions
# Handles configuration merging and management

# Source utility functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/utils.sh" 2>/dev/null || true
source "$LIB_DIR/core.sh" 2>/dev/null || true

# Function: Merge configuration
merge_config() {
    info "Merging configuration..."
    
    if ! should_update_item "settings"; then
        verbose "Skipping configuration merge (excluded by user)"
        return 0
    fi
    
    local settings_dir="$MEMENTO_DIR/settings"
    local source_settings="${SOURCE_DIR:-$(pwd)}/settings"
    local merge_failed=false
    
    # Ensure settings directory exists
    ensure_dir "$settings_dir"
    
    if is_dry_run; then
        info "[DRY RUN] Would merge configuration files"
        return 0
    fi
    
    # List of config files to merge
    local config_files=(
        "config.json"
        "preferences.json"
        "user-settings.json"
    )
    
    for config_file in "${config_files[@]}"; do
        local user_config="$settings_dir/$config_file"
        local new_config="$source_settings/$config_file"
        local default_config="$source_settings/${config_file}.default"
        
        # Skip if no new config available
        if [ ! -f "$new_config" ] && [ ! -f "$default_config" ]; then
            verbose "No new config for $config_file"
            continue
        fi
        
        # Use default config if main config doesn't exist
        if [ ! -f "$new_config" ] && [ -f "$default_config" ]; then
            new_config="$default_config"
        fi
        
        # If user config doesn't exist, copy new config
        if [ ! -f "$user_config" ]; then
            verbose "Creating new config: $config_file"
            cp "$new_config" "$user_config" || {
                warn "Failed to create $config_file"
                merge_failed=true
                continue
            }
        else
            # Merge configurations
            verbose "Merging config: $config_file"
            
            # Create backup of user config
            cp "$user_config" "${user_config}.backup" || warn "Failed to backup $config_file"
            
            # Perform merge (user settings take priority)
            if command -v jq >/dev/null 2>&1; then
                # Use jq for JSON merging if available
                merge_json_with_jq "$new_config" "$user_config" "$user_config.tmp"
            else
                # Fallback to simple merge
                merge_json_simple "$new_config" "$user_config" "$user_config.tmp"
            fi
            
            if [ -f "$user_config.tmp" ]; then
                mv "$user_config.tmp" "$user_config" || {
                    warn "Failed to update $config_file"
                    merge_failed=true
                    # Restore from backup
                    [ -f "${user_config}.backup" ] && mv "${user_config}.backup" "$user_config"
                }
            fi
            
            # Clean up backup if merge succeeded
            [ -f "${user_config}.backup" ] && rm "${user_config}.backup"
        fi
    done
    
    if [ "$merge_failed" = true ]; then
        warn "Some configuration files failed to merge"
        return 1
    fi
    
    success "Configuration merged successfully"
}

# Function: Merge JSON using jq
merge_json_with_jq() {
    local new_config="$1"
    local user_config="$2"
    local output="$3"
    
    # Merge with user config taking priority
    jq -s '.[0] * .[1]' "$new_config" "$user_config" > "$output" 2>/dev/null || {
        warn "jq merge failed, using simple merge"
        merge_json_simple "$new_config" "$user_config" "$output"
    }
}

# Function: Simple JSON merge (fallback)
merge_json_simple() {
    local new_config="$1"
    local user_config="$2"
    local output="$3"
    
    # Simple strategy: keep user config but add any new top-level keys from new config
    # This is a basic implementation - in production, you'd want more sophisticated merging
    
    # For now, just keep the user config as-is (user settings take full priority)
    cp "$user_config" "$output"
    
    # Log that we're using simple merge
    verbose "Using simple merge strategy (user config preserved)"
}

# Function: Validate configuration files
validate_config() {
    local settings_dir="$MEMENTO_DIR/settings"
    local validation_failed=false
    
    # Check for required configuration files
    local required_configs=(
        "config.json"
    )
    
    for config in "${required_configs[@]}"; do
        if [ ! -f "$settings_dir/$config" ]; then
            warn "Missing required configuration: $config"
            validation_failed=true
        elif command -v jq >/dev/null 2>&1; then
            # Validate JSON syntax if jq is available
            if ! jq empty "$settings_dir/$config" 2>/dev/null; then
                warn "Invalid JSON in $config"
                validation_failed=true
            fi
        fi
    done
    
    if [ "$validation_failed" = true ]; then
        return 1
    fi
    
    return 0
}

# Function: Backup configuration
backup_config() {
    local settings_dir="$MEMENTO_DIR/settings"
    local backup_dir="$1"
    
    if [ -d "$settings_dir" ]; then
        verbose "Backing up configuration..."
        cp -r "$settings_dir" "$backup_dir/" || warn "Failed to backup configuration"
    fi
}

# Function: Restore configuration
restore_config() {
    local backup_dir="$1"
    local settings_backup="$backup_dir/settings"
    
    if [ -d "$settings_backup" ]; then
        verbose "Restoring configuration..."
        rm -rf "$MEMENTO_DIR/settings" 2>/dev/null
        cp -r "$settings_backup" "$MEMENTO_DIR/" || warn "Failed to restore configuration"
    fi
}

# Export functions
export -f merge_config merge_json_with_jq merge_json_simple
export -f validate_config backup_config restore_config