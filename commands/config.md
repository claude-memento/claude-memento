---
allowed-tools: [Read, Write, Edit, Bash]
description: "Claude Memento - Configuration management"
---

# /cm:config - Configuration Management

## Purpose
Manage Claude Memento configuration settings, preferences, and system options.

## Usage
```
/cm:config [key] [value] [--get] [--set] [--list] [--reset]
```

## Arguments
- `key` - Configuration key to get or set
- `value` - Value to set for the specified key
- `--get` - Get specific configuration value
- `--set` - Set configuration key-value pair
- `--list` - List all configuration settings
- `--reset` - Reset configuration to defaults
- `--edit` - Open configuration file in editor

## Execution
1. Load current configuration from files
2. Parse and validate configuration settings
3. Apply requested configuration changes
4. Update configuration files with new settings
5. Verify configuration integrity and provide feedback

## Claude Code Integration
- Uses Read for configuration file loading
- Leverages Write/Edit for configuration updates
- Applies Bash for system-level configuration
- Maintains configuration validation and backup

## Implementation
```bash
#!/bin/bash
CLAUDE_MEMENTO_BRIDGE=1
MEMENTO_DIR="$HOME/.claude/memento"
export CLAUDE_MEMENTO_BRIDGE
"$MEMENTO_DIR/src/bridge/claude-code-bridge.sh" config "$@"
```