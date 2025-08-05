#!/bin/bash

# Logger utilities for Claude Memento

# Log levels
LOG_ERROR=1
LOG_WARN=2
LOG_INFO=3
LOG_DEBUG=4

# Current log level (default: INFO)
LOG_LEVEL=${LOG_LEVEL:-3}

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log functions
log_error() {
    [ $LOG_LEVEL -ge $LOG_ERROR ] && echo -e "${RED}❌ ERROR: $*${NC}" >&2
}

log_warn() {
    [ $LOG_LEVEL -ge $LOG_WARN ] && echo -e "${YELLOW}⚠️  WARN: $*${NC}" >&2
}

log_info() {
    [ $LOG_LEVEL -ge $LOG_INFO ] && echo -e "${GREEN}ℹ️  INFO: $*${NC}"
}

log_debug() {
    [ $LOG_LEVEL -ge $LOG_DEBUG ] && echo -e "${BLUE}🔧 DEBUG: $*${NC}"
}

# Success message
log_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

# Progress indicator
log_progress() {
    echo -e "${BLUE}⏳ $*${NC}"
}

# Write to log file
write_log() {
    local level=$1
    shift
    local message="$*"
    local log_file="$HOME/.claude/memento/logs/memento.log"
    
    # Create log directory if needed
    mkdir -p "$(dirname "$log_file")"
    
    # Write log entry
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$log_file"
}

# Combined logging (console + file)
log() {
    local level=$1
    shift
    
    case $level in
        ERROR)
            log_error "$@"
            write_log "ERROR" "$@"
            ;;
        WARN)
            log_warn "$@"
            write_log "WARN" "$@"
            ;;
        INFO)
            log_info "$@"
            write_log "INFO" "$@"
            ;;
        DEBUG)
            log_debug "$@"
            write_log "DEBUG" "$@"
            ;;
    esac
}