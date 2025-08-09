#!/bin/bash

# Claude Memento Update System - Core Update Functions
# Handles core update operations for system files and directories

# Source utility functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/utils.sh" 2>/dev/null || true

# Function: Check if item should be updated
should_update_item() {
    local item="$1"
    
    # Check if item is in skip list
    if [ -n "${SKIP_ITEMS:-}" ]; then
        if echo ",$SKIP_ITEMS," | grep -q ",$item,"; then
            return 1
        fi
    fi
    
    # Check selective update list
    if [ "${UPDATE_ALL:-true}" = false ] && [ -n "${SELECTIVE_UPDATE:-}" ]; then
        if echo ",$SELECTIVE_UPDATE," | grep -q ",$item,"; then
            return 0
        else
            return 1
        fi
    fi
    
    return 0
}

# Function: Update system files
update_system_files() {
    info "Updating system files..."
    
    local source_dir="${SOURCE_DIR:-$(pwd)}"
    local update_failed=false
    local updated_items=()
    local skipped_items=()
    
    if [ ! -d "$source_dir" ]; then
        error_exit "Source directory not found: $source_dir"
    fi
    
    if is_dry_run; then
        info "[DRY RUN] Would update files from: $source_dir"
    fi
    
    # Show update mode
    if [ "${UPDATE_ALL:-true}" = false ]; then
        info "Selective update mode: ${SELECTIVE_UPDATE:-}"
    elif [ -n "${SKIP_ITEMS:-}" ]; then
        info "Skipping items: $SKIP_ITEMS"
    else
        info "Full update mode: all components"
    fi
    
    # Update system directories
    for dir in "${SYSTEM_DIRS[@]}"; do
        if ! should_update_item "$dir"; then
            verbose "Skipping $dir (excluded by user)"
            skipped_items+=("$dir")
            continue
        fi
        local source="$source_dir/$dir"
        local target="$MEMENTO_DIR/$dir"
        
        if [ -d "$source" ]; then
            verbose "Updating $dir..."
            
            if is_dry_run; then
                info "[DRY RUN] Would update: $dir"
            else
                # Remove old directory and copy new one
                if [ -d "$target" ]; then
                    rm -rf "$target" || {
                        warn "Failed to remove old $dir"
                        update_failed=true
                        continue
                    }
                fi
                
                cp -r "$source" "$MEMENTO_DIR/" || {
                    warn "Failed to update $dir"
                    update_failed=true
                    continue
                }
                
                updated_items+=("$dir")
            fi
        else
            verbose "Skipping $dir (not found in source)"
        fi
    done
    
    # Update system files
    for file in "${SYSTEM_FILES[@]}"; do
        local source="$source_dir/$file"
        local target="$MEMENTO_DIR/$file"
        
        if [ -f "$source" ]; then
            verbose "Updating $file..."
            
            if is_dry_run; then
                info "[DRY RUN] Would update: $file"
            else
                cp "$source" "$MEMENTO_DIR/" || {
                    warn "Failed to update $file"
                    update_failed=true
                    continue
                }
                
                # Make scripts executable
                if [[ "$file" == *.sh ]]; then
                    chmod +x "$target"
                fi
                
                updated_items+=("$file")
            fi
        else
            verbose "Skipping $file (not found in source)"
        fi
    done
    
    # Update VERSION file
    if [ -f "$source_dir/VERSION" ]; then
        if is_dry_run; then
            info "[DRY RUN] Would update: VERSION"
        else
            cp "$source_dir/VERSION" "$MEMENTO_DIR/" || warn "Failed to update VERSION file"
            updated_items+=("VERSION")
        fi
    fi
    
    # Update wrapper scripts in parent directory
    if should_update_item "wrappers"; then
        update_wrapper_scripts "$source_dir"
    else
        verbose "Skipping wrapper scripts (excluded by user)"
        skipped_items+=("wrappers")
    fi
    
    # Update agent files
    if should_update_item "agents"; then
        update_agent_files "$source_dir"
        updated_items+=("agents")
    else
        verbose "Skipping agent files (excluded by user)"
        skipped_items+=("agents")
    fi
    
    # Report results
    if [ ${#updated_items[@]} -gt 0 ]; then
        info "Updated items: ${updated_items[*]}"
    fi
    
    if [ ${#skipped_items[@]} -gt 0 ]; then
        info "Skipped items: ${skipped_items[*]}"
    fi
    
    if [ "$update_failed" = true ]; then
        warn "Some files failed to update. Check the log for details."
        return 1
    fi
    
    success "System files updated successfully"
}

# Function: Update wrapper scripts
update_wrapper_scripts() {
    local source_dir="$1"
    
    # List of wrapper scripts that should be in ~/.claude/
    local wrapper_scripts=(
        "cm"
        "claude-memento"
    )
    
    for script in "${wrapper_scripts[@]}"; do
        local source_file="$source_dir/wrappers/${script}.sh"
        local target_file="$CLAUDE_DIR/$script"
        
        # If source doesn't have wrappers dir, check root
        if [ ! -f "$source_file" ]; then
            source_file="$source_dir/${script}.sh"
        fi
        
        if [ -f "$source_file" ]; then
            if is_dry_run; then
                info "[DRY RUN] Would update wrapper: $script"
            else
                verbose "Updating wrapper script: $script"
                cp "$source_file" "$target_file" || {
                    warn "Failed to update wrapper script: $script"
                    continue
                }
                chmod +x "$target_file"
            fi
        fi
    done
}

# Function: Update agent files
update_agent_files() {
    local source_dir="$1"
    local agents_source_dir="$source_dir/.claude/agents"
    
    if [ ! -d "$agents_source_dir" ]; then
        verbose "No agents directory found in source, skipping agent files update"
        return 0
    fi
    
    if is_dry_run; then
        info "[DRY RUN] Would update agent files"
    else
        info "Updating agent files..."
        ensure_dir "$CLAUDE_DIR/agents"
    fi
    
    for agent_file in "$agents_source_dir"/*.md; do
        if [ -f "$agent_file" ]; then
            local agent_name=$(basename "$agent_file")
            local target_file="$CLAUDE_DIR/agents/$agent_name"
            
            if is_dry_run; then
                info "[DRY RUN] Would update agent: $agent_name"
            else
                verbose "Updating agent file: $agent_name"
                safe_copy "$agent_file" "$target_file" || {
                    warn "Failed to update agent file: $agent_name"
                    continue
                }
            fi
        fi
    done
}

# Function: Verify update integrity
verify_update() {
    info "Verifying update integrity..."
    
    local verification_failed=false
    
    # Check system directories exist
    for dir in "${SYSTEM_DIRS[@]}"; do
        if [ ! -d "$MEMENTO_DIR/$dir" ]; then
            warn "Missing directory after update: $dir"
            verification_failed=true
        fi
    done
    
    # Check system files exist
    for file in "${SYSTEM_FILES[@]}"; do
        if [ ! -f "$MEMENTO_DIR/$file" ]; then
            warn "Missing file after update: $file"
            verification_failed=true
        fi
    done
    
    # Check wrapper scripts
    if [ ! -f "$CLAUDE_DIR/cm" ] || [ ! -x "$CLAUDE_DIR/cm" ]; then
        warn "Wrapper script 'cm' is missing or not executable"
        verification_failed=true
    fi
    
    if [ "$verification_failed" = true ]; then
        return 1
    fi
    
    success "Update verification passed"
    return 0
}

# Function: Update CLAUDE.md
update_claude_md() {
    info "Updating CLAUDE.md integration..."
    
    if ! should_update_item "claude-md"; then
        verbose "Skipping CLAUDE.md update (excluded by user)"
        return 0
    fi
    
    local claude_md="$CLAUDE_DIR/CLAUDE.md"
    local source_template="${SOURCE_DIR:-$(pwd)}/templates/claude-memento-section.md"
    local begin_marker="<!-- Claude Memento Integration -->"
    local end_marker="<!-- End Claude Memento Integration -->"
    
    if is_dry_run; then
        info "[DRY RUN] Would update CLAUDE.md integration"
        return 0
    fi
    
    # Check if CLAUDE.md exists
    if [ ! -f "$claude_md" ]; then
        warn "CLAUDE.md not found, skipping update"
        return 0
    fi
    
    # Check if new template exists
    if [ ! -f "$source_template" ]; then
        verbose "No new CLAUDE.md template found"
        return 0
    fi
    
    # Backup CLAUDE.md before modification
    local backup_file="${claude_md}.backup.$(get_timestamp)"
    cp "$claude_md" "$backup_file" || {
        warn "Failed to backup CLAUDE.md"
        return 1
    }
    verbose "Backed up CLAUDE.md to: $backup_file"
    
    # Remove ALL existing Claude Memento sections (handle duplicates)
    local temp_file="${claude_md}.tmp"
    local removed_count=0
    
    cp "$claude_md" "$temp_file"
    
    # Remove all Claude Memento sections
    while grep -q "$begin_marker" "$temp_file" 2>/dev/null; do
        awk -v begin="$begin_marker" -v end="$end_marker" '
            BEGIN { skip = 0 }
            $0 ~ begin { skip = 1; next }
            $0 ~ end { skip = 0; next }
            skip == 0 { print }
        ' "$temp_file" > "${temp_file}.2"
        
        mv "${temp_file}.2" "$temp_file"
        removed_count=$((removed_count + 1))
        
        # Safety check to prevent infinite loop
        if [ $removed_count -gt 20 ]; then
            warn "Removed $removed_count Claude Memento sections. Stopping to prevent infinite loop."
            break
        fi
    done
    
    if [ $removed_count -gt 0 ]; then
        verbose "Removed $removed_count existing Claude Memento section(s)"
    fi
    
    # Add new Claude Memento section
    {
        cat "$temp_file"
        echo ""
        echo "$begin_marker"
        cat "$source_template"
        echo "$end_marker"
    } > "${temp_file}.new"
    
    # Replace original file
    if mv "${temp_file}.new" "$claude_md"; then
        rm -f "$temp_file"
        success "CLAUDE.md updated successfully"
    else
        # Restore from backup on failure
        warn "Failed to update CLAUDE.md, restoring from backup"
        mv "$backup_file" "$claude_md"
        rm -f "$temp_file" "${temp_file}.new"
        return 1
    fi
    
    # Clean up old backups (keep only last 5)
    cleanup_claude_md_backups
}

# Function: Clean up old CLAUDE.md backups
cleanup_claude_md_backups() {
    local backup_pattern="${CLAUDE_DIR}/CLAUDE.md.backup.*"
    local backups=($(ls -1 $backup_pattern 2>/dev/null | sort -r))
    local max_backups=5
    
    if [ ${#backups[@]} -gt $max_backups ]; then
        for ((i=$max_backups; i<${#backups[@]}; i++)); do
            rm -f "${backups[$i]}"
            verbose "Removed old CLAUDE.md backup: $(basename "${backups[$i]}")"
        done
    fi
}

# Export functions
export -f should_update_item update_system_files update_wrapper_scripts update_agent_files
export -f verify_update update_claude_md cleanup_claude_md_backups