#!/usr/bin/env bash

# Claude Memento Indexing System
# Cross-platform compatible (Windows/macOS/Linux, bash/zsh)

# Load common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/logger.sh"

# Index configuration
INDEX_FILE="$MEMENTO_DIR/.index.json"
INDEX_LOCK="$MEMENTO_DIR/.index.lock"
INDEX_BACKUP="$MEMENTO_DIR/.index.backup.json"
INDEX_VERSION="1.0"
INDEX_AUTO_UPDATE="${MEMENTO_INDEX_AUTO_UPDATE:-true}"

# Initialize indexing system
init_index() {
    log_info "Initializing index system..."
    
    # Create index file if it doesn't exist
    if [ ! -f "$INDEX_FILE" ]; then
        create_empty_index
    fi
    
    # Validate existing index
    if ! validate_index; then
        log_warn "Invalid index file, rebuilding..."
        rebuild_index
    fi
    
    log_success "Index system initialized"
}

# Create empty index structure
create_empty_index() {
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    cat > "$INDEX_FILE" << EOF
{
  "version": "$INDEX_VERSION",
  "created": "$timestamp",
  "updated": "$timestamp",
  "checkpoints": [],
  "memory": {
    "long_term": null,
    "session": null
  },
  "stats": {
    "total_checkpoints": 0,
    "total_size": 0,
    "compressed_count": 0,
    "last_cleanup": null
  }
}
EOF
    
    log_debug "Created empty index"
}

# Validate index file
validate_index() {
    if [ ! -f "$INDEX_FILE" ]; then
        return 1
    fi
    
    # Basic JSON validation
    if has_command jq; then
        jq empty "$INDEX_FILE" 2>/dev/null
    else
        # Fallback: basic structure check
        grep -q '"version"' "$INDEX_FILE" && \
        grep -q '"checkpoints"' "$INDEX_FILE" && \
        grep -q '^{' "$INDEX_FILE" && \
        grep -q '}$' "$INDEX_FILE"
    fi
}

# Create index lock
create_lock() {
    local timeout="${1:-10}"
    local count=0
    
    while [ $count -lt $timeout ]; do
        if (set -C; echo $$ > "$INDEX_LOCK") 2>/dev/null; then
            return 0
        fi
        
        # Check if lock process is still running
        if [ -f "$INDEX_LOCK" ]; then
            local lock_pid=$(cat "$INDEX_LOCK" 2>/dev/null)
            if [ -n "$lock_pid" ] && ! is_process_running "$lock_pid"; then
                log_warn "Removing stale lock (PID: $lock_pid)"
                rm -f "$INDEX_LOCK"
            fi
        fi
        
        sleep 1
        count=$((count + 1))
    done
    
    log_error "Failed to acquire index lock"
    return 1
}

# Remove index lock
remove_lock() {
    rm -f "$INDEX_LOCK"
}

# Backup index file
backup_index() {
    if [ -f "$INDEX_FILE" ]; then
        cp "$INDEX_FILE" "$INDEX_BACKUP"
        log_debug "Index backed up"
    fi
}

# Restore index from backup
restore_index() {
    if [ -f "$INDEX_BACKUP" ]; then
        cp "$INDEX_BACKUP" "$INDEX_FILE"
        log_info "Index restored from backup"
        return 0
    fi
    return 1
}

