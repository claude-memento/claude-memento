#!/bin/bash

# Claude Memento Update Script
# Updates Claude Memento to the latest version while preserving user data
# Principle: "Move Nothing, Replace Only" - User data stays in place, only system files are updated

set -e  # Exit on error

# Script info
SCRIPT_NAME="Claude Memento Update"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# System directories
export CLAUDE_DIR="$HOME/.claude"
export MEMENTO_DIR="$CLAUDE_DIR/memento"
export BACKUP_DIR="$MEMENTO_DIR/.backup"
export UPDATE_LOG="$MEMENTO_DIR/update.log"

# User data directories (preserve these)
export USER_DATA_DIRS=(
    "checkpoints"
    "chunks"
    "settings"
)

# System directories (replace these)
export SYSTEM_DIRS=(
    "src"
    "commands"
    "templates"
)

# System files (replace these)
export SYSTEM_FILES=(
    "cm.sh"
    "claude-memento.sh"
)

# Flags
export DRY_RUN=false
export FORCE_UPDATE=false
export VERBOSE=false
export BACKUP_ONLY=false
export RESTORE_BACKUP=false
export VERSION_CHECK_ONLY=false
export SKIP_BACKUP=false
export SELECTIVE_UPDATE=""
export UPDATE_ALL=true
export SKIP_ITEMS=""
export SOURCE_DIR=""

# Source library modules
LIB_DIR="$SCRIPT_DIR/lib/update"
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/backup.sh"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/rollback.sh"

# Source version management if available
VERSION_SCRIPT="$SCRIPT_DIR/src/version.sh"
if [ -f "$VERSION_SCRIPT" ]; then
    source "$VERSION_SCRIPT"
    VERSION_MANAGEMENT_AVAILABLE=true
else
    VERSION_MANAGEMENT_AVAILABLE=false
fi

# Function: Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Updates Claude Memento to the latest version while preserving user data.

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show script version
    -d, --dry-run           Show what would be updated without making changes
    -f, --force             Force update even if already on latest version
    -V, --verbose           Show detailed output
    -b, --backup-only       Only create backup without updating
    -r, --restore           Restore from previous backup
    -c, --check-version     Only check version without updating
    --skip-backup           Skip backup creation (not recommended)
    --source PATH           Path to new version source (default: current directory)
    --selective ITEMS       Update only specific items (comma-separated)
                           Available: src,commands,templates,wrappers,claude-md
    --skip ITEMS           Skip specific items during update (comma-separated)

EXAMPLES:
    $0                      # Normal update with backup (all components)
    $0 --dry-run            # Preview what would be updated
    $0 --selective src,commands  # Update only src and commands directories
    $0 --skip claude-md     # Update everything except CLAUDE.md
    $0 --force              # Force update even if on latest version
    $0 --restore            # Restore from previous backup

EOF
}

# Function: Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION"
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE_UPDATE=true
                shift
                ;;
            -V|--verbose)
                VERBOSE=true
                shift
                ;;
            -b|--backup-only)
                BACKUP_ONLY=true
                shift
                ;;
            -r|--restore)
                RESTORE_BACKUP=true
                shift
                ;;
            -c|--check-version)
                VERSION_CHECK_ONLY=true
                shift
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --source)
                SOURCE_DIR="$2"
                shift 2
                ;;
            --selective)
                SELECTIVE_UPDATE="$2"
                UPDATE_ALL=false
                shift 2
                ;;
            --skip)
                SKIP_ITEMS="$2"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done
}

# Function: Check if Claude Memento is installed
check_installation() {
    if [ ! -d "$MEMENTO_DIR" ]; then
        error_exit "Claude Memento is not installed. Please run install.sh first."
    fi
    
    if [ ! -f "$MEMENTO_DIR/cm.sh" ]; then
        error_exit "Claude Memento installation appears to be corrupted. Missing cm.sh"
    fi
}

# Function: Get current version
get_current_version() {
    if [ "$VERSION_MANAGEMENT_AVAILABLE" = true ] && type -t get_installed_version >/dev/null 2>&1; then
        get_installed_version
    else
        local version_file="$MEMENTO_DIR/VERSION"
        if [ -f "$version_file" ]; then
            cat "$version_file"
        elif [ -f "$MEMENTO_DIR/.install.log" ]; then
            grep "Version:" "$MEMENTO_DIR/.install.log" | cut -d' ' -f2
        else
            echo "unknown"
        fi
    fi
}

# Function: Get new version
get_new_version() {
    local version_file="${SOURCE_DIR:-$SCRIPT_DIR}/VERSION"
    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo "unknown"
    fi
}

