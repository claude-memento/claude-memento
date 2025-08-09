#!/bin/bash

# Claude Memento Installation Script
# Non-destructive installation as independent extension

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output (cross-platform)
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    # Windows (Git Bash/MSYS2)
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Installation directories
CLAUDE_DIR="$HOME/.claude"
MEMENTO_DIR="$CLAUDE_DIR/memento"
COMMANDS_DIR="$CLAUDE_DIR/commands"
CM_COMMANDS_DIR="$COMMANDS_DIR/cm"
AGENTS_DIR="$CLAUDE_DIR/agents"

# Markers for CLAUDE.md integration
BEGIN_MARKER="<!-- BEGIN_CLAUDE_MEMENTO -->"
END_MARKER="<!-- END_CLAUDE_MEMENTO -->"

echo -e "${BLUE}🧠 Claude Memento Installer${NC}"
echo "================================"

# Function to check if already installed
check_installation() {
    local installed=false
    local installation_found=()
    
    # Check 1: CLAUDE.md marker
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && grep -q "$BEGIN_MARKER" "$CLAUDE_DIR/CLAUDE.md"; then
        installed=true
        installation_found+=("CLAUDE.md marker")
    fi
    
    # Check 2: Memento directory exists
    if [ -d "$MEMENTO_DIR" ]; then
        installed=true
        installation_found+=("memento directory")
    fi
    
    # Check 3: Core CLI script exists
    if [ -f "$MEMENTO_DIR/src/cli.sh" ]; then
        installed=true
        installation_found+=("core CLI script")
    fi
    
    # Check 4: Command directory exists
    if [ -d "$CM_COMMANDS_DIR" ] && [ "$(ls -A "$CM_COMMANDS_DIR" 2>/dev/null)" ]; then
        installed=true
        installation_found+=("command files")
    fi
    
    # Check 5: Wrapper scripts exist
    if ls "$COMMANDS_DIR"/cm-*.sh 1> /dev/null 2>&1; then
        installed=true
        installation_found+=("wrapper scripts")
    fi
    
    if [ "$installed" = true ]; then
        echo -e "${YELLOW}Found existing installation components:${NC}"
        for component in "${installation_found[@]}"; do
            echo "  - $component"
        done
        return 0
    fi
    
    return 1
}

# Function to detect existing backups
detect_existing_backups() {
    local backup_found=false
    local backup_dirs=()
    
    echo -e "${YELLOW}Scanning for existing backups...${NC}"
    
    # Find installation backups
    for dir in "$HOME"/.claude_backup_*; do
        if [ -d "$dir" ] && [ -f "$dir/.backup_metadata" ]; then
            backup_dirs+=("$dir")
            backup_found=true
        fi
    done
    
    # Find update backups
    for dir in "$HOME"/.claude_memento_update_*; do
        if [ -d "$dir" ] && [ -f "$dir/.backup_metadata" ]; then
            backup_dirs+=("$dir")
            backup_found=true
        fi
    done
    
    if [ "$backup_found" = true ]; then
        echo -e "${GREEN}Found ${#backup_dirs[@]} backup(s):${NC}"
        return 0
    else
        return 1
    fi
}

# Function to display backup information
display_backup_info() {
    local backup_dir="$1"
    local metadata_file="$backup_dir/.backup_metadata"
    
    if [ -f "$metadata_file" ]; then
        echo -e "${BLUE}Backup: $(basename "$backup_dir")${NC}"
        grep -E "^Backup date:|^Backup type:|^Claude Memento version:" "$metadata_file" | sed 's/^/  /'
        
        # Check if it has user data
        if [ -d "$backup_dir/checkpoints" ] || [ -d "$backup_dir/config" ]; then
            echo "  Contains: User data (checkpoints, config)"
        fi
        if [ -f "$backup_dir/CLAUDE.md" ]; then
            echo "  Contains: CLAUDE.md"
        fi
    fi
}

