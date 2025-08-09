# Claude Memento v1.0 🧠

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues](https://img.shields.io/github/issues/claude-memento/claude-memento)](https://github.com/claude-memento/claude-memento/issues)
[![GitHub stars](https://img.shields.io/github/stars/claude-memento/claude-memento)](https://github.com/claude-memento/claude-memento/stargazers)

[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md)

A memory management extension for Claude Code that preserves context across conversations and ensures continuity in long-term projects.

**📢 Status**: Initial release - actively improving! Expect some rough edges as we refine the experience.

## What is Claude Memento? 🤔

Claude Memento addresses the context loss problem in Claude Code by providing:
- 💾 **Automatic memory backup** for important work states and context
- 🔄 **Session continuity** to seamlessly resume previous work
- 📝 **Knowledge accumulation** with permanent storage of project decisions
- 🎯 **Native Claude Code integration** via `/cm:` command namespace
- 🔐 **Non-destructive installation** that preserves existing settings

## Current Status 📊

**What's Working Well:**
- Core memory management system
- 7 integrated Claude Code commands
- Cross-platform installation (macOS, Linux, Windows)
- Automatic compression and indexing
- Hook system for customization

**Known Limitations:**
- Initial release with expected bugs
- Limited to local storage (cloud sync coming)
- Single profile support currently
- Manual checkpoint management

## Key Features ✨

### Commands 🛠️
7 essential commands for memory management:

**Memory Operations:**
- `/cm:save` - Save current state with description
- `/cm:load` - Load specific checkpoint
- `/cm:status` - View system status

**Checkpoint Management:**
- `/cm:list` - List all checkpoints
- `/cm:last` - Load most recent checkpoint

**Configuration:**
- `/cm:config` - View/edit configuration
- `/cm:hooks` - Manage hook scripts

### Smart Features 🎭
- **Automatic Compression**: Efficiently stores large contexts
- **Intelligent Indexing**: Fast checkpoint search and retrieval
- **Hook System**: Custom scripts for save/load events
- **Incremental Backups**: Only saves changes to optimize storage
- **Full System Backup**: Creates complete backup of ~/.claude directory before installation
- **Easy Restoration**: One-command restore script included with backups

## Claude Code Agent Integration 🤖

Claude Memento includes the **Context-Manager-Memento** agent for enhanced context management across multiple agent interactions.

### Agent Features
- **Automatic Context Capture**: Real-time monitoring and checkpoint creation
- **Smart Chunking**: Handles contexts >10K tokens with semantic boundary detection
- **Multi-Agent Coordination**: Seamless handoffs between specialized agents
- **Intelligent Compression**: 30-50% token reduction while preserving accuracy

### Quick Agent Commands
```bash
# Core operations
/cm:save "Project milestone complete"
/cm:load checkpoint-id
/cm:last

# Smart search
/cm:chunk search "authentication"
/cm:chunk graph --depth 2

# Configuration
/cm:config auto-save.interval 15
/cm:status
```

### Agent Benefits
- **40-60% token usage reduction** through smart context loading
- **Automatic session continuity** with persistent checkpoints
- **Cross-agent memory sharing** for complex multi-step workflows
- **Performance optimization** with intelligent caching

For detailed agent usage, see [Agent Usage Guide](docs/AGENT_USAGE.md).

## Installation 📦

Claude Memento installs with a single script and creates automatic backups.

### Prerequisites
- Claude Code installed (or `~/.claude/` directory exists)
- Bash environment (Git Bash, WSL, or PowerShell on Windows)
- Node.js (for graph database and vectorization features)
- jq (for JSON processing - auto-installed if missing)

### Quick Install

**macOS / Linux:**
```bash
# Clone and install
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh

# Verify installation
/cm:status
```

**Windows (PowerShell):**
```powershell
# Clone repository
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento

# Set execution policy if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run installer
.\install.ps1
```

**Windows (Git Bash):**
```bash
# Clone and install
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh
```

### Installation Features
- ✅ **Automatic Backup**: Creates complete backup before installation
- ✅ **Non-destructive**: Preserves existing CLAUDE.md content
- ✅ **Cross-platform**: Works on macOS, Linux, Windows
- ✅ **Dependency Check**: Validates and installs missing dependencies
- ✅ **Rollback Ready**: Easy restoration if needed

## How It Works 🔄

1. **State Capture**: Claude Memento captures your current work context
2. **Compression**: Large contexts are intelligently compressed
3. **Storage**: Checkpoints are stored with metadata and timestamps
4. **Retrieval**: Load any checkpoint to restore full context
5. **Integration**: Native Claude Code commands for seamless workflow

### Architecture Overview

```
Claude Code Session
    ↓
/cm:save command
    ↓
Context Processing → Compression → Storage
                                      ↓
                                 Checkpoint
                                      ↓
                              ~/.claude/memento/
                                      ↓
/cm:load command ← Decompression ← Retrieval
    ↓
Restored Session
```

## Usage Examples 💡

### Basic Workflow
```bash
# Starting a new feature
/cm:save "Initial feature setup complete"

# After significant progress
/cm:save "API endpoints implemented"

# Next day - restore context
/cm:last

# Or load specific checkpoint
/cm:list
/cm:load checkpoint-20240119-143022
```

### Advanced Usage
```bash
# Configure auto-save interval
/cm:config set autoSave true
/cm:config set saveInterval 300

# Add custom hooks
/cm:hooks add post-save ./scripts/backup-to-cloud.sh
/cm:hooks add pre-load ./scripts/validate-checkpoint.sh

# Check system health
/cm:status --verbose
```

## Configuration 🔧

### Settings Structure (`~/.claude/memento/config/settings.json`)

```json
{
  "autoSave": {
    "enabled": true,        // Boolean: Auto-save activation
    "interval": 60,         // Number: Save interval in seconds
    "onSessionEnd": true    // Boolean: Save on session end
  },
  "chunking": {
    "enabled": true,        // Boolean: Chunk system activation
    "threshold": 10240,     // Number: Chunking threshold (bytes)
    "chunkSize": 2000,      // Number: Individual chunk size
    "overlap": 50           // Number: Overlap between chunks
  },
  "memory": {
    "maxSize": 1048576,     // Number: Maximum memory usage
    "compression": true     // Boolean: Enable compression
  },
  "search": {
    "method": "tfidf",      // String: Search method (tfidf/simple)
    "maxResults": 20,       // Number: Max search results
    "minScore": 0.1         // Number: Minimum similarity score
  }
}
```

**⚠️ Important**: Use actual boolean/number types, not strings (`true` not `"true"`).

### Configuration Commands
```bash
# View current settings
/cm:config

# Enable auto-save with 60-second interval
/cm:auto-save enable
/cm:auto-save config interval 60

# Check system status
/cm:status
```

## Project Structure 📁

```
claude-memento/
├── src/
│   ├── commands/      # Command implementations
│   ├── core/          # Core memory management
│   ├── chunk/         # Graph DB & chunking system
│   ├── config/        # Configuration management
│   ├── hooks/         # Hook system
│   └── bridge/        # Claude Code integration
├── commands/cm/       # Command definitions
├── test/             # Test scripts
├── docs/             # Documentation
└── examples/         # Usage examples

Runtime Structure (~/.claude/memento/):
├── checkpoints/      # Saved checkpoints
├── chunks/           # Graph DB & chunk storage
├── config/           # Runtime configuration
└── src/              # Installed system files
```

## Advanced Features 🚀

### Graph Database System
Claude Memento includes an advanced graph-based chunk management system:

- **TF-IDF Vectorization**: Semantic similarity search
- **Graph Relationships**: Automatic content relationship discovery
- **Smart Loading**: Query-based selective context restoration
- **Performance**: Sub-50ms search times

### Chunk Management
```bash
# Search chunks by keyword
/cm:chunk search "API implementation"

# List all chunks
/cm:chunk list

# Build semantic relationships
/cm:chunk build-relations

# Get system statistics
/cm:chunk stats
```

## Uninstallation 🗑️

### Safe Removal Options

Claude Memento provides comprehensive uninstallation with data preservation options:

**Complete Removal:**
```bash
# Remove everything (PERMANENT DATA DELETION)
./uninstall.sh
```

**Preserve Data:**
```bash
# Keep checkpoints and chunks
./uninstall.sh --keep-data

# PowerShell equivalent
.\uninstall.ps1 -KeepData
```

**Force Mode (Skip Confirmations):**
```bash
# Automated removal
./uninstall.sh --force

# With data preservation
./uninstall.sh --keep-data --force
```

### What Gets Removed
- ✅ **Running Processes**: Automatically stopped with graceful shutdown
- ✅ **Claude Memento Section**: Removed from CLAUDE.md (file preserved)
- ✅ **Command Files**: All `/cm:` commands removed
- ✅ **Installation Files**: Complete system cleanup
- ✅ **Temporary Files**: PID files and caches cleared

### Data Preservation
When using `--keep-data`:
- Checkpoints backed up to `~/claude-memento-backup-[timestamp]/`
- Configuration files preserved
- Graph database and chunks maintained
- Active context files saved

## Troubleshooting 🔍

### Installation Issues

**Commands not working:**
```bash
# Check installation
/cm:status

# Verify command files
ls ~/.claude/commands/cm/
```

**Auto-save not working:**
```bash
# Check configuration
/cm:auto-save status

# Enable if needed
/cm:auto-save enable
/cm:auto-save config interval 60
```

**Graph system errors:**
```bash
# Run system tests
cd ~/.claude/memento/test/
./test-chunk-system.sh

# Check Node.js installation
node --version
```

### Performance Issues

**Slow search:**
```bash
# Rebuild search index
/cm:chunk build-relations

# Check system performance
/cm:status --verbose
```

### Recovery Options

**Restore from backup:**
```bash
# List available backups
ls ~/.claude_backup_*/

# Run restore script
~/.claude_backup_[timestamp]/restore.sh
```

**Reset configuration:**
```bash
# Reset to defaults
rm ~/.claude/memento/config/settings.json
/cm:status  # Will recreate defaults
```

## Contributing 🤝

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap 🗺️

**Version 1.1:**
- [ ] Web interface for chunk visualization
- [ ] Advanced search filters and queries  
- [ ] Multi-language content support

**Version 2.0:**
- [ ] Cloud backup integration
- [ ] Team collaboration features
- [ ] Advanced analytics dashboard
- [ ] Integration with other AI tools

**Recent Updates (v1.0.1):**
- ✅ Enhanced uninstall scripts with process management
- ✅ Improved configuration system with proper data types
- ✅ Graph database system with semantic search
- ✅ Auto-save functionality with background daemon
- ✅ Comprehensive test suite with performance validation

## FAQ ❓

**Q: Is my data secure?**
A: All data is stored locally in your home directory. Cloud features will include encryption.

**Q: Can I use this with multiple projects?**
A: Yes! Checkpoints are organized by project context automatically.

**Q: What happens if Claude Code updates?**
A: Claude Memento is designed to be forward-compatible with Claude Code updates.

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

Special thanks to the Claude Code community for feedback and contributions.

---

**Need help?** Check our [documentation](docs/README.md) or [open an issue](https://github.com/claude-memento/claude-memento/issues).

**Love Claude Memento?** Give us a ⭐ on [GitHub](https://github.com/claude-memento/claude-memento)!

## Star History

<a href="https://www.star-history.com/#claude-memento/claude-memento&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=claude-memento/claude-memento&type=Date" />
 </picture>
</a>