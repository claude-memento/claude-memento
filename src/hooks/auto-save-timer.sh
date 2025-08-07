#!/bin/bash

# Auto-save Timer for Claude Memento
# Periodically saves checkpoints based on configuration

MEMENTO_DIR="${MEMENTO_DIR:-$HOME/.claude/memento}"
source "$MEMENTO_DIR/src/utils/logger.sh" 2>/dev/null
source "$MEMENTO_DIR/src/utils/common.sh" 2>/dev/null

# Default settings
DEFAULT_INTERVAL=900  # 15 minutes in seconds
PID_FILE="$MEMENTO_DIR/.auto-save.pid"
LAST_SAVE_FILE="$MEMENTO_DIR/.last-auto-save"

# Get configuration
get_config() {
    local key=$1
    local default=$2
    
    if [ -f "$MEMENTO_DIR/config/settings.json" ]; then
        local value=$(grep -E "\"$key\":" "$MEMENTO_DIR/config/settings.json" | sed -E 's/.*"'$key'":\s*"?([^",}]+)"?.*/\1/')
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# Check if auto-save is enabled
is_enabled() {
    local enabled=$(get_config "autoSave.enabled" "false")
    [[ "$enabled" == "true" ]]
}

# Get save interval
get_interval() {
    local interval=$(get_config "autoSave.interval" "$DEFAULT_INTERVAL")
    echo "$interval"
}

# Check if enough time has passed
should_save() {
    local interval=$(get_interval)
    local now=$(date +%s)
    
    if [ -f "$LAST_SAVE_FILE" ]; then
        local last_save=$(cat "$LAST_SAVE_FILE" 2>/dev/null || echo "0")
        local elapsed=$((now - last_save))
        
        if [ $elapsed -ge $interval ]; then
            return 0
        else
            return 1
        fi
    else
        # First run, should save
        return 0
    fi
}

# Check for changes
has_changes() {
    # Check context file modification time
    if [ -f "$MEMENTO_DIR/claude-context.md" ]; then
        local last_save=$(cat "$LAST_SAVE_FILE" 2>/dev/null || echo "0")
        local file_mtime=$(stat -f %m "$MEMENTO_DIR/claude-context.md" 2>/dev/null || stat -c %Y "$MEMENTO_DIR/claude-context.md" 2>/dev/null || echo "0")
        
        if [ $file_mtime -gt $last_save ]; then
            return 0
        fi
    fi
    
    return 1
}

# Perform auto-save
do_auto_save() {
    local reason="Auto-save: $(date '+%Y-%m-%d %H:%M:%S')"
    
    log_info "Performing auto-save..."
    
    if [ -f "$MEMENTO_DIR/src/commands/save.sh" ]; then
        "$MEMENTO_DIR/src/commands/save.sh" "$reason" >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            # Update last save time
            date +%s > "$LAST_SAVE_FILE"
            log_success "Auto-save completed"
            return 0
        else
            log_error "Auto-save failed"
            return 1
        fi
    else
        log_error "Save command not found"
        return 1
    fi
}

# Start daemon
start_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "Auto-save daemon already running (PID: $pid)"
            return 1
        fi
    fi
    
    log_info "Starting auto-save daemon..."
    
    # Run in background with proper detachment
    (
        # Detach from terminal
        trap '' HUP
        
        while true; do
            if is_enabled && should_save && has_changes; then
                do_auto_save
            fi
            
            # Sleep for 1 minute, check more frequently than save interval
            sleep 60
        done
    ) > /dev/null 2>&1 &
    
    local daemon_pid=$!
    echo $daemon_pid > "$PID_FILE"
    
    # Verify daemon started
    sleep 1
    if kill -0 "$daemon_pid" 2>/dev/null; then
        log_success "Auto-save daemon started (PID: $daemon_pid)"
    else
        rm -f "$PID_FILE"
        log_error "Failed to start auto-save daemon"
        return 1
    fi
}

# Stop daemon
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            log_success "Auto-save daemon stopped"
        else
            rm -f "$PID_FILE"
            log_warn "Auto-save daemon not running"
        fi
    else
        log_warn "No PID file found"
    fi
}

# Status check
check_status() {
    echo "Auto-Save Status:"
    echo "================="
    
    # Check if enabled
    if is_enabled; then
        echo "Enabled: Yes"
        echo "Interval: $(get_interval) seconds ($(( $(get_interval) / 60 )) minutes)"
    else
        echo "Enabled: No"
    fi
    
    # Check daemon
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Daemon: Running (PID: $pid)"
        else
            echo "Daemon: Not running (stale PID file)"
        fi
    else
        echo "Daemon: Not running"
    fi
    
    # Last save
    if [ -f "$LAST_SAVE_FILE" ]; then
        local last_save=$(cat "$LAST_SAVE_FILE")
        local last_save_date=$(date -r "$last_save" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -d "@$last_save" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
        echo "Last save: $last_save_date"
    else
        echo "Last save: Never"
    fi
}

# Main command handling
case "${1:-status}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    status)
        check_status
        ;;
    save)
        # Force immediate save
        if is_enabled; then
            do_auto_save
        else
            log_error "Auto-save is disabled"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|save}"
        exit 1
        ;;
esac