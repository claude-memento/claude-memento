---
allowed-tools: [Read, Grep, Bash]
description: "Claude Memento - List and search saved checkpoints"
---

# /cm:list - Checkpoint Management

## Purpose
List, search, and manage saved conversation checkpoints with filtering and sorting options.

## Usage
```
/cm:list [--search term] [--tag tag] [--limit n] [--sort date|size|name]
```

## Arguments
- `--search` - Search checkpoints by content, description, or metadata
- `--tag` - Filter checkpoints by specific tags
- `--limit` - Limit number of results (default: 10)
- `--sort` - Sort by date, size, or name (default: date descending)
- `--stats` - Show detailed statistics and storage information
- `--all` - Show all checkpoints (override limit)

## Execution
1. Load checkpoint index and metadata
2. Apply search filters and tag filtering
3. Sort results according to specified criteria
4. Display formatted checkpoint list with key information
5. Provide storage statistics and usage insights

## Claude Code Integration
- Uses Read for index and metadata loading
- Leverages Grep for content search across checkpoints
- Applies Bash for file system operations
- Maintains efficient checkpoint browsing experience

## Implementation
```bash
#!/bin/bash
CLAUDE_MEMENTO_BRIDGE=1
MEMENTO_DIR="$HOME/.claude/memento"
export CLAUDE_MEMENTO_BRIDGE
"$MEMENTO_DIR/src/bridge/claude-code-bridge.sh" list "$@"
```