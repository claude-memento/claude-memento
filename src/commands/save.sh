#!/usr/bin/env bash

# Save command - Create checkpoint

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/src/utils/common.sh"
source "$MEMENTO_DIR/src/utils/logger.sh"
source "$MEMENTO_DIR/src/core/checkpoint.sh"
source "$MEMENTO_DIR/src/core/hooks.sh"
source "$MEMENTO_DIR/src/core/memory.sh"
source "$MEMENTO_DIR/src/core/context-capture.sh"

# Parse arguments
REASON="${1:-Manual checkpoint}"
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            REASON="$1"
            shift
            ;;
    esac
done

# Main save function
main() {
    log_info "Creating checkpoint..."
    
    # Prepare hook context
    local hook_context="{\"reason\":\"$REASON\",\"force\":$FORCE,\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
    
    # Run pre-checkpoint hooks
    log_debug "Running pre-checkpoint hooks..."
    run_hooks "pre" "checkpoint" "$hook_context"
    
    # Create checkpoint
    local checkpoint_file
    checkpoint_file=$(create_checkpoint "$REASON")
    
    if [ $? -eq 0 ] && [ -n "$checkpoint_file" ]; then
        # Check if content needs chunking
        local checkpoint_content=$(cat "$checkpoint_file")
        local checkpoint_id=$(basename "$checkpoint_file" .md)
        
        if auto_chunk "$checkpoint_content" "$checkpoint_id"; then
            log_info "Large checkpoint auto-chunked for efficient storage"
        fi
        
        log_success "Checkpoint created: $(basename "$checkpoint_file")"
        
        # Show checkpoint info
        local size=$(get_file_size "$checkpoint_file")
        echo "📄 File: $checkpoint_file"
        echo "📏 Size: $(format_size $size)"
        echo "📝 Reason: $REASON"
        echo "🕐 Time: $(get_readable_time)"
        
        # Update hook context with checkpoint file
        hook_context="{\"reason\":\"$REASON\",\"force\":$FORCE,\"checkpoint_file\":\"$checkpoint_file\",\"size\":$size,\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
        
        # Cleanup old checkpoints
        cleanup_old_checkpoints
        
        # Update context
        update_session_context "last_checkpoint" "$(basename "$checkpoint_file")"
        
        # Run post-checkpoint hooks
        log_debug "Running post-checkpoint hooks..."
        run_hooks "post" "checkpoint" "$hook_context"
        
        return 0
    else
        log_error "Failed to create checkpoint"
        
        # Run post-checkpoint hooks even on failure
        hook_context="{\"reason\":\"$REASON\",\"force\":$FORCE,\"error\":true,\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
        run_hooks "post" "checkpoint" "$hook_context"
        
        return 1
    fi
}

# Run main function
main