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
AGENTS_DIR="$CLAUDE_DIR/agents"

# Markers for CLAUDE.md integration
BEGIN_MARKER="<!-- BEGIN_CLAUDE_MEMENTO -->"
END_MARKER="<!-- END_CLAUDE_MEMENTO -->"

# Parse arguments with validation
KEEP_DATA=false
FORCE_REMOVE=false
VERBOSE=false

for arg in "$@"; do
    case $arg in
        --keep-data)
            KEEP_DATA=true
            shift
            ;;
        --force)
            FORCE_REMOVE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Claude Memento Uninstaller"
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --keep-data    Preserve checkpoint and chunk data"
            echo "  --force        Skip confirmation prompts"
            echo "  --verbose, -v  Enable verbose output"
            echo "  --help, -h     Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            echo "Use --help for usage information"
            exit 1
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
        echo -e "${YELLOW}Removing Claude Memento section(s) from CLAUDE.md...${NC}"
        
        # Create backup before modification
        cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.uninstall.backup"
        
        local temp_file="$CLAUDE_DIR/CLAUDE.md.uninstall.tmp"
        local removed_count=0
        
        # Remove ALL existing Claude Memento sections (handle multiple sections)
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
            if [ $removed_count -gt 20 ]; then
                echo -e "${RED}Warning: Removed $removed_count Claude Memento sections. Stopping to prevent infinite loop.${NC}"
                break
            fi
        done
        
        if [ $removed_count -gt 0 ]; then
            echo -e "${GREEN}✓ Removed $removed_count Claude Memento section(s) from CLAUDE.md${NC}"
        else
            echo -e "${YELLOW}ℹ️  No Claude Memento sections found in CLAUDE.md${NC}"
        fi
    fi
}

# Function to preserve data
preserve_data() {
    backup_dir="$HOME/claude-memento-backup-$(date +%Y%m%d_%H%M%S)"
    local has_data=false
    
    # Check for checkpoints
    if [ -d "$MEMENTO_DIR/checkpoints" ] && [ "$(ls -A "$MEMENTO_DIR/checkpoints")" ]; then
        has_data=true
    fi
    
    # Check for chunks
    if [ -d "$MEMENTO_DIR/chunks" ] && [ "$(ls -A "$MEMENTO_DIR/chunks")" ]; then
        has_data=true
    fi
    
    if [ "$has_data" = true ]; then
        echo -e "${YELLOW}Preserving data...${NC}"
        mkdir -p "$backup_dir"
        
        # Copy checkpoints if exist
        if [ -d "$MEMENTO_DIR/checkpoints" ] && [ "$(ls -A "$MEMENTO_DIR/checkpoints")" ]; then
            cp -r "$MEMENTO_DIR/checkpoints" "$backup_dir/"
            echo -e "${GREEN}✓ Checkpoints backed up${NC}"
        fi
        
        # Copy chunks if exist
        if [ -d "$MEMENTO_DIR/chunks" ] && [ "$(ls -A "$MEMENTO_DIR/chunks")" ]; then
            cp -r "$MEMENTO_DIR/chunks" "$backup_dir/"
            echo -e "${GREEN}✓ Chunks backed up${NC}"
        fi
        
        # Copy graph database and vectorizer data if exists
        if [ -f "$MEMENTO_DIR/chunks/graph.json" ]; then
            cp "$MEMENTO_DIR/chunks/graph.json" "$backup_dir/" 2>/dev/null
            echo -e "${GREEN}✓ Graph database backed up${NC}"
        fi
        
        # Copy vectorizer data if exists
        if [ -f "$MEMENTO_DIR/chunks/vectors.json" ]; then
            cp "$MEMENTO_DIR/chunks/vectors.json" "$backup_dir/" 2>/dev/null
            echo -e "${GREEN}✓ Vector database backed up${NC}"
        fi
        
        # Copy configuration files
        if [ -f "$MEMENTO_DIR/config/settings.json" ]; then
            mkdir -p "$backup_dir/config"
            cp "$MEMENTO_DIR/config/settings.json" "$backup_dir/config/" 2>/dev/null
            echo -e "${GREEN}✓ Configuration backed up${NC}"
        fi
        
        echo -e "${GREEN}✓ Data backed up to: $backup_dir${NC}"
    fi
}

