# Contributing to Claude Memento

Thank you for your interest in contributing to Claude Memento! We welcome contributions from the community and are excited to work with you.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please be respectful and constructive in all interactions.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

1. **Clear title and description**
2. **Steps to reproduce**
3. **Expected behavior**
4. **Actual behavior**
5. **System information** (OS, Claude Code version, etc.)
6. **Error messages or logs**

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:

1. **Check existing issues** for similar suggestions
2. **Provide a clear use case**
3. **Explain the expected benefits**
4. **Consider implementation complexity**

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Test thoroughly** (see Testing Guidelines below)
5. **Commit with clear messages** (`git commit -m 'Add: New checkpoint compression algorithm'`)
6. **Push to your fork** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

#### PR Guidelines

- **One feature per PR** - Keep PRs focused and manageable
- **Update documentation** - Include README updates if needed
- **Add tests** - For new features or bug fixes
- **Follow code style** - Maintain consistency with existing code
- **Update CHANGELOG.md** - Add your changes to the Unreleased section

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/claude-memento/claude-memento.git
   cd claude-memento
   ```

2. **Install development dependencies**
   ```bash
   # Currently no special dependencies required
   # Just ensure you have bash and Claude Code installed
   ```

3. **Run tests**
   ```bash
   ./test.sh
   ```

## Testing Guidelines

### Running Tests

```bash
# Run all tests
./test.sh

# Run specific test suite
./test.sh unit
./test.sh integration
```

### Writing Tests

- Place unit tests in `tests/unit/`
- Place integration tests in `tests/integration/`
- Follow existing test patterns
- Test both success and failure cases

## Code Style

### Shell Scripts

- Use `#!/bin/bash` shebang
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use meaningful variable names
- Add comments for complex logic
- Handle errors gracefully

### Example:
```bash
#!/bin/bash

# Create checkpoint with proper error handling
create_checkpoint() {
    local reason="${1:-Manual checkpoint}"
    
    # Validate input
    if [ -z "$reason" ]; then
        log_error "Checkpoint reason cannot be empty"
        return 1
    fi
    
    # Create checkpoint
    # ... implementation ...
}
```

### Documentation

- Use clear, concise language
- Include code examples
- Update relevant documentation when changing functionality
- Use proper Markdown formatting

## Directory Structure

Understanding the project structure helps with contributions:

```
claude-memento/
├── src/
│   ├── core/          # Core functionality
│   ├── commands/      # Command implementations
│   ├── utils/         # Utility functions
│   └── bridge/        # Claude Code integration
├── templates/         # Configuration templates
├── commands/          # Command definitions (.md files)
├── docs/              # Additional documentation
├── tests/             # Test suites
└── examples/          # Usage examples
```

## Commit Messages

Follow conventional commit format:

- `Add:` New feature
- `Fix:` Bug fix
- `Update:` Enhancement to existing feature
- `Remove:` Removal of feature/code
- `Refactor:` Code refactoring
- `Docs:` Documentation updates
- `Test:` Test additions/updates

Example: `Fix: Checkpoint creation on Windows paths with spaces`

## Release Process

1. Update version in relevant files
2. Update CHANGELOG.md
3. Create git tag
4. Push tag to trigger release

## Questions?

- Open an issue for general questions
- Tag maintainers for urgent matters
- Join discussions in existing issues

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to Claude Memento! 🧠✨