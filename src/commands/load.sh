#!/bin/bash

# Load command - Restore context from memory

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/utils/common.sh"
source "$MEMENTO_DIR/utils/logger.sh"
source "$MEMENTO_DIR/core/memory.sh"

# Parse arguments
CHECKPOINT=""
AUTO_RESTORE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-auto)
            AUTO_RESTORE=false
            shift
            ;;
        *)
            CHECKPOINT="$1"
            shift
            ;;
    esac
done

# Main load function
main() {
    log_info "Loading context..."
    
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
        display_checkpoint "$checkpoint_file"
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
    cat "$checkpoint_file"
    
    # Update session context
    update_session_context "loaded_checkpoint" "$(basename "$checkpoint_file")"
    log_success "Context loaded successfully"
}

# Run main function
main