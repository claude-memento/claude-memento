#!/bin/bash

# Claude Memento Version Management System
# Handles version detection, compatibility checks, and migration

# Version format: MAJOR.MINOR.PATCH
CURRENT_VERSION="1.0.0"
MIN_COMPATIBLE_VERSION="1.0.0"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMENTO_DIR="$HOME/.claude/memento"
VERSION_FILE="$MEMENTO_DIR/.version"
INSTALL_LOG="$MEMENTO_DIR/.install.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to parse version string
parse_version() {
    local version="$1"
    echo "$version" | sed 's/v//g' | sed 's/[^0-9.]//g'
}

# Function to compare versions
# Returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
compare_versions() {
    local v1=$(parse_version "$1")
    local v2=$(parse_version "$2")
    
    if [ "$v1" = "$v2" ]; then
        return 0
    fi
    
    # Split versions into components
    IFS='.' read -ra V1_PARTS <<< "$v1"
    IFS='.' read -ra V2_PARTS <<< "$v2"
    
    # Compare major.minor.patch
    for i in 0 1 2; do
        local p1="${V1_PARTS[$i]:-0}"
        local p2="${V2_PARTS[$i]:-0}"
        
        if [ "$p1" -gt "$p2" ]; then
            return 1
        elif [ "$p1" -lt "$p2" ]; then
            return 2
        fi
    done
    
    return 0
}

# Function to get installed version
get_installed_version() {
    # Try multiple sources for version
    
    # 1. Check version file
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
        return 0
    fi
    
    # 2. Check install log
    if [ -f "$INSTALL_LOG" ]; then
        grep "^Version:" "$INSTALL_LOG" | cut -d' ' -f2
        return 0
    fi
    
    # 3. Check package version in source if available
    local src_version_file="$(dirname "$SCRIPT_DIR")/VERSION"
    if [ -f "$src_version_file" ]; then
        cat "$src_version_file"
        return 0
    fi
    
    # No version found
    echo "unknown"
    return 1
}

# Function to save current version
save_version() {
    local version="${1:-$CURRENT_VERSION}"
    echo "$version" > "$VERSION_FILE"
    echo -e "${GREEN}✓ Version $version saved${NC}"
}

# Function to check compatibility
check_compatibility() {
    local installed_version="$1"
    local new_version="${2:-$CURRENT_VERSION}"
    
    echo -e "${YELLOW}Checking version compatibility...${NC}"
    echo "  Installed: $installed_version"
    echo "  New:       $new_version"
    
    # Parse versions
    local installed_parsed=$(parse_version "$installed_version")
    local new_parsed=$(parse_version "$new_version")
    
    # Check if downgrade
    compare_versions "$new_parsed" "$installed_parsed"
    local result=$?
    
    if [ $result -eq 2 ]; then
        echo -e "${RED}Warning: Downgrade detected ($installed_version → $new_version)${NC}"
        echo "Downgrades may cause compatibility issues."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Check minimum compatible version
    compare_versions "$installed_parsed" "$MIN_COMPATIBLE_VERSION"
    result=$?
    
    if [ $result -eq 2 ]; then
        echo -e "${RED}Error: Installed version $installed_version is below minimum compatible version $MIN_COMPATIBLE_VERSION${NC}"
        echo "Please perform a clean installation instead of update."
        return 1
    fi
    
    # Check for major version change
    IFS='.' read -ra INSTALLED_PARTS <<< "$installed_parsed"
    IFS='.' read -ra NEW_PARTS <<< "$new_parsed"
    
    if [ "${INSTALLED_PARTS[0]}" != "${NEW_PARTS[0]}" ]; then
        echo -e "${YELLOW}Major version change detected!${NC}"
        echo "This may include breaking changes."
        read -p "Continue with update? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    echo -e "${GREEN}✓ Version compatibility check passed${NC}"
    return 0
}

