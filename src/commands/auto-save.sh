#!/bin/bash

# Auto-save management command for Claude Memento

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/src/utils/common.sh"
source "$MEMENTO_DIR/src/utils/logger.sh"

# Command wrapper for auto-save timer
main() {
    local action="${1:-status}"
    
    case "$action" in
        enable)
            enable_auto_save
            ;;
        disable)
            disable_auto_save
            ;;
        start|stop|restart|status|save)
            # Delegate to timer script
            "$MEMENTO_DIR/src/hooks/auto-save-timer.sh" "$action"
            ;;
        config)
            configure_auto_save "$@"
            ;;
        *)
            show_help
            ;;
    esac
}

# Enable auto-save
enable_auto_save() {
    log_info "Enabling auto-save..."
    
    # Update configuration
    update_config "autoSave.enabled" "true"
    
    # Start daemon
    "$MEMENTO_DIR/src/hooks/auto-save-timer.sh" start
    
    log_success "Auto-save enabled"
}

# Disable auto-save
disable_auto_save() {
    log_info "Disabling auto-save..."
    
    # Stop daemon
    "$MEMENTO_DIR/src/hooks/auto-save-timer.sh" stop
    
    # Update configuration
    update_config "autoSave.enabled" "false"
    
    log_success "Auto-save disabled"
}

# Configure auto-save settings
configure_auto_save() {
    shift # Remove 'config' argument
    local key="$1"
    local value="$2"
    
    if [ -z "$key" ]; then
        # Show current configuration
        echo "Auto-Save Configuration:"
        echo "======================="
        
        local enabled=$(get_config_value "autoSave.enabled" "false")
        local interval=$(get_config_value "autoSave.interval" "900")
        local on_session_end=$(get_config_value "autoSave.onSessionEnd" "true")
        
        echo "Enabled: $enabled"
        echo "Interval: $interval seconds ($(( interval / 60 )) minutes)"
        echo "Save on session end: $on_session_end"
        
        return
    fi
    
    case "$key" in
        interval)
            if [ -z "$value" ]; then
                echo "Error: Interval value required (in seconds)"
                return 1
            fi
            update_config "autoSave.interval" "$value"
            log_success "Auto-save interval set to $value seconds"
            
            # Restart daemon if running
            if [ -f "$MEMENTO_DIR/.auto-save.pid" ]; then
                "$MEMENTO_DIR/src/hooks/auto-save-timer.sh" restart
            fi
            ;;
        on-session-end)
            if [[ "$value" =~ ^(true|false)$ ]]; then
                update_config "autoSave.onSessionEnd" "$value"
                log_success "Save on session end: $value"
            else
                echo "Error: Value must be 'true' or 'false'"
                return 1
            fi
            ;;
        *)
            echo "Error: Unknown configuration key: $key"
            echo "Available keys: interval, on-session-end"
            return 1
            ;;
    esac
}

# Update configuration value
update_config() {
    local key="$1"
    local value="$2"
    local config_file="$MEMENTO_DIR/config/settings.json"
    
    # Ensure config directory exists
    mkdir -p "$MEMENTO_DIR/config"
    
    # Copy default if settings don't exist
    if [ ! -f "$config_file" ]; then
        cp "$MEMENTO_DIR/src/config/default-settings.json" "$config_file"
    fi
    
    # Update value using simple sed (works for flat keys)
    # For nested keys like autoSave.enabled, this is simplified
    if [[ "$key" == *"."* ]]; then
        # Handle nested keys (simplified for one level)
        local parent="${key%%.*}"
        local child="${key#*.}"
        
        # This is a simplified update - in production would use jq
        sed -i.bak -E "s/(\"$child\":\s*)(\"[^\"]*\"|[^,}]+)/\1\"$value\"/" "$config_file"
    else
        sed -i.bak -E "s/(\"$key\":\s*)(\"[^\"]*\"|[^,}]+)/\1\"$value\"/" "$config_file"
    fi
}

# Get configuration value
get_config_value() {
    local key="$1"
    local default="$2"
    local config_file="$MEMENTO_DIR/config/settings.json"
    
    if [ -f "$config_file" ]; then
        # Simplified extraction
        local value=$(grep -E "\"${key##*.}\":" "$config_file" | sed -E 's/.*"[^"]+\":\s*"?([^",}]+)"?.*/\1/')
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# Show help
show_help() {
    cat << EOF
Claude Memento Auto-Save Management

Usage: /cm:auto-save [command] [options]

Commands:
  enable              Enable auto-save and start daemon
  disable             Disable auto-save and stop daemon
  start               Start auto-save daemon
  stop                Stop auto-save daemon
  restart             Restart auto-save daemon
  status              Show auto-save status
  save                Force immediate auto-save
  config [key] [val]  Configure auto-save settings

Configuration Keys:
  interval <seconds>      Set save interval (default: 900)
  on-session-end <bool>   Save on session end (default: true)

Examples:
  /cm:auto-save enable
  /cm:auto-save config interval 600    # 10 minutes
  /cm:auto-save config on-session-end false
  /cm:auto-save status
EOF
}

# Run main function
main "$@"