# Rebuild complete index
rebuild_index() {
    log_info "Rebuilding index..."
    
    if ! create_lock; then
        return 1
    fi
    
    # Backup current index
    backup_index
    
    local temp_index=$(create_temp_file "index")
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local checkpoints_dir="$MEMENTO_DIR/checkpoints"
    
    # Start JSON structure
    cat > "$temp_index" << EOF
{
  "version": "$INDEX_VERSION",
  "created": "$timestamp",
  "updated": "$timestamp",
  "checkpoints": [
EOF
    
    # Index checkpoints
    local first=true
    local total_count=0
    local total_size=0
    local compressed_count=0
    
    if [ -d "$checkpoints_dir" ]; then
        # Process all checkpoint files
        for checkpoint in "$checkpoints_dir"/*; do
            if [ -f "$checkpoint" ]; then
                local basename=$(basename "$checkpoint")
                
                # Skip hidden files and backups
                case "$basename" in
                    .*|*.bak|*.tmp) continue ;;
                esac
                
                # Add comma separator
                if [ "$first" = false ]; then
                    echo "," >> "$temp_index"
                fi
                first=false
                
                # Extract checkpoint metadata
                local checkpoint_info=$(extract_checkpoint_info "$checkpoint")
                echo "    $checkpoint_info" >> "$temp_index"
                
                # Update statistics
                total_count=$((total_count + 1))
                local size=$(get_file_size "$checkpoint")
                total_size=$((total_size + size))
                
                # Check if compressed
                if string_contains "$basename" ".gz" || string_contains "$basename" ".bz2" || \
                   string_contains "$basename" ".xz" || string_contains "$basename" ".Z"; then
                    compressed_count=$((compressed_count + 1))
                fi
            fi
        done
    fi
    
    # Close checkpoints array and add memory info
    cat >> "$temp_index" << EOF
  ],
  "memory": {
    "long_term": $(get_memory_info "long_term"),
    "session": $(get_memory_info "session")
  },
  "stats": {
    "total_checkpoints": $total_count,
    "total_size": $total_size,
    "compressed_count": $compressed_count,
    "last_cleanup": $(get_last_cleanup_time),
    "index_size": $(get_file_size "$INDEX_FILE" 2>/dev/null || echo 0)
  }
}
EOF
    
    # Validate and replace index file
    if validate_json_file "$temp_index"; then
        mv "$temp_index" "$INDEX_FILE"
        log_success "Index rebuilt successfully ($total_count checkpoints)"
    else
        log_error "Failed to rebuild index (invalid JSON)"
        rm -f "$temp_index"
        restore_index
        remove_lock
        return 1
    fi
    
    remove_lock
    return 0
}

# Extract checkpoint information
extract_checkpoint_info() {
    local checkpoint="$1"
    local basename=$(basename "$checkpoint")
    local size=$(get_file_size "$checkpoint")
    local mtime=$(get_file_mtime "$checkpoint")
    local readable_time=$(get_file_mtime_readable "$checkpoint")
    
    # Extract metadata from file content
    local reason=""
    local context_lines=0
    local is_compressed=false
    
    # Check if file is compressed
    if string_contains "$basename" ".gz" || string_contains "$basename" ".bz2" || \
       string_contains "$basename" ".xz" || string_contains "$basename" ".Z"; then
        is_compressed=true
        
        # Try to extract metadata from compressed file
        if has_command zcat && string_contains "$basename" ".gz"; then
            reason=$(zcat "$checkpoint" | grep "^\*\*Reason\*\*:" | head -n 1 | cut -d: -f2- | sed 's/^[ \t]*//' 2>/dev/null || echo "")
            context_lines=$(zcat "$checkpoint" | wc -l 2>/dev/null || echo 0)
        elif has_command bzcat && string_contains "$basename" ".bz2"; then
            reason=$(bzcat "$checkpoint" | grep "^\*\*Reason\*\*:" | head -n 1 | cut -d: -f2- | sed 's/^[ \t]*//' 2>/dev/null || echo "")
            context_lines=$(bzcat "$checkpoint" | wc -l 2>/dev/null || echo 0)
        fi
    else
        # Regular file
        reason=$(grep "^\*\*Reason\*\*:" "$checkpoint" | head -n 1 | cut -d: -f2- | sed 's/^[ \t]*//' 2>/dev/null || echo "")
        context_lines=$(wc -l < "$checkpoint" 2>/dev/null || echo 0)
    fi
    
    # Clean up reason (remove quotes, escape JSON)
    reason=$(echo "$reason" | sed 's/^"//; s/"$//; s/\\/\\\\/g; s/"/\\"/g' | head -c 200)
    if [ -z "$reason" ]; then
        reason="No reason provided"
    fi
    
    # Extract timestamp from filename
    local timestamp=""
    if echo "$basename" | grep -q '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{6\}'; then
        timestamp=$(echo "$basename" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{6\}' | head -n 1)
        # Convert to ISO format
        if [ -n "$timestamp" ]; then
            local year=${timestamp:0:4}
            local month=${timestamp:5:2}
            local day=${timestamp:8:2}
            local hour=${timestamp:11:2}
            local minute=${timestamp:13:2}
            local second=${timestamp:15:2}
            timestamp="${year}-${month}-${day}T${hour}:${minute}:${second}Z"
        fi
    else
        timestamp=$(date -u -r "$mtime" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
    fi
    
    # Generate JSON entry
    cat << EOF
{
      "file": "$basename",
      "path": "$checkpoint",
      "size": $size,
      "mtime": $mtime,
      "timestamp": "$timestamp",
      "readable_time": "$readable_time",
      "reason": "$reason",
      "context_lines": $context_lines,
      "compressed": $is_compressed
    }
EOF
}

# Get memory information
get_memory_info() {
    local memory_type="$1"
    local memory_file=""
    
    case "$memory_type" in
        long_term)
            memory_file="$MEMENTO_DIR/claude-memory.md"
            ;;
        session)
            memory_file="$MEMENTO_DIR/claude-context.md"
            ;;
        *)
            echo "null"
            return
            ;;
    esac
    
    if [ -f "$memory_file" ]; then
        local size=$(get_file_size "$memory_file")
        local mtime=$(get_file_mtime "$memory_file")
        local readable_time=$(get_file_mtime_readable "$memory_file")
        
        cat << EOF
{
      "file": "$(basename "$memory_file")",
      "path": "$memory_file",
      "size": $size,
      "mtime": $mtime,
      "readable_time": "$readable_time"
    }
EOF
    else
        echo "null"
    fi
}

# Get last cleanup time
get_last_cleanup_time() {
    local cleanup_log="$MEMENTO_DIR/logs/cleanup.log"
    
    if [ -f "$cleanup_log" ]; then
        local last_cleanup=$(tail -n 1 "$cleanup_log" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z' | head -n 1)
        if [ -n "$last_cleanup" ]; then
            echo "\"$last_cleanup\""
        else
            echo "null"
        fi
    else
        echo "null"
    fi
}

# Validate JSON file
validate_json_file() {
    local file="$1"
    
    if has_command jq; then
        jq empty "$file" 2>/dev/null
    else
        # Basic validation
        grep -q '^{' "$file" && grep -q '}$' "$file"
    fi
}

# Update index entry
update_index_entry() {
    local operation="$1"  # add, update, remove
    local checkpoint_file="$2"
    
    if [ "$INDEX_AUTO_UPDATE" != "true" ]; then
        log_debug "Index auto-update disabled"
        return 0
    fi
    
    if ! create_lock 5; then
        log_warn "Could not update index (lock timeout)"
        return 1
    fi
    
    case "$operation" in
        add|update)
            log_debug "Updating index entry: $checkpoint_file"
            # For now, just trigger a rebuild for simplicity
            # TODO: Implement incremental updates
            rebuild_index
            ;;
        remove)
            log_debug "Removing index entry: $checkpoint_file"
            rebuild_index
            ;;
        *)
            log_error "Unknown index operation: $operation"
            ;;
    esac
    
    remove_lock
}

