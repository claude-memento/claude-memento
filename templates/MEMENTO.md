# Claude Memento Entry Point

Memory management extension for Claude Code.

@COMMANDS.md
@PRINCIPLES.md
@RULES.md
@HOOKS.md

## System Overview

Claude Memento provides checkpoint-based conversation memory management with:
- Context preservation across sessions
- Automatic compression and optimization
- Hook-based automation
- Flexible configuration

## Quick Start

```bash
# Save current context
/cm:save "Feature implementation complete"

# Load previous context
/cm:load checkpoint-20240119-1530

# Check status
/cm:status
```

## Architecture

### Components
- **Checkpoint System**: Core memory persistence
- **Hook Manager**: Automation and integration
- **Configuration**: Flexible settings management
- **Command Interface**: Claude Code integration

### Data Flow
1. Context capture from current session
2. Compression and optimization
3. Metadata generation
4. Secure local storage
5. Index update for quick retrieval

## Installation

Claude Memento is installed at `~/.claude/memento/` and integrates seamlessly with Claude Code.

## Version

Claude Memento v1.0.0