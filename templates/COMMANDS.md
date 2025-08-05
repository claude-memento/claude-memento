# Claude Memento Commands

## Available Commands

### /cm:save [name] [options]
Save current conversation context as a checkpoint.

**Options:**
- `--compress` - Enable compression
- `--include-files` - Include working files
- `--tag tag1,tag2` - Add tags for filtering
- `--note "description"` - Add descriptive note

**Examples:**
```bash
/cm:save "auth feature complete"
/cm:save --include-files --tag feature,auth
/cm:save quick --compress
```

### /cm:load [checkpoint]
Load a saved checkpoint to restore context.

**Arguments:**
- `checkpoint` - Checkpoint ID or name (optional, defaults to latest)

**Examples:**
```bash
/cm:load
/cm:load checkpoint-20240119-1530
/cm:load "auth feature complete"
```

### /cm:list [options]
List available checkpoints.

**Options:**
- `--limit N` - Show last N checkpoints
- `--tag tag` - Filter by tag
- `--date YYYY-MM-DD` - Filter by date
- `--format short|detailed` - Output format

**Examples:**
```bash
/cm:list
/cm:list --limit 5
/cm:list --tag feature --format detailed
```

### /cm:status
Show current memory usage and system status.

**Output includes:**
- Total checkpoints
- Storage usage
- Latest checkpoint info
- Configuration summary
- Hook status

### /cm:config [key] [value]
Manage configuration settings.

**Operations:**
- No args - Show all settings
- `key` only - Show specific setting
- `key value` - Update setting

**Examples:**
```bash
/cm:config
/cm:config checkpoint.retention
/cm:config checkpoint.retention 10
```

### /cm:hooks [action] [args]
Manage automation hooks.

**Actions:**
- `list` - Show all hooks
- `enable <hook>` - Enable a hook
- `disable <hook>` - Disable a hook
- `test <hook>` - Test hook execution

**Examples:**
```bash
/cm:hooks list
/cm:hooks enable pre-save
/cm:hooks test post-load
```

### /cm:last [options]
Quick access to the most recent checkpoint.

**Options:**
- `--info` - Show checkpoint details
- `--load` - Load the checkpoint
- `--diff` - Show changes since checkpoint

**Examples:**
```bash
/cm:last --info
/cm:last --load
```