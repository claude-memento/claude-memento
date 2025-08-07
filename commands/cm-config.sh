#!/bin/bash

# SuperClaude command wrapper for /cm:config
# This file should be placed in ~/.claude/commands/

MEMENTO_DIR="$HOME/.claude/memento"

# Execute config command
"$MEMENTO_DIR/src/commands/config.sh" "$@"