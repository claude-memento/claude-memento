#!/bin/bash

# SuperClaude command wrapper for /cm:last
# This file should be placed in ~/.claude/commands/

MEMENTO_DIR="$HOME/.claude/memento"

# Execute last command
"$MEMENTO_DIR/commands/last.sh" "$@"