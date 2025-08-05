# Claude Memento Operating Rules

## Checkpoint Creation Rules

### 1. Automatic Triggers
- Every 15 minutes of active conversation
- Before major context switches
- On explicit save commands
- When working memory exceeds threshold

### 2. Data Selection
- Current conversation context
- Active file references with paths
- Session metadata (timestamp, duration)
- Exclude sensitive information (keys, passwords)
- Include command history

### 3. Retention Policy
- Keep last 10 checkpoints by default
- Preserve tagged checkpoints indefinitely
- Auto-cleanup after 30 days
- Maintain at least 3 checkpoints
- Honor user retention settings

## Loading Rules

### 1. Context Restoration
- Merge with current context (non-destructive)
- Preserve existing work
- Clear notification of loaded state
- Maintain context continuity

### 2. Conflict Resolution
- Current context takes precedence
- User confirmation for overwrites
- Automatic backup before load
- Detailed conflict reporting

### 3. Validation
- Verify checkpoint integrity
- Check version compatibility
- Validate file references
- Ensure data completeness

## Storage Rules

### 1. File Organization
- ISO 8601 timestamps (YYYYMMDD-HHMMSS)
- Descriptive naming with sanitization
- Metadata in JSON format
- Separate index file

### 2. Compression
- Gzip for text content
- Threshold: >1MB uncompressed
- Maintain readability for debugging
- Preserve metadata uncompressed

### 3. Storage Limits
- Maximum 1GB total storage
- Single checkpoint limit: 50MB
- Automatic compression above 5MB
- Warning at 80% capacity

## Hook Execution Rules

### 1. Timing
- Pre-hooks before operation
- Post-hooks after success only
- Timeout: 5 seconds per hook
- Async execution where possible

### 2. Error Handling
- Continue on hook failure
- Log all hook errors
- User notification for critical failures
- Rollback support

### 3. Security
- Sandboxed execution
- No network access
- Limited file system access
- User approval for new hooks

## Data Integrity Rules

### 1. Validation
- Checksum verification
- Structure validation
- Metadata consistency
- Reference integrity

### 2. Backup
- Before destructive operations
- Rotating backup strategy
- Off-site backup support
- Recovery procedures

### 3. Privacy
- No telemetry
- Local processing only
- Secure deletion
- Data anonymization options