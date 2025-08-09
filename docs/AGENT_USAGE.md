# Context-Manager-Memento Agent Usage Guide

## Overview

The `context-manager-memento` agent provides enhanced context management with Claude Memento integration, automatically maintaining coherent state across multiple agent interactions and sessions.

## Core Commands

### Basic Operations
- `/cm:save [reason]` - Save current context checkpoint
- `/cm:load [checkpoint]` - Load specific checkpoint or last saved
- `/cm:last` - View and load most recent checkpoint
- `/cm:list` - List all available checkpoints
- `/cm:status` - View memory usage and system status

### Smart Search
- `/cm:chunk search [query]` - Search through context chunks
- `/cm:chunk graph --depth 2` - View context relationships
- `/cm:chunk related "topic"` - Find related contexts

### Configuration
- `/cm:config auto-save.interval 15` - Set auto-save interval (minutes)
- `/cm:config checkpoint.compress true` - Enable compression
- `/cm:config checkpoint.retention 30` - Set retention period (days)

## Quick Start

1. **Install Claude Memento** with agent support:
   ```bash
   ./install.sh  # Automatically installs agent files
   ```

2. **Check status**:
   ```
   /cm:status
   ```

3. **Save your first checkpoint**:
   ```
   /cm:save "Initial project setup"
   ```

4. **Load when needed**:
   ```
   /cm:last
   ```

## Key Features

### Auto-Context Management
- **Automatic saving** every 15 minutes (configurable)
- **Smart chunking** for large contexts (>10K tokens)
- **Intelligent compression** (30-50% token reduction)
- **Cross-session persistence** with relationship tracking

### Multi-Agent Coordination
- **Context handoffs** between specialized agents
- **Selective loading** based on agent requirements
- **Dependency tracking** across agent interactions

### Performance Optimization
- **Token usage reduction** by 40-60% through smart loading
- **Compression** saves additional 30-50%
- **Caching** for frequently accessed contexts

## Usage Examples

### Large Project Management
```
# When context approaches token limits
Agent detects: "Context size approaching limit. Initiating smart chunking..."
Executes: /cm:save "Pre-chunking checkpoint"
Result: Context automatically split into manageable pieces
```

### Agent Handoffs
```
# Switching from backend to frontend work
Current: /cm:save "Backend API complete, switching to frontend"
Next: /cm:chunk search "API endpoints"
Result: Frontend agent receives only relevant context
```

### Error Recovery
```
# After unexpected termination
Recovery: /cm:last
Status: /cm:status
Result: "Restored context from checkpoint 2 hours ago"
```

## Best Practices

1. **Save Early, Save Often**
   - Use descriptive save reasons
   - Create checkpoints at major milestones

2. **Smart Loading**
   - Load only what you need with queries
   - Use relationship graph for dependencies

3. **Monitor Performance**
   - Check token usage with `/cm:status`
   - Enable auto-compression for efficiency

## Integration Notes

- **Requires**: Claude Memento v1.0.0+
- **Auto-installed**: During Claude Memento installation
- **Location**: `~/.claude/agents/context-manager-memento.md`
- **Compatibility**: Works with all Claude Code agents

For detailed configuration and advanced features, see the full agent documentation in the agents directory.