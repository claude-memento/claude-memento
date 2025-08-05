#!/bin/bash

# SuperClaude command wrapper for /cm:save
# This file should be placed in ~/.claude/commands/

MEMENTO_DIR="$HOME/.claude/memento"

# Execute save command
"$MEMENTO_DIR/commands/save.sh" "$@"