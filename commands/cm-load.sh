#!/bin/bash

# SuperClaude command wrapper for /cm:load
# This file should be placed in ~/.claude/commands/

MEMENTO_DIR="$HOME/.claude/memento"

# Execute load command
"$MEMENTO_DIR/commands/load.sh" "$@"