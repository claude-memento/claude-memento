#!/bin/bash

# SuperClaude command wrapper for /cm:status
# This file should be placed in ~/.claude/commands/

MEMENTO_DIR="$HOME/.claude/memento"

# Execute status command
"$MEMENTO_DIR/commands/status.sh" "$@"