# Search index
search_index() {
    local query="$1"
    local field="${2:-all}"  # all, reason, file, content
    local max_results="${3:-10}"
    
    if [ ! -f "$INDEX_FILE" ]; then
        log_error "Index file not found. Run 'rebuild_index' first."
        return 1
    fi
    
    if [ -z "$query" ]; then
        log_error "Search query cannot be empty"
        return 1
    fi
    
    log_debug "Searching index: query='$query', field='$field'"
    
    if has_command jq; then
        # Use jq for advanced searching
        local jq_filter=""
        case "$field" in
            reason)
                jq_filter=".checkpoints[] | select(.reason | ascii_downcase | contains(\"$(echo "$query" | tr '[:upper:]' '[:lower:]')\"))"
                ;;
            file)
                jq_filter=".checkpoints[] | select(.file | ascii_downcase | contains(\"$(echo "$query" | tr '[:upper:]' '[:lower:]')\"))"
                ;;
            all|*)
                jq_filter=".checkpoints[] | select((.reason + \" \" + .file) | ascii_downcase | contains(\"$(echo "$query" | tr '[:upper:]' '[:lower:]')\"))"
                ;;
        esac
        
        jq -r "$jq_filter | \"\\(.timestamp) | \\(.file) | \\(.reason) | \\(.size)\"" "$INDEX_FILE" | head -n "$max_results"
    else
        # Fallback grep-based search
        local pattern=$(echo "$query" | tr '[:upper:]' '[:lower:]')
        
        case "$field" in
            reason)
                grep -i "\"reason\".*$pattern" "$INDEX_FILE" | head -n "$max_results"
                ;;
            file)
                grep -i "\"file\".*$pattern" "$INDEX_FILE" | head -n "$max_results"
                ;;
            all|*)
                grep -i "$pattern" "$INDEX_FILE" | head -n "$max_results"
                ;;
        esac
    fi
}

