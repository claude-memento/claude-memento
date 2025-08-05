---
allowed-tools: [Read, Write, Bash, Glob, Grep]
description: "Claude Memento - Save conversation context and working memory"
---

# /cm:save - Conversation Context Save

## Purpose
Save current conversation context, working memory, and session state for future retrieval.

## Usage
```
/cm:save [checkpoint-name] [--include-files] [--compress] [--tag tag1,tag2]
```

## Arguments
- `checkpoint-name` - Optional name for the checkpoint (auto-generated if not provided)
- `--include-files` - Include current working files in the checkpoint
- `--compress` - Enable compression for large checkpoints
- `--tag` - Add tags for easier filtering and search
- `--note` - Add descriptive note to the checkpoint

## Execution
1. Capture current conversation context and working state
2. Create checkpoint with metadata (timestamp, session info, files)
3. Run pre-checkpoint hooks if configured
4. Save checkpoint data with optional compression
5. Update index and run post-checkpoint hooks
6. Provide checkpoint summary and access information

## Claude Code Integration
- Uses Read for file content analysis
- Leverages Write for checkpoint data storage
- Applies Bash for system-level operations
- Maintains structured checkpoint metadata

## Implementation
```bash
#!/bin/bash
CLAUDE_MEMENTO_BRIDGE=1
MEMENTO_DIR="$HOME/.claude/memento"
export CLAUDE_MEMENTO_BRIDGE
"$MEMENTO_DIR/src/bridge/claude-code-bridge.sh" save "$@"
```