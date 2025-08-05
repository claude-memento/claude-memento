#!/bin/bash

# Memory core functionality

MEMENTO_DIR="$HOME/.claude/memento"
source "$MEMENTO_DIR/utils/common.sh"
source "$MEMENTO_DIR/utils/logger.sh"

# Initialize memory system
init_memory() {
    # Create necessary directories
    mkdir -p "$MEMENTO_DIR"/{checkpoints,config,logs}
    
    # Initialize memory files if they don't exist
    if [ ! -f "$MEMENTO_DIR/claude-memory.md" ]; then
        cat > "$MEMENTO_DIR/claude-memory.md" << 'EOF'
# 🧠 Claude Long-term Memory

## System Information
- Initialized: $(date)
- Version: Claude Memento v1.0.0

## Projects
<!-- Project information will be stored here -->

## Preferences
<!-- User preferences and settings -->

## Knowledge Base
<!-- Accumulated knowledge and patterns -->

---
*This file stores long-term memory that persists across sessions*
EOF
    fi
    
    if [ ! -f "$MEMENTO_DIR/claude-context.md" ]; then
        create_session_context
    fi
}

# Create new session context
create_session_context() {
    cat > "$MEMENTO_DIR/claude-context.md" << EOF
# 💫 Claude Session Context

**Session Started**: $(get_readable_time)
**Session ID**: $(get_timestamp)

## Current Work
<!-- Current tasks and progress -->

## Open Files
<!-- Files being worked on -->

## Active Processes
<!-- Running processes and commands -->

## Notes
<!-- Session-specific notes -->

---
*This file stores temporary session context*
EOF
}

# Update session context
update_session_context() {
    local key=$1
    local value=$2
    local context_file="$MEMENTO_DIR/claude-context.md"
    
    # Ensure context file exists
    if [ ! -f "$context_file" ]; then
        create_session_context
    fi
    
    # Update or add key-value pair
    # For now, append to notes section
    local temp_file=$(mktemp)
    awk -v key="$key" -v value="$value" '
        /^## Notes/ { in_notes=1 }
        { print }
        in_notes && /^$/ && !done {
            print "- " key ": " value
            done=1
        }
    ' "$context_file" > "$temp_file"
    
    mv "$temp_file" "$context_file"
}

# Save to long-term memory
save_to_memory() {
    local category=$1
    local content=$2
    local memory_file="$MEMENTO_DIR/claude-memory.md"
    
    # Append to appropriate section
    case $category in
        "project")
            append_to_section "Projects" "$content" "$memory_file"
            ;;
        "preference")
            append_to_section "Preferences" "$content" "$memory_file"
            ;;
        "knowledge")
            append_to_section "Knowledge Base" "$content" "$memory_file"
            ;;
        *)
            # Append to end of file
            echo "$content" >> "$memory_file"
            ;;
    esac
    
    log_debug "Saved to memory: $category"
}

# Append content to specific section
append_to_section() {
    local section=$1
    local content=$2
    local file=$3
    
    local temp_file=$(mktemp)
    local in_section=false
    local section_found=false
    
    while IFS= read -r line; do
        echo "$line"
        
        # Check if we're entering the target section
        if [[ "$line" == "## $section" ]]; then
            in_section=true
            section_found=true
        elif [[ "$line" =~ ^##\  ]] && [ "$in_section" = true ]; then
            # We've hit the next section, insert content before it
            echo "$content"
            echo
            in_section=false
        fi
    done < "$file" > "$temp_file"
    
    # If section was found but we're still in it (last section), append
    if [ "$in_section" = true ]; then
        echo "$content" >> "$temp_file"
        echo >> "$temp_file"
    fi
    
    # If section wasn't found, append at end
    if [ "$section_found" = false ]; then
        echo >> "$temp_file"
        echo "## $section" >> "$temp_file"
        echo "$content" >> "$temp_file"
    fi
    
    mv "$temp_file" "$file"
}

# Search memory
search_memory() {
    local query=$1
    local memory_file="$MEMENTO_DIR/claude-memory.md"
    local context_file="$MEMENTO_DIR/claude-context.md"
    
    echo "🔍 Searching for: $query"
    echo "========================"
    
    # Search in long-term memory
    if [ -f "$memory_file" ]; then
        echo
        echo "📚 Long-term Memory:"
        grep -n -i "$query" "$memory_file" | while IFS=: read -r line_num content; do
            echo "  Line $line_num: $content"
        done
    fi
    
    # Search in session context
    if [ -f "$context_file" ]; then
        echo
        echo "💫 Session Context:"
        grep -n -i "$query" "$context_file" | while IFS=: read -r line_num content; do
            echo "  Line $line_num: $content"
        done
    fi
    
    # Search in checkpoints
    echo
    echo "📸 Checkpoints:"
    grep -l -i "$query" "$MEMENTO_DIR/checkpoints/"*.md 2>/dev/null | while read -r file; do
        echo "  Found in: $(basename "$file")"
        grep -n -i "$query" "$file" | head -3 | while IFS=: read -r line_num content; do
            echo "    Line $line_num: $content"
        done
    done
}

# Compact memory (remove duplicates and optimize)
compact_memory() {
    local memory_file="$MEMENTO_DIR/claude-memory.md"
    
    if [ ! -f "$memory_file" ]; then
        log_warn "No memory file to compact"
        return 1
    fi
    
    log_info "Compacting memory..."
    
    # Create backup
    cp "$memory_file" "${memory_file}.bak"
    
    # Remove duplicate lines while preserving order and structure
    awk '!seen[$0]++ || /^#/ || /^$/' "$memory_file" > "${memory_file}.tmp"
    mv "${memory_file}.tmp" "$memory_file"
    
    # Report results
    local before=$(wc -l < "${memory_file}.bak")
    local after=$(wc -l < "$memory_file")
    local removed=$((before - after))
    
    log_success "Compacted memory: removed $removed duplicate lines"
    
    # Remove backup
    rm -f "${memory_file}.bak"
}