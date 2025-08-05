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

## Installation 📦

Claude Memento installs with a single script.

### Prerequisites
- Claude Code installed (or `~/.claude/` directory exists)
- Bash environment (Git Bash, WSL, or PowerShell on Windows)

### Quick Install

**macOS / Linux:**
```bash
# Clone and install
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
./install.sh

# Verify in Claude Code
# /cm:status
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

Default configuration (`~/.claude/memento/config/default.json`):
```json
{
  "checkpoint": {
    "retention": 10,
    "auto_save": true,
    "interval": 900,
    "strategy": "full"
  },
  "memory": {
    "max_size": "10MB",
    "compression": true,
    "format": "markdown"
  },
  "session": {
    "timeout": 300,
    "auto_restore": true
  },
  "integration": {
    "superclaude": true,
    "command_prefix": "cm:"
  }
}
```

## Project Structure 📁

```
claude-memento/
├── src/
│   ├── core/          # Core memory management
│   ├── commands/      # Command implementations
│   ├── utils/         # Utilities and helpers
│   └── bridge/        # Claude Code integration
├── templates/         # Configuration templates
├── commands/          # Command definitions
├── docs/             # Documentation
└── examples/         # Usage examples
```

## Troubleshooting 🔍

### Common Issues

**Commands not working:**
```bash
# Check if commands are installed
ls ~/.claude/commands/cm/

# Verify status command
/cm:status
```

**Installation fails:**
```bash
# Check permissions
chmod +x install.sh
./install.sh --verbose
```

**Memory load errors:**
```bash
# Verify checkpoint integrity
/cm:status --check
# Repair if needed
./src/utils/repair.sh
```

**Path structure issues after installation:**
```bash
# If commands fail with "file not found" errors
# This might be due to incorrect installation
# Reinstall with the updated script:
./uninstall.sh && ./install.sh
```

**Permission errors:**
```bash
# If you get "permission denied" errors
# Check file permissions
ls -la ~/.claude/memento/src/**/*.sh

# Manually fix permissions if needed
find ~/.claude/memento/src -name "*.sh" -type f -exec chmod +x {} \;
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
- [ ] Cloud backup support
- [ ] Multiple profile management
- [ ] Real-time sync capability

**Version 2.0:**
- [ ] Web UI dashboard
- [ ] Team collaboration features
- [ ] Advanced search and filtering
- [ ] Integration with other AI tools

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