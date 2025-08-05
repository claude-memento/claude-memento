#!/bin/bash

# Claude Memento Uninstall Script
# Safe removal with data preservation options

set -e

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

# Parse arguments
KEEP_DATA=false
for arg in "$@"; do
    case $arg in
        --keep-data)
            KEEP_DATA=true
            shift
            ;;
    esac
done

echo -e "${BLUE}🧠 Claude Memento Uninstaller${NC}"
echo "===================================="

# Function to check if installed
check_installation() {
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && grep -q "$BEGIN_MARKER" "$CLAUDE_DIR/CLAUDE.md"; then
        return 0
    fi
    if [ -d "$MEMENTO_DIR" ]; then
        return 0
    fi
    return 1
}

# Function to remove from CLAUDE.md
remove_from_claude_md() {
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        echo -e "${YELLOW}Removing Claude Memento section from CLAUDE.md...${NC}"
        
        # Create backup before modification
        cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.uninstall.backup"
        
        # Remove only the Claude Memento section between markers
        # First, remove the section including the blank line before it
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
        ' "$CLAUDE_DIR/CLAUDE.md" > "$CLAUDE_DIR/CLAUDE.md.tmp"
        
        mv "$CLAUDE_DIR/CLAUDE.md.tmp" "$CLAUDE_DIR/CLAUDE.md"
        
        # No need to clean up temp file as we moved it
        
        echo -e "${GREEN}✓ Removed Claude Memento section from CLAUDE.md${NC}"
    fi
}

# Function to preserve data
preserve_data() {
    if [ -d "$MEMENTO_DIR/checkpoints" ] && [ "$(ls -A "$MEMENTO_DIR/checkpoints")" ]; then
        local backup_dir="$HOME/claude-memento-backup-$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Preserving checkpoint data...${NC}"
        mkdir -p "$backup_dir"
        cp -r "$MEMENTO_DIR/checkpoints" "$backup_dir/"
        echo -e "${GREEN}✓ Checkpoint data backed up to: $backup_dir${NC}"
    fi
}

# Check if installed
if ! check_installation; then
    echo -e "${RED}Error: Claude Memento is not installed!${NC}"
    exit 1
fi

# Confirm uninstallation
echo -e "${YELLOW}This will uninstall Claude Memento.${NC}"
if [ "$KEEP_DATA" = true ]; then
    echo "Checkpoint data will be preserved."
else
    echo -e "${RED}⚠️  All checkpoint data will be deleted!${NC}"
    echo "Use '--keep-data' to preserve checkpoints."
fi
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

# Remove from CLAUDE.md
remove_from_claude_md

# Handle data preservation
if [ "$KEEP_DATA" = true ]; then
    preserve_data
fi

# Remove command files
echo -e "${YELLOW}Removing command files...${NC}"
if [ -d "$CM_COMMANDS_DIR" ]; then
    rm -rf "$CM_COMMANDS_DIR"
    echo -e "${GREEN}✓ Removed command files${NC}"
fi

# Remove main installation
echo -e "${YELLOW}Removing Claude Memento files...${NC}"
if [ -d "$MEMENTO_DIR" ]; then
    if [ "$KEEP_DATA" = true ]; then
        # Remove everything except checkpoints
        find "$MEMENTO_DIR" -mindepth 1 -maxdepth 1 ! -name 'checkpoints' -exec rm -rf {} +
        # If checkpoints is empty, remove it too
        if [ ! "$(ls -A "$MEMENTO_DIR/checkpoints" 2>/dev/null)" ]; then
            rm -rf "$MEMENTO_DIR"
        else
            echo -e "${YELLOW}ℹ️  Checkpoint data preserved in: $MEMENTO_DIR/checkpoints${NC}"
        fi
    else
        rm -rf "$MEMENTO_DIR"
    fi
    echo -e "${GREEN}✓ Removed Claude Memento files${NC}"
fi

# Clean up empty directories
if [ -d "$COMMANDS_DIR" ] && [ ! "$(ls -A "$COMMANDS_DIR")" ]; then
    rmdir "$COMMANDS_DIR"
fi

# Show summary
echo ""
echo -e "${GREEN}✅ Claude Memento uninstalled successfully!${NC}"
echo ""

# Show backup locations if applicable
if [ -f "$CLAUDE_DIR/CLAUDE.md.uninstall.backup" ]; then
    echo "CLAUDE.md backup: $CLAUDE_DIR/CLAUDE.md.uninstall.backup"
fi

if [ "$KEEP_DATA" = true ] && [ -d "$backup_dir" ]; then
    echo "Checkpoint backup: $backup_dir"
fi

# Check for installation backups
echo -e "${BLUE}📦 Installation backups:${NC}"
installation_backups=$(ls -d "$HOME"/.claude_backup_* 2>/dev/null || true)
if [ -n "$installation_backups" ]; then
    for backup in $installation_backups; do
        if [ -f "$backup/.backup_metadata" ]; then
            echo -e "   ${GREEN}$backup${NC}"
            # Show metadata
            grep "Backup date:" "$backup/.backup_metadata" | sed 's/^/      /'
            if [ -f "$backup/restore.sh" ]; then
                echo "      Restore command: $backup/restore.sh"
            fi
        fi
    done
else
    echo "   No installation backups found"
fi

echo ""
echo "Thank you for using Claude Memento!"