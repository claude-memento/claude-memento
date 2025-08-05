#!/bin/bash

# SuperClaude command wrapper for /cm:list
# This file should be placed in ~/.claude/commands/

MEMENTO_DIR="$HOME/.claude/memento"

# Execute list command
"$MEMENTO_DIR/commands/list.sh" "$@"