# Get latest checkpoint from index
get_latest_checkpoint() {
    if [ ! -f "$INDEX_FILE" ]; then
        return 1
    fi
    
    if has_command jq; then
        jq -r '.checkpoints | sort_by(.mtime) | reverse | .[0].path // empty' "$INDEX_FILE"
    else
        # Fallback: simple grep and sort
        grep '"path"' "$INDEX_FILE" | tail -n 1 | cut -d'"' -f4
    fi
}

# Get checkpoint count
get_checkpoint_count() {
    if [ ! -f "$INDEX_FILE" ]; then
        echo 0
        return
    fi
    
    if has_command jq; then
        jq '.stats.total_checkpoints // 0' "$INDEX_FILE"
    else
        grep -c '"file"' "$INDEX_FILE" 2>/dev/null || echo 0
    fi
}

# Get index statistics
get_index_stats() {
    if [ ! -f "$INDEX_FILE" ]; then
        echo "Index not found"
        return 1
    fi
    
    echo "${BLUE}📊 Index Statistics${NC}"
    echo "=================="
    
    if has_command jq; then
        local stats=$(jq '.stats' "$INDEX_FILE" 2>/dev/null)
        if [ -n "$stats" ] && [ "$stats" != "null" ]; then
            echo "$stats" | jq -r '
                "Total checkpoints: \(.total_checkpoints // 0)",
                "Total size: \(.total_size // 0) bytes",
                "Compressed files: \(.compressed_count // 0)",
                "Index size: \(.index_size // 0) bytes"
            '
        fi
        
        local created=$(jq -r '.created // "Unknown"' "$INDEX_FILE")
        local updated=$(jq -r '.updated // "Unknown"' "$INDEX_FILE")
        echo "Created: $created"
        echo "Updated: $updated"
    else
        # Fallback
        local count=$(grep -c '"file"' "$INDEX_FILE" 2>/dev/null || echo 0)
        echo "Total checkpoints: $count"
        echo "Index size: $(get_file_size "$INDEX_FILE") bytes"
    fi
}

# List recent checkpoints from index
list_recent_checkpoints() {
    local count="${1:-10}"
    
    if [ ! -f "$INDEX_FILE" ]; then
        log_error "Index not found. Run 'rebuild_index' first."
        return 1
    fi
    
    echo "${BLUE}📋 Recent Checkpoints (from index)${NC}"
    echo "================================="
    
    if has_command jq; then
        jq -r ".checkpoints | sort_by(.mtime) | reverse | limit($count; .[]) | 
            \"\\(.timestamp) | \\(.file) | \\(.reason) | $(format_size \\(.size))\"" "$INDEX_FILE"
    else
        # Fallback: simple listing
        grep '"file"' "$INDEX_FILE" | head -n "$count"
    fi
}