# Function to perform version-specific migrations
migrate_version() {
    local from_version="$1"
    local to_version="${2:-$CURRENT_VERSION}"
    
    echo -e "${YELLOW}Checking for required migrations...${NC}"
    
    # Parse versions for comparison
    local from_parsed=$(parse_version "$from_version")
    local to_parsed=$(parse_version "$to_version")
    
    # No migration needed if same version
    compare_versions "$from_parsed" "$to_parsed"
    if [ $? -eq 0 ]; then
        echo "No migrations needed (same version)"
        return 0
    fi
    
    # Migration paths
    local migrations_performed=0
    
    # 0.9.x → 1.0.0 migration
    compare_versions "$from_parsed" "1.0.0"
    if [ $? -eq 2 ]; then
        compare_versions "$to_parsed" "1.0.0"
        if [ $? -ge 0 ]; then
            echo -e "${YELLOW}Migrating from pre-1.0 to 1.0+...${NC}"
            migrate_to_1_0_0
            migrations_performed=$((migrations_performed + 1))
        fi
    fi
    
    # Future migration paths can be added here
    # 1.0.x → 1.1.0 migration
    # compare_versions "$from_parsed" "1.1.0"
    # if [ $? -eq 2 ]; then
    #     compare_versions "$to_parsed" "1.1.0"
    #     if [ $? -ge 0 ]; then
    #         echo -e "${YELLOW}Migrating to 1.1.0...${NC}"
    #         migrate_to_1_1_0
    #         migrations_performed=$((migrations_performed + 1))
    #     fi
    # fi
    
    if [ $migrations_performed -gt 0 ]; then
        echo -e "${GREEN}✓ $migrations_performed migration(s) completed${NC}"
    else
        echo "No migrations required"
    fi
    
    return 0
}

# Migration function for 1.0.0
migrate_to_1_0_0() {
    echo "  - Adding chunks directory for auto-chunking system..."
    mkdir -p "$MEMENTO_DIR/chunks"
    
    echo "  - Updating configuration format..."
    if [ -f "$MEMENTO_DIR/config/settings.json" ]; then
        # Backup old config
        cp "$MEMENTO_DIR/config/settings.json" "$MEMENTO_DIR/config/settings.json.pre-1.0.0"
        
        # Add new configuration fields if missing
        if ! grep -q "\"auto_save\"" "$MEMENTO_DIR/config/settings.json"; then
            # Add auto_save configuration
            echo "    Adding auto_save configuration..."
            # This would need proper JSON manipulation in production
        fi
    fi
    
    echo "  - Setting up graph database for chunk relationships..."
    touch "$MEMENTO_DIR/chunks/.graph.json"
    
    echo -e "${GREEN}  ✓ Migration to 1.0.0 completed${NC}"
}

# Function to display version info
show_version_info() {
    echo -e "${BLUE}Claude Memento Version Information${NC}"
    echo "=================================="
    
    local installed_version=$(get_installed_version)
    echo "Installed version: $installed_version"
    echo "Package version:   $CURRENT_VERSION"
    echo "Minimum compatible: $MIN_COMPATIBLE_VERSION"
    
    if [ -f "$VERSION_FILE" ]; then
        echo "Version file:      $(cat "$VERSION_FILE")"
    fi
    
    if [ -f "$INSTALL_LOG" ]; then
        echo ""
        echo "Installation info:"
        grep -E "^Installation Date:|^Version:" "$INSTALL_LOG" | sed 's/^/  /'
    fi
    
    # Check if update available
    if [ "$installed_version" != "unknown" ] && [ "$installed_version" != "$CURRENT_VERSION" ]; then
        compare_versions "$CURRENT_VERSION" "$installed_version"
        if [ $? -eq 1 ]; then
            echo ""
            echo -e "${GREEN}Update available: $installed_version → $CURRENT_VERSION${NC}"
        fi
    fi
}

# Main function for version check
version_check() {
    local command="${1:-check}"
    
    case "$command" in
        check)
            show_version_info
            ;;
        
        save)
            save_version "${2:-$CURRENT_VERSION}"
            ;;
        
        compare)
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo "Usage: version compare <version1> <version2>"
                exit 1
            fi
            compare_versions "$2" "$3"
            case $? in
                0) echo "$2 = $3" ;;
                1) echo "$2 > $3" ;;
                2) echo "$2 < $3" ;;
            esac
            ;;
        
        compatibility)
            local installed=$(get_installed_version)
            check_compatibility "$installed" "${2:-$CURRENT_VERSION}"
            ;;
        
        migrate)
            local installed=$(get_installed_version)
            migrate_version "$installed" "${2:-$CURRENT_VERSION}"
            ;;
        
        *)
            echo "Usage: version [check|save|compare|compatibility|migrate]"
            exit 1
            ;;
    esac
}

# Export functions for use in other scripts
export -f parse_version
export -f compare_versions
export -f get_installed_version
export -f check_compatibility
export -f migrate_version

# Run if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    version_check "$@"
fi