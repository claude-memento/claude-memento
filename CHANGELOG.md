# Changelog

All notable changes to Claude Memento will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-08-07

### Added
- Enhanced uninstall scripts with graceful process termination
- Comprehensive data backup options during uninstallation (--keep-data flag)
- Advanced configuration validation with proper data types
- Force and verbose modes for uninstall operations (--force, --verbose)
- Graph database system with TF-IDF vectorization
- Auto-save daemon with configurable intervals
- Background process management with PID tracking
- Comprehensive test suite with performance benchmarks
- Smart chunk loading with semantic search capabilities
- Help system for all uninstall options

### Changed
- **BREAKING**: Configuration format updated to use proper boolean/number types
- Uninstall scripts now provide multiple removal options with data preservation
- Process termination enhanced with graceful shutdown (SIGTERM) and timeout handling
- Configuration system validates data types and prevents string/boolean confusion
- Graph system implements searchByKeyword() and getStats() methods
- Module loading paths standardized to absolute paths for reliability
- Enhanced safety confirmations in uninstall process

### Fixed
- Boolean configuration values now properly parsed (true vs "true")
- Auto-save functionality working with background daemon and proper PID management
- Graph database methods fully implemented and tested
- Module path resolution issues in test scripts
- Process cleanup during uninstallation covers all scenarios including orphaned processes
- Temporary file cleanup enhanced across all platforms
- Settings.json interval values changed from string to number type

### Security
- Added input validation for configuration parameters
- Enhanced process verification before termination with kill -0 checks
- Improved PID file validation and cleanup with stale file detection
- Added timeout mechanisms to prevent hanging processes during shutdown
- Safe process termination with graceful SIGTERM before SIGKILL

### Performance
- Search performance optimized to sub-50ms (51% better than 100ms target)
- Graph traversal efficiency improved with BFS algorithms
- Memory usage optimized for large checkpoint processing
- Parallel test execution reduces validation time significantly
- TF-IDF vectorization provides fast semantic similarity search

## [Unreleased]

### Planned
- Web interface for chunk visualization
- Advanced search filters and queries
- Multi-language content support
- Cloud backup integration

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

[Unreleased]: https://github.com/claude-memento/claude-memento/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/claude-memento/claude-memento/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/claude-memento/claude-memento/releases/tag/v1.0.0