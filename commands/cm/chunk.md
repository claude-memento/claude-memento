# /cm:chunk - Chunk Management System

## Purpose
Manage document chunking for efficient context storage and retrieval. Automatically splits large documents into manageable pieces with intelligent search and loading capabilities.

## Usage
```
/cm:chunk [subcommand] [options]
```

## Subcommands

### create <content>
Create chunks from provided content.
```
/cm:chunk create "Your long text content here..."
```

### search <query>
Search for chunks containing specific keywords using TF-IDF matching.
```
/cm:chunk search "API implementation"
```

### load <query>
Load intelligent context based on query, assembling relevant chunks.
```
/cm:chunk load "previous conversation about authentication"
```

### stats
Show chunk system statistics including total chunks, tokens, and relationships.
```
/cm:chunk stats
```

### list [filter]
List all chunks, optionally filtered by keywords.
```
/cm:chunk list
/cm:chunk list "database"
```

### delete <id>
Delete a specific chunk by ID.
```
/cm:chunk delete abc123def456
```

## Features

### Automatic Chunking
- **Smart Boundaries**: Splits at natural boundaries (paragraphs, sections)
- **Optimal Size**: 2-3K tokens per chunk
- **Overlap**: Maintains context continuity between chunks
- **Metadata**: Preserves relationships and keywords

### TF-IDF Search
- **Keyword Extraction**: Automatic keyword and n-gram extraction
- **Relevance Scoring**: Cosine similarity for accurate matching
- **Fast Retrieval**: Efficient indexing for quick searches
- **No Dependencies**: Pure JavaScript implementation

### Smart Loading
- **Query-Based**: Load only relevant chunks based on query
- **Token Budget**: Stay within context window limits
- **Relationship Expansion**: Include related chunks automatically
- **Assembly**: Reconstruct content in logical order

## Integration

Works seamlessly with save/load commands:
- Checkpoints >10KB are automatically chunked
- Load commands support query-based retrieval
- Search works across all chunks and checkpoints

## Examples

### Manual Chunking
```bash
# Create chunks from large text
/cm:chunk create "Long document content that needs to be split..."
```

### Search and Retrieve
```bash
# Search for specific content
/cm:chunk search "error handling"

# Load context about a topic
/cm:chunk load "database migration discussion"
```

### Management
```bash
# View statistics
/cm:chunk stats

# List recent chunks
/cm:chunk list

# Clean up old chunks
/cm:chunk delete old-chunk-id
```

## Implementation
```bash
#!/bin/bash
CLAUDE_MEMENTO_BRIDGE=1
MEMENTO_DIR="$HOME/.claude/memento"
export CLAUDE_MEMENTO_BRIDGE
node "$MEMENTO_DIR/src/commands/chunk-wrapper.js" "$@"
```