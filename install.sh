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

# Markers for CLAUDE.md integration
BEGIN_MARKER="<!-- BEGIN_CLAUDE_MEMENTO -->"
END_MARKER="<!-- END_CLAUDE_MEMENTO -->"

echo -e "${BLUE}🧠 Claude Memento Installer${NC}"
echo "================================"

# Function to check if already installed
check_installation() {
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && grep -q "$BEGIN_MARKER" "$CLAUDE_DIR/CLAUDE.md"; then
        return 0
    fi
    return 1
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

# Create full backup first
backup_claude_directory

# Handle CLAUDE.md
echo -e "${YELLOW}Checking CLAUDE.md...${NC}"
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    backup_claude_md
else
    echo -e "${YELLOW}CLAUDE.md not found. Creating minimal version...${NC}"
    create_minimal_claude_md
fi

# Create memento directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "$MEMENTO_DIR"/{checkpoints,config,logs}
mkdir -p "$COMMANDS_DIR"
mkdir -p "$CM_COMMANDS_DIR"

# Copy core files with proper structure
echo -e "${YELLOW}Installing core files...${NC}"
cp -r src "$MEMENTO_DIR/"

# Copy markdown commands to cm namespace directory for Claude Code integration
echo -e "${YELLOW}Installing Claude Code integration commands...${NC}"
cp commands/*.md "$CM_COMMANDS_DIR/" 2>/dev/null || true

# Copy template files as memento reference files
echo -e "${YELLOW}Installing reference documentation...${NC}"
cp "$SCRIPT_DIR/templates/MEMENTO.md" "$MEMENTO_DIR/"
cp "$SCRIPT_DIR/templates/COMMANDS.md" "$MEMENTO_DIR/"
cp "$SCRIPT_DIR/templates/PRINCIPLES.md" "$MEMENTO_DIR/"
cp "$SCRIPT_DIR/templates/RULES.md" "$MEMENTO_DIR/"
cp "$SCRIPT_DIR/templates/HOOKS.md" "$MEMENTO_DIR/"

# Create default configuration
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

# Add Claude Memento section to CLAUDE.md
echo -e "${YELLOW}Updating CLAUDE.md...${NC}"
echo "" >> "$CLAUDE_DIR/CLAUDE.md"
cat "$SCRIPT_DIR/templates/claude-section.md" >> "$CLAUDE_DIR/CLAUDE.md"

# Create hooks configuration
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

# Set permissions for all shell scripts
echo -e "${YELLOW}Setting execute permissions...${NC}"
find "$MEMENTO_DIR/src" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
# Also make the main CLI script executable
chmod +x "$MEMENTO_DIR/src/cli.sh" 2>/dev/null || true
# Make bridge script executable
chmod +x "$MEMENTO_DIR/src/bridge/claude-code-bridge.sh" 2>/dev/null || true

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
echo -e "${BLUE}📦 Full backup created:${NC}"
echo "   $FULL_BACKUP_PATH"
echo ""
echo "Available commands:"
echo "  /cm:save    - Create a checkpoint"
echo "  /cm:load    - Load context from memory"
echo "  /cm:status  - Show memory status"
echo "  /cm:last    - Show last checkpoint"
echo "  /cm:list    - List all checkpoints"
echo "  /cm:config  - Manage configuration"
echo "  /cm:hooks   - Manage hooks"
echo ""
echo "Configuration: $MEMENTO_DIR/config/"
echo "Checkpoints:  $MEMENTO_DIR/checkpoints/"
echo "Reference:    $MEMENTO_DIR/MEMENTO.md"
echo ""
echo "To uninstall: ./uninstall.sh"
echo "To uninstall and keep data: ./uninstall.sh --keep-data"