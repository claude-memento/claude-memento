#!/bin/bash

# Claude Code Session End Hook
# Automatically saves checkpoint when session ends

MEMENTO_DIR="${MEMENTO_DIR:-$HOME/.claude/memento}"
source "$MEMENTO_DIR/src/utils/logger.sh" 2>/dev/null || {
    echo "[$(date)] Failed to load logger" >> "$MEMENTO_DIR/logs/hooks.log"
    exit 1
}

# Check if we should auto-save
should_auto_save() {
    # Check if auto-save is enabled
    local auto_save_enabled=$(grep -E '"autoSave":\s*true' "$MEMENTO_DIR/config/settings.json" 2>/dev/null || echo "false")
    
    if [[ "$auto_save_enabled" == *"true"* ]]; then
        return 0
    else
        return 1
    fi
}

# Check if there are changes to save
has_changes() {
    # Check if context file exists and has content
    if [ -f "$MEMENTO_DIR/claude-context.md" ] && [ -s "$MEMENTO_DIR/claude-context.md" ]; then
        # Check if file was modified recently (within last hour)
        local modified=$(find "$MEMENTO_DIR/claude-context.md" -mmin -60 2>/dev/null | wc -l)
        if [ $modified -gt 0 ]; then
            return 0
        fi
    fi
    
    return 1
}

# Main execution
main() {
    log_info "Session end hook triggered"
    
    # Check if auto-save is enabled
    if ! should_auto_save; then
        log_debug "Auto-save disabled, skipping"
        exit 0
    fi
    
    # Check if there are changes
    if ! has_changes; then
        log_debug "No recent changes, skipping save"
        exit 0
    fi
    
    # Generate reason with timestamp
    local reason="Auto-save: Session ended at $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Execute save command
    log_info "Creating auto-save checkpoint..."
    
    if [ -f "$MEMENTO_DIR/src/commands/save.sh" ]; then
        "$MEMENTO_DIR/src/commands/save.sh" "$reason"
        
        if [ $? -eq 0 ]; then
            log_success "Auto-save checkpoint created successfully"
        else
            log_error "Failed to create auto-save checkpoint"
        fi
    else
        log_error "Save command not found"
    fi
}

# Run main function
main "$@"