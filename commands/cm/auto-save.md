# /cm:auto-save - Automatic Save Management

## Purpose
Configure and manage automatic checkpoint creation for continuous context preservation. Provides both timer-based and session-end auto-save capabilities.

## Usage
```
/cm:auto-save [command] [options]
```

## Commands

### enable
Enable auto-save and start the background daemon.
```
/cm:auto-save enable
```

### disable
Disable auto-save and stop the background daemon.
```
/cm:auto-save disable
```

### start
Start the auto-save daemon (without changing enabled state).
```
/cm:auto-save start
```

### stop
Stop the auto-save daemon (without changing enabled state).
```
/cm:auto-save stop
```

### restart
Restart the auto-save daemon.
```
/cm:auto-save restart
```

### status
Show current auto-save status and configuration.
```
/cm:auto-save status
```

### save
Force an immediate auto-save checkpoint.
```
/cm:auto-save save
```

### config [key] [value]
Configure auto-save settings.
```
/cm:auto-save config                    # Show all settings
/cm:auto-save config interval 600       # Set interval to 10 minutes
/cm:auto-save config on-session-end false  # Disable session-end saves
```

## Configuration Options

### interval <seconds>
Set the auto-save interval in seconds.
- Default: 900 (15 minutes)
- Range: 60-3600 (1 minute to 1 hour)

### on-session-end <true|false>
Enable or disable saving when Claude Code session ends.
- Default: true

## Features

### Timer-Based Auto-Save
- **Background Daemon**: Runs without interrupting work
- **Change Detection**: Only saves if content has been modified
- **Configurable Interval**: Customize save frequency
- **Smart Chunking**: Automatically chunks large contexts

### Session-End Auto-Save
- **Automatic Trigger**: Saves when closing Claude Code
- **No Data Loss**: Preserves work even on unexpected exits
- **Conditional**: Only saves if there are changes
- **Enabled by Default**: Works out of the box

### Integration
- **Works with Chunking**: Large checkpoints automatically split
- **Respects Limits**: Maintains checkpoint retention settings
- **Hook Compatible**: Integrates with existing hook system

## Examples

### Basic Setup
```bash
# Enable auto-save with default settings
/cm:auto-save enable

# Check current status
/cm:auto-save status
```

### Custom Configuration
```bash
# Set to save every 10 minutes
/cm:auto-save config interval 600

# Disable session-end saves
/cm:auto-save config on-session-end false

# View current configuration
/cm:auto-save config
```

### Manual Control
```bash
# Force immediate save
/cm:auto-save save

# Temporarily stop daemon
/cm:auto-save stop

# Resume daemon
/cm:auto-save start
```

## Default Settings
```json
{
  "autoSave": {
    "enabled": false,
    "interval": 900,
    "onSessionEnd": true,
    "compression": true,
    "maxCheckpoints": 10
  }
}
```

## Status Output Example
```
Auto-Save Status:
=================
Enabled: Yes
Interval: 900 seconds (15 minutes)
Daemon: Running (PID: 12345)
Last save: 2024-01-20 14:30:00
```

## Implementation
```bash
#!/bin/bash
CLAUDE_MEMENTO_BRIDGE=1
MEMENTO_DIR="$HOME/.claude/memento"
export CLAUDE_MEMENTO_BRIDGE
"$MEMENTO_DIR/src/commands/auto-save.sh" "$@"
```