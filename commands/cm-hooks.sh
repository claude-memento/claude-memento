#!/usr/bin/env bash

# Claude Memento Hooks Management Command
# Usage: /cm:hooks [command] [options]

MEMENTO_DIR="${MEMENTO_DIR:-$HOME/.claude/memento}"

# Load dependencies
source "$MEMENTO_DIR/src/utils/common.sh"
source "$MEMENTO_DIR/src/utils/logger.sh"
source "$MEMENTO_DIR/src/core/hooks.sh"

# Show usage
show_usage() {
    echo "${BLUE}🎣 Claude Memento Hooks Management${NC}"
    echo "================================="
    echo ""
    echo "${YELLOW}Usage:${NC}"
    echo "  /cm:hooks [command] [options]"
    echo ""
    echo "${YELLOW}Commands:${NC}"
    echo "  init                    - Initialize hook system"
    echo "  list                    - List available hooks"
    echo "  status                  - Show hook system status"
    echo "  test                    - Test hook system"
    echo "  logs [lines]            - Show hook execution logs"
    echo "  clean-logs [days]       - Clean old hook logs"
    echo "  create <phase> <name>   - Create new hook template"
    echo "  edit <phase> <name>     - Edit existing hook"
    echo "  remove <phase> <name>   - Remove hook"
    echo "  enable <phase> <name>   - Enable hook (make executable)"
    echo "  disable <phase> <name>  - Disable hook (remove execute permission)"
    echo ""
    echo "${YELLOW}Examples:${NC}"
    echo "  /cm:hooks init"
    echo "  /cm:hooks list"
    echo "  /cm:hooks create post notify-slack"
    echo "  /cm:hooks test"
    echo "  /cm:hooks logs 50"
}

# Create new hook template
create_hook() {
    local phase="$1"
    local name="$2"
    
    if [ -z "$phase" ] || [ -z "$name" ]; then
        log_error "Usage: create <phase> <name>"
        echo "Phase: pre or post"
        echo "Name: hook script name (without extension)"
        return 1
    fi
    
    if [ "$phase" != "pre" ] && [ "$phase" != "post" ]; then
        log_error "Phase must be 'pre' or 'post'"
        return 1
    fi
    
    local hook_file="$HOOKS_DIR/$phase/$name.sh"
    
    if [ -f "$hook_file" ]; then
        log_error "Hook already exists: $hook_file"
        return 1
    fi
    
    # Create hook directory if needed
    mkdir -p "$HOOKS_DIR/$phase"
    
    # Create hook template
    cat > "$hook_file" << EOF
#!/usr/bin/env bash

# Claude Memento Hook: $name
# Phase: $phase
# Created: $(date)

# Load common utilities for cross-platform support
if [ -f "\$MEMENTO_DIR/src/utils/common.sh" ]; then
    source "\$MEMENTO_DIR/src/utils/common.sh"
fi

# Hook environment variables:
# \$HOOK_EVENT     - Event type (checkpoint, load, cleanup, config, list)
# \$HOOK_PHASE     - Hook phase (pre, post)  
# \$HOOK_CONTEXT   - Event context (JSON)
# \$MEMENTO_DIR    - Claude Memento directory
# \$OS_TYPE        - Operating system (macos, linux, windows, wsl)
# \$SHELL_TYPE     - Shell type (bash, zsh, etc)

echo "Hook: $name (\$HOOK_PHASE-\$HOOK_EVENT)"

# Example: Handle different events
case "\$HOOK_EVENT" in
    checkpoint)
        echo "Checkpoint event - implement your logic here"
        # Example: show_notification "Claude Memento" "Checkpoint created"
        ;;
    load)
        echo "Load event - implement your logic here"
        ;;
    cleanup)
        echo "Cleanup event - implement your logic here"
        ;;
    config)
        echo "Config event - implement your logic here"
        ;;
    list)
        echo "List event - implement your logic here"
        ;;
    *)
        echo "Unknown event: \$HOOK_EVENT"
        ;;
esac

# Exit with success
exit 0
EOF
    
    # Make executable
    if [ "$OS_TYPE" != "windows" ]; then
        chmod +x "$hook_file"
    fi
    
    log_success "Hook created: $hook_file"
    echo "Edit the hook file to customize its behavior"
    
    # Optionally open in editor
    if has_command "\$EDITOR"; then
        echo "Opening in editor..."
        \$EDITOR "$hook_file"
    fi
}