# Function to stop running processes with enhanced safety
stop_processes() {
    local stopped=false
    local timeout=10
    
    echo -e "${YELLOW}Checking for running processes...${NC}"
    
    # Check for auto-save daemon with timeout
    if [ -f "$MEMENTO_DIR/.auto-save.pid" ]; then
        local pid=$(cat "$MEMENTO_DIR/.auto-save.pid" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}Stopping auto-save daemon (PID: $pid)...${NC}"
            
            # Graceful shutdown first (SIGTERM)
            if kill -TERM "$pid" 2>/dev/null; then
                local count=0
                while [ $count -lt $timeout ] && kill -0 "$pid" 2>/dev/null; do
                    sleep 1
                    count=$((count + 1))
                done
                
                # Force kill if still running
                if kill -0 "$pid" 2>/dev/null; then
                    echo -e "${YELLOW}Force stopping process $pid...${NC}"
                    kill -KILL "$pid" 2>/dev/null
                fi
            fi
            
            rm -f "$MEMENTO_DIR/.auto-save.pid"
            echo -e "${GREEN}✓ Auto-save daemon stopped${NC}"
            stopped=true
        else
            # Stale or invalid PID file
            rm -f "$MEMENTO_DIR/.auto-save.pid" 2>/dev/null
        fi
    fi
    
    # Check for any other Claude Memento processes with improved detection
    # Look for processes running memento scripts
    local memento_pids
    if command -v pgrep >/dev/null 2>&1; then
        # Use pgrep for better process detection
        memento_pids=$(pgrep -f "claude-memento|/memento/" 2>/dev/null | tr '\n' ' ')
    else
        # Fallback to ps + grep
        memento_pids=$(ps aux 2>/dev/null | grep -E "claude-memento|/memento/" | grep -v grep | awk '{print $2}' | tr '\n' ' ')
    fi
    
    if [ -n "$memento_pids" ]; then
        echo -e "${YELLOW}Found Claude Memento processes: $memento_pids${NC}"
        for pid in $memento_pids; do
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                # Graceful shutdown first
                if kill -TERM "$pid" 2>/dev/null; then
                    sleep 2
                    # Force kill if still running
                    if kill -0 "$pid" 2>/dev/null; then
                        kill -KILL "$pid" 2>/dev/null
                    fi
                fi
                echo -e "${GREEN}✓ Stopped process $pid${NC}"
                stopped=true
            fi
        done
    fi
    
    if [ "$stopped" = false ]; then
        echo -e "${GREEN}✓ No running processes found${NC}"
    fi
    
    # Clean up any remaining PID files with validation
    find "$MEMENTO_DIR" -name ".*.pid" -type f -exec rm -f {} \; 2>/dev/null || true
    
    # Additional cleanup for temporary files
    rm -f "$MEMENTO_DIR"/tmp/* 2>/dev/null || true
    rm -f "/tmp/claude-memento-*" 2>/dev/null || true
}

# Check if installed
if ! check_installation; then
    echo -e "${RED}Error: Claude Memento is not installed!${NC}"
    exit 1
fi

# Confirm uninstallation with enhanced safety
if [ "$FORCE_REMOVE" = false ]; then
    echo -e "${YELLOW}This will uninstall Claude Memento.${NC}"
    if [ "$KEEP_DATA" = true ]; then
        echo "Checkpoint data will be preserved and backed up."
    else
        echo -e "${RED}⚠️  All checkpoint data will be PERMANENTLY deleted!${NC}"
        echo "Use '--keep-data' to preserve checkpoints."
    fi
    echo ""
    echo "This action will:"
    echo "  - Stop all running Claude Memento processes"
    echo "  - Remove Claude Memento section from CLAUDE.md"
    echo "  - Delete all installation files and scripts"
    if [ "$KEEP_DATA" = false ]; then
        echo -e "  ${RED}- DELETE all saved checkpoints and chunks${NC}"
    fi
    echo ""
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi
else
    echo -e "${YELLOW}Force removal mode - skipping confirmation${NC}"
fi

# Stop running processes first
stop_processes

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

# Remove cm-*.sh wrapper scripts
echo -e "${YELLOW}Removing wrapper scripts...${NC}"
rm -f "$COMMANDS_DIR"/cm-*.sh 2>/dev/null
echo -e "${GREEN}✓ Removed wrapper scripts${NC}"

# Remove agent files
echo -e "${YELLOW}Removing agent files...${NC}"
if [ -d "$AGENTS_DIR" ]; then
    rm -rf "$AGENTS_DIR"
    echo -e "${GREEN}✓ Removed agent files${NC}"
else
    echo -e "${YELLOW}ℹ️  No agent files found${NC}"
fi

# Remove claude-memento.md if exists
if [ -f "$MEMENTO_DIR/claude-memento.md" ]; then
    echo -e "${YELLOW}Removing active context tracker...${NC}"
    if [ "$KEEP_DATA" = true ]; then
        cp "$MEMENTO_DIR/claude-memento.md" "$backup_dir/claude-memento.md" 2>/dev/null
        echo -e "${GREEN}✓ Active context backed up${NC}"
    fi
    rm -f "$MEMENTO_DIR/claude-memento.md"
    echo -e "${GREEN}✓ Removed active context tracker${NC}"
fi

# Remove main installation
echo -e "${YELLOW}Removing Claude Memento files...${NC}"
if [ -d "$MEMENTO_DIR" ]; then
    if [ "$KEEP_DATA" = true ]; then
        # Remove everything except checkpoints and chunks
        find "$MEMENTO_DIR" -mindepth 1 -maxdepth 1 ! -name 'checkpoints' ! -name 'chunks' -exec rm -rf {} +
        # If checkpoints and chunks are empty, remove them too
        if [ ! "$(ls -A "$MEMENTO_DIR/checkpoints" 2>/dev/null)" ] && [ ! "$(ls -A "$MEMENTO_DIR/chunks" 2>/dev/null)" ]; then
            rm -rf "$MEMENTO_DIR"
        else
            echo -e "${YELLOW}ℹ️  Data preserved in: $MEMENTO_DIR${NC}"
            [ -d "$MEMENTO_DIR/checkpoints" ] && echo -e "${YELLOW}     - Checkpoints: $MEMENTO_DIR/checkpoints${NC}"
            [ -d "$MEMENTO_DIR/chunks" ] && echo -e "${YELLOW}     - Chunks: $MEMENTO_DIR/chunks${NC}"
            [ -f "$MEMENTO_DIR/chunks/graph.json" ] && echo -e "${YELLOW}     - Graph DB: $MEMENTO_DIR/chunks/graph.json${NC}"
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
echo ""
echo -e "${BLUE}For support or to reinstall:${NC}"
echo "  - Documentation: https://github.com/user/claude-memento"
echo "  - Reinstall: ./install.sh"
if [ "$KEEP_DATA" = true ]; then
    echo "  - Your data backups are preserved and can be restored"
fi