#!/bin/bash

# Checkpoint core functionality

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/utils/common.sh"
source "$MEMENTO_DIR/utils/logger.sh"

# Create checkpoint
create_checkpoint() {
    local reason="${1:-Manual checkpoint}"
    local timestamp=$(get_timestamp)
    local checkpoint_file="$MEMENTO_DIR/checkpoints/checkpoint-$timestamp.md"
    
    # Ensure checkpoint directory exists
    mkdir -p "$MEMENTO_DIR/checkpoints"
    
    # Create checkpoint content
    {
        echo "# 📸 Checkpoint: $timestamp"
        echo "**Created**: $(get_readable_time)"
        echo "**Reason**: $reason"
        echo
        echo "---"
        echo
        
        # Include current context
        echo "## 🔄 Session Context"
        echo
        if [ -f "$MEMENTO_DIR/claude-context.md" ]; then
            cat "$MEMENTO_DIR/claude-context.md"
        else
            echo "*No active session context*"
        fi
        echo
        
        # Include memory summary
        echo "## 💾 Memory Summary"
        echo
        if [ -f "$MEMENTO_DIR/claude-memory.md" ]; then
            # Include last 50 lines of memory
            echo "### Recent Memory Entries"
            echo '```'
            tail -50 "$MEMENTO_DIR/claude-memory.md"
            echo '```'
        else
            echo "*No long-term memory*"
        fi
        echo
        
        # Include system state
        echo "## 🔧 System State"
        echo
        echo "- Working Directory: $(pwd)"
        echo "- Environment: $(uname -s) $(uname -r)"
        echo "- Claude Memento: v1.0.0"
        
        # Include active tasks if any
        if [ -f "$MEMENTO_DIR/claude-context.md" ]; then
            local pending_tasks=$(grep -c "^- \[ \]" "$MEMENTO_DIR/claude-context.md" 2>/dev/null || echo "0")
            if [ $pending_tasks -gt 0 ]; then
                echo
                echo "### ⚠️ Pending Tasks"
                grep "^- \[ \]" "$MEMENTO_DIR/claude-context.md"
            fi
        fi
    } > "$checkpoint_file"
    
    # Verify checkpoint was created
    if [ -f "$checkpoint_file" ] && [ -s "$checkpoint_file" ]; then
        log_debug "Checkpoint created: $checkpoint_file"
        echo "$checkpoint_file"
        return 0
    else
        log_error "Failed to create checkpoint"
        return 1
    fi
}

# Cleanup old checkpoints
cleanup_old_checkpoints() {
    local checkpoint_dir="$MEMENTO_DIR/checkpoints"
    local retention=${CHECKPOINT_RETENTION:-3}
    
    log_debug "Cleaning up old checkpoints (keeping $retention)"
    
    # Get list of checkpoints sorted by time
    local checkpoints=($(ls -t "$checkpoint_dir"/checkpoint-*.md 2>/dev/null))
    local count=${#checkpoints[@]}
    
    # Remove old checkpoints
    if [ $count -gt $retention ]; then
        for ((i=$retention; i<$count; i++)); do
            local old_checkpoint="${checkpoints[$i]}"
            log_debug "Removing old checkpoint: $(basename "$old_checkpoint")"
            rm -f "$old_checkpoint"
        done
        
        local removed=$((count - retention))
        log_info "Removed $removed old checkpoint(s)"
    fi
}

# List checkpoints
list_checkpoints() {
    local checkpoint_dir="$MEMENTO_DIR/checkpoints"
    
    if [ ! -d "$checkpoint_dir" ]; then
        echo "No checkpoints directory found"
        return 1
    fi
    
    local checkpoints=($(ls -t "$checkpoint_dir"/checkpoint-*.md 2>/dev/null))
    
    if [ ${#checkpoints[@]} -eq 0 ]; then
        echo "No checkpoints found"
        return 0
    fi
    
    echo "📸 Available Checkpoints:"
    echo "========================"
    
    for checkpoint in "${checkpoints[@]}"; do
        local name=$(basename "$checkpoint")
        local size=$(du -h "$checkpoint" | cut -f1)
        local modified=$(get_file_mtime_readable "$checkpoint")
        
        # Extract reason if available
        local reason=$(grep "^\*\*Reason\*\*:" "$checkpoint" | cut -d: -f2- | sed 's/^ //')
        
        echo
        echo "📄 $name"
        echo "   Size: $size | Modified: $modified"
        if [ -n "$reason" ]; then
            echo "   Reason: $reason"
        fi
    done
}

# Get checkpoint info
get_checkpoint_info() {
    local checkpoint_file=$1
    
    if [ ! -f "$checkpoint_file" ]; then
        return 1
    fi
    
    # Extract metadata
    local created=$(grep "^\*\*Created\*\*:" "$checkpoint_file" | cut -d: -f2- | sed 's/^ //')
    local reason=$(grep "^\*\*Reason\*\*:" "$checkpoint_file" | cut -d: -f2- | sed 's/^ //')
    
    echo "Checkpoint: $(basename "$checkpoint_file")"
    echo "Created: $created"
    echo "Reason: $reason"
}