# Function: Compare versions
compare_versions() {
    local current=$1
    local new=$2
    
    # If either version is unknown, recommend update
    if [ "$current" = "unknown" ] || [ "$new" = "unknown" ]; then
        return 1
    fi
    
    # Simple string comparison for now
    if [ "$current" = "$new" ]; then
        return 0
    else
        return 1
    fi
}

# Function: Validate update
validate_update() {
    info "Validating update..."
    
    # Verify file integrity
    if ! verify_update; then
        error_exit "Update validation failed. Files are missing or corrupted."
    fi
    
    # Test basic functionality
    if [ -f "$MEMENTO_DIR/cm.sh" ]; then
        if ! bash -n "$MEMENTO_DIR/cm.sh" 2>/dev/null; then
            warn "Syntax error detected in cm.sh"
            return 1
        fi
    fi
    
    # Validate configuration if available
    if type -t validate_config >/dev/null 2>&1; then
        validate_config || warn "Configuration validation failed"
    fi
    
    success "Update validated successfully"
}

# Function: Main update process
perform_update() {
    local current_version=$(get_current_version)
    local new_version=$(get_new_version)
    
    info "Current version: $current_version"
    info "New version: $new_version"
    
    # Use enhanced version checking if available
    if [ "$VERSION_MANAGEMENT_AVAILABLE" = true ] && type -t check_compatibility >/dev/null 2>&1; then
        if ! check_compatibility "$current_version" "$new_version"; then
            if [ "$FORCE_UPDATE" != true ]; then
                error_exit "Version compatibility check failed. Use --force to override."
            else
                warn "Forcing update despite compatibility warnings"
            fi
        fi
    elif compare_versions "$current_version" "$new_version" && [ "$FORCE_UPDATE" = false ]; then
        info "Already on the latest version"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        info "DRY RUN MODE - No changes will be made"
    fi
    
    # Initialize rollback system
    init_rollback
    
    # Create backup unless skipped
    if [ "$SKIP_BACKUP" != true ]; then
        create_backup || {
            error_exit "Backup creation failed. Aborting update."
        }
    fi
    
    # Set trap for error handling
    trap 'handle_update_error' ERR
    
    # Update system files
    set_update_stage "system_files"
    update_system_files || {
        warn "System files update failed"
        trigger_rollback "System files update failed"
        return 1
    }
    
    # Perform version migrations if available
    if [ "$VERSION_MANAGEMENT_AVAILABLE" = true ] && type -t migrate_version >/dev/null 2>&1; then
        info "Checking for version migrations..."
        migrate_version "$current_version" "$new_version"
    fi
    
    # Save new version
    if [ "$VERSION_MANAGEMENT_AVAILABLE" = true ] && type -t save_version >/dev/null 2>&1; then
        save_version "$new_version"
    fi
    
    # Update CLAUDE.md
    set_update_stage "claude_md"
    update_claude_md || {
        warn "CLAUDE.md update failed"
        trigger_rollback "CLAUDE.md update failed"
        return 1
    }
    
    # Merge configuration
    set_update_stage "config"
    merge_config || {
        warn "Configuration merge failed"
        trigger_rollback "Configuration merge failed"
        return 1
    }
    
    # Validate update
    if ! validate_update; then
        warn "Update validation failed"
        trigger_rollback "Update validation failed"
        return 1
    fi
    
    # Clear trap
    trap - ERR
    
    # Commit rollback point (mark as successful)
    commit_update
    
    success "Update completed successfully!"
}

# Main execution
main() {
    print_color "$GREEN" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "     Claude Memento Update Script v$SCRIPT_VERSION"
    print_color "$GREEN" "═══════════════════════════════════════════════════════════════"
    echo
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize log file
    ensure_dir "$(dirname "$UPDATE_LOG")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Update started" >> "$UPDATE_LOG"
    
    # Check installation
    check_installation
    
    # Handle different modes
    if [ "$VERSION_CHECK_ONLY" = true ]; then
        info "Current version: $(get_current_version)"
        info "Available version: $(get_new_version)"
        exit 0
    fi
    
    if [ "$RESTORE_BACKUP" = true ]; then
        restore_backup
        exit 0
    fi
    
    if [ "$BACKUP_ONLY" = true ]; then
        create_backup
        exit 0
    fi
    
    # Perform update
    perform_update
    
    echo
    print_color "$GREEN" "═══════════════════════════════════════════════════════════════"
    print_color "$GREEN" "     Update Process Complete"
    print_color "$GREEN" "═══════════════════════════════════════════════════════════════"
}

# Run main function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi