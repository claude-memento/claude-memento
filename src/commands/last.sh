#!/bin/bash

# Last command - Show last checkpoint

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/utils/common.sh"
source "$MEMENTO_DIR/utils/logger.sh"

# Main function
main() {
    local checkpoint_dir="$MEMENTO_DIR/checkpoints"
    
    # Find last checkpoint
    local last_checkpoint=$(ls -t "$checkpoint_dir"/checkpoint-*.md 2>/dev/null | head -1)
    
    if [ -z "$last_checkpoint" ]; then
        log_warn "No checkpoints found"
        return 1
    fi
    
    # Display checkpoint info
    echo "📸 Last Checkpoint"
    echo "=================="
    echo
    
    # Show metadata
    local name=$(basename "$last_checkpoint")
    local size=$(du -h "$last_checkpoint" | cut -f1)
    local modified=$(get_file_mtime_readable "$last_checkpoint")
    local age=$(time_diff $(get_file_mtime "$last_checkpoint"))
    
    echo "📄 File: $name"
    echo "📏 Size: $size"
    echo "🕐 Created: $modified ($age ago)"
    
    # Extract and show reason
    local reason=$(grep "^\*\*Reason\*\*:" "$last_checkpoint" | cut -d: -f2- | sed 's/^ //')
    if [ -n "$reason" ]; then
        echo "📝 Reason: $reason"
    fi
    
    echo
    echo "📋 Content Preview:"
    echo "-------------------"
    
    # Show first 30 lines
    head -30 "$last_checkpoint"
    
    # If more content exists, indicate it
    local total_lines=$(wc -l < "$last_checkpoint")
    if [ $total_lines -gt 30 ]; then
        echo
        echo "... ($(($total_lines - 30)) more lines)"
        echo
        echo "💡 Tip: Use '/cm:load' to load the full checkpoint"
    fi
}

# Run main function
main