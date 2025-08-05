---
allowed-tools: [Read, Grep, Bash, Glob]
description: "Claude Memento - Load conversation context and working memory"
---

# /cm:load - Conversation Context Load

## Purpose
Load previously saved conversation context, working memory, and session state.

## Usage
```
/cm:load [checkpoint-id|pattern] [--files] [--search term] [--tag tag]
```

## Arguments
- `checkpoint-id` - Specific checkpoint ID or partial pattern to match
- `--files` - Also restore working files from the checkpoint
- `--search` - Search checkpoints by content or description
- `--tag` - Filter checkpoints by tag
- `--latest` - Load the most recent checkpoint
- `--interactive` - Show selection menu for multiple matches

## Execution
1. Search and identify target checkpoint(s)
2. Load checkpoint metadata and validate integrity
3. Run pre-load hooks if configured
4. Restore conversation context and working state
5. Optionally restore associated files
6. Run post-load hooks and provide restoration summary

## Claude Code Integration
- Uses Read for checkpoint data loading
- Leverages Grep for content search
- Applies Bash for file restoration
- Maintains context continuity across sessions

## Implementation
```bash
#!/bin/bash
CLAUDE_MEMENTO_BRIDGE=1
MEMENTO_DIR="$HOME/.claude/memento"
export CLAUDE_MEMENTO_BRIDGE
"$MEMENTO_DIR/src/bridge/claude-code-bridge.sh" load "$@"
```