# Edit existing hook
edit_hook() {
    local phase="$1"
    local name="$2"
    
    if [ -z "$phase" ] || [ -z "$name" ]; then
        log_error "Usage: edit <phase> <name>"
        return 1
    fi
    
    local hook_file="$HOOKS_DIR/$phase/$name.sh"
    
    if [ ! -f "$hook_file" ]; then
        # Try without .sh extension
        hook_file="$HOOKS_DIR/$phase/$name"
        if [ ! -f "$hook_file" ]; then
            log_error "Hook not found: $phase/$name"
            return 1
        fi
    fi
    
    # Determine editor
    local editor="${EDITOR:-nano}"
    
    # Use system-specific editor if EDITOR not set
    if [ "$editor" = "nano" ] && ! has_command nano; then
        case "$OS_TYPE" in
            macos)
                editor="open -t"
                ;;
            windows)
                editor="notepad"
                ;;
            *)
                if has_command vim; then
                    editor="vim"
                elif has_command vi; then
                    editor="vi"
                else
                    editor="cat"
                fi
                ;;
        esac
    fi
    
    echo "Opening $hook_file in $editor..."
    $editor "$hook_file"
}

# Remove hook
remove_hook() {
    local phase="$1"
    local name="$2"
    
    if [ -z "$phase" ] || [ -z "$name" ]; then
        log_error "Usage: remove <phase> <name>"
        return 1
    fi
    
    local hook_file="$HOOKS_DIR/$phase/$name.sh"
    
    if [ ! -f "$hook_file" ]; then
        # Try without .sh extension
        hook_file="$HOOKS_DIR/$phase/$name"
        if [ ! -f "$hook_file" ]; then
            log_error "Hook not found: $phase/$name"
            return 1
        fi
    fi
    
    # Confirm removal
    echo -n "Remove hook $phase/$name? (y/N): "
    read -r confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        rm -f "$hook_file"
        log_success "Hook removed: $phase/$name"
    else
        echo "Cancelled"
    fi
}

# Enable hook (make executable)
enable_hook() {
    local phase="$1"
    local name="$2"
    
    if [ -z "$phase" ] || [ -z "$name" ]; then
        log_error "Usage: enable <phase> <name>"
        return 1
    fi
    
    local hook_file="$HOOKS_DIR/$phase/$name.sh"
    
    if [ ! -f "$hook_file" ]; then
        hook_file="$HOOKS_DIR/$phase/$name"
        if [ ! -f "$hook_file" ]; then
            log_error "Hook not found: $phase/$name"
            return 1
        fi
    fi
    
    if [ "$OS_TYPE" != "windows" ]; then
        chmod +x "$hook_file"
        log_success "Hook enabled: $phase/$name"
    else
        log_info "On Windows, all files are executable by default"
    fi
}

# Disable hook (remove execute permission)
disable_hook() {
    local phase="$1"
    local name="$2"
    
    if [ -z "$phase" ] || [ -z "$name" ]; then
        log_error "Usage: disable <phase> <name>"
        return 1
    fi
    
    local hook_file="$HOOKS_DIR/$phase/$name.sh"
    
    if [ ! -f "$hook_file" ]; then
        hook_file="$HOOKS_DIR/$phase/$name"
        if [ ! -f "$hook_file" ]; then
            log_error "Hook not found: $phase/$name"
            return 1
        fi
    fi
    
    if [ "$OS_TYPE" != "windows" ]; then
        chmod -x "$hook_file"
        log_success "Hook disabled: $phase/$name"
    else
        # On Windows, rename to .disabled
        mv "$hook_file" "${hook_file}.disabled"
        log_success "Hook disabled: $phase/$name (renamed to .disabled)"
    fi
}

# Main command handler
main() {
    local command="$1"
    shift
    
    case "$command" in
        ""|help|-h|--help)
            show_usage
            ;;
        init)
            init_hooks
            ;;
        list)
            list_hooks
            ;;
        status)
            hook_status
            ;;
        test)
            test_hooks
            ;;
        logs)
            show_hook_logs "$@"
            ;;
        clean-logs)
            clean_hook_logs "$@"
            ;;
        create)
            create_hook "$@"
            ;;
        edit)
            edit_hook "$@"
            ;;
        remove|rm)
            remove_hook "$@"
            ;;
        enable)
            enable_hook "$@"
            ;;
        disable)
            disable_hook "$@"
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"