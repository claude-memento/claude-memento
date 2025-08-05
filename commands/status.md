---
allowed-tools: [Read, Bash, Glob]
description: "Claude Memento - Show system status and configuration"
---

# /cm:status - System Status

## Purpose
Display Claude Memento system status, configuration, and health information.

## Usage
```
/cm:status [--config] [--storage] [--hooks] [--health]
```

## Arguments
- `--config` - Show current configuration settings
- `--storage` - Display storage usage and statistics
- `--hooks` - List configured hooks and their status
- `--health` - Run system health checks
- `--verbose` - Show detailed system information

## Execution
1. Load system configuration and validate settings
2. Check storage usage and available space
3. Verify hook system and plugin status
4. Run diagnostic checks on core components
5. Display comprehensive status summary

## Claude Code Integration
- Uses Read for configuration file analysis
- Leverages Bash for system diagnostics
- Applies Glob for storage analysis
- Maintains system health monitoring

## Implementation
```bash
#!/bin/bash
CLAUDE_MEMENTO_BRIDGE=1
MEMENTO_DIR="$HOME/.claude/memento"
export CLAUDE_MEMENTO_BRIDGE
"$MEMENTO_DIR/src/bridge/claude-code-bridge.sh" status "$@"
```