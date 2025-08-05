---
allowed-tools: [Read, Write, Edit, Bash, Glob]
description: "Claude Memento - Hook system management"
---

# /cm:hooks - Hook System Management

## Purpose
Manage Claude Memento hook system for extending functionality with custom scripts and integrations.

## Usage
```
/cm:hooks [action] [hook-name] [--type pre|post] [--event checkpoint|load|cleanup]
```

## Arguments
- `action` - Hook action (create, edit, remove, enable, disable, list)
- `hook-name` - Name of the hook to manage
- `--type` - Hook type (pre or post execution)
- `--event` - Event type (checkpoint, load, cleanup)
- `--list` - List all configured hooks
- `--test` - Test hook execution

## Execution
1. Parse hook management command and parameters
2. Validate hook configuration and permissions
3. Execute requested hook management operation
4. Update hook registry and configuration
5. Provide hook status and execution feedback

## Claude Code Integration
- Uses Read for hook script analysis
- Leverages Write/Edit for hook creation and modification
- Applies Bash for hook execution and testing
- Maintains hook system security and validation

## Implementation
```bash
#!/bin/bash
CLAUDE_MEMENTO_BRIDGE=1
MEMENTO_DIR="$HOME/.claude/memento"
export CLAUDE_MEMENTO_BRIDGE
"$MEMENTO_DIR/src/bridge/claude-code-bridge.sh" hooks "$@"
```