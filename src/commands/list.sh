#!/bin/bash

# List command - List all checkpoints

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/utils/common.sh"
source "$MEMENTO_DIR/utils/logger.sh"
source "$MEMENTO_DIR/core/checkpoint.sh"

# Parse arguments
LIMIT=10
SORT="time"  # time or size

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--limit)
            LIMIT="$2"
            shift 2
            ;;
        -s|--sort)
            SORT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Main function
main() {
    local checkpoint_dir="$MEMENTO_DIR/checkpoints"
    
    if [ ! -d "$checkpoint_dir" ]; then
        log_error "Checkpoint directory not found"
        return 1
    fi
    
    # Get checkpoints
    local checkpoints
    if [ "$SORT" = "size" ]; then
        checkpoints=($(ls -S "$checkpoint_dir"/checkpoint-*.md 2>/dev/null))
    else
        checkpoints=($(ls -t "$checkpoint_dir"/checkpoint-*.md 2>/dev/null))
    fi
    
    if [ ${#checkpoints[@]} -eq 0 ]; then
        echo "📭 No checkpoints found"
        return 0
    fi
    
    echo "📸 Checkpoints (sorted by $SORT)"
    echo "================================"
    echo
    
    # Display summary
    local total=${#checkpoints[@]}
    local total_size=$(du -sh "$checkpoint_dir" 2>/dev/null | cut -f1)
    echo "📊 Summary: $total checkpoints, $total_size total"
    echo
    
    # List checkpoints
    local count=0
    for checkpoint in "${checkpoints[@]}"; do
        if [ $count -ge $LIMIT ]; then
            echo
            echo "... and $((total - count)) more"
            break
        fi
        
        local name=$(basename "$checkpoint")
        local size=$(du -h "$checkpoint" | cut -f1)
        local modified=$(get_file_mtime_readable "$checkpoint")
        local age=$(time_diff $(get_file_mtime "$checkpoint"))
        
        # Extract reason
        local reason=$(grep "^\*\*Reason\*\*:" "$checkpoint" | cut -d: -f2- | sed 's/^ //')
        
        # Format display
        printf "%-35s %8s  %s\n" "$name" "$size" "$age ago"
        if [ -n "$reason" ]; then
            printf "  └─ %s\n" "$reason"
        fi
        echo
        
        ((count++))
    done
    
    # Show commands hint
    echo "💡 Commands:"
    echo "  • Load checkpoint: /cm:load <checkpoint-name>"
    echo "  • View details: /cm:last"
    echo "  • Create new: /cm:save \"reason\""
}

# Run main function
main