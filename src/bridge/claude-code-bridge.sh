#!/bin/bash

# Claude Code Bridge for Claude Memento
# Connects Claude Code .md commands to actual shell implementations

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMENTO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
COMMANDS_DIR="$MEMENTO_DIR/commands"

# Source common utilities
source "$MEMENTO_DIR/utils/common.sh" 2>/dev/null || {
    echo "Error: Could not load common utilities"
    exit 1
}

# Bridge function to execute actual commands
execute_command() {
    local cmd="$1"
    shift
    local args="$@"
    
    case "$cmd" in
        "save")
            "$COMMANDS_DIR/save.sh" $args
            ;;
        "load")
            "$COMMANDS_DIR/load.sh" $args
            ;;
        "list")
            "$COMMANDS_DIR/list.sh" $args
            ;;
        "status")
            "$COMMANDS_DIR/status.sh" $args
            ;;
        "config")
            "$COMMANDS_DIR/config.sh" $args
            ;;
        "hooks")
            "$MEMENTO_DIR/core/hooks.sh" $args
            ;;
        "last")
            "$COMMANDS_DIR/last.sh" $args
            ;;
        *)
            echo "Unknown command: $cmd"
            echo "Available commands: save, load, list, status, config, hooks, last"
            exit 1
            ;;
    esac
}

# Check if we're being called from Claude Code
if [ -n "$CLAUDE_CODE_SESSION" ] || [ -n "$CLAUDE_MEMENTO_BRIDGE" ]; then
    # Extract command from script name or first argument
    if [[ "$0" =~ cm-([^.]+) ]]; then
        CMD="${BASH_REMATCH[1]}"
        execute_command "$CMD" "$@"
    elif [ -n "$1" ]; then
        execute_command "$@"
    else
        echo "Error: No command specified"
        exit 1
    fi
else
    # Direct execution
    execute_command "$@"
fi