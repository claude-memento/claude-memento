# Auto-Chunking System

Automatic document splitting for efficient context management.

## Overview

Claude Memento now automatically chunks large checkpoints (>10KB) during save operations, enabling:
- Unlimited context storage
- Smart context retrieval
- Efficient memory usage
- Query-based loading

## How It Works

### Save Flow
```
/cm:save → Create checkpoint → Size > 10KB? → Auto-chunk → Save manifest
```

### Load Flow
```
/cm:load → Detect manifest → Smart load → Assemble context
```

## Automatic Operation

### During Save

When you save a checkpoint that exceeds 10KB:

1. **Automatic Detection**: System detects large checkpoint
2. **Smart Chunking**: Splits at natural boundaries (paragraphs, sections)
3. **Manifest Creation**: Creates tracking file for chunks
4. **Seamless Storage**: Original checkpoint replaced with lightweight reference

```bash
$ /cm:save "completed large feature"
📸 Creating checkpoint...
📄 Large checkpoint detected (45KB), initiating auto-chunking...
✅ Created 12 chunks (11250 tokens)
✅ Checkpoint successfully chunked
```

### During Load

When loading a chunked checkpoint:

1. **Automatic Detection**: System detects chunked checkpoint
2. **Smart Assembly**: Reconstructs content intelligently
3. **Query Support**: Optional query-based loading
4. **Full Compatibility**: Works like regular checkpoints

```bash
# Load all chunks
$ /cm:load checkpoint-20240120-1430

# Load with query (smart selection)
$ /cm:load checkpoint-20240120-1430 --query "API implementation"

# Or simpler syntax
$ /cm:load checkpoint-20240120-1430 "database schema"
```

## Smart Loading Options

### Full Load (Default)
Loads all chunks in order - suitable when you need complete context.

### Query-Based Load
Loads only relevant chunks based on your query:
- Uses TF-IDF similarity matching
- Includes related chunks automatically
- Stays within token budget (8000 tokens)

### Recent Load
Load only recent portions:
```bash
$ /cm:load --recent 5  # Load last 5 chunks
```

## Features

### Intelligent Chunking
- **Natural Boundaries**: Splits at paragraphs, headers, sections
- **Optimal Size**: 2-3K tokens per chunk
- **Context Overlap**: Small overlap for continuity
- **Metadata Preservation**: Maintains relationships

### Efficient Storage
- **Compression**: Each chunk individually stored
- **Deduplication**: Same content reuses chunk IDs
- **Cleanup**: Old chunks removed with checkpoints
- **Indexing**: Fast keyword and semantic search

### Smart Retrieval
- **Keyword Search**: Fast text matching
- **TF-IDF Scoring**: Relevance ranking
- **Relationship Expansion**: Include related chunks
- **Token Budget**: Stay within context limits

## Technical Details

### Chunk Structure
```json
{
  "id": "sha256-hash",
  "content": "chunk text...",
  "metadata": {
    "checkpointId": "checkpoint-20240120-1430",
    "position": 0,
    "total": 12,
    "tokens": 950,
    "previous": null,
    "next": "next-chunk-id"
  },
  "keywords": [...],
  "summary": "chunk summary..."
}
```

### Manifest Structure
```json
{
  "checkpointId": "checkpoint-20240120-1430",
  "created": "2024-01-20T14:30:00Z",
  "originalSize": 46080,
  "chunks": [...],
  "summary": {
    "totalChunks": 12,
    "totalTokens": 11250
  }
}
```

## Configuration

Future configuration options (in development):

```json
{
  "autoChunking": {
    "enabled": true,
    "threshold": 10240,  // 10KB
    "chunkSize": 2000,   // tokens
    "overlap": 50        // tokens
  }
}
```

## Performance

- **Chunking Speed**: ~1MB/second
- **Load Time**: <100ms for smart assembly
- **Query Search**: <50ms for 1000 chunks
- **Storage Overhead**: ~5% for metadata

## Troubleshooting

### Checkpoint Not Chunking
- Check Node.js is installed: `node --version`
- Verify size threshold (>10KB)
- Check logs for errors

### Smart Load Not Working
- Ensure manifest file exists
- Verify chunks are indexed
- Check query syntax

### Missing Chunks
- Run `/cm:chunk stats` to verify
- Check chunk index integrity
- Rebuild index if needed

## Best Practices

1. **Let It Work Automatically**: No manual intervention needed
2. **Use Queries for Large Contexts**: More efficient than loading all
3. **Monitor Storage**: Check `/cm:status` periodically
4. **Trust the System**: Chunking preserves all content

## Examples

### Large Conversation Save
```bash
# Just save normally - chunking happens automatically
$ /cm:save "completed authentication system implementation"
```

### Targeted Context Load
```bash
# Load specific parts of a large checkpoint
$ /cm:load checkpoint-20240120-1430 "error handling"
```

### Search Across Chunks
```bash
# Search functionality works across all chunks
$ /cm:chunk search "database connection"
```

## Integration with Commands

All existing commands work seamlessly with chunked checkpoints:
- `/cm:list` - Shows all checkpoints (chunked or regular)
- `/cm:status` - Reports chunk statistics
- `/cm:hooks` - Hooks run normally with chunking

## Future Enhancements

- Semantic search with embeddings
- Cross-checkpoint relationships
- Incremental chunking
- Compression optimization
- Visual chunk browser