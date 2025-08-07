<!-- Claude Memento Integration for CLAUDE.md -->
<!-- Add this section to your ~/.claude/CLAUDE.md file -->

## 🧠 Claude Memento Integration

### Quick Commands
- `/cm:save [reason]` - Save current context checkpoint
- `/cm:load [checkpoint]` - Load previous context
- `/cm:last` - View/load last checkpoint
- `/cm:list` - List all checkpoints
- `/cm:chunk search [query]` - Smart context search
- `/cm:status` - Memory system status

### Auto-Context Tracking
**Active Context File**: `~/.claude/memento/claude-memento.md`
- Automatically tracks conversation history
- Records file operations (Read/Write/Edit)
- Preserves decision rationale
- Maintains task progress

### Checkpoint Strategy
```bash
# Quick save after completing a feature
/cm:save "Implemented user authentication"

# Save with file context
/cm:save --include-files "API endpoints complete"

# Load specific context
/cm:load --query "database schema"
```

### Smart Features
- **Auto-Chunking**: Large contexts automatically split into manageable chunks
- **Relationship Graph**: Chunks linked by semantic similarity
- **Intelligent Loading**: Query-based selective context restoration
- **Real-time Capture**: Continuous context preservation

### Best Practices
1. Save checkpoint after major milestones
2. Use descriptive save reasons
3. Load relevant context before continuing work
4. Review `/cm:status` periodically
5. Use chunk search for specific topics

### Configuration
```bash
# Set auto-save interval (minutes)
/cm:config auto-save.interval 15

# Enable compression for large contexts
/cm:config checkpoint.compress true

# Set retention period (days)
/cm:config checkpoint.retention 30
```

---
*Claude Memento v1.0.0 - Never lose context again*