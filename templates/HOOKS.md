# Claude Memento Hook System

## Overview

Hooks allow customization and automation of Claude Memento operations. They are shell scripts executed at specific points in the checkpoint lifecycle.

## Available Hooks

### pre-save
Executed before checkpoint creation.

**Environment variables:**
- `CM_CHECKPOINT_NAME` - Proposed checkpoint name
- `CM_CHECKPOINT_PATH` - Where it will be saved
- `CM_CONTEXT_SIZE` - Size of context data

**Use cases:**
- Validate checkpoint data
- Add custom metadata
- Filter sensitive information
- Cancel save operation (exit 1)

### post-save
Executed after successful checkpoint creation.

**Environment variables:**
- `CM_CHECKPOINT_ID` - Created checkpoint ID
- `CM_CHECKPOINT_PATH` - Full path to checkpoint
- `CM_CHECKPOINT_SIZE` - Final size after compression

**Use cases:**
- Send notifications
- Update external systems
- Trigger backups
- Create summaries

### pre-load
Executed before loading a checkpoint.

**Environment variables:**
- `CM_CHECKPOINT_ID` - Checkpoint to be loaded
- `CM_CURRENT_CONTEXT` - Current context summary
- `CM_CHECKPOINT_AGE` - Age of checkpoint

**Use cases:**
- Backup current state
- Validate checkpoint integrity
- User confirmation
- Prepare environment

### post-load
Executed after successful checkpoint load.

**Environment variables:**
- `CM_CHECKPOINT_ID` - Loaded checkpoint ID
- `CM_LOAD_STATUS` - Success/partial/failed
- `CM_RESTORED_FILES` - Number of files restored

**Use cases:**
- Update UI state
- Refresh dependencies
- Log operations
- Notify integrations

### pre-delete
Executed before checkpoint deletion.

**Environment variables:**
- `CM_CHECKPOINT_ID` - Checkpoint to be deleted
- `CM_CHECKPOINT_TAGS` - Associated tags
- `CM_DELETE_REASON` - Automatic/manual

**Use cases:**
- Backup before deletion
- Confirm deletion
- Archive important data

## Configuration

Hooks are configured in `~/.claude/memento/config/hooks.json`:

```json
{
  "pre-save": [
    {
      "name": "filter-secrets",
      "script": "hooks/filter-secrets.sh",
      "enabled": true,
      "timeout": 5
    }
  ],
  "post-save": [
    {
      "name": "notify",
      "script": "hooks/notify.sh",
      "enabled": false
    }
  ]
}
```

## Writing Hooks

### Example Hook Script

```bash
#!/bin/bash
# hooks/filter-secrets.sh

# Check for common secret patterns
if grep -qE "(api_key|password|secret|token)\\s*[:=]" "$CM_CONTEXT_FILE"; then
    echo "WARNING: Potential secrets detected"
    # Remove them
    sed -i -E 's/(api_key|password|secret|token)\\s*[:=]\\s*[^\\s]+/\\1=<FILTERED>/g' "$CM_CONTEXT_FILE"
fi

# Success
exit 0
```

### Best Practices

1. **Fast Execution** - Keep hooks lightweight
2. **Error Handling** - Always handle errors gracefully
3. **Logging** - Log to `$CM_HOOK_LOG`
4. **Exit Codes** - 0 for success, 1 to abort operation
5. **Idempotency** - Hooks should be safe to run multiple times

## Built-in Hooks

### filter-secrets
Removes common secret patterns from checkpoints.

### compress-images
Optimizes images included in checkpoints.

### git-snapshot
Creates a git commit alongside checkpoints.

### sync-remote
Syncs checkpoints to remote storage (disabled by default).

## Debugging Hooks

Enable debug mode:
```bash
/cm:config hooks.debug true
```

Test a specific hook:
```bash
/cm:hooks test pre-save filter-secrets
```

View hook logs:
```bash
cat ~/.claude/memento/logs/hooks.log
```