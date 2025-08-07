#!/bin/bash

# Context Capture Module for Claude Memento
# Captures and updates real-time context

MEMENTO_DIR="$HOME/.claude/memento"
CONTEXT_FILE="$MEMENTO_DIR/claude-memento.md"
CHUNK_DIR="$MEMENTO_DIR/chunks"

# Source dependencies
source "$MEMENTO_DIR/src/utils/logger.sh"

# Update context file with current state
update_context() {
    local section=$1
    local content=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Update last update time
    sed -i '' "s/\*\*Last Update\*\*:.*/\*\*Last Update\*\*: $timestamp/" "$CONTEXT_FILE" 2>/dev/null || \
    sed -i "s/\*\*Last Update\*\*:.*/\*\*Last Update\*\*: $timestamp/" "$CONTEXT_FILE"
    
    log_debug "Context updated: $section"
}

# Capture file operations
capture_file_operation() {
    local operation=$1  # read, write, edit
    local file_path=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Add to working files section
    case $operation in
        "read")
            echo "- READ: $file_path ($timestamp)" >> "$CONTEXT_FILE.tmp"
            ;;
        "write")
            echo "- WRITE: $file_path ($timestamp)" >> "$CONTEXT_FILE.tmp"
            ;;
        "edit")
            echo "- EDIT: $file_path ($timestamp)" >> "$CONTEXT_FILE.tmp"
            ;;
    esac
}

# Check if content needs chunking
needs_chunking() {
    local content="$1"
    local char_count=$(echo -n "$content" | wc -c)
    local token_estimate=$((char_count / 4))  # Rough estimate: 4 chars = 1 token
    
    if [ $token_estimate -gt 3000 ]; then
        return 0  # true - needs chunking
    else
        return 1  # false - no chunking needed
    fi
}

# Auto-chunk large content
auto_chunk() {
    local content="$1"
    local checkpoint_id="$2"
    
    if needs_chunking "$content"; then
        log_info "Content exceeds token limit. Auto-chunking..."
        
        # Call the chunker
        echo "$content" | node "$MEMENTO_DIR/src/chunk/checkpoint-chunker.js" "$checkpoint_id"
        
        return $?
    else
        return 1  # No chunking performed
    fi
}

# Initialize context file if not exists
init_context_file() {
    if [ ! -f "$CONTEXT_FILE" ]; then
        cat > "$CONTEXT_FILE" << EOF
# Claude Memento - Active Context

**Session ID**: $(date '+%Y-%m-%d-%H%M')  
**Started**: $(date '+%Y-%m-%d %H:%M:%S')  
**Last Update**: $(date '+%Y-%m-%d %H:%M:%S')

---

## 📋 Current Tasks

## 🗂️ Working Files

### Recently Modified

### Currently Open

## 💡 Key Decisions

## 🔄 Recent Context

## 📝 Session Notes

## 🎯 Next Steps

---

*This file is automatically updated by Claude Memento*
EOF
        log_info "Context file initialized"
    fi
}

# Export functions for use in other scripts
export -f update_context
export -f capture_file_operation
export -f needs_chunking
export -f auto_chunk
export -f init_context_file

# Initialize on source
init_context_file