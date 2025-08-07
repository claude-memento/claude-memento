# Auto-Save System

Automatic checkpoint creation for continuous context preservation.

## Overview

Claude Memento provides two auto-save mechanisms:
1. **Session End Auto-Save**: Automatically saves when Claude Code session ends
2. **Timer-Based Auto-Save**: Periodically saves at configurable intervals

Both features work with the auto-chunking system for unlimited context storage.

## Session End Auto-Save

### How It Works

When you close Claude Code or end a conversation:
1. Session end hook triggers automatically
2. Checks if there are unsaved changes
3. Creates checkpoint with timestamp
4. Auto-chunks if content >10KB

### Setup

The session end hook is automatically installed. To ensure it works:

```bash
# Verify hook is installed
ls ~/.claude/hooks/claude-session-end.sh

# Check if executable
chmod +x ~/.claude/hooks/claude-session-end.sh
```

### Configuration

Control session end saves:
```bash
/cm:auto-save config on-session-end true   # Enable (default)
/cm:auto-save config on-session-end false  # Disable
```

## Timer-Based Auto-Save

### Features

- **Configurable Intervals**: Default 15 minutes
- **Change Detection**: Only saves if content changed
- **Background Daemon**: Runs without interrupting work
- **Smart Chunking**: Auto-chunks large contexts

### Commands

```bash
# Enable and start auto-save
/cm:auto-save enable

# Disable and stop auto-save
/cm:auto-save disable

# Check status
/cm:auto-save status

# Manual control
/cm:auto-save start    # Start daemon
/cm:auto-save stop     # Stop daemon
/cm:auto-save restart  # Restart daemon

# Force immediate save
/cm:auto-save save
```

### Configuration

```bash
# Set save interval (in seconds)
/cm:auto-save config interval 600    # 10 minutes
/cm:auto-save config interval 1800   # 30 minutes
/cm:auto-save config interval 3600   # 1 hour

# View current settings
/cm:auto-save config
```

## Default Settings

```json
{
  "autoSave": {
    "enabled": false,          // Timer disabled by default
    "interval": 900,           // 15 minutes
    "onSessionEnd": true,      // Session end enabled
    "compression": true,       // Compress checkpoints
    "maxCheckpoints": 10       // Keep last 10 auto-saves
  }
}
```

## How Auto-Save Works

### Timer Process

1. **Daemon Start**: Background process monitors changes
2. **Interval Check**: Every minute, checks if save interval reached
3. **Change Detection**: Compares file modification times
4. **Smart Save**: Only saves if changes detected
5. **Auto-Chunking**: Large contexts automatically split

### Save Conditions

Auto-save triggers when ALL conditions are met:
- Auto-save is enabled
- Interval time has passed
- Context file has been modified
- No manual save in progress

## Integration with Chunking

Auto-saved checkpoints work seamlessly with chunking:
- Checkpoints >10KB automatically chunked
- Manifest created for smart loading
- Query-based retrieval supported

Example auto-save with chunking:
```
[15:30:00] Auto-save triggered
[15:30:01] Large checkpoint detected (45KB)
[15:30:02] Creating 12 chunks...
[15:30:03] Auto-save completed
```

## Best Practices

### Recommended Settings

**For Active Development**:
```bash
/cm:auto-save enable
/cm:auto-save config interval 600    # 10 minutes
```

**For Long Sessions**:
```bash
/cm:auto-save enable
/cm:auto-save config interval 1800   # 30 minutes
```

**For Critical Work**:
```bash
/cm:auto-save enable
/cm:auto-save config interval 300    # 5 minutes
```

### Tips

1. **Start Small**: Begin with 15-minute intervals
2. **Monitor Storage**: Check `/cm:status` periodically
3. **Manual Saves**: Still use `/cm:save` for milestones
4. **Trust the System**: Auto-chunking handles large contexts

## Troubleshooting

### Auto-Save Not Working

```bash
# Check if enabled
/cm:auto-save status

# Check daemon
ps aux | grep auto-save

# View logs
cat ~/.claude/memento/logs/hooks.log
```

### Session End Save Not Triggering

1. Verify hook installation:
```bash
ls -la ~/.claude/hooks/
```

2. Check hook execution:
```bash
tail -f ~/.claude/memento/logs/hooks.log
```

3. Test manually:
```bash
~/.claude/hooks/claude-session-end.sh
```

### High Disk Usage

Auto-saves respect the checkpoint retention limit:
```bash
# Check current checkpoints
/cm:list

# Adjust retention (in config)
"maxCheckpoints": 10
```

## Performance Impact

- **CPU**: Minimal (<1% for checks)
- **Memory**: ~5MB for daemon
- **Disk I/O**: Only during saves
- **Network**: None (all local)

## Future Enhancements

- Incremental saves (only changes)
- Smart scheduling (activity-based)
- Compression optimization
- Cloud backup integration
- Save profiles (dev/production)