# Index system status
index_status() {
    echo "${BLUE}📊 Index System Status${NC}"
    echo "====================="
    
    if [ -f "$INDEX_FILE" ]; then
        echo "${GREEN}✅ Index file exists${NC}"
        echo "Location: $INDEX_FILE"
        echo "Size: $(format_size $(get_file_size "$INDEX_FILE"))"
        
        if validate_index; then
            echo "${GREEN}✅ Index is valid${NC}"
        else
            echo "${RED}❌ Index is invalid${NC}"
        fi
    else
        echo "${RED}❌ Index file not found${NC}"
    fi
    
    if [ -f "$INDEX_LOCK" ]; then
        local lock_pid=$(cat "$INDEX_LOCK" 2>/dev/null)
        echo "${YELLOW}⚠️  Index is locked (PID: $lock_pid)${NC}"
    fi
    
    if [ -f "$INDEX_BACKUP" ]; then
        echo "Backup: $(format_size $(get_file_size "$INDEX_BACKUP"))"
    fi
    
    echo "Auto-update: $INDEX_AUTO_UPDATE"
    echo "Version: $INDEX_VERSION"
}

# Clean index (remove orphaned entries)
clean_index() {
    log_info "Cleaning index..."
    
    if ! create_lock; then
        return 1
    fi
    
    local cleaned=0
    local checkpoints_dir="$MEMENTO_DIR/checkpoints"
    
    if [ -f "$INDEX_FILE" ] && has_command jq; then
        # Check for orphaned entries
        local temp_index=$(create_temp_file "index_clean")
        
        jq '.checkpoints | map(select(.path | if test("^/") then . else ("'"$checkpoints_dir"'/" + .) end | test(".") and (. as $path | ("/bin/test -f \"" + $path + "\"") | test("."))))' "$INDEX_FILE" > "$temp_index"
        
        if [ -s "$temp_index" ]; then
            # Count removed entries
            local before=$(jq '.checkpoints | length' "$INDEX_FILE")
            local after=$(jq '. | length' "$temp_index")
            cleaned=$((before - after))
            
            if [ "$cleaned" -gt 0 ]; then
                # Update index with cleaned entries
                jq --argjson new_checkpoints "$(cat "$temp_index")" '.checkpoints = $new_checkpoints | .updated = now | .stats.total_checkpoints = ($new_checkpoints | length)' "$INDEX_FILE" > "${INDEX_FILE}.tmp"
                mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
                log_success "Index cleaned: $cleaned orphaned entries removed"
            else
                log_info "No orphaned entries found"
            fi
        fi
        
        rm -f "$temp_index"
    else
        # Fallback: rebuild index
        log_info "Rebuilding index for cleanup..."
        rebuild_index
    fi
    
    remove_lock
    return 0
}

# Main function for CLI usage
main() {
    local command="$1"
    shift
    
    case "$command" in
        init)
            init_index
            ;;
        rebuild)
            rebuild_index
            ;;
        search)
            search_index "$@"
            ;;
        stats)
            get_index_stats
            ;;
        status)
            index_status
            ;;
        list)
            list_recent_checkpoints "$@"
            ;;
        latest)
            get_latest_checkpoint
            ;;
        count)
            get_checkpoint_count
            ;;
        clean)
            clean_index
            ;;
        update)
            update_index_entry "$@"
            ;;
        *)
            echo "Usage: $0 {init|rebuild|search|stats|status|list|latest|count|clean|update}"
            echo ""
            echo "Commands:"
            echo "  init                     - Initialize index system"
            echo "  rebuild                  - Rebuild complete index"
            echo "  search <query> [field]   - Search checkpoints"
            echo "  stats                    - Show index statistics"
            echo "  status                   - Show index system status"
            echo "  list [count]             - List recent checkpoints"
            echo "  latest                   - Get latest checkpoint path"
            echo "  count                    - Get checkpoint count"
            echo "  clean                    - Clean orphaned entries"
            echo "  update <op> <file>       - Update index entry"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ] || [ "${ZSH_EVAL_CONTEXT}" = "toplevel" ]; then
    main "$@"
fi

# Initialize index system on load
if [ "$INDEX_AUTO_UPDATE" = "true" ]; then
    init_index
fi