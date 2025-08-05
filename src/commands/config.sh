#!/bin/bash

# Config command - Manage configuration

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/src/utils/common.sh"
source "$MEMENTO_DIR/src/utils/logger.sh"

# Configuration file
CONFIG_FILE="$MEMENTO_DIR/config/default.json"

# Parse arguments
ACTION="${1:-show}"
KEY="$2"
VALUE="$3"

# Show configuration
show_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_warn "Configuration file not found, using defaults"
        return 1
    fi
    
    echo "⚙️  Claude Memento Configuration"
    echo "================================"
    echo
    
    if command -v jq &> /dev/null; then
        # Pretty print with jq
        jq . "$CONFIG_FILE"
    else
        # Fallback: simple cat
        cat "$CONFIG_FILE"
    fi
    
    echo
    echo "📄 Config file: $CONFIG_FILE"
}

# Get configuration value
get_config() {
    local key=$1
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found"
        return 1
    fi
    
    if command -v jq &> /dev/null; then
        # Use jq to extract value
        local value=$(jq -r ".$key // empty" "$CONFIG_FILE" 2>/dev/null)
        if [ -n "$value" ]; then
            echo "$key: $value"
        else
            log_error "Key not found: $key"
            return 1
        fi
    else
        # Fallback: grep method
        log_warn "jq not installed, using basic search"
        grep -E "\"${key//./\\\\.|\"}" "$CONFIG_FILE"
    fi
}

# Set configuration value
set_config() {
    local key=$1
    local value=$2
    
    if [ -z "$key" ] || [ -z "$value" ]; then
        log_error "Usage: config set <key> <value>"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found"
        return 1
    fi
    
    # Create backup
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    if command -v jq &> /dev/null; then
        # Use jq to update value
        local temp_file=$(mktemp)
        
        # Convert value to appropriate type
        if [[ "$value" =~ ^[0-9]+$ ]]; then
            # Integer
            jq ".$key = $value" "$CONFIG_FILE" > "$temp_file"
        elif [[ "$value" =~ ^(true|false)$ ]]; then
            # Boolean
            jq ".$key = $value" "$CONFIG_FILE" > "$temp_file"
        else
            # String
            jq ".$key = \"$value\"" "$CONFIG_FILE" > "$temp_file"
        fi
        
        if [ $? -eq 0 ]; then
            mv "$temp_file" "$CONFIG_FILE"
            log_success "Configuration updated: $key = $value"
        else
            log_error "Failed to update configuration"
            rm -f "$temp_file"
            return 1
        fi
    else
        log_error "jq is required to modify configuration"
        echo "Install jq: brew install jq (macOS) or apt-get install jq (Linux)"
        return 1
    fi
}

# Reset configuration
reset_config() {
    echo "⚠️  This will reset all configuration to defaults."
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        return 0
    fi
    
    # Backup current config
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(get_timestamp)"
        log_info "Current config backed up"
    fi
    
    # Create default config
    cat > "$CONFIG_FILE" << 'EOF'
{
  "checkpoint": {
    "retention": 3,
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
EOF
    
    log_success "Configuration reset to defaults"
}

# Main function
main() {
    case "$ACTION" in
        show)
            show_config
            ;;
        get)
            get_config "$KEY"
            ;;
        set)
            set_config "$KEY" "$VALUE"
            ;;
        reset)
            reset_config
            ;;
        help|--help|-h)
            echo "Usage: config [show|get|set|reset]"
            echo
            echo "Commands:"
            echo "  show           Show all configuration"
            echo "  get <key>      Get specific configuration value"
            echo "  set <key> <value>  Set configuration value"
            echo "  reset          Reset to default configuration"
            echo
            echo "Examples:"
            echo "  config show"
            echo "  config get checkpoint.retention"
            echo "  config set checkpoint.retention 5"
            echo "  config reset"
            ;;
        *)
            log_error "Unknown action: $ACTION"
            echo "Run 'config help' for usage information"
            return 1
            ;;
    esac
}

# Run main function
main