#!/bin/bash

# Claude Memento Update System - Utility Functions
# Provides common utility functions for the update system

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure UPDATE_LOG is set
UPDATE_LOG="${UPDATE_LOG:-$HOME/.claude/memento/update.log}"

# Function: Print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function: Print error and exit
error_exit() {
    print_color "$RED" "❌ Error: $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$UPDATE_LOG"
    exit 1
}

# Function: Print warning
warn() {
    print_color "$YELLOW" "⚠️  Warning: $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$UPDATE_LOG"
}

# Function: Print info
info() {
    print_color "$BLUE" "ℹ️  $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> "$UPDATE_LOG"
}

# Function: Print success
success() {
    print_color "$GREEN" "✅ $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $1" >> "$UPDATE_LOG"
}

# Function: Print verbose message (only if VERBOSE is true)
verbose() {
    if [ "${VERBOSE:-false}" = true ]; then
        info "$1"
    fi
}

# Function: Ensure directory exists
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || error_exit "Failed to create directory: $dir"
    fi
}

# Function: Safe copy with error handling
safe_copy() {
    local source="$1"
    local dest="$2"
    
    if [ ! -e "$source" ]; then
        error_exit "Source does not exist: $source"
    fi
    
    cp -r "$source" "$dest" || error_exit "Failed to copy $source to $dest"
}

# Function: Check if running in dry-run mode
is_dry_run() {
    [ "${DRY_RUN:-false}" = true ]
}

# Function: Execute command with dry-run support
execute_cmd() {
    local cmd="$1"
    local description="${2:-$cmd}"
    
    if is_dry_run; then
        info "[DRY RUN] Would execute: $description"
        return 0
    else
        verbose "Executing: $description"
        eval "$cmd"
        return $?
    fi
}

# Function: Get timestamp
get_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# Function: Get ISO timestamp
get_iso_timestamp() {
    date -Iseconds
}

# Function: Calculate directory size
get_dir_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

# Export functions for use in other scripts
export -f print_color error_exit warn info success verbose
export -f ensure_dir safe_copy is_dry_run execute_cmd
export -f get_timestamp get_iso_timestamp get_dir_size