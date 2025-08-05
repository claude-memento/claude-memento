#!/bin/bash

# Status command - Show memory status

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/utils/common.sh"
source "$MEMENTO_DIR/utils/logger.sh"

# Main status function
main() {
    echo "🧠 Claude Memento Status"
    echo "========================"
    echo
    
    # Memory status
    show_memory_status
    echo
    
    # Session status
    show_session_status
    echo
    
    # Checkpoint status
    show_checkpoint_status
    echo
    
    # System status
    show_system_status
}

# Show memory status
show_memory_status() {
    echo "💾 Memory Status:"
    
    local memory_file="$MEMENTO_DIR/claude-memory.md"
    if [ -f "$memory_file" ]; then
        local size=$(du -h "$memory_file" | cut -f1)
        local lines=$(wc -l < "$memory_file")
        local modified=$(get_file_mtime_readable "$memory_file")
        
        echo "  📄 File: claude-memory.md"
        echo "  📏 Size: $size"
        echo "  📝 Lines: $lines"
        echo "  🕐 Modified: $modified"
        
        # Extract summary
        local projects=$(grep -c "^## Project:" "$memory_file" 2>/dev/null || echo "0")
        local decisions=$(grep -c "^### Decision:" "$memory_file" 2>/dev/null || echo "0")
        echo "  📊 Content: $projects projects, $decisions decisions"
    else
        echo "  ❌ No long-term memory found"
    fi
}

# Show session status
show_session_status() {
    echo "🔄 Session Status:"
    
    local context_file="$MEMENTO_DIR/claude-context.md"
    if [ -f "$context_file" ]; then
        if is_recent "$context_file"; then
            echo "  ✅ Active session (recent activity)"
        else
            local age=$(time_diff $(get_file_mtime "$context_file"))
            echo "  ⏸️  Inactive session (last activity: $age ago)"
        fi
        
        # Extract session info
        local tasks=$(grep -c "^- \[ \]" "$context_file" 2>/dev/null || echo "0")
        local completed=$(grep -c "^- \[x\]" "$context_file" 2>/dev/null || echo "0")
        echo "  📋 Tasks: $completed completed, $tasks pending"
    else
        echo "  ❌ No active session"
    fi
}

# Show checkpoint status
show_checkpoint_status() {
    echo "📸 Checkpoint Status:"
    
    local checkpoint_dir="$MEMENTO_DIR/checkpoints"
    if [ -d "$checkpoint_dir" ]; then
        local count=$(ls -1 "$checkpoint_dir"/*.md 2>/dev/null | wc -l)
        
        if [ $count -gt 0 ]; then
            echo "  📁 Total checkpoints: $count"
            
            # Show recent checkpoints
            echo "  📅 Recent checkpoints:"
            ls -t "$checkpoint_dir"/*.md 2>/dev/null | head -3 | while read -r checkpoint; do
                local name=$(basename "$checkpoint")
                local size=$(du -h "$checkpoint" | cut -f1)
                local age=$(time_diff $(get_file_mtime "$checkpoint"))
                echo "    • $name ($size, $age ago)"
            done
            
            # Total size
            local total_size=$(du -sh "$checkpoint_dir" 2>/dev/null | cut -f1)
            echo "  💿 Total size: $total_size"
        else
            echo "  ❌ No checkpoints found"
        fi
    else
        echo "  ❌ Checkpoint directory not found"
    fi
}

# Show system status
show_system_status() {
    echo "⚙️  System Status:"
    
    # Configuration
    local config_file="$MEMENTO_DIR/config/default.json"
    if [ -f "$config_file" ]; then
        echo "  ✅ Configuration: OK"
        
        # Extract key settings using grep (fallback if no jq)
        if command -v jq &> /dev/null; then
            local retention=$(jq -r '.checkpoint.retention' "$config_file" 2>/dev/null || echo "3")
            local auto_save=$(jq -r '.checkpoint.auto_save' "$config_file" 2>/dev/null || echo "true")
            local compression=$(jq -r '.memory.compression' "$config_file" 2>/dev/null || echo "true")
        else
            local retention=$(grep -o '"retention":[^,}]*' "$config_file" | cut -d: -f2 | tr -d ' ')
            local auto_save=$(grep -o '"auto_save":[^,}]*' "$config_file" | cut -d: -f2 | tr -d ' ')
            local compression=$(grep -o '"compression":[^,}]*' "$config_file" | cut -d: -f2 | tr -d ' ')
        fi
        
        echo "  ⚙️  Settings:"
        echo "    • Checkpoint retention: $retention"
        echo "    • Auto-save: $auto_save"
        echo "    • Compression: $compression"
    else
        echo "  ⚠️  Using default configuration"
    fi
    
    # Disk usage
    local total_size=$(du -sh "$MEMENTO_DIR" 2>/dev/null | cut -f1)
    echo "  💿 Total disk usage: $total_size"
    
    # Version
    echo "  📦 Version: 1.0.0"
}

# Run main function
main