---
allowed-tools: [Read, Bash]
description: "Claude Memento - Quick access to last checkpoint"
---

# /cm:last - Last Checkpoint Access

## Purpose
Quick access to the most recently created checkpoint for immediate loading or information.

## Usage
```
/cm:last [--load] [--info] [--files]
```

## Arguments
- `--load` - Automatically load the last checkpoint
- `--info` - Show detailed information about the last checkpoint
- `--files` - List files included in the last checkpoint
- `--quick` - Quick summary of last checkpoint

## Execution
1. Identify the most recent checkpoint from index
2. Load checkpoint metadata and basic information
3. Optionally load the checkpoint content
4. Display checkpoint summary and contents
5. Provide quick access options for further actions

## Claude Code Integration
- Uses Read for checkpoint metadata loading
- Leverages Bash for quick checkpoint operations
- Maintains efficient access to recent checkpoints
- Provides streamlined user experience for common operations

## Implementation
```bash
#!/bin/bash
CLAUDE_MEMENTO_BRIDGE=1
MEMENTO_DIR="$HOME/.claude/memento"
export CLAUDE_MEMENTO_BRIDGE
"$MEMENTO_DIR/src/bridge/claude-code-bridge.sh" last "$@"
```