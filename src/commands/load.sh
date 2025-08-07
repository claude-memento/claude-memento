#!/bin/bash

# Load command - Restore context from memory

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/src/utils/common.sh"
source "$MEMENTO_DIR/src/utils/logger.sh"
source "$MEMENTO_DIR/src/core/memory.sh"

# Parse arguments
CHECKPOINT=""
AUTO_RESTORE=true
QUERY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-auto)
            AUTO_RESTORE=false
            shift
            ;;
        --query|-q)
            QUERY="$2"
            shift 2
            ;;
        *)
            if [ -z "$CHECKPOINT" ]; then
                CHECKPOINT="$1"
            else
                # Additional arguments treated as query
                QUERY="$QUERY $1"
            fi
            shift
            ;;
    esac
done

# Trim query
QUERY=$(echo "$QUERY" | xargs)

# Main load function
main() {
    log_info "Loading context..."
    
    # If query is provided, use smart loader
    if [ -n "$QUERY" ]; then
        log_info "Searching for: $QUERY"
        
        # Use smart loader for query-based loading
        cd "$MEMENTO_DIR/src/chunk" || exit 1
        node smart-loader.js query "$QUERY" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            log_success "Found relevant context"
        else
            log_error "No relevant context found for query: $QUERY"
        fi
        return
    fi
    
    # If no checkpoint specified, load most recent
    if [ -z "$CHECKPOINT" ]; then
        # Check if session is recent (within 5 minutes)
        if is_recent "$MEMENTO_DIR/claude-context.md" && [ "$AUTO_RESTORE" = true ]; then
            log_info "Restoring recent session..."
            display_context
        else
            log_info "Loading from last checkpoint..."
            load_last_checkpoint
        fi
    else
        # Load specific checkpoint
        log_info "Loading checkpoint: $CHECKPOINT"
        if [ -n "$QUERY" ]; then
            log_info "With query: $QUERY"
        fi
        load_checkpoint "$CHECKPOINT"
    fi
}

# Display current context
display_context() {
    echo "📋 Session Context:"
    echo "=================="
    
    if [ -f "$MEMENTO_DIR/claude-context.md" ]; then
        cat "$MEMENTO_DIR/claude-context.md"
    else
        echo "No active session context found."
    fi
    
    echo
    echo "💾 Long-term Memory:"
    echo "==================="
    
    if [ -f "$MEMENTO_DIR/claude-memory.md" ]; then
        cat "$MEMENTO_DIR/claude-memory.md" | head -20
        
        local line_count=$(wc -l < "$MEMENTO_DIR/claude-memory.md")
        if [ $line_count -gt 20 ]; then
            echo "... ($(($line_count - 20)) more lines)"
        fi
    else
        echo "No long-term memory found."
    fi
}

# Load last checkpoint
load_last_checkpoint() {
    local last_checkpoint=$(ls -t "$MEMENTO_DIR/checkpoints/"*.md 2>/dev/null | head -1)
    
    if [ -n "$last_checkpoint" ]; then
        log_info "Found checkpoint: $(basename "$last_checkpoint")"
        display_checkpoint "$last_checkpoint"
    else
        log_warn "No checkpoints found"
        display_context
    fi
}

# Load specific checkpoint
load_checkpoint() {
    local checkpoint_name=$1
    local checkpoint_file
    
    # Find checkpoint file
    if [ -f "$MEMENTO_DIR/checkpoints/$checkpoint_name" ]; then
        checkpoint_file="$MEMENTO_DIR/checkpoints/$checkpoint_name"
    elif [ -f "$MEMENTO_DIR/checkpoints/checkpoint-$checkpoint_name.md" ]; then
        checkpoint_file="$MEMENTO_DIR/checkpoints/checkpoint-$checkpoint_name.md"
    else
        # Search by partial match
        checkpoint_file=$(ls "$MEMENTO_DIR/checkpoints/"*"$checkpoint_name"* 2>/dev/null | head -1)
    fi
    
    if [ -n "$checkpoint_file" ] && [ -f "$checkpoint_file" ]; then
        display_checkpoint "$checkpoint_file" "$QUERY"
    else
        log_error "Checkpoint not found: $checkpoint_name"
        return 1
    fi
}

# Display checkpoint content
display_checkpoint() {
    local checkpoint_file=$1
    
    echo "📸 Checkpoint: $(basename "$checkpoint_file")"
    echo "============================================"
    
    # Check if checkpoint is chunked
    local manifest="${checkpoint_file%.md}-manifest.json"
    if [ -f "$manifest" ]; then
        log_info "Detected chunked checkpoint, loading intelligently..."
        
        # Use checkpoint loader
        if command -v node &> /dev/null; then
            export MEMENTO_DIR="$MEMENTO_DIR"
            
            # Check if query was provided as second argument
            if [ -n "$2" ]; then
                node "$MEMENTO_DIR/src/chunk/checkpoint-loader.js" "$checkpoint_file" "$2"
            else
                node "$MEMENTO_DIR/src/chunk/checkpoint-loader.js" "$checkpoint_file"
            fi
            
            if [ $? -ne 0 ]; then
                log_warn "Failed to load chunked checkpoint, falling back to simple display"
                cat "$checkpoint_file"
            fi
        else
            log_warn "Node.js not found, displaying simplified checkpoint"
            cat "$checkpoint_file"
        fi
    else
        # Regular checkpoint
        cat "$checkpoint_file"
    fi
    
    # Update session context
    update_session_context "loaded_checkpoint" "$(basename "$checkpoint_file")"
    log_success "Context loaded successfully"
}

# Run main function
main