# Changelog

All notable changes to Claude Memento will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Fixed installation script directory structure issue where `cp -r src/*` flattened the directory hierarchy
- Fixed shell script execution permissions not being set correctly during installation
- Added proper execute permissions for all `.sh` files in `install.sh`
- Added Git Bash permission handling in `install.ps1` for Windows users
- Corrected batch wrapper path in `install.ps1` to reference `src\cli.sh`
- Fixed all script source paths to include `/src/` prefix

### Changed
- Updated README.md with correct installation paths (`~/.claude/memento/` instead of `~/.claude-memento/`)
- Updated configuration file documentation to match actual structure
- Added comprehensive troubleshooting section for common issues
- Improved installation process with better permission handling

### Added
- Full system backup feature before installation with restore script
- Automatic permission setting for all shell scripts
- Windows PowerShell support for setting Unix permissions via Git Bash
- Additional troubleshooting documentation for path and permission issues

## [1.0.0] - 2025-08-05

### Added
- Initial release of Claude Memento
- Core memory management system with checkpoint functionality
- 7 integrated Claude Code commands (`/cm:save`, `/cm:load`, `/cm:status`, `/cm:list`, `/cm:last`, `/cm:config`, `/cm:hooks`)
- Cross-platform installation support (macOS, Linux, Windows)
- Automatic compression and indexing
- Hook system for customization
- Configuration management
- Installation and uninstallation scripts
- Comprehensive documentation

### Known Issues
- Limited to local storage (cloud sync planned for v1.1)
- Single profile support only
- Manual checkpoint management required

[Unreleased]: https://github.com/claude-memento/claude-memento/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/claude-memento/claude-memento/releases/tag/v1.0.0