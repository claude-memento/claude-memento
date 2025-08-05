#!/bin/bash

# Claude Memento CLI
# Main entry point for command line interface

VERSION="1.0.0"
MEMENTO_DIR="$HOME/.claude/memento"

# Source utilities
source "$MEMENTO_DIR/utils/common.sh"
source "$MEMENTO_DIR/utils/logger.sh"

# Show help
show_help() {
    cat << EOF
Claude Memento v$VERSION - Memory Management for SuperClaude

Usage: claude-memento [COMMAND] [OPTIONS]

Commands:
  save [reason]      Create a checkpoint with optional reason
  load [checkpoint]  Load context from memory or specific checkpoint
  status            Show current memory status
  last              Show last checkpoint
  list              List all checkpoints
  config            Manage configuration
  help              Show this help message
  version           Show version information

Options:
  -v, --verbose     Enable verbose output
  -q, --quiet       Suppress non-error output
  -f, --force       Force operation without confirmation

Examples:
  claude-memento save "Completed API implementation"
  claude-memento load
  claude-memento status

For SuperClaude integration, use /cm: prefix:
  /cm:save "Checkpoint reason"
  /cm:status
  /cm:load

Documentation: https://github.com/claude-memento/claude-memento
EOF
}

# Main command handler
main() {
    case "${1:-help}" in
        save)
            shift
            "$MEMENTO_DIR/commands/save.sh" "$@"
            ;;
        load)
            shift
            "$MEMENTO_DIR/commands/load.sh" "$@"
            ;;
        status)
            shift
            "$MEMENTO_DIR/commands/status.sh" "$@"
            ;;
        last)
            shift
            "$MEMENTO_DIR/commands/last.sh" "$@"
            ;;
        list)
            shift
            "$MEMENTO_DIR/commands/list.sh" "$@"
            ;;
        config)
            shift
            "$MEMENTO_DIR/commands/config.sh" "$@"
            ;;
        --version|-v|version)
            echo "Claude Memento v$VERSION"
            ;;
        --help|-h|help)
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run 'claude-memento help' for usage information."
            exit 1
            ;;
    esac
}

# Run main function
main "$@"