# Function to prompt for backup restoration
prompt_restore_backup() {
    local backup_dirs=()
    
    # Collect all valid backups
    for dir in "$HOME"/.claude_backup_* "$HOME"/.claude_memento_update_*; do
        if [ -d "$dir" ] && [ -f "$dir/.backup_metadata" ]; then
            backup_dirs+=("$dir")
        fi
    done
    
    if [ ${#backup_dirs[@]} -eq 0 ]; then
        return 1
    fi
    
    # Sort backups by date (newest first)
    IFS=$'\n' sorted_dirs=($(printf '%s\n' "${backup_dirs[@]}" | sort -r))
    unset IFS
    
    echo -e "${YELLOW}\nFound existing backup(s). Would you like to restore from a backup?${NC}"
    echo "This can recover your previous Claude Memento data and settings."
    echo ""
    
    # Display backups with numbers
    local i=1
    for dir in "${sorted_dirs[@]}"; do
        echo "[$i] $(basename "$dir")"
        display_backup_info "$dir" | sed 's/^/    /'
        echo ""
        ((i++))
    done
    
    echo "[0] Skip restoration and continue with fresh installation"
    echo ""
    
    read -p "Select option (0-$((i-1))): " -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -lt "$i" ]; then
        if [ "$choice" -eq 0 ]; then
            echo -e "${YELLOW}Skipping restoration. Continuing with installation...${NC}"
            return 1
        else
            local selected_backup="${sorted_dirs[$((choice-1))]}"
            echo -e "${GREEN}Selected: $(basename "$selected_backup")${NC}"
            restore_from_backup "$selected_backup"
            return 0
        fi
    else
        echo -e "${RED}Invalid choice. Skipping restoration.${NC}"
        return 1
    fi
}

# Function to restore from backup
restore_from_backup() {
    local backup_dir="$1"
    
    echo -e "${YELLOW}Restoring from backup...${NC}"
    
    # Create memento directories if they don't exist
    mkdir -p "$MEMENTO_DIR"/{checkpoints,config,logs,chunks}
    
    # Restore user data (checkpoints, config, chunks)
    if [ -d "$backup_dir/memento/checkpoints" ]; then
        echo -e "${YELLOW}Restoring checkpoints...${NC}"
        cp -r "$backup_dir/memento/checkpoints/"* "$MEMENTO_DIR/checkpoints/" 2>/dev/null || true
        echo -e "${GREEN}✓ Checkpoints restored${NC}"
    fi
    
    if [ -d "$backup_dir/memento/config" ]; then
        echo -e "${YELLOW}Restoring configuration...${NC}"
        # Backup current config if exists
        if [ -f "$MEMENTO_DIR/config/settings.json" ]; then
            mv "$MEMENTO_DIR/config/settings.json" "$MEMENTO_DIR/config/settings.json.bak"
        fi
        cp -r "$backup_dir/memento/config/"* "$MEMENTO_DIR/config/" 2>/dev/null || true
        echo -e "${GREEN}✓ Configuration restored${NC}"
    fi
    
    if [ -d "$backup_dir/memento/chunks" ]; then
        echo -e "${YELLOW}Restoring chunks...${NC}"
        cp -r "$backup_dir/memento/chunks/"* "$MEMENTO_DIR/chunks/" 2>/dev/null || true
        echo -e "${GREEN}✓ Chunks restored${NC}"
    fi
    
    if [ -d "$backup_dir/memento/logs" ]; then
        echo -e "${YELLOW}Restoring logs...${NC}"
        cp -r "$backup_dir/memento/logs/"* "$MEMENTO_DIR/logs/" 2>/dev/null || true
        echo -e "${GREEN}✓ Logs restored${NC}"
    fi
    
    # Restore CLAUDE.md if user confirms
    if [ -f "$backup_dir/CLAUDE.md" ]; then
        echo -e "${YELLOW}\nFound CLAUDE.md in backup. Restore it?${NC}"
        echo "Warning: This will replace your current CLAUDE.md"
        read -p "Restore CLAUDE.md? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Backup current CLAUDE.md
            if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
                cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.before_restore.$(date +%Y%m%d_%H%M%S)"
            fi
            cp "$backup_dir/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
            echo -e "${GREEN}✓ CLAUDE.md restored${NC}"
        else
            echo -e "${YELLOW}Keeping current CLAUDE.md${NC}"
        fi
    fi
    
    echo -e "${GREEN}✅ Restoration complete!${NC}"
    echo -e "${BLUE}Your previous Claude Memento data has been restored.${NC}"
    echo ""
    
    # Mark that restoration was performed
    export RESTORED_FROM_BACKUP="$backup_dir"
}

# Function to backup entire .claude directory
backup_claude_directory() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.claude_backup_$timestamp"
    
    echo -e "${YELLOW}Creating full backup of .claude directory...${NC}"
    
    # Create backup with metadata
    mkdir -p "$backup_dir"
    
    # Copy entire .claude directory
    if [ -d "$CLAUDE_DIR" ]; then
        cp -r "$CLAUDE_DIR"/* "$backup_dir/" 2>/dev/null || true
        cp -r "$CLAUDE_DIR"/.[!.]* "$backup_dir/" 2>/dev/null || true
    fi
    
    # Create metadata file
    cat > "$backup_dir/.backup_metadata" << EOF
Backup created by: Claude Memento
Backup date: $(date)
Backup type: Full directory backup
Original location: $CLAUDE_DIR
Claude Memento version: 1.0.0
Reason: Pre-installation backup
EOF
    
    # Create restore script
    cat > "$backup_dir/restore.sh" << 'EOF'
#!/bin/bash
# Claude Memento Backup Restore Script

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "🔄 Claude Memento Backup Restore"
echo "================================"
echo "This will restore .claude from: $BACKUP_DIR"
echo "To: $CLAUDE_DIR"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup current state before restore
    if [ -d "$CLAUDE_DIR" ]; then
        mv "$CLAUDE_DIR" "$CLAUDE_DIR.before_restore.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Restore backup
    mkdir -p "$CLAUDE_DIR"
    cp -r "$BACKUP_DIR"/* "$CLAUDE_DIR/" 2>/dev/null || true
    cp -r "$BACKUP_DIR"/.[!.]* "$CLAUDE_DIR/" 2>/dev/null || true
    
    # Remove backup metadata and restore script from restored directory
    rm -f "$CLAUDE_DIR/.backup_metadata"
    rm -f "$CLAUDE_DIR/restore.sh"
    
    echo "✅ Restore completed!"
else
    echo "❌ Restore cancelled."
fi
EOF
    
    chmod +x "$backup_dir/restore.sh"
    
    echo -e "${GREEN}✓ Full backup created at: $backup_dir${NC}"
    echo -e "${BLUE}  To restore, run: $backup_dir/restore.sh${NC}"
    
    # Store backup location for installation log
    FULL_BACKUP_PATH="$backup_dir"
}

# Function to backup CLAUDE.md
backup_claude_md() {
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        local backup_file="$CLAUDE_DIR/CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CLAUDE_DIR/CLAUDE.md" "$backup_file"
        echo -e "${GREEN}✓ Backed up CLAUDE.md to: $backup_file${NC}"
    fi
}

# Function to create minimal CLAUDE.md
create_minimal_claude_md() {
    mkdir -p "$CLAUDE_DIR"
    cp "$SCRIPT_DIR/templates/minimal-claude.md" "$CLAUDE_DIR/CLAUDE.md"
    echo -e "${GREEN}✓ Created new CLAUDE.md${NC}"
}

# Check if already installed
if check_installation; then
    echo -e "${RED}Error: Claude Memento is already installed!${NC}"
    echo "Use './uninstall.sh' first if you want to reinstall."
    exit 1
fi

# Check for existing backups and offer restoration
if detect_existing_backups; then
    if prompt_restore_backup; then
        echo -e "${GREEN}User data restored from backup.${NC}"
        echo -e "${YELLOW}Continuing with system files installation...${NC}"
        echo ""
    fi
fi

# Create full backup first (unless we just restored)
if [ -z "$RESTORED_FROM_BACKUP" ]; then
    backup_claude_directory
else
    echo -e "${YELLOW}Skipping full backup (data was just restored)${NC}"
    FULL_BACKUP_PATH="$RESTORED_FROM_BACKUP"
fi

# Handle CLAUDE.md
echo -e "${YELLOW}Checking CLAUDE.md...${NC}"
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    backup_claude_md
else
    echo -e "${YELLOW}CLAUDE.md not found. Creating minimal version...${NC}"
    create_minimal_claude_md
fi

# Create memento directories (skip if already restored)
echo -e "${YELLOW}Creating directories...${NC}"
if [ -z "$RESTORED_FROM_BACKUP" ]; then
    mkdir -p "$MEMENTO_DIR"/{checkpoints,config,logs,chunks}
else
    # Only create missing directories
    for dir in checkpoints config logs chunks; do
        mkdir -p "$MEMENTO_DIR/$dir"
    done
fi
mkdir -p "$COMMANDS_DIR"
mkdir -p "$CM_COMMANDS_DIR"

# Copy core files with proper structure
echo -e "${YELLOW}Installing core files...${NC}"
cp -r src "$MEMENTO_DIR/"

# Copy test directory for system verification
if [ -d "$SCRIPT_DIR/test" ]; then
    echo -e "${YELLOW}Installing test suite...${NC}"
    cp -r "$SCRIPT_DIR/test" "$MEMENTO_DIR/"
    chmod +x "$MEMENTO_DIR/test/"*.sh 2>/dev/null || true
    echo -e "${GREEN}✓ Test suite installed${NC}"
fi

# Chunks directory already created above

# Copy default settings for new features
if [ -f "$SCRIPT_DIR/src/config/default-settings.json" ]; then
    cp "$SCRIPT_DIR/src/config/default-settings.json" "$MEMENTO_DIR/config/settings.json"
fi

# Copy command documentation to Claude's command directory
if [ -d "$SCRIPT_DIR/commands/cm" ]; then
    echo -e "${YELLOW}Installing command documentation...${NC}"
    mkdir -p "$HOME/.claude/commands/cm"
    
    # Copy all .md files
    for md_file in "$SCRIPT_DIR/commands/cm/"*.md; do
        if [ -f "$md_file" ]; then
            cp "$md_file" "$HOME/.claude/commands/cm/"
            echo -e "  ${GREEN}✓${NC} Installed: $(basename "$md_file")"
        fi
    done
fi

# Copy markdown commands to cm namespace directory for Claude Code integration
echo -e "${YELLOW}Installing Claude Code integration commands...${NC}"
cp commands/*.md "$CM_COMMANDS_DIR/" 2>/dev/null || true

# Copy wrapper scripts to commands directory
echo -e "${YELLOW}Installing wrapper scripts...${NC}"
for wrapper in commands/cm-*.sh; do
    if [ -f "$wrapper" ]; then
        cp "$wrapper" "$COMMANDS_DIR/"
        chmod +x "$COMMANDS_DIR/$(basename "$wrapper")"
        echo -e "  ${GREEN}✓${NC} Installed: $(basename "$wrapper")"
    fi
done

# Copy agent files to agents directory
if [ -d "$SCRIPT_DIR/.claude/agents" ]; then
    echo -e "${YELLOW}Installing agent files...${NC}"
    mkdir -p "$AGENTS_DIR"
    for agent_file in "$SCRIPT_DIR/.claude/agents"/*.md; do
        if [ -f "$agent_file" ]; then
            cp "$agent_file" "$AGENTS_DIR/"
            echo -e "  ${GREEN}✓${NC} Installed: $(basename "$agent_file")"
        fi
    done
fi

# Copy template files as memento reference files
echo -e "${YELLOW}Installing reference documentation...${NC}"
cp "$SCRIPT_DIR/templates/MEMENTO.md" "$MEMENTO_DIR/"
cp "$SCRIPT_DIR/templates/COMMANDS.md" "$MEMENTO_DIR/"
cp "$SCRIPT_DIR/templates/PRINCIPLES.md" "$MEMENTO_DIR/"
cp "$SCRIPT_DIR/templates/RULES.md" "$MEMENTO_DIR/"
cp "$SCRIPT_DIR/templates/HOOKS.md" "$MEMENTO_DIR/"

# Create default configuration (skip if restored)
if [ -z "$RESTORED_FROM_BACKUP" ] || [ ! -f "$MEMENTO_DIR/config/default.json" ]; then
    echo -e "${YELLOW}Creating default configuration...${NC}"
    cat > "$MEMENTO_DIR/config/default.json" << 'EOF'
{
  "checkpoint": {
    "retention": 10,
    "auto_save": true,
    "interval": 900,
    "strategy": "full"
  },
  "memory": {
    "max_size": "10MB",
    "compression": true,
    "format": "markdown"
  },
  "session": {
    "timeout": 300,
    "auto_restore": true
  },
  "integration": {
    "superclaude": true,
    "command_prefix": "cm:"
  }
}
EOF
else
    echo -e "${YELLOW}Configuration already restored from backup${NC}"
fi

# Add Claude Memento section to CLAUDE.md
echo -e "${YELLOW}Updating CLAUDE.md...${NC}"

# Function to safely remove existing Claude Memento sections
remove_existing_memento_sections() {
    local temp_file="$CLAUDE_DIR/CLAUDE.md.install.tmp"
    local removed_count=0
    
    # Remove all existing Claude Memento sections (could be multiple due to previous issues)
    while grep -q "$BEGIN_MARKER" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null; do
        awk '
        BEGIN { in_section = 0; blank_before = 0 }
        /^$/ { blank_before = 1; blank_line = $0; next }
        /<!-- BEGIN_CLAUDE_MEMENTO -->/ { 
            in_section = 1
            blank_before = 0
            next
        }
        /<!-- END_CLAUDE_MEMENTO -->/ { 
            in_section = 0
            next
        }
        !in_section { 
            if (blank_before) {
                print blank_line
                blank_before = 0
            }
            print
        }
        ' "$CLAUDE_DIR/CLAUDE.md" > "$temp_file"
        
        mv "$temp_file" "$CLAUDE_DIR/CLAUDE.md"
        removed_count=$((removed_count + 1))
        
        # Safety check to prevent infinite loop
        if [ $removed_count -gt 10 ]; then
            echo -e "${RED}Warning: Removed $removed_count Claude Memento sections. Stopping to prevent infinite loop.${NC}"
            break
        fi
    done
    
    if [ $removed_count -gt 0 ]; then
        echo -e "${YELLOW}✓ Removed $removed_count existing Claude Memento section(s)${NC}"
    fi
}

# Remove any existing Claude Memento sections first
if grep -q "$BEGIN_MARKER" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null; then
    echo -e "${YELLOW}Removing existing Claude Memento sections...${NC}"
    remove_existing_memento_sections
fi

# Add new Claude Memento section
echo -e "${YELLOW}Adding new Claude Memento section...${NC}"
echo "" >> "$CLAUDE_DIR/CLAUDE.md"
# Use the enhanced claude-memento-section.md if it exists, otherwise use basic
if [ -f "$SCRIPT_DIR/templates/claude-memento-section.md" ]; then
    cat "$SCRIPT_DIR/templates/claude-memento-section.md" >> "$CLAUDE_DIR/CLAUDE.md"
else
    cat "$SCRIPT_DIR/templates/claude-section.md" >> "$CLAUDE_DIR/CLAUDE.md"
fi
echo -e "${GREEN}✓ CLAUDE.md updated with fresh Memento section${NC}"

# Create claude-memento.md for active context tracking (preserve if restored)
if [ ! -f "$MEMENTO_DIR/claude-memento.md" ]; then
    echo -e "${YELLOW}Creating active context tracker...${NC}"
    cp "$SCRIPT_DIR/templates/claude-memento-template.md" "$MEMENTO_DIR/claude-memento.md" 2>/dev/null || \
    cat > "$MEMENTO_DIR/claude-memento.md" << 'EOF'
# Claude Memento - Active Context

**Session ID**: $(date '+%Y-%m-%d-%H%M')  
**Started**: $(date '+%Y-%m-%d %H:%M:%S')  
**Last Update**: $(date '+%Y-%m-%d %H:%M:%S')

---

## 📋 Current Tasks

## 🗂️ Working Files

## 💡 Key Decisions

## 🔄 Recent Context

## 📝 Session Notes

---

*This file is automatically updated by Claude Memento*
EOF
    echo -e "${GREEN}✓ Active context tracker created${NC}"
else
    echo -e "${YELLOW}Active context tracker already exists (preserved from backup)${NC}"
fi

# Create hooks configuration (skip if restored)
if [ -z "$RESTORED_FROM_BACKUP" ] || [ ! -f "$MEMENTO_DIR/config/hooks.json" ]; then
    echo -e "${YELLOW}Creating hooks configuration...${NC}"
    cat > "$MEMENTO_DIR/config/hooks.json" << 'EOF'
{
  "pre-save": [],
  "post-save": [],
  "pre-load": [],
  "post-load": [],
  "pre-delete": []
}
EOF
else
    echo -e "${YELLOW}Hooks configuration already restored from backup${NC}"
fi

# Set permissions for all shell scripts
echo -e "${YELLOW}Setting execute permissions...${NC}"
find "$MEMENTO_DIR/src" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
# Also make the main CLI script executable
chmod +x "$MEMENTO_DIR/src/cli.sh" 2>/dev/null || true
# Make bridge script executable
chmod +x "$MEMENTO_DIR/src/bridge/claude-code-bridge.sh" 2>/dev/null || true
# Make Node.js scripts executable
chmod +x "$MEMENTO_DIR/src/commands/chunk-wrapper.js" 2>/dev/null || true
chmod +x "$MEMENTO_DIR/src/chunk/"*.js 2>/dev/null || true
# Make hook scripts executable
chmod +x "$MEMENTO_DIR/src/hooks/"*.sh 2>/dev/null || true

# Create installation log
echo -e "${YELLOW}Creating installation log...${NC}"
cat > "$MEMENTO_DIR/.install.log" << EOF
Installation Date: $(date)
Version: 1.0.0
Install Directory: $MEMENTO_DIR
Command Directory: $CM_COMMANDS_DIR
Marker: $BEGIN_MARKER
Full Backup: $FULL_BACKUP_PATH
CLAUDE.md Backup: $(ls -t "$CLAUDE_DIR"/CLAUDE.md.backup.* 2>/dev/null | head -1 || echo "none")
EOF

echo -e "${GREEN}🎉 Claude Memento installed successfully!${NC}"
echo ""
if [ -n "$RESTORED_FROM_BACKUP" ]; then
    echo -e "${BLUE}📦 Data restored from:${NC}"
    echo "   $RESTORED_FROM_BACKUP"
else
    echo -e "${BLUE}📦 Full backup created:${NC}"
    echo "   $FULL_BACKUP_PATH"
fi
echo ""
echo "Available commands:"
echo "  /cm:save      - Create a checkpoint (auto-chunks if >10KB)"
echo "  /cm:load      - Load context (supports smart query loading)"
echo "  /cm:status    - Show memory status"
echo "  /cm:last      - Show last checkpoint"
echo "  /cm:list      - List all checkpoints"
echo "  /cm:config    - Manage configuration"
echo "  /cm:hooks     - Manage hooks"
echo "  /cm:chunk     - Chunk management commands"
echo "  /cm:auto-save - Configure auto-save settings"
echo ""
echo "Configuration: $MEMENTO_DIR/config/"
echo "Checkpoints:  $MEMENTO_DIR/checkpoints/"
echo "Chunks:       $MEMENTO_DIR/chunks/"
echo "Reference:    $MEMENTO_DIR/MEMENTO.md"
echo "Test Suite:   $MEMENTO_DIR/test/test-chunk-system.sh"
echo ""
echo "New Features:"
echo "  ✅ Auto-chunking for large contexts (>10KB)"
echo "  ✅ Smart query-based loading with graph expansion"
echo "  ✅ Relationship-based context discovery"
echo "  ✅ Auto-save on session end"
echo "  ✅ Timer-based auto-save (configurable)"
echo "  ✅ TF-IDF powered search with semantic relations"
echo "  ✅ Graph database for chunk relationships"
echo ""
echo "To uninstall: ./uninstall.sh"
echo "To uninstall and keep data: ./uninstall.sh --keep-data"