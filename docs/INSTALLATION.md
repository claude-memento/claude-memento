# Claude Memento Installation Guide

This guide provides detailed installation instructions for Claude Memento on different platforms.

## Prerequisites

### All Platforms
- Claude Code installed and configured
- Git for cloning the repository
- Basic command line knowledge

### Platform-Specific Requirements

**macOS/Linux:**
- Bash shell (usually pre-installed)
- Standard Unix utilities (chmod, find, etc.)

**Windows:**
- Git Bash or WSL (Windows Subsystem for Linux)
- OR PowerShell with Git installed

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/claude-memento/claude-memento.git
cd claude-memento
```

### 2. Platform-Specific Installation

#### macOS / Linux

```bash
# Make installer executable
chmod +x install.sh

# Run installer
./install.sh
```

#### Windows (PowerShell)

```powershell
# Check execution policy
Get-ExecutionPolicy

# If restricted, allow script execution for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run installer
.\install.ps1
```

#### Windows (Git Bash)

```bash
# Same as macOS/Linux
chmod +x install.sh
./install.sh
```

### 3. Verify Installation

After installation, verify everything is working:

```bash
# Check status
/cm:status

# Expected output:
# 🧠 Claude Memento Status
# ========================
# ...
# ⚙️  System Status:
#   ✅ Configuration: OK
```

## Installation Details

### What Gets Installed

1. **Core Files** (`~/.claude/memento/src/`)
   - Command implementations
   - Core functionality
   - Utility scripts
   - Bridge for Claude Code integration

2. **Command Definitions** (`~/.claude/commands/cm/`)
   - Markdown files defining each command
   - Integrated with Claude Code's command system

3. **Configuration** (`~/.claude/memento/config/`)
   - `default.json` - Main configuration
   - `hooks.json` - Hook system configuration

4. **Documentation** (`~/.claude/memento/`)
   - MEMENTO.md - System overview
   - COMMANDS.md - Command reference
   - PRINCIPLES.md - Design principles
   - RULES.md - Operating rules
   - HOOKS.md - Hook system guide

### Directory Structure After Installation

```
~/.claude/
├── memento/
│   ├── src/
│   │   ├── bridge/
│   │   ├── commands/
│   │   ├── core/
│   │   └── utils/
│   ├── config/
│   ├── checkpoints/
│   ├── logs/
│   └── *.md (documentation)
├── commands/
│   └── cm/
│       └── *.md (command definitions)
└── CLAUDE.md (updated with Memento section)
```

### Backup System

The installer automatically creates a full backup of your `~/.claude` directory:

- Location: `~/.claude_backup_[timestamp]`
- Includes: All existing configurations and data
- Restore script: Included in backup directory

To restore from backup:
```bash
/path/to/backup/restore.sh
```

## Troubleshooting Installation

### Permission Denied Errors

If you encounter permission errors:

```bash
# Check current permissions
ls -la install.sh

# Make executable
chmod +x install.sh

# For installed scripts
find ~/.claude/memento/src -name "*.sh" -type f -exec chmod +x {} \;
```

### Path Not Found Errors

If commands fail with "file not found":

1. Check installation directory:
   ```bash
   ls ~/.claude/memento/
   ```

2. Verify command files:
   ```bash
   ls ~/.claude/commands/cm/
   ```

3. Reinstall if necessary:
   ```bash
   ./uninstall.sh && ./install.sh
   ```

### Windows-Specific Issues

**PowerShell Execution Policy:**
```powershell
# Check current policy
Get-ExecutionPolicy

# Allow scripts (admin required for LocalMachine)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Git Bash Not Found:**
- Install Git for Windows from https://git-scm.com/download/win
- Ensure Git Bash is in your PATH

## Uninstallation

### Complete Removal
```bash
./uninstall.sh
```

### Keep Data (Remove Only Code)
```bash
./uninstall.sh --keep-data
```

## Post-Installation

### First Steps

1. **Check System Status**
   ```bash
   /cm:status
   ```

2. **Create Your First Checkpoint**
   ```bash
   /cm:save "Initial setup complete"
   ```

3. **List Checkpoints**
   ```bash
   /cm:list
   ```

### Configuration

View current configuration:
```bash
/cm:config
```

Modify settings:
```bash
/cm:config checkpoint.retention 20
```

### Setting Up Hooks

Enable automatic behaviors:
```bash
/cm:hooks enable pre-save
/cm:hooks enable post-load
```

## Getting Help

- Run `/cm:status --health` for system diagnostics
- Check `~/.claude/memento/logs/` for detailed logs
- See [Troubleshooting](../README.md#troubleshooting-) in README
- Open an issue on GitHub for additional support

## Next Steps

- Read the [Command Reference](../templates/COMMANDS.md)
- Explore [Hook System](../templates/HOOKS.md)
- Review [Configuration Options](../README.md#configuration-)

Happy memory management